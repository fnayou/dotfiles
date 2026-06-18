# Decision: Use GNU Stow `--no-folding` for the Zsh Package

**Number:** 0024
**Date:** 2026-06-18
**Status:** Accepted
**PRD:** 0008-zsh-managed-layer-activation
**Architecture:** 0008-zsh-managed-layer-activation-architecture

## Context

Review 0024 found `~/.config/zsh` was stowed as a **directory fold** — one directory
symlink `~/.config/zsh → …/stow/common/zsh/.config/zsh` — rather than the per-file
symlinks `docs/stow-usage.md` depicts (Issue 3). With folding, `~/.config/zsh` **is** the
repo package directory: any non-managed file dropped there is written inside the repo
tree, and there is no filesystem boundary for a real, unversioned `local.zsh` (ADR-0023).

## Decision

Use GNU Stow `--no-folding` for the zsh package.

Reason:
- keep `~/.config/zsh` as a normal directory,
- make managed files explicit symlinks,
- keep local/private files such as `local.zsh` out of the repo,
- avoid accidental writes into the repository through a folded directory symlink.

## Consequences

- `~/.config/zsh` is a real directory Stow owns; each managed file is its own symlink into
  the package — explicit, per-file visibility of what is repo-managed.
- A real directory lets `local.zsh` live as a real, unversioned file alongside the
  symlinks, outside the repo working tree (ADR-0026), strengthening the privacy boundary
  beyond `.gitignore` alone (ADR-0023, AGENTS §9).
- Non-managed files dropped into `~/.config/zsh` no longer land inside the repo tree.
- Tradeoff: each new managed file needs a `--no-folding --restow` to create its link —
  accepted and explicit by design (PRD 0008).
- Folding is no longer the intended behavior for this package; the migration runbook
  (Architecture 0008 §3) converts the existing fold safely, dry-run-gated, never `--adopt`.
