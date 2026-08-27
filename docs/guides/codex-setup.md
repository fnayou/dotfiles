# Codex Package Setup Guide

This guide explains how to set up the managed Codex CLI configuration on a machine. It is written for
a human user, not for implementation agents.

---

## 1. What this package manages

The `stow/common/codex/` package manages portable Codex CLI preferences and one custom syntax theme:

| Repository file | Symlink created at | Purpose |
|---|---|---|
| `stow/common/codex/.codex/config.toml` | `~/.codex/config.toml` | Portable Codex CLI config: model defaults, hooks flag, status line, theme name |
| `stow/common/codex/.codex/themes/catppuccin-macchiato-blue.tmTheme` | `~/.codex/themes/catppuccin-macchiato-blue.tmTheme` | Repo-owned Catppuccin Macchiato blue TextMate syntax theme |

Codex reads `~/.codex/config.toml` on startup. The theme file is selected by:

```toml
[tui]
theme = "catppuccin-macchiato-blue"
```

Codex CLI theming is syntax highlighting, not terminal ANSI colors. Alacritty owns terminal colors;
Herdr owns its UI token mapping.

---

## 2. What stays local

Never commit or stow these from a live `~/.codex/` directory:

- `auth.json`
- `*.sqlite`
- logs, transcripts, rollouts, caches, model caches, app-server state
- plugin checkouts or plugin runtime files
- `[projects]` trust entries from a live `config.toml`
- local work profiles or credentials

`~/.codex` must remain a real directory. Use `--no-folding` so Stow creates per-file symlinks inside
that directory instead of turning the whole Codex home into a symlink.

---

## 3. Conflict resolution for existing `config.toml`

If `~/.codex/config.toml` already exists as a real file, Stow will refuse to replace it. Back it up
before stowing.

```bash
stamp="$(date +%Y%m%d-%H%M%S)"
cp -p ~/.codex/config.toml ~/.codex/config.toml.backup-"$stamp"
mv ~/.codex/config.toml ~/.codex/config.toml.pre-stow-"$stamp"
```

Review the backup and the managed config before applying Stow. If the live file had `[projects]`
entries, keep them local; do not commit them to the repository.

---

## 4. Dry-run step

Always dry-run first:

```bash
stow --dir=stow/common --target="$HOME" --no-folding --simulate --verbose codex
```

Expected output includes links for:

```text
LINK: .codex/config.toml => ...
LINK: .codex/themes/catppuccin-macchiato-blue.tmTheme => ...
```

No conflict lines. Exit code 0.

---

## 5. Apply step

⚠️  MANUAL STEP — review dry-run output before running

```bash
stow --dir=stow/common --target="$HOME" --no-folding codex
```

Use `--restow` instead when the package is already stowed and new files were added:

```bash
stow --dir=stow/common --target="$HOME" --no-folding --restow codex
```

Never use `stow --adopt`.

---

## 6. Validation

Confirm `~/.codex` is still a real directory:

```bash
test ! -L "$HOME/.codex" && echo "OK: ~/.codex is a real directory"
```

Confirm the managed symlinks:

```bash
ls -la ~/.codex/config.toml
ls -la ~/.codex/themes/catppuccin-macchiato-blue.tmTheme
```

Both should show `->` arrows into this repository.

Ask Codex to validate the config:

```bash
codex doctor --json
```

The overall doctor result may fail for unrelated auth, network, or local-state reasons. For this
package, check that `config.load` is `ok` and `config.toml parse` is `ok`.

### Check for local trust-entry drift

Codex may add `[projects]` trust entries after a project trust prompt or a configuration repair.
Since the managed config is a per-file symlink, those entries are written into the repository.
They contain machine-specific absolute paths and must remain local.

From the repository root, inspect the managed file after using Codex:

```bash
git diff -- stow/common/codex/.codex/config.toml
```

If `[projects]` entries appear, preserve any needed local trust state in the pre-stow backup or
another local configuration mechanism, then remove those entries from the repository file before
committing. Never commit absolute project paths.

---

## 7. Rollback

⚠️  MANUAL STEP — review before running

```bash
stow --dir=stow/common --target="$HOME" --no-folding --delete codex
```

Then restore the pre-stow config if needed:

```bash
cp ~/.codex/config.toml.backup-YYYYMMDD-HHMMSS ~/.codex/config.toml
```

Keep auth, transcripts, caches, and runtime state untouched.
