import Foundation

public enum SelectionMath {
    /// Rebases a collapsed insertion point across a completed text mutation.
    /// The caller must only use this for a caret positioned outside the mutation range.
    public static func rebasedCaret(
        _ caret: Int,
        replacing range: NSRange,
        withUTF16Length newLength: Int
    ) -> Int {
        guard range.location != NSNotFound else { return caret }

        let oldEnd = NSMaxRange(range)
        guard caret >= oldEnd else { return caret }

        return caret + (newLength - range.length)
    }
}
