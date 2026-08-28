import XCTest
@testable import AutocorrectProviders

final class OpenAICompatibleCorrectionProviderTests: XCTestCase {
    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        super.tearDown()
    }

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

    func testCorrectionUsesBearerKeyAndStructuredResponse() async throws {
        let credentialStore = InMemoryCredentialStore(values: ["gemini": "test-key"])
        let session = makeMockSession()

        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer test-key")
            XCTAssertEqual(request.cachePolicy, .reloadIgnoringLocalCacheData)

            let body = try requestBodyData(request)
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

            let responseJSON = """
            {
              "choices": [
                {"message": {"content": "{\"replacement\":\"gagawin\"}"}}
              ]
            }
            """
            let response = HTTPURLResponse(
                url: try XCTUnwrap(request.url),
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data(responseJSON.utf8))
        }

        let provider = OpenAICompatibleCorrectionProvider(
            configuration: .init(
                identifier: ProviderPresets.gemini.identifier,
                displayName: ProviderPresets.gemini.displayName,
                baseURL: testBaseURL,
                model: ProviderPresets.gemini.model,
                reasoningEffort: ProviderPresets.gemini.reasoningEffort
            ),
            credentialStore: credentialStore,
            session: session
        )

        let result = try await provider.correct(
            CorrectionRequest(completedWord: "gagwin", leftContext: "ano ang ")
        )
        XCTAssertEqual(result.replacement, "gagawin")
    }

    func testMissingAPIKeyFailsBeforeNetworkRequest() async {
        let credentialStore = InMemoryCredentialStore(values: [:])
        let provider = OpenAICompatibleCorrectionProvider(
            configuration: ProviderPresets.gemini,
            credentialStore: credentialStore,
            session: makeMockSession()
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
        let session = makeMockSession()

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 429,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data("rate limited".utf8))
        }

        let provider = OpenAICompatibleCorrectionProvider(
            configuration: .init(
                identifier: "gemini",
                displayName: "Gemini",
                baseURL: testBaseURL,
                model: "gemini-3.7-flash",
                reasoningEffort: "low"
            ),
            credentialStore: credentialStore,
            session: session
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

    private var testBaseURL: URL {
        URL(string: "https://example.invalid/v1/")!
    }

    private func makeMockSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        configuration.urlCache = nil
        configuration.httpShouldSetCookies = false
        return URLSession(configuration: configuration)
    }
}

private func requestBodyData(_ request: URLRequest) throws -> Data {
    if let body = request.httpBody {
        return body
    }

    guard let stream = request.httpBodyStream else {
        throw URLError(.zeroByteResource)
    }

    stream.open()
    defer { stream.close() }

    var data = Data()
    var buffer = [UInt8](repeating: 0, count: 4096)

    while true {
        let readCount = buffer.withUnsafeMutableBufferPointer { pointer in
            guard let baseAddress = pointer.baseAddress else { return 0 }
            return stream.read(baseAddress, maxLength: pointer.count)
        }

        if readCount < 0 {
            throw stream.streamError ?? URLError(.cannotDecodeContentData)
        }

        if readCount == 0 {
            break
        }

        data.append(contentsOf: buffer.prefix(readCount))
    }

    return data
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

private final class MockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = Self.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
