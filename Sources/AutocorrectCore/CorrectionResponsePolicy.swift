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

    /// Optimal-string-alignment distance. Adjacent transpositions such as
    /// `teh` -> `the` count as one typo rather than two substitutions.
    private static func editDistance(_ source: [Character], _ target: [Character]) -> Int {
        guard !source.isEmpty else { return target.count }
        guard !target.isEmpty else { return source.count }

        var matrix = Array(
            repeating: Array(repeating: 0, count: target.count + 1),
            count: source.count + 1
        )

        for sourceIndex in 0...source.count {
            matrix[sourceIndex][0] = sourceIndex
        }
        for targetIndex in 0...target.count {
            matrix[0][targetIndex] = targetIndex
        }

        for sourceIndex in 1...source.count {
            for targetIndex in 1...target.count {
                let substitutionCost = source[sourceIndex - 1] == target[targetIndex - 1] ? 0 : 1
                var distance = min(
                    matrix[sourceIndex - 1][targetIndex] + 1,
                    matrix[sourceIndex][targetIndex - 1] + 1,
                    matrix[sourceIndex - 1][targetIndex - 1] + substitutionCost
                )

                if sourceIndex > 1,
                   targetIndex > 1,
                   source[sourceIndex - 1] == target[targetIndex - 2],
                   source[sourceIndex - 2] == target[targetIndex - 1] {
                    distance = min(distance, matrix[sourceIndex - 2][targetIndex - 2] + 1)
                }

                matrix[sourceIndex][targetIndex] = distance
            }
        }

        return matrix[source.count][target.count]
    }
}
