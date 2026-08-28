import Foundation
import XCTest
@testable import AutocorrectCore
@testable import AutocorrectProviders

final class QualityRegressionTests: XCTestCase {
    func testCorpusHasBalancedCoverage() throws {
        let corpus = try loadCorpus()

        XCTAssertGreaterThanOrEqual(corpus.candidateCases.count, 50)
        XCTAssertGreaterThanOrEqual(corpus.responseCases.count, 15)
        XCTAssertGreaterThanOrEqual(corpus.liveCases.count, 30)

        let candidateLanguages = Set(corpus.candidateCases.map { $0.language })
        XCTAssertTrue(candidateLanguages.isSuperset(of: ["english", "filipino", "taglish"]))

        let liveLanguages = Set(corpus.liveCases.map { $0.language })
        XCTAssertTrue(liveLanguages.isSuperset(of: ["english", "filipino", "taglish"]))
    }

    func testCandidatePolicyRegressionCorpus() throws {
        for testCase in try loadCorpus().candidateCases {
            let actual = CorrectionCandidatePolicy.shouldRequestCorrection(
                completedWord: testCase.input,
                leftContext: testCase.leftContext,
                isKnownWord: testCase.isKnownWord
            )

            XCTAssertEqual(
                actual,
                testCase.shouldRequest,
                "Candidate policy mismatch for \(testCase.id): \(testCase.input)"
            )
        }
    }

    func testResponsePolicyRegressionCorpus() throws {
        for testCase in try loadCorpus().responseCases {
            let actual = CorrectionResponsePolicy.validatedReplacement(
                original: testCase.original,
                proposed: testCase.proposed
            )

            XCTAssertEqual(
                actual,
                testCase.expectedAccepted,
                "Response policy mismatch for \(testCase.id): \(testCase.original) -> \(testCase.proposed)"
            )
        }
    }

    func testProtectedTokensAreCaseInsensitive() {
        XCTAssertTrue(ProtectedTokenLexicon.contains("WALA"))
        XCTAssertTrue(ProtectedTokenLexicon.contains("Pre"))
        XCTAssertTrue(ProtectedTokenLexicon.contains("LMAO"))
        XCTAssertFalse(ProtectedTokenLexicon.contains("gagwin"))
        XCTAssertFalse(ProtectedTokenLexicon.contains("tommorow"))
    }

    func testCandidatePolicyHotPathPerformance() throws {
        let cases = try loadCorpus().candidateCases

        measure(metrics: [XCTClockMetric()]) {
            for _ in 0..<500 {
                for testCase in cases {
                    _ = CorrectionCandidatePolicy.shouldRequestCorrection(
                        completedWord: testCase.input,
                        leftContext: testCase.leftContext,
                        isKnownWord: testCase.isKnownWord
                    )
                }
            }
        }
    }

