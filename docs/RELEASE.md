# Release Process

v0.1.0 is distributed as a per-user macOS ZIP containing the input method, the menu-bar settings companion, an installer, an uninstaller, and installation notes.

## Local unsigned package

Use this for packaging smoke tests only:

```sh
zsh scripts/package-release.sh --unsigned
```

Output:

- `dist/Autocorrect-0.1.0-macOS.zip`
- `dist/Autocorrect-0.1.0-macOS.zip.sha256`

Unsigned packages are not release artifacts.

## Local signed and notarized package

The Mac must have the intended Developer ID Application identity available in Keychain. Store notarization credentials once with `notarytool`, then run:

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

The packaging script verifies both app signatures, requires the Hardened Runtime, verifies that both apps carry the same team-prefixed shared application/keychain group, submits each app to Apple notarization, staples the resulting tickets, asks Gatekeeper to assess the stapled apps, then creates the final ZIP and checksum.

## GitHub Actions secrets

The tag release workflow requires these repository secrets:

- `APPLE_CERTIFICATE_P12_BASE64`: base64-encoded Developer ID Application `.p12`
- `APPLE_CERTIFICATE_PASSWORD`: password for the `.p12`
- `APPLE_TEAM_ID`: Apple Developer Team ID
- `APPLE_ID`: Apple ID used for notarization
- `APPLE_APP_SPECIFIC_PASSWORD`: app-specific password for notarization

No signing certificate, private key, Apple ID password, API key, or notarization credential belongs in the repository.

## Signed release-candidate gate

Before creating the tag:

1. Build a signed and notarized candidate with `scripts/package-release.sh --notarize`.
2. Install it from the generated ZIP, not from DerivedData.
3. Complete every required row in `docs/COMPATIBILITY.md` on the actual packaged build.
4. Complete the cross-process credential check in `docs/COMPATIBILITY.md`.
5. Confirm the input method remains pass-through in secure text fields.
6. Confirm the GitHub `Build` workflow is green on the release commit.
7. Confirm `git diff` is clean and the release commit is the intended commit.

Do not tag a candidate with failing or unverified required release checks.

## Publish v0.1.0

After the signed RC gate passes:

```sh
git tag v0.1.0
git push origin v0.1.0
```

The `Release` workflow imports the Developer ID certificate into an ephemeral runner Keychain, configures `notarytool`, rebuilds the apps from the tagged commit, signs and notarizes them, generates the ZIP and SHA-256 file, then creates the GitHub Release.

The release script rejects a tag version that does not match `MARKETING_VERSION` in `project.yml`.
