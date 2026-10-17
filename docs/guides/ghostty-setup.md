# Ghostty Package Setup Guide

This guide explains how to set up the managed Ghostty configuration on a new machine. It is written for a human user, not for implementation agents.

Two Stow packages are involved:

- `stow/common/ghostty/` — the main configuration, for macOS and Arch.
- `stow/macos/ghostty/` — macOS-only settings. Stow it on macOS only, after the common package.

Run every command in this guide from the root of your dotfiles repository (`/path/to/dotfiles`).

---

## 1. What this package manages

The `stow/common/ghostty/` package manages two files, stowed into `~/.config/ghostty/`:

| Repository file | Symlink created at | Purpose |
|---|---|---|
| `stow/common/ghostty/.config/ghostty/config.ghostty` | `~/.config/ghostty/config.ghostty` | Main configuration — theme selection, terminal type, window, scrolling, font, shell, key bindings |
| `stow/common/ghostty/.config/ghostty/themes/catppuccin-macchiato` | `~/.config/ghostty/themes/catppuccin-macchiato` | Catppuccin Macchiato color theme |

Ghostty loads `~/.config/ghostty/config.ghostty` automatically on start. The line `theme = catppuccin-macchiato` loads the theme by name from `~/.config/ghostty/themes/`. No manual activation step is required beyond stowing the files and restarting Ghostty.

[macOS] The second package, `stow/macos/ghostty/`, manages one file:

| Repository file | Symlink created at | Purpose |
|---|---|---|
| `stow/macos/ghostty/.config/ghostty/macos.ghostty` | `~/.config/ghostty/macos.ghostty` | macOS-only options — `macos-option-as-alt = true` (both Option keys act as Alt) |

The last line of the common `config.ghostty` is `config-file = ?macos.ghostty`. This is an optional include: Ghostty loads `macos.ghostty` when it is linked and skips it, with no error, when it is not.

---

## 2. What it does NOT manage

- [macOS] `~/Library/Application Support/com.mitchellh.ghostty/config.ghostty`. Ghostty reads this file in addition to `~/.config/ghostty/config.ghostty`, and its settings layer over the repository config. It is not managed by this repository and must stay empty. Change settings only in the repository files.
- Ghostty's own state (window state, caches, preferences written by the app).
- Fonts. `JetBrainsMono Nerd Font` is installed separately (see Prerequisites).
- The `/Applications/Ghostty.app` bundle. It is never modified.
- The app icon. No custom icon is shipped; Ghostty keeps its official icon.

### Platform notes

- The common `config.ghostty` has no `macos-*` option. macOS-only options live in `macos.ghostty`.
- [Arch] Stow only the common package. `macos.ghostty` is not linked, so the optional include `config-file = ?macos.ghostty` is skipped with no message. The `alt+…` key bindings apply to the Alt key.
- [macOS] With only the common package stowed, Option is not Alt: Option+N and Option+Shift+L compose characters instead of typing `~` and `|`. This is expected. Stow both packages on macOS.
- [Debian] Ghostty is not installed and neither package is stowed on Debian servers.

---

## 3. Prerequisites

Install Ghostty, JetBrainsMono Nerd Font, and GNU Stow before beginning.

### macOS

⚠️  MANUAL STEP — review before running
```bash
# macOS
brew install --cask ghostty
brew install --cask font-jetbrains-mono-nerd-font
brew install stow
```

### Arch / EndeavourOS

⚠️  MANUAL STEP — review before running
```bash
# Arch
sudo pacman -S ghostty ttf-jetbrains-mono-nerd stow
```

Verify Ghostty is available. On macOS the binary is not on `PATH`; use its full path:

```bash
# macOS
/Applications/Ghostty.app/Contents/MacOS/ghostty --version
```

```bash
# Arch
ghostty --version
```

---

## 4. Dry-run step

Always dry-run the Stow packages before applying them. This shows exactly what symlinks would be created without making any changes. `-v` makes Stow print the `LINK:` lines.

Common package (macOS and Arch):

```bash
stow -v --dir=stow/common --target="$HOME" --simulate --no-folding ghostty
```

**What to look for:** Two `LINK:` lines, one for each managed file:

