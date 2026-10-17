# Codex Package Setup Guide

This guide explains how to set up the managed Codex CLI configuration on a machine. It is written for
a human user, not for implementation agents.

---

## 1. What is managed

| Repository file | Installed as | How |
|---|---|---|
| `stow/common/codex/.codex/themes/catppuccin-macchiato-blue.tmTheme` | `~/.codex/themes/catppuccin-macchiato-blue.tmTheme` | GNU Stow symlink, package `codex` |
| `stow/common/codex/.codex/config.toml` | `~/.codex/config.toml` | **Not stowed.** Propagated by `task codex:sync` (see §7) |

The config template holds portable Codex CLI preferences only: model defaults, hooks enablement,
theme name, colored status line output and item order. Stowing the config is prohibited on purpose:
Codex writes generated state (`[projects]` trust paths, `[hooks.state]` hashes,
`[tui.model_availability_nux]`, `screen_reader_detection_done`) into the live config, and a symlink
would deliver those machine-specific absolute paths into this repository.
`stow/common/codex/.stow-local-ignore` lists `config.toml`, so stowing `codex` links only the theme
and never the config, in either direction.

Codex CLI theming is syntax highlighting, not terminal ANSI colors. Alacritty and Ghostty own terminal colors;
Herdr owns its UI token mapping.

---

## 2. What stays local

Never commit or stow these from a live `~/.codex/` directory:

- `auth.json`
- `*.sqlite`
- logs, transcripts, rollouts, caches, model caches, app-server state
- plugin checkouts or plugin runtime files
- `[projects]` trust entries, `[hooks.state]` hashes, and other generated keys in the live
  `~/.codex/config.toml`
- local work profiles or credentials

`~/.codex` must remain a real directory. Use `--no-folding` so Stow creates per-file symlinks inside
that directory instead of turning the whole Codex home into a symlink.

---

## 3. Dry-run step

When Stow encodes which files are linked, `config.toml` never appears: the `.stow-local-ignore`
excludes it. Always dry-run first:

```bash
stow --dir=stow/common --target="$HOME" --no-folding --simulate codex
```

Expected: a single `LINK: .codex/themes/catppuccin-macchiato-blue.tmTheme => ...` line and no
`config.toml` link. No conflict lines. Exit code 0.

If a dry-run shows a `config.toml` link, stop — you are missing the `.stow-local-ignore` entry.

---

## 4. Apply step

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

## 5. First-time config propagation

If `~/.codex/config.toml` already exists as a real file, back it up, then apply the template:

```bash
stamp="$(date +%Y%m%d-%H%M%S)"
cp -p ~/.codex/config.toml ~/.codex/config.toml.pre-sync-"$stamp"
task codex:sync                 # DRY RUN — inspect the reported diff first
task codex:sync ARGS='--apply'  # real propagation, backup included automatically
```

`--apply` writes a timestamped backup (`~/.codex/config.toml.bak-YYYYMMDDHHMMSS`) before touching
the live file. Review the dry-run report before running it.

---

## 6. Validation

Confirm `~/.codex` is still a real directory:

```bash
test ! -L "$HOME/.codex" && echo "OK: ~/.codex is a real directory"
```

Confirm `config.toml` stays local and only the theme is stowed:

```bash
test ! -L "$HOME/.codex/config.toml" && echo "OK: config is a real local file, not a symlink"
ls -la ~/.codex/themes/catppuccin-macchiato-blue.tmTheme
```

The `ls` should show a `->` arrow into this repository.

Check the sync status:

```bash
task codex:inspect
```

The verdict should end with `STATUS: SYNCED`. `ko` rows mean a repo-owned key in the live config
differs from the template; fix by editing the repository template and re-running
`task codex:sync ARGS='--apply'`. Live-only keys are preserved and never merged back.

Ask Codex to validate the config:

```bash
codex doctor --json
```

The overall doctor result may fail for unrelated auth, network, or local-state reasons. For this
package, check that `config.load` is `ok` and `config.toml parse` is `ok`.

### Generated state stays local

Codex adds `[projects]` trust entries, `[hooks.state]` hashes, and onboarding flags while you use
it. Because the live config is a real local file, those writes never touch the repository, and the
sync script preserves them: it only rewrites repo-owned keys, and it counts live-only keys without
listing or deleting them. No manual `git diff` cleanup is needed anymore.

---

## 7. Day-to-day sync

After changing the template, run:

```bash
task codex:inspect                     # see which keys changed
task codex:sync                        # DRY RUN by default — show the diff, write nothing
task codex:sync ARGS='--apply'         # propagate: backup, then write repo-owned keys
```

Sync is one-directional, repository -> live config. The repository template wins for keys it owns;
live-only generated state is preserved in place and never copied back or deleted.

---

## 8. Rollback

⚠️  MANUAL STEP — review before running

```bash
stow --dir=stow/common --target="$HOME" --no-folding --delete codex
```

This removes the theme symlink only; the local `~/.codex/config.toml` is untouched by Stow. Then
restore the live config from the newest sync backup if needed:

    cp ~/.codex/config.toml.bak-YYYYMMDDHHMMSS ~/.codex/config.toml

Keep auth, transcripts, caches, and runtime state untouched.
