# bat

Managed [bat](https://github.com/sharkdp/bat) configuration. Stows into `~/.config/bat/`.

## What it configures

- Output style (line numbers, git changes, header), wrapping, italics, paging.
- Catppuccin Macchiato theme, shipped as a `.tmTheme` and compiled into bat's cache.

## Files

| File | Stowed to | Purpose |
|---|---|---|
| `.config/bat/config` | `~/.config/bat/config` | Main config — style, wrap, paging, active theme |
| `.config/bat/themes/Catppuccin Macchiato.tmTheme` | `~/.config/bat/themes/Catppuccin Macchiato.tmTheme` | Catppuccin Macchiato theme ([catppuccin/bat](https://github.com/catppuccin/bat)) |

## Setup

See [bat Package Setup Guide](../../../docs/guides/bat-setup.md) for the full dry-run → install → `bat cache --build` workflow.
