import XCTest
@testable import AutocorrectCore

final class CorrectionSafetyPolicyTests: XCTestCase {
    func testKnownWordDoesNotRequestRemoteCorrection() {
        XCTAssertFalse(
            CorrectionCandidatePolicy.shouldRequestCorrection(
                completedWord: "world",
                leftContext: "hello ",
                isKnownWord: true
            )
        )
    }

    func testUnknownPlainWordCanRequestRemoteCorrection() {
        XCTAssertTrue(
            CorrectionCandidatePolicy.shouldRequestCorrection(
                completedWord: "wrld",
                leftContext: "hello ",
                isKnownWord: false
            )
        )
    }

    func testURLAndEmailFragmentsAreRejected() {
        XCTAssertFalse(
            CorrectionCandidatePolicy.shouldRequestCorrection(
                completedWord: "com",
                leftContext: "https://example.",
                isKnownWord: false
            )
        )
        XCTAssertFalse(
            CorrectionCandidatePolicy.shouldRequestCorrection(
                completedWord: "com",
                leftContext: "person@example.",
                isKnownWord: false
            )
        )
    }

    func testCodeLikeFragmentsAreRejected() {
        XCTAssertFalse(
            CorrectionCandidatePolicy.shouldRequestCorrection(
                completedWord: "property",
                leftContext: "someObject.",
                isKnownWord: false
            )
        )
        XCTAssertFalse(
            CorrectionCandidatePolicy.shouldRequestCorrection(
                completedWord: "value",
                leftContext: "api_key_",
                isKnownWord: false
            )
        )
    }

    func testSecretAndSocialTokenPrefixesAreRejected() {
        XCTAssertFalse(
            CorrectionCandidatePolicy.shouldRequestCorrection(
                completedWord: "abcdef",
                leftContext: "sk-",
                isKnownWord: false
            )
        )
        XCTAssertFalse(
            CorrectionCandidatePolicy.shouldRequestCorrection(
                completedWord: "someone",
                leftContext: "@",
                isKnownWord: false
            )
        )
        XCTAssertFalse(
            CorrectionCandidatePolicy.shouldRequestCorrection(
                completedWord: "topic",
                leftContext: "#",
                isKnownWord: false
            )
        )
    }

    func testIntentionalCapitalizationIsRejected() {
        XCTAssertFalse(
            CorrectionCandidatePolicy.shouldRequestCorrection(
                completedWord: "fooBar",
                leftContext: "",
                isKnownWord: false
            )
        )
        XCTAssertFalse(
            CorrectionCandidatePolicy.shouldRequestCorrection(
                completedWord: "NASA",
                leftContext: "",
                isKnownWord: false
            )
        )
    }

    func testMidSentenceProperNounIsRejectedButSentenceStartTypoCanPass() {
        XCTAssertFalse(
            CorrectionCandidatePolicy.shouldRequestCorrection(
                completedWord: "Angelo",
                leftContext: "hello ",
                isKnownWord: false
            )
        )
        XCTAssertTrue(
            CorrectionCandidatePolicy.shouldRequestCorrection(
                completedWord: "Tommorow",
                leftContext: "See you. ",
                isKnownWord: false
            )
        )
    }

    func testShortWordsAreRejected() {
        XCTAssertFalse(
            CorrectionCandidatePolicy.shouldRequestCorrection(
                completedWord: "na",
                leftContext: "",
                isKnownWord: false
            )
        )
    }

    func testResponseAcceptsConservativeTypoCorrections() {
        XCTAssertEqual(
            CorrectionResponsePolicy.validatedReplacement(original: "wrld", proposed: "world"),
            "world"
        )
        XCTAssertEqual(
            CorrectionResponsePolicy.validatedReplacement(original: "gagwin", proposed: "gagawin"),
            "gagawin"
        )
        XCTAssertEqual(
            CorrectionResponsePolicy.validatedReplacement(original: "dont", proposed: "don't"),
            "don't"
        )
    }

    func testResponseRejectsNoOpPhraseTranslationAndDistantRewrite() {
        XCTAssertNil(
            CorrectionResponsePolicy.validatedReplacement(original: "world", proposed: "world")
        )
        XCTAssertNil(
            CorrectionResponsePolicy.validatedReplacement(original: "wrld", proposed: "the world")
        )
        XCTAssertNil(
            CorrectionResponsePolicy.validatedReplacement(original: "bahay", proposed: "house")
        )
        XCTAssertNil(
            CorrectionResponsePolicy.validatedReplacement(original: "typing", proposed: "rewritten")
        )
    }

    func testResponsePreservesCapitalizationStyle() {
        XCTAssertEqual(
            CorrectionResponsePolicy.validatedReplacement(
                original: "Tommorow",
                proposed: "Tomorrow"
            ),
            "Tomorrow"
        )
        XCTAssertNil(
            CorrectionResponsePolicy.validatedReplacement(
                original: "Tommorow",
                proposed: "tomorrow"
            )
        )
    }
}
