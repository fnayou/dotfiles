# Decision: Use AREA and PACKAGE Variables for Stow Task Interface

**Number:** 0012
**Date:** 2026-06-15
**Status:** Accepted
**Supersedes:** [ADR-0011](0011-task-dry-run-single-package-var.md)

## Context

ADR-0011 defined a single `PACKAGE=<platform>/<name>` variable for `task dry-run`, passing `common/git` directly to Stow:

```bash
stow --dir=stow --target="$HOME" --simulate common/git
```

Validation revealed this is invalid. GNU Stow does not permit slashes in package names:

```
stow: ERROR: Slashes are not permitted in package names
task: Failed to run task "dry-run": exit status 2
```

Stow requires the package name to be a bare directory name — a direct child of `--dir`. The slash must be handled at the `--dir` level, not in the package argument.

## Decision

Split the task interface into two variables:

- `AREA` — the platform subdirectory under `stow/`: one of `common`, `macos`, or `arch`.
- `PACKAGE` — the package directory name within that area: e.g., `git`, `zsh`.

The Taskfile `dry-run` task translates these into the correct Stow invocation:

```bash
stow --dir=stow/{{.AREA}} --target="$HOME" --simulate {{.PACKAGE}}
```

Example:

```bash
task dry-run AREA=common PACKAGE=git
# runs: stow --dir=stow/common --target="$HOME" --simulate git
```

Direct Stow command (manual, without Taskfile):

```bash
stow --dir=stow/common --target="$HOME" --simulate git
```

`task list` output remains in `<area>/<package>` form (e.g., `common/git`) as a human-readable hint. The user splits on `/` to get `AREA` and `PACKAGE`.

## Consequences

- `task dry-run` now correctly invokes Stow without triggering the slash-in-package-name error.
- Two variables are required instead of one — slightly more to type, but unambiguous and correct.
- All documentation and validation commands updated to use the two-variable form.
- `task list` output is unchanged — `common/git` is still useful as a hint for `AREA=common PACKAGE=git`.
- ADR-0011 is superseded by this decision.
