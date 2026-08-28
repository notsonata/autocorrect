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
ARCHIVE="$DIST_DIR/Autocorrect-$VERSION-macOS.zip"

rm -rf "$BUILD_DIR" "$ARCHIVE"
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

APP="$PRODUCTS_DIR/Autocorrect.app"
EMBEDDED_INPUT="$APP/Contents/Resources/InputMethod/Autocorrect.app"

if [[ ! -d "$APP" ]]; then
  echo "Expected build product is missing: $APP" >&2
  exit 1
fi

if [[ ! -d "$EMBEDDED_INPUT" ]]; then
  echo "Embedded input method is missing: $EMBEDDED_INPUT" >&2
  exit 1
fi

if [[ "$MODE" == "signed" ]]; then
  zsh scripts/release/verify-signed-release.sh "$APP"
else
  # Free community builds use ad-hoc signatures only. Do not opt these bundles
  # into Hardened Runtime: without a Developer ID team identity, hardened
  # library validation can reject our own embedded frameworks at launch.
  # The paid Developer ID path above keeps Hardened Runtime enabled.
  codesign --force --deep --sign - "$EMBEDDED_INPUT"
  codesign --force --deep --sign - "$APP"
  codesign --verify --deep --strict --verbose=2 "$APP"

  app_details="$(codesign --display --verbose=4 "$APP" 2>&1)"
  if printf '%s\n' "$app_details" | grep -Eq '^Runtime Version=|flags=.*runtime'; then
    echo "Community app unexpectedly has Hardened Runtime enabled." >&2
    exit 1
  fi

  while IFS= read -r framework; do
    framework_details="$(codesign --display --verbose=4 "$framework" 2>&1)"
    if printf '%s\n' "$framework_details" | grep -Eq '^Runtime Version=|flags=.*runtime'; then
      echo "Community framework unexpectedly has Hardened Runtime enabled: $framework" >&2
      exit 1
    fi
  done < <(find "$APP/Contents" -type d -name '*.framework' -prune -print)
fi

if (( NOTARIZE )); then
  : "${AUTOCORRECT_NOTARY_PROFILE:?AUTOCORRECT_NOTARY_PROFILE is required with --notarize}"
  NOTARY_ZIP="$DIST_DIR/Autocorrect-$VERSION-notary.zip"
  rm -f "$NOTARY_ZIP"

  ditto -c -k --sequesterRsrc --keepParent "$APP" "$NOTARY_ZIP"
  xcrun notarytool submit "$NOTARY_ZIP" \
    --keychain-profile "$AUTOCORRECT_NOTARY_PROFILE" \
    --wait
  xcrun stapler staple "$APP"
  xcrun stapler validate "$APP"
  spctl --assess --type execute --verbose=4 "$APP"
  rm -f "$NOTARY_ZIP"
fi

ditto -c -k --sequesterRsrc --keepParent "$APP" "$ARCHIVE"

echo "Created $ARCHIVE"
