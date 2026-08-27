# Features

What the repository configures, grouped by area. Each area maps to one or more Stow packages under
`stow/common/`. Install them independently — none requires the others.

| Area | Tools / packages | Page |
|---|---|---|
| **Shell** | Layered Zsh config (path, history, plugins, tools, prompt, per-OS layers) | [Shell](shell.md) |
| **Git** | Portable config, aliases, global ignore (no secrets) | [Git](git.md) |
| **Terminal** | Alacritty terminal, Herdr multiplexer | [Terminal](terminal.md) |
| **Editor** | Neovim (Lua, Catppuccin Macchiato) | [Editor](editor.md) |
| **Packages** | bat, eza, btop, Claude Code status line, Codex CLI, and Oh My Posh | [Packages](packages.md) |
| **Scripts** | Helper scripts, e.g. OS maintenance | [Scripts](scripts.md) |

!!! note "One package per tool"
    Everything here is a separate Stow package. You can stow the shell without git, git without
    alacritty, and so on. See [Installation](../installation.md) for the dry-run-first workflow and
    [GNU Stow Workflow](../reference/stow.md) for the mechanics.

A shared thread across the visual tools (alacritty, herdr, bat, eza, btop, oh-my-posh, neovim,
Codex CLI) is the **Catppuccin Macchiato** palette with a blue accent, so the terminal looks
consistent across them.
