# Alacritty Package Setup Guide

This guide explains how to set up the managed Alacritty configuration on a new machine. It is written for a human user, not for implementation agents.

---

## 1. What this package manages

The `stow/common/alacritty/` package manages two files, stowed into `~/.config/alacritty/`:

| Repository file | Symlink created at | Purpose |
|---|---|---|
| `stow/common/alacritty/.config/alacritty/alacritty.toml` | `~/.config/alacritty/alacritty.toml` | Main configuration — window, font, keyboard bindings, shell, theme import |
| `stow/common/alacritty/.config/alacritty/catppuccin-macchiato.toml` | `~/.config/alacritty/catppuccin-macchiato.toml` | Catppuccin Macchiato color theme |

Alacritty loads `~/.config/alacritty/alacritty.toml` automatically on startup. No manual activation step is required beyond stowing the files.

---

## 2. Platform notes

This package lives under `stow/common/` and is shared across macOS and Arch. Some settings inside `alacritty.toml` are macOS-specific:

- `decorations = "Buttonless"` — hides the macOS title bar buttons. Has no effect on Linux.
- `option_as_alt = "Both"` — remaps the Option key to Alt on macOS. Has no effect on Linux.

These settings are harmless on Arch — Alacritty ignores unknown or inapplicable values gracefully.

---

## 3. Prerequisites

Install Alacritty and GNU Stow before beginning.

### macOS

⚠️  MANUAL STEP — review before running
```bash
brew install --cask alacritty
brew install stow
```

### Arch / EndeavourOS

⚠️  MANUAL STEP — review before running
```bash
sudo pacman -S alacritty stow
```

Verify Alacritty is available:

```bash
alacritty --version
```

---

## 4. Dry-run step

Always dry-run the Stow package before applying it. This shows exactly what symlinks would be created without making any changes.

```bash
stow --dir=stow/common --target="$HOME" --no-folding --simulate alacritty
```

**What to look for:** Two `LINK:` lines, one for each managed file:

```
LINK: .config/alacritty/alacritty.toml => ../../works/dotfiles/stow/common/alacritty/.config/alacritty/alacritty.toml
LINK: .config/alacritty/catppuccin-macchiato.toml => ../../works/dotfiles/stow/common/alacritty/.config/alacritty/catppuccin-macchiato.toml
```

No conflict lines. Exit code 0.

**If you see a conflict:** A real file already exists at the target path. Do NOT use `stow --adopt`. See the Troubleshooting section below.

---

## 5. Apply step (Stow)

After reviewing the dry-run output and confirming no conflicts, apply the Stow package:

⚠️  MANUAL STEP — review dry-run output before running
```bash
stow --dir=stow/common --target="$HOME" --no-folding alacritty
```

**`--no-folding` is required.** Without it, Stow may collapse `~/.config/alacritty` into a single symlink pointing at the package directory instead of creating `~/.config/alacritty` as a real directory with one symlink per file. Always stow this package with `--no-folding`.

**`stow --adopt` is forbidden.** It silently overwrites files in `$HOME` with the repository version, destroying your existing content without a backup.

---

## 6. Validation steps

After stowing, verify the installation:

```bash
# Confirm ~/.config/alacritty is a real directory, NOT a folded symlink
test ! -L "$HOME/.config/alacritty" && echo "OK: ~/.config/alacritty is a real directory"
```

```bash
# Confirm both symlinks exist
ls -la ~/.config/alacritty/
```

Expected: `alacritty.toml` and `catppuccin-macchiato.toml` shown as symlinks (`->` arrows).

```bash
# Confirm each symlink resolves into the repository
readlink ~/.config/alacritty/alacritty.toml
readlink ~/.config/alacritty/catppuccin-macchiato.toml
```

Both should resolve to paths inside your dotfiles repository.

Launch Alacritty to confirm it starts without errors and applies the theme:

```bash
alacritty &
```

---

## 7. Rollback steps

To undo the setup:

⚠️  MANUAL STEP — review before running
```bash
stow --dir=stow/common --target="$HOME" --delete alacritty
```

This removes both symlinks from `~/.config/alacritty/`. Your Alacritty installation is not affected — it will simply fall back to its built-in defaults or any remaining config you have in that directory.

---

## 8. Troubleshooting

### Stow conflict: real file exists at target

Symptom: Stow dry-run reports a conflict such as:

```
WARNING! stowing alacritty would cause conflicts:
  * cannot stow ... over existing target .config/alacritty/alacritty.toml since neither a link nor a directory and --adopt not specified
All operations aborted.
```

This happens when a real (non-symlink) file already exists at the target path — typically from a previous manual Alacritty setup.

Resolution:
1. Identify the conflicting file: `ls -la ~/.config/alacritty/`
2. Compare it with the repository version to check for differences you want to keep:
   ```bash
   diff ~/.config/alacritty/alacritty.toml stow/common/alacritty/.config/alacritty/alacritty.toml
   ```
3. If you want to keep changes from the home file, update the repository file first.
4. Move the existing file out of the way:
   ```bash
   mv ~/.config/alacritty/alacritty.toml ~/.config/alacritty/alacritty.toml.bak
   ```
5. Re-run the dry-run to confirm the conflict is gone.
6. Then run the Stow apply step.

Do NOT use `stow --adopt` — it would silently overwrite your existing file with the repository version without any backup.

### `~/.config/alacritty` became a symlink (directory folding)

Symptom: `~/.config/alacritty` is a symlink pointing at the package directory instead of a real directory. Caused by stowing without `--no-folding`.

Verify:

```bash
ls -ld ~/.config/alacritty    # a leading "l" (lrwxr-xr-x) means it is a folded symlink
```

Resolution:
1. Roll back the fold:

   ⚠️  MANUAL STEP — review before running
   ```bash
   stow --dir=stow/common --target="$HOME" --delete alacritty
   ```

2. Recreate `~/.config/alacritty` as a real directory:

   ```bash
   mkdir -p ~/.config/alacritty
   ```

3. Re-run the apply step WITH `--no-folding`:

   ⚠️  MANUAL STEP — review before running
   ```bash
   stow --dir=stow/common --target="$HOME" --no-folding alacritty
   ```

4. Confirm it is now a real directory: `test ! -L "$HOME/.config/alacritty" && echo "OK: real directory"`

### Theme not applied (color scheme looks wrong)

Symptom: Alacritty starts but shows default colors instead of Catppuccin Macchiato.

Cause: The `[general].import` in `alacritty.toml` requires both files to be present at `~/.config/alacritty/`. If only one symlink was created, the import silently fails.

Resolution:
```bash
# Confirm both symlinks exist
ls -la ~/.config/alacritty/

# Confirm the theme file resolves correctly
readlink ~/.config/alacritty/catppuccin-macchiato.toml
```

If either symlink is missing, re-run the Stow apply step.

---

## 9. Expected final file layout

After successful setup, your files should look like this:

```
~/.config/alacritty/
  alacritty.toml            ->  /path/to/dotfiles/stow/common/alacritty/.config/alacritty/alacritty.toml
  catppuccin-macchiato.toml ->  /path/to/dotfiles/stow/common/alacritty/.config/alacritty/catppuccin-macchiato.toml
```

Both entries are symlinks (`->` arrows), not real files. `~/.config/alacritty` is a real directory, not a symlink.
