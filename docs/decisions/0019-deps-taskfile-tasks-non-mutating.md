# Decision: `deps:` Taskfile Tasks Are Non-Mutating (Check and Print Only)

**Number:** 0019
**Date:** 2026-06-17
**Status:** Accepted
**PRD:** 0006-shell-dependencies
**Architecture:** 0006-shell-dependencies-architecture

## Context

ADR-0009 establishes that the foundation-phase Taskfile contains only read-only and
`--simulate` tasks. Adding a mutating task (one that installs, removes, or modifies
the system) requires a new PRD that explicitly lifts this restriction.

PRD 0006 introduces two new Taskfile tasks in the `deps:` namespace:
`deps:check:zsh` and `deps:macos:shell`. The question is whether either task should
execute `brew bundle` to perform an actual install.

## Decision

Both `deps:` tasks are **non-mutating**:

- `deps:check:zsh` runs `scripts/check-zsh-deps.sh` — read-only, reports tool
  presence/absence, exits non-zero if any required tool is missing.
- `deps:macos:shell` **prints** the `brew bundle` and `git clone` commands with
  `⚠️  MANUAL STEP` markers and exits. It does not execute them.

PRD 0006 operates entirely within ADR-0009's mutation ban — it does not lift it.

If a genuinely executing install task is needed in future, that requires a separate
PRD and a separate ADR explicitly lifting the mutation restriction.

## Consequences

- No Taskfile task can install packages or clone repositories.
- The user always sees and approves the exact install command before running it.
- The Check/Install/Activate split (Architecture 0006) is preserved in the Taskfile
  interface: tasks stay on the Check side of the line.
- ADR-0009's safety boundary is unchanged and remains the default.
