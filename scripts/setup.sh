#!/usr/bin/env bash
# Install DOSBox Staging, stage X-COM: Apocalypse, write a dosbox.conf,
# and build a double-clickable .app wrapper.
set -euo pipefail

GAME_DIR="${GAME_DIR:-$HOME/Games/XCOMApocalypse}"
APP_PATH="${APP_PATH:-$HOME/Applications/X-COM Apocalypse.app}"
DOSBOX_BIN="${DOSBOX_BIN:-/Applications/DOSBox Staging.app/Contents/MacOS/dosbox}"
CONFIG="$GAME_DIR/dosbox.conf"
SOURCE=""

usage() {
  cat <<'EOF'
Usage: setup.sh [--source <folder-or-gog-installer>]

  --source <path>  Folder containing XCOMAPOC.EXE, or a GOG setup .exe.
                   Omit when the game is already in ~/Games/XCOMApocalypse.

Environment overrides:
  GAME_DIR     default ~/Games/XCOMApocalypse
  APP_PATH     default ~/Applications/X-COM Apocalypse.app
  DOSBOX_BIN   default /Applications/DOSBox Staging.app/Contents/MacOS/dosbox
EOF
}

die() { printf 'error: %s\n' "$*" >&2; exit 1; }
say() { printf '%s\n' "$*"; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source) SOURCE="${2:?--source needs a path}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown argument: $1 (try --help)" ;;
  esac
done

command -v brew >/dev/null 2>&1 || die "Homebrew is required: https://brew.sh"

if brew list --cask dosbox-staging-app >/dev/null 2>&1; then
  say "DOSBox Staging already installed."
else
  say "Installing DOSBox Staging..."
  brew install --cask dosbox-staging-app
fi

[[ -x "$DOSBOX_BIN" ]] || die "DOSBox executable not found: $DOSBOX_BIN"

# 0.83 renamed glshader to shader and folded imgmount into mount.
version_line="$("$DOSBOX_BIN" --version 2>/dev/null | { IFS= read -r line; printf '%s' "$line"; })"
version="${version_line#*version }"
version="${version%% *}"

shader_key=glshader
cd_mount=imgmount
protected_cycles=""
if [[ "$version" =~ ^([0-9]+)\.([0-9]+) ]] \
  && { (( BASH_REMATCH[1] > 0 )) || (( BASH_REMATCH[1] == 0 && BASH_REMATCH[2] >= 83 )); }; then
  shader_key=shader
  cd_mount=mount
  protected_cycles="cpu_cycles_protected = max"
fi

mkdir -p "$GAME_DIR" "$(dirname "$APP_PATH")" "$HOME/Movies/XCOMApocalypse"

if [[ -n "$SOURCE" ]]; then
  [[ -e "$SOURCE" ]] || die "source not found: $SOURCE"
  if [[ -d "$SOURCE" ]]; then
    src="$SOURCE"
  elif [[ -f "$SOURCE" ]]; then
    command -v innoextract >/dev/null 2>&1 || brew install innoextract
    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' EXIT
    say "Extracting GOG installer..."
    innoextract -s -d "$tmp" "$SOURCE" >/dev/null
    exe="$(find "$tmp" -iname 'XCOMAPOC.EXE' -print -quit)"
    [[ -n "$exe" ]] || die "could not find XCOMAPOC.EXE inside $SOURCE"
    src="$(dirname "$exe")"
  else
    die "--source must be a folder or a GOG .exe"
  fi

  if [[ -f "$GAME_DIR/XCOMAPOC.EXE" ]]; then
    say "Game files already in $GAME_DIR; leaving them untouched."
  else
    say "Copying game files to $GAME_DIR..."
    cp -R "$src"/. "$GAME_DIR"/
  fi
fi

[[ -f "$GAME_DIR/XCOMAPOC.EXE" ]] \
  || die "XCOMAPOC.EXE not found in $GAME_DIR. Pass --source <folder with the game files>."

cue="$(find "$GAME_DIR" -maxdepth 3 -iname '*.cue' -print -quit || true)"

if [[ -f "$CONFIG" ]]; then
  say "Keeping existing $CONFIG (delete it to regenerate)."
else
  say "Writing $CONFIG (DOSBox Staging $version rules)..."
  {
    cat <<EOF
# X-COM: Apocalypse — DOSBox Staging
[sdl]
fullscreen = true

[capture]
capture_dir = $HOME/Movies/XCOMApocalypse

[dosbox]
machine = svga_s3
memsize = 16

[cpu]
cpu_cycles = max
EOF
    if [[ -n "$protected_cycles" ]]; then
      printf '%s\n' "$protected_cycles"
    fi
    cat <<EOF

[render]
$shader_key = sharp

[sblaster]
sbtype = sb16
irq = 7

[autoexec]
@echo off
mount C "$GAME_DIR"
EOF
    if [[ -n "$cue" ]]; then
      printf '%s D "%s" -t cdrom\n' "$cd_mount" "$cue"
    else
      say "warning: no .cue image found; the game may ask for the CD." >&2
    fi
    cat <<EOF
C:
xcomapoc.exe
exit
EOF
  } > "$CONFIG"
fi

"$(cd "$(dirname "$0")" && pwd)/make-app.sh" "$CONFIG" "$APP_PATH"

say ""
say "Done."
say "  Launch:  open -na \"DOSBox Staging\" --args -conf \"$CONFIG\""
say "  Or open: $APP_PATH"