    /// Opt-in live quality gate. CI skips this because no provider credential is supplied.
    /// Set AUTOCORRECT_LIVE_API_KEY locally to measure the current model end-to-end.
    func testLiveGeminiQualityAndLatencyWhenOptedIn() async throws {
        let environment = ProcessInfo.processInfo.environment
        guard let apiKey = environment["AUTOCORRECT_LIVE_API_KEY"], !apiKey.isEmpty else {
            throw XCTSkip("Set AUTOCORRECT_LIVE_API_KEY to run the live Gemini quality gate.")
        }

        let model = environment["AUTOCORRECT_LIVE_MODEL"] ?? "gemini-3.7-flash"
        let provider = OpenAICompatibleCorrectionProvider(
            configuration: ProviderPresets.gemini(model: model),
            credentialStore: EvaluationCredentialStore(apiKey: apiKey)
        )
        let cases = try loadCorpus().liveCases

        var correctionTotal = 0
        var correctionCorrect = 0
        var preservationTotal = 0
        var preservationCorrect = 0
        var rawProviderCorrect = 0
        var latencies: [Double] = []

        for testCase in cases {
            let request = CorrectionRequest(
                completedWord: testCase.input,
                leftContext: testCase.leftContext
            )
            let start = DispatchTime.now().uptimeNanoseconds
            let response = try await provider.correct(request)
            let elapsed = DispatchTime.now().uptimeNanoseconds - start
            latencies.append(Double(elapsed) / 1_000_000.0)

            if response.replacement == testCase.expected {
                rawProviderCorrect += 1
            }

            let finalValue = CorrectionResponsePolicy.validatedReplacement(
                original: testCase.input,
                proposed: response.replacement
            ) ?? testCase.input

            if testCase.input == testCase.expected {
                preservationTotal += 1
                if finalValue == testCase.expected {
                    preservationCorrect += 1
                }
            } else {
                correctionTotal += 1
                if finalValue == testCase.expected {
                    correctionCorrect += 1
                }
            }
        }

        let correctionAccuracy = ratio(correctionCorrect, correctionTotal)
        let preservationAccuracy = ratio(preservationCorrect, preservationTotal)
        let rawAccuracy = ratio(rawProviderCorrect, cases.count)
        let p50 = percentile(latencies, 0.50)
        let p95 = percentile(latencies, 0.95)

        print(
            String(
                format: "LIVE QUALITY model=%@ correction=%.1f%% preserve=%.1f%% raw=%.1f%% p50=%.0fms p95=%.0fms",
                model,
                correctionAccuracy * 100,
                preservationAccuracy * 100,
                rawAccuracy * 100,
                p50,
                p95
            )
        )

        XCTAssertGreaterThanOrEqual(correctionAccuracy, 0.80)
        XCTAssertGreaterThanOrEqual(preservationAccuracy, 0.90)
        XCTAssertLessThanOrEqual(p95, 3_500.0)
    }

    private func loadCorpus() throws -> QualityCorpus {
        let sourceURL = URL(fileURLWithPath: #filePath)
        let corpusURL = sourceURL
            .deletingLastPathComponent()
            .appendingPathComponent("taglish-regressions.json")
        let data = try Data(contentsOf: corpusURL)
        return try JSONDecoder().decode(QualityCorpus.self, from: data)
    }

    private func ratio(_ numerator: Int, _ denominator: Int) -> Double {
        guard denominator > 0 else { return 0 }
        return Double(numerator) / Double(denominator)
    }

    private func percentile(_ values: [Double], _ percentile: Double) -> Double {
        guard !values.isEmpty else { return 0 }
        let sorted = values.sorted()
        let rank = max(0, min(sorted.count - 1, Int(ceil(Double(sorted.count) * percentile)) - 1))
        return sorted[rank]
    }
}

private struct QualityCorpus: Decodable {
    let candidateCases: [CandidateCase]
    let responseCases: [ResponseCase]
    let liveCases: [LiveCase]

    enum CodingKeys: String, CodingKey {
        case candidateCases = "candidate_cases"
        case responseCases = "response_cases"
        case liveCases = "live_cases"
    }
}

private struct CandidateCase: Decodable {
    let id: String
    let language: String
    let leftContext: String
    let input: String
    let isKnownWord: Bool
    let shouldRequest: Bool

    enum CodingKeys: String, CodingKey {
        case id, language, input
        case leftContext = "left_context"
        case isKnownWord = "is_known_word"
        case shouldRequest = "should_request"
    }
}

private struct ResponseCase: Decodable {
    let id: String
    let original: String
    let proposed: String
    let expectedAccepted: String?

    enum CodingKeys: String, CodingKey {
        case id, original, proposed
        case expectedAccepted = "expected_accepted"
    }
}

private struct LiveCase: Decodable {
    let id: String
    let language: String
    let leftContext: String
    let input: String
    let expected: String

    enum CodingKeys: String, CodingKey {
        case id, language, input, expected
        case leftContext = "left_context"
    }
}

private struct EvaluationCredentialStore: ProviderCredentialStore {
    let apiKey: String

    func apiKey(for providerIdentifier: String) throws -> String? {
        apiKey
    }

    func setAPIKey(_ apiKey: String, for providerIdentifier: String) throws {}
    func removeAPIKey(for providerIdentifier: String) throws {}
}
