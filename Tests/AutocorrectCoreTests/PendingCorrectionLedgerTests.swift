import XCTest
@testable import AutocorrectCore

final class PendingCorrectionLedgerTests: XCTestCase {
    func testEarlierLongerCorrectionRebasesLaterJob() throws {
        var ledger = PendingCorrectionLedger()
        let first = ledger.register(
            original: "thnk",
            range: NSRange(location: 2, length: 4)
        )
        let second = ledger.register(
            original: "taht",
            range: NSRange(location: 7, length: 4)
        )

        ledger.commit(first, replacementUTF16Length: 5)

        let rebasedSecond = try XCTUnwrap(ledger.job(for: second))
        XCTAssertEqual(rebasedSecond.range, NSRange(location: 8, length: 4))
    }

    func testLaterCorrectionCanCommitBeforeEarlierJob() throws {
        var ledger = PendingCorrectionLedger()
        let first = ledger.register(
            original: "wrld",
            range: NSRange(location: 0, length: 4)
        )
        let second = ledger.register(
            original: "shoud",
            range: NSRange(location: 5, length: 5)
        )

        ledger.commit(second, replacementUTF16Length: 6)

        let unchangedFirst = try XCTUnwrap(ledger.job(for: first))
        XCTAssertEqual(unchangedFirst.range, NSRange(location: 0, length: 4))
    }

    func testInsertionBeforePendingWordShiftsItsRange() throws {
        var ledger = PendingCorrectionLedger()
        let id = ledger.register(
            original: "wrld",
            range: NSRange(location: 10, length: 4)
        )

        ledger.recordMutation(
            TextMutation(
                range: NSRange(location: 3, length: 0),
                replacementUTF16Length: 2
            )
        )

        let job = try XCTUnwrap(ledger.job(for: id))
        XCTAssertEqual(job.range, NSRange(location: 12, length: 4))
    }

    func testInsertionAfterPendingWordLeavesItsRangeUnchanged() throws {
        var ledger = PendingCorrectionLedger()
        let id = ledger.register(
            original: "wrld",
            range: NSRange(location: 10, length: 4)
        )

        ledger.recordMutation(
            TextMutation(
                range: NSRange(location: 15, length: 0),
                replacementUTF16Length: 1
            )
        )

        let job = try XCTUnwrap(ledger.job(for: id))
        XCTAssertEqual(job.range, NSRange(location: 10, length: 4))
    }

    func testInsertionAtPendingWordEdgeCancelsCorrection() {
        var ledger = PendingCorrectionLedger()
        let id = ledger.register(
            original: "wrld",
            range: NSRange(location: 10, length: 4)
        )

        ledger.recordMutation(
            TextMutation(
                range: NSRange(location: 14, length: 0),
                replacementUTF16Length: 1
            )
        )

        XCTAssertNil(ledger.job(for: id))
    }

    func testOverlappingUserEditCancelsPendingCorrection() {
        var ledger = PendingCorrectionLedger()
        let id = ledger.register(
            original: "wrld",
            range: NSRange(location: 10, length: 4)
        )

        ledger.recordMutation(
            TextMutation(
                range: NSRange(location: 12, length: 1),
                replacementUTF16Length: 2
            )
        )

        XCTAssertNil(ledger.job(for: id))
        XCTAssertEqual(ledger.count, 0)
    }

    func testCancelAllPurgesPendingWords() {
        var ledger = PendingCorrectionLedger()
        _ = ledger.register(original: "wrld", range: NSRange(location: 0, length: 4))
        _ = ledger.register(original: "shoud", range: NSRange(location: 5, length: 5))

        ledger.cancelAll()

        XCTAssertEqual(ledger.count, 0)
    }
}
