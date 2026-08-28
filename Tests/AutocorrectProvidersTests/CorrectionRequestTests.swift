import XCTest
@testable import AutocorrectProviders

final class CorrectionRequestTests: XCTestCase {
    func testLeftContextIsBoundedToMostRecentCharacters() {
        let source = String(repeating: "a", count: 300) + "TAIL"
        let request = CorrectionRequest(completedWord: "wrld", leftContext: source)

        XCTAssertEqual(request.leftContext.count, CorrectionRequest.maximumContextCharacters)
        XCTAssertTrue(request.leftContext.hasSuffix("TAIL"))
        XCTAssertEqual(request.completedWord, "wrld")
    }
}
