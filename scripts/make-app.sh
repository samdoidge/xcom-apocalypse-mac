#!/usr/bin/env bash
# Build a double-clickable .app that launches DOSBox Staging with a config.
set -euo pipefail

CONFIG="${1:-$HOME/Games/XCOMApocalypse/dosbox.conf}"
APP_PATH="${2:-$HOME/Applications/X-COM Apocalypse.app}"

[[ -f "$CONFIG" ]] || { printf 'error: config not found: %s\n' "$CONFIG" >&2; exit 1; }
[[ -d "/Applications/DOSBox Staging.app" ]] \
  || { printf 'error: /Applications/DOSBox Staging.app is missing\n' >&2; exit 1; }

mkdir -p "$(dirname "$APP_PATH")"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

cat > "$tmp/launcher.applescript" <<EOF
do shell script "open -na " & quoted form of "DOSBox Staging" & " --args -conf " & quoted form of "$CONFIG"
EOF

rm -rf "$APP_PATH"
osacompile -o "$APP_PATH" "$tmp/launcher.applescript"

printf 'Built %s\n' "$APP_PATH"
