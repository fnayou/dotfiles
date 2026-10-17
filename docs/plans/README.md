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
2. Confirm the PRD and architecture have explicit user approval.
3. Use the Planner agent or `create-plan` skill to produce a Draft plan.
4. Review the plan.
5. Stop and wait for explicit user approval before Builder starts.
6. Reference the plan number in review reports.

## Rules

- Plans must be **approved by the user** before Builder begins implementation.
- Plan approval must be an explicit user response after the plan exists; it cannot be inferred from
  the original request.
- Builder implements **only** the approved plan — no improvisation.
- Plans must be updated if scope changes mid-implementation.

## Status values

- **Draft** — in progress, not yet approved.
- **Approved** — approved by the user, ready for Builder.
- **Complete** — all tasks completed and reviewed.
- **Superseded by: docs/plans/NNNN-title.md** — replaced by a newer plan.

These values mirror `docs/claude/DOCUMENT-LIFECYCLE.md`, which is the canonical lifecycle reference.

---

## Index

| Number | Title | Status |
|---|---|---|
| [0001](0001-initial-repository-scaffold.md) | Initial Repository Scaffold | Complete — implementation review [0002](../reviews/0002-pre-first-commit-review.md), no blocking issues |
| [0002](0002-root-project-hygiene-files.md) | Root Project Hygiene Files | Complete — implementation review [0002](../reviews/0002-pre-first-commit-review.md), no blocking issues |
| [0003](0003-add-initial-prd.md) | Add Initial PRD for Claude Operating Layer | Complete — implementation review [0002](../reviews/0002-pre-first-commit-review.md), no blocking issues |
| [0004](0004-add-github-actions-ci.md) | Add Minimal GitHub Actions CI | Complete — implementation review [0002](../reviews/0002-pre-first-commit-review.md), no blocking issues |
| [0005](0005-implement-dotfiles-foundation.md) | Implement Dotfiles Foundation | Complete |
| [0006](0006-implement-git-package.md) | Implement Git Configuration Stow Package | Complete |
| [0007](0007-implement-zsh-configuration-foundation.md) | Implement Zsh Configuration Foundation | Complete |
| [0008](0008-implement-oh-my-posh-support.md) | Implement Oh My Posh Support | Complete |
| [0009](0009-corrective-stow-conflict-and-fake-home-validation.md) | Corrective — Stow Directory Conflict and Fake-Home Validation | Complete |
| [0010](0010-zsh-omp-optional-integration.md) | Zsh — Reference Oh My Posh as Optional Integration | Complete |
| [0011](0011-implement-shell-dependencies.md) | Implement Shell Dependency Management | Complete |
| [0012](0012-implement-zsh-activation-migration.md) | Implement Zsh Activation & Migration (Model 4 → Model 3) | Complete |
| [0013](0013-implement-zsh-managed-layer-activation.md) | Implement Zsh Managed-Layer Activation (--no-folding) | Complete |
| [0014](0014-real-zsh-configuration-plan.md) | Real Zsh Configuration Adoption | Complete |
| [0015](0015-implement-alacritty-configuration.md) | Implement Alacritty Configuration Package | Complete |
| [0016](0016-implement-herdr-configuration.md) | Implement Herdr Configuration Package | Complete — implementation review [0057](../reviews/0057-herdr-configuration-implementation-review.md), no blocking issues. Two accepted divergences (`theme.name`, `[scrollback]`) are recorded there; the config block below is a historical record, not the current file. |
| [0017](0017-implement-bat-configuration.md) | Implement bat Configuration Package | Complete — implementation review [0042](../reviews/0042-bat-configuration-implementation-review.md), no blocking issues |
| [0018](0018-implement-eza-configuration.md) | Implement eza Configuration Package | Complete — implementation review [0044](../reviews/0044-eza-configuration-implementation-review.md), no blocking issues |
| [0019](0019-implement-taskfile-completion.md) | Implement Native Taskfile Completion (go-task + fzf-tab) | Complete |
| [0020](0020-implement-claude-statusline.md) | Implement Claude Code Statusline Package | Complete — implementation review [0058](../reviews/0058-claude-statusline-implementation-review.md). One blocking issue (non-portable `stat` call breaking the PR/MR segment on Linux) was found during review and fixed in the same change. |
| [0021](0021-implement-os-maintenance.md) | Implement OS Maintenance Helper | Complete |
| [0022](0022-implement-herdr-completion.md) | Implement Herdr Session Completion (herdr + fzf-tab) | Complete |
| [0023](0023-implement-btop-configuration.md) | Implement btop Configuration | Complete — implementation review [0053](../reviews/0053-btop-implementation-review.md), no blocking issues |
| [0024](0024-implement-caveman-session-scoped-savings.md) | 0024 — Implement caveman session-scoped savings | Complete — implementation review [0061](../reviews/0061-caveman-session-scoped-savings-implementation-review.md), no blocking issues |
| [0025](0025-real-zsh-git-configuration-plan.md) | Real Zsh and Git Configuration Adoption | Complete |
| [0026](0026-implement-neovim-configuration.md) | Implement Neovim Configuration Package | Complete |
| [0027](0027-implement-cli-speed-test-tool.md) | Implement CLI Speed Test Tool | Complete |
| [0028](0028-implement-codex-customization.md) | Implement Codex Customization Package | Complete |
| [0029](0029-implement-macchiato-blue-palette-alignment.md) | Implement Macchiato Blue Palette Alignment | Complete |
| [0030](0030-implement-lms-docker-desktop-completions.md) | Interactive CLI Completions for `lms` and `docker desktop` | Complete — implementation review [0089](../reviews/0089-lms-docker-desktop-completions-implementation-review.md), no blocking issues |
| [0031](0031-implement-ghostty-configuration.md) | Implement Ghostty Configuration | Complete |
| [0032](0032-ghostty-follow-ups.md) | Ghostty Follow-ups — Doctor, Task Dry-Run, Palette Wording | Complete |
