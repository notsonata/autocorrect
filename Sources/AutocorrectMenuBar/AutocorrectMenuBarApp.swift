import AppKit
import SwiftUI

@main
struct AutocorrectApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var model = SettingsViewModel()

    var body: some Scene {
        WindowGroup("Autocorrect", id: "settings") {
            SettingsView(model: model)
                .frame(width: 560, height: 690)
                .onAppear {
                    NSApplication.shared.activate(ignoringOtherApps: true)
                }
        }
        .windowResizability(.contentSize)

        MenuBarExtra {
            MenuContentView(model: model)
        } label: {
            Label(
                "Autocorrect",
                systemImage: model.isEnabled && model.privacyAcknowledged
                    ? "checkmark.circle.fill"
                    : "checkmark.circle"
            )
        }
        .menuBarExtraStyle(.menu)
    }
}

private struct MenuContentView: View {
    @ObservedObject var model: SettingsViewModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Toggle("Autocorrect", isOn: $model.isEnabled)
            .disabled(!model.privacyAcknowledged || !model.inputMethodInstalled)

        Text("Provider: \(model.selectedProvider.displayName)")

        if !model.inputMethodInstalled {
            Text("Input method needs installation")
        } else if !model.privacyAcknowledged {
            Text("Privacy acknowledgment required")
        }

        Divider()

        Button("Settings…") {
            NSApplication.shared.activate(ignoringOtherApps: true)
            openWindow(id: "settings")
        }

        Divider()

        Button("Quit Autocorrect") {
            NSApplication.shared.terminate(nil)
        }
    }
}
