import Foundation

public enum CorrectionResponsePolicy {
    public static func validatedReplacement(
        original: String,
        proposed: String
    ) -> String? {
        guard proposed == proposed.trimmingCharacters(in: .whitespacesAndNewlines),
              !proposed.isEmpty,
              proposed.count <= 64,
              isWordLike(proposed),
              proposed != original,
              caseStyle(of: proposed) == caseStyle(of: original) else {
            return nil
        }

        let distance = editDistance(
            Array(original.lowercased()),
            Array(proposed.lowercased())
        )
        let maximumDistance = min(3, max(1, original.count / 4 + 1))

        guard distance <= maximumDistance else {
            return nil
        }

        return proposed
    }

    private enum CaseStyle: Equatable {
        case lowercase
        case uppercase
        case capitalized
        case mixed
        case uncased
    }

    private static func caseStyle(of word: String) -> CaseStyle {
        let letters = word.filter { $0.isLetter }
        guard !letters.isEmpty else {
            return .uncased
        }

        if letters.allSatisfy({ $0.isLowercase }) {
            return .lowercase
        }

        if letters.allSatisfy({ $0.isUppercase }) {
            return .uppercase
        }

        if let first = letters.first,
           first.isUppercase,
           letters.dropFirst().allSatisfy({ $0.isLowercase }) {
            return .capitalized
        }

        return .mixed
    }

    private static func isWordLike(_ word: String) -> Bool {
        word.range(
            of: #"^[\p{L}\p{M}]+(?:['’-][\p{L}\p{M}]+)*$"#,
            options: .regularExpression
        ) != nil
    }

    private static func editDistance(_ source: [Character], _ target: [Character]) -> Int {
        guard !source.isEmpty else { return target.count }
        guard !target.isEmpty else { return source.count }

        var previous = Array(0...target.count)

        for (sourceIndex, sourceCharacter) in source.enumerated() {
            var current = [sourceIndex + 1]
            current.reserveCapacity(target.count + 1)

            for (targetIndex, targetCharacter) in target.enumerated() {
                let insertion = current[targetIndex] + 1
                let deletion = previous[targetIndex + 1] + 1
                let substitution = previous[targetIndex] + (sourceCharacter == targetCharacter ? 0 : 1)
                current.append(min(insertion, deletion, substitution))
            }

            previous = current
        }

        return previous[target.count]
    }
}
