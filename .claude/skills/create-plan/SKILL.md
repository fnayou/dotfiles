# Skill: create-plan

Produces a numbered implementation plan under `docs/plans/`.

## When to use

- An architecture has been approved and the user is ready to begin implementation.
- A PRD is approved and the Architect has produced a design.
- A specific, well-scoped task needs to be broken into safe steps.

## Process

### Step 1 — Read the PRD

Locate and read the relevant PRD under `docs/prd/`. Confirm goals, non-goals, safety requirements, and acceptance criteria.

### Step 2 — Read the architecture

Locate and read the relevant architecture document under `docs/architecture/`. Confirm layout, decisions, and risks.

### Step 3 — Create ordered tasks

Break the implementation into the **smallest safe, individually verifiable steps**.

Each task must:

- Be specific and actionable.
- Produce a visible, verifiable result.
- Be safe to stop after if needed.

Do not group multiple distinct changes into one task.

### Step 4 — Identify files affected

For each task, list:

- Files to be created.
- Files to be modified.
- Files to be deleted (flag these — requires safety review).

### Step 5 — Identify commands needed

List any commands that will be run. Flag dangerous commands explicitly.

### Step 6 — Identify validation steps

For each task, specify a safe read-only command or check to verify it completed correctly.

Example:

```bash
git status   # Verify only expected files are changed
ls -la stow/common/zsh/   # Verify directory structure is correct
```

### Step 7 — Identify rollback strategy

State how to undo the plan if something goes wrong. Prefer git-based rollback:

```bash
git checkout -- <file>    # Undo a specific file change
git reset HEAD~1          # Undo the last commit (before push)
```

### Step 8 — Do not implement

This skill produces a **plan only**. The Builder implements. Do not create or modify dotfile packages or home directory files.

### Step 9 — Produce the plan document

Write the plan to a numbered file:

```
docs/plans/0001-bootstrap-claude-operating-layer.md
docs/plans/0002-add-zsh-common-package.md
```

Use the next available number in the sequence.

## Plan document template

```markdown
# Plan: [Title]

**Number:** 0001
**Status:** Draft | Approved | In Progress | Done
**Date:** YYYY-MM-DD
**PRD:** [number]
**Architecture:** [number]

## Objective

[One sentence: what this plan achieves]

## Assumptions

- [assumption]

## Ordered Tasks

1. [Task description]
2. [Task description]
3. [Task description]

## Files Affected

- path/to/file — created
- path/to/file — modified

## Safety Checks

- [check before starting]
- [check during execution]

## Validation Commands

```bash
git status
```

## Rollback Strategy

[How to undo if something goes wrong]

## Completion Criteria

- [ ] [verifiable condition]
- [ ] [verifiable condition]
```
