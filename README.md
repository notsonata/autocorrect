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

PR #1 proved seamless delayed replacement through InputMethodKit. PR #2 added multiple concurrent correction jobs, range rebasing, stale-edit cancellation, and additional word boundaries.

The current deterministic test words are:

- `wrld` → `world`
- `shoud` → `should`
- `tommorow` → `tomorrow`
- `gagwin` → `gagawin`
- `pupnta` → `pupunta`

PR #3 introduces the provider layer and Gemini-compatible network transport. It does not yet replace the deterministic runtime path; runtime model selection and safety filtering are introduced in later PRs.

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
2. Type `wrld shoud tommorow gagwin pupnta keep typing here` continuously.
3. Confirm every boundary appears immediately.
4. Confirm typing remains responsive while delayed corrections are pending.
5. Confirm corrections can land out of order without corrupting later text.
6. Confirm no characters typed after a corrected word are lost or reordered.
7. Confirm the caret does not visibly jump back to corrected words.
8. Confirm password and secure fields receive pass-through typing without correction.

Development is tracked through pull requests against `main`.
