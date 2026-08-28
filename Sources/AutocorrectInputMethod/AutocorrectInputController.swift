import AppKit
import AutocorrectCore
import InputMethodKit

@objc(AutocorrectInputController)
final class AutocorrectInputController: IMKInputController {
    private static let insertionPoint = NSRange(location: NSNotFound, length: NSNotFound)

    private var activeClientID: ObjectIdentifier?
    private var pendingCorrections = PendingCorrectionLedger()

    override func inputText(_ string: String!, client sender: Any!) -> Bool {
        guard let string, let sender else {
            return false
        }

        let client = sender as AnyObject
        let clientID = ObjectIdentifier(client)
        synchronizeSession(with: clientID)

        let isBoundary = WordBoundaryDetector.triggersCorrection(for: string)

        // Ordinary input is never text-inspected. We only track its document mutation
        // so outstanding correction ranges can stay anchored while the user types.
        guard isBoundary else {
            let selectionBeforeInsertion = IMKClientBridge.selectedRange(client: client)
            IMKClientBridge.insert(text: string, replacing: Self.insertionPoint, client: client)
            recordUserMutation(
                replacing: selectionBeforeInsertion,
                withUTF16Length: string.utf16.count
            )
            return true
        }

        // A correction boundary is the only point where surrounding text is inspected.
        // Fail closed before reading it if the focused field is secure or unverifiable.
        guard AccessibilityGate.safeFocusedField() != nil else {
            pendingCorrections.cancelAll()
            IMKClientBridge.insert(text: string, replacing: Self.insertionPoint, client: client)
            return true
        }

        let selectionBeforeInsertion = IMKClientBridge.selectedRange(client: client)
        let snapshot = WordSnapshot.capture(from: client)

        // The boundary reaches the client immediately. No correction work blocks typing.
        IMKClientBridge.insert(text: string, replacing: Self.insertionPoint, client: client)
        recordUserMutation(
            replacing: selectionBeforeInsertion,
            withUTF16Length: string.utf16.count
        )

        guard let snapshot,
              let plan = PrototypeCorrectionEngine.correction(for: snapshot.original),
              plan.replacement != snapshot.original else {
            return true
        }

        let correctionID = pendingCorrections.register(
            original: snapshot.original,
            range: snapshot.range
        )

        DispatchQueue.main.asyncAfter(deadline: .now() + plan.delay) { [weak self] in
            self?.apply(
                replacement: plan.replacement,
                correctionID: correctionID,
                expectedClientID: clientID
            )
        }

        return true
    }

    private func synchronizeSession(with clientID: ObjectIdentifier) {
        guard activeClientID != clientID else {
            return
        }

        pendingCorrections.cancelAll()
        activeClientID = clientID
    }

    private func recordUserMutation(replacing range: NSRange, withUTF16Length newLength: Int) {
        guard range.location != NSNotFound else {
            // We cannot safely rebase pending jobs around an unknown edit location.
            pendingCorrections.cancelAll()
            return
        }

        pendingCorrections.recordMutation(
            TextMutation(range: range, replacementUTF16Length: newLength)
        )
    }

    private func apply(
        replacement: String,
        correctionID: PendingCorrectionID,
        expectedClientID: ObjectIdentifier
    ) {
        guard let currentClient = client() else {
            pendingCorrections.cancel(correctionID)
            return
        }

        let currentClientObject = currentClient as AnyObject
        let currentClientID = ObjectIdentifier(currentClientObject)
        guard currentClientID == expectedClientID,
              activeClientID == expectedClientID else {
            pendingCorrections.cancel(correctionID)
            return
        }

        // Re-check the privacy boundary at completion time because focus may have moved
        // into a password or secure field while the asynchronous job was pending.
        guard let fieldAccess = AccessibilityGate.safeFocusedField() else {
            pendingCorrections.cancelAll()
            return
        }

        guard let job = pendingCorrections.job(for: correctionID) else {
            return
        }

        guard IMKClientBridge.string(range: job.range, client: currentClientObject) == job.original else {
            // Unknown edits, mouse-driven changes, or another text system may have
            // touched the document. Never search for a replacement target elsewhere.
            pendingCorrections.cancel(correctionID)
            return
        }

        let selection = IMKClientBridge.selectedRange(client: currentClientObject)
        guard selection.location != NSNotFound,
              selection.length == 0,
              !caretIsInside(selection.location, range: job.range),
              fieldAccess.preflightCollapsedSelection(location: selection.location) else {
            pendingCorrections.cancel(correctionID)
            return
        }

        let rebasedCaret = SelectionMath.rebasedCaret(
            selection.location,
            replacing: job.range,
            withUTF16Length: replacement.utf16.count
        )

        IMKClientBridge.insert(
            text: replacement,
            replacing: job.range,
            client: currentClientObject
        )

        guard fieldAccess.restoreCollapsedSelection(location: rebasedCaret) else {
            // The ledger is intentionally not committed until cursor restoration
            // succeeds, so a rollback leaves every outstanding range unchanged.
            let replacementRange = NSRange(
                location: job.range.location,
                length: replacement.utf16.count
            )
            IMKClientBridge.insert(
                text: job.original,
                replacing: replacementRange,
                client: currentClientObject
            )
            _ = fieldAccess.restoreCollapsedSelection(location: selection.location)
            pendingCorrections.cancel(correctionID)
            return
        }

        pendingCorrections.commit(
            correctionID,
            replacementUTF16Length: replacement.utf16.count
        )
    }

    private func caretIsInside(_ caret: Int, range: NSRange) -> Bool {
        caret > range.location && caret < NSMaxRange(range)
    }
}
