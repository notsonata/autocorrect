import AutocorrectSettings
import SwiftUI

struct SettingsView: View {
    @ObservedObject var model: SettingsViewModel

    var body: some View {
        Form {
            Section("General") {
                Toggle("Enable autocorrect", isOn: $model.isEnabled)
                    .disabled(!model.privacyAcknowledged)

                Toggle(
                    "Launch settings app at login",
                    isOn: Binding(
                        get: { model.launchAtLogin },
                        set: { model.setLaunchAtLogin($0) }
                    )
                )

                if let message = model.launchServiceMessage {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("AI Provider") {
                Picker("Provider", selection: $model.selectedProvider) {
                    ForEach(CorrectionProviderSelection.allCases) { provider in
                        Text(provider.displayName).tag(provider)
                    }
                }

                switch model.selectedProvider {
                case .gemini:
                    TextField("Model", text: $model.geminiModel)
                case .openRouter:
                    TextField("Model", text: $model.openRouterModel)
                    Text("Uses https://openrouter.ai/api/v1/")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                case .custom:
                    TextField("Base URL", text: $model.customBaseURL)
                    TextField("Model", text: $model.customModel)
                }

                HStack {
                    SecureField("New API key", text: $model.pendingAPIKey)
                    Button("Save") {
                        model.saveAPIKey()
                    }
                    .disabled(model.pendingAPIKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                HStack {
                    Text(model.hasStoredAPIKey ? "API key stored in Keychain" : "No API key stored")
                        .foregroundStyle(.secondary)
                    Spacer()
                    if model.hasStoredAPIKey {
                        Button("Remove Key", role: .destructive) {
                            model.removeAPIKey()
                        }
                    }
                }

                if let message = model.credentialMessage {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Excluded Applications") {
                if model.excludedBundleIdentifiers.isEmpty {
                    Text("No excluded applications.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(model.excludedBundleIdentifiers, id: \.self) { bundleIdentifier in
                        HStack {
                            VStack(alignment: .leading) {
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
                    }
                }

                Button("Add Application…") {
                    model.addExcludedApplication()
                }
            }

            Section("Privacy") {
                Text(
                    "Autocorrect can observe completed words in supported text fields. It does not keep typing history. Secure and unverifiable fields are pass-through only. When a correction candidate needs AI, the completed word and up to 256 preceding characters may be sent to the selected provider. Typed text and model responses are not intentionally stored locally."
                )
                .fixedSize(horizontal: false, vertical: true)

                Toggle(
                    "I understand and allow network autocorrection in non-secure fields",
                    isOn: $model.privacyAcknowledged
                )
            }
        }
        .padding(20)
    }
}
