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
8. **Explicit enablement.** Autocorrect defaults off and network correction is blocked until the user acknowledges the privacy disclosure in the companion app.

## Shared settings

The input method and menu-bar companion share only non-sensitive configuration through the preference suite `dev.notsonata.autocorrect.shared`, including:

- enabled state,
- privacy acknowledgment,
- selected provider and model,
- custom provider base URL,
- excluded application bundle identifiers.

The shared preference domain never stores typed text, context, prompts, responses, correction history, or API keys.

Settings changes are announced through `DistributedNotificationCenter`. The input method keeps a small in-memory settings snapshot so the Space/word-boundary hot path does not perform preference-disk synchronization.

If Autocorrect is disabled, privacy acknowledgment is absent, the current app is excluded, or provider configuration is invalid, the boundary is passed through before `WordSnapshot.capture` is called.

## Secure-input checks

Correction is rejected when either of these checks indicates a protected input path:

- macOS `IsSecureEventInputEnabled()` reports Secure Event Input.
- The focused Accessibility element has the `AXSecureTextField` subrole.

It also rejects fields whose role or writable selection range cannot be positively verified. The security gate runs before every completed-word snapshot and again immediately before any asynchronous correction is applied.

## Network correction

Only the selected provider receives a bounded correction request. The provider client:

- uses an ephemeral `URLSession`,
- disables URL caching,
- disables HTTP cookie storage,
- uses short timeouts,
- does not log prompts or responses,
- does not include prompt text in public error values.

Provider output is validated locally before it can mutate text. Disabling Autocorrect, excluding the current app, or changing provider configuration while a request is pending causes that result to be discarded before mutation.

## Authentication data

Provider API keys are credentials, not typing data. They are stored only in macOS Keychain under the provider identifier and are never embedded in the repository or written to ordinary preferences.

Two Keychain sharing modes are supported:

- Developer ID builds use the shared application-group/data-protection Keychain path when the signed entitlement is available.
- Free GitHub builds have no paid application-group entitlement, so they use the macOS file-based Keychain with an ACL that trusts only the installed Autocorrect input-method and settings executables.

The free fallback does not move the API key into a plaintext file. It changes only the Keychain access-control mechanism used by the two local processes. Because legacy trusted-application identity is tied to the installed programs, an ad-hoc update can cause macOS to request Keychain authorization again.

The settings UI never displays an existing stored API key. It only reports whether a credential exists, accepts a replacement key transiently, and clears the input after saving.

## Memory limitations

The application can guarantee that it does not intentionally persist typing data. It cannot guarantee physical zeroization of every temporary Swift `String` copy or guarantee that macOS never pages transient process memory to swap or includes process memory in an operating-system diagnostic. The implementation therefore minimizes lifetime and scope of text objects rather than claiming cryptographic memory erasure.
