# Architecture

## Input pipeline

Autocorrect uses InputMethodKit as the primary macOS text-input integration.

Word completion is triggered by Space and common punctuation boundaries:

1. Positively verify that the focused field is a supported non-secure text control.
2. Snapshot the completed word immediately before the insertion point.
3. Insert the boundary immediately. Correction work must never block typing.
4. Resolve a correction asynchronously.
5. Before applying it, verify that the client is still active and the original word still exists at the current rebased target range.
6. Preflight the ability to restore the current collapsed selection.
7. Replace only the completed word.
8. Rebase and restore the live caret so ongoing typing remains uninterrupted.
9. Record the committed mutation and rebase every other pending correction around it.

PR #2 still uses a deterministic delayed correction map in the live input path, with different delays so completions intentionally arrive out of order.

## Concurrent correction ledger

Every correction job keeps only:

- an opaque in-memory identifier,
- the original completed word,
- its current UTF-16 document range.

The ledger also tracks document mutations caused by the input method. When a mutation occurs:

- jobs entirely before it are unchanged,
- jobs entirely after it are shifted by the mutation delta,
- jobs overlapping it are discarded because their target can no longer be proven safe.

Successful corrections are committed to the ledger only after cursor restoration succeeds. Unknown edits are never searched for heuristically. If the original word is not still present at the expected rebased range, the job is cancelled.

Switching text clients purges all pending jobs.

## Security gate

The input layer fails closed. It does not inspect surrounding text when:

- Secure Event Input is active.
- Accessibility identifies the focused element as a secure text field.
- The focused control cannot be positively classified as supported editable text.
- Its selection range cannot be safely restored.

The gate is checked before every word snapshot and again immediately before applying any asynchronous correction. Ordinary non-boundary characters are passed through without surrounding-text inspection.

Unknown clients are pass-through only.

## Correction providers

Provider integration is isolated from the input method through a small protocol:

```swift
protocol CorrectionProvider {
    var identifier: String { get }
    func correct(_ request: CorrectionRequest) async throws -> CorrectionResponse
}
```

`CorrectionRequest` bounds preceding context to the most recent 256 characters before it can reach a network provider.

PR #3 adds a reusable OpenAI-compatible Chat Completions transport. A provider configuration consists of:

- provider identifier,
- display name,
- base URL,
- model identifier,
- optional reasoning effort.

Google Gemini is the first preset:

- base URL: `https://generativelanguage.googleapis.com/v1beta/openai/`
- model: `gemini-3.7-flash`
- reasoning effort: `low`

OpenRouter uses the same transport with `https://openrouter.ai/api/v1/` and an OpenRouter model slug. Custom OpenAI-compatible endpoints can use the same client without changing the correction pipeline.

Provider API keys are stored in macOS Keychain. Typed text is never stored in Keychain.

The network client uses an ephemeral `URLSession`, disables URL caching and cookies, uses short request timeouts, and does not place prompt or response text into error values or logs.

Structured model output is requested as a JSON schema containing only one field: `replacement`.

## Planned PR sequence

1. **InputMethodKit POC:** delayed deterministic correction, secure-field fail-closed behavior, cursor-invariance proof. Completed.
2. **Concurrent edit engine:** correction jobs, cancellation, mutation tracking, pending-range rebasing, additional word boundaries. Completed.
3. **OpenAI-compatible provider layer:** provider protocol, API-key Keychain storage, Gemini preset/client, OpenRouter/custom compatibility, bounded context. Current.
4. **Correction safety + runtime integration:** connect the provider to the input pipeline, local candidate filtering, conservative response validation, translation/rewrite rejection, URL/email/code/secret guards.
5. **Menu-bar/settings app:** enable/disable, provider/model selection, API-key management, excluded apps, launch behavior, privacy disclosure.
6. **English/Filipino/Taglish quality suite:** regression corpus, do-not-change cases, latency and correction-quality tests.
7. **Packaging:** signing, notarization, install/update path, compatibility matrix.
