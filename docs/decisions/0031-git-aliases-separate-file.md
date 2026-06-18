# Decision: Git Aliases Extracted to a Separate `aliases` File

**Number:** 0031
**Date:** 2026-06-18
**Status:** Accepted
**Related:** ADR-0025, Architecture-0009

## Context

In the XDG Git layout established by ADR-0025, two approaches existed for organizing
aliases relative to settings:

1. **Combined** — one `config-common` file with both settings and `[alias]` section.
2. **Separated** — `config-common` for settings only; `aliases` as a separate file.

The legacy `.gitconfig.example` combined everything into one file.

## Decision

Extract Git aliases into a dedicated `aliases` file. `config-common` contains ONLY
non-alias configuration sections. `aliases` contains ONLY the `[alias]` section.

Both files are included from `~/.gitconfig` via separate `[include] path = ...` entries.

**Alias safety policy — permanently forbidden:**

- Force-push wrappers (any alias calling `push --force` or `push -f`).
- Hard-reset shortcuts (any alias calling `reset --hard`).
- `git clean` shortcuts or `git purge`/nuke variants.
- `git-svn` workflow aliases.
- `filter-branch` aliases (superseded by `git filter-repo`).
- Aliases that hardcode `master` as a branch name.
- `git-daemon` shortcuts.
- Any alias that could silently destroy work history.

Forbidden aliases are removed completely — not preserved in any legacy file.

The `aliases` file may contain a comprehensive set of safe aliases beyond a minimal
shorthand list. The set committed at initial adoption was audited against all forbidden
patterns and passed. New aliases may be added in future commits provided they pass
the same safety audit.

## Consequences

- Settings and aliases have different change rates; separate files make diffs cleaner.
- Security audits of `aliases` are focused: a reviewer scans one file for risky shorthand.
- `config-common` is easier to read without an `[alias]` section growing over time.
- New aliases are added to `aliases` only; `config-common` is not touched for alias changes.
- Trade-off accepted: two include entries in `~/.gitconfig` instead of one.
