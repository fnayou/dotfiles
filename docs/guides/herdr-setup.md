# Herdr Package Setup Guide

This guide explains how to set up the managed Herdr configuration on a new machine. It is written for a human user, not for implementation agents.

---

## 1. What this package manages

The `stow/common/herdr/` package manages one file, stowed into `~/.config/herdr/`:

| Repository file | Symlink created at | Purpose |
|---|---|---|
| `stow/common/herdr/.config/herdr/config.toml` | `~/.config/herdr/config.toml` | Main Herdr configuration — theme, terminal, UI, toast |

Herdr loads `~/.config/herdr/config.toml` automatically on startup. No manual activation step is required beyond stowing the file.

**Important:** Herdr stores other files under `~/.config/herdr/` (session state, workspace data, etc.) that are not managed by this repository. Only `config.toml` is managed. Do not remove the entire `~/.config/herdr/` directory — only the single file.

---

## 2. Configuration summary

| Setting | Value | Notes |
|---|---|---|
| `theme.name` | `tokyo-night` | Base theme; custom palette overrides apply on top |
| `theme.custom` | Catppuccin Macchiato palette | panel_bg, accent, green, red, yellow |
| `terminal.default_shell` | `zsh` | Consistent with shell setup on both platforms |
| `terminal.new_cwd` | `follow` | New panes inherit the active pane's working directory |
| `ui.show_agent_labels_on_pane_borders` | `true` | Labels visible on pane borders |
| `ui.sidebar.initial_split_width` | `25` | 25% initial sidebar width |
| `ui.toast.delivery` | `herdr` | Toast notifications shown inside Herdr UI |
| `ui.toast.herdr.position` | `bottom-right` | Toast position within the Herdr UI |
| `ui.sound.enabled` | `true` | Sound notifications enabled |
| `update.channel` | `stable` | Herdr update channel |

---

## 3. Platform notes

This package lives under `stow/common/` and is shared across macOS and Arch. All settings are cross-platform. Herdr is available via Homebrew on both platforms.

---

## 4. Prerequisites

Install Herdr and GNU Stow before beginning.

### macOS

⚠️  MANUAL STEP — review before running
```bash
brew install herdr
brew install stow
```

### Arch / EndeavourOS

⚠️  MANUAL STEP — review before running
```bash
brew install herdr
```

Stow is installed via pacman if not already present:

⚠️  MANUAL STEP — review before running
```bash
sudo pacman -S stow
```

Verify Herdr is available:

```bash
herdr --version
```

---

## 5. Conflict resolution (existing `config.toml`)

If Herdr has been used before, `~/.config/herdr/config.toml` already exists as a real file. Stow will refuse to create the symlink over it.

**Do not remove the entire `~/.config/herdr/` directory** — Herdr stores session state, workspace data, and other files there that are not managed by this repository.

Back up and remove only `config.toml`:

```bash
# Check what exists
ls -la ~/.config/herdr/config.toml

# Back up
cp ~/.config/herdr/config.toml ~/.config/herdr/config.toml.bak

# Remove only the single file
rm ~/.config/herdr/config.toml
```

All other files in `~/.config/herdr/` are untouched.

---

## 6. Dry-run step

Always dry-run the Stow package before applying it. This shows exactly what symlinks would be created without making any changes.

```bash
stow --dir=stow/common --target="$HOME" --no-folding --simulate herdr
```

**What to look for:** One `LINK:` line for `config.toml`:

```
LINK: .config/herdr/config.toml => ../../works/dotfiles/stow/common/herdr/.config/herdr/config.toml
```

No conflict lines. Exit code 0.

**If you see a conflict:** A real file already exists at the target path. See section 5 above — back up and remove only `config.toml`, then re-run the dry-run.

---

## 7. Apply step (Stow)

After reviewing the dry-run output and confirming no conflicts, apply the Stow package:

⚠️  MANUAL STEP — review dry-run output before running
```bash
stow --dir=stow/common --target="$HOME" --no-folding herdr
```

**`--no-folding` is required.** Without it, Stow may collapse `~/.config/herdr` into a single symlink pointing at the package directory instead of creating a per-file symlink inside the existing real directory.

**`stow --adopt` is forbidden.** It silently overwrites files in `$HOME` with the repository version, destroying your existing content without a backup.

---

## 8. Validation steps

After stowing, verify the installation:

```bash
# Confirm ~/.config/herdr is a real directory, NOT a folded symlink
test ! -L "$HOME/.config/herdr" && echo "OK: ~/.config/herdr is a real directory"
```

```bash
# Confirm the symlink exists
ls -la ~/.config/herdr/config.toml
```

Expected: `config.toml` shown as a symlink (`->` arrow).

```bash
# Confirm the symlink resolves into the repository
readlink ~/.config/herdr/config.toml
```

Should resolve to a path inside your dotfiles repository.

Launch Herdr to confirm the configuration loads correctly:

```bash
herdr
```

Confirm visually:
- Catppuccin Macchiato colors (dark blue base `#24273a`)
- Agent labels visible on pane borders
- Sidebar width approximately 25%
- New panes inherit the working directory of the active pane
- Toast notifications appear inside the Herdr UI (bottom-right), not as macOS/system alerts

---

## 9. Rollback steps

To undo the setup:

⚠️  MANUAL STEP — review before running
```bash
stow --dir=stow/common --target="$HOME" --delete herdr
```

This removes the `config.toml` symlink. All other files in `~/.config/herdr/` are untouched. To restore the original:

```bash
cp ~/.config/herdr/config.toml.bak ~/.config/herdr/config.toml
```

---

## 10. Troubleshooting

### Stow conflict: real file exists at target

Symptom: Stow dry-run reports a conflict such as:

```
WARNING! stowing herdr would cause conflicts:
  * cannot stow ... over existing target .config/herdr/config.toml since neither a link nor a directory and --adopt not specified
All operations aborted.
```

Resolution: Follow section 5 — back up and remove only `config.toml`, then re-run.

### `~/.config/herdr` became a symlink (directory folding)

Symptom: `~/.config/herdr` is a symlink pointing at the package directory instead of a real directory. Caused by stowing without `--no-folding`.

Verify:

```bash
ls -ld ~/.config/herdr    # a leading "l" (lrwxr-xr-x) means it is a folded symlink
```

Resolution:
1. Roll back the fold:

   ⚠️  MANUAL STEP — review before running
   ```bash
   stow --dir=stow/common --target="$HOME" --delete herdr
   ```

2. Recreate `~/.config/herdr` as a real directory:

   ```bash
   mkdir -p ~/.config/herdr
   ```

3. Re-run the apply step WITH `--no-folding`:

   ⚠️  MANUAL STEP — review before running
   ```bash
   stow --dir=stow/common --target="$HOME" --no-folding herdr
   ```

4. Confirm it is now a real directory: `test ! -L "$HOME/.config/herdr" && echo "OK: real directory"`

---

## 11. Expected final file layout

After successful setup, your files should look like this:

```
~/.config/herdr/
  config.toml    ->  /path/to/dotfiles/stow/common/herdr/.config/herdr/config.toml
  <other files>      (Herdr-managed session state — not symlinks, not in this repo)
```

`config.toml` is a symlink (`->` arrow). `~/.config/herdr` is a real directory, not a symlink. All other files in the directory are untouched by Stow.
