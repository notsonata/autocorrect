# Installing Autocorrect

Autocorrect requires macOS 14 or later.

## Install

1. Download `Autocorrect-<version>-macOS.zip` from the GitHub Release.
2. Extract the ZIP.
3. Drag `Autocorrect.app` to `/Applications`.
4. Open `Autocorrect.app` once.
5. Autocorrect automatically installs its embedded input method into `~/Library/Input Methods/Autocorrect.app`.
6. Open **System Settings > Keyboard > Text Input > Edit** and add or enable **Autocorrect** as an input source.
7. Configure your provider and API key in Autocorrect, acknowledge the privacy disclosure, and enable correction.

There is no separate installer or settings application.

## Updating

Replace `/Applications/Autocorrect.app` with the newer version and open it once. The app compares the embedded input-method version with the installed copy and updates `~/Library/Input Methods/Autocorrect.app` automatically when needed.

Preferences and Keychain credentials remain in place across updates.

## Removing

Remove `/Applications/Autocorrect.app` and `~/Library/Input Methods/Autocorrect.app`.

Provider API keys and preferences are intentionally not deleted automatically. Remove API keys from Autocorrect before deleting the application if you want those credentials removed from Keychain.

## Gatekeeper

Community releases are built by GitHub Actions and ad-hoc signed. They are not Developer ID notarized. macOS may block the first launch. If you trust the release, use **System Settings > Privacy & Security > Open Anyway** for `Autocorrect.app`.
