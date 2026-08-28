import Foundation

public struct OpenAICompatibleProviderConfiguration: Sendable, Equatable {
    public let identifier: String
    public let displayName: String
    public let baseURL: URL
    public let model: String
    public let reasoningEffort: String?

    public init(
        identifier: String,
        displayName: String,
        baseURL: URL,
        model: String,
        reasoningEffort: String? = nil
    ) {
        self.identifier = identifier
        self.displayName = displayName
        self.baseURL = baseURL
        self.model = model
        self.reasoningEffort = reasoningEffort
    }

    public var chatCompletionsURL: URL {
        baseURL
            .appendingPathComponent("chat")
            .appendingPathComponent("completions")
    }
}

public enum ProviderPresets {
    public static let gemini = OpenAICompatibleProviderConfiguration(
        identifier: "gemini",
        displayName: "Google Gemini",
        baseURL: URL(string: "https://generativelanguage.googleapis.com/v1beta/openai/")!,
        model: "gemini-3.7-flash",
        reasoningEffort: "low"
    )

    public static func openRouter(model: String) -> OpenAICompatibleProviderConfiguration {
        OpenAICompatibleProviderConfiguration(
            identifier: "openrouter",
            displayName: "OpenRouter",
            baseURL: URL(string: "https://openrouter.ai/api/v1/")!,
            model: model
        )
    }

    public static func custom(
        identifier: String,
        displayName: String,
        baseURL: URL,
        model: String,
        reasoningEffort: String? = nil
    ) -> OpenAICompatibleProviderConfiguration {
        OpenAICompatibleProviderConfiguration(
            identifier: identifier,
            displayName: displayName,
            baseURL: baseURL,
            model: model,
            reasoningEffort: reasoningEffort
        )
    }
}
