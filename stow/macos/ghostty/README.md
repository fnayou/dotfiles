# ghostty (macOS)

macOS-only settings for [Ghostty](https://ghostty.org/). Stows into `~/.config/ghostty/`, next to
the common `ghostty` package.

## What it configures

- Both Option keys act as Alt (`macos-option-as-alt = true`).

The common `config.ghostty` ends with `config-file = ?macos.ghostty`, an optional include: it loads
this package's `macos.ghostty` when it is linked and skips it otherwise.

Without this package, Ghostty on macOS still starts with the common config, but Option is not Alt.

No custom app icon is shipped: on macOS 27 with Ghostty 1.3.1, `macos-icon` (custom or built-in)
was read by Ghostty but not shown by the Dock (PRD 0028, Decision 11 withdrawn).

## Files

| File | Stowed to | Purpose |
|---|---|---|
| `.config/ghostty/macos.ghostty` | `~/.config/ghostty/macos.ghostty` | macOS-only options — Option as Alt |

## Setup

macOS only. Stow the common `ghostty` package first, then this one. Both use `--no-folding`.
See [Ghostty Package Setup Guide](../../../docs/guides/ghostty-setup.md) for the full dry-run →
install workflow. Quit Ghostty fully and start it again to apply the setting.
