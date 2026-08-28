import Foundation

struct WordSnapshot {
    private static let maximumWordProbeCharacters = 128
    private static let maximumLeftContextCharacters = 256

    let original: String
    let range: NSRange
    let leftContext: String

    static func capture(from client: AnyObject) -> WordSnapshot? {
        let selection = IMKClientBridge.selectedRange(client: client)
        guard selection.location != NSNotFound,
              selection.length == 0,
              selection.location > 0 else {
            return nil
        }

        let probeLength = min(
            selection.location,
            maximumWordProbeCharacters + maximumLeftContextCharacters
        )
        let probeRange = NSRange(
            location: selection.location - probeLength,
            length: probeLength
        )

        guard let probe = IMKClientBridge.string(range: probeRange, client: client) else {
            return nil
        }

        let text = probe as NSString
        let searchRange = NSRange(location: 0, length: text.length)
        guard let match = Self.wordRegex.firstMatch(in: probe, range: searchRange),
              NSMaxRange(match.range) == text.length else {
            return nil
        }

        let original = text.substring(with: match.range)
        let precedingProbe = text.substring(to: match.range.location)
        let leftContext = String(precedingProbe.suffix(maximumLeftContextCharacters))
        let documentRange = NSRange(
            location: probeRange.location + match.range.location,
            length: match.range.length
        )

        return WordSnapshot(
            original: original,
            range: documentRange,
            leftContext: leftContext
        )
    }

    private static let wordRegex = try! NSRegularExpression(
        pattern: "[\\p{L}\\p{M}]+(?:['’-][\\p{L}\\p{M}]+)*$"
    )
}
