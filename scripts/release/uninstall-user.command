#!/bin/zsh
set -euo pipefail

INPUT_DEST="$HOME/Library/Input Methods/Autocorrect.app"
SETTINGS_DEST="$HOME/Applications/Autocorrect Settings.app"

osascript -e 'tell application "Autocorrect Settings" to quit' >/dev/null 2>&1 || true
pkill -x "Autocorrect" >/dev/null 2>&1 || true

rm -rf "$INPUT_DEST" "$SETTINGS_DEST"

cat <<'EOF'
Autocorrect has been removed for the current user.

Provider API keys and preferences were intentionally left in place. Remove API keys from Autocorrect Settings before uninstalling if you want those credentials deleted as well.
EOF
