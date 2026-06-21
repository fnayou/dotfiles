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
| [0007](0007-homebrew-split-brewfiles.md) | Homebrew split Brewfiles | Superseded by 0045 |
| [0008](0008-minimal-github-actions-ci.md) | Minimal GitHub Actions CI | Accepted |
| [0009](0009-foundation-taskfile-no-install-tasks.md) | Foundation Taskfile — no install tasks | Accepted |
| [0010](0010-packages-dir-deferred.md) | Packages directory deferred | Accepted |
| [0011](0011-task-dry-run-single-package-var.md) | Task dry-run single package var | Accepted |
| [0012](0012-use-area-and-package-for-stow-task-interface.md) | Use AREA and PACKAGE for Stow task interface | Accepted |
| [0013](0013-include-based-git-config-strategy.md) | Include-based Git config strategy | Accepted |
| [0014](0014-gitconfig-common-filename.md) | `.gitconfig.common` filename | Accepted |
| [0015](0015-git-credential-helpers-deferred.md) | Git credential helpers deferred | Accepted |
| [0016](0016-zsh-common-package-runtime-os-detection.md) | Zsh files in `stow/common/zsh/` with runtime OS detection | Accepted |
| [0017](0017-use-fake-home-for-stow-validation.md) | Use fake home for Stow validation | Accepted |
| [0018](0018-brewfile-categories-evolving-per-prd.md) | Brewfile categories evolving per PRD | Superseded by 0045 |
| [0019](0019-deps-taskfile-tasks-non-mutating.md) | `deps:` Taskfile tasks are non-mutating | Accepted |
| [0020](0020-zinit-manual-clone-never-auto-cloned.md) | Zinit manual clone, never auto-cloned | Accepted |
| [0021](0021-zsh-activation-include-block-and-index-entrypoint.md) | Zsh activation include block + `index.zsh` entry point | Accepted |
| [0022](0022-zsh-migration-model-4-start-model-3-target.md) | Zsh migration: Model 4 start, Model 3 target | Accepted |
| [0023](0023-zsh-local-override-slot.md) | `local.zsh` git-ignored last-sourced override slot | Accepted |
| [0024](0024-use-no-folding-for-zsh-package.md) | Use GNU Stow `--no-folding` for the zsh package | Accepted |
| [0025](0025-managed-zsh-files-git-ignored-linked-by-presence.md) | Managed zsh real files are linked by Stow from physical presence while staying git-ignored | Accepted |
| [0026](0026-local-zsh-real-file-outside-repo-never-symlinked.md) | `local.zsh` is a real, unversioned file outside the repo, never symlinked | Accepted |
| [0027](0027-zshrc-stays-unmanaged-no-folding-migration-does-not-touch-it.md) | `~/.zshrc` stays unmanaged; `--no-folding` migration does not touch it | Accepted |
| [0028](0028-require-human-setup-guides-for-manually-activated-packages.md) | Require human setup guides for manually-activated packages | Accepted |
| [0029](0029-shared-index-zsh-tracked-with-real-content.md) | `shared.zsh` and `index.zsh` tracked with real safe content | Accepted |
| [0030](0030-xdg-style-git-config-layout.md) | XDG-style Git config layout (`~/.config/git/`) | Accepted |
| [0031](0031-git-aliases-separate-file.md) | Git aliases extracted to a separate `aliases` file | Accepted |
| [0032](0032-git-bootstrap-taskfile-tasks.md) | `git:bootstrap` and `git:bootstrap:dry-run` as first mutating Taskfile tasks | Accepted |
| [0033](0033-shared-zsh-content-scope.md) | `shared.zsh` content scope | Accepted |
| [0034](0034-platform-layers-runtime-selected.md) | `macos.zsh` and `arch.zsh` as runtime-selected platform layers | Accepted |
| [0035](0035-omp-zsh-double-guarded-prompt-file.md) | `omp.zsh` as standalone double-guarded prompt file | Accepted |
| [0036](0036-local-zsh-created-by-editor-not-example.md) | `local.zsh` created directly by user, not copied from `.example` | Accepted |
| [0037](0037-extended-aliases-excluded-from-examples.md) | Extended aliases excluded from committed `.example` files | Superseded by 0044 |
| [0038](0038-histfile-at-home-not-xdg.md) | `HISTFILE` at `$HOME/.zsh_history`, not XDG | Accepted |
| [0039](0039-completion-guard-avoid-double-compinit.md) | Completion guard — avoid double `compinit` when Zinit is present | Superseded by 0046 |
| [0040](0040-fzf-zsh-integration-method.md) | `fzf --zsh` as the fzf integration method | Accepted |
| [0041](0041-zoxide-init-without-cmd-override.md) | `zoxide init zsh` without `--cmd` override | Superseded by 0047 |
| [0042](0042-eza-minimal-alias-only.md) | Minimal `ls='eza'` alias only in committed template | Superseded by 0044 |
| [0043](0043-zsh-bootstrap-taskfile-tasks.md) | `zsh:bootstrap` and `zsh:bootstrap:dry-run` as mutating Taskfile tasks for zsh | Accepted |
| [0044](0044-personal-preferences-in-committed-zsh-files.md) | Personal preferences permitted in committed managed zsh files | Accepted |
| [0045](0045-cross-platform-packages-flat-brewfile.md) | Cross-platform packages — single Brewfile and Arch package list | Accepted |
| [0046](0046-compinit-unconditional-zinit-light-mode.md) | `compinit` runs unconditionally — Zinit guard removed (light mode) | Accepted |
| [0047](0047-zoxide-init-with-cmd-cd.md) | `zoxide init zsh` with `--cmd cd` override | Accepted |
| [0048](0048-status-blocks-kept-in-sync-with-repo-state.md) | Status blocks in `AGENTS.md`/`CLAUDE.md` kept in sync with repo state | Accepted |
