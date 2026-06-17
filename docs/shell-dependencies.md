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

---

## Dependency tiers

| Tool | Tier | macOS source | Arch source |
|---|---|---|---|
| `git` | core | `Brewfile.core` | `pacman` |
| `stow` | core | `Brewfile.core` | `pacman` |
| `go-task` | core | `Brewfile.core` (tap) | AUR (`go-task` or `task-bin`) |
| `fzf` | shell | `Brewfile.shell` | `pacman` |
| `zoxide` | shell | `Brewfile.shell` | `pacman` |
| `eza` | shell | `Brewfile.shell` | `pacman` |
| `oh-my-posh` | shell | `Brewfile.shell` (tap) | AUR (`oh-my-posh-bin`) |
| `zinit` | shell | manual git clone (see below) | manual git clone / AUR |

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

### Homebrew-managed shell tools

Install `fzf`, `zoxide`, `eza`, and `oh-my-posh` via Homebrew:

⚠️  MANUAL STEP — review before running
```bash
brew bundle --file=packages/macos/Brewfile.shell
```

To see what would be installed first (read-only):

```bash
brew bundle list --file=packages/macos/Brewfile.shell
```

### Core prerequisites (if not already installed)

⚠️  MANUAL STEP — review before running
```bash
brew bundle --file=packages/macos/Brewfile.core
```

### zinit (manual one-time clone)

`zinit` is not in any Brewfile. Install it once per machine with a manual `git clone`:

⚠️  MANUAL STEP — review before running
```bash
git clone https://github.com/zdharma-continuum/zinit.git \
  "${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
```

The zsh config sources zinit via a directory-existence guard — it never auto-clones. If zinit is absent, the shell starts cleanly without it.

---

## Step 2 — Install (Arch / EndeavourOS)

Arch support is **planned but not yet implemented**. A future PRD will define the package list and install steps using `pacman` and `paru`/`yay` (for AUR tools such as `oh-my-posh-bin`).

Until then, install tools manually using the Arch package manager appropriate for each tool. Run `task deps:check:zsh` to confirm what is missing.

---

## Step 3 — Verify

After installing, re-run the checker to confirm all tools are present:

```bash
task deps:check:zsh
```

All lines should show `PASS`. Exit code 0 means all required shell-tier tools are installed.

---

## Cleanup (macOS)

To preview which installed packages are not listed in a Brewfile (dry-run only — removes nothing):

```bash
brew bundle cleanup --dry-run --file=packages/macos/Brewfile.shell
```

Do not run `brew bundle cleanup` without `--dry-run` — it removes packages immediately.

---

## Optional extras

`packages/macos/Brewfile.optional` is a placeholder for tools that are useful but not required for a working shell. It is currently empty. Add entries as needed and install with:

⚠️  MANUAL STEP — review before running
```bash
brew bundle --file=packages/macos/Brewfile.optional
```

---

## Taskfile reference

| Task | What it does |
|---|---|
| `task check` | Check core prerequisites (`git`, `stow`, `task`) |
| `task deps:check:zsh` | Check shell-tier tools (`fzf`, `zoxide`, `eza`, `oh-my-posh`, `zinit`) |
| `task deps:macos:shell` | Print the manual install commands for macOS shell tools |

None of these tasks install anything. They check and report, or print instructions.
