# Decision: Extended Aliases Excluded from Committed `.example` Files

**Number:** 0037
**Date:** 2026-06-19
**Status:** Superseded by 0044
**Related:** PRD-0010, Architecture-0010 §12, ADR-0033

## Context

Committed `.example` templates represent the minimum safe default for a new machine. Aliases are a point of personal preference — different users have different workflows, different tool flags, and different conventions. Including extended aliases (`ll`, `la`, `lt`, `tree`) in committed templates imposes workflow choices without a safety or portability justification.

## Decision

Only minimal, guarded, uncontroversial aliases appear in committed `.example` files:

| Alias | Location | Guard | Rationale |
|---|---|---|---|
| `alias grep='grep --color=auto'` | `shared.zsh.example` | None (grep always present; flag valid on BSD and GNU) | Universally safe; improves readability |
| `alias ls='eza'` | `shared.zsh.example` | `command -v eza` | Minimal redirect; no flags that express personal preference |
| `alias o='open'` | `macos.zsh.example` | None (open always present on macOS) | macOS-only file; `open` is always available |
| `alias sc='systemctl'` | `arch.zsh.example` | None (systemctl always present on Arch) | Arch-only file; systemctl is always present |
| `alias aur='yay'` / `alias aur='paru'` | `arch.zsh.example` | `command -v yay` / `command -v paru` | AUR helper shorthand; guarded correctly |

Extended aliases (`ll='ls -lh'`, `la='ls -lha'`, `lt='ls --sort=modified'`, `ll='eza -lh'`, tree variants) are personal preference and belong in:
- The user's real `shared.zsh` (if desired on all machines).
- `local.zsh` (if machine-specific or sensitive-context-dependent).

## Consequences

- Committed templates represent the minimum safe default. No user is forced into an alias they did not choose.
- Users who want extended aliases add them in their own `shared.zsh` or `local.zsh`. The setup guide (`docs/guides/zsh-setup.md`) notes this pattern.
- Future contributors who want to add a new alias to `.example` files must justify it against these criteria: is it portable, is it uncontroversial, is it guarded when it assumes tool presence?
- This decision complements ADR-0033 (content scope) and ADR-0042 (eza-specific alias scope).
