# Decision: Managed Zsh Real Files Are Linked by Stow from Physical Presence While Staying Git-Ignored; Only `.example` Templates Are Versioned

**Number:** 0025
**Date:** 2026-06-18
**Status:** Accepted
**PRD:** 0008-zsh-managed-layer-activation
**Architecture:** 0008-zsh-managed-layer-activation-architecture (§4)

## Context

PRD 0008 raised a concern: the package `.gitignore` excludes the real managed filenames
(`index.zsh`, `shared.zsh`, `macos.zsh`, `arch.zsh`, `omp.zsh`), yet `--no-folding` must
symlink exactly those files from the package directory into `~/.config/zsh/`. If the files
are git-ignored, can Stow still link them?

Architecture 0008 §4 resolved this: Stow determines what to symlink by scanning the package
directory for files **physically present on disk**, not by reading the git index. A
git-ignored file that exists on disk is linked by Stow just as any tracked file would be.

## Decision

Keep the package `.gitignore` exactly as-is. Do not un-ignore `index.zsh`, `shared.zsh`,
`macos.zsh`, `arch.zsh`, or `omp.zsh`.

The workflow is:

1. User copies `.example` → real filename locally (e.g. `index.zsh.example` → `index.zsh`).
2. The real file exists on disk in the package dir; it is git-ignored and never committed.
3. `stow --no-folding` scans the package dir and creates a per-file symlink for each
   physical file it finds, tracked or not.
4. The `*.example` templates remain the only committed source of truth — placeholder values
   only, no personal or sensitive data.

"Versioned" in PRD 0008 means the template is versioned (the `.example`), not the
filled-in real file.

## Consequences

- Filled-in real files (which may contain personal paths, tool choices, or machine-specific
  values) are never committed, satisfying AGENTS §9 (privacy) and ADR-0003.
- The `.gitignore` at `stow/common/zsh/.config/zsh/.gitignore` needs no change.
- Each new managed file requires a `--no-folding --restow` to create its symlink —
  accepted trade-off (PRD 0008, ADR-0024).
- `local.zsh` remains ignored and additionally lives physically outside the repo (ADR-0026),
  so it cannot be `git add`-ed by accident.
- If a future requirement genuinely demands committing a fully-portable managed file with no
  personal values, that would require a separate ADR un-ignoring only that specific filename
  and is not recommended now.
