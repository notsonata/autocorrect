# Autocorrect

A native macOS autocorrection utility designed for seamless English, Filipino, and Taglish correction.

## Project principles

- Corrections must never block normal typing.
- Corrections must not move the user's logical insertion point.
- Completed words are evaluated when a word boundary is typed, beginning with Space.
- Typed text is transient and is never intentionally persisted to disk, `UserDefaults`, logs, analytics, or correction history.
- Secure text fields and password entry are never processed.
- AI providers are isolated behind a provider interface.
- Network providers use an OpenAI-compatible Chat Completions transport where possible.
- Provider API keys are stored only in macOS Keychain.

Google Gemini is the first network target through Google's OpenAI-compatible Gemini endpoint. The same transport is designed to support OpenRouter and custom OpenAI-compatible endpoints by changing the base URL, model, and credential.

See [Privacy](docs/PRIVACY.md) and [Architecture](docs/ARCHITECTURE.md).

## Current implementation

PR #1 proved seamless delayed replacement through InputMethodKit. PR #2 added multiple concurrent correction jobs, range rebasing, stale-edit cancellation, and additional word boundaries. PR #3 added the OpenAI-compatible provider layer, Gemini preset, Keychain credential storage, bounded context, and ephemeral networking.

The current runtime path now uses the Gemini provider when a Gemini API key exists in Keychain. Before any request is sent, a local safety policy rejects already-known words, short tokens, URL/email/code/secret-like fragments, acronyms, mixed-case identifiers, and likely mid-sentence proper nouns. Provider output is accepted only when it is a single word-like token, preserves capitalization style, and stays within a conservative edit-distance bound from the original word.

Provider failures, missing API keys, rejected candidates, rejected responses, stale edits, secure fields, and unverifiable fields all degrade to normal pass-through typing.

Provider/model selection and API-key entry UI are intentionally deferred to the menu-bar/settings PR.

## Build and install

Requires macOS 14+, Xcode, and XcodeGen.

```sh
brew install xcodegen
zsh scripts/install-input-method.sh
```

Then open **System Settings > Keyboard > Text Input > Edit**, enable Autocorrect as an input source, and grant the installed input method Accessibility permission for secure-field and selection-safety checks. If macOS does not list a newly installed input method immediately, log out and back in once.

## Manual input-method acceptance test

Test at minimum in TextEdit, Notes, Safari, Chrome, and Discord:

1. Enable the Autocorrect input source.
2. Type continuously while corrections are pending and confirm every boundary appears immediately.
3. Confirm corrections can land out of order without corrupting later text.
4. Confirm no characters typed after a corrected word are lost or reordered.
5. Confirm the caret does not visibly jump back to corrected words.
6. Confirm correctly spelled common words do not trigger visible mutations.
7. Confirm URLs, email addresses, hashtags, code-like identifiers, and secret-like tokens remain untouched.
8. Confirm password and secure fields receive pass-through typing without correction.
9. Confirm removing the provider API key causes silent pass-through behavior rather than typing interruption.

Development is tracked through pull requests against `main`.
