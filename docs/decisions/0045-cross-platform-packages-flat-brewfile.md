# Decision: Cross-Platform Packages — Single Brewfile and Arch Package List

**Number:** 0045
**Date:** 2026-06-19
**Status:** Accepted
**Supersedes:** 0007, 0018

## Context

ADR-0007 established a split-Brewfiles-by-category layout under `packages/macos/`.
ADR-0018 defined the category set as open and per-PRD.

In practice, the total tool count remained small (8 tools) and every tool is available
on both macOS (via Homebrew) and Arch / EndeavourOS (via pacman or AUR). The split into
three category Brewfiles added overhead without value at this scale:

- `Brewfile.core` and `Brewfile.shell` together had 8 entries.
- `Brewfile.optional` was empty and had been empty since creation.
- The `packages/macos/` subdirectory name implied macOS-only tools, which was incorrect
  — all tools are cross-platform.
- `bat` was missing from all Brewfiles despite being actively used in `aliases.zsh`
  suffix aliases.

No Arch package list existed, leaving Arch / EndeavourOS users with no package reference.

## Decision

Replace the three split Brewfiles with a **single `packages/Brewfile`** and add
**`packages/arch/packages.txt`** as the Arch / EndeavourOS equivalent.

New structure:

```
packages/
├── Brewfile              # All tools — brew (macOS + Linux with Homebrew)
└── arch/
    └── packages.txt      # All tools — pacman + AUR (Arch / EndeavourOS)
```

The `packages/macos/` subdirectory is removed entirely. `bat` is added to both files.

Install on macOS or Linux (Homebrew):

```bash
brew bundle --file=packages/Brewfile
```

Install on Arch / EndeavourOS (pacman + AUR):

```bash
sudo pacman -S git stow go-task fzf zoxide eza bat
yay -S oh-my-posh-bin
```

If the total tool count grows large enough to warrant splitting (e.g. adding GUI casks,
language toolchains, or macOS-specific tools), a `packages/macos/` subdirectory may be
reintroduced at that time. The current scale does not justify it.

## Consequences

- One `brew bundle` command installs everything — no per-category targeting needed.
- Both macOS and Arch have a package reference under `packages/`.
- `bat` is now tracked in all package lists (was missing before).
- `packages/macos/` directory and its three Brewfiles are deleted.
- ADR-0007's split-by-category principle is retired at current scale.
- ADR-0018's per-PRD category gate is retired; tool additions require only a PR.
- `Taskfile.yml` task `deps:macos:shell` is renamed to `deps:brew`; `deps:arch` is added.
- `scripts/check-zsh-deps.sh` now checks `bat` in addition to prior tools.
