# Plan: Add Initial PRD for Claude Operating Layer

**Number:** 0003
**Status:** Approved
**Date:** 2026-06-15
**PRD:** self-referential — this plan produces PRD 0001
**Architecture:** docs/architecture/0001-dotfiles-repository-architecture.md

## Objective

Create `docs/prd/0001-claude-operating-layer.md` — a retrospective PRD documenting the scope and intent of the Claude Code operating layer already in place.

## Assumptions

- `docs/prd/` directory exists and contains no PRD files yet.
- The Claude Code operating layer (AGENTS.md, agents, rules, skills, docs/) is already implemented.
- Root hygiene files (.editorconfig, .gitignore, README.md, LICENSE) are already in place.
- This task is documentation-only — no implementation, no Stow, no $HOME changes.

## Ordered Tasks

1. Create `docs/prd/0001-claude-operating-layer.md` with status Approved, covering context, problem statement, goals, non-goals, scope, safety requirements, privacy requirements, cross-platform considerations, acceptance criteria, out-of-scope items, and related documents.

## Files Affected

- `docs/prd/0001-claude-operating-layer.md` — created

## Safety Checks

- Verify the file is created inside the repository only.
- Verify no real credentials, hostnames, emails, or sensitive data appear in the PRD.
- Verify no `stow`, `rm`, `mv`, or `ln -s` against `$HOME` is run.

## Validation Commands

```bash
ls docs/prd/
git status
git diff --staged
```

## Rollback Strategy

Single new file — remove with:

```bash
git clean -n          # dry run
git clean -f docs/prd/0001-claude-operating-layer.md
```

## Completion Criteria

- [ ] `docs/prd/0001-claude-operating-layer.md` exists.
- [ ] PRD status is Approved.
- [ ] PRD includes all required sections.
- [ ] No sensitive data in the file.
- [ ] `git status` shows only this file added.
