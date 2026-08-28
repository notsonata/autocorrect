import Foundation

struct PrototypeCorrectionPlan {
    let replacement: String
    let delay: TimeInterval
}

enum PrototypeCorrectionEngine {
    /// PR #2 still uses deterministic offline corrections. Different delays force
    /// completions to arrive out of order so the range ledger is exercised manually.
    static func correction(for word: String) -> PrototypeCorrectionPlan? {
        corrections[word.lowercased()]
    }

    private static let corrections: [String: PrototypeCorrectionPlan] = [
        "wrld": PrototypeCorrectionPlan(replacement: "world", delay: 0.9),
        "shoud": PrototypeCorrectionPlan(replacement: "should", delay: 0.2),
        "tommorow": PrototypeCorrectionPlan(replacement: "tomorrow", delay: 0.7),
        "gagwin": PrototypeCorrectionPlan(replacement: "gagawin", delay: 0.4),
        "pupnta": PrototypeCorrectionPlan(replacement: "pupunta", delay: 0.1)
    ]
}
