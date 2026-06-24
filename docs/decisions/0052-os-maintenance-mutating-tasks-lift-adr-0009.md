# Decision: OS Maintenance Taskfile Tasks May Mutate (Lifts ADR-0009 Ban for This Feature)

**Number:** 0052
**Date:** 2026-06-24
**Status:** Accepted
**PRD:** 0018-os-maintenance
**Architecture:** 0018-os-maintenance-architecture
**Relates to:** 0009 (foundation Taskfile non-mutating), 0019 (deps tasks non-mutating),
0032 (git bootstrap mutating tasks), 0043 (zsh bootstrap mutating tasks)

## Context

ADR-0009 establishes that the Taskfile contains only read-only / `--simulate` tasks, and ADR-0019
restates that adding a mutating task requires a separate PRD that explicitly lifts the restriction
plus a separate ADR. The mutation ban has since been lifted per-feature for the bootstrap tasks
(ADR-0032 `git:bootstrap`, ADR-0043 `zsh:bootstrap`), each marked "MANUAL USE ONLY".

PRD 0018 introduces `update` and `clean:apply` tasks that execute privileged, destructive system
maintenance (`sudo pacman -Syu`, `sudo pacman -Rns`, `paccache -r`, `journalctl --vacuum`,
`brew cleanup`). These are mutating and therefore require an explicit lift.

## Decision

The mutation ban (ADR-0009) is explicitly lifted for the os-maintenance Taskfile tasks
(`update`, `clean:apply`), following the precedent of ADR-0032 and ADR-0043. Conditions:

- Both tasks are labelled **MANUAL USE ONLY** in their descriptions — never run automatically,
  never on shell startup or a schedule.
- `clean` (without `:apply`) remains **non-mutating** (dry-run report only).
- `clean:apply` re-prints the dry-run report before performing any deletion.
- The destructive logic lives in `scripts/os-maintenance.sh` with all privileged commands
  explicit and visible; the tasks are thin wrappers.

The ban remains the default for every other task. This lift applies only to the two named tasks.

## Consequences

- `task update` and `task clean:apply` execute system changes — consistent with the bootstrap
  precedent, bounded by the MANUAL USE ONLY contract and the dry-run-first safety design.
- A future mutating task still requires its own explicit lift; this ADR does not generalise.
- PRD 0018 records the lift so the authorisation is traceable from the requirements, per ADR-0019.
