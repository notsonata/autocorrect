# Autocorrect

A native macOS autocorrection utility designed for seamless English, Filipino, and Taglish correction.

## Project principles

- Corrections must never block normal typing.
- Corrections must not move the user's logical insertion point.
- Completed words are evaluated when a word boundary is typed, beginning with Space.
- Typed text is transient and is never intentionally persisted to disk, `UserDefaults`, logs, analytics, or correction history.
- Secure text fields and password entry are never processed.
- AI providers are isolated behind a provider interface.
- Provider API keys are stored only in macOS Keychain.

## Current implementation

PRs #1-#4 established InputMethodKit replacement, concurrent range rebasing, the OpenAI-compatible provider layer, and conservative live AI safety guards.

PR #5 adds a native SwiftUI menu-bar companion and shared runtime configuration:

- autocorrect defaults off,
- explicit privacy acknowledgment is required before network correction,
- Google Gemini, OpenRouter, and custom OpenAI-compatible provider selection,
- per-provider model configuration,
- API-key save/remove through macOS Keychain,
- application exclusion by bundle identifier,
- launch-at-login control,
- live cross-process settings refresh without putting configuration reads on the keystroke hot path.

Only non-sensitive configuration is stored in the shared preferences domain. Typed text and API keys are never stored there.

See [Privacy](docs/PRIVACY.md) and [Architecture](docs/ARCHITECTURE.md).

## Build and install

Requires macOS 14+, Xcode, and XcodeGen.

```sh
brew install xcodegen
xcodegen generate
```

The generated project builds both `Autocorrect` (the input method) and `Autocorrect Settings` (the menu-bar companion). The release packaging/install flow is intentionally deferred to PR #7.

For input-method development you can continue to use:

```sh
zsh scripts/install-input-method.sh
```

Then open **System Settings > Keyboard > Text Input > Edit**, enable Autocorrect as an input source, and grant the installed input method Accessibility permission for secure-field and selection-safety checks.

## Manual acceptance checks

1. Open `Autocorrect Settings` and acknowledge the privacy disclosure.
2. Store a Gemini API key, keep `gemini-3.7-flash`, and enable Autocorrect.
3. Confirm misspellings correct while continuous typing and cursor position remain uninterrupted.
4. Disable Autocorrect from the menu bar and confirm subsequent boundaries do not inspect or correct text.
5. Add an application to Excluded Applications and confirm it receives pass-through typing.
6. Change provider/model while a request is pending and confirm the stale result is discarded.
7. Confirm password and secure fields remain pass-through only.

Development is tracked through pull requests against `main`.
