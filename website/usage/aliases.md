# Aliases

The aliases below come from the actual config in `stow/common/zsh/` (and the per-OS layers). Tool-backed
aliases are guarded with `command -v` — if the tool isn't installed, the alias falls back or is skipped.

## Listing and files

Defined in `aliases.zsh`. When `eza` is installed:

| Alias | Expands to |
|---|---|
| `ls` | `eza --icons --long` |
| `ll` | `eza --icons --all --long` |
| `tree` | `eza --icons --tree` |

Without `eza`, `ll` falls back to `ls -ahl`.

## Safety overrides

These add confirmation/verbosity so destructive commands are less surprising:

| Alias | Expands to |
|---|---|
| `grep` | `grep --color=auto` |
| `cp` | `cp -iv` |
| `rm` | `rm -i` |
| `mv` | `mv -iv` |

## File viewing (bat)

When `bat` is installed:

| Alias | Effect |
|---|---|
| `cat` | `bat` |
| `*.md` / `*.txt` / `*.log` | suffix aliases — run the file through `bat` |

Suffix aliases mean typing `./notes.md` opens it in `bat`.

## Navigation

`cd` is replaced by [zoxide](https://github.com/ajeetdsouza/zoxide) via `zoxide init --cmd cd zsh` in
`tools.zsh`, so `cd <partial-name>` jumps to frequently used directories.

## System / package management (Arch)

From `arch.zsh` (sourced only on Arch / EndeavourOS):

| Alias | Expands to |
|---|---|
| `aur` | `yay` or `paru` (whichever is installed) |
| `sc` | `systemctl` |
| `scu` | `systemctl --user` |
| `pacs` | `pacman -Ss` (search) |
| `paci` | `sudo pacman -S` (install) |
| `pacu` | `sudo pacman -Syu` (upgrade) |

## macOS

From `macos.zsh`:

| Alias | Expands to |
|---|---|
| `o` | `open` |

## Git aliases

The Git package defines a large set of short aliases in `stow/common/git/.config/git/aliases`. A few
high-traffic ones:

| Alias | Expands to |
|---|---|
| `git s` | `status` |
| `git a` | `add --all` |
| `git cm` | `commit -m` |
| `git cam` | `commit -am` |
| `git ps` | `push` |
| `git pl` | `pull` |
| `git lg` | `log --oneline --graph --decorate` |
| `git b` | `branch` |
| `git o` | `checkout` |

!!! info "Full list in the repo"
    There are many more (diff, rebase, stash, remote, and helper shortcuts). See the complete file at
    `stow/common/git/.config/git/aliases` in the repository.
