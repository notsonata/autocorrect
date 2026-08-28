import AppKit
import SwiftUI

@main
struct AutocorrectInstallerApp: App {
    @StateObject private var model = InstallerViewModel()

    var body: some Scene {
        WindowGroup("Autocorrect Installer") {
            InstallerView(model: model)
                .frame(width: 520, height: 330)
        }
        .windowResizability(.contentSize)
    }
}

private struct InstallerView: View {
    @ObservedObject var model: InstallerViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Autocorrect")
                .font(.largeTitle.bold())

            Text("Install the input method and menu-bar settings app for the current user. No administrator password is required.")
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 6) {
                Label("~/Library/Input Methods/Autocorrect.app", systemImage: "keyboard")
                Label("~/Applications/Autocorrect Settings.app", systemImage: "gearshape")
            }
            .font(.callout.monospaced())

            Spacer()

            if let status = model.statusMessage {
                Text(status)
                    .font(.callout)
                    .foregroundStyle(model.statusIsError ? Color.red : Color.secondary)
            }

            HStack {
                Button("Uninstall", role: .destructive) {
                    model.uninstall()
                }

                Spacer()

                Button("Install Autocorrect") {
                    model.install()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
    }
}

@MainActor
private final class InstallerViewModel: ObservableObject {
    private enum InstallerError: LocalizedError {
        case missingSource(String)
        case unexpectedBundle(String)

        var errorDescription: String? {
            switch self {
            case .missingSource(let name):
                return "Missing \(name). Keep the installer beside both Autocorrect app bundles."
            case .unexpectedBundle(let name):
                return "The bundled identifier for \(name) is not the expected Autocorrect identifier."
            }
        }
    }

    @Published var statusMessage: String?
    @Published var statusIsError = false

    private let fileManager = FileManager.default
    private let inputBundleIdentifier = "dev.notsonata.autocorrect.inputmethod"
    private let settingsBundleIdentifier = "dev.notsonata.autocorrect.settings"

    private var packageDirectory: URL {
        Bundle.main.bundleURL.deletingLastPathComponent()
    }

    private var inputSource: URL {
        packageDirectory.appendingPathComponent("Autocorrect.app", isDirectory: true)
    }

    private var settingsSource: URL {
        packageDirectory.appendingPathComponent("Autocorrect Settings.app", isDirectory: true)
    }

    private var inputDestination: URL {
        fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Input Methods/Autocorrect.app", isDirectory: true)
    }

    private var settingsDestination: URL {
        fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent("Applications/Autocorrect Settings.app", isDirectory: true)
    }

    func install() {
        do {
            try validateSource(inputSource, expectedIdentifier: inputBundleIdentifier)
            try validateSource(settingsSource, expectedIdentifier: settingsBundleIdentifier)
            terminateInstalledApps()
            try replaceItem(at: inputDestination, with: inputSource)
            try replaceItem(at: settingsDestination, with: settingsSource)

            statusIsError = false
            statusMessage = "Installed. Enable Autocorrect in System Settings > Keyboard > Text Input > Edit, then configure the menu-bar app."
            _ = NSWorkspace.shared.open(settingsDestination)
        } catch {
            statusIsError = true
            statusMessage = error.localizedDescription
        }
    }

    func uninstall() {
        do {
            terminateInstalledApps()
            try removeIfPresent(inputDestination)
            try removeIfPresent(settingsDestination)
            statusIsError = false
            statusMessage = "Removed both apps. Preferences and Keychain credentials were left in place intentionally."
        } catch {
            statusIsError = true
            statusMessage = error.localizedDescription
        }
    }

    private func validateSource(_ url: URL, expectedIdentifier: String) throws {
        guard fileManager.fileExists(atPath: url.path) else {
            throw InstallerError.missingSource(url.lastPathComponent)
        }

        guard Bundle(url: url)?.bundleIdentifier == expectedIdentifier else {
            throw InstallerError.unexpectedBundle(url.lastPathComponent)
        }
    }

    private func replaceItem(at destination: URL, with source: URL) throws {
        try fileManager.createDirectory(
            at: destination.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try removeIfPresent(destination)
        try fileManager.copyItem(at: source, to: destination)
    }

    private func removeIfPresent(_ url: URL) throws {
        guard fileManager.fileExists(atPath: url.path) else { return }
        try fileManager.removeItem(at: url)
    }

    private func terminateInstalledApps() {
        NSRunningApplication.runningApplications(withBundleIdentifier: settingsBundleIdentifier)
            .forEach { $0.terminate() }
        NSRunningApplication.runningApplications(withBundleIdentifier: inputBundleIdentifier)
            .forEach { $0.terminate() }
    }
}
