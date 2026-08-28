# Language quality and latency gates

PR #6 adds two complementary quality layers.

## Deterministic CI corpus

`Tests/AutocorrectQualityTests/taglish-regressions.json` contains English, Filipino, Taglish, and safety cases. CI checks:

- obvious typos are admitted to the AI path,
- common Filipino/Taglish tokens and chat abbreviations are protected locally,
- URLs, code-like fragments, mentions, hashtags, and secret-like prefixes stay out of the AI path,
- conservative provider responses are accepted,
- translations, phrases, distant rewrites, punctuation changes, and capitalization-style changes are rejected,
- adjacent transposition typos such as `teh -> the` are treated as one edit,
- the local candidate policy has an XCTest clock measurement so hot-path regressions remain visible in test reports.

The protected-token list is intentionally small. It exists to prevent high-confidence false positives from an English-centric system dictionary, not to replace a Filipino dictionary.

## Opt-in live Gemini gate

The same test target contains `testLiveGeminiQualityAndLatencyWhenOptedIn`. It is skipped in CI unless `AUTOCORRECT_LIVE_API_KEY` is present.

To run it locally, provide the API key only to the test process and optionally set `AUTOCORRECT_LIVE_MODEL`. The default model is `gemini-3.7-flash`.

```sh
xcodegen generate
AUTOCORRECT_LIVE_API_KEY="$AUTOCORRECT_LIVE_API_KEY" \
AUTOCORRECT_LIVE_MODEL="gemini-3.7-flash" \
xcodebuild \
  -project Autocorrect.xcodeproj \
  -scheme AutocorrectInputMethod \
  -configuration Debug \
  -derivedDataPath .build \
  -only-testing:AutocorrectQualityTests/QualityRegressionTests/testLiveGeminiQualityAndLatencyWhenOptedIn \
  test
```

The live gate reports raw model accuracy, final post-policy correction accuracy, preservation accuracy, median latency, and p95 latency. Current acceptance thresholds are:

- correction accuracy: at least 80%,
- preservation accuracy: at least 90%,
- p95 provider latency: at most 3500 ms.

These are release gates, not claims about every possible Filipino or Taglish phrase. Corpus cases should be expanded when real false positives or missed corrections are found.