```
LINK: .config/ghostty/config.ghostty => ../../path/to/dotfiles/stow/common/ghostty/.config/ghostty/config.ghostty
LINK: .config/ghostty/themes/catppuccin-macchiato => ../../../path/to/dotfiles/stow/common/ghostty/.config/ghostty/themes/catppuccin-macchiato
```

The relative part of each target depends on where your repository sits. `MKDIR:` lines and a simulation-mode warning may also appear. No conflict lines. Exit code 0.

[macOS] Then dry-run the macOS package:

```bash
# macOS
stow -v --dir=stow/macos --target="$HOME" --simulate --no-folding ghostty
```

**What to look for:** One `LINK:` line:

```
LINK: .config/ghostty/macos.ghostty => ../../path/to/dotfiles/stow/macos/ghostty/.config/ghostty/macos.ghostty
```

No conflict lines. Exit code 0.

**If you see a conflict:** A real file already exists at the target path. Do NOT use `stow --adopt`. See the Troubleshooting section below.

---

## 5. Apply step (Stow)

After reviewing the dry-run output and confirming no conflicts, apply the common package:

⚠️  MANUAL STEP — review before running
```bash
stow --dir=stow/common --target="$HOME" --no-folding ghostty
```

[macOS] Then apply the macOS package:

⚠️  MANUAL STEP — review before running
```bash
# macOS
stow --dir=stow/macos --target="$HOME" --no-folding ghostty
```

**`--no-folding` is required for both packages.** The two packages link files into the same directory, `~/.config/ghostty/`. Without `--no-folding`, Stow may collapse `~/.config/ghostty` (or `~/.config/ghostty/themes`) into a single symlink pointing at one package directory. That blocks the other package, and anything Ghostty or you write there lands in the repository. With `--no-folding`, both directories stay real directories with one symlink per file.

**`stow --adopt` is forbidden.** It silently overwrites files with the repository version, destroying your existing content without a backup.

---

## 6. Manual activation steps

1. Quit Ghostty fully (Cmd+Q on macOS, close every window on Arch) and start it again. Some changes, such as background opacity on macOS, apply only after a full restart.
2. Confirm the shell is a login zsh:

   ```bash
   [[ -o login ]] && echo login-shell
   echo $SHELL $0
   ```

   Expected: `login-shell`, and both values name zsh.
3. [macOS] Check that Option acts as Alt: Option+N types `~` and Option+Shift+L types `|`.
4. Check that Shift+Enter at the prompt sends a newline.
5. Numpad check (PRD 0028 Decision 9). Skip it if your keyboard has no numeric keypad. Run:

   ```bash
   cat -v
   ```

   Press, on the numeric keypad: `0`–`9`, `+`, `-`, `*`, `/`, `.`, then `Enter`. Then press Ctrl+C. Repeat in application keypad mode:

   ```bash
   tput smkx; cat -v
   ```

   Press the same keys, then Ctrl+C, then restore normal keypad mode:

   ```bash
   tput rmkx
   ```

   Expected: each key prints its literal character (`0123456789+-*/.`) and `Enter` ends the line, in both runs. A key that prints anything else (for example an `^[O…` sequence) misbehaves.

**If a numpad key misbehaves:** fix it in the repository, not in the Application Support file. Add one `keybind = numpad_<key>=text:<char>` line per misbehaving key to `stow/common/ghostty/.config/ghostty/config.ghostty`, at the end of the key-binding block and before the final `config-file` line. Then quit and restart Ghostty and repeat the check.

---

## 7. Validation steps

After stowing, verify the installation:

```bash
# Confirm ~/.config/ghostty and its themes/ directory are real directories, NOT folded symlinks
test ! -L "$HOME/.config/ghostty" && echo "OK: ~/.config/ghostty is a real directory"
test ! -L "$HOME/.config/ghostty/themes" && echo "OK: ~/.config/ghostty/themes is a real directory"
```

```bash
# Confirm the symlinks exist
ls -la ~/.config/ghostty/ ~/.config/ghostty/themes/
```

Expected: `config.ghostty` and `themes/catppuccin-macchiato` shown as symlinks (`->` arrows); on macOS also `macos.ghostty`.

```bash
# Confirm each common symlink resolves into the repository
readlink ~/.config/ghostty/config.ghostty
readlink ~/.config/ghostty/themes/catppuccin-macchiato
```

```bash
# macOS
readlink ~/.config/ghostty/macos.ghostty
```

