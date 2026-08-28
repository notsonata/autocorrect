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

PR #7 adds release packaging, the native installer, optional Developer ID signing/notarization support, and release-candidate compatibility checks.

The default distribution path does **not** require a paid Apple Developer account:

- every PR build produces a downloadable unsigned community artifact,
- every successful push to `main` builds the current `MARKETING_VERSION`,
- GitHub automatically creates `v<MARKETING_VERSION>` when that version does not already have a release,
- the macOS ZIP and SHA-256 checksum are attached to the GitHub Release,
- community builds are ad-hoc signed locally for macOS runtime identity but are not Developer ID signed or notarized,
- Gatekeeper may therefore require manual approval on first launch.

When a Developer ID application-group entitlement is unavailable, API keys remain in macOS Keychain through the local file-based Keychain ACL fallback. They are not written to preferences or plaintext files.

Only non-sensitive configuration is stored in the shared preferences domain. Typed text and API keys are never stored there.

See [Privacy](docs/PRIVACY.md), [Architecture](docs/ARCHITECTURE.md), [Quality](docs/QUALITY.md), [Compatibility](docs/COMPATIBILITY.md), and [Release Process](docs/RELEASE.md).

## Build

Requires macOS 14+, Xcode, and XcodeGen for local builds.

```sh
brew install xcodegen
xcodegen generate
```

The generated project builds `Autocorrect` (the input method), `Autocorrect Settings` (the menu-bar companion), and `Autocorrect Installer` (the release installer).

For development input-method installation:

```sh
zsh scripts/install-input-method.sh
```

For the same free community package produced by GitHub Actions:

```sh
zsh scripts/package-release.sh --unsigned
```

The package script performs an ad-hoc code signature with no Apple certificate. This is free and is not equivalent to Developer ID signing/notarization.

## Install

Release ZIPs install entirely into the current user's home directory and do not require an administrator password:

- `~/Library/Input Methods/Autocorrect.app`
- `~/Applications/Autocorrect Settings.app`

Open `Install Autocorrect.app` from the extracted release, click **Install Autocorrect**, then enable Autocorrect in **System Settings > Keyboard > Text Input > Edit**. Because the free GitHub build is not notarized, macOS may require **System Settings > Privacy & Security > Open Anyway** for first launch. Full instructions are in [INSTALL.md](docs/INSTALL.md).

## Automatic releases

`MARKETING_VERSION` in `project.yml` is the release version source of truth.

After a successful `main` build, GitHub Actions checks for `v<MARKETING_VERSION>`. If no GitHub Release exists for that version, the workflow creates the tag against the exact tested commit and publishes the package automatically. Further commits using the same version do not overwrite that release. Bump `MARKETING_VERSION` before the next release.

## Manual acceptance checks

1. Open `Autocorrect Settings` and acknowledge the privacy disclosure.
2. Store a Gemini API key, keep `gemini-3.7-flash`, and enable Autocorrect.
3. Confirm misspellings correct while continuous typing and cursor position remain uninterrupted.
4. Disable Autocorrect from the menu bar and confirm subsequent boundaries do not inspect or correct text.
5. Add an application to Excluded Applications and confirm it receives pass-through typing.
6. Change provider/model while a request is pending and confirm the stale result is discarded.
7. Confirm password and secure fields remain pass-through only.
8. Complete the compatibility matrix on the packaged build before calling a version stable.

Development is tracked through pull requests against `main`.
