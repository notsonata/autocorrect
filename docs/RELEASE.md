# Release Process

Autocorrect is distributed as a per-user macOS ZIP containing three app bundles: the input method, the menu-bar settings companion, and a native installer with Install and Uninstall controls. Installation notes are included alongside them.

## Default: automatic free GitHub release

A paid Apple Developer account is not required for the default release path.

`MARKETING_VERSION` in `project.yml` is the version source of truth. After the full `Build` workflow succeeds on a push to `main`, GitHub Actions:

1. builds the current version in Release mode,
2. ad-hoc signs all three app bundles with the free `-` identity,
3. verifies their local code signatures,
4. creates `Autocorrect-<version>-macOS.zip` and its SHA-256 checksum,
5. uploads both files as a workflow artifact,
6. checks for GitHub Release `v<version>`,
7. if the release does not exist, creates it against the exact successful commit and attaches both files.

Creating the GitHub Release also creates the Git tag, so there is no separate manual tagging step for the community build.

A later push that still uses the same `MARKETING_VERSION` leaves the existing release unchanged. Bump `MARKETING_VERSION` before publishing the next version.

The community build is ad-hoc signed, not Developer ID signed or Apple-notarized. Users should expect Gatekeeper manual approval on first launch. See `docs/INSTALL.md`.

## Pull-request artifacts

Pull requests run the same package construction and upload the ZIP/checksum through `actions/upload-artifact`. They do not create a tag or GitHub Release. This makes it possible to download and test a candidate directly from the PR's Actions run before merge.

## Local community package

To produce the same free package locally:

```sh
zsh scripts/package-release.sh --unsigned
```

Output:

- `dist/Autocorrect-0.1.0-macOS.zip`
- `dist/Autocorrect-0.1.0-macOS.zip.sha256`

Despite the historical `--unsigned` option name, the final app bundles receive an ad-hoc local code signature after the Xcode build. No Apple certificate or paid membership is involved.

## Keychain behavior without Developer ID

Developer ID builds can use the shared application-group/data-protection Keychain path.

When that entitlement is absent, `KeychainCredentialStore` uses the macOS file-based Keychain and creates the provider credential with an ACL trusting the installed executables at:

- `~/Library/Input Methods/Autocorrect.app/Contents/MacOS/Autocorrect`
- `~/Applications/Autocorrect Settings.app/Contents/MacOS/Autocorrect Settings`

The API key remains a Keychain item. It is not placed in preferences, the release ZIP, logs, or a plaintext credential file.

This fallback is a legacy macOS Keychain mechanism. Because trust is tied to the installed programs, an unsigned/ad-hoc update may cause macOS to request Keychain authorization again.

## Optional Developer ID and notarized package

If a polished public distribution is wanted later, the existing paid path remains available. The Mac must have a Developer ID Application identity available in Keychain. Store notarization credentials once with `notarytool`, then run:

```sh
xcrun notarytool store-credentials autocorrect-notary \
  --apple-id "YOUR_APPLE_ID" \
  --team-id "YOUR_TEAM_ID" \
  --password "YOUR_APP_SPECIFIC_PASSWORD"

AUTOCORRECT_TEAM_ID="YOUR_TEAM_ID" \
AUTOCORRECT_SIGN_IDENTITY="Developer ID Application" \
AUTOCORRECT_NOTARY_PROFILE="autocorrect-notary" \
zsh scripts/package-release.sh --notarize
```

The packaging script verifies all three app signatures and requires the Hardened Runtime. It also verifies that the input method and settings companion carry the same team-prefixed shared application/keychain group. It then submits all three apps to Apple notarization, staples the resulting tickets, asks Gatekeeper to assess the stapled apps, and creates the final ZIP and checksum.

The final ZIP contains:

- `Install Autocorrect.app`
- `Autocorrect.app`
- `Autocorrect Settings.app`
- `README.md`

The installer copies only into per-user locations and does not require administrator privileges.

## Optional signed-release secrets

The existing signed tag workflow requires these repository secrets if Developer ID distribution is enabled later:

- `APPLE_CERTIFICATE_P12_BASE64`
- `APPLE_CERTIFICATE_PASSWORD`
- `APPLE_TEAM_ID`
- `APPLE_ID`
- `APPLE_APP_SPECIFIC_PASSWORD`

No signing certificate, private key, Apple ID password, provider API key, or notarization credential belongs in the repository.

## Release validation

Before treating a community or signed build as stable:

1. Download/extract the exact generated ZIP rather than running from DerivedData.
2. Install through `Install Autocorrect.app`.
3. Complete every required row in `docs/COMPATIBILITY.md`.
4. Complete the installer and cross-process credential checks.
5. Confirm secure fields remain pass-through only.
6. Confirm the GitHub `Build` workflow is green for the release commit.

The automated release mechanism proves the package was built from a green commit. It does not replace the manual real-application compatibility checks.
