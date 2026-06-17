# Decision: Zsh Migration Starts at Model 4 (`.zshrc.example`) and Targets Model 3 (Guarded Include Block)

**Number:** 0022
**Date:** 2026-06-17
**Status:** Accepted
**PRD:** 0007-zsh-activation-migration
**Architecture:** 0007-zsh-activation-migration-architecture

## Context

The user has a working, hand-tuned `~/.zshrc` (Homebrew, Zinit, Oh My Posh, fzf, zoxide,
eza, aliases, history, completions, local overrides) on macOS (primary). An abrupt
replacement of that file is unacceptable. PRD 0007 evaluated four activation models:

1. User-managed `~/.zshrc` sourcing managed files via scattered manual `source` lines.
2. A tiny **managed/stowed** `~/.zshrc` that sources `~/.config/zsh/*.zsh`.
3. An **unmanaged** `~/.zshrc` with **one** guarded managed include block.
4. A `.zshrc.example` reference only, until manual migration.

## Decision

- **Start state — Model 4.** Ship `zshrc.example` as a reference template. Nothing is
  wired into any startup file. Zero risk to the working shell while the managed layer is
  still being proven.
- **Target state — Model 3.** The user keeps an unmanaged `~/.zshrc` and adds one
  guarded, delimited managed include block sourcing `~/.config/zsh/index.zsh` (ADR-0021).
- **Model 2 is rejected for migration.** A stowed/replaced `~/.zshrc` requires the exact
  abrupt cutover the user forbids and conflicts on stow. It is **deferred** to a possible
  future, separate PRD scoped to **fresh-machine provisioning only** (machines with no
  existing `~/.zshrc`).
- **Model 1 is superseded by Model 3.** Scattered manual `source` lines are collapsed
  into one block + one `index.zsh` orchestrator — same safety, less maintenance.

Migration is incremental: `index.zsh` starts minimal and the user moves one capability at
a time (history → completions → aliases → tool integrations → prompt), verifying after
each, and relocates machine-specific lines into `local.zsh` (ADR-0023). The include block
goes **last** in `~/.zshrc` so managed defaults and `local.zsh` take effect after the
user's own lines.

## Consequences

- The working shell is never broken; the cutover is reversible at every step (delete the
  block to revert; restore from a pre-adoption `~/.zshrc` backup to fully abort).
- A `zshrc.example` exists as the Model 4 artifact and the seed for any future
  fresh-machine Model 2 work — a clean seam without committing to Model 2 now.
- New-machine reproducibility via the block is documented, not stowed — accepted
  trade-off consistent with ADR-0013 / ADR-0016.
