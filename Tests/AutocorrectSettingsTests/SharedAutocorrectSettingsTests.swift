import XCTest
@testable import AutocorrectSettings

final class SharedAutocorrectSettingsTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        suiteName = "dev.notsonata.autocorrect.tests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        suiteName = nil
        super.tearDown()
    }

    func testDefaultsFailClosed() {
        let store = SharedAutocorrectSettings(defaults: defaults)
        let snapshot = store.snapshot()

        XCTAssertFalse(snapshot.isEnabled)
        XCTAssertFalse(snapshot.privacyAcknowledged)
        XCTAssertEqual(snapshot.selectedProvider, .gemini)
        XCTAssertEqual(snapshot.geminiModel, "gemini-3.7-flash")
        XCTAssertTrue(snapshot.excludedBundleIdentifiers.isEmpty)
    }

    func testRoundTripsNonSensitiveConfiguration() {
        let store = SharedAutocorrectSettings(defaults: defaults)
        store.privacyAcknowledged = true
        store.isEnabled = true
        store.selectedProvider = .openRouter
        store.openRouterModel = "anthropic/claude-sonnet-4.6"
        store.excludedBundleIdentifiers = ["com.apple.Terminal", "com.mitchellh.ghostty"]

        let snapshot = store.snapshot()
        XCTAssertTrue(snapshot.isEnabled)
        XCTAssertTrue(snapshot.privacyAcknowledged)
        XCTAssertEqual(snapshot.selectedProvider, .openRouter)
        XCTAssertEqual(snapshot.selectedProvider.rawValue, "openrouter")
        XCTAssertEqual(snapshot.credentialIdentifier, "openrouter")
        XCTAssertEqual(snapshot.openRouterModel, "anthropic/claude-sonnet-4.6")
        XCTAssertEqual(
            snapshot.excludedBundleIdentifiers,
            ["com.apple.Terminal", "com.mitchellh.ghostty"]
        )
    }

    func testProviderSignatureTracksSelectedConfiguration() {
        let gemini = AutocorrectSettingsSnapshot(
            isEnabled: true,
            privacyAcknowledged: true,
            selectedProvider: .gemini,
            geminiModel: "gemini-3.7-flash",
            openRouterModel: "unused",
            customBaseURL: "",
            customModel: "",
            excludedBundleIdentifiers: []
        )
        let changedModel = AutocorrectSettingsSnapshot(
            isEnabled: true,
            privacyAcknowledged: true,
            selectedProvider: .gemini,
            geminiModel: "gemini-3.6-flash",
            openRouterModel: "unused",
            customBaseURL: "",
            customModel: "",
            excludedBundleIdentifiers: []
        )

        XCTAssertNotEqual(
            gemini.providerConfigurationSignature,
            changedModel.providerConfigurationSignature
        )
    }
}
