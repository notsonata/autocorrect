#!/bin/zsh
set -euo pipefail

PACKAGE_DIR="$(cd "$(dirname "$0")" && pwd)"
INPUT_SOURCE="$PACKAGE_DIR/Autocorrect.app"
SETTINGS_SOURCE="$PACKAGE_DIR/Autocorrect Settings.app"
INPUT_DEST_DIR="$HOME/Library/Input Methods"
SETTINGS_DEST_DIR="$HOME/Applications"
INPUT_DEST="$INPUT_DEST_DIR/Autocorrect.app"
SETTINGS_DEST="$SETTINGS_DEST_DIR/Autocorrect Settings.app"

if [[ ! -d "$INPUT_SOURCE" || ! -d "$SETTINGS_SOURCE" ]]; then
  echo "This installer must stay next to Autocorrect.app and Autocorrect Settings.app." >&2
  exit 1
fi

osascript -e 'tell application "Autocorrect Settings" to quit' >/dev/null 2>&1 || true
pkill -x "Autocorrect" >/dev/null 2>&1 || true

mkdir -p "$INPUT_DEST_DIR" "$SETTINGS_DEST_DIR"
rm -rf "$INPUT_DEST" "$SETTINGS_DEST"
ditto "$INPUT_SOURCE" "$INPUT_DEST"
ditto "$SETTINGS_SOURCE" "$SETTINGS_DEST"

open "$SETTINGS_DEST"

cat <<'EOF'
Autocorrect is installed for the current user.

Next:
1. Open System Settings > Keyboard > Text Input > Edit.
2. Add or enable Autocorrect as an input source.
3. Grant Autocorrect Accessibility permission when macOS asks.
4. Open Autocorrect Settings from the menu bar, review the privacy disclosure, add an API key, and enable correction.

If the input source does not appear immediately, log out and back in once.
EOF
