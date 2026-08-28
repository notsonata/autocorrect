import XCTest
@testable import AutocorrectProviders

final class OpenAICompatibleCorrectionProviderTests: XCTestCase {
    func testGeminiPresetUsesGoogleOpenAICompatibilityEndpoint() {
        XCTAssertEqual(
            ProviderPresets.gemini.chatCompletionsURL.absoluteString,
            "https://generativelanguage.googleapis.com/v1beta/openai/chat/completions"
        )
        XCTAssertEqual(ProviderPresets.gemini.model, "gemini-3.7-flash")
        XCTAssertEqual(ProviderPresets.gemini.reasoningEffort, "low")
    }

    func testOpenRouterPresetUsesSameOpenAICompatibleShape() {
        let preset = ProviderPresets.openRouter(model: "google/gemini-3.7-flash")
        XCTAssertEqual(
            preset.chatCompletionsURL.absoluteString,
            "https://openrouter.ai/api/v1/chat/completions"
        )
        XCTAssertEqual(preset.model, "google/gemini-3.7-flash")
    }

    func testRequestUsesBearerKeyAndStructuredBody() throws {
        let provider = OpenAICompatibleCorrectionProvider(
            configuration: ProviderPresets.gemini,
            credentialStore: InMemoryCredentialStore(values: ["gemini": "test-key"])
        )

        let request = try provider.makeURLRequest(
            for: CorrectionRequest(completedWord: "gagwin", leftContext: "ano ang "),
            apiKey: "test-key"
        )

        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer test-key")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
        XCTAssertEqual(request.cachePolicy, .reloadIgnoringLocalCacheData)
        XCTAssertEqual(request.url, ProviderPresets.gemini.chatCompletionsURL)

        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(
            JSONSerialization.jsonObject(with: body) as? [String: Any]
        )
        XCTAssertEqual(json["model"] as? String, "gemini-3.7-flash")
        XCTAssertEqual(json["reasoning_effort"] as? String, "low")

        let responseFormat = try XCTUnwrap(json["response_format"] as? [String: Any])
        XCTAssertEqual(responseFormat["type"] as? String, "json_schema")

        let messages = try XCTUnwrap(json["messages"] as? [[String: Any]])
        XCTAssertEqual(messages.count, 2)
        let userContent = try XCTUnwrap(messages.last?["content"] as? String)
        XCTAssertTrue(userContent.contains("gagwin"))
        XCTAssertTrue(userContent.contains("ano ang"))
    }

    func testCorrectionDecodesStructuredResponse() async throws {
        let credentialStore = InMemoryCredentialStore(values: ["gemini": "test-key"])
        let transport = MockHTTPTransport { request in
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer test-key")

            let responseJSON = """
            {
              "choices": [
                {"message": {"content": "{\"replacement\":\"gagawin\"}"}}
              ]
            }
            """
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (Data(responseJSON.utf8), response)
        }

        let provider = OpenAICompatibleCorrectionProvider(
            configuration: ProviderPresets.gemini,
            credentialStore: credentialStore,
            transport: transport
        )

        let result = try await provider.correct(
            CorrectionRequest(completedWord: "gagwin", leftContext: "ano ang ")
        )
        XCTAssertEqual(result.replacement, "gagawin")
    }

    func testMissingAPIKeyFailsBeforeNetworkRequest() async {
        let credentialStore = InMemoryCredentialStore(values: [:])
        let transport = MockHTTPTransport { _ in
            XCTFail("Transport must not be called without a configured API key")
            throw URLError(.userAuthenticationRequired)
        }
        let provider = OpenAICompatibleCorrectionProvider(
            configuration: ProviderPresets.gemini,
            credentialStore: credentialStore,
            transport: transport
        )

        do {
            _ = try await provider.correct(
                CorrectionRequest(completedWord: "wrld", leftContext: "hello ")
            )
            XCTFail("Expected authentication error")
        } catch let error as CorrectionProviderError {
            XCTAssertEqual(error, .notAuthenticated)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testHTTPFailureDoesNotIncludePromptInError() async {
        let credentialStore = InMemoryCredentialStore(values: ["gemini": "test-key"])
        let transport = MockHTTPTransport { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 429,
                httpVersion: nil,
                headerFields: nil
            )!
            return (Data("rate limited".utf8), response)
        }

        let provider = OpenAICompatibleCorrectionProvider(
            configuration: ProviderPresets.gemini,
            credentialStore: credentialStore,
            transport: transport
        )

        do {
            _ = try await provider.correct(
                CorrectionRequest(completedWord: "privateword", leftContext: "private context ")
            )
            XCTFail("Expected request failure")
        } catch let error as CorrectionProviderError {
            XCTAssertEqual(error, .requestFailed(statusCode: 429))
            XCTAssertFalse(String(describing: error).contains("privateword"))
            XCTAssertFalse(String(describing: error).contains("private context"))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}

private final class InMemoryCredentialStore: ProviderCredentialStore, @unchecked Sendable {
    private var values: [String: String]

    init(values: [String: String]) {
        self.values = values
    }

    func apiKey(for providerIdentifier: String) throws -> String? {
        values[providerIdentifier]
    }

    func setAPIKey(_ apiKey: String, for providerIdentifier: String) throws {
        values[providerIdentifier] = apiKey
    }

    func removeAPIKey(for providerIdentifier: String) throws {
        values.removeValue(forKey: providerIdentifier)
    }
}

private struct MockHTTPTransport: HTTPTransport {
    let handler: @Sendable (URLRequest) throws -> (Data, URLResponse)

    init(handler: @escaping @Sendable (URLRequest) throws -> (Data, URLResponse)) {
        self.handler = handler
    }

    func send(_ request: URLRequest) async throws -> (Data, URLResponse) {
        try handler(request)
    }
}
