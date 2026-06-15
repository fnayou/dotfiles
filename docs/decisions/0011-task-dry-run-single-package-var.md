# Decision: `task dry-run` Accepts Single `PACKAGE=<platform>/<name>` Argument

**Number:** 0011
**Date:** 2026-06-15
**Status:** Superseded by [ADR-0012](0012-use-area-and-package-for-stow-task-interface.md)

## Context

Architecture 0001 proposed two variables for the `stow:dry-run` task: `PLATFORM=<p>` and `PACKAGE=<n>`. PRD 0002 referenced a single `PACKAGE=<name>` variable. The two forms were in tension.

Reference: Architecture 0002 Decision 3.

## Decision

`task dry-run` uses a **single variable**: `PACKAGE=<platform>/<name>` (e.g., `PACKAGE=common/git`).

The user specifies the full sub-path under `stow/`. The variable is passed directly to `stow --dir=stow`:

```bash
stow --dir=stow --target="$HOME" --simulate common/git
```

`task list` strips the `stow/` prefix from its output (via `sed 's|^stow/||'`), so copy-paste from `task list` into `task dry-run PACKAGE=...` works directly.

## Consequences

- Single variable is unambiguous — the user writes exactly the path they intend to stow.
- `task list` output format matches `PACKAGE=` format directly — no manual editing.
- Two-variable form (`PLATFORM=macos PACKAGE=arch-pkg`) is prevented — a cross-contamination misuse vector eliminated.
- Trade-off accepted: slightly longer `PACKAGE=common/git` vs. `PACKAGE=git` — accepted for precision and safety.
