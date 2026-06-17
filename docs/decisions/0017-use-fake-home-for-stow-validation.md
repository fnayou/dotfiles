# Decision: Use Fake Home for Stow Validation When Real Home Has Conflicts

**Number:** 0017
**Date:** 2026-06-17
**Status:** Accepted
**Context:** Plan 0009 — corrective after OMP package dry-run conflict

---

## Context

Running `stow --simulate` against `$HOME` is the standard way to preview what a
package would do. For packages whose target paths (`~/.config/<name>`) commonly
already exist as real directories on a developer's machine, the dry-run produces:

```
WARNING! stowing <package> would cause conflicts:
  * existing target is not owned by stow: .config/<name>
All operations aborted.
```

This is correct Stow behaviour. The package layout may be completely valid — the
conflict only means the directory existed before Stow tried to claim it. A real-home
dry-run alone cannot confirm layout validity in this case.

First observed when running `task dry-run AREA=common PACKAGE=omp` against a machine
where `~/.config/omp/` already contained the user's real Oh My Posh configuration.

---

## Decision

For packages targeting paths that commonly already exist (e.g., `~/.config/omp/`,
`~/.config/git/`), supplement real-home dry-runs with fake-home validation to confirm
package layout:

```bash
TEST_HOME="$(mktemp -d)"
stow --dir=stow/<area> --target="$TEST_HOME" --simulate <package>
rm -rf "$TEST_HOME"
```

Rules:

- Always remove `$TEST_HOME` immediately after validation.
- `$TEST_HOME` must be created with `mktemp -d` — never reuse a path or hardcode one.
- Real-home dry-run is still useful to surface the conflict explicitly; it is not
  replaced, only supplemented.
- `--adopt` remains forbidden. A directory-ownership conflict is a stop signal, not a
  flag to bypass.
- A clean fake-home result confirms the package layout is correct. It does not
  authorise skipping the real-home conflict resolution before stowing for real.

---

## Consequences

- Package layout can be verified without a clean home directory.
- Conflicts on real home are still surfaced and remain stop signals.
- `--adopt` prohibition is unchanged and absolute.
- `docs/stow-usage.md` documents this technique under "Conflict handling" →
  "Fake-home validation".
- Applies to the `omp` package and any future package whose target path may already
  exist on a developer's machine.
