# Plans

This directory stores implementation plans for this dotfiles repository.

## Purpose

Implementation plans define the **ordered, safe, reviewable steps** that the Builder follows.

A plan must include:

- **Objective** — what this plan achieves.
- **Assumptions** — what must be true before starting.
- **Ordered tasks** — specific, actionable, individually verifiable steps.
- **Files affected** — every file to be created, modified, or deleted.
- **Safety checks** — conditions to verify before and during execution.
- **Validation commands** — safe read-only commands to verify each task.
- **Rollback strategy** — how to undo if something goes wrong.
- **Completion criteria** — explicit, verifiable conditions that define "done".

## Naming convention

Use numbered filenames in sequence:

```
0001-bootstrap-claude-operating-layer.md
0002-add-zsh-common-package.md
0003-add-nvim-common-package.md
```

## Workflow

1. Read the related PRD and architecture document.
2. Use the Planner agent or `create-plan` skill to produce a plan.
3. Review and approve the plan before Builder starts.
4. Reference the plan number in review reports.

## Rules

- Plans must be **approved by the user** before Builder begins implementation.
- Builder implements **only** the approved plan — no improvisation.
- Plans must be updated if scope changes mid-implementation.

## Status values

- **Draft** — in progress, not yet approved.
- **Approved** — approved by the user, ready for Builder.
- **In Progress** — Builder is currently implementing.
- **Done** — all tasks completed and reviewed.

---

## Index

| Number | Title | Status |
|---|---|---|
| [0001](0001-initial-repository-scaffold.md) | Initial repository scaffold | Done |
| [0002](0002-root-project-hygiene-files.md) | Root project hygiene files | Done |
| [0003](0003-add-initial-prd.md) | Add initial PRD | Done |
| [0004](0004-add-github-actions-ci.md) | Add GitHub Actions CI | Done |
| [0005](0005-implement-dotfiles-foundation.md) | Implement dotfiles foundation | Done |
| [0006](0006-implement-git-package.md) | Implement Git package | Done |
| [0007](0007-implement-zsh-configuration-foundation.md) | Implement Zsh configuration foundation | Approved |
