# Decision: XDG-Style Git Config Layout (`~/.config/git/`)

**Number:** 0030
**Date:** 2026-06-18
**Status:** Accepted
**Supersedes:** ADR-0013 (include-based Git config strategy, in part), ADR-0014 (gitconfig-common filename)
**Related:** Architecture-0009, PRD-0009

## Context

ADR-0013 defined an include-based Git config strategy where `~/.gitconfig` includes a
managed common file. ADR-0014 named that file `.gitconfig.common` (home-level dotfile).
ADR-0006 established `.example`-only templates for all Git config files.

The initial revision of Architecture-0009 proposed continuing with home-level files
(`.gitconfig.common`, `.gitignore_global`). A revision adopted XDG layout
(`~/.config/git/`) instead. This ADR records that revision decision.

Three options were considered:

1. **Home-level dotfiles** — `~/.gitconfig.common`, `~/.gitignore_global`. Familiar,
   but clutters `$HOME`, uses legacy naming conventions.
2. **XDG layout** — `~/.config/git/config-common`, `~/.config/git/aliases`,
   `~/.config/git/ignore`. Clean, modern, already used by Git natively for
   `~/.config/git/config`.
3. **Single combined file** — one file with both settings and aliases. Simpler to
   manage but harder to audit.

## Decision

Use the XDG-style layout with three committed files under `~/.config/git/`:

- `config-common` — portable settings (no identity, no aliases).
- `aliases` — Git aliases only.
- `ignore` — global ignore patterns (referenced via `core.excludesfile`).

The Stow package tree mirrors this at `stow/common/git/.config/git/`.
`~/.gitconfig` includes `config-common` and `aliases` via `[include] path = ...`.
`ignore` is referenced by `core.excludesfile = ~/.config/git/ignore` inside
`config-common` — no separate include needed.

## Consequences

- Supersedes the home-level path decisions in ADR-0013 and ADR-0014. Those ADRs
  remain for historical context but their path choices are no longer active.
- `stow/common/git/.gitconfig.example` and `.gitignore_global.example` are removed.
- Root `.gitignore` entries for `stow/common/git/.gitconfig.common` and
  `stow/common/git/.gitignore_global` are removed (those paths no longer exist).
- `~/.config/git/` is created on the user's machine when Stow runs.
- Bootstrap task wires the includes into `~/.gitconfig` (see ADR-0027).
- Each file has a single clear responsibility and can be audited independently.
- Trade-off accepted: slightly more files than a single combined config.
