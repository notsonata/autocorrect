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
    /// Returns nil when the mutation overlaps the target range, because the caller can
    /// no longer prove that the target still refers to the same logical text.
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
            if mutationStart <= targetStart {
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
