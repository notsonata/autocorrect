import Foundation

protocol HTTPTransport: Sendable {
    func send(_ request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: HTTPTransport {
    func send(_ request: URLRequest) async throws -> (Data, URLResponse) {
        try await data(for: request)
    }
}

public final class OpenAICompatibleCorrectionProvider: CorrectionProvider, @unchecked Sendable {
    public let identifier: String

    private let configuration: OpenAICompatibleProviderConfiguration
    private let credentialStore: ProviderCredentialStore
    private let transport: any HTTPTransport

    public init(
        configuration: OpenAICompatibleProviderConfiguration,
        credentialStore: ProviderCredentialStore,
        session: URLSession? = nil
    ) {
        self.identifier = configuration.identifier
        self.configuration = configuration
        self.credentialStore = credentialStore
        self.transport = session ?? Self.makeEphemeralSession()
    }

    init(
        configuration: OpenAICompatibleProviderConfiguration,
        credentialStore: ProviderCredentialStore,
        transport: any HTTPTransport
    ) {
        self.identifier = configuration.identifier
        self.configuration = configuration
        self.credentialStore = credentialStore
        self.transport = transport
    }

    public func correct(_ request: CorrectionRequest) async throws -> CorrectionResponse {
        guard let apiKey = try credentialStore.apiKey(for: configuration.identifier),
              !apiKey.isEmpty else {
            throw CorrectionProviderError.notAuthenticated
        }

        let urlRequest = try makeURLRequest(for: request, apiKey: apiKey)
        let (data, response) = try await transport.send(urlRequest)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CorrectionProviderError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw CorrectionProviderError.requestFailed(statusCode: httpResponse.statusCode)
        }

        let completion: ChatCompletionResponse
        do {
            completion = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
        } catch {
            throw CorrectionProviderError.invalidResponse
        }

        guard let content = completion.choices.first?.message.content,
              !content.isEmpty else {
            throw CorrectionProviderError.emptyResponse
        }

        let payload: CorrectionPayload
        do {
            payload = try JSONDecoder().decode(CorrectionPayload.self, from: Data(content.utf8))
        } catch {
            throw CorrectionProviderError.invalidResponse
        }

        return CorrectionResponse(replacement: payload.replacement)
    }

    /// Kept internal so tests can inspect the complete wire request without sending it.
    /// No typed text is logged or persisted here.
    func makeURLRequest(for request: CorrectionRequest, apiKey: String) throws -> URLRequest {
        var urlRequest = URLRequest(url: configuration.chatCompletionsURL)
        urlRequest.httpMethod = "POST"
        urlRequest.cachePolicy = .reloadIgnoringLocalCacheData
        urlRequest.timeoutInterval = 4
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.httpBody = try JSONEncoder().encode(
            ChatCompletionRequest(
                model: configuration.model,
                reasoningEffort: configuration.reasoningEffort,
                messages: [
                    .init(role: "system", content: Self.systemPrompt),
                    .init(role: "user", content: request.providerInput)
                ],
                responseFormat: .correctionSchema
            )
        )
        return urlRequest
    }

    private static func makeEphemeralSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.urlCache = nil
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.httpShouldSetCookies = false
        configuration.timeoutIntervalForRequest = 4
        configuration.timeoutIntervalForResource = 5
        configuration.waitsForConnectivity = false
        return URLSession(configuration: configuration)
    }

    private static let systemPrompt = """
    You are a conservative autocorrect engine for English, Filipino, and Taglish.
    Correct only the completed word using the preceding context for disambiguation.
    Fix clear spelling or typographical errors. Preserve valid words, slang, abbreviations,
    code-switching, capitalization style, names, and informal tone. Never translate between
    English and Filipino. Never rewrite surrounding text. If the completed word is already
    acceptable, return it unchanged.
    """
}

private extension CorrectionRequest {
    var providerInput: String {
        let payload: [String: String] = [
            "left_context": leftContext,
            "completed_word": completedWord
        ]

        guard let data = try? JSONSerialization.data(withJSONObject: payload),
              let string = String(data: data, encoding: .utf8) else {
            return completedWord
        }

        return string
    }
}

private struct ChatCompletionRequest: Encodable {
    let model: String
    let reasoningEffort: String?
    let messages: [Message]
    let responseFormat: ResponseFormat

    enum CodingKeys: String, CodingKey {
        case model
        case reasoningEffort = "reasoning_effort"
        case messages
        case responseFormat = "response_format"
    }

    struct Message: Encodable {
        let role: String
        let content: String
    }

    struct ResponseFormat: Encodable {
        let type: String
        let jsonSchema: JSONSchema

        enum CodingKeys: String, CodingKey {
            case type
            case jsonSchema = "json_schema"
        }

        static let correctionSchema = ResponseFormat(
            type: "json_schema",
            jsonSchema: JSONSchema(
                name: "autocorrect_word",
                strict: true,
                schema: Schema(
                    type: "object",
                    properties: ["replacement": Property(type: "string")],
                    required: ["replacement"],
                    additionalProperties: false
                )
            )
        )
    }

    struct JSONSchema: Encodable {
        let name: String
        let strict: Bool
        let schema: Schema
    }

    struct Schema: Encodable {
        let type: String
        let properties: [String: Property]
        let required: [String]
        let additionalProperties: Bool

        enum CodingKeys: String, CodingKey {
            case type
            case properties
            case required
            case additionalProperties = "additionalProperties"
        }
    }

    struct Property: Encodable {
        let type: String
    }
}

private struct ChatCompletionResponse: Decodable {
    let choices: [Choice]

    struct Choice: Decodable {
        let message: Message
    }

    struct Message: Decodable {
        let content: String?
    }
}

private struct CorrectionPayload: Decodable {
    let replacement: String
}
