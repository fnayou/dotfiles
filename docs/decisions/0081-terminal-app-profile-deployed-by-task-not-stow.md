# Decision: Terminal.app Profile Deployed by a Task, Not by Stow

**Number:** 0081
**Date:** 2026-10-23
**Status:** Accepted
**PRD:** 0031 — macOS Terminal.app Profile
**Architecture:** 0027 — macOS Terminal.app Profile

## Context

macOS Terminal.app rendered the Oh My Posh Apple glyph as a placeholder square, because its
profile font was not a Nerd Font, and used its own colors instead of the repository's Catppuccin
Macchiato palette. Alacritty and Ghostty are configured by files that Stow links. Terminal.app is
different: it keeps its profiles inside the `Window Settings` dictionary of the `com.apple.Terminal`
preference domain, as `NSKeyedArchiver` data. There is no dotfile for a symlink to point at.

Three ways to deliver a profile were weighed:

- **Stow it.** The repository's normal mechanism, but there is nothing for Terminal.app to read.
- **`open` the `.terminal` file.** Apple's own import path, but it launches Terminal.app, opens a
  window, cannot be dry-run, and its behavior when a profile of the same name exists is unverified.
- **Edit `~/Library/Preferences/com.apple.Terminal.plist` directly.** It bypasses `cfprefsd`, which
  caches the domain, so a live edit can be lost or corrupt state.

## Decision

Ship the profile as `stow/macos/terminal/Catppuccin Macchiato.terminal`, listed entirely in
`.stow-local-ignore` so Stow links nothing, and deploy it with `task terminal:sync`
(`scripts/terminal-sync.sh`), following the `task codex:sync` pattern:

- Dry run by default: it reports the state and writes nothing.
- `--apply` backs up the domain, then adds or updates only the `Catppuccin Macchiato` key with
  `defaults write com.apple.Terminal "Window Settings" -dict-add`. That goes through `cfprefsd`,
  replaces one key, and is idempotent. Every other profile is left alone.
- `--apply` refuses while Terminal.app is running, because Terminal.app rewrites its profiles on
  quit and could drop a key added behind its back.
- Making the profile the default is a separate opt-in, `--apply --set-default`, and the script
  prints the commands that restore the previous values.
- `--build` regenerates the `.terminal` file from the Alacritty Macchiato theme, so the palette has
  one source. It writes inside the repository only.
- macOS only: the script exits on Arch and Debian before it reads any preference.

The selection color departs from Alacritty and Ghostty: Terminal.app cannot set a selection text
color, so the profile uses Surface2 `#5b6078` instead of rosewater `#f4dbd6`, which would hide
light text.

## Consequences

- The deployment is reviewable and repeatable on a new Mac, and nothing changes in Terminal.app
  unless the user runs `--apply` themselves. No agent, bootstrap or install script may call it.
- The package under `stow/macos/` is deliberately not stowed. Tooling that lists packages sees one
  whose files are all ignored.
- Terminal.app has no 24-bit color, so hex colors from Oh My Posh, Neovim and bat are approximated
  to 256 colors there. The profile fixes the background, text and ANSI slots only.
- `TERMINAL_SYNC_DOMAIN` exists for validation. It accepts only the live domain or a
  `com.example.terminal-sync-test*` domain, and the running-Terminal guard and the backup always
  apply to the live domain.
- The backup is written next to the live preferences file, as `codex-sync.sh` does.

## Update (2026-10-23)

The profile uses the **Mono** font variant, `JetBrainsMono Nerd Font Mono` (PostScript name
`JetBrainsMonoNFM-Regular`), not the `JetBrainsMono Nerd Font` (`JetBrainsMonoNF-Regular`) that
Ghostty and Alacritty use. On the first deployment the regular variant was installed and stored in the
profile correctly, yet Terminal.app drew the Oh My Posh icons as boxes with a question mark; switching
the profile to the Mono variant in Terminal.app's font picker made every icon render. PRD 0031 and
architecture 0027 carry a dated amendment. The font is still installed through the same Homebrew cask.
