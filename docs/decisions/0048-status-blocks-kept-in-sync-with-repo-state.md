# Decision: Status Blocks in `AGENTS.md` and `CLAUDE.md` Kept in Sync With Repo State

**Number:** 0048
**Date:** 2026-06-21
**Status:** Accepted

## Context

`AGENTS.md` (§1–2) and `CLAUDE.md` both carry a hand-written "current status" block
describing implementation progress and the set of Stow packages. These blocks are prose
mirrors of facts that actually live in git and in `stow/`.

They drifted. While packages `alacritty`, `git`, `herdr`, `omp`, and `zsh` landed across
multiple `feat(...)` commits, the status blocks still claimed "dotfiles implementation not
started" and "packages exist as `.example` files only". The process sections (agent roles,
rules) stayed correct because they describe workflow, not state — only the
state-describing blocks rotted.

Conversation history is not a substitute for written documentation, and stale
documentation is worse than none: a new session reads the status block first and starts
from a false premise.

## Decision

The status blocks in `AGENTS.md` and `CLAUDE.md` are treated as **tracked state** that
must match reality:

1. Whenever a Stow package is added, removed, or first stowed to `$HOME`, update **both**
   status blocks in the **same commit** as the change.
2. The blocks describe **prose state only** (implementation phase, stowed-vs-not). The
   per-package list is a pointer to `stow/common/` (and `stow/macos/`, `stow/arch/` once
   populated) rather than a hand-maintained enumeration — the directory is the source of
   truth.
3. This obligation is enforced operationally by the rule
   `.claude/rules/status-sync.md`, which every agent session loads.

A pre-commit hook that diffs the package list against `stow/*/` was considered and
deferred — markdown-block parsing is brittle, and pointing at the directory (decision 2)
removes most of what a hook would check.

## Consequences

- New-session agents can trust the status blocks again.
- Adding or stowing a package now carries a small, explicit doc-update obligation, paid in
  the same commit.
- The package list stops drifting because it is no longer enumerated by hand — `stow/`
  is the single source of truth.
- If drift recurs despite the rule, escalate to a pre-commit hook (the deferred option).
