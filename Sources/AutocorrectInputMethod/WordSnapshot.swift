import AppKit

struct WordSnapshot {
    let original: String
    let range: NSRange
    let clientID: ObjectIdentifier

    static func capture(from client: NSTextInputClient, clientObject: AnyObject) -> WordSnapshot? {
        let selection = client.selectedRange()
        guard selection.location != NSNotFound,
              selection.length == 0,
              selection.location > 0 else {
            return nil
        }

        let probeLength = min(selection.location, 128)
        let proposedRange = NSRange(
            location: selection.location - probeLength,
            length: probeLength
        )

        var actualRange = NSRange(location: NSNotFound, length: 0)
        guard let attributed = client.attributedSubstring(
            forProposedRange: proposedRange,
            actualRange: &actualRange
        ), actualRange.location != NSNotFound else {
            return nil
        }

        let text = attributed.string as NSString
        let searchRange = NSRange(location: 0, length: text.length)
        guard let match = Self.wordRegex.firstMatch(in: attributed.string, range: searchRange),
              NSMaxRange(match.range) == text.length else {
            return nil
        }

        let original = text.substring(with: match.range)
        let documentRange = NSRange(
            location: actualRange.location + match.range.location,
            length: match.range.length
        )

        return WordSnapshot(
            original: original,
            range: documentRange,
            clientID: ObjectIdentifier(clientObject)
        )
    }

    func stillMatches(in client: NSTextInputClient) -> Bool {
        var actualRange = NSRange(location: NSNotFound, length: 0)
        guard let attributed = client.attributedSubstring(
            forProposedRange: range,
            actualRange: &actualRange
        ), actualRange == range else {
            return false
        }

        return attributed.string == original
    }

    private static let wordRegex = try! NSRegularExpression(
        pattern: "[\\p{L}\\p{M}]+(?:['’-][\\p{L}\\p{M}]+)*$"
    )
}
