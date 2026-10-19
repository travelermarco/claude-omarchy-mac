# claude-omarchy-mac

**Omarchy-style Claude Code integration for macOS.** A global keyboard shortcut
that opens/resumes Claude Code, plus a menu-bar widget that shows your
**official Claude usage percentages** (5-hour session + weekly) — the same data
as Claude's *Usage* panel. Inspired by [Omarchy](https://omarchy.org)'s AI agent
panel.

> 🖥️ **macOS only.**

```
Menu bar (top-right):   ✦ 6% / 24%        ← session (5h) / week (7d)
Global shortcut:        ⌃⌥A               ← open / resume Claude Code
```

## What you get

- **Global shortcut `⌃⌥A`** (ctrl + alt + A) → opens **Ghostty** and resumes your
  last Claude Code session (`claude --continue`, falling back to a fresh one).
- **Menu-bar widget `✦ 6% / 24%`** → official **session (5h)** and **weekly (7d)**
  usage %, with a dropdown showing reset countdowns, per-model limits (e.g.
  Fable), the 5-hour cost/tokens (via ccusage), and quick actions (open/resume
  Claude Code, open Claude.app, refresh).
- **Automatic OAuth token refresh**, so the widget keeps working without
  re-login.

## How it works

- The widget reads the **official usage endpoint**
  `GET https://api.anthropic.com/api/oauth/usage` — the same data behind Claude's
  *Usage* panel — authenticated with your Claude Code OAuth token from the macOS
  Keychain (`Claude Code-credentials`).
- When the token is near expiry it is refreshed via the OAuth token endpoint and
  written back to the Keychain (so Claude Code keeps working too).
- If no OAuth token is available, it **falls back to [ccusage](https://github.com/ryoppippi/ccusage)**
  (local logs) and shows cost/tokens instead of percentages.
- **No secrets live in this repo.** The token stays in your Keychain and is only
  ever sent to `api.anthropic.com`.

## Requirements

| Requirement | Notes |
|---|---|
| macOS (Apple Silicon or Intel) | required |
| [Homebrew](https://brew.sh) | required |
| [Claude Code CLI](https://docs.claude.com/en/docs/claude-code) + a **Claude Pro/Max** subscription | required for the official % |
| Node.js + npm | for `ccusage` — `brew install node` |
| [Ghostty](https://ghostty.org) | used by the `⌃⌥A` launcher — `brew install --cask ghostty` |
| [SwiftBar](https://swiftbar.app) | installed automatically by `install.sh` |
| `skhd` (optional) | for the global shortcut; otherwise bind the launcher in Raycast / BetterTouchTool / Karabiner |

## Install

```bash
git clone https://github.com/travelermarco/claude-omarchy-mac.git
cd claude-omarchy-mac
./install.sh
```

Then sign the CLI in so the percentages can be read:

```bash
claude auth login
```

Complete the browser sign-in with your Claude Pro/Max account. Within a minute
the menu bar shows `✦ 6% / 24%`. If macOS shows a Keychain prompt the first time
the widget reads the token, choose **Always Allow**.

## For an AI agent

If you are an AI coding agent with shell access **on the target Mac**, read
[AGENTS.md](AGENTS.md) — it has the exact, ordered steps. In short: run
`./install.sh`, ask the human to run `claude auth login` (interactive), then
verify with `~/.local/bin/claude-usage`.

## Customize

- **Change the shortcut** → edit the `ctrl + alt - a` line in `~/.skhdrc`, then `skhd --reload`.
- **Resume from a specific folder** → set `CLAUDE_DIR` at the top of `~/.local/bin/claude-session`.
- **Refresh interval** → the `5m` in the plugin filename `claude.5m.sh` (e.g. rename to `claude.2m.sh`).
- **Color thresholds / optional budget %** → top of `~/.config/swiftbar/plugins/claude.5m.sh`.

## Uninstall

```bash
./uninstall.sh
```

## Credits

- Official usage endpoint & token-refresh approach inspired by [claudebar](https://github.com/mryll/claudebar).
- Local usage/cost via [ccusage](https://github.com/ryoppippi/ccusage).
- Menu bar via [SwiftBar](https://swiftbar.app). Concept inspired by [Omarchy](https://omarchy.org).

## License

[MIT](LICENSE)
