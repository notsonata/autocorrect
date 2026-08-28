# Privacy model

Autocorrect must be treated as keylogger-class software from a threat-model perspective because an enabled macOS input method can observe text passing through the text-input system. The project is designed to minimize that capability rather than retain or exploit it.

## Hard invariants

1. **No intentional persistence of typed text.** Typed text, surrounding context, correction requests, and correction results must never be written to files, databases, `UserDefaults`, Keychain, analytics, crash breadcrumbs, or correction history.
2. **No text-bearing logs.** Production logging must never include typed words, context, prompts, model responses, or reconstructed document contents.
3. **Secure fields are pass-through only.** If macOS Secure Event Input is enabled, if the focused Accessibility element is a secure text field, or if the field cannot be positively classified as a supported non-secure editable control, Autocorrect must not inspect surrounding text or create a correction job.
4. **Fail closed.** Failure to inspect security state or failure to prove cursor restoration capability disables correction for that field. Ordinary input continues normally.
5. **Minimal context.** Network correction requests are type-bounded to at most the most recent 256 characters of preceding context plus the completed word.
6. **Ephemeral jobs.** Correction jobs live only in process memory and are released immediately after completion, cancellation, invalidation, or client change.
7. **No clipboard capture.** Clipboard contents are outside the correction pipeline.
8. **Local rejection before network use.** Known words and URL/email/code/secret-like candidates are rejected before a provider request is created.
9. **Untrusted provider output.** Remote output cannot mutate text until a local response policy verifies token shape, capitalization, and conservative edit distance.

## Current input behavior

On a supported word boundary the input method reads only enough preceding text to identify the completed word and bounded context, inserts the boundary immediately, and retains only pending correction state required to safely target that word.

Multiple pending words may exist concurrently. Each live input job retains only the original word, an opaque identifier, and its rebased document range. Completed, stale, overlapping, unsafe, or client-switched jobs are immediately removed from the in-memory ledger.

Ordinary non-boundary input is passed directly to the client and is not accumulated in a keystroke buffer. Its text is not inspected by the correction engine. Only its selection range and replacement length are used transiently to keep pending ranges anchored.

## Secure-input checks

Correction is rejected when either of these checks indicates a protected input path:

- macOS `IsSecureEventInputEnabled()` reports Secure Event Input.
- The focused Accessibility element has the `AXSecureTextField` subrole.

It also rejects fields whose role or writable selection range cannot be positively verified.

The security gate runs before any completed-word snapshot and again before any asynchronous correction is applied. This second check prevents a pending correction from landing after focus has moved into a secure field.

These checks are defense in depth. Secure or unknown fields receive normal pass-through input without context inspection.

## Network correction

The live runtime path uses the Gemini provider only after local candidate filtering. Candidates are rejected before network access when they are already known to macOS spelling or resemble short tokens, acronyms, mixed-case identifiers, likely proper nouns, URLs, email addresses, domains, mentions, hashtags, paths, code fragments, or common credential shapes.

For candidates that survive, only the selected provider receives the bounded correction request. The provider client:

- uses an ephemeral `URLSession`,
- disables URL caching,
- disables HTTP cookie storage,
- uses short timeouts,
- does not log prompts or responses,
- does not include prompt text in public error values.

Remote providers necessarily receive the bounded context required to perform the requested correction. The settings UI will disclose the selected provider before broader end-user configuration is enabled.

Provider output is not trusted. The input method rejects outputs containing whitespace or multiple tokens, outputs that change capitalization style, and outputs whose edit distance is too large to be treated as a conservative spelling correction. This is a local structural defense against translation and general rewriting.

## Authentication data

Provider API keys are credentials, not typing data. They are stored only in macOS Keychain under the provider identifier and are never embedded in the repository or written to ordinary preferences.

Typed text, prompts, model responses, and correction history are never stored in Keychain.

## Memory limitations

The application can guarantee that it does not intentionally persist typing data. It cannot guarantee physical zeroization of every temporary Swift `String` copy or guarantee that macOS never pages transient process memory to swap or includes process memory in an operating-system diagnostic. The implementation therefore minimizes lifetime and scope of text objects rather than claiming cryptographic memory erasure.
