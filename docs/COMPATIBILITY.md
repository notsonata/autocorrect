# v0.1.0 Compatibility Matrix

This matrix is the manual release gate for the signed and notarized v0.1.0 candidate. CI cannot exercise InputMethodKit against arbitrary foreground applications, so rows must be verified on the actual packaged build before tagging the release.

A row passes only when normal typing remains immediate, the intended misspelling is corrected after a word boundary, the insertion point remains logical during continued typing, and no correction occurs in secure text entry.

| Application | UI stack / surface | Required check | v0.1.0 RC status |
| --- | --- | --- | --- |
| TextEdit | AppKit text view | Baseline English + Taglish correction and continuous typing | Pending manual RC |
| Notes | Native macOS editor | Correction and cursor stability across multi-line notes | Pending manual RC |
| Messages | Native message composer | Casual Taglish, abbreviations preserved, correction before send | Pending manual RC |
| Mail | Native compose window | Paragraph typing and correction without focus loss | Pending manual RC |
| Safari | Web text fields / contenteditable | Plain inputs and a contenteditable editor | Pending manual RC |
| Google Chrome | Chromium web text fields | Plain inputs and a contenteditable editor | Pending manual RC |
| Slack | Electron editor | Message composer correction and cursor stability | Pending manual RC |
| Microsoft Word | Rich text editor | Paragraph typing and selection/cursor stability | Pending manual RC |
| Visual Studio Code | Electron/Monaco | Add app to exclusions and confirm pass-through typing | Pending manual RC |
| Terminal | Terminal text input | Add app to exclusions and confirm pass-through typing | Pending manual RC |
| macOS password field | Secure text field | No surrounding-text inspection or correction | Pending manual RC |

## Installer check

The signed release candidate must be installed from the extracted release using `Install Autocorrect.app`, not from DerivedData. Confirm the installer places the input method and settings companion in their documented per-user locations and can replace an existing installation without requesting administrator privileges.

## Cross-process credential check

The signed release candidate must also pass this functional Keychain test:

1. Install both packaged apps using `Install Autocorrect.app`.
2. In Autocorrect Settings, save a temporary provider API key.
3. Enable the Autocorrect input source and correction.
4. Type a known corpus typo such as `wrld ` in TextEdit.
5. Confirm the input method successfully performs the provider-backed correction without asking for the key again.
6. Remove the temporary key from Autocorrect Settings.

This verifies that the settings companion can write a credential that the separately signed input-method process can read through their common macOS application/keychain group.

## Release rule

Do not publish v0.1.0 while any required row is marked failing. A pending row means the compatibility claim has not yet been made.
