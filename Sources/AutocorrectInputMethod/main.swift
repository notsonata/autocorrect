import AppKit
import InputMethodKit

private let connectionName = Bundle.main.object(forInfoDictionaryKey: "InputMethodConnectionName") as? String
private let bundleIdentifier = Bundle.main.bundleIdentifier

guard let connectionName, let bundleIdentifier else {
    fatalError("Missing InputMethodKit bundle configuration")
}

NSApplication.shared.setActivationPolicy(.prohibited)
let server = IMKServer(name: connectionName, bundleIdentifier: bundleIdentifier)
_ = server
NSApplication.shared.run()
