import Foundation
import XCTest
@testable import AutocorrectProviders

final class OpenAICompatibleEndpointPolicyTests: XCTestCase {
    func testAllowsHTTPSRemoteEndpoint() throws {
        let url = try XCTUnwrap(URL(string: "https://example.com/v1/"))
        XCTAssertTrue(OpenAICompatibleEndpointPolicy.allows(baseURL: url))
    }

    func testRejectsPlainHTTPRemoteEndpoint() throws {
        let url = try XCTUnwrap(URL(string: "http://example.com/v1/"))
        XCTAssertFalse(OpenAICompatibleEndpointPolicy.allows(baseURL: url))
    }

    func testAllowsLoopbackHTTPForLocalProviders() throws {
        let urls = [
            "http://localhost:11434/v1/",
            "http://127.0.0.1:1234/v1/",
            "http://127.0.0.42:8080/v1/",
            "http://[::1]:11434/v1/"
        ]

        for value in urls {
            let url = try XCTUnwrap(URL(string: value))
            XCTAssertTrue(OpenAICompatibleEndpointPolicy.allows(baseURL: url), value)
        }
    }

    func testRejectsNonHTTPProtocols() throws {
        let url = try XCTUnwrap(URL(string: "file:///tmp/v1/"))
        XCTAssertFalse(OpenAICompatibleEndpointPolicy.allows(baseURL: url))
    }
}
