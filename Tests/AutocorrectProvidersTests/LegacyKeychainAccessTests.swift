import XCTest
@testable import AutocorrectProviders

final class LegacyKeychainAccessTests: XCTestCase {
    func testTrustedExecutablePathsUsePerUserInstallLocations() {
        let home = URL(fileURLWithPath: "/Users/example", isDirectory: true)

        XCTAssertEqual(
            LegacyKeychainAccess.trustedExecutablePaths(homeDirectory: home),
            [
                "/Users/example/Library/Input Methods/Autocorrect.app/Contents/MacOS/Autocorrect",
                "/Users/example/Applications/Autocorrect Settings.app/Contents/MacOS/Autocorrect Settings"
            ]
        )
    }
}
