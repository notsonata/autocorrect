import AppKit
import OSLog

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let logger = Logger(subsystem: "dev.notsonata.autocorrect", category: "startup")
    private var windowCloseObserver: NSObjectProtocol?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate(ignoringOtherApps: true)

        windowCloseObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: nil,
            queue: .main
        ) { _ in
            DispatchQueue.main.async {
                guard !NSApplication.shared.windows.contains(where: { window in
                    window.isVisible && window.canBecomeMain
                }) else {
                    return
                }

                // Closing the settings window should leave Autocorrect running as
                // a menu-bar utility instead of keeping an unnecessary Dock icon.
                NSApplication.shared.setActivationPolicy(.accessory)
            }
        }

        logger.info("Autocorrect application finished launching")
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    deinit {
        if let windowCloseObserver {
            NotificationCenter.default.removeObserver(windowCloseObserver)
        }
    }
}
