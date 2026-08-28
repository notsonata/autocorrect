import Foundation

enum WordBoundaryDetector {
    static func triggersCorrection(for input: String) -> Bool {
        guard input.count == 1, let character = input.first else {
            return false
        }

        return boundaries.contains(character)
    }

    private static let boundaries: Set<Character> = [
        " ", ".", ",", "?", "!", ":", ";", "\n", "\t"
    ]
}