All should resolve to paths inside your dotfiles repository.

Validate the configuration Ghostty loads:

```bash
# macOS
/Applications/Ghostty.app/Contents/MacOS/ghostty +validate-config; echo "exit=$?"
```

```bash
# Arch
ghostty +validate-config; echo "exit=$?"
```

Expected: `exit=0` and no message.

[macOS] Confirm the Application Support file is still empty:

```bash
# macOS
wc -c < "$HOME/Library/Application Support/com.mitchellh.ghostty/config.ghostty"
```

Expected: `0`.

Finally, check the theme visually: a new Ghostty window shows the Catppuccin Macchiato colors (dark blue-gray background, light lavender text).

---

## 8. Rollback steps

To undo the setup, remove the macOS package first (macOS only), then the common package.

⚠️  MANUAL STEP — review before running
```bash
# macOS
stow --dir=stow/macos --target="$HOME" --delete ghostty
```

⚠️  MANUAL STEP — review before running
```bash
stow --dir=stow/common --target="$HOME" --delete ghostty
```

This removes the symlinks from `~/.config/ghostty/`. Your Ghostty installation is not affected. After a full restart, Ghostty falls back to its built-in defaults or any remaining config you have in that directory.

Removing only the macOS package leaves the common config working: the optional include `config-file = ?macos.ghostty` is skipped, and Option is no longer Alt.

---

## 9. Troubleshooting

### Stow conflict: real file exists at target

Symptom: Stow dry-run reports a conflict such as:

```
WARNING! stowing ghostty would cause conflicts:
  * cannot stow ... over existing target .config/ghostty/config.ghostty since neither a link nor a directory and --adopt not specified
All operations aborted.
```

This happens when a real (non-symlink) file already exists at the target path — typically from a previous manual Ghostty setup.

Resolution:
1. Identify the conflicting file: `ls -la ~/.config/ghostty/`
2. Compare it with the repository version to check for differences you want to keep:
   ```bash
   diff ~/.config/ghostty/config.ghostty stow/common/ghostty/.config/ghostty/config.ghostty
   ```
3. If you want to keep changes from the home file, update the repository file first.
4. Move the existing file out of the way:

   ⚠️  MANUAL STEP — review before running
   ```bash
   mv ~/.config/ghostty/config.ghostty ~/.config/ghostty/config.ghostty.bak
   ```
5. Re-run the dry-run to confirm the conflict is gone.
6. Then run the Stow apply step.

Do NOT use `stow --adopt` — it would silently overwrite your existing file with the repository version without any backup.

### `~/.config/ghostty` became a symlink (directory folding)

Symptom: `~/.config/ghostty` or `~/.config/ghostty/themes` is a symlink pointing at a package directory instead of a real directory. Caused by stowing without `--no-folding`.

Verify:

```bash
ls -ld ~/.config/ghostty ~/.config/ghostty/themes    # a leading "l" (lrwxr-xr-x) means a folded symlink
```

Resolution:

Step 1 — roll back both packages (the macOS package on macOS only):

⚠️  MANUAL STEP — review before running
```bash
# macOS
stow --dir=stow/macos --target="$HOME" --delete ghostty
```

⚠️  MANUAL STEP — review before running
```bash
stow --dir=stow/common --target="$HOME" --delete ghostty
```

Step 2 — recreate the directories as real directories:

```bash
mkdir -p ~/.config/ghostty/themes
```

Step 3 — re-run the apply steps WITH `--no-folding`:

⚠️  MANUAL STEP — review before running
```bash
stow --dir=stow/common --target="$HOME" --no-folding ghostty
```

⚠️  MANUAL STEP — review before running
```bash
# macOS
stow --dir=stow/macos --target="$HOME" --no-folding ghostty
```

Step 4 — confirm both are real directories:

```bash
test ! -L "$HOME/.config/ghostty" && test ! -L "$HOME/.config/ghostty/themes" && echo "OK: real directories"
```

### Theme not applied (color scheme looks wrong)

Symptom: Ghostty starts but shows default colors, or a slightly different Catppuccin palette.

Causes:
- The `themes/catppuccin-macchiato` symlink is missing, so the theme name does not resolve.
- The `theme =` line was changed to Ghostty's bundled `Catppuccin Macchiato` (capitalised, with a space). That is a different file from the repository theme `catppuccin-macchiato`. The repository config must say `theme = catppuccin-macchiato`.

