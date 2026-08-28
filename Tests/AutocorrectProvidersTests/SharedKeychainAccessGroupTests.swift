import XCTest
@testable import AutocorrectProviders

final class SharedKeychainAccessGroupTests: XCTestCase {
    func testSelectsTeamPrefixedSharedGroup() {
        let groups = [
            "ABCDE12345.dev.notsonata.autocorrect.settings",
            "ABCDE12345.dev.notsonata.autocorrect.shared"
        ]

        XCTAssertEqual(
            SharedKeychainAccessGroup.select(from: groups),
            "ABCDE12345.dev.notsonata.autocorrect.shared"
        )
    }

    func testIgnoresUnrelatedGroups() {
        XCTAssertNil(
            SharedKeychainAccessGroup.select(from: [
                "ABCDE12345.dev.notsonata.other.shared",
                "group.dev.notsonata.autocorrect.shared-extra"
            ])
        )
    }

    func testAcceptsExactSuffixForUnsignedTestFixtures() {
        XCTAssertEqual(
            SharedKeychainAccessGroup.select(from: [SharedKeychainAccessGroup.suffix]),
            SharedKeychainAccessGroup.suffix
        )
    }
}
