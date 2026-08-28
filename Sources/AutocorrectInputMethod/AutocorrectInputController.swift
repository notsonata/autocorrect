import AppKit
import AutocorrectCore
import InputMethodKit

@objc(AutocorrectInputController)
final class AutocorrectInputController: IMKInputController {
    private static let insertionPoint = NSRange(location: NSNotFound, length: NSNotFound)
    private static let prototypeDelay: TimeInterval = 0.8

    override func inputText(_ string: String!, client sender: Any!) -> Bool {
        guard let string, let sender else {
            return false
        }

        let client = sender as AnyObject

        // Ordinary characters are passed through immediately and are never buffered.
        guard string == " " else {
            IMKClientBridge.insert(text: string, replacing: Self.insertionPoint, client: client)
            return true
        }

        // A Space is the first correction boundary. We only inspect surrounding text
        // after the privacy gate positively identifies a non-secure text field.
        let snapshot: WordSnapshot?
        if AccessibilityGate.safeFocusedField() != nil {
            snapshot = WordSnapshot.capture(from: client)
        } else {
            snapshot = nil
        }

        // Never wait for correction work before inserting the boundary character.
        IMKClientBridge.insert(text: string, replacing: Self.insertionPoint, client: client)

        guard let snapshot,
              let replacement = PrototypeCorrectionEngine.correction(for: snapshot.original),
              replacement != snapshot.original else {
            return true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + Self.prototypeDelay) { [weak self] in
            self?.apply(replacement: replacement, to: snapshot)
        }

        return true
    }

    private func apply(replacement: String, to snapshot: WordSnapshot) {
        guard let currentClient = client() else {
            return
        }

        let currentClientObject = currentClient as AnyObject
        guard ObjectIdentifier(currentClientObject) == snapshot.clientID,
              let fieldAccess = AccessibilityGate.safeFocusedField(),
              snapshot.stillMatches(in: currentClientObject) else {
            return
        }

        let selection = IMKClientBridge.selectedRange(client: currentClientObject)
        guard selection.location != NSNotFound,
              selection.length == 0,
              selection.location >= NSMaxRange(snapshot.range),
              fieldAccess.preflightCollapsedSelection(location: selection.location) else {
            return
        }

        let rebasedCaret = SelectionMath.rebasedCaret(
            selection.location,
            replacing: snapshot.range,
            withUTF16Length: replacement.utf16.count
        )

        IMKClientBridge.insert(
            text: replacement,
            replacing: snapshot.range,
            client: currentClientObject
        )

        guard fieldAccess.restoreCollapsedSelection(location: rebasedCaret) else {
            // If the client unexpectedly stops accepting selection writes after the
            // mutation, roll back instead of knowingly leaving a displaced caret.
            let replacementRange = NSRange(
                location: snapshot.range.location,
                length: replacement.utf16.count
            )
            IMKClientBridge.insert(
                text: snapshot.original,
                replacing: replacementRange,
                client: currentClientObject
            )
            _ = fieldAccess.restoreCollapsedSelection(location: selection.location)
            return
        }
    }
}
