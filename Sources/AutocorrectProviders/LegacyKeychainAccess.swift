import Foundation
import Security

enum LegacyKeychainAccess {
    static let inputMethodExecutableRelativePath = "Library/Input Methods/Autocorrect.app/Contents/MacOS/Autocorrect"
    static let settingsExecutableRelativePath = "Applications/Autocorrect Settings.app/Contents/MacOS/Autocorrect Settings"

    static func trustedExecutablePaths(
        homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser
    ) -> [String] {
        [
            homeDirectory.appendingPathComponent(inputMethodExecutableRelativePath).path,
            homeDirectory.appendingPathComponent(settingsExecutableRelativePath).path
        ]
    }

    static func makeAccess(
        trustedExecutablePaths paths: [String] = trustedExecutablePaths(),
        fileManager: FileManager = .default
    ) throws -> SecAccess {
        guard !paths.isEmpty,
              paths.allSatisfy({ fileManager.fileExists(atPath: $0) }) else {
            throw ProviderCredentialStoreError.unsignedSharingUnavailable
        }

        var trustedApplications: [SecTrustedApplication] = []
        trustedApplications.reserveCapacity(paths.count)

        for path in paths {
            var trustedApplication: SecTrustedApplication?
            let status = path.withCString { cPath in
                SecTrustedApplicationCreateFromPath(cPath, &trustedApplication)
            }

            guard status == errSecSuccess, let trustedApplication else {
                throw ProviderCredentialStoreError.unexpectedStatus(status)
            }

            trustedApplications.append(trustedApplication)
        }

        var access: SecAccess?
        let status = SecAccessCreate(
            "Autocorrect Provider API Key" as CFString,
            trustedApplications as CFArray,
            &access
        )

        guard status == errSecSuccess, let access else {
            throw ProviderCredentialStoreError.unexpectedStatus(status)
        }

        return access
    }
}
