# Release Process

Autocorrect is distributed as one ZIP containing one visible application bundle.

```text
Autocorrect-<version>-macOS.zip
└── Autocorrect.app
```

The main app contains an embedded InputMethodKit app under `Contents/Resources/InputMethod/Autocorrect.app`. It installs that component into the current user's `~/Library/Input Methods` directory when launched.

## Community build

The default release path does not require an Apple Developer membership:

```sh
zsh scripts/package-release.sh --unsigned
```

The build is ad-hoc signed after compilation so the app and its embedded input method have valid local code signatures. It is not Developer ID identified or notarized, so Gatekeeper may require manual approval on first launch.

The command produces only:

```text
dist/Autocorrect-<version>-macOS.zip
```

No checksum sidecar, installer app, settings app, or README is placed beside the application in the ZIP.

## GitHub automatic release

A successful push to `main`:

1. builds and tests Autocorrect on a macOS runner,
2. creates the single-app ZIP,
3. uploads that ZIP as the workflow artifact,
4. reads `MARKETING_VERSION` from `project.yml`,
5. creates tag `v<MARKETING_VERSION>` if its GitHub Release does not already exist,
6. publishes the ZIP as the only release asset.

The workflow never rewrites an existing versioned release. Bump `MARKETING_VERSION` before publishing the next release.

## Optional Developer ID build

`scripts/package-release.sh --signed` and `--notarize` remain available for a future paid Developer ID distribution path. The signing verifier checks both the outer app and embedded input method. This path is not required for community releases.
