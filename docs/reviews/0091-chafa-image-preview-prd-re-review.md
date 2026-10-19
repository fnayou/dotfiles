# Review: chafa Image Preview PRD — Re-review

**Number:** 0091
**Status:** Complete
**Date:** 2026-10-19
**PRD reviewed:** [0030-chafa-image-preview](../prd/0030-chafa-image-preview.md) (Draft)
**Previous review:** [0090](0090-chafa-image-preview-prd-review.md)
**Files reviewed:** `docs/prd/0030-chafa-image-preview.md`

## Summary

Re-review of PRD 0030 — Image Preview in the Terminal with chafa, after the fixes for review 0090.
Both blocking issues are resolved and all six non-blocking suggestions were applied. PRD 0030 is
ready for operator approval.

## Blocking Issues

None.

## Review 0090 Findings

| Finding | Result | Evidence |
|---|---|---|
| Blocking 1 — routing for options with values | Resolved | Goals: no image argument means one `bat` call with all arguments as given; per-file routing only when an image file is present. New criterion `cat -l md notes.txt` |
| Blocking 2 — Scope misses five documents | Resolved | Scope lists `docs/guides/zsh-setup.md`, `docs/guides/packages-setup.md`, `website/usage/aliases.md`, `website/features/shell.md`, `website/features/packages.md`; new criterion "Every document listed in Scope matches the new behaviour" |
| Non-blocking 1 — `bat` absent | Applied | Goal and criterion: real `cat` when `bat` is not on `PATH` |
| Non-blocking 2 — alias before function | Applied | Constraint added. Verified: with `alias cat=bat`, defining `cat()` fails with `defining function based on alias 'cat'` and a parse error; after `unalias cat` it succeeds |
| Non-blocking 3 — `/tmp/x` | Applied | Criterion uses `mktemp` |
| Non-blocking 4 — `TERM_PROGRAM` over SSH and remote herdr | Applied | Constraint added; remote herdr marked untested |
| Non-blocking 5 — dependency check | Applied | Scope and criterion: `task deps:check:zsh` reports chafa as optional. The script today exits 1 only for required tools (`scripts/check-zsh-deps.sh:4`), so an optional tier is new plan work |
| Non-blocking 6 — `--` and `-`-prefixed names | Applied | Covered by the one-call `bat` rule |

## Non-Blocking Suggestions

1. The Safety Requirement "No new file outside the existing `zsh` package and the package
   manifests" still holds, since the added Scope items are edits to existing files. The plan should
   keep it that way.

## Safety Verdict

PASS — unchanged from review 0090; the new criteria clean up only their own `mktemp` file.

## Privacy Verdict

PASS — no hostnames, user paths or secrets added.

## Cross-Platform Verdict

PASS — the `bat`-absent fallback covers apt-only Debian machines; no OS branch added.

## Documentation Verdict

PASS — Scope now covers every document that describes `cat`, the suffix aliases or the package
lists.

## Recommended Next Action

1. Operator: approve PRD 0030 explicitly (e.g. "Approve PRD 0030"). No architecture document is
   needed; the plan follows approval.
