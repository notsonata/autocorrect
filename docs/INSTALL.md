# Installing Autocorrect 0.1.0

Autocorrect requires macOS 14 or later.

## Install

1. Keep `Install Autocorrect.app`, `Autocorrect.app`, and `Autocorrect Settings.app` together in the extracted release folder.
2. Open `Install Autocorrect.app` and click **Install Autocorrect**.
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

Open `Install Autocorrect.app` from the newer release and install again. It replaces both installed app bundles while preserving preferences and Keychain credentials.

## Uninstall

Open `Install Autocorrect.app` from a release folder and click **Uninstall**, or remove the two installed app bundles manually.

Uninstall intentionally preserves preferences and provider credentials. If you want an API key removed from Keychain, remove it from Autocorrect Settings before uninstalling.

## Gatekeeper

Official release artifacts are intended to contain Developer ID signed and Apple-notarized app bundles, including the installer. Do not bypass Gatekeeper or strip quarantine attributes from a release artifact.
