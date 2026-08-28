#!/bin/zsh
set -euo pipefail

if (( $# != 2 )); then
  echo "Usage: zsh scripts/release/verify-signed-release.sh <Autocorrect.app> <Autocorrect Settings.app>" >&2
  exit 64
fi

INPUT_APP="$1"
SETTINGS_APP="$2"
EXPECTED_SUFFIX="dev.notsonata.autocorrect.shared"
EXPECTED_TEAM="${AUTOCORRECT_TEAM_ID:-}"

for app in "$INPUT_APP" "$SETTINGS_APP"; do
  if [[ ! -d "$app" ]]; then
    echo "Missing app bundle: $app" >&2
    exit 1
  fi

  codesign --verify --deep --strict --verbose=2 "$app"

  details="$(codesign --display --verbose=4 "$app" 2>&1)"
  team="$(printf '%s\n' "$details" | awk -F= '/^TeamIdentifier=/{print $2; exit}')"

  if [[ -z "$team" || "$team" == "not set" ]]; then
    echo "No Developer Team identifier found in $app" >&2
    exit 1
  fi

  if [[ -n "$EXPECTED_TEAM" && "$team" != "$EXPECTED_TEAM" ]]; then
    echo "Unexpected TeamIdentifier for $app: $team" >&2
    exit 1
  fi

  if ! printf '%s\n' "$details" | grep -q 'runtime'; then
    echo "Hardened Runtime flag is missing from $app" >&2
    exit 1
  fi

  entitlements="$(mktemp)"
  trap 'rm -f "$entitlements"' EXIT
  codesign --display --entitlements - --xml "$app" > "$entitlements" 2>/dev/null

  expected_group="$team.$EXPECTED_SUFFIX"
  if ! /usr/libexec/PlistBuddy -c 'Print :com.apple.security.application-groups' "$entitlements" 2>/dev/null | grep -Fq "$expected_group"; then
    echo "Shared application/keychain group $expected_group is missing from $app" >&2
    exit 1
  fi

  rm -f "$entitlements"
  trap - EXIT

done

input_team="$(codesign --display --verbose=4 "$INPUT_APP" 2>&1 | awk -F= '/^TeamIdentifier=/{print $2; exit}')"
settings_team="$(codesign --display --verbose=4 "$SETTINGS_APP" 2>&1 | awk -F= '/^TeamIdentifier=/{print $2; exit}')"

if [[ "$input_team" != "$settings_team" ]]; then
  echo "App bundles are signed by different teams." >&2
  exit 1
fi

echo "Signed release verification passed for team $input_team."
