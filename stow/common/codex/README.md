# codex

Codex CLI configuration template. **This package is never stowed.** Codex writes generated state
into `~/.codex/config.toml` (project trust paths, onboarding flags, hook hashes), so a Stow symlink
would land those machine-specific writes in this repository. Instead, the template stays at
`stow/common/codex/.codex/config.toml` and is propagated to the live config with
`scripts/codex-sync.sh` (Taskfile: `task codex:inspect`, `task codex:sync`).

`.stow-local-ignore` lists `config.toml`, so Stow refuses to link it in either direction. The
theme file stays in this package and is the only part stowed.

## What it contains

`.codex/config.toml` tracks only portable, non-secret preferences:

- model defaults and reasoning effort
- hooks enablement
- the Catppuccin Macchiato blue theme name
- colored built-in status line output and item order

## What it deliberately excludes

Never add these to the template:

- `auth.json` — authentication tokens
- `*.sqlite`, logs, rollouts, transcripts, app-server state, caches, and model caches
- plugin checkouts or plugin runtime files
- `[projects]` trust entries — machine-specific absolute paths; they belong in the live config only
- `[hooks.state]` hashes, `[tui.model_availability_nux]`, and `screen_reader_detection_done` —
  generated state that the sync script preserves in the live config
- local profiles that carry work-specific settings or credentials

## Sync workflow

```bash
task codex:inspect                  # read-only status report; verdict SYNCED or NOT SYNCED
task codex:sync                     # DRY RUN — reports the diff, writes nothing
task codex:sync ARGS='--apply'      # real propagation, with a timestamped backup first
```

The sync is one-directional (repository -> live config):

- repo-owned keys whose live value differs are rewritten to the template value (repository wins)
- live-only keys (trust paths, hook hashes, onboarding state) are preserved, never listed, never
  copied back, never deleted
- before writing, the script backs up the live config to `~/.codex/config.toml.bak-YYYYMMDDHHMMSS`

`.stow-local-ignore` lists `config.toml`, so the template can never be stowed accidentally.

## Theme

Codex CLI theming is syntax-highlighting theming, not a terminal ANSI palette. The CLI resolves the
`tui.theme` name against a bundled theme or a custom TextMate `.tmTheme` file under
`$CODEX_HOME/themes/`.

The theme file lives in this package under `.codex/themes/` and is the only part of the Codex
config that is stowed. The template selects it by name:

```toml
[tui]
theme = "catppuccin-macchiato-blue"
```

This makes the syntax palette repo-owned instead of relying on the bundled Codex
`catppuccin-macchiato` approximation. Alacritty and Ghostty still own terminal ANSI colors; Herdr owns its UI
token mapping.

## Status line

The template configures the built-in status line items:

- model with reasoning effort
- current directory
- git branch
- pull request number
- branch changes
- context used
- five-hour limit
- weekly limit

`rtk` and caveman savings are not configured here. Codex still lacks a documented external custom
status line interface, so no custom payload can be rendered without unsupported internals. The
Claude Code status line (stow/common/claude) shows real session output tokens instead of estimates —
that is the reference model.

## Setup

Full workflow in [Codex Package Setup Guide](../../../docs/guides/codex-setup.md).

Stow the package (`--no-folding` keeps `~/.codex` a real directory). Stow links the theme only —
the `.stow-local-ignore` entry keeps `config.toml` out of `$HOME`:

```bash
# Dry run first
stow --dir=stow/common --target="$HOME" --no-folding --simulate codex
```

⚠️  MANUAL STEP — run only after approving the dry-run output

```bash
stow --dir=stow/common --target="$HOME" --no-folding codex
```

Then propagate the template with the sync tasks above. `task codex:inspect` reports `SYNCED` when
the live config matches the template.