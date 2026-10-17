# ghostty

Managed [Ghostty](https://ghostty.org/) terminal configuration. Stows into `~/.config/ghostty/`.

## What it configures

- Window, font, scrolling, key bindings, and shell, mirrored from the alacritty package.
- Catppuccin Macchiato color theme, loaded from a separate repo-managed theme file.

## Files

| File | Stowed to | Purpose |
|---|---|---|
| `.config/ghostty/config.ghostty` | `~/.config/ghostty/config.ghostty` | Main config — window, font, key bindings, shell, theme selection |
| `.config/ghostty/themes/catppuccin-macchiato` | `~/.config/ghostty/themes/catppuccin-macchiato` | Catppuccin Macchiato color theme |

## Setup

See [Ghostty Package Setup Guide](../../../docs/guides/ghostty-setup.md) for the full dry-run → install workflow.

On macOS, also stow `stow/macos/ghostty` for Option-as-Alt (see the setup guide).
