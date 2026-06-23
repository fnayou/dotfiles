# Packages Setup Guide

This guide explains how to install all tools required by this dotfiles repository on a new machine. It is written for a human user performing the setup, not for implementation agents.

---

## What needs to be installed

All tools in this repository are cross-platform — they are available on both macOS and Arch / EndeavourOS.

| Tool | Used by | Required? |
|---|---|---|
| `git` | repository management | Yes |
| `stow` | symlink manager | Yes |
| [`go-task`](https://taskfile.dev/) | task runner; also powers `task <Tab>` zsh completion | Yes |
| `herdr` | terminal multiplexer with AI agent integration | Optional |
| `fzf` | fuzzy finder (shell integration, fzf-tab completion previews) | Optional |
| `zoxide` | smarter `cd` | Optional |
| `eza` | modern `ls` with icons (aliases, fzf-tab previews) | Optional |
| `bat` | syntax-highlighted file viewer (suffix aliases: `.md`, `.txt`, `.log`) | Optional |
| `oh-my-posh` | shell prompt theme | Optional |
| `zinit` | zsh plugin manager | Optional |

Optional tools are fully guarded — the shell starts cleanly without them. Install only what you want.

Package files:
- macOS / Linux (Homebrew): `packages/Brewfile`
- Arch / EndeavourOS: `packages/arch/packages.txt`

---

## macOS

### Prerequisites

Homebrew must be installed before any other step. If it is not installed:

⚠️  MANUAL STEP — review before running

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### Step 1: Preview what will be installed

```bash
brew bundle list --file=packages/Brewfile
```

This shows which packages would be installed. No changes are made.

### Step 2: Install all packages

⚠️  MANUAL STEP — review brew bundle list output before running

```bash
brew bundle --file=packages/Brewfile
```

This installs all tools in one step: `git`, `stow`, `go-task`, `fzf`, `zoxide`, `eza`, `bat`, and `oh-my-posh`.

### Step 3: Install zinit

`zinit` is not in the Brewfile — it is installed via a one-time manual `git clone`:

⚠️  MANUAL STEP — review before running

```bash
git clone https://github.com/zdharma-continuum/zinit.git \
  "${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
```

This clones zinit into `~/.local/share/zinit/zinit.git`. The zsh config detects it on the next shell start.

### Step 4: Verify

```bash
task deps:check:zsh
```

All lines should show `PASS`. If any tool shows `FAIL`, follow the install hint printed on that line.

---

## Arch / EndeavourOS

### Step 1: Install pacman packages

⚠️  MANUAL STEP — review before running

```bash
sudo pacman -S git stow go-task fzf zoxide eza bat
```

### Step 2: Install AUR packages

`oh-my-posh` is only available via the AUR. Requires `yay` or `paru`:

⚠️  MANUAL STEP — review before running

```bash
yay -S oh-my-posh-bin
```

Skip this step if you do not want the Oh My Posh shell prompt — `prompt.zsh` is a no-op when `oh-my-posh` is absent.

### Step 2b: Install the Neovim tier (optional)

Only needed if you stow the `nvim` package. `base-devel` provides the C compiler and
`tree-sitter-cli` the parser builder — without the latter, nvim-treesitter parser
builds fail with `ENOENT ... (cmd): 'tree-sitter'`. See `stow/common/nvim/README.md`
for the full dependency rationale.

⚠️  MANUAL STEP — review before running

```bash
sudo pacman -S neovim ripgrep fd nodejs npm python python-pipx base-devel tree-sitter-cli
```

### Step 3: Install zinit

⚠️  MANUAL STEP — review before running

```bash
git clone https://github.com/zdharma-continuum/zinit.git \
  "${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
```

### Step 4: Verify

```bash
task deps:check:zsh
```

All lines should show `PASS`. If you installed the Neovim tier, also run:

```bash
task deps:check:nvim
```

---

## Selective install (any platform)

If you want only specific tools rather than everything, install them individually:

```bash
# macOS — individual tools
brew install eza
brew install fzf
brew install zoxide
brew install bat
brew install jandedobbeleer/oh-my-posh/oh-my-posh

# Arch — individual tools
sudo pacman -S eza
sudo pacman -S fzf
sudo pacman -S zoxide
sudo pacman -S bat
yay -S oh-my-posh-bin
```

All optional tools are guarded in the zsh config — uninstalled tools are silently skipped.

---

## Taskfile shortcuts

| Task | What it does |
|---|---|
| `task deps:brew` | Print the macOS install commands (does not run them) |
| `task deps:arch` | Print the Arch install commands (does not run them) |
| `task deps:check:zsh` | Check which shell tools are installed vs missing |
| `task deps:check:nvim` | Check which Neovim-tier tools are installed vs missing |

---

## Package files reference

| File | Platform | Format |
|---|---|---|
| `packages/Brewfile` | macOS / Linux (Homebrew) | `brew bundle` format |
| `packages/arch/packages.txt` | Arch / EndeavourOS | Annotated reference — read and run manually |

Neither file is executed automatically. All installs are manual.
