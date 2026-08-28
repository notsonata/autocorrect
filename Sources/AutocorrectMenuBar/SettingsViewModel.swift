import AppKit
import AutocorrectProviders
import AutocorrectSettings
import Combine
import ServiceManagement
import UniformTypeIdentifiers

@MainActor
final class SettingsViewModel: ObservableObject {
    private let settings: SharedAutocorrectSettings
    private let credentialStore: ProviderCredentialStore
    private let inputMethodInstaller: InputMethodInstaller

    let credentialStorageDescription = "~/Library/Application Support/Autocorrect/credentials.json"

    @Published var isEnabled: Bool {
        didSet { settings.isEnabled = isEnabled }
    }

    @Published var privacyAcknowledged: Bool {
        didSet {
            settings.privacyAcknowledged = privacyAcknowledged
            if !privacyAcknowledged && isEnabled {
                isEnabled = false
            }
        }
    }

    @Published var selectedProvider: CorrectionProviderSelection {
        didSet {
            settings.selectedProvider = selectedProvider
            pendingAPIKey = ""
            refreshCredentialStatus()
        }
    }

    @Published var geminiModel: String {
        didSet { settings.geminiModel = geminiModel }
    }

    @Published var openRouterModel: String {
        didSet { settings.openRouterModel = openRouterModel }
    }

    @Published var customBaseURL: String {
        didSet { settings.customBaseURL = customBaseURL }
    }

    @Published var customModel: String {
        didSet { settings.customModel = customModel }
    }

    @Published var excludedBundleIdentifiers: [String]
    @Published var pendingAPIKey = ""
    @Published private(set) var hasStoredAPIKey = false
    @Published private(set) var credentialMessage: String?
    @Published private(set) var launchAtLogin: Bool
    @Published private(set) var launchServiceMessage: String?
    @Published private(set) var inputMethodInstalled = false
    @Published private(set) var inputMethodMessage: String?

    init(
        settings: SharedAutocorrectSettings = SharedAutocorrectSettings(),
        credentialStore: ProviderCredentialStore = LocalCredentialStore(),
        inputMethodInstaller: InputMethodInstaller = InputMethodInstaller()
    ) {
        self.settings = settings
        self.credentialStore = credentialStore
        self.inputMethodInstaller = inputMethodInstaller

        let snapshot = settings.snapshot()
        self.isEnabled = snapshot.isEnabled
        self.privacyAcknowledged = snapshot.privacyAcknowledged
        self.selectedProvider = snapshot.selectedProvider
        self.geminiModel = snapshot.geminiModel
        self.openRouterModel = snapshot.openRouterModel
        self.customBaseURL = snapshot.customBaseURL
        self.customModel = snapshot.customModel
        self.excludedBundleIdentifiers = Array(snapshot.excludedBundleIdentifiers).sorted()
        self.launchAtLogin = SMAppService.mainApp.status == .enabled

        installInputMethodIfNeeded()
        refreshCredentialStatus()
    }

    var enablementHint: String? {
        if !inputMethodInstalled {
            return "Install the input method before enabling Autocorrect."
        }
        if !privacyAcknowledged {
            return "Review and accept the privacy setting before enabling Autocorrect."
        }
        return nil
    }

    func installInputMethodIfNeeded() {
        do {
            let changed = try inputMethodInstaller.installIfNeeded()
            inputMethodInstalled = true
            inputMethodMessage = changed
                ? "Input method installed. Add Autocorrect in Keyboard Settings, then select it as an input source."
                : "Input method is installed."
        } catch {
            inputMethodInstalled = inputMethodInstaller.isInstalled()
            inputMethodMessage = "Could not install the embedded input method: \(error.localizedDescription)"
            if !inputMethodInstalled && isEnabled {
                isEnabled = false
            }
        }
    }

    func repairInputMethod() {
        do {
            try inputMethodInstaller.reinstall()
            inputMethodInstalled = true
            inputMethodMessage = "Input method reinstalled. Add Autocorrect in Keyboard Settings if it is not already enabled."
        } catch {
            inputMethodInstalled = inputMethodInstaller.isInstalled()
            inputMethodMessage = "Could not reinstall the input method: \(error.localizedDescription)"
        }
    }

    func openKeyboardSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.Keyboard-Settings.extension") else {
            return
        }
        NSWorkspace.shared.open(url)
    }

    func saveAPIKey() {
        let value = pendingAPIKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return }

        do {
            try credentialStore.setAPIKey(value, for: selectedProvider.rawValue)
            pendingAPIKey = ""
            hasStoredAPIKey = true
            credentialMessage = "API key saved locally."
        } catch {
            credentialMessage = "Could not save the API key locally."
        }
    }

    func removeAPIKey() {
        do {
            try credentialStore.removeAPIKey(for: selectedProvider.rawValue)
            pendingAPIKey = ""
            hasStoredAPIKey = false
            credentialMessage = "API key removed."
        } catch {
            credentialMessage = "Could not remove the local API key."
        }
    }

    func refreshCredentialStatus() {
        do {
            let stored = try credentialStore.apiKey(for: selectedProvider.rawValue)
            hasStoredAPIKey = !(stored?.isEmpty ?? true)
            credentialMessage = nil
        } catch {
            hasStoredAPIKey = false
            credentialMessage = "Could not read the local API key file."
        }
    }

    func addExcludedApplication() {
        let panel = NSOpenPanel()
        panel.title = "Exclude an Application"
        panel.prompt = "Exclude"
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.applicationBundle]

        guard panel.runModal() == .OK,
              let url = panel.url,
              let bundleIdentifier = Bundle(url: url)?.bundleIdentifier,
              !bundleIdentifier.isEmpty else {
            return
        }

        var identifiers = Set(excludedBundleIdentifiers)
        identifiers.insert(bundleIdentifier)
        excludedBundleIdentifiers = Array(identifiers).sorted()
        settings.excludedBundleIdentifiers = identifiers
    }

    func removeExcludedApplication(_ bundleIdentifier: String) {
        var identifiers = Set(excludedBundleIdentifiers)
        identifiers.remove(bundleIdentifier)
        excludedBundleIdentifiers = Array(identifiers).sorted()
        settings.excludedBundleIdentifiers = identifiers
    }

    func displayName(for bundleIdentifier: String) -> String {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) else {
            return bundleIdentifier
        }
        return FileManager.default.displayName(atPath: url.path)
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        launchServiceMessage = nil

        Task { @MainActor in
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try await SMAppService.mainApp.unregister()
                }
                launchAtLogin = SMAppService.mainApp.status == .enabled
            } catch {
                launchAtLogin = SMAppService.mainApp.status == .enabled
                launchServiceMessage = "macOS could not update the login-item setting."
            }
        }
    }
}
