# Decision: `git:bootstrap` and `git:bootstrap:dry-run` as First Mutating Taskfile Tasks

**Number:** 0032
**Date:** 2026-06-18
**Status:** Accepted
**Supersedes:** N/A (lifts the ADR-0009 restriction for this specific, bounded case)
**Related:** ADR-0002, ADR-0009, ADR-0025, Architecture-0009

## Context

ADR-0009 restricted the foundation-phase Taskfile to read-only tasks, stating:
"Adding a mutating task in a future phase requires a new PRD that explicitly lifts
this restriction."

PRD-0009 defines Git configuration adoption. After Stow links managed Git files into
`~/.config/git/`, the user's `~/.gitconfig` must be wired with two `[include] path = ...`
entries pointing to those files. Without a task for this, the wiring is a manual,
error-prone multi-step operation that is hard to make idempotent.

## Decision

Add two tasks to `Taskfile.yml`:

- `git:bootstrap:dry-run` — shows current `include.path` state and what would be added.
  Never modifies any file.
- `git:bootstrap` — adds missing `include.path` entries to `~/.gitconfig` using
  `git config --global --add`. Idempotent via check-before-add. Creates a timestamped
  backup before modifying an existing file.

**Safety invariants (all must hold):**

- Never overwrites `~/.gitconfig` — uses `--add` to append only.
- Timestamped backup (`~/.gitconfig.bak.YYYYMMDDHHMMSS`) created before any write.
- Idempotent: checks `git config --global --get-all include.path | grep -qxF <value>`
  before each `--add`. A second run produces only "skip (already present)" lines.
- Never touches `user.name`, `user.email`, signing keys, credentials, or existing
  `include.path` entries.
- Never removes existing `include.path` entries.
- Never called by another task, never triggered automatically.

**ADR-0009 scope lift:** This decision explicitly authorizes the first mutating Taskfile
tasks under these conditions. The conditions are: user-invoked only, idempotent,
backup-creating, scoped to `[include]` entries only, and never automatic. These
conditions must hold for any future mutating Taskfile task added in this repository.

## Consequences

- Users run `task git:bootstrap:dry-run` first to preview, then `task git:bootstrap`.
- The backup provides a guaranteed rollback path.
- Running `git:bootstrap` twice is safe — no duplicates, no errors.
- The Taskfile now contains one mutating task. The mutating-task boundary is explicit
  and documented. ADR-0009's safety default remains; this ADR records the exception.
- Trade-off accepted: the convenience of idempotent, auditable wiring outweighs the
  added complexity of a mutating task.
