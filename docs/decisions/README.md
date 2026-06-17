# Decisions

This directory stores ADR-style (Architecture Decision Record) documents for this dotfiles repository.

## Purpose

Decision records capture **important technical choices** made during the evolution of the repository — with context, rationale, and consequences.

Every significant decision that is not obvious from the code or structure should have a record here.

## Structure of a decision record

Each decision record must include:

- **Context** — what situation led to this decision.
- **Decision** — what was decided.
- **Consequences** — what changes as a result; what tradeoffs were accepted.
- **Status** — current state of the decision.

## Naming convention

Use numbered filenames in sequence:

```
0001-use-agents-md-as-operating-contract.md
0002-use-stow-package-based-layout.md
0003-separate-macos-arch-stow-packages.md
```

## When to write a decision record

- A structural choice was made that future contributors (or future sessions) need to understand.
- A non-obvious tradeoff was accepted.
- A convention was established that must be followed consistently.
- An earlier decision was revisited and changed.

## Status values

- **Proposed** — decision is under discussion.
- **Accepted** — decision is in effect.
- **Deprecated** — decision is no longer in effect but not yet replaced.
- **Superseded by [number]** — replaced by a newer decision record.

## Template

```markdown
# Decision: [Title]

**Number:** 0001
**Date:** YYYY-MM-DD
**Status:** Accepted

## Context

[What situation, constraint, or question led to this decision]

## Decision

[What was decided — be explicit]

## Consequences

[What changes as a result; tradeoffs accepted]
```

---

## Index

| Number | Title | Status |
|---|---|---|
| [0001](0001-platform-first-stow-layout.md) | Platform-first Stow layout | Accepted |
| [0002](0002-go-task-as-task-runner.md) | Go-task as task runner | Accepted |
| [0003](0003-example-files-for-sensitive-config.md) | `.example` files for sensitive config | Accepted |
| [0004](0004-xdg-mixed-mode-adoption.md) | XDG mixed-mode adoption | Accepted |
| [0005](0005-ssh-config-out-of-scope.md) | SSH config out of scope | Accepted |
| [0006](0006-git-config-templates-only.md) | Git config templates only | Accepted |
| [0007](0007-homebrew-split-brewfiles.md) | Homebrew split Brewfiles | Accepted |
| [0008](0008-minimal-github-actions-ci.md) | Minimal GitHub Actions CI | Accepted |
| [0009](0009-foundation-taskfile-no-install-tasks.md) | Foundation Taskfile — no install tasks | Accepted |
| [0010](0010-packages-dir-deferred.md) | Packages directory deferred | Accepted |
| [0011](0011-task-dry-run-single-package-var.md) | Task dry-run single package var | Accepted |
| [0012](0012-use-area-and-package-for-stow-task-interface.md) | Use AREA and PACKAGE for Stow task interface | Accepted |
| [0013](0013-include-based-git-config-strategy.md) | Include-based Git config strategy | Accepted |
| [0014](0014-gitconfig-common-filename.md) | `.gitconfig.common` filename | Accepted |
| [0015](0015-git-credential-helpers-deferred.md) | Git credential helpers deferred | Accepted |
| [0016](0016-zsh-common-package-runtime-os-detection.md) | Zsh files in `stow/common/zsh/` with runtime OS detection | Accepted |
