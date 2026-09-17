#!/usr/bin/env bash
# Installs the 4 MesloLGS NF weights (Regular/Bold/Italic/Bold Italic) --
# the font Powerlevel10k's nerdfont-v3 mode expects.
#
# System-wide (Linux, needs sudo) if possible; falls back to a user-local
# font directory otherwise. macOS goes to ~/Library/Fonts (no sudo needed).
#
# Safe to re-run.

set -euo pipefail

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

WEIGHTS=("Regular" "Bold" "Italic" "Bold%20Italic")
NAMES=("Regular" "Bold" "Italic" "Bold Italic")

echo "==> Downloading MesloLGS NF..."
for i in "${!WEIGHTS[@]}"; do
  w="${WEIGHTS[$i]}"
  n="${NAMES[$i]}"
  curl -fsSL --retry 3 --max-time 90 \
    -o "$TMPDIR/MesloLGS NF ${n}.ttf" \
    "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20${w}.ttf"
  echo "  - MesloLGS NF ${n}.ttf"
done

case "$(uname -s)" in
  Darwin)
    DEST="$HOME/Library/Fonts"
    mkdir -p "$DEST"
    cp "$TMPDIR"/*.ttf "$DEST/"
    echo "==> Installed to $DEST (macOS, user-level -- always readable by all apps for this user)"
    ;;
  Linux)
    if [ "$(id -u)" = "0" ] || sudo -n true 2>/dev/null; then
      DEST="/usr/share/fonts/truetype/meslo-nerd-font"
      sudo mkdir -p "$DEST"
      sudo cp "$TMPDIR"/*.ttf "$DEST/"
      sudo chmod 644 "$DEST"/*.ttf
      sudo fc-cache -f "$DEST" >/dev/null 2>&1 || true
      echo "==> Installed system-wide to $DEST"
    else
      DEST="$HOME/.local/share/fonts"
      mkdir -p "$DEST"
      cp "$TMPDIR"/*.ttf "$DEST/"
      fc-cache -f "$DEST" >/dev/null 2>&1 || true
      echo "==> No passwordless sudo -- installed user-local to $DEST instead"
    fi
    ;;
  *)
    echo "==> Unrecognized OS ($(uname -s)) -- fonts downloaded to $TMPDIR, install manually."
    exit 1
    ;;
esac

echo "==> Verify with: fc-list | grep -i 'MesloLGS NF'  (Linux)  or open Font Book (macOS)"
