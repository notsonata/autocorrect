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

PRs #1-#5 established InputMethodKit replacement, concurrent range rebasing, provider isolation, conservative live AI safety guards, and the native menu-bar settings companion.

PR #6 adds deterministic English, Filipino, and Taglish quality gates, conservative protected tokens, response-policy regression coverage, and opt-in live Gemini quality/latency evaluation.

The v0.1.0 release work adds:

- a shared signed application/keychain group for the input method and settings companion,
- source-controlled release versioning,
- reproducible per-user ZIP packaging,
- a native signed installer app for install/update/uninstall,
- Developer ID signing and Hardened Runtime verification,
- Apple notarization and stapling hooks,
- a signed release-candidate compatibility matrix,
- automated tagged GitHub Release publishing.

Only non-sensitive configuration is stored in the shared preferences domain. Typed text and API keys are never stored there.

See [Privacy](docs/PRIVACY.md), [Architecture](docs/ARCHITECTURE.md), [Quality](docs/QUALITY.md), [Compatibility](docs/COMPATIBILITY.md), and [Release Process](docs/RELEASE.md).

## Build

Requires macOS 14+, Xcode, and XcodeGen.

```sh
brew install xcodegen
xcodegen generate
```

The generated project builds `Autocorrect` (the input method), `Autocorrect Settings` (the menu-bar companion), and `Autocorrect Installer` (the release installer).

For development input-method installation:

```sh
zsh scripts/install-input-method.sh
```

For a complete unsigned release-layout smoke test:

```sh
zsh scripts/package-release.sh --unsigned
```

Unsigned packages are development artifacts only. Published builds are intended to be Developer ID signed and Apple-notarized. See [Release Process](docs/RELEASE.md).

## Install

Release ZIPs install entirely into the current user's home directory and do not require an administrator password:

- `~/Library/Input Methods/Autocorrect.app`
- `~/Applications/Autocorrect Settings.app`

Open `Install Autocorrect.app` from the extracted release, click **Install Autocorrect**, then enable Autocorrect in **System Settings > Keyboard > Text Input > Edit**. Full instructions are in [INSTALL.md](docs/INSTALL.md).

## Manual acceptance checks

1. Open `Autocorrect Settings` and acknowledge the privacy disclosure.
2. Store a Gemini API key, keep `gemini-3.7-flash`, and enable Autocorrect.
3. Confirm misspellings correct while continuous typing and cursor position remain uninterrupted.
4. Disable Autocorrect from the menu bar and confirm subsequent boundaries do not inspect or correct text.
5. Add an application to Excluded Applications and confirm it receives pass-through typing.
6. Change provider/model while a request is pending and confirm the stale result is discarded.
7. Confirm password and secure fields remain pass-through only.
8. For a signed release candidate, complete every required row plus the installer and cross-process credential checks in [COMPATIBILITY.md](docs/COMPATIBILITY.md).

Development is tracked through pull requests against `main`.
