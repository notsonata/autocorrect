import XCTest
@testable import AutocorrectCore

final class SelectionMathTests: XCTestCase {
    func testCaretAfterLongerReplacementMovesByDelta() {
        let result = SelectionMath.rebasedCaret(
            20,
            replacing: NSRange(location: 4, length: 5),
            withUTF16Length: 6
        )
        XCTAssertEqual(result, 21)
    }

    func testCaretAfterShorterReplacementMovesBackByDelta() {
        let result = SelectionMath.rebasedCaret(
            20,
            replacing: NSRange(location: 4, length: 6),
            withUTF16Length: 4
        )
        XCTAssertEqual(result, 18)
    }

    func testCaretBeforeReplacementDoesNotMove() {
        let result = SelectionMath.rebasedCaret(
            3,
            replacing: NSRange(location: 4, length: 5),
            withUTF16Length: 6
        )
        XCTAssertEqual(result, 3)
    }

    func testInvalidReplacementRangeDoesNotMoveCaret() {
        let result = SelectionMath.rebasedCaret(
            20,
            replacing: NSRange(location: NSNotFound, length: 0),
            withUTF16Length: 6
        )
        XCTAssertEqual(result, 20)
    }
}
