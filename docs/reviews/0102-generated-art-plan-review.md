# Review: Generated Art and Architecture Diagram Plan

**Number:** 0102
**Status:** Complete
**Date:** 2026-10-23
**Plan reviewed:** [0036-generated-art-and-architecture-diagram](../plans/0036-generated-art-and-architecture-diagram.md) (Draft)
**PRD:** [0032-generated-art-and-architecture-diagram](../prd/0032-generated-art-and-architecture-diagram.md) (Approved)
**Architecture:** [0028-generated-art-and-architecture-diagram-architecture](../architecture/0028-generated-art-and-architecture-diagram-architecture.md) (Approved)
**Files reviewed:** Plan 0036, PRD 0032, Architecture 0028, review format 0099, lifecycle, reviewer guidance, all `.claude/rules/*.md`, and cited repository files.

## Summary

Strict review of Plan 0036. Three blocking issues remain: generated outputs are committed before later documentation changes alter their inputs; rollback misses ignored diagram outputs; and Task 21 does not constrain its live push or remote cleanup. Plan 0036 remains Draft and is not approved by this review.

## Blocking Issues

1. `docs/plans/0036-generated-art-and-architecture-diagram.md:135-156` puts the committed image outputs in the first build commit, then adds an ADR and guide in the fourth commit (`:139-146`, `:153-156`). The facts reader counts ADRs and guides (`:54-57`), and the architecture uses those facts; adding the ADR and guide after generating and committing images changes generated facts and can leave committed SVGs stale. The final `task art:check` at `:149-151` happens before commits, but the prescribed commit sequence itself creates the staleness. Make the documentation inputs land before image generation, or assign the regenerated outputs to a commit after those inputs.
2. `docs/plans/0036-generated-art-and-architecture-diagram.md:121-124,188-188,241-245` ignores the generated architecture SVG and PNG, but the uncommitted rollback procedure finds created files using only `git status --short`. Ignored outputs do not appear there, so rollback can leave generated diagram files behind. Include an explicit path check and manual removal for those two ignored outputs; keep the no-tree-wide-clean rule.
3. `docs/plans/0036-generated-art-and-architecture-diagram.md:157-165` directs a live `git push` from a throwaway branch without specifying a local test remote or confirming that the branch cannot be published to the project remote. Cleanup only says “Delete the throwaway branch,” which does not say whether to remove a remote branch. Bound the test push to an isolated local remote (or otherwise explicitly scope the remote effect) and state local and remote cleanup before this is safe to execute.

## Checks

### PRD acceptance criteria

| Criterion | Result | Task and validation |
|---|---|---|
| Shared Macchiato palette; mismatch fails | Met | Task 1 checks Alacritty theme and altered value (`:46-51`). |
| Four generators use Python standard library | Met | Tasks 4–7; Task 20 compiles modules (`:67-83`, `:149-151`). |
| Every generated SVG gets same-name PNG after it | Met | Task 3 renderer and Tasks 4–7 validate pair creation/dimensions (`:60-83`). Docs CI `--no-png` is architecture-approved. |
| README uses SVG banner with PNG beside it | Met | Tasks 15–16 validate image path and outputs (`:130-138`). |
| No glow and shared lavender/blue treatment | Met | Tasks 4–6 (`:67-78`). |
| Social names platforms and uses repository numbers | Met | Task 6 (`:75-78`). |
| Byte-identical SVGs on repeated same-state runs | Met | Tasks 5–7 (`:71-83`); cross-version/locale run is absent. |
| Build, read-only check, logo-only tasks listed | Met | Tasks 8 and 10 (`:84-104`). |
| PR CI freshness check needs neither `rsvg-convert` nor `task` | Met | Task 13 calls script directly; docs invocation uses `--no-png` (`:119-124`). |
| Claude reminder before commit/push/PR; command can proceed | Partial | Tasks 12 and 21 cover synthetic/live behavior (`:110-118`, `:157-165`), but hook range endpoints are underspecified. |
| Opt-in terminal hooks remind only when relevant | Met | Tasks 9, 11 and 21 (`:91-109`, `:157-165`). |
| Both mechanisms are read-only and fail silently | Met | Tasks 9, 11–12 and Safety Checks (`:91-118`, `:212-214`). |
| Hook setup previews local config and guide explains disable | Met | Tasks 10 and 18 (`:98-104`, `:142-146`). |
| `ship-change` has pre-commit/push/PR check | Met | Task 19 (`:147-148`). |
| Diagram generated in docs build and strict site build passes | Partial | Tasks 13 and 15 build and publish the diagram; no task runs `mkdocs build --strict`, only post-merge run is deferred (`:119-134`, `:237`). |
| Optional librsvg in platform lists and doctor | Met | Task 14 (`:125-129`). |
| Guide and ADR cover workflow, pairing, no CI commits, manual markers | Met | Tasks 17–18 (`:139-146`). |
| MkDocs logo/favicon and all referenced images resolve | Met | Task 15 includes path validation (`:130-134`). |
| No secrets, usernames, machine-specific paths | Met | Task 20 privacy audit and Safety Checks (`:149-151`, `:217-218`, `:234`). |

