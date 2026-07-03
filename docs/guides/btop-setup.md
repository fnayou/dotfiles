# btop Package Setup Guide

This guide explains how to set up the managed [btop](https://github.com/aristocratos/btop)
configuration on a new machine. It is written for a human user, not for implementation agents.

---

## 1. What this package manages

The `stow/common/btop/` package manages two files, stowed into `~/.config/btop/`:

| Repository file | Symlink created at | Purpose |
|---|---|---|
| `stow/common/btop/.config/btop/btop.conf` | `~/.config/btop/btop.conf` | Active theme, background, truecolor, vim keys |
| `stow/common/btop/.config/btop/themes/catppuccin_macchiato.theme` | `~/.config/btop/themes/catppuccin_macchiato.theme` | Catppuccin Macchiato theme |

btop reads `btop.conf` and the `themes/` directory automatically. Unlike bat, there is **no
cache-build step** — the theme applies as soon as the files are stowed and btop is restarted.

Most btop options are left commented in `btop.conf`; btop writes its own defaults for anything you
don't set. Edit the commented lines to taste.

---

## 2. Accent note

The [catppuccin/btop](https://github.com/catppuccin/btop) port ships **one theme per flavor** —
there is no separate accent selector like eza or Alacritty have. The Macchiato theme already uses
**Blue** (`#8aadf4`) for highlights, the selected process row, and the process-box outline, so the
blue-accent look is built in. To use a different accent you would hand-edit the `.theme` file.

---

## 3. Platform notes

This package lives under `stow/common/` and is shared across macOS, Arch, and Debian. btop, its
config path (`~/.config/btop/` via XDG), and the theme format are identical on all three.

---

## 4. Prerequisites

Install btop and GNU Stow before beginning.

### macOS

⚠️  MANUAL STEP — review before running
```bash
brew install btop stow
```

### Arch / EndeavourOS

⚠️  MANUAL STEP — review before running
```bash
sudo pacman -S btop stow
```

### Debian (stable / trixie)

⚠️  MANUAL STEP — review before running
```bash
sudo apt install btop stow
```

Verify btop is available:

```bash
btop --version
```

---

## 5. Dry-run step

Always dry-run the Stow package before applying it. This shows exactly what symlinks would be
created without making any changes.

```bash
stow --dir=stow/common --target="$HOME" --no-folding --simulate -v btop
```

**What to look for:** Two `LINK:` lines:

```
LINK: .config/btop/btop.conf => ...
LINK: .config/btop/themes/catppuccin_macchiato.theme => ...
```

No conflict lines. Exit code 0. (`MKDIR:` lines for `.config/btop` and `themes` are expected when
the directory does not yet exist.)

**If you see a conflict:** A real file already exists at the target path. Do NOT use
`stow --adopt`. See the Troubleshooting section below.

---

## 6. Apply step (Stow)

After reviewing the dry-run output and confirming no conflicts, apply the Stow package:

⚠️  MANUAL STEP — review dry-run output before running
```bash
stow --dir=stow/common --target="$HOME" --no-folding btop
```

**`--no-folding` is required.** Without it, Stow may collapse `~/.config/btop` into a single
symlink pointing at the package directory instead of creating `~/.config/btop` as a real directory.
This matters for btop because it writes runtime state (`btop.conf` updates on exit) into that
directory — a folded symlink would push those writes back into the repository.

**`stow --adopt` is forbidden.** It silently overwrites files in `$HOME` with the repository
version, destroying your existing content without a backup.

Restart btop to pick up the theme.

---

## 7. Validation steps

After stowing, verify the installation:

```bash
# Confirm ~/.config/btop is a real directory, NOT a folded symlink
test ! -L "$HOME/.config/btop" && echo "OK: ~/.config/btop is a real directory"
```

```bash
# Confirm the symlinks exist and resolve into the repository
ls -la ~/.config/btop/
readlink ~/.config/btop/btop.conf
readlink ~/.config/btop/themes/catppuccin_macchiato.theme
```

Both should be shown as symlinks (`->` arrow) resolving into your dotfiles repository.

Launch btop to confirm the colors apply:

```bash
btop
```

Highlights and the selected process row render blue; the CPU / Memory / Network / Proc boxes show
Mauve / Green / Maroon / Blue outlines.

---

## 8. Rollback steps

To undo the setup:

⚠️  MANUAL STEP — review before running
```bash
stow --dir=stow/common --target="$HOME" --delete btop
```

This removes the symlinks from `~/.config/btop/`. Your btop installation is not affected — it falls
back to its built-in default theme and options.

---

## 9. Troubleshooting

### Stow conflict: real file exists at target

Symptom: Stow dry-run reports a conflict such as:

```
WARNING! stowing btop would cause conflicts:
  * cannot stow ... over existing target .config/btop/btop.conf since neither a link nor a directory and --adopt not specified
All operations aborted.
```

This happens when a real (non-symlink) file already exists at the target path — typically because
btop wrote its own `btop.conf` on a previous run.

Resolution:
1. Identify the conflicting file: `ls -la ~/.config/btop/`
2. Compare it with the repository version:
   ```bash
   diff ~/.config/btop/btop.conf stow/common/btop/.config/btop/btop.conf
   ```
3. If you want to keep changes from the home file, update the repository file first.
4. Move the existing file out of the way (back it up, don't delete the whole directory):
   ```bash
   mv ~/.config/btop/btop.conf ~/.config/btop/btop.conf.bak
   ```
5. Re-run the dry-run to confirm the conflict is gone.
6. Then run the Stow apply step.

Do NOT use `stow --adopt` — it would silently overwrite your existing file with the repository
version without any backup.

### `~/.config/btop` became a symlink (directory folding)

Symptom: `~/.config/btop` is a symlink pointing at the package directory instead of a real
directory. Caused by stowing without `--no-folding`.

Verify:

```bash
ls -ld ~/.config/btop    # a leading "l" (lrwxr-xr-x) means it is a folded symlink
```

Resolution:
1. Roll back the fold:

   ⚠️  MANUAL STEP — review before running
   ```bash
   stow --dir=stow/common --target="$HOME" --delete btop
   ```

2. Recreate `~/.config/btop` as a real directory:

   ```bash
   mkdir -p ~/.config/btop
   ```

3. Re-run the apply step WITH `--no-folding`:

   ⚠️  MANUAL STEP — review before running
   ```bash
   stow --dir=stow/common --target="$HOME" --no-folding btop
   ```

4. Confirm it is now a real directory: `test ! -L "$HOME/.config/btop" && echo "OK: real directory"`

### Theme not applied (colors look default)

Symptom: btop shows its default theme instead of Catppuccin Macchiato.

Most likely causes:
- `color_theme` in `btop.conf` does not match the theme file name. It must be
  `color_theme = "catppuccin_macchiato"` (the `.theme` file name, without the suffix).
- The terminal is limited to 256 colors. Set `truecolor = False` in `btop.conf`, or use a
  truecolor-capable terminal.
- btop wrote its own `btop.conf` before stowing, so your symlink was never used — see the conflict
  section above.

There is no compiled theme cache to rebuild (this differs from bat).

---

## 10. Expected final file layout

After successful setup, your files should look like this:

```
~/.config/btop/
  btop.conf  ->  /path/to/dotfiles/stow/common/btop/.config/btop/btop.conf
  themes/
    catppuccin_macchiato.theme  ->  /path/to/dotfiles/stow/common/btop/.config/btop/themes/catppuccin_macchiato.theme
```

The two files are symlinks (`->` arrow). `~/.config/btop` and `~/.config/btop/themes` are real
directories, not symlinks.
