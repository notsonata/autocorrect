import Foundation

public struct TextMutation: Equatable, Sendable {
    public let range: NSRange
    public let replacementUTF16Length: Int

    public init(range: NSRange, replacementUTF16Length: Int) {
        self.range = range
        self.replacementUTF16Length = replacementUTF16Length
    }

    public var delta: Int {
        replacementUTF16Length - range.length
    }
}

public enum TextRangeRebaser {
    /// Rebases a target range across a completed mutation.
    ///
    /// Returns nil when the mutation overlaps or directly touches the target range in
    /// a way that may represent a user editing the target token itself.
    public static func rebase(_ target: NSRange, across mutation: TextMutation) -> NSRange? {
        guard target.location != NSNotFound,
              mutation.range.location != NSNotFound else {
            return nil
        }

        let targetStart = target.location
        let targetEnd = NSMaxRange(target)
        let mutationStart = mutation.range.location
        let mutationEnd = NSMaxRange(mutation.range)

        if mutation.range.length == 0 {
            if mutationStart < targetStart {
                return NSRange(
                    location: targetStart + mutation.delta,
                    length: target.length
                )
            }

            if mutationStart > targetEnd {
                return target
            }

            // An insertion at either edge or inside the target may be the user
            // manually editing that token. Discard the pending correction.
            return nil
        }

        if mutationEnd <= targetStart {
            return NSRange(
                location: targetStart + mutation.delta,
                length: target.length
            )
        }

        if mutationStart >= targetEnd {
            return target
        }

        return nil
    }
}
