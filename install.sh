#!/usr/bin/env bash
# jh-zsh-theme installer.
#
# Sets up: oh-my-zsh (if missing) + Powerlevel10k theme + this repo's p10k.zsh config +
# MesloLGS NF fonts (best-effort, system-wide if root/sudo available, else user-local).
#
# Usage:
#   git clone https://github.com/githubhjs/jh-zsh-theme.git
#   cd jh-zsh-theme && ./install.sh
#
# Safe to re-run: existing ~/.zshrc / ~/.p10k.zsh are backed up with a timestamp suffix
# before being touched, never silently overwritten.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"

echo "==> jh-zsh-theme installer"

# 1. oh-my-zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "==> Installing oh-my-zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
  echo "==> oh-my-zsh already present, skipping."
fi

# 2. Powerlevel10k theme
P10K_DIR="$HOME/.oh-my-zsh/custom/themes/powerlevel10k"
if [ ! -d "$P10K_DIR" ]; then
  echo "==> Cloning powerlevel10k..."
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
else
  echo "==> powerlevel10k already present, skipping clone (run 'git -C $P10K_DIR pull' to update)."
fi

# 3. Install this repo's p10k.zsh config
if [ -f "$HOME/.p10k.zsh" ]; then
  cp "$HOME/.p10k.zsh" "$HOME/.p10k.zsh.bak.$TIMESTAMP"
  echo "==> Backed up existing ~/.p10k.zsh -> ~/.p10k.zsh.bak.$TIMESTAMP"
fi
cp "$REPO_DIR/p10k.zsh" "$HOME/.p10k.zsh"
echo "==> Installed ~/.p10k.zsh"

# 4. Wire ~/.zshrc: instant-prompt block (top), ZSH_THEME, source ~/.p10k.zsh (bottom)
ZSHRC="$HOME/.zshrc"
if [ -f "$ZSHRC" ]; then
  cp "$ZSHRC" "$ZSHRC.bak.$TIMESTAMP"
  echo "==> Backed up existing ~/.zshrc -> ~/.zshrc.bak.$TIMESTAMP"
else
  touch "$ZSHRC"
fi

INSTANT_PROMPT_MARKER='Enable Powerlevel10k instant prompt'
if ! grep -q "$INSTANT_PROMPT_MARKER" "$ZSHRC"; then
  echo "==> Prepending instant-prompt block to ~/.zshrc"
  TMP="$(mktemp)"
  cat "$REPO_DIR/snippets/instant-prompt.zsh" "$ZSHRC" > "$TMP"
  mv "$TMP" "$ZSHRC"
fi

if grep -q '^ZSH_THEME=' "$ZSHRC"; then
  sed -i.bak-themeline 's/^ZSH_THEME=.*/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$ZSHRC"
  rm -f "$ZSHRC.bak-themeline"
  echo "==> Updated existing ZSH_THEME line in ~/.zshrc"
else
  echo 'ZSH_THEME="powerlevel10k/powerlevel10k"' >> "$ZSHRC"
  echo "==> Appended ZSH_THEME line to ~/.zshrc"
fi

SOURCE_MARKER='source ~/.p10k.zsh'
if ! grep -q "$SOURCE_MARKER" "$ZSHRC"; then
  {
    echo ""
    echo "# To customize prompt, run \`p10k configure\` or edit ~/.p10k.zsh."
    echo "[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh"
  } >> "$ZSHRC"
  echo "==> Appended '[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh' to ~/.zshrc"
fi

# 5. Fonts: MesloLGS NF (best-effort; skip gracefully if no network or no write access)
echo "==> Installing MesloLGS NF fonts..."
bash "$REPO_DIR/install-fonts.sh" || echo "==> Font install failed/skipped -- see install-fonts.sh to retry manually."

echo ""
echo "==> Done. Start a new shell (or 'exec zsh') to see the prompt."
echo "==> If glyphs render as boxes, set your TERMINAL EMULATOR's font to 'MesloLGS NF'"
echo "    (installing the font on the machine Claude Code/zsh runs on does NOT help if you're"
echo "    connecting to it over SSH from a different machine -- the font must be set in the"
echo "    terminal app you're looking at, e.g. iTerm2/Windows Terminal/GNOME Terminal)."
