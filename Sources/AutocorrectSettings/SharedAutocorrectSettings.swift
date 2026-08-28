import Foundation

public enum CorrectionProviderSelection: String, CaseIterable, Identifiable, Sendable {
    case gemini
    case openRouter
    case custom

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .gemini:
            return "Google Gemini"
        case .openRouter:
            return "OpenRouter"
        case .custom:
            return "Custom OpenAI-compatible"
        }
    }
}

public struct AutocorrectSettingsSnapshot: Equatable, Sendable {
    public let isEnabled: Bool
    public let privacyAcknowledged: Bool
    public let selectedProvider: CorrectionProviderSelection
    public let geminiModel: String
    public let openRouterModel: String
    public let customBaseURL: String
    public let customModel: String
    public let excludedBundleIdentifiers: Set<String>

    public init(
        isEnabled: Bool,
        privacyAcknowledged: Bool,
        selectedProvider: CorrectionProviderSelection,
        geminiModel: String,
        openRouterModel: String,
        customBaseURL: String,
        customModel: String,
        excludedBundleIdentifiers: Set<String>
    ) {
        self.isEnabled = isEnabled
        self.privacyAcknowledged = privacyAcknowledged
        self.selectedProvider = selectedProvider
        self.geminiModel = geminiModel
        self.openRouterModel = openRouterModel
        self.customBaseURL = customBaseURL
        self.customModel = customModel
        self.excludedBundleIdentifiers = excludedBundleIdentifiers
    }

    public var credentialIdentifier: String {
        selectedProvider.rawValue
    }

    public var providerConfigurationSignature: String {
        switch selectedProvider {
        case .gemini:
            return "gemini|\(geminiModel)"
        case .openRouter:
            return "openrouter|\(openRouterModel)"
        case .custom:
            return "custom|\(customBaseURL)|\(customModel)"
        }
    }
}

public final class SharedAutocorrectSettings: @unchecked Sendable {
    public static let suiteName = "dev.notsonata.autocorrect.shared"
    public static let didChangeNotification = Notification.Name(
        "dev.notsonata.autocorrect.settingsChanged"
    )

    private enum Key {
        static let enabled = "enabled"
        static let privacyAcknowledged = "privacyAcknowledged"
        static let selectedProvider = "selectedProvider"
        static let geminiModel = "geminiModel"
        static let openRouterModel = "openRouterModel"
        static let customBaseURL = "customBaseURL"
        static let customModel = "customModel"
        static let excludedBundleIdentifiers = "excludedBundleIdentifiers"
    }

    private let defaults: UserDefaults

    public init(defaults: UserDefaults? = nil) {
        self.defaults = defaults ?? UserDefaults(suiteName: Self.suiteName) ?? .standard
        self.defaults.register(defaults: [
            Key.enabled: false,
            Key.privacyAcknowledged: false,
            Key.selectedProvider: CorrectionProviderSelection.gemini.rawValue,
            Key.geminiModel: "gemini-3.7-flash",
            Key.openRouterModel: "google/gemini-3.7-flash",
            Key.customBaseURL: "",
            Key.customModel: "",
            Key.excludedBundleIdentifiers: [String]()
        ])
    }

    public var isEnabled: Bool {
        get { defaults.bool(forKey: Key.enabled) }
        set { write(newValue, forKey: Key.enabled) }
    }

    public var privacyAcknowledged: Bool {
        get { defaults.bool(forKey: Key.privacyAcknowledged) }
        set { write(newValue, forKey: Key.privacyAcknowledged) }
    }

    public var selectedProvider: CorrectionProviderSelection {
        get {
            let rawValue = defaults.string(forKey: Key.selectedProvider)
            return CorrectionProviderSelection(rawValue: rawValue ?? "") ?? .gemini
        }
        set { write(newValue.rawValue, forKey: Key.selectedProvider) }
    }

    public var geminiModel: String {
        get { defaults.string(forKey: Key.geminiModel) ?? "gemini-3.7-flash" }
        set { write(newValue, forKey: Key.geminiModel) }
    }

    public var openRouterModel: String {
        get { defaults.string(forKey: Key.openRouterModel) ?? "google/gemini-3.7-flash" }
        set { write(newValue, forKey: Key.openRouterModel) }
    }

    public var customBaseURL: String {
        get { defaults.string(forKey: Key.customBaseURL) ?? "" }
        set { write(newValue, forKey: Key.customBaseURL) }
    }

    public var customModel: String {
        get { defaults.string(forKey: Key.customModel) ?? "" }
        set { write(newValue, forKey: Key.customModel) }
    }

    public var excludedBundleIdentifiers: Set<String> {
        get { Set(defaults.stringArray(forKey: Key.excludedBundleIdentifiers) ?? []) }
        set { write(Array(newValue).sorted(), forKey: Key.excludedBundleIdentifiers) }
    }

    public func snapshot() -> AutocorrectSettingsSnapshot {
        defaults.synchronize()
        return AutocorrectSettingsSnapshot(
            isEnabled: isEnabled,
            privacyAcknowledged: privacyAcknowledged,
            selectedProvider: selectedProvider,
            geminiModel: geminiModel,
            openRouterModel: openRouterModel,
            customBaseURL: customBaseURL,
            customModel: customModel,
            excludedBundleIdentifiers: excludedBundleIdentifiers
        )
    }

    private func write(_ value: Any, forKey key: String) {
        defaults.set(value, forKey: key)
        defaults.synchronize()
        DistributedNotificationCenter.default().post(
            name: Self.didChangeNotification,
            object: nil,
            userInfo: nil,
            deliverImmediately: true
        )
    }
}
