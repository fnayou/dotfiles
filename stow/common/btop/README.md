# btop

Managed [btop](https://github.com/aristocratos/btop) configuration. Stows into `~/.config/btop/`.

## What it configures

- Resource-monitor behaviour: active theme, terminal-transparent background, truecolor, vim keys.
  A small set of common options is left commented for you to tweak.
- Catppuccin Macchiato theme, shipped as a `.theme` file and read directly (no cache build).

## Files

| File | Stowed to | Purpose |
|---|---|---|
| `.config/btop/btop.conf` | `~/.config/btop/btop.conf` | Main config — active theme, background, truecolor, vim keys |
| `.config/btop/themes/catppuccin_macchiato.theme` | `~/.config/btop/themes/catppuccin_macchiato.theme` | Catppuccin Macchiato theme ([catppuccin/btop](https://github.com/catppuccin/btop)) |

## Accent

The catppuccin/btop port ships one theme per flavor — there is no separate accent selector.
The Macchiato theme already uses **Blue** (`#8aadf4`) for highlights, the selected process row, and
the process-box outline, so the "blue accent" look is built in.

## Activation

btop reads `~/.config/btop/btop.conf` and its `themes/` directory directly — no cache-build step
(unlike bat). The theme is active as soon as the files are stowed and btop is restarted.

## Setup

See [btop Package Setup Guide](../../../docs/guides/btop-setup.md) for the full dry-run → install
workflow.
