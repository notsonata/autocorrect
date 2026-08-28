import AutocorrectSettings
import SwiftUI

private enum SettingsPane: String, CaseIterable, Identifiable {
    case general
    case provider
    case exclusions
    case privacy

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general: "General"
        case .provider: "AI Provider"
        case .exclusions: "Exclusions"
        case .privacy: "Privacy"
        }
    }

    var systemImage: String {
        switch self {
        case .general: "gearshape"
        case .provider: "sparkles"
        case .exclusions: "nosign"
        case .privacy: "hand.raised"
        }
    }
}

struct SettingsView: View {
    @ObservedObject var model: SettingsViewModel
    @State private var selectedPane: SettingsPane? = .general

    var body: some View {
        NavigationSplitView {
            List(SettingsPane.allCases, selection: $selectedPane) { pane in
                Label(pane.title, systemImage: pane.systemImage)
                    .tag(pane)
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 150, ideal: 170, max: 190)
        } detail: {
            ScrollView {
                detailContent
                    .frame(maxWidth: 620, alignment: .topLeading)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 26)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .background(Color(nsColor: .windowBackgroundColor))
        }
    }

    @ViewBuilder
    private var detailContent: some View {
        switch selectedPane ?? .general {
        case .general:
            generalPane
        case .provider:
            providerPane
        case .exclusions:
            exclusionsPane
        case .privacy:
            privacyPane
        }
    }

    private var generalPane: some View {
        VStack(alignment: .leading, spacing: 20) {
            SettingsHeader(
                title: "General",
                subtitle: "Control when Autocorrect runs and verify the macOS input method."
            )

            SettingsCard {
                VStack(alignment: .leading, spacing: 14) {
                    Toggle("Enable Autocorrect", isOn: $model.isEnabled)
                        .font(.headline)
                        .disabled(!model.privacyAcknowledged || !model.inputMethodInstalled)

                    if let hint = model.enablementHint {
                        Label(hint, systemImage: "info.circle")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }

                    Divider()

                    Toggle(
                        "Launch Autocorrect at login",
                        isOn: Binding(
                            get: { model.launchAtLogin },
                            set: { model.setLaunchAtLogin($0) }
                        )
                    )

                    if let message = model.launchServiceMessage {
                        Text(message)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            SettingsCard {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 10) {
                        Image(systemName: model.inputMethodInstalled ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .foregroundStyle(model.inputMethodInstalled ? .green : .orange)
                            .font(.title3)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Input Method")
                                .font(.headline)
                            Text(model.inputMethodInstalled ? "Installed for this user" : "Installation required")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }

                    if let message = model.inputMethodMessage {
                        Text(message)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Button("Open Keyboard Settings") {
                            model.openKeyboardSettings()
                        }
                        .buttonStyle(.borderedProminent)

                        Button("Repair Input Method") {
                            model.repairInputMethod()
                        }
                    }
                }
            }
        }
    }

    private var providerPane: some View {
        VStack(alignment: .leading, spacing: 20) {
            SettingsHeader(
                title: "AI Provider",
                subtitle: "Choose the OpenAI-compatible backend used for uncertain corrections."
            )

            SettingsCard {
                VStack(alignment: .leading, spacing: 16) {
                    LabeledContent("Provider") {
                        Picker("Provider", selection: $model.selectedProvider) {
                            ForEach(CorrectionProviderSelection.allCases) { provider in
                                Text(provider.displayName).tag(provider)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 280)
                    }

                    Divider()

                    switch model.selectedProvider {
                    case .gemini:
                        LabeledContent("Model") {
                            TextField("Model", text: $model.geminiModel)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 320)
                        }
                    case .openRouter:
                        LabeledContent("Model") {
                            TextField("Model", text: $model.openRouterModel)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 320)
                        }

                        Text("OpenRouter endpoint: https://openrouter.ai/api/v1/")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    case .custom:
                        LabeledContent("Base URL") {
                            TextField("https://example.com/v1/", text: $model.customBaseURL)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 320)
                        }

                        LabeledContent("Model") {
                            TextField("Model", text: $model.customModel)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 320)
                        }

                        Text("Remote providers require HTTPS. Plain HTTP is allowed only for loopback providers such as localhost.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            SettingsCard {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("API Key")
                                .font(.headline)
                            Text(model.hasStoredAPIKey ? "A key is saved for this provider." : "No key is saved for this provider.")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(systemName: model.hasStoredAPIKey ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(model.hasStoredAPIKey ? .green : .secondary)
                    }

                    HStack(spacing: 10) {
                        SecureField("Paste API key", text: $model.pendingAPIKey)
                            .textFieldStyle(.roundedBorder)

                        Button(model.hasStoredAPIKey ? "Replace Key" : "Save Key") {
                            model.saveAPIKey()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(model.pendingAPIKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }

                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "internaldrive")
                            .foregroundStyle(.secondary)
                        Text("Stored locally at \(model.credentialStorageDescription) with owner-only file permissions.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    }

                    HStack {
                        if let message = model.credentialMessage {
                            Text(message)
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if model.hasStoredAPIKey {
                            Button("Remove Key", role: .destructive) {
                                model.removeAPIKey()
                            }
                        }
                    }
                }
            }
        }
    }

    private var exclusionsPane: some View {
        VStack(alignment: .leading, spacing: 20) {
            SettingsHeader(
                title: "Exclusions",
                subtitle: "Autocorrect will pass typing through untouched in these applications."
            )

            SettingsCard {
                VStack(alignment: .leading, spacing: 12) {
                    if model.excludedBundleIdentifiers.isEmpty {
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.circle")
                                .foregroundStyle(.secondary)
                            Text("No excluded applications")
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 6)
                    } else {
                        ForEach(model.excludedBundleIdentifiers, id: \.self) { bundleIdentifier in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(model.displayName(for: bundleIdentifier))
                                    Text(bundleIdentifier)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Button("Remove") {
                                    model.removeExcludedApplication(bundleIdentifier)
                                }
                            }

                            if bundleIdentifier != model.excludedBundleIdentifiers.last {
                                Divider()
                            }
                        }
                    }

                    Divider()

                    Button("Add Application…") {
                        model.addExcludedApplication()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }

    private var privacyPane: some View {
        VStack(alignment: .leading, spacing: 20) {
            SettingsHeader(
                title: "Privacy",
                subtitle: "Autocorrect is designed to inspect as little text as possible."
            )

            SettingsCard {
                VStack(alignment: .leading, spacing: 14) {
                    PrivacyRow(
                        icon: "lock.shield",
                        title: "Secure fields are excluded",
                        detail: "Password and unverifiable fields are pass-through only."
                    )
                    Divider()
                    PrivacyRow(
                        icon: "clock.arrow.circlepath",
                        title: "No typing history",
                        detail: "Completed words, context, prompts, and model responses are not intentionally persisted."
                    )
                    Divider()
                    PrivacyRow(
                        icon: "network",
                        title: "Bounded network context",
                        detail: "When AI is needed, the completed word and up to 256 preceding characters may be sent to the selected provider."
                    )
                }
            }

            SettingsCard {
                VStack(alignment: .leading, spacing: 10) {
                    Toggle(
                        "Allow network autocorrection in non-secure fields",
                        isOn: $model.privacyAcknowledged
                    )
                    .font(.headline)

                    Text("Turning this off also disables Autocorrect.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

private struct SettingsHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 26, weight: .semibold))
            Text(subtitle)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }
}

private struct SettingsCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
    }
}

private struct PrivacyRow: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .frame(width: 20)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(detail)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
