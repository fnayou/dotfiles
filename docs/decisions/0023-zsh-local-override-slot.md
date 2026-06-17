# Decision: `local.zsh` Is the Git-Ignored, Last-Sourced Zsh Override Slot

**Number:** 0023
**Date:** 2026-06-17
**Status:** Accepted
**PRD:** 0007-zsh-activation-migration
**Architecture:** 0007-zsh-activation-migration-architecture

## Context

Architecture 0004 left a `local.zsh` slot as an open question. Migration makes it
necessary: the user's real `~/.zshrc` contains machine-specific and potentially sensitive
"local override" lines. Those must have a home that is **never committed** and that
**wins** over managed defaults.

## Decision

`local.zsh` is the machine-specific override slot:

- Sourced **last** by `index.zsh` (after `shared.zsh`, the platform file, and `omp.zsh`),
  only if present:

  ```zsh
  [[ -r "$HOME/.config/zsh/local.zsh" ]] && source "$HOME/.config/zsh/local.zsh"
  ```

- **Git-ignored** via `stow/common/zsh/.config/zsh/.gitignore`. It has **no** `.example`
  template and is **never tracked** — it is the designated home for secrets and
  machine-specific values (AGENTS §9, privacy).
- It is the migration target for the user's existing local-override section: those lines
  move from `~/.zshrc` into `local.zsh`.

**Scope of "wins".** `local.zsh` wins **among managed layers** because `index.zsh` sources
it last. For it to win end-to-end over the user's own `~/.zshrc` lines, the managed
include block (ADR-0021) must be placed **last** in `~/.zshrc`. The migration runbook
(`docs/zsh-migration.md`) states this explicitly (Review 0021, non-blocking #2).

## Consequences

- Machine-specific/sensitive config has an untracked, always-last home — no secret is
  ever committed by design.
- `index.zsh` sources `local.zsh` only if it exists, so machines without overrides start
  a clean shell.
- Resolves the Architecture 0004 open question about a `local.zsh` slot.
