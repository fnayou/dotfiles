# git

Managed [Git](https://git-scm.com/) configuration. Stows into `~/.config/git/`.

Holds **portable, non-secret** Git settings only. Identity (`user.name`, `user.email`) and
any machine- or work-specific values stay in local, unstowed files.

## What it configures

- Editor, colors, pull strategy, merge conflict style, and diff options.
- Shorthand aliases for common operations.
- Global ignore patterns (macOS artifacts, editor files, archives, logs).

## Files

| File | Stowed to | Purpose |
|---|---|---|
| `.config/git/config-common` | `~/.config/git/config-common` | Portable Git settings |
| `.config/git/aliases` | `~/.config/git/aliases` | Git aliases |
| `.config/git/ignore` | `~/.config/git/ignore` | Global ignore patterns |

## Setup

See [Git Package Setup Guide](../../../docs/guides/git-setup.md) for the full dry-run → install workflow and how to wire in local identity.
