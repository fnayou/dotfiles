# codex

Managed Codex CLI configuration. Stows into `~/.codex/config.toml`.

This package tracks only portable, non-secret preferences: model defaults, hooks enablement, the
Catppuccin Macchiato TUI theme, colored status line output, and the built-in status line item order.

## What it deliberately excludes

Never add these to the package:

- `auth.json` — authentication tokens
- `*.sqlite`, logs, rollouts, transcripts, app-server state, caches, and model caches
- plugin checkouts or plugin runtime files
- `[projects]` trust entries from `config.toml`, because they contain machine-specific absolute paths
- local profiles that carry work-specific settings or credentials

## Status line

Codex `0.149.1` supports the built-in status line items configured here:

- model with reasoning effort
- current directory
- git branch
- pull request number
- branch changes
- context used
- five-hour limit
- weekly limit

`rtk` and caveman savings are not configured in this package. The existing Claude Code status line
shows the correct scoping model: `rtk` uses `rtk gain --project --format json`, and caveman computes
session savings from the session transcript plus a repository ledger. Codex needs a documented custom
status line command/payload before those can be added here without relying on unsupported internals.

## Setup

Back up or inspect your live config before stowing. If it contains `[projects]` entries, preserve
them locally; this package intentionally does not commit them.

```bash
# Dry run first
stow --dir=stow/common --target="$HOME" --no-folding --simulate codex
```

⚠️  MANUAL STEP — run only after approving the dry-run output

```bash
stow --dir=stow/common --target="$HOME" --no-folding codex
```

If Stow reports a conflict at `~/.codex/config.toml`, stop and merge manually. Never use
`stow --adopt`.
