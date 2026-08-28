#!/bin/zsh
set -euo pipefail

if (( $# != 1 )); then
  echo "Usage: zsh scripts/release/verify-signed-release.sh <Autocorrect.app>" >&2
  exit 64
fi

APP="$1"
EMBEDDED_INPUT="$APP/Contents/Resources/InputMethod/Autocorrect.app"
EXPECTED_SUFFIX="dev.notsonata.autocorrect.shared"
EXPECTED_TEAM="${AUTOCORRECT_TEAM_ID:-}"
REFERENCE_TEAM=""

for bundle in "$APP" "$EMBEDDED_INPUT"; do
  if [[ ! -d "$bundle" ]]; then
    echo "Missing app bundle: $bundle" >&2
    exit 1
  fi

  codesign --verify --deep --strict --verbose=2 "$bundle"

  details="$(codesign --display --verbose=4 "$bundle" 2>&1)"
  team="$(printf '%s\n' "$details" | awk -F= '/^TeamIdentifier=/{print $2; exit}')"

  if [[ -z "$team" || "$team" == "not set" ]]; then
    echo "No Developer Team identifier found in $bundle" >&2
    exit 1
  fi

  if [[ -n "$EXPECTED_TEAM" && "$team" != "$EXPECTED_TEAM" ]]; then
    echo "Unexpected TeamIdentifier for $bundle: $team" >&2
    exit 1
  fi

  if [[ -n "$REFERENCE_TEAM" && "$team" != "$REFERENCE_TEAM" ]]; then
    echo "Outer app and embedded input method are signed by different teams." >&2
    exit 1
  fi
  REFERENCE_TEAM="$team"

  if ! printf '%s\n' "$details" | grep -q 'runtime'; then
    echo "Hardened Runtime flag is missing from $bundle" >&2
    exit 1
  fi

  entitlements="$(mktemp)"
  trap 'rm -f "$entitlements"' EXIT
  codesign --display --entitlements - --xml "$bundle" > "$entitlements" 2>/dev/null

  expected_group="$team.$EXPECTED_SUFFIX"
  if ! /usr/libexec/PlistBuddy -c 'Print :com.apple.security.application-groups' "$entitlements" 2>/dev/null | grep -Fq "$expected_group"; then
    echo "Shared application/keychain group $expected_group is missing from $bundle" >&2
    exit 1
  fi

  rm -f "$entitlements"
  trap - EXIT
done

echo "Signed release verification passed for team $REFERENCE_TEAM."
