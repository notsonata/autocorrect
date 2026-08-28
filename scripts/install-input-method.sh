#!/bin/zsh
set -euo pipefail

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "xcodegen is required. Install it with: brew install xcodegen" >&2
  exit 1
fi

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

xcodegen generate
xcodebuild \
  -project Autocorrect.xcodeproj \
  -scheme AutocorrectInputMethod \
  -configuration Debug \
  -derivedDataPath .build \
  build

SOURCE_APP="$ROOT_DIR/.build/Build/Products/Debug/Autocorrect.app"
DEST_DIR="$HOME/Library/Input Methods"
DEST_APP="$DEST_DIR/Autocorrect.app"

mkdir -p "$DEST_DIR"
rm -rf "$DEST_APP"
cp -R "$SOURCE_APP" "$DEST_APP"

cat <<'EOF'
Installed Autocorrect.app in ~/Library/Input Methods.

Next:
1. Open System Settings > Keyboard > Text Input > Edit.
2. Add/enable Autocorrect as an input source.
3. Grant Autocorrect Accessibility permission when testing corrections.
4. If the input source does not appear immediately, log out and back in once.

POC test: type "hello wrld keep typing". After Space following "wrld",
typing should continue immediately and "wrld" should become "world" about 0.8s later.
EOF
