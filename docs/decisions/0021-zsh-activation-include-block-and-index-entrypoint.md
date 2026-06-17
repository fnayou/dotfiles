# Decision: Zsh Activation via a Single Guarded `~/.zshrc` Include Block + Managed `index.zsh` Entry Point

**Number:** 0021
**Date:** 2026-06-17
**Status:** Accepted
**PRD:** 0007-zsh-activation-migration
**Architecture:** 0007-zsh-activation-migration-architecture

## Context

Architecture 0004 / ADR-0016 had the user append a multi-line source block to their
real `~/.zshrc` (source `shared.zsh`, then an inline `if/elif` OS branch). As more
managed layers appear (Oh My Posh, local overrides, tool integrations), that footprint
grows, so there is no single revert point and every new layer means another hand-edit
of `~/.zshrc`.

PRD 0007 chose Model 3 as the migration target: the user keeps an **unmanaged**
`~/.zshrc` and adds exactly **one** guarded include block that sources a single managed
entry point. This minimizes and stabilizes the managed footprint in `~/.zshrc` and gives
migration one clean revert point.

## Decision

Zsh activation uses a **single guarded include block** that the user adds to their real
`~/.zshrc` **by hand**. No tool or script in this repository ever writes to `~/.zshrc`,
and `~/.zshrc` is never stowed.

```zsh
# >>> dotfiles managed (zsh) — added manually; delete this block to disable >>>
[[ -r "$HOME/.config/zsh/index.zsh" ]] && source "$HOME/.config/zsh/index.zsh"
# <<< dotfiles managed (zsh) <<<
```

- The block is **delimited** so the managed region is unambiguous and a one-step revert
  (delete the three lines) fully disables the managed layer.
- The block is **guarded** (`[[ -r ... ]]`): if `index.zsh` is absent, it is a no-op and
  the shell still starts.
- `~/.config/zsh/index.zsh` is the managed **entry point**. It owns **source order only**
  — it sources `shared.zsh`, the OS-detected platform file, `omp.zsh` (if present), and
  `local.zsh` (last). Each layer file keeps its own guarded logic; this preserves the
  shared/macos/arch separation from Architecture 0004.
- This refines ADR-0016: the inline OS-detection block becomes the body of `index.zsh`.

**`zshrc.example` placement.** The reference template for `~/.zshrc` is committed at
`stow/common/zsh/.config/zsh/zshrc.example`, not at the package root. From there Stow can
only ever link it to `~/.config/zsh/zshrc.example` — **never** to `~/.zshrc`. This avoids
a `.stow-local-ignore` (which would replace Stow's default ignore list, a footgun) while
guaranteeing the template is never auto-applied to `~/.zshrc`. The user hand-copies the
include block (or, on a fresh machine, the whole template) into their real `~/.zshrc`.

## Consequences

- `~/.zshrc` gains exactly one managed region — one revert point. New layers are wired
  inside `index.zsh`, never in `~/.zshrc`.
- One extra managed file (`index.zsh`) and one indirection hop — accepted for the safety
  and revert-simplicity gain.
- `index.zsh` is committed as `index.zsh.example`; the real `index.zsh` is git-ignored.
- The block text is reproducible and identical on every machine.
- Supersedes the multi-line `~/.zshrc` source block previously documented in
  `docs/stow-usage.md` (updated to the single include block).
