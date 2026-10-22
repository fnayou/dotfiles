# Terminal.app Setup Guide

This guide explains how to give the macOS **Terminal.app** the repository's Catppuccin Macchiato
profile and a Nerd Font. It is written for a human user, not for implementation agents.

Unlike the other packages, `stow/macos/terminal/` is **not stowed**. Terminal.app keeps its profiles
inside the `com.apple.Terminal` preference domain, so there is no file for Stow to link. The profile
is deployed with `task terminal:sync` (PRD 0031, ADR 0081).

Run every command in this guide from the root of your dotfiles repository (`/path/to/dotfiles`).

---

## 1. What this manages

| File | Used by | Purpose |
|---|---|---|
| `stow/macos/terminal/Catppuccin Macchiato.terminal` | `task terminal:sync` | The profile: background, text, cursor, selection, the 16 ANSI colors and the font |
| `scripts/terminal-sync.sh` | `task terminal:sync` | Reports, applies and rebuilds the profile |

The profile uses:

- the colors of `stow/common/alacritty/.config/alacritty/catppuccin-macchiato.toml`, with blue
  `#8aadf4` as the accent;
- the font `JetBrainsMono Nerd Font` (PostScript name `JetBrainsMonoNF-Regular`), size 13, so the
  Oh My Posh icons render instead of a square with a question mark.

The selection color is Surface2 `#5b6078`, not the rosewater of Alacritty and Ghostty. Terminal.app
cannot set a selection text color, so a rosewater background would hide light text.

## 2. What it does NOT manage

- Window size, opacity, blur, bell, tab behavior and key mappings.
- Option as Alt (Meta) and the other Alacritty/Ghostty key bindings.
- The shell: Terminal.app already starts your login shell.
- 24-bit color. **Terminal.app does not support it.** Hex colors from Oh My Posh, Neovim and bat are
  approximated to 256 colors, so they look slightly different from Alacritty and Ghostty even with
  this profile. The profile fixes the background, text and ANSI colors only.

Platform: macOS only. The script exits on Arch and Debian before it reads any preference.

## 3. Prerequisites

⚠️  MANUAL STEP — review before running
```bash
# macOS
brew install --cask font-jetbrains-mono-nerd-font
```

## 4. Dry-run step

The default mode reads the state and changes nothing:

```bash
# macOS
task terminal:sync
```

It reports, with ok/ko lines:

- whether the font is installed;
- whether the `Catppuccin Macchiato` profile exists, and whether it matches the repository file;
- which profiles are the default and the startup profile.

## 5. Apply step

Terminal.app keeps its profiles in memory and rewrites them when it quits, which can drop a profile
added behind its back. The script therefore **refuses to run while Terminal.app is open**. Quit it
with Cmd+Q and run the commands from another terminal (Alacritty or Ghostty).

⚠️  MANUAL STEP — review output before running
```bash
# macOS — adds or updates only the "Catppuccin Macchiato" profile; writes a backup first
task terminal:sync ARGS='--apply'
```

The script prints the backup path. The backup is written next to the live preferences file as
`com.apple.Terminal.plist.bak-<timestamp>`. Re-running `--apply` is safe: it replaces that one
profile and never duplicates it.

## 6. Make it the default profile (optional)

Without this step the profile is available under Terminal → Settings → Profiles, and your current
default stays as it is. This lets you try it first.

⚠️  MANUAL STEP — review output before running
```bash
# macOS — also sets the default and startup profile
task terminal:sync ARGS='--apply --set-default'
```

The script prints the previous default and startup profile and the exact commands that restore
them. Keep that output until you are happy with the result.

## 7. Validation steps

```bash
# macOS
task terminal:sync          # expect SYNCED, and ok on the default and startup profile if you set them
```

Then open Terminal.app and check:

- the Oh My Posh Apple icon renders, not a square with a question mark;
- the background is `#24273a` and the text is `#cad3f5`.

If a freshly applied profile does not appear in the Profiles list, quit Terminal.app and reopen it.
As a last resort:

⚠️  MANUAL STEP — review before running
```bash
# macOS — restarts the preferences daemon; harmless but affects every app's preferences cache
killall cfprefsd
```

## 8. Rollback steps

Restore the whole domain from the backup the script printed:

⚠️  MANUAL STEP — review before running
```bash
# macOS — quit Terminal.app first; replace <timestamp> with the one the script printed
defaults import com.apple.Terminal "$HOME/Library/Preferences/com.apple.Terminal.plist.bak-<timestamp>"
```

To undo only the default profile, run the restore commands that `--set-default` printed. They look
like this, with your previous values:

⚠️  MANUAL STEP — review before running
```bash
# macOS — example only; use the exact commands the script printed
defaults write com.apple.Terminal 'Default Window Settings' -string 'Clear Dark'
defaults write com.apple.Terminal 'Startup Window Settings' -string 'Clear Dark'
```

To remove only the profile, open Terminal → Settings → Profiles, select `Catppuccin Macchiato` and
click the minus button. The repository is not affected by any of these steps.

## 9. Changing the palette

The palette has one source, the Alacritty Macchiato theme. After changing it, regenerate the profile
(this writes inside the repository only) and review the diff:

```bash
# macOS
task terminal:sync ARGS='--build'
git diff --stat stow/macos/terminal/
```

Then apply it again as in §5.

## 10. Troubleshooting

### `REFUSED: Terminal.app is running`

Quit Terminal.app with Cmd+Q and run the command from another terminal. A terminal window of
Terminal.app itself cannot do it, because it is the application being quit.

### `MISSING: preference domain com.apple.Terminal not found`

Open Terminal.app once so it creates its preferences, quit it, and run the command again.

### `UNSUPPORTED: Terminal.app exists on macOS only`

You ran it on Arch or Debian. Nothing was changed.

### The icon is still a square

The font is missing or the profile is not in use. Check the first line of the dry run
(`font JetBrainsMono Nerd Font installed`), then confirm the window uses the
`Catppuccin Macchiato` profile under Terminal → Settings → Profiles.
