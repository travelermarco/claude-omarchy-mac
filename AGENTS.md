# AGENTS.md — install guide for AI agents

You are installing **claude-omarchy-mac** on a **macOS** machine (macOS only).
Follow these steps in order. Run shell commands on the target Mac.

## 0. Safety

- **Never read, print, log, or exfiltrate the Keychain token or any credential.**
  The scripts handle the OAuth token locally; it is only ever sent to
  `api.anthropic.com`. Do not add code or commands that dump it.
- Nothing here needs `sudo`.

## 1. Preconditions (verify, don't assume)

```bash
uname                       # must print "Darwin" — else STOP, macOS only
command -v brew             # Homebrew required; if missing, ask the human to install from https://brew.sh and STOP
command -v claude           # Claude Code CLI; needed for the official %
command -v npm              # for ccusage; if missing: brew install node
ls -d /Applications/Ghostty.app 2>/dev/null   # launcher uses Ghostty; if missing: brew install --cask ghostty (optional)
```

## 2. Install

From the repository root:

```bash
./install.sh
```

This installs SwiftBar + ccusage, copies the scripts to `~/.local/bin` and
`~/.config/swiftbar/plugins`, configures and launches SwiftBar, and — if `skhd`
is present — adds the `ctrl + alt - a` shortcut.

## 3. Human step (cannot be automated)

Ask the human to run this and complete the browser sign-in with their
**Claude Pro/Max** account:

```bash
claude auth login
```

This stores the OAuth token in the Keychain, which the widget needs for the
official percentages. If a macOS Keychain prompt appears, they must choose
**Always Allow**.

## 4. Verify

```bash
claude auth status                 # expect  "loggedIn": true
~/.local/bin/claude-usage          # expect e.g.  Sessione(5h): 6%   Settimana(7d): 24%
open "swiftbar://refreshallplugins"
```

Success = the menu bar (top-right) shows `✦ 6% / 24%`.

## 5. If the shortcut is wanted but `skhd` is absent

The global `⌃⌥A` shortcut needs `skhd`. If it is not installed, either skip it
or bind `~/.local/bin/claude-session` to a hotkey in Raycast / BetterTouchTool /
Karabiner. Do not install a window manager unprompted.

## Troubleshooting

- Menu bar shows `✦ $X.XX` (a cost) instead of `%` → the OAuth token is not
  available; run `claude auth login`. The widget auto-upgrades to % once it is.
- Menu bar shows `✦ login` or `⚠` → token missing/expired; run
  `claude auth login`, then the dropdown's **Aggiorna ora**.
- Menu bar unchanged → open the SwiftBar menu → **Refresh**, or re-run
  `open "swiftbar://refreshallplugins"`.
