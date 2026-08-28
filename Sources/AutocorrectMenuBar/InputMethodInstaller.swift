import AppKit
import Foundation

enum InputMethodInstallerError: LocalizedError {
    case embeddedInputMethodMissing
    case unexpectedBundleIdentifier

    var errorDescription: String? {
        switch self {
        case .embeddedInputMethodMissing:
            return "The embedded Autocorrect input method is missing from this application."
        case .unexpectedBundleIdentifier:
            return "The embedded input method has an unexpected bundle identifier."
        }
    }
}

struct InputMethodInstaller {
    static let inputMethodBundleIdentifier = "dev.notsonata.autocorrect.inputmethod"

    private let fileManager: FileManager
    private let appBundle: Bundle

    init(
        fileManager: FileManager = .default,
        appBundle: Bundle = .main
    ) {
        self.fileManager = fileManager
        self.appBundle = appBundle
    }

    var destinationURL: URL {
        fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Input Methods/Autocorrect.app", isDirectory: true)
    }

    func installIfNeeded() throws -> Bool {
        let source = try embeddedInputMethodURL()

        if isCurrentInstallation(source: source, destination: destinationURL) {
            return false
        }

        try install(source: source, destination: destinationURL)
        return true
    }

    func reinstall() throws {
        let source = try embeddedInputMethodURL()
        try install(source: source, destination: destinationURL)
    }

    func isInstalled() -> Bool {
        guard fileManager.fileExists(atPath: destinationURL.path),
              let bundle = Bundle(url: destinationURL) else {
            return false
        }
        return bundle.bundleIdentifier == Self.inputMethodBundleIdentifier
    }

    private func embeddedInputMethodURL() throws -> URL {
        guard let resources = appBundle.resourceURL else {
            throw InputMethodInstallerError.embeddedInputMethodMissing
        }

        let source = resources
            .appendingPathComponent("InputMethod", isDirectory: true)
            .appendingPathComponent("Autocorrect.app", isDirectory: true)

        guard fileManager.fileExists(atPath: source.path),
              let bundle = Bundle(url: source) else {
            throw InputMethodInstallerError.embeddedInputMethodMissing
        }

        guard bundle.bundleIdentifier == Self.inputMethodBundleIdentifier else {
            throw InputMethodInstallerError.unexpectedBundleIdentifier
        }

        return source
    }

    private func isCurrentInstallation(source: URL, destination: URL) -> Bool {
        guard fileManager.fileExists(atPath: destination.path),
              let sourceBundle = Bundle(url: source),
              let destinationBundle = Bundle(url: destination),
              destinationBundle.bundleIdentifier == Self.inputMethodBundleIdentifier else {
            return false
        }

        let sourceVersion = sourceBundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        let sourceBuild = sourceBundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String
        let destinationVersion = destinationBundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        let destinationBuild = destinationBundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String

        return sourceVersion == destinationVersion && sourceBuild == destinationBuild
    }

    private func install(source: URL, destination: URL) throws {
        NSRunningApplication
            .runningApplications(withBundleIdentifier: Self.inputMethodBundleIdentifier)
            .forEach { $0.terminate() }

        let parent = destination.deletingLastPathComponent()
        try fileManager.createDirectory(
            at: parent,
            withIntermediateDirectories: true
        )

        let temporary = parent.appendingPathComponent(
            ".Autocorrect-Installing-\(UUID().uuidString).app",
            isDirectory: true
        )

        if fileManager.fileExists(atPath: temporary.path) {
            try fileManager.removeItem(at: temporary)
        }

        do {
            try fileManager.copyItem(at: source, to: temporary)
            if fileManager.fileExists(atPath: destination.path) {
                try fileManager.removeItem(at: destination)
            }
            try fileManager.moveItem(at: temporary, to: destination)
        } catch {
            try? fileManager.removeItem(at: temporary)
            throw error
        }
    }
}
