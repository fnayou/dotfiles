# terminal (macOS)

Catppuccin Macchiato profile for the macOS **Terminal.app**, with `JetBrainsMono Nerd Font`.

This package is **deliberately not stowed**. Terminal.app does not read a dotfile: its profiles live
inside the `com.apple.Terminal` preference domain. Every file here is listed in
`.stow-local-ignore`, so Stow links nothing from this package. It is deployed with
`task terminal:sync` instead (PRD 0031, architecture 0027).

## What it configures

- Background, text, cursor, selection and the 16 ANSI colors, from the Alacritty Macchiato theme
  (`stow/common/alacritty/.config/alacritty/catppuccin-macchiato.toml`). The selection uses
  Surface2 `#5b6078`, because Terminal.app cannot set a selection text color.
- Font `JetBrainsMono Nerd Font` (PostScript name `JetBrainsMonoNF-Regular`), size 13, so the
  Oh My Posh icons render.

Terminal.app has no 24-bit color. Hex colors from Oh My Posh, Neovim and bat are approximated to
256 colors there.

## Files

| File | Used by | Purpose |
|---|---|---|
| `Catppuccin Macchiato.terminal` | `task terminal:sync` | The profile: source of truth, an XML property list built by `scripts/terminal-sync.sh --build` |
| `.stow-local-ignore` | Stow | Ignores every file, so nothing is linked |

## Setup

macOS only. The commands that change Terminal.app are manual steps. See the
[Terminal.app Setup Guide](../../../docs/guides/terminal-app-setup.md): dry run, apply, set as
default and rollback.
