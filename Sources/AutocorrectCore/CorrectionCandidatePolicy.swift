import Foundation

public enum CorrectionCandidatePolicy {
    public static func shouldRequestCorrection(
        completedWord: String,
        leftContext: String,
        isKnownWord: Bool
    ) -> Bool {
        guard !isKnownWord,
              (3...48).contains(completedWord.count),
              isWordLike(completedWord),
              !hasIntentionalCapitalization(completedWord),
              !looksLikeMidSentenceProperNoun(completedWord, leftContext: leftContext),
              !hasSensitiveOrCodeLikeTokenPrefix(leftContext) else {
            return false
        }

        return true
    }

    private static func isWordLike(_ word: String) -> Bool {
        word.range(
            of: #"^[\p{L}\p{M}]+(?:['’-][\p{L}\p{M}]+)*$"#,
            options: .regularExpression
        ) != nil
    }

    private static func hasIntentionalCapitalization(_ word: String) -> Bool {
        let letters = word.filter { $0.isLetter }
        guard letters.count > 1 else {
            return false
        }

        if letters.allSatisfy({ $0.isUppercase }) {
            return true
        }

        var sawLowercase = false
        for character in letters {
            if character.isLowercase {
                sawLowercase = true
            } else if sawLowercase && character.isUppercase {
                return true
            }
        }

        return false
    }

    private static func looksLikeMidSentenceProperNoun(
        _ word: String,
        leftContext: String
    ) -> Bool {
        let letters = word.filter { $0.isLetter }
        guard let first = letters.first,
              first.isUppercase,
              letters.dropFirst().allSatisfy({ $0.isLowercase }) else {
            return false
        }

        let trimmedContext = leftContext.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let previous = trimmedContext.last else {
            return false
        }

        return !".!?".contains(previous)
    }

    private static func hasSensitiveOrCodeLikeTokenPrefix(_ leftContext: String) -> Bool {
        let tail = leftContext.suffix(96)
        let tokenPrefix = String(
            tail.reversed().prefix { !$0.isWhitespace }.reversed()
        )

        guard !tokenPrefix.isEmpty else {
            return false
        }

        let lowered = tokenPrefix.lowercased()
        let secretPrefixes = [
            "sk-",
            "ghp_",
            "github_pat_",
            "xoxb-",
            "xoxp-",
            "xoxa-",
            "bearer"
        ]

        if secretPrefixes.contains(where: { lowered.hasPrefix($0) }) {
            return true
        }

        let sensitiveMarkers: [Character] = [
            "@", "/", "\\", "`", "_", "=", "{", "}", "[", "]",
            "<", ">", "$", "#", ":"
        ]

        if tokenPrefix.contains(where: { sensitiveMarkers.contains($0) }) {
            return true
        }

        if tokenPrefix.contains(".") || tokenPrefix.contains(where: { $0.isNumber }) {
            return true
        }

        return false
    }
}