Resolution:

```bash
# Confirm the theme symlink exists and resolves into the repository
ls -la ~/.config/ghostty/themes/
readlink ~/.config/ghostty/themes/catppuccin-macchiato
grep '^theme = ' ~/.config/ghostty/config.ghostty
```

```bash
# macOS
/Applications/Ghostty.app/Contents/MacOS/ghostty +show-config | grep '^palette = 0='
```

```bash
# Arch
ghostty +show-config | grep '^palette = 0='
```

Expected: `theme = catppuccin-macchiato` and `palette = 0=#494d64`. If the theme symlink is missing, re-run the Stow apply step.

### Settings overridden by the Application Support file [macOS]

Symptom: a setting from the repository config does not apply, or Ghostty shows settings you did not set in the repository.

Cause: `~/Library/Application Support/com.mitchellh.ghostty/config.ghostty` is not empty. Ghostty reads it in addition to `~/.config/ghostty/config.ghostty`, and its settings layer over the repository config. Ghostty's "open config" action (Cmd+,) can open this file for editing.

Check:

```bash
# macOS
wc -c < "$HOME/Library/Application Support/com.mitchellh.ghostty/config.ghostty"
cat "$HOME/Library/Application Support/com.mitchellh.ghostty/config.ghostty"
```

Resolution: move any setting you want to keep into the repository files, then empty the Application Support file by hand. It must stay empty. Then quit and restart Ghostty.

### `xterm-ghostty` vs `xterm-256color` over SSH

Symptom: over SSH, a remote host reports an unknown terminal type, or full-screen programs draw incorrectly.

Cause: Ghostty's own terminal type, `xterm-ghostty`, has no terminfo entry on most remote hosts. The repository config sets `term = xterm-256color`, which remote hosts (including Debian) already ship.

Check, in a Ghostty window:

```bash
echo $TERM
```

Expected: `xterm-256color`. If it prints `xterm-ghostty`, the repository config is not loaded: check the symlinks (Validation steps) and restart Ghostty.

### Font fallback (font looks wrong)

Symptom: Ghostty uses a system font instead of JetBrainsMono Nerd Font, and icons show as boxes. Ghostty prints no error when a font is missing.

Check that the font is installed:

```bash
# macOS
/Applications/Ghostty.app/Contents/MacOS/ghostty +list-fonts | grep -i 'JetBrainsMono Nerd Font'
```

```bash
# Arch
ghostty +list-fonts | grep -i 'JetBrainsMono Nerd Font'
```

If nothing is printed, install the font (see Prerequisites) and restart Ghostty.

### Option not acting as Alt [macOS]

Symptom: Option+N or Option+Shift+L composes a character instead of typing `~` or `|`.

Causes:
- Ghostty was not fully restarted after stowing. Quit it with Cmd+Q and start it again.
- The macOS package is not stowed. Run the macOS dry-run and apply steps.
- `macos.ghostty` is not linked. Check it:

```bash
# macOS
readlink ~/.config/ghostty/macos.ghostty
/Applications/Ghostty.app/Contents/MacOS/ghostty +show-config | grep '^macos-option-as-alt'
```

Expected: a path inside your dotfiles repository, and `macos-option-as-alt = true`.

### Custom Dock icon not supported [macOS]

A custom Dock icon is not supported on macOS 27 with Ghostty 1.3.1. Ghostty reads `macos-icon` (custom or built-in), but the Dock keeps the official icon. No icon file and no `macos-icon` line ship in these packages (PRD 0028 Decision 11, withdrawn).

---

## 10. Expected final file layout

After successful setup, your files should look like this:

```
~/.config/ghostty/
  config.ghostty            ->  /path/to/dotfiles/stow/common/ghostty/.config/ghostty/config.ghostty
  macos.ghostty             ->  /path/to/dotfiles/stow/macos/ghostty/.config/ghostty/macos.ghostty   (macOS only)
  themes/
    catppuccin-macchiato    ->  /path/to/dotfiles/stow/common/ghostty/.config/ghostty/themes/catppuccin-macchiato
```

All file entries are symlinks (`->` arrows), not real files. `~/.config/ghostty` and `~/.config/ghostty/themes` are real directories, not symlinks. On Arch, `macos.ghostty` is absent.
