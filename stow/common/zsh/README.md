# zsh

Managed [Zsh](https://www.zsh.org/) configuration. Stows into `~/.config/zsh/`.

Layered design: `index.zsh` is the entry point and sources each layer in order. After Stow,
`~/.config/zsh/` is a **real directory** of per-file symlinks — not a single directory symlink.

## What it configures

- Layered init: path, history, completions, plugins, tools, prompt, aliases, keybindings.
- Per-OS layers (`macos.zsh`, `arch.zsh`) loaded conditionally.
- Local, unstowed override hook (`local.zsh`, from `local.zsh.example`) for machine-specific values.

## Files (selected)

| File | Purpose |
|---|---|
| `.config/zsh/index.zsh` | Entry point — sources all layers in order |
| `.config/zsh/path.zsh`, `history.zsh`, `completions.zsh` | Core shell setup |
| `.config/zsh/plugins.zsh`, `tools.zsh`, `prompt.zsh` | Plugins, CLI tools, Oh My Posh prompt |
| `.config/zsh/aliases.zsh`, `keybindings.zsh` | Aliases and key bindings |
| `.config/zsh/macos.zsh`, `arch.zsh` | Per-platform layers |
| `.config/zsh/local.zsh.example` | Template for local-only overrides |

## Setup

See [Zsh Package Setup Guide](../../../docs/guides/zsh-setup.md) for the full dry-run → install workflow, `.zshenv` wiring, and local override setup.
