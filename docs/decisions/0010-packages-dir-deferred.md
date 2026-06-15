# Decision: `packages/` Directory Deferred Until Brewfile Scope Approved

**Number:** 0010
**Date:** 2026-06-15
**Status:** Accepted

## Context

Architecture 0001 reserves `packages/macos/` for split Brewfiles (ADR-0007). The question arose whether to pre-create this directory in the foundation phase to reserve the slot and signal intent.

Reference: Architecture 0002 Decision 2.

## Decision

`packages/macos/` is **not created** in the foundation phase.

The directory is created only when a Brewfile PRD is written, reviewed, and approved.

## Consequences

- No empty `packages/macos/` directory exists to invite accidental Brewfile commits before a PRD defines the scope.
- Each top-level directory in the repository is created only when it has authorized content behind a PRD.
- When Homebrew management is scoped, a PRD lifts this deferral and the directory is created as part of that plan.
- Trade-off accepted: minor — the directory must be created later, but this is trivial and controlled.
