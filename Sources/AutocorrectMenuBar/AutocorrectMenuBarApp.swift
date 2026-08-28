import SwiftUI

@main
struct AutocorrectMenuBarApp: App {
    @StateObject private var model = SettingsViewModel()

    var body: some Scene {
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

        Settings {
            SettingsView(model: model)
                .frame(width: 560, height: 610)
        }
    }
}

private struct MenuContentView: View {
    @ObservedObject var model: SettingsViewModel
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        Toggle("Autocorrect", isOn: $model.isEnabled)
            .disabled(!model.privacyAcknowledged)

        Text("Provider: \(model.selectedProvider.displayName)")

        if !model.privacyAcknowledged {
            Text("Privacy acknowledgment required")
        }

        Divider()

        Button("Settings…") {
            openSettings()
        }

        Divider()

        Button("Quit Autocorrect") {
            NSApplication.shared.terminate(nil)
        }
    }
}
