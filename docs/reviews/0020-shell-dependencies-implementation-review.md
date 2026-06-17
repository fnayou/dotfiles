# Review: Shell Dependencies Implementation

**Number:** 0020
**Status:** Complete
**Date:** 2026-06-17
**Plan:** 0011-implement-shell-dependencies.md
**Branch:** feat/shell-deps

---

## Scope

Implementation review for Plan 0011 — shell dependency management layer (Brewfiles, `check-zsh-deps.sh`, ADRs 0018–0020, Taskfile `deps:` namespace).

---

## Checklist

| Check | Result |
|---|---|
| Builder implemented only approved plan scope | Pass |
| No `brew bundle install` executed or auto-triggered | Pass |
| No `brew bundle --cleanup` or destructive cleanup | Pass |
| `deps:macos:shell` task only echoes instructions | Pass |
| `check-zsh-deps.sh` does not install (read-only) | Pass |
| Zinit not auto-cloned | Pass |
| Shell startup files unmodified | Pass |
| `$HOME` unmodified | Pass |
| No Stow install/adopt operation run | Pass |
| Brewfiles contain only approved package names | Pass |
| macOS and Arch remain separated | Pass |
| No secrets present | Pass |

---

## Findings

### Nit — check-zsh-deps.sh:29

`hint_install` function signature differs slightly from plan specification. Plan describes `hint_install "$tool"` with a named parameter; implementation omits the unused `local tool="$1"`. Functionally equivalent — no behavioral difference.

**Severity:** Nit (no action required)

---

## Files Reviewed

- `packages/` — Brewfile manifests (macos/common, macos/shell, arch/shell)
- `scripts/check-zsh-deps.sh` — read-only dependency checker
- `Taskfile.yml` — `deps:` namespace tasks
- `docs/decisions/0018-brewfile-categories-evolving-per-prd.md`
- `docs/decisions/0019-deps-taskfile-tasks-non-mutating.md`
- `docs/decisions/0020-zinit-manual-clone-never-auto-cloned.md`
- `docs/plans/0011-implement-shell-dependencies.md`
- `docs/prd/0006-shell-dependencies.md`
- `docs/architecture/0006-shell-dependencies-architecture.md`
- `docs/shell-dependencies.md`

---

## Summary

**Verdict: PASS**

0 blockers. 0 warnings. 1 nit (no action required).

Implementation matches approved plan scope exactly. No packages installed, no home directory modified, no destructive operations present. Safe to merge.
