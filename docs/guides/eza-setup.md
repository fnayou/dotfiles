# eza Package Setup Guide

This guide explains how to set up the managed [eza](https://github.com/eza-community/eza) theme on a new machine. It is written for a human user, not for implementation agents.

---

## 1. What this package manages

The `stow/common/eza/` package manages one file, stowed into `~/.config/eza/`:

| Repository file | Symlink created at | Purpose |
|---|---|---|
| `stow/common/eza/.config/eza/theme.yml` | `~/.config/eza/theme.yml` | Catppuccin Macchiato (Blue) color theme |

eza reads `~/.config/eza/theme.yml` automatically. Unlike bat, there is **no cache-build
step** — the theme applies as soon as the file is stowed.

eza CLI flags and aliases (`ls`, `ll`, `la`, `lt`) are managed by the zsh package, not here.

---

## 2. Platform notes

This package lives under `stow/common/` and is shared across macOS and Arch. eza, its config
path (`~/.config/eza/` via XDG), and the theme format are identical on both platforms.

---

## 3. Prerequisites

Install eza and GNU Stow before beginning.

### macOS

⚠️  MANUAL STEP — review before running
```bash
brew install eza stow
```

### Arch / EndeavourOS

⚠️  MANUAL STEP — review before running
```bash
sudo pacman -S eza stow
```

Verify eza is available:

```bash
eza --version
```

---

## 4. Dry-run step

Always dry-run the Stow package before applying it. This shows exactly what symlinks would be
created without making any changes.

```bash
stow --dir=stow/common --target="$HOME" --no-folding --simulate eza
```

**What to look for:** One `LINK:` line:

```
LINK: .config/eza/theme.yml => ../../works/dotfiles/stow/common/eza/.config/eza/theme.yml
```

No conflict lines. Exit code 0.

**If you see a conflict:** A real file already exists at the target path. Do NOT use
`stow --adopt`. See the Troubleshooting section below.

---

## 5. Apply step (Stow)

After reviewing the dry-run output and confirming no conflicts, apply the Stow package:

⚠️  MANUAL STEP — review dry-run output before running
```bash
stow --dir=stow/common --target="$HOME" --no-folding eza
```

**`--no-folding` is required.** Without it, Stow may collapse `~/.config/eza` into a single
symlink pointing at the package directory instead of creating `~/.config/eza` as a real
directory with the `theme.yml` symlink inside it. Always stow this package with `--no-folding`.

**`stow --adopt` is forbidden.** It silently overwrites files in `$HOME` with the repository
version, destroying your existing content without a backup.

There is no further activation step — eza picks up `theme.yml` on its next run.

---

## 6. Validation steps

After stowing, verify the installation:

```bash
# Confirm ~/.config/eza is a real directory, NOT a folded symlink
test ! -L "$HOME/.config/eza" && echo "OK: ~/.config/eza is a real directory"
```

```bash
# Confirm the symlink exists and resolves into the repository
ls -la ~/.config/eza/
readlink ~/.config/eza/theme.yml
```

`theme.yml` should be shown as a symlink (`->` arrow) resolving into your dotfiles repository.

Render a directory listing to confirm the colors apply:

```bash
eza -la --git
```

---

## 7. Rollback steps

To undo the setup:

⚠️  MANUAL STEP — review before running
```bash
stow --dir=stow/common --target="$HOME" --delete eza
```

This removes the symlink from `~/.config/eza/`. Your eza installation is not affected — it
falls back to its built-in default colors.

---

## 8. Troubleshooting

### Stow conflict: real file exists at target

Symptom: Stow dry-run reports a conflict such as:

```
WARNING! stowing eza would cause conflicts:
  * cannot stow ... over existing target .config/eza/theme.yml since neither a link nor a directory and --adopt not specified
All operations aborted.
```

This happens when a real (non-symlink) file already exists at the target path — typically from
a previous manual eza setup.

Resolution:
1. Identify the conflicting file: `ls -la ~/.config/eza/`
2. Compare it with the repository version:
   ```bash
   diff ~/.config/eza/theme.yml stow/common/eza/.config/eza/theme.yml
   ```
3. If you want to keep changes from the home file, update the repository file first.
4. Move the existing file out of the way:
   ```bash
   mv ~/.config/eza/theme.yml ~/.config/eza/theme.yml.bak
   ```
5. Re-run the dry-run to confirm the conflict is gone.
6. Then run the Stow apply step.

Do NOT use `stow --adopt` — it would silently overwrite your existing file with the repository
version without any backup.

### `~/.config/eza` became a symlink (directory folding)

Symptom: `~/.config/eza` is a symlink pointing at the package directory instead of a real
directory. Caused by stowing without `--no-folding`.

Verify:

```bash
ls -ld ~/.config/eza    # a leading "l" (lrwxr-xr-x) means it is a folded symlink
```

Resolution:
1. Roll back the fold:

   ⚠️  MANUAL STEP — review before running
   ```bash
   stow --dir=stow/common --target="$HOME" --delete eza
   ```

2. Recreate `~/.config/eza` as a real directory:

   ```bash
   mkdir -p ~/.config/eza
   ```

3. Re-run the apply step WITH `--no-folding`:

   ⚠️  MANUAL STEP — review before running
   ```bash
   stow --dir=stow/common --target="$HOME" --no-folding eza
   ```

4. Confirm it is now a real directory: `test ! -L "$HOME/.config/eza" && echo "OK: real directory"`

### Theme not applied (colors look default)

Symptom: eza shows default colors instead of Catppuccin Macchiato.

Most likely cause: `EZA_CONFIG_DIR` is set to a directory other than `~/.config/eza`, so eza
reads `theme.yml` from there instead.

Resolution:
```bash
# Check whether the override is set
echo "$EZA_CONFIG_DIR"
```

If it is set and non-empty, eza reads `theme.yml` from that directory, not `~/.config/eza`.
Either unset it, point it at `~/.config/eza`, or place the theme where it points.

Also confirm the symlink resolves:

```bash
readlink ~/.config/eza/theme.yml
```

Note: eza does not use a compiled theme cache, so there is no cache to rebuild (this differs
from bat).

---

## 9. Expected final file layout

After successful setup, your files should look like this:

```
~/.config/eza/
  theme.yml  ->  /path/to/dotfiles/stow/common/eza/.config/eza/theme.yml
```

`theme.yml` is a symlink (`->` arrow), not a real file. `~/.config/eza` is a real directory,
not a symlink.