### Other checks

| Check | Result | Evidence |
|---|---|---|
| Architecture decisions 1–12 implemented without contradiction | Met, with ordering defect | Decision 1 Python package: Tasks 1–8. Decision 2 deterministic file facts/no task runtime: Task 2. Decision 3 committed art/ignored build-time diagram: Tasks 13 and 16. Decision 4 sidecars/atomic writes/optional renderer: Task 3 and Tasks 4–7. Decision 5 SVG-only CI freshness: Task 13. Decision 6 shared palette check: Task 1. Decision 7 centralized read-only reminder: Task 9. Decision 8 Claude show-and-continue hook/fallback: Task 12 and Task 21. Decision 9 opt-in Git hooks/local config: Tasks 10–11 and 21. Decision 10 ship-change: Task 19. Decision 11 website and README: Task 15. Decision 12 platform package lists/doctor/guide: Tasks 14 and 18. Task 20's commit order nevertheless leaves generated facts stale; see Blocking Issue 1. |
| Safety, hooks, tests, and rollback | Fail | Plan confines hooks to reminder behavior and local `core.hooksPath` (`:207-220`); tests say hooks exit 0 and do not stage/regenerate/commit (`:212-214`). The live push is not bounded to an isolated remote (`:157-165`). Tracked test edits are to be restored (`:219-220`). Rollback forbids tree-wide `git clean` and limits manual deletion to individual paths (`:241-245`), but misses the ignored diagram outputs (Blocking Issue 2). |
| Cited repository facts and paths | Partial | All requested paths exist: `Taskfile.yml`, both workflows, `scripts/doctor.sh`, package guide and three package lists, `mkdocs.yml`, website scripts page, ship-change skill, ADR index, `.gitignore`, and `CHANGELOG.md`. Taskfile top-level task names are parseable by a simple rule: keys at two-space indentation beneath `tasks:`; current file has 32 task keys. First non-Unreleased heading is `## [2026.10] - 2026-10-20`. `.claude/settings.json` does not exist. Actual highest numbers: ADR 0081, review 0101, plan 0036. Plan assumption `:30` incorrectly says highest plan is 0035; `:31` correctly asks to check next ADR/review numbers. This is non-blocking. |
| Task ordering, independence, and four-commit partition | Fail | The commit list assigns build code and generated outputs to commit 1, but the ADR and guide whose counts feed generated facts to commit 4 (`:139-156`). Task 16 depends on Tasks 4–8 and 15, not Tasks 17–18 (`:135-138`). Thus output changes can be introduced after its validation and in a different commit. See Blocking Issue 1. Other tasks have stated dependencies where needed. |
| Risks omitted or under-validated | Partial | PNG/SVG pairing and optional `rsvg-convert` are covered (`:60-66`, `:125-129`). CI does not need a new tool: it invokes Python directly and uses `--no-png` for docs (`:119-124`). No Stow package is added, so the status-sync rule does not apply. Conventional Commit subjects are given for the four commits (`:152-156`) and planning commit (`:41-45`). Reminder behavior is covered by synthetic tests and a live test (`:91-118`, `:157-165`). Architecture identifies Python-version reproducibility as a risk and says the plan tests both (`docs/architecture/0028-generated-art-and-architecture-diagram-architecture.md:248-250`), but no task explicitly runs across Python versions or controls locale. The pre-existing global `rtk` hook is acknowledged in Architecture 0028 (`:188-190`); the plan does not add an interaction test, though the reminder does not rewrite commands. |
| Ambiguities for Builder | Partial | Task 12 says the Claude hook selects `--staged` or `--range` but does not define how it derives range endpoints for `git push`/`gh pr create` (`:113-115`); Architecture Decision 7 gives the command interface, not endpoint selection. Task 21 also leaves remote push and cleanup scope unspecified (`:159-165`; Blocking Issue 3). |

## Non-Blocking Suggestions

- Correct the stale highest-plan assumption at `docs/plans/0036-generated-art-and-architecture-diagram.md:30`.
- Specify how the Claude hook derives the range for push and pull-request commands at `:113-115`.
- Add explicit cross-Python-version and locale reproducibility validation, matching the architecture risk statement at `docs/architecture/0028-generated-art-and-architecture-diagram-architecture.md:248-250`.
- Add a local `mkdocs build --strict` validation task if the necessary environment is available, rather than relying only on the post-merge workflow (`:237`).

## Safety Verdict

FAIL — the live push target and remote cleanup are undefined, and rollback misses ignored generated diagram files.

## Privacy Verdict

PASS — no secret or private data is introduced by the plan; the planned privacy audit covers generated files and staged changes.

## Documentation Verdict

FAIL — the four-commit partition creates stale committed outputs, and the rollback procedure does not cover ignored diagram files.

## Recommended Next Action

Planner: fix Blocking Issues 1–3 and re-review Plan 0036. Keep the plan Draft; the user must explicitly approve it after a passing review. This review does not approve the plan.
