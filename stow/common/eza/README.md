# eza

Managed [eza](https://github.com/eza-community/eza) theme. Stows into `~/.config/eza/`.

## What it configures

- Catppuccin Macchiato (Blue accent) color theme for `eza`, shipped as `theme.yml`.

eza CLI flags and shell aliases (`ls`, `ll`, `la`, `lt`) are **not** managed here — they live
in the zsh package (`aliases.zsh`).

## Files

| File | Stowed to | Purpose |
|---|---|---|
| `.config/eza/theme.yml` | `~/.config/eza/theme.yml` | Catppuccin Macchiato Blue theme ([catppuccin/eza](https://github.com/catppuccin/eza)) |

## Activation

eza reads `~/.config/eza/theme.yml` directly — no cache-build step (unlike bat). The theme is
active as soon as the file is stowed.

## Setup

See [eza Package Setup Guide](../../../docs/guides/eza-setup.md) for the full dry-run → install
workflow.
