#!/usr/bin/env bash
#
# claude-omarchy-mac — installer (macOS only)
#
# Installs:
#   - ~/.local/bin/claude-session   (global-hotkey launcher for Claude Code)
#   - ~/.local/bin/claude-usage     (official usage % reader + OAuth auto-refresh)
#   - ~/.config/swiftbar/plugins/claude.5m.sh  (menu-bar widget)
#   - SwiftBar (via Homebrew) + ccusage (via npm)
#   - optional skhd hotkey  (ctrl + alt - a)  if skhd is present
#
# After running this, the user must run:  claude auth login
# (interactive browser sign-in) so the usage percentages can be read.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
BIN="$HOME/.local/bin"
PLUGINS="$HOME/.config/swiftbar/plugins"

say() { printf '\033[1;35m==>\033[0m %s\n' "$1"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$1"; }

# 1. macOS only -------------------------------------------------------------
if [ "$(uname)" != "Darwin" ]; then
  echo "This tool works only on macOS." >&2
  exit 1
fi

# 2. Homebrew ---------------------------------------------------------------
if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew is required. Install it from https://brew.sh and re-run." >&2
  exit 1
fi

# 3. SwiftBar (menu-bar host) ----------------------------------------------
if ! brew list --cask swiftbar >/dev/null 2>&1; then
  say "Installing SwiftBar..."
  brew install --cask swiftbar
else
  say "SwiftBar already installed."
fi

# 4. ccusage (local usage/cost, Node CLI) ----------------------------------
if ! command -v ccusage >/dev/null 2>&1; then
  if ! command -v npm >/dev/null 2>&1; then
    echo "npm is required for ccusage. Install Node first:  brew install node" >&2
    exit 1
  fi
  say "Installing ccusage (npm global)..."
  npm install -g ccusage
else
  say "ccusage already installed."
fi

# 5. Claude Code CLI (needed for the official %) ----------------------------
if ! command -v claude >/dev/null 2>&1; then
  warn "'claude' (Claude Code CLI) not found in PATH."
  warn "Install it and sign in with a Claude Pro/Max subscription for the usage %."
fi

# 6. Ghostty (used by the launcher) ----------------------------------------
if [ ! -d "/Applications/Ghostty.app" ]; then
  warn "Ghostty not found. The ⌃⌥A launcher opens Claude Code in Ghostty."
  warn "Install it with:  brew install --cask ghostty   (or edit bin/claude-session for another terminal)."
fi

# 7. Install files ----------------------------------------------------------
say "Installing scripts..."
mkdir -p "$BIN" "$PLUGINS" "$HOME/.cache/claude-usage"
install -m 0755 "$REPO_DIR/bin/claude-session" "$BIN/claude-session"
install -m 0755 "$REPO_DIR/bin/claude-usage"   "$BIN/claude-usage"
install -m 0755 "$REPO_DIR/swiftbar/claude.5m.sh" "$PLUGINS/claude.5m.sh"

# 8. SwiftBar config + login item + launch ----------------------------------
say "Configuring SwiftBar..."
defaults write com.ameba.SwiftBar PluginDirectory "$PLUGINS" >/dev/null 2>&1 || true
osascript -e 'tell application "System Events" to make login item at end with properties {path:"/Applications/SwiftBar.app", hidden:false}' >/dev/null 2>&1 || true
open -a SwiftBar >/dev/null 2>&1 || true
sleep 1
open "swiftbar://refreshallplugins" >/dev/null 2>&1 || true

# 9. Optional global hotkey via skhd ----------------------------------------
if command -v skhd >/dev/null 2>&1; then
  SKHDRC="$HOME/.skhdrc"
  touch "$SKHDRC"
  if ! grep -q "claude-session" "$SKHDRC"; then
    printf '\n# claude-omarchy-mac: open/resume Claude Code (Omarchy-style)\nctrl + alt - a : ~/.local/bin/claude-session\n' >> "$SKHDRC"
    skhd --reload >/dev/null 2>&1 || true
    say "Added global shortcut  ctrl + alt - a  to ~/.skhdrc"
  else
    say "skhd shortcut already present."
  fi
else
  warn "skhd not found: the global shortcut is optional."
  warn "With skhd+yabai, bind:  ctrl + alt - a : ~/.local/bin/claude-session"
  warn "Or bind ~/.local/bin/claude-session to a hotkey in Raycast / BetterTouchTool / Karabiner."
fi

# 10. PATH note -------------------------------------------------------------
case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) warn "Add ~/.local/bin to your PATH (e.g. in ~/.zprofile)." ;;
esac

echo
say "Install complete."
echo
echo "LAST STEP (required for the usage percentages):"
echo "    claude auth login"
echo "  Complete the sign-in in the browser with your Claude Pro/Max account."
echo
echo "Then the menu bar (top-right) shows:  ✦ 6% / 24%   (session 5h / week 7d)."
echo "Shortcut:  ⌃⌥A  opens/resumes Claude Code in Ghostty."
