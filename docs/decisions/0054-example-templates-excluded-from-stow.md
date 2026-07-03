# Decision: `local.zsh.example` and `zshrc.example` Excluded from Stow

**Number:** 0054
**Date:** 2026-07-03
**Status:** Accepted

## Context

The `stow/common/zsh/` package stows with `--no-folding` (ADR-0024), so every file
physically present in the package directory is symlinked into `~/.config/zsh/` —
including `.example` templates. Earlier design (Architecture 0008–0010) accepted these
`.example` symlinks as "harmless reference copies."

Two of these templates are pure references the shell never sources:

- `local.zsh.example` — skeleton the user copies to a real, git-ignored
  `~/.config/zsh/local.zsh` (ADR-0023, ADR-0026).
- `zshrc.example` — template for the user's `~/.zshrc`; never linked to `~/.zshrc`
  (ADR-0021).

Symlinking them into `~/.config/zsh/` adds clutter with no function and invites
confusion (e.g. copying from the `$HOME` symlink instead of the repo source). The
package already carries a `.stow-local-ignore` (Review 0035) that excludes
`local.zsh`, so the "no `.stow-local-ignore` footgun" concern raised in ADR-0021 was
already accepted for this package.

## Decision

Extend `stow/common/zsh/.stow-local-ignore` to exclude both reference templates from
stow:

```
^/\.config/zsh/local\.zsh\.example$
^/\.config/zsh/zshrc\.example$
```

They remain tracked in the repo as templates but are **never** symlinked into
`~/.config/zsh/`. Users read them at their repo path and copy from there.

The other `.example` templates (`shared`, `macos`, `arch`, `index`, `omp`) are **not**
excluded — they still symlink in as harmless reference copies alongside their real
counterparts. This ADR narrows only the two never-sourced references.

## Consequences

- `~/.config/zsh/` no longer contains `local.zsh.example` / `zshrc.example` symlinks
  after a re-stow — cleaner managed directory.
- Copy instructions must reference the **repo path**, not the (now-absent) `$HOME`
  symlink. Docs updated accordingly: `docs/stow-usage.md`, `docs/guides/zsh-setup.md`,
  `website/features/shell.md`.
- Existing adopters keep stale `~/.config/zsh/{local.zsh,zshrc}.example` symlinks until
  they run `stow --restow zsh`; the ignore only affects future stows.
- Narrows, does not reverse, ADR-0021 — the `.stow-local-ignore` footgun was already
  accepted for `local.zsh` in this package.
- Supersedes the "all `.example` files stow harmlessly" statements in Architecture
  0008–0010 for these two files only; those historical records are left as-is.
