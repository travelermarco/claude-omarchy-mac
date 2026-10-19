#!/usr/bin/env bash
#
# claude-omarchy-mac — uninstaller
#
set -uo pipefail

echo "Removing claude-omarchy-mac files..."
rm -f "$HOME/.local/bin/claude-session"
rm -f "$HOME/.local/bin/claude-usage"
rm -f "$HOME/.config/swiftbar/plugins/claude.5m.sh"
rm -rf "$HOME/.cache/claude-usage"

# Remove the skhd shortcut lines we added (keeps the rest of ~/.skhdrc intact).
if [ -f "$HOME/.skhdrc" ]; then
  sed -i '' '/claude-omarchy-mac: open\/resume Claude Code/d' "$HOME/.skhdrc" 2>/dev/null || true
  sed -i '' '\|ctrl + alt - a : ~/.local/bin/claude-session|d' "$HOME/.skhdrc" 2>/dev/null || true
  command -v skhd >/dev/null 2>&1 && skhd --reload >/dev/null 2>&1 || true
fi

echo "Done."
echo
echo "Left installed (remove manually if you want):"
echo "    brew uninstall --cask swiftbar"
echo "    npm uninstall -g ccusage"
echo "The Claude CLI login was left intact. To sign the CLI out:  claude auth logout"
