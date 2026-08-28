import Foundation
import Security

enum LegacyKeychainAccess {
    static let inputMethodExecutableRelativePath = "Library/Input Methods/Autocorrect.app/Contents/MacOS/AutocorrectInputMethod"
    static let userApplicationsExecutableRelativePath = "Applications/Autocorrect.app/Contents/MacOS/Autocorrect"
    static let systemApplicationsExecutablePath = "/Applications/Autocorrect.app/Contents/MacOS/Autocorrect"

    static func candidateExecutablePaths(
        homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser
    ) -> [String] {
        [
            homeDirectory.appendingPathComponent(inputMethodExecutableRelativePath).path,
            systemApplicationsExecutablePath,
            homeDirectory.appendingPathComponent(userApplicationsExecutableRelativePath).path
        ]
    }

    static func trustedExecutablePaths(
        homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser,
        fileManager: FileManager = .default
    ) -> [String] {
        candidateExecutablePaths(homeDirectory: homeDirectory)
            .filter { fileManager.fileExists(atPath: $0) }
    }

    static func makeAccess(
        trustedExecutablePaths paths: [String] = trustedExecutablePaths(),
        fileManager: FileManager = .default
    ) throws -> SecAccess {
        let hasInputMethod = paths.contains { $0.hasSuffix(inputMethodExecutableRelativePath) }
        let hasMainApplication = paths.contains { path in
            path == systemApplicationsExecutablePath || path.hasSuffix(userApplicationsExecutableRelativePath)
        }

        guard hasInputMethod,
              hasMainApplication,
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
