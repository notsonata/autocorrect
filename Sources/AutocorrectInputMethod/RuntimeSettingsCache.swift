import AutocorrectSettings
import Foundation

final class RuntimeSettingsCache {
    private let store: SharedAutocorrectSettings
    private let lock = NSLock()
    private var cachedSnapshot: AutocorrectSettingsSnapshot
    private var observer: NSObjectProtocol?

    init(store: SharedAutocorrectSettings = SharedAutocorrectSettings()) {
        self.store = store
        self.cachedSnapshot = store.snapshot()

        observer = DistributedNotificationCenter.default().addObserver(
            forName: SharedAutocorrectSettings.didChangeNotification,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            self?.reload()
        }
    }

    deinit {
        if let observer {
            DistributedNotificationCenter.default().removeObserver(observer)
        }
    }

    var current: AutocorrectSettingsSnapshot {
        lock.lock()
        defer { lock.unlock() }
        return cachedSnapshot
    }

    private func reload() {
        let snapshot = store.snapshot()
        lock.lock()
        cachedSnapshot = snapshot
        lock.unlock()
    }
}
