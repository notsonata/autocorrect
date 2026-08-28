# Autocorrect

A native macOS autocorrection utility designed for seamless English, Filipino, and Taglish correction.

## Project principles

- Corrections must never block normal typing.
- Corrections must not move the user's logical insertion point.
- Completed words are evaluated when a word boundary is typed, beginning with Space.
- Typed text is transient and is never intentionally persisted to disk, `UserDefaults`, logs, analytics, or correction history.
- Secure text fields and password entry are never processed.
- AI providers are isolated behind a provider interface. Google Gemini is the first target, authenticated with OAuth.

See [Privacy](docs/PRIVACY.md) and [Architecture](docs/ARCHITECTURE.md).

## Current proof of concept

PR #1 is intentionally offline. It uses InputMethodKit plus a small deterministic typo map to prove the hardest interaction requirement before any AI provider is connected.

When you type:

```text
hello wrld keep typing
```

pressing Space after `wrld` must insert the Space immediately. About 0.8 seconds later, `wrld` changes to `world` while whatever you have typed since remains intact and the live insertion point stays where you are typing.

The POC recognizes these deterministic test words:

- `wrld` → `world`
- `shoud` → `should`
- `tommorow` → `tomorrow`
- `gagwin` → `gagawin`
- `pupnta` → `pupunta`

## Build and install

Requires macOS 14+, Xcode, and XcodeGen.

```sh
brew install xcodegen
zsh scripts/install-input-method.sh
```

Then open **System Settings > Keyboard > Text Input > Edit**, enable Autocorrect as an input source, and grant the installed input method Accessibility permission for the POC's secure-field and selection-safety checks. If macOS does not list a newly installed input method immediately, log out and back in once.

## Manual POC acceptance test

Test at minimum in TextEdit, Notes, Safari, Chrome, and Discord:

1. Enable the Autocorrect input source.
2. Type `hello wrld this keeps moving` without pausing after `wrld`.
3. Confirm the Space after `wrld` appears immediately.
4. Confirm typing remains responsive while the delayed correction is pending.
5. Confirm `wrld` becomes `world` behind the live caret.
6. Confirm no characters typed after `wrld` are lost or reordered.
7. Confirm the caret does not visibly jump back to the corrected word.
8. Confirm password and secure fields receive pass-through typing without correction.

Development is tracked through pull requests against `main`.
