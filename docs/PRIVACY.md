# Privacy model

Autocorrect must be treated as keylogger-class software from a threat-model perspective because an enabled macOS input method can observe text passing through the text-input system. The project is designed to minimize that capability rather than retain or exploit it.

## Hard invariants

1. **No intentional persistence of typed text.** Typed text, surrounding context, correction requests, and correction results must never be written to files, databases, `UserDefaults`, Keychain, analytics, crash breadcrumbs, or correction history.
2. **No text-bearing logs.** Production logging must never include typed words, context, prompts, model responses, or reconstructed document contents.
3. **Secure fields are pass-through only.** If macOS Secure Event Input is enabled, if the focused Accessibility element is a secure text field, or if the field cannot be positively classified as a supported non-secure editable control, Autocorrect must not inspect surrounding text or create a correction job.
4. **Fail closed.** Failure to inspect security state or failure to prove cursor restoration capability disables correction for that field. Ordinary input continues normally.
5. **Minimal context.** The input layer should inspect only the minimum text needed to identify a completed word and, when AI correction is introduced, the minimum bounded context required for disambiguation.
6. **Ephemeral jobs.** Correction jobs live only in process memory and are released immediately after completion, cancellation, invalidation, or client change.
7. **No clipboard capture.** Clipboard contents are outside the correction pipeline.

## Current offline behavior

The current proof of concept performs no networking. On a supported word boundary it reads at most 128 UTF-16 code units immediately before the insertion point, extracts only the final completed word, inserts the boundary immediately, and retains only words that have a known deterministic prototype correction.

Multiple pending words may exist concurrently. Each job retains only the original word, an opaque identifier, and its rebased document range. Completed, stale, overlapping, unsafe, or client-switched jobs are immediately removed from the in-memory ledger.

Ordinary non-boundary input is passed directly to the client and is not accumulated in a keystroke buffer. Its text is not inspected by the correction engine. Only its selection range and replacement length are used transiently to keep pending ranges anchored.

## Secure-input checks

The proof of concept rejects correction when either of these checks indicates a protected input path:

- macOS `IsSecureEventInputEnabled()` reports Secure Event Input.
- The focused Accessibility element has the `AXSecureTextField` subrole.

It also rejects fields whose role or writable selection range cannot be positively verified.

The security gate runs before any completed-word snapshot and again before any delayed correction is applied. This second check prevents a pending correction from landing after focus has moved into a secure field.

These checks are defense in depth. Secure or unknown fields receive normal pass-through input without context inspection.

## Memory limitations

The application can guarantee that it does not intentionally persist typing data. It cannot guarantee physical zeroization of every temporary Swift `String` copy or guarantee that macOS never pages transient process memory to swap or includes process memory in an operating-system diagnostic. The implementation therefore minimizes lifetime and scope of text objects rather than claiming cryptographic memory erasure.

## Authentication data

Provider authentication credentials are not typing data. When Google Gemini OAuth is added, refresh/access credentials that must survive app restarts will be stored only in macOS Keychain. Typed text will never be stored alongside them.

## Remote AI providers

A later AI-enabled release will necessarily transmit bounded correction context to the selected provider. The application must clearly disclose the provider and its data-handling implications before enabling network correction. Provider requests must not be logged locally.
