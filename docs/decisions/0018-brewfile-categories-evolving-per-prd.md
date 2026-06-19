# Decision: Brewfile Categories Are an Evolving, Per-PRD Set

**Number:** 0018
**Date:** 2026-06-17
**Status:** Superseded by 0045
**PRD:** 0006-shell-dependencies
**Architecture:** 0006-shell-dependencies-architecture

## Context

ADR-0007 introduced split Brewfiles under `packages/macos/` and listed illustrative
categories: `core`, `cli`, `dev`, `gui`, `optional`. PRD 0006 scopes shell dependencies
and requires a `shell` category that maps 1:1 to zsh runtime needs. The `shell`
category does not appear in ADR-0007's illustrative list, which could appear to
contradict that ADR.

## Decision

ADR-0007's category list is **illustrative and non-exhaustive**, not a closed
enumeration. Brewfile categories are defined per-PRD as new dependency scopes are
introduced. Each category requires a PRD that explicitly scopes it before the file
is created.

For PRD 0006, the categories in use are:

- `Brewfile.core` — repository prerequisites (`git`, `stow`, `go-task`)
- `Brewfile.shell` — zsh shell runtime tools (`fzf`, `zoxide`, `eza`, `oh-my-posh`)
- `Brewfile.optional` — optional extras (placeholder; contents deferred)

Future categories (e.g. `Brewfile.cli`, `Brewfile.dev`, `Brewfile.gui`) may be added
when a PRD scopes them. No Brewfile is created without an authorizing PRD.

## Consequences

- ADR-0007 and ADR-0018 are consistent: ADR-0007 established the split-by-category
  principle; ADR-0018 clarifies the category set is open and evolves per-PRD.
- The `shell` category is not a renamed `cli` — it is a dedicated tier for zsh
  runtime tools, with a 1:1 mapping to `check-zsh-deps.sh`.
- Adding any new category still requires a PRD — the per-PRD gate is unchanged.
