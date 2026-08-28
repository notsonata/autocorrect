# Installing Autocorrect 0.1.0

Autocorrect requires macOS 14 or later.

## Install

1. Keep `Autocorrect.app`, `Autocorrect Settings.app`, and `Install Autocorrect.command` together in the extracted release folder.
2. Double-click `Install Autocorrect.command`.
3. Open **System Settings > Keyboard > Text Input > Edit** and add or enable **Autocorrect** as an input source.
4. Grant the Autocorrect input method Accessibility permission when macOS requests it.
5. Open **Autocorrect Settings** from the menu bar.
6. Review and acknowledge the privacy disclosure, choose a provider, save the provider API key, then enable Autocorrect.

The installer uses only per-user locations:

- `~/Library/Input Methods/Autocorrect.app`
- `~/Applications/Autocorrect Settings.app`

No administrator password is required.

If the input source does not appear immediately after installation, log out and back in once.

## Update

Run the installer from the newer release. It replaces both app bundles while preserving preferences and Keychain credentials.

## Uninstall

Double-click `Uninstall Autocorrect.command` from a release folder, or remove the two installed app bundles manually.

The uninstaller intentionally preserves preferences and provider credentials. If you want an API key removed from Keychain, remove it from Autocorrect Settings before uninstalling.

## Gatekeeper

Official release artifacts are intended to be signed with a Developer ID Application certificate and notarized by Apple. Do not bypass Gatekeeper or strip quarantine attributes from a release artifact.
