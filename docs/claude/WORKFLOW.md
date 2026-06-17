# Workflow

This document describes the standard workflow for all significant work in this repository.

## Canonical delivery sequence

```
PRD → Architecture → Review → Plan → Review → Build → Review → Commit
```

Every significant change follows this sequence. No phase is skipped.

## Overview

```
1. Discuss need
      ↓
2. Create or update PRD
      ↓
3. Create or update architecture
      ↓
4. Review (PRD + architecture)
      ↓
5. Create plan
      ↓
6. Review (plan)
      ↓
7. Implement
      ↓
8. Review (implementation)
      ↓
9. Commit
      ↓
10. Iterate
```

## Steps

### 1. Discuss need

Start by discussing the goal with Claude. Clarify:

- What problem needs solving?
- What platform(s) are affected?
- What is explicitly out of scope?

Do not jump to implementation.

### 2. Create or update PRD

Use the `create-prd` skill to produce a formal PRD under `docs/prd/`.

The PRD defines goals, non-goals, scope, safety requirements, and acceptance criteria.

**No significant work starts without an approved PRD.**

### 3. Create or update architecture

Use the Architect agent or `create-architecture` skill to produce an architecture document under `docs/architecture/`.

The architecture defines structure, decisions, tradeoffs, and risks.

**No plan is created without an approved architecture when the change is structural.**

### 4. Review (PRD + architecture)

Use the Reviewer agent or `review-change` skill to validate the PRD and architecture before planning begins.

The Reviewer checks safety, privacy, scope, and cross-platform correctness.

**No plan is created until the PRD and architecture pass review.**

### 5. Create plan

Use the Planner agent or `create-plan` skill to produce an implementation plan under `docs/plans/`.

The plan defines ordered tasks, affected files, safety checks, validation commands, and rollback strategy.

**Builder must not start without an approved plan.**

### 6. Review (plan)

Use the Reviewer agent to validate the plan before implementation begins.

The Reviewer checks that tasks are safe, ordered correctly, and include validation and rollback steps.

**Builder must not start until the plan passes review.**

### 7. Implement

Use the Builder agent to implement the approved plan items only.

The Builder makes minimal, focused changes and reports what was done, what was skipped, and what is next.

**Builder must not change the Plan status.** Builder's output ends at "Next Steps".

### 8. Review (implementation)

Use the Reviewer agent or `review-change` skill to validate all changes.

The Reviewer checks safety, privacy, cross-platform correctness, and documentation quality.

**Commit only after the Reviewer issues PASS on all three verdicts.**

After all verdicts pass, the Reviewer must:

1. Update the plan file: change `**Status:** Approved` to `**Status:** Complete`.
2. Name the completed Plan in the review report Summary (e.g., "Plan 0007 — Implement Zsh Configuration Foundation").

### 9. Commit

After Reviewer approval:

- Run `git diff --staged` to confirm what will be committed.
- Verify no secrets are staged.
- Write a commit message that explains intent, not just what changed.
- Commit.

### 10. Iterate

After a commit, return to step 1 for the next item.

## Document lifecycle

Valid statuses, transition rules, and responsibilities for all document types are defined in `docs/claude/DOCUMENT-LIFECYCLE.md`.

## Current repository status

The dotfiles implementation must **not start** until:

1. The Claude Code operating layer is created (done).
2. The operating layer is reviewed by the Reviewer agent.
3. The user confirms readiness to begin dotfiles implementation.

Do not skip this gate.
