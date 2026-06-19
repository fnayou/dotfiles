# Shell Dependencies

This document covers **tool installation** for the managed zsh configuration. It is separate from `docs/stow-usage.md`, which covers Stow symlink management.

---

## Overview

The managed zsh configuration depends on a set of external tools. These tools must be installed **before** stowing the zsh package or sourcing the managed config files.

Three concerns are kept strictly separate:

| Concern | What it means | How |
|---|---|---|
| **Check** | Detect which tools are present or missing | `task deps:check:zsh` |
| **Install** | Place tools on the system | Manual — see steps below |
| **Activate** | Wire tools into the shell | Happens when zsh package is stowed and sourced |

Nothing in this repository installs tools automatically. Shell startup never runs `brew`, `pacman`, or `git clone`.

For a step-by-step installation guide see: `docs/guides/packages-setup.md`

---

## Dependency tiers

| Tool | Tier | macOS source | Arch source |
|---|---|---|---|
| `git` | core | `packages/Brewfile` | `pacman` |
| `stow` | core | `packages/Brewfile` | `pacman` |
| `go-task` | core | `packages/Brewfile` (tap) | `pacman` |
| `fzf` | shell | `packages/Brewfile` | `pacman` |
| `zoxide` | shell | `packages/Brewfile` | `pacman` |
| `eza` | shell | `packages/Brewfile` | `pacman` |
| `bat` | shell | `packages/Brewfile` | `pacman` |
| `oh-my-posh` | shell | `packages/Brewfile` (tap) | AUR (`oh-my-posh-bin`) |
| `zinit` | shell | manual git clone (see below) | manual git clone |

Core tooling (`git`, `stow`, `go-task`) is checked by `scripts/check.sh`. Shell tooling is checked by `scripts/check-zsh-deps.sh`.

---

## Step 1 — Check what is missing

```bash
task deps:check:zsh
```

Or directly:

```bash
bash scripts/check-zsh-deps.sh
```

Output is `PASS: <tool>` or `FAIL: <tool> (not installed)` per tool, with an install hint on failure. Exit code is non-zero if any required tool is missing.

---

## Step 2 — Install (macOS)

### All tools via Brewfile

⚠️  MANUAL STEP — review before running

```bash
brew bundle --file=packages/Brewfile
```

To preview what would be installed (read-only):

```bash
brew bundle list --file=packages/Brewfile
```

### zinit (manual one-time clone)

`zinit` is not in the Brewfile. Install it once per machine:

⚠️  MANUAL STEP — review before running

```bash
git clone https://github.com/zdharma-continuum/zinit.git \
  "${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
```

The zsh config sources zinit via a directory-existence guard — it never auto-clones. If zinit is absent, the shell shows an error and skips the plugin block.

---

## Step 2 — Install (Arch / EndeavourOS)

### Pacman packages

⚠️  MANUAL STEP — review before running

```bash
sudo pacman -S git stow go-task fzf zoxide eza bat
```

### AUR packages (requires yay or paru)

⚠️  MANUAL STEP — review before running

```bash
yay -S oh-my-posh-bin
```

### zinit (manual one-time clone)

Same as macOS:

⚠️  MANUAL STEP — review before running

```bash
git clone https://github.com/zdharma-continuum/zinit.git \
  "${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
```

See `packages/arch/packages.txt` for a full annotated package list.

---

## Step 3 — Verify

After installing, re-run the checker to confirm all tools are present:

```bash
task deps:check:zsh
```

All lines should show `PASS`. Exit code 0 means all required shell-tier tools are installed.

---

## Cleanup (macOS)

To preview which installed packages are not listed in the Brewfile (dry-run only — removes nothing):

```bash
brew bundle cleanup --dry-run --file=packages/Brewfile
```

Do not run `brew bundle cleanup` without `--dry-run` — it removes packages immediately.

---

## Taskfile reference

| Task | What it does |
|---|---|
| `task check` | Check core prerequisites (`git`, `stow`, `task`) |
| `task deps:check:zsh` | Check shell-tier tools (`fzf`, `zoxide`, `eza`, `bat`, `oh-my-posh`, `zinit`) |
| `task deps:brew` | Print manual install commands for macOS / Homebrew |
| `task deps:arch` | Print manual install commands for Arch / EndeavourOS |

None of these tasks install anything. They check and report, or print instructions.
