import Foundation

enum PrototypeCorrectionEngine {
    /// PR #1 deliberately uses a tiny deterministic map instead of networking.
    /// The delayed result proves that an asynchronous correction can land behind
    /// ongoing typing without persisting the user's text.
    static func correction(for word: String) -> String? {
        corrections[word.lowercased()]
    }

    private static let corrections: [String: String] = [
        "wrld": "world",
        "shoud": "should",
        "tommorow": "tomorrow",
        "gagwin": "gagawin",
        "pupnta": "pupunta"
    ]
}
