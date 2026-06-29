# Supported Systems

This is a personal setup, kept tidy enough to share. Three systems are actively used and tested; anything
else should be treated as a reference to read and adapt, not a drop-in install.

## Tested platforms

| Platform | Status |
|---|---|
| **macOS** | Primary environment, frequently used |
| **EndeavourOS / Arch Linux** | Also used and supported from the start |
| **Debian** (stable, trixie / 13+) | Supported — runs on all servers |

!!! warning "No broad-Linux claim"
    The repository targets macOS, Arch / EndeavourOS, and Debian (stable, trixie / 13+) specifically.
    Other Linux distributions are not claimed to work — the package manager steps assume Homebrew (macOS),
    `pacman` / AUR (Arch), or `apt` (Debian). On another distro, the shell config and themes may still be
    useful, but you'll need to install dependencies your own way.

!!! note "Debian: package/dependency support is complete; the zsh per-OS layer is pending"
    Package lists, dependency checks, Neovim, and Stow all treat Debian as first-class. The zsh
    **per-OS layer** (`macos.zsh` / `arch.zsh`) and `task detect` currently recognize only macOS and
    Arch — on Debian the shared zsh layers load normally and the OS-specific layer is a no-op for now.

## What's portable vs system-specific

| Layer | Portability |
|---|---|
| Zsh config, aliases, prompt, tool integrations | Portable across macOS, Arch, and Debian; optional tools are guarded and no-op when absent |
| Git config, aliases, ignore | Portable (no OS-specific assumptions) |
| Alacritty, bat, eza, Neovim themes | Portable config paths (XDG); some Alacritty lines are macOS-only but harmless on Linux |
| Package installation | System-specific — Homebrew on macOS, `pacman`/AUR on Arch, `apt` on Debian |
| OS maintenance (`task update` / `clean`) | Branches by OS inside the helper script |

The zsh package separates per-OS concerns into `macos.zsh` and `arch.zsh`, selected at runtime, so the
shared layers stay identical across systems. There is no `debian.zsh` yet — Debian loads the shared
layers only (see the note above). See [Shell](../features/shell.md).

## Check your machine

The repository ships read-only dependency checks (they never install anything):

```bash
task check            # core prerequisites: stow, git, task
task deps:check:zsh   # shell-tier tools: fzf, zoxide, eza, bat, oh-my-posh, zinit
task deps:check:nvim  # Neovim-tier tools: nvim, tree-sitter, rg, fd, node
```

Detect which OS the helper scripts will assume:

```bash
task detect           # prints "macos" or "arch" (Debian shell-layer detection pending)
```

## Expect to adapt

This configuration encodes personal preferences. Treat it as a starting point: read the parts that
interest you, copy what fits, and change what doesn't. See [Philosophy](../philosophy.md) and
[Getting Started](../getting-started.md).

## Related

- [Installation](../installation.md) · [Shell Dependencies](shell-dependencies.md) · [Troubleshooting](troubleshooting.md)
