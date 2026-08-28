import Foundation

public final class LocalCredentialStore: ProviderCredentialStore, @unchecked Sendable {
    private struct CredentialDocument: Codable {
        var version: Int = 1
        var apiKeys: [String: String] = [:]
    }

    private let fileManager: FileManager
    private let directoryURL: URL
    private let fileURL: URL
    private let lock = NSLock()

    public convenience init(fileManager: FileManager = .default) {
        let applicationSupport = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support", isDirectory: true)

        self.init(
            directoryURL: applicationSupport.appendingPathComponent("Autocorrect", isDirectory: true),
            fileManager: fileManager
        )
    }

    public init(directoryURL: URL, fileManager: FileManager = .default) {
        self.fileManager = fileManager
        self.directoryURL = directoryURL
        self.fileURL = directoryURL.appendingPathComponent("credentials.json", isDirectory: false)
    }

    public var credentialFileURL: URL {
        fileURL
    }

    public func apiKey(for providerIdentifier: String) throws -> String? {
        lock.lock()
        defer { lock.unlock() }

        return try readDocument().apiKeys[providerIdentifier]
    }

    public func setAPIKey(_ apiKey: String, for providerIdentifier: String) throws {
        lock.lock()
        defer { lock.unlock() }

        var document = try readDocument()
        document.apiKeys[providerIdentifier] = apiKey
        try write(document)
    }

    public func removeAPIKey(for providerIdentifier: String) throws {
        lock.lock()
        defer { lock.unlock() }

        var document = try readDocument()
        document.apiKeys.removeValue(forKey: providerIdentifier)

        if document.apiKeys.isEmpty {
            if fileManager.fileExists(atPath: fileURL.path) {
                try fileManager.removeItem(at: fileURL)
            }
            return
        }

        try write(document)
    }

    private func readDocument() throws -> CredentialDocument {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return CredentialDocument()
        }

        let data = try Data(contentsOf: fileURL)
        do {
            return try JSONDecoder().decode(CredentialDocument.self, from: data)
        } catch {
            throw ProviderCredentialStoreError.invalidData
        }
    }

    private func write(_ document: CredentialDocument) throws {
        try fileManager.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true,
            attributes: [.posixPermissions: 0o700]
        )
        try fileManager.setAttributes(
            [.posixPermissions: 0o700],
            ofItemAtPath: directoryURL.path
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(document)
        try data.write(to: fileURL, options: [.atomic])
        try fileManager.setAttributes(
            [.posixPermissions: 0o600],
            ofItemAtPath: fileURL.path
        )
    }
}
