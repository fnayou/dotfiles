# Decision: Foundation-Phase Taskfile Excludes Install and Mutating Tasks

**Number:** 0009
**Date:** 2026-06-15
**Status:** Accepted

## Context

The dotfiles foundation phase (PRD 0002) establishes the repository structure, placeholder packages, helper scripts, and Stow usage documentation. No real dotfiles are stowed in this phase. A Taskfile is required as a unified, discoverable entry point for safe operations.

The question arose: should `task install` and `task uninstall` (Stow install/uninstall operations) be included in the foundation Taskfile for completeness, with documentation warning against premature use?

Reference: Architecture 0002 Decision 1.

## Decision

The foundation-phase `Taskfile.yml` contains **only read-only and `--simulate` tasks**:

- `detect` — print detected OS
- `check` — verify prerequisites
- `list` — list available Stow packages
- `dry-run` — run `stow --simulate` for a named package

Install, uninstall, adopt, and any task that mutates `$HOME` are **explicitly absent**.

Adding a mutating task in a future phase requires a new PRD that explicitly lifts this restriction.

## Consequences

- No Taskfile task can modify `$HOME` — the risk of an accidental `task install` is zero.
- Install operations remain entirely manual: the user must construct and run the stow command directly, guided by `docs/stow-usage.md`.
- When a future PRD scopes install tasks, they are added deliberately and reviewed before implementation.
- Trade-off accepted: slightly less convenience (no `task install` shortcut) in exchange for a hard safety boundary during the foundation phase.
