import XCTest
@testable import AutocorrectProviders

final class LocalCredentialStoreTests: XCTestCase {
    private var directoryURL: URL!

    override func setUpWithError() throws {
        try super.setUpWithError()
        directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("AutocorrectCredentialTests-\(UUID().uuidString)", isDirectory: true)
    }

    override func tearDownWithError() throws {
        if let directoryURL {
            try? FileManager.default.removeItem(at: directoryURL)
        }
        directoryURL = nil
        try super.tearDownWithError()
    }

    func testCredentialPersistsAcrossStoreInstances() throws {
        let first = LocalCredentialStore(directoryURL: directoryURL)
        try first.setAPIKey("gemini-secret", for: "gemini")

        let second = LocalCredentialStore(directoryURL: directoryURL)
        XCTAssertEqual(try second.apiKey(for: "gemini"), "gemini-secret")
    }

    func testCredentialFileUsesOwnerOnlyPermissions() throws {
        let store = LocalCredentialStore(directoryURL: directoryURL)
        try store.setAPIKey("secret", for: "gemini")

        let directoryAttributes = try FileManager.default.attributesOfItem(atPath: directoryURL.path)
        let fileAttributes = try FileManager.default.attributesOfItem(atPath: store.credentialFileURL.path)

        let directoryPermissions = (directoryAttributes[.posixPermissions] as? NSNumber)?.intValue
        let filePermissions = (fileAttributes[.posixPermissions] as? NSNumber)?.intValue

        XCTAssertEqual(directoryPermissions.map { $0 & 0o777 }, 0o700)
        XCTAssertEqual(filePermissions.map { $0 & 0o777 }, 0o600)
    }

    func testRemovingLastCredentialDeletesCredentialFile() throws {
        let store = LocalCredentialStore(directoryURL: directoryURL)
        try store.setAPIKey("secret", for: "gemini")
        XCTAssertTrue(FileManager.default.fileExists(atPath: store.credentialFileURL.path))

        try store.removeAPIKey(for: "gemini")

        XCTAssertNil(try store.apiKey(for: "gemini"))
        XCTAssertFalse(FileManager.default.fileExists(atPath: store.credentialFileURL.path))
    }

    func testCredentialsRemainSeparatedByProvider() throws {
        let store = LocalCredentialStore(directoryURL: directoryURL)
        try store.setAPIKey("gemini-key", for: "gemini")
        try store.setAPIKey("openrouter-key", for: "openrouter")

        XCTAssertEqual(try store.apiKey(for: "gemini"), "gemini-key")
        XCTAssertEqual(try store.apiKey(for: "openrouter"), "openrouter-key")
    }

    func testMalformedCredentialFileFailsClosed() throws {
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        let fileURL = directoryURL.appendingPathComponent("credentials.json")
        try Data("not-json".utf8).write(to: fileURL)

        let store = LocalCredentialStore(directoryURL: directoryURL)
        XCTAssertThrowsError(try store.apiKey(for: "gemini")) { error in
            XCTAssertEqual(error as? ProviderCredentialStoreError, .invalidData)
        }
    }
}
