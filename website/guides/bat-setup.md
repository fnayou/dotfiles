# bat Package Setup Guide

This guide explains how to set up the managed [bat](https://github.com/sharkdp/bat) configuration on a new machine. It is written for a human user, not for implementation agents.

---

## 1. What this package manages

The `stow/common/bat/` package manages two files, stowed into `~/.config/bat/`:

| Repository file | Symlink created at | Purpose |
|---|---|---|
| `stow/common/bat/.config/bat/config` | `~/.config/bat/config` | Main configuration — style, wrap, italics, paging, active theme |
| `stow/common/bat/.config/bat/themes/Catppuccin Macchiato.tmTheme` | `~/.config/bat/themes/Catppuccin Macchiato.tmTheme` | Catppuccin Macchiato theme |

bat reads `~/.config/bat/config` automatically. Unlike Alacritty, the theme is **not** active just by stowing — bat loads themes from a compiled cache, so you must run `bat cache --build` once after stowing (see section 6).

---

## 2. Platform notes

This package lives under `stow/common/` and is shared across macOS and Arch. The config uses only portable bat options, so no platform-specific handling is needed. `--italic-text="always"` depends on terminal/font support rather than the OS.

---

## 3. Prerequisites

Install bat and GNU Stow before beginning.

### macOS

⚠️  MANUAL STEP — review before running
```bash
brew install bat stow
```

### Arch / EndeavourOS

⚠️  MANUAL STEP — review before running
```bash
sudo pacman -S bat stow
```

Verify bat is available and check its config dir resolves to `~/.config/bat`:

```bash
bat --version
bat --config-dir
```

---

## 4. Dry-run step

Always dry-run the Stow package before applying it. This shows exactly what symlinks would be created without making any changes.

```bash
stow --dir=stow/common --target="$HOME" --no-folding --simulate bat
```

**What to look for:** Two `LINK:` lines, one for each managed file:

```
LINK: .config/bat/config => ../../works/dotfiles/stow/common/bat/.config/bat/config
LINK: .config/bat/themes/Catppuccin Macchiato.tmTheme => ../../works/dotfiles/stow/common/bat/.config/bat/themes/Catppuccin Macchiato.tmTheme
```

No conflict lines. Exit code 0.

**If you see a conflict:** A real file already exists at the target path. Do NOT use `stow --adopt`. See the Troubleshooting section below.

---

## 5. Apply step (Stow)

After reviewing the dry-run output and confirming no conflicts, apply the Stow package:

⚠️  MANUAL STEP — review dry-run output before running
```bash
stow --dir=stow/common --target="$HOME" --no-folding bat
```

**`--no-folding` is required.** Without it, Stow may collapse `~/.config/bat` into a single symlink pointing at the package directory instead of creating `~/.config/bat` (and `~/.config/bat/themes`) as real directories with one symlink per file. Always stow this package with `--no-folding`.

**`stow --adopt` is forbidden.** It silently overwrites files in `$HOME` with the repository version, destroying your existing content without a backup.

---

## 6. Activate the theme (build the cache)

bat does not read `.tmTheme` files directly — it reads a compiled cache. After stowing, build the cache once so the Catppuccin Macchiato theme becomes available:

```bash
bat cache --build
```

Then confirm the theme is registered:

```bash
bat --list-themes | grep "Catppuccin Macchiato"
```

You only need to repeat `bat cache --build` if you add or change theme files later.

---

## 7. Validation steps

After stowing and building the cache, verify the installation:

```bash
# Confirm ~/.config/bat is a real directory, NOT a folded symlink
test ! -L "$HOME/.config/bat" && echo "OK: ~/.config/bat is a real directory"
```

```bash
# Confirm both symlinks exist
ls -la ~/.config/bat/ ~/.config/bat/themes/
```

Expected: `config` and `Catppuccin Macchiato.tmTheme` shown as symlinks (`->` arrows).

```bash
# Confirm each symlink resolves into the repository
readlink ~/.config/bat/config
readlink "$HOME/.config/bat/themes/Catppuccin Macchiato.tmTheme"
```

Both should resolve to paths inside your dotfiles repository.

Render a file to confirm the theme applies with colors:

```bash
bat README.md
```

---

## 8. Rollback steps

To undo the setup:

⚠️  MANUAL STEP — review before running
```bash
stow --dir=stow/common --target="$HOME" --delete bat
```

This removes both symlinks from `~/.config/bat/`. Your bat installation is not affected — it falls back to its built-in defaults. The compiled cache can be cleared with `bat cache --clear` if you want a clean slate.

---

## 9. Troubleshooting

### Stow conflict: real file exists at target

Symptom: Stow dry-run reports a conflict such as:

```
WARNING! stowing bat would cause conflicts:
  * cannot stow ... over existing target .config/bat/config since neither a link nor a directory and --adopt not specified
All operations aborted.
```

This happens when a real (non-symlink) file already exists at the target path — typically from a previous manual bat setup.

Resolution:
1. Identify the conflicting file: `ls -la ~/.config/bat/`
2. Compare it with the repository version to check for differences you want to keep:
   ```bash
   diff ~/.config/bat/config stow/common/bat/.config/bat/config
   ```
3. If you want to keep changes from the home file, update the repository file first.
4. Move the existing file out of the way:
   ```bash
   mv ~/.config/bat/config ~/.config/bat/config.bak
   ```
5. Re-run the dry-run to confirm the conflict is gone.
6. Then run the Stow apply step.

Do NOT use `stow --adopt` — it would silently overwrite your existing file with the repository version without any backup.

### `~/.config/bat` became a symlink (directory folding)

Symptom: `~/.config/bat` is a symlink pointing at the package directory instead of a real directory. Caused by stowing without `--no-folding`.

Verify:

```bash
ls -ld ~/.config/bat    # a leading "l" (lrwxr-xr-x) means it is a folded symlink
```

Resolution:
1. Roll back the fold:

   ⚠️  MANUAL STEP — review before running
   ```bash
   stow --dir=stow/common --target="$HOME" --delete bat
   ```

2. Recreate `~/.config/bat` as a real directory:

   ```bash
   mkdir -p ~/.config/bat/themes
   ```

3. Re-run the apply step WITH `--no-folding`:

   ⚠️  MANUAL STEP — review before running
   ```bash
   stow --dir=stow/common --target="$HOME" --no-folding bat
   ```

4. Confirm it is now a real directory: `test ! -L "$HOME/.config/bat" && echo "OK: real directory"`

### Theme not applied (colors look wrong or error about unknown theme)

Symptom: bat shows default colors, or errors that the theme `Catppuccin Macchiato` is unknown.

Cause: The cache was not built after stowing the theme file.

Resolution:
```bash
# Rebuild the theme cache
bat cache --build

# Confirm the theme is now registered
bat --list-themes | grep "Catppuccin Macchiato"
```

If the theme still does not appear, confirm the theme symlink resolves correctly:

```bash
readlink "$HOME/.config/bat/themes/Catppuccin Macchiato.tmTheme"
```

---

## 10. Expected final file layout

After successful setup, your files should look like this:

```
~/.config/bat/
  config                            ->  /path/to/dotfiles/stow/common/bat/.config/bat/config
  themes/
    Catppuccin Macchiato.tmTheme    ->  /path/to/dotfiles/stow/common/bat/.config/bat/themes/Catppuccin Macchiato.tmTheme
```

All entries are symlinks (`->` arrows), not real files. `~/.config/bat` and `~/.config/bat/themes` are real directories, not symlinks.
