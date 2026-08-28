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

## Free GitHub build and Gatekeeper

The default GitHub Release is a free community build. It is ad-hoc code signed but is **not** Developer ID signed or Apple-notarized.

On first launch, macOS may refuse to open an app because the developer cannot be verified. Do not disable Gatekeeper globally and do not strip quarantine attributes. Instead:

1. Try to open the app normally once.
2. Open **System Settings > Privacy & Security**.
3. Use **Open Anyway** for the blocked Autocorrect app.
4. Confirm the macOS prompt.

You may need to approve `Install Autocorrect.app` and `Autocorrect Settings.app` separately. The input method can also require a first-run approval before macOS will load it as an input source.

A future Developer ID/notarized build can use the same package format without these manual approval steps.

## API-key storage in the free build

Provider API keys still live in macOS Keychain. When the paid application-group entitlement is unavailable, the free build uses a macOS Keychain ACL that trusts the installed Autocorrect input method and settings executable. The API key is not written to `UserDefaults`, configuration files, or the release directory.

Because this fallback binds trust to the installed executables, a later unsigned update can cause macOS Keychain to ask for access again. That is expected for the free distribution path.

## Update

Open `Install Autocorrect.app` from the newer release and install again. It replaces both installed app bundles while preserving preferences and Keychain credentials.

## Uninstall

Open `Install Autocorrect.app` from a release folder and click **Uninstall**, or remove the two installed app bundles manually.

Uninstall intentionally preserves preferences and provider credentials. If you want an API key removed from Keychain, remove it from Autocorrect Settings before uninstalling.
