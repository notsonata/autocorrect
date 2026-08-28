# Architecture

## Processes

Autocorrect has two native macOS processes:

1. **Autocorrect input method**: InputMethodKit integration, secure-field gating, completed-word capture, candidate filtering, asynchronous correction, range rebasing, and cursor-safe text mutation.
2. **Autocorrect Settings**: SwiftUI menu-bar companion for enable/disable, provider/model configuration, Keychain credential management, application exclusions, login-item behavior, and privacy acknowledgment.

They share non-sensitive runtime configuration through `AutocorrectSettings`. Provider credentials remain in Keychain through `AutocorrectProviders`.

## Input pipeline

Word completion is triggered by Space and common punctuation boundaries:

1. Read the in-memory runtime settings snapshot.
2. If disabled, unacknowledged, excluded, or provider-invalid, pass the boundary through without inspecting surrounding text.
3. Positively verify that the focused field is a supported non-secure text control.
4. Snapshot the completed word immediately before the insertion point.
5. Insert the boundary immediately. Keychain/network work never blocks typing.
6. Run local candidate filtering.
7. Resolve a correction asynchronously through the selected OpenAI-compatible provider.
8. Validate the response locally as a conservative typo-scale single-token edit.
9. Before applying it, re-check enabled/privacy/exclusion/provider state, client identity, secure-field state, original target text, and cursor-restoration capability.
10. Replace only the completed word, restore the rebased caret, and update the concurrent correction ledger.

Changing provider configuration while a request is in flight invalidates that response before mutation.

## Shared runtime settings

`SharedAutocorrectSettings` writes to the suite `dev.notsonata.autocorrect.shared` and emits a distributed settings-change notification. The input method's `RuntimeSettingsCache` reloads outside the typing hot path and serves immutable snapshots to boundary handling.

Persisted values are configuration only. Typed text never enters the settings subsystem.

The default state is fail closed:

- autocorrect disabled,
- privacy acknowledgment false,
- Gemini selected,
- model `gemini-3.7-flash`,
- no excluded applications.

## Correction providers

`CorrectionProvider` isolates provider/network behavior. The reusable OpenAI-compatible transport currently supports:

- Google Gemini through `https://generativelanguage.googleapis.com/v1beta/openai/`,
- OpenRouter through `https://openrouter.ai/api/v1/`,
- custom OpenAI-compatible base URLs.

Google Gemini defaults to `gemini-3.7-flash` with low reasoning effort. The settings app can override the model identifier without changing the transport.

Provider API keys are stored in macOS Keychain. Typed text is never stored in Keychain.

## Concurrent correction ledger

Every correction job keeps only an opaque in-memory identifier, the original completed word, and its current UTF-16 range. Mutations before pending jobs rebase them; overlapping mutations discard them. Successful corrections commit only after cursor restoration succeeds.

## Planned PR sequence

1. **InputMethodKit POC**: completed.
2. **Concurrent edit engine**: completed.
3. **OpenAI-compatible provider layer**: completed.
4. **Correction safety + runtime integration**: completed.
5. **Menu-bar/settings app**: current.
6. **English/Filipino/Taglish quality suite**: regression corpus, do-not-change cases, latency and correction-quality tests.
7. **Packaging**: signing, notarization, install/update path, compatibility matrix.
