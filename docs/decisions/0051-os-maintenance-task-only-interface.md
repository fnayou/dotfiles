# Decision: OS Maintenance Exposed via `task` Only; Zsh Wrapper Deferred

**Number:** 0051
**Date:** 2026-06-24
**Status:** Accepted
**PRD:** 0018-os-maintenance
**Architecture:** 0018-os-maintenance-architecture

## Context

The maintenance helper needs a user-facing entry point. Two candidates: expose it through the
existing `task` runner (as `detect`, `check`, `deps:*` already are), or add a per-OS zsh
function/alias in `arch.zsh` / `macos.zsh`. A zsh wrapper would have to call the script by an
absolute path, but the zsh layers have no stable `$DOTFILES` anchor, and hardcoding
`~/work/dotfiles` violates the "no machine-specific paths" rule (§10).

## Decision

For this milestone the canonical interface is `task` (`task update`, `task clean`,
`task clean:apply`). No zsh alias or function is added. A guarded per-OS zsh wrapper is deferred
until a `$DOTFILES` anchor is introduced as a separate change. Existing aliases (`pacu`, `pacs`,
`paci`, `aur`) are untouched.

## Consequences

- No coupling between an interactive shell and the repo's on-disk location.
- The helper is run from a repo checkout, consistent with the other `task` targets.
- A zsh wrapper drops in additively once `$DOTFILES` exists — no redesign.
- The existing pacman/AUR aliases keep working unchanged; no name collisions (`pacu` ≠ `update`).
