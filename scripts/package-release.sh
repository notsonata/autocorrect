#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

MODE="unsigned"
NOTARIZE=0

while (( $# > 0 )); do
  case "$1" in
    --unsigned)
      MODE="unsigned"
      ;;
    --signed)
      MODE="signed"
      ;;
    --notarize)
      MODE="signed"
      NOTARIZE=1
      ;;
    *)
      echo "Unknown option: $1" >&2
      echo "Usage: zsh scripts/package-release.sh [--unsigned|--signed|--notarize]" >&2
      exit 64
      ;;
  esac
  shift
done

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "Release packaging must run on macOS." >&2
  exit 1
fi

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "xcodegen is required. Install it with: brew install xcodegen" >&2
  exit 1
fi

PROJECT_VERSION="$(awk -F'"' '/MARKETING_VERSION:/ {print $2; exit}' project.yml)"
VERSION="${AUTOCORRECT_VERSION:-$PROJECT_VERSION}"

if [[ -z "$PROJECT_VERSION" || "$VERSION" != "$PROJECT_VERSION" ]]; then
  echo "Release version $VERSION does not match project MARKETING_VERSION $PROJECT_VERSION." >&2
  exit 1
fi

BUILD_DIR="$ROOT_DIR/.release-build"
PRODUCTS_DIR="$BUILD_DIR/Build/Products/Release"
DIST_DIR="$ROOT_DIR/dist"
STAGE_ROOT="$DIST_DIR/stage"
PACKAGE_DIR="$STAGE_ROOT/Autocorrect-$VERSION"
ARCHIVE="$DIST_DIR/Autocorrect-$VERSION-macOS.zip"

rm -rf "$BUILD_DIR" "$STAGE_ROOT" "$ARCHIVE" "$ARCHIVE.sha256"
mkdir -p "$DIST_DIR"

xcodegen generate

build_args=(
  xcodebuild
  -project Autocorrect.xcodeproj
  -scheme AutocorrectInputMethod
  -configuration Release
  -derivedDataPath "$BUILD_DIR"
  clean
  build
)

if [[ "$MODE" == "signed" ]]; then
  : "${AUTOCORRECT_TEAM_ID:?AUTOCORRECT_TEAM_ID is required for signed builds}"
  : "${AUTOCORRECT_SIGN_IDENTITY:?AUTOCORRECT_SIGN_IDENTITY is required for signed builds}"

  build_args+=(
    DEVELOPMENT_TEAM="$AUTOCORRECT_TEAM_ID"
    CODE_SIGN_STYLE=Manual
    CODE_SIGN_IDENTITY="$AUTOCORRECT_SIGN_IDENTITY"
    OTHER_CODE_SIGN_FLAGS=--timestamp
  )
else
  build_args+=(CODE_SIGNING_ALLOWED=NO)
fi

"${build_args[@]}"

INPUT_APP="$PRODUCTS_DIR/Autocorrect.app"
SETTINGS_APP="$PRODUCTS_DIR/Autocorrect Settings.app"

for app in "$INPUT_APP" "$SETTINGS_APP"; do
  if [[ ! -d "$app" ]]; then
    echo "Expected build product is missing: $app" >&2
    exit 1
  fi
done

if [[ "$MODE" == "signed" ]]; then
  zsh scripts/release/verify-signed-release.sh "$INPUT_APP" "$SETTINGS_APP"
fi

if (( NOTARIZE )); then
  : "${AUTOCORRECT_NOTARY_PROFILE:?AUTOCORRECT_NOTARY_PROFILE is required with --notarize}"
  NOTARY_DIR="$DIST_DIR/notary"
  rm -rf "$NOTARY_DIR"
  mkdir -p "$NOTARY_DIR"

  for app in "$INPUT_APP" "$SETTINGS_APP"; do
    name="$(basename "$app" .app | tr ' ' '-')"
    submission="$NOTARY_DIR/$name.zip"

    ditto -c -k --sequesterRsrc --keepParent "$app" "$submission"
    xcrun notarytool submit "$submission" \
      --keychain-profile "$AUTOCORRECT_NOTARY_PROFILE" \
      --wait
    xcrun stapler staple "$app"
    xcrun stapler validate "$app"
    spctl --assess --type execute --verbose=4 "$app"
  done
fi

mkdir -p "$PACKAGE_DIR"
ditto "$INPUT_APP" "$PACKAGE_DIR/Autocorrect.app"
ditto "$SETTINGS_APP" "$PACKAGE_DIR/Autocorrect Settings.app"
cp scripts/release/install-user.command "$PACKAGE_DIR/Install Autocorrect.command"
cp scripts/release/uninstall-user.command "$PACKAGE_DIR/Uninstall Autocorrect.command"
cp docs/INSTALL.md "$PACKAGE_DIR/README.md"
chmod +x "$PACKAGE_DIR/Install Autocorrect.command" "$PACKAGE_DIR/Uninstall Autocorrect.command"

ditto -c -k --sequesterRsrc --keepParent "$PACKAGE_DIR" "$ARCHIVE"
shasum -a 256 "$ARCHIVE" > "$ARCHIVE.sha256"

rm -rf "$STAGE_ROOT"

echo "Created $ARCHIVE"
echo "SHA-256: $(cat "$ARCHIVE.sha256")"
