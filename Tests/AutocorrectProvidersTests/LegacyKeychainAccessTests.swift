import XCTest
@testable import AutocorrectProviders

final class LegacyKeychainAccessTests: XCTestCase {
    func testCandidatePathsCoverInputMethodAndNormalApplicationLocations() {
        let home = URL(fileURLWithPath: "/Users/example", isDirectory: true)

        XCTAssertEqual(
            LegacyKeychainAccess.candidateExecutablePaths(homeDirectory: home),
            [
                "/Users/example/Library/Input Methods/Autocorrect.app/Contents/MacOS/AutocorrectInputMethod",
                "/Applications/Autocorrect.app/Contents/MacOS/Autocorrect",
                "/Users/example/Applications/Autocorrect.app/Contents/MacOS/Autocorrect"
            ]
        )
    }
}
