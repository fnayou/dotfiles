# Decision: `~/.zshrc` Stays an Unmanaged User-Owned Regular File; the `--no-folding` Migration Does Not Touch It

**Number:** 0027
**Date:** 2026-06-18
**Status:** Accepted
**PRD:** 0008-zsh-managed-layer-activation
**Architecture:** 0008-zsh-managed-layer-activation-architecture (§6)
**Reaffirms:** ADR-0021

## Context

ADR-0021 established that `~/.zshrc` is never stowed, never symlinked, and never
auto-edited — the user adds the single guarded include block by hand. ADR-0024 introduced
the `--no-folding` migration, which changes how the zsh package is stowed. A question
arises: does the migration affect `~/.zshrc`?

Review 0024 confirmed `~/.zshrc` is already a regular file (7 lines, not a symlink)
containing the guarded include block. Architecture 0008 §6 confirmed the migration alters
only the shape of `~/.config/zsh/` — converting the directory-fold symlink into a real
directory with per-file symlinks — and never touches `~/.zshrc`.

## Decision

`~/.zshrc` remains an unmanaged, user-owned regular file throughout and after the
`--no-folding` migration.

Specifically:
- The zsh package path is `stow/common/zsh/.config/zsh/`. Stow targets `~/.config/zsh/`.
  `~/.zshrc` is at the `$HOME` root — outside the package's reach. Stow cannot link or
  touch it regardless of flags.
- No migration step (unstow fold, restow with `--no-folding`, copy `.example` → real file)
  reads, writes, or checks `~/.zshrc` content. The guarded include block already present
  is the sole, sufficient trigger: once `index.zsh` becomes a real per-file symlink, the
  guard passes on the next interactive shell open — no `~/.zshrc` edit required.
- `zshrc.example` in the package stows only to `~/.config/zsh/zshrc.example` (a reference
  copy); it is never linked to `~/.zshrc` (ADR-0021).
- No agent, script, or task in this repository ever writes to `~/.zshrc` (AGENTS §8).

## Consequences

- The migration path is simpler: it is purely a stow-shape change. The user edits only
  `$HOME` stow targets inside `~/.config/zsh/`; `~/.zshrc` is untouched.
- The guarded include block the user added (confirmed by Review 0024) is the activation
  trigger and requires no modification for the `--no-folding` migration to take effect.
- Reaffirms ADR-0021 against the new migration context: the managed footprint in `~/.zshrc`
  remains exactly one delimited three-line block, and the sole revert path (delete those
  three lines) is unchanged.
