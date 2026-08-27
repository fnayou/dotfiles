# codex

Managed Codex CLI configuration. Stows into `~/.codex/config.toml` and `~/.codex/themes/`.

This package tracks only portable, non-secret preferences: model defaults, hooks enablement, the
Catppuccin Macchiato blue Codex CLI syntax theme, colored status line output, and the built-in
status line item order.

## What it deliberately excludes

Never add these to the package:

- `auth.json` — authentication tokens
- `*.sqlite`, logs, rollouts, transcripts, app-server state, caches, and model caches
- plugin checkouts or plugin runtime files
- `[projects]` trust entries from `config.toml`, because they contain machine-specific absolute paths
- local profiles that carry work-specific settings or credentials

## Theme

Codex CLI theming is syntax-highlighting theming, not a terminal ANSI palette. Official OpenAI Docs
define `tui.theme` as a syntax-highlighting theme override, and the CLI looks up either a bundled
theme name or a custom TextMate `.tmTheme` file from `$CODEX_HOME/themes/`.

This package uses a repo-owned custom theme:

| File | Stowed to | Purpose |
|---|---|---|
| `.codex/themes/catppuccin-macchiato-blue.tmTheme` | `~/.codex/themes/catppuccin-macchiato-blue.tmTheme` | Codex CLI syntax theme derived from the vendored Catppuccin Macchiato TextMate theme |

The theme name in `config.toml` is therefore:

```toml
[tui]
theme = "catppuccin-macchiato-blue"
```

This makes the syntax palette repo-owned instead of relying on the bundled Codex
`catppuccin-macchiato` approximation. Alacritty still owns terminal ANSI colors; Herdr owns its UI
token mapping.

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

See [Codex Package Setup Guide](../../../docs/guides/codex-setup.md) for the full backup,
dry-run, install, validation, and rollback workflow.

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

After stowing, Codex may write local `[projects]` trust entries when a directory is trusted or when
the CLI repairs its configuration. Because `~/.codex/config.toml` is a per-file symlink, those
writes land in this repository. Keep the entries local and remove them from the repository file
before committing; inspect `git diff -- stow/common/codex/.codex/config.toml` after trust changes.
