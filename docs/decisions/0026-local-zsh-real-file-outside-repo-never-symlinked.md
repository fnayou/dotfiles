# Decision: `local.zsh` Is a Real, Unversioned File Created Outside the Repo Under `~/.config/zsh/`, Never Symlinked

**Number:** 0026
**Date:** 2026-06-18
**Status:** Accepted
**PRD:** 0008-zsh-managed-layer-activation
**Architecture:** 0008-zsh-managed-layer-activation-architecture (§5)
**Refines:** ADR-0023

## Context

ADR-0023 established `local.zsh` as the git-ignored, last-sourced override slot. Under the
old directory-fold stow, `~/.config/zsh` was a symlink into the repo package dir — so a
`local.zsh` created in `~/.config/zsh/` would physically reside inside the repo working
tree; the only protection against accidental commit was the `.gitignore` entry.

ADR-0024 switched the intended stow strategy to `--no-folding`. Under `--no-folding`,
`~/.config/zsh/` is a **real directory** that Stow owns, not a symlink into the repo.
Stow places per-file symlinks for managed files inside it; any non-symlinked file placed
there resides **outside the repo working tree** and cannot be `git add`-ed by accident.

## Decision

`local.zsh` is a **real, unversioned file** that the user creates directly under
`~/.config/zsh/` using their editor:

```
⚠️  MANUAL STEP — create a REAL private file (not from the repo); put machine-specific and
    sensitive values only here; never commit
$EDITOR "$HOME/.config/zsh/local.zsh"
```

It is:
- **Not** copied from the repo (no `.example` template exists for it — ADR-0023).
- **Not** a symlink — Stow has no `local.zsh` in the package dir to link from.
- **Not** tracked by git: the `.gitignore` entry is a belt-and-suspenders second line of
  defence, but the primary boundary is physical: the file is outside the repo working tree
  and cannot be staged.

`index.zsh` sources it last (`[[ -r "$HOME/.config/zsh/local.zsh" ]] && source …`) and
only if present, so machines without a `local.zsh` start a clean shell.

## Consequences

- `local.zsh` has a stronger privacy boundary than under folding: even without `.gitignore`,
  it could not enter git because it lives outside the repo (ADR-0003 / AGENTS §9).
- The `.gitignore` entry for `local.zsh` in `stow/common/zsh/.config/zsh/.gitignore`
  remains correct and is kept as the belt-and-suspenders guard.
- No `.example` template exists for `local.zsh`; this is intentional — the content is
  machine-specific and sensitive by design.
- Refines ADR-0023: the "git-ignored" property still holds, but the stronger "physically
  outside the repo" property now also holds under `--no-folding`.
