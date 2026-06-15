# PRDs

This directory stores Product Requirements Documents for this dotfiles repository.

## Purpose

PRDs define the **why and what** before any architecture or implementation begins.

A PRD must include:

- **Goals** — what this achieves.
- **Non-goals** — what is explicitly out of scope.
- **Scope** — what files, packages, or systems are affected.
- **Safety requirements** — constraints to prevent data loss or credential exposure.
- **Acceptance criteria** — explicit, verifiable conditions that define "done".

## Naming convention

Use numbered filenames in sequence:

```
0001-dotfiles-foundation.md
0002-zsh-package.md
0003-nvim-package.md
```

## Workflow

1. Use the `create-prd` skill to produce a new PRD.
2. Review and approve the PRD before architecture begins.
3. Reference the PRD number in architecture documents and plans.

## Status values

Each PRD has a status:

- **Draft** — in progress, not yet approved.
- **Approved** — approved by the user, ready for architecture.
- **Superseded** — replaced by a newer PRD.
