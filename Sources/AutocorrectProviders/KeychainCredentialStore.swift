import Foundation
import Security

public protocol ProviderCredentialStore: Sendable {
    func apiKey(for providerIdentifier: String) throws -> String?
    func setAPIKey(_ apiKey: String, for providerIdentifier: String) throws
    func removeAPIKey(for providerIdentifier: String) throws
}

public enum ProviderCredentialStoreError: Error, Equatable {
    case unexpectedStatus(OSStatus)
    case invalidData
    case unsignedSharingUnavailable
}

public final class KeychainCredentialStore: ProviderCredentialStore, @unchecked Sendable {
    private enum StorageMode {
        case sharedDataProtection(accessGroup: String)
        case legacyTrustedApplications
    }

    private let service: String
    private let storageMode: StorageMode

    public init(
        service: String = "dev.notsonata.autocorrect.providers",
        accessGroup: String? = SharedKeychainAccessGroup.current()
    ) {
        self.service = service
        if let accessGroup, !accessGroup.isEmpty {
            self.storageMode = .sharedDataProtection(accessGroup: accessGroup)
        } else {
            self.storageMode = .legacyTrustedApplications
        }
    }

    public func apiKey(for providerIdentifier: String) throws -> String? {
        var query = baseQuery(providerIdentifier: providerIdentifier)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecItemNotFound {
            return nil
        }

        guard status == errSecSuccess else {
            throw ProviderCredentialStoreError.unexpectedStatus(status)
        }

        guard let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            throw ProviderCredentialStoreError.invalidData
        }

        return value
    }

    public func setAPIKey(_ apiKey: String, for providerIdentifier: String) throws {
        let data = Data(apiKey.utf8)
        let query = baseQuery(providerIdentifier: providerIdentifier)

        var updateAttributes: [String: Any] = [
            kSecValueData as String: data
        ]

        if case .sharedDataProtection = storageMode {
            updateAttributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        }

        let updateStatus = SecItemUpdate(query as CFDictionary, updateAttributes as CFDictionary)
        if updateStatus == errSecSuccess {
            return
        }

        guard updateStatus == errSecItemNotFound else {
            throw ProviderCredentialStoreError.unexpectedStatus(updateStatus)
        }

        var insert = query
        insert.merge(updateAttributes) { _, new in new }

        if case .legacyTrustedApplications = storageMode {
            insert[kSecAttrAccess as String] = try LegacyKeychainAccess.makeAccess()
        }

        let addStatus = SecItemAdd(insert as CFDictionary, nil)
        guard addStatus == errSecSuccess else {
            throw ProviderCredentialStoreError.unexpectedStatus(addStatus)
        }
    }

    public func removeAPIKey(for providerIdentifier: String) throws {
        let status = SecItemDelete(baseQuery(providerIdentifier: providerIdentifier) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw ProviderCredentialStoreError.unexpectedStatus(status)
        }
    }

    private func baseQuery(providerIdentifier: String) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: providerIdentifier
        ]

        if case .sharedDataProtection(let accessGroup) = storageMode {
            query[kSecUseDataProtectionKeychain as String] = true
            query[kSecAttrAccessGroup as String] = accessGroup
        }

        return query
    }
}
