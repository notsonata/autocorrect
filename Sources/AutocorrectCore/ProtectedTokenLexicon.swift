import Foundation

/// High-confidence English chat and Filipino/Taglish tokens that should not be
/// treated as misspellings merely because the active macOS dictionary does not
/// recognize them. This is intentionally small rather than a general dictionary.
public enum ProtectedTokenLexicon {
    private static let tokens: Set<String> = [
        "afaik", "akin", "ako", "alin", "ano", "ayoko", "bakit", "bro", "btw",
        "bukas", "dito", "diyan", "doon", "dude", "dyan", "gimme", "gonna", "grabe",
        "gusto", "haha", "hahaha", "hala", "hehe", "hindi", "idk", "ikaw", "imo",
        "imho", "iyan", "iyon", "kasi", "kami", "kayo", "kinda", "lang", "lmao",
        "lol", "lemme", "mamaya", "mayroon", "meron", "naku", "naman", "nah", "natin",
        "ngayon", "niyo", "nope", "nyo", "omg", "okay", "pala", "pero", "pls", "plz",
        "pre", "pwede", "salamat", "sana", "sige", "sila", "sino", "sobra", "talaga",
        "tara", "tayo", "thx", "tol", "uy", "wala", "wanna", "wtf", "yeah", "yep",
        "yung", "yun"
    ]

    public static func contains(_ token: String) -> Bool {
        tokens.contains(token.lowercased())
    }
}
