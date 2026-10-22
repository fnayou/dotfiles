# Review: Generated Art and Architecture Diagram Plan

**Number:** 0103
**Status:** Complete
**Date:** 2026-10-23
**Plan reviewed:** [0036-generated-art-and-architecture-diagram](../plans/0036-generated-art-and-architecture-diagram.md) (Draft)
**Previous review:** [0102](0102-generated-art-plan-review.md)

## Summary

Strict re-review of Draft Plan 0036. The revision resolves the three earlier blocking findings, but two new sequencing defects remain: Task 19 changes a counted CI input after image generation, and Task 20 requires Task 22's review before commits even though Task 22 comes later. Plan 0036 remains Draft; this review does not approve it.

## Blocking Issues

1. `docs/plans/0036-generated-art-and-architecture-diagram.md:142-157,158-166` generates the committed art in Task 18, then edits `ci.yml` in Task 19. `facts.py` counts CI steps (Task 2, `:48-53`), so adding the freshness step changes an input used by generated facts after regeneration. Task 18's late-rebuild condition names ADRs, guides, tasks, packages and `CHANGELOG.md`, but omits CI files (`:147-148`). The fourth commit groups both changes, leaving committed SVGs stale. Move Task 19's CI edit before regeneration or regenerate after it.
2. `docs/plans/0036-generated-art-and-architecture-diagram.md:39,158-185` says tasks run in order, places the commits in Task 20, and says those commits occur only after Task 22 passes (`:161-162`). Task 22 is later and requires Task 21 to have been completed. This cannot be followed in the stated order. It also reverses the repository handoff rule that review passes before commit. Reorder the review and commit steps, and specify when the user's Task 21 test occurs relative to review and commit.

## Resolution of Review 0102 Findings

| Finding from 0102 | Status | Plan evidence and reasoning |
|---|---|---|
| Generated images committed before ADR and guide inputs, leaving outputs stale | Resolved | Tasks 14–15 add the ADR and guide before Task 18 regenerates images (`:128-148`). The new CI-after-regeneration defect is listed separately. |
| Rollback missed ignored diagram SVG and PNG | Resolved | Rollback explicitly checks ignored paths and names both diagram files for manual deletion (`:261-267`). |
| Live test push and remote cleanup insufficiently scoped | Resolved | Task 21 specifies an isolated local bare repository and excludes `origin`; cleanup says only the locally created temp repository is removed (`:167-182`, `:274-281`). The removal command is marked manual and its comment scopes it to that repository. |
| Correct stale highest-plan assumption | Not resolved | Assumptions still state plan 0035 was highest before this plan (`:31-33`). This remains a non-blocking factual correction. |
| Specify Claude hook range endpoints | Resolved | Commit uses staged files; push uses `@{u}..HEAD` or `origin/main..HEAD`; PR creation uses `origin/main..HEAD` (`:115-122`). |
| Test Python-version and locale reproducibility | Resolved | Task 19 specifies `LC_ALL=C`, default locale, and each installed Python 3.11+ interpreter (`:154-157`). |
| Add local `mkdocs build --strict` validation when available | Partially resolved | Task 19 runs it if MkDocs is installed; assumptions state it is not installed locally, so strict build remains deferred to the first post-merge workflow (`:34-35`, `:149-157`). This is still a reasonable optional suggestion, not a blocker. |

## Checks

### PRD acceptance criteria

| Criterion | Result | Task and validation |
|---|---|---|
| Shared palette; generators; deterministic SVG; brand outputs and tasks | Met | Tasks 1–8 specify palette verification, stdlib generators, dimensions, repeatability and CLI checks (`:51-92`). |
| Reminders are read-only, relevant-only, and continue on errors | Met | Tasks 9, 11–12 define the read-only command and both hook integrations (`:93-122`); Safety Checks confirm no mutation (`:224-239`). |
| CI freshness and docs-time diagram generation | Partial | Task 19 specifies both workflows, but edits counted CI input after Task 18's generation (`:142-157`). See Blocking Issue 1. |
| Optional librsvg setup, guide, ADR and website publication | Met | Tasks 13–16 cover package lists, doctor, ADR, guide and website (`:123-141`). |
| Git hook opt-in and live test behavior | Met | Task 10 describes dry-run/apply boundaries; Task 21 uses a local isolated remote and `gh pr create --help` (`:100-106`, `:167-182`). |

### Revision-specific checks

| Check | Result | Evidence |
|---|---|---|
| Renumbered task references and dependencies | Partial | Tasks 1–19 follow their intended inputs and cross-references. Task 18 includes Tasks 10–17 but Task 19 is the later counted-input change; the recovery clause at `:147-148` omits CI files. Task 20's dependency on later Task 22 is impossible under the declared order (`:39`, `:158-185`). |
| Four-commit partition | Fail | Tasks 1–8/10/13, 9/11/12/17, 14/15/16, and 18/19 are each assigned once (`:163-166`). But commit four combines images with a new counted CI step introduced after those images are generated; Task 20 also places commits before its required later review in task order (`:161-166`). |
| Task 18 follows every counted input | Fail | It follows ADR, guide, task and package edits (`:128-148`), but Task 19 adds a CI step while `facts.py` counts CI steps (`:48-53`, `:149-157`). |
| Task 21 live push and help invocation | Met | `TEST_REMOTE` is described as an isolated local bare repository, push avoids `origin`, and `gh pr create --help` creates no pull request (`:169-175`). `rm -rf "$TEST_REMOTE"` is marked manual and scoped by its adjacent comment to the user-created test remote (`:274-281`). |
| Claude hook range coverage | Met | Upstream and no-upstream push ranges, staged commit input, and PR base are all explicit (`:115-122`). |
| Cross-interpreter and locale reproducibility | Feasible | Run `art.py check` with each installed Python 3.11+ executable and both locale settings as Task 19 describes (`:154-157`). The clause limits the matrix to interpreters present on the primary machine. |
| Plan review header | Accurate for this revision | Line 8 points to review 0102 and records that its three findings were addressed. It identifies the previous review, not the current re-review. |
| Rollback for ignored diagram files and test remote | Met | Exact ignored paths are named; remote deletion is a marked manual command scoped by its comment (`:261-281`). |
| Safety, privacy, platform separation | Met as planned | Safety checks confine writes and local config changes; platform-specific librsvg commands are kept in their respective lists; staged diff privacy audit is required (`:123-127`, `:224-239`). |

## Non-Blocking Suggestions

- Correct the outdated highest-plan assumption at `docs/plans/0036-generated-art-and-architecture-diagram.md:31-33`.
- Run `mkdocs build --strict` in a suitable local environment before merge if available; the plan defers it otherwise (`:149-157`).
- Refresh the Plan review header at `:8` when a later plan revision records this re-review.

## Safety Verdict

FAIL — Task 20's stated review-before-commit gate cannot run in the declared task order. The isolated push and marked cleanup are adequately scoped.

## Privacy Verdict

PASS — no new private data is specified; the plan requires a staged-diff audit (`:236`).

## Documentation Verdict

FAIL — Task 19 changes a counted CI input after image regeneration, and the review/commit sequence is contradictory (`:142-166`, `:183-185`).

## Recommended Next Action

Planner: move the CI input change before regeneration (or regenerate afterward), and place the review gate before commits while preserving Task 21's required live test. Keep Plan 0036 Draft. Reviewer does not approve the plan; the user must explicitly approve it after a passing re-review.
