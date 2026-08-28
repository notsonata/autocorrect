# Autocorrect

A native macOS autocorrection utility for seamless English, Filipino, and Taglish correction.

## Project principles

- Corrections must never block normal typing.
- Corrections must not move the user's logical insertion point.
- Completed words are evaluated at word boundaries.
- Typed text is transient and is never intentionally persisted to disk, `UserDefaults`, logs, analytics, or correction history.
- Secure text fields and password entry are never processed.
- AI providers are isolated behind an OpenAI-compatible provider interface.
- Provider API keys are stored only in macOS Keychain.

## Application layout

Autocorrect is distributed as one macOS application:

```text
Autocorrect.app
└── Contents/Resources/InputMethod/Autocorrect.app
```

The nested bundle is an implementation detail required by InputMethodKit. When the main app launches, it installs or updates that embedded input method at:

```text
~/Library/Input Methods/Autocorrect.app
```

The visible `Autocorrect.app` owns the settings window, menu-bar controls, provider configuration, API-key management, app exclusions, and launch-at-login behavior. There is no separate settings application or installer application.

## Build

Requires macOS 14+, Xcode, and XcodeGen.

```sh
brew install xcodegen
xcodegen generate
```

For a complete community release package:

```sh
zsh scripts/package-release.sh --unsigned
```

This produces one file:

```text
dist/Autocorrect-0.1.1-macOS.zip
```

The ZIP contains only `Autocorrect.app`.

## Install

1. Download and extract the release ZIP.
2. Drag `Autocorrect.app` to `/Applications`.
3. Open Autocorrect once. It installs its embedded input method automatically for the current user.
4. Open **System Settings > Keyboard > Text Input > Edit** and add or enable **Autocorrect** as an input source.
5. Configure the AI provider and API key in the Autocorrect window.
6. Review the privacy disclosure and enable autocorrection.

Community releases are ad-hoc signed rather than Developer ID notarized. macOS may require **System Settings > Privacy & Security > Open Anyway** on first launch.

## Releases

Every successful `main` build packages the app on GitHub Actions. If `v<MARKETING_VERSION>` does not already exist, the workflow automatically creates the tag and GitHub Release and attaches the single macOS ZIP.

The next version is controlled by `MARKETING_VERSION` in `project.yml`.

See [Privacy](docs/PRIVACY.md), [Architecture](docs/ARCHITECTURE.md), and [Quality](docs/QUALITY.md).
