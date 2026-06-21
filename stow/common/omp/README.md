# omp

Managed [Oh My Posh](https://ohmyposh.dev/) prompt theme. Stows into `~/.config/omp/`.

The zsh package initializes Oh My Posh against this config (see the zsh prompt layer).

## What it configures

- Prompt segments (path, git, status) and layout.
- Catppuccin Macchiato palette colors.

## Files

| File | Stowed to | Purpose |
|---|---|---|
| `.config/omp/omp.toml` | `~/.config/omp/omp.toml` | Oh My Posh prompt theme |

## Setup

No dedicated guide. Stow with the standard workflow:

```bash
# Dry run first
stow --dir=stow/common --target="$HOME" --simulate omp
```

See the [Packages Setup Guide](../../../docs/guides/packages-setup.md) to install Oh My Posh itself.
