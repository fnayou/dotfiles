# Review: macOS Terminal.app Profile Plan Third Review

**Number:** 0098
**Status:** Complete
**Date:** 2026-10-22
**Plan reviewed:** [0035-terminal-app-profile](../plans/0035-terminal-app-profile.md) (Draft)
**Previous review:** [0097](0097-terminal-app-profile-plan-re-review.md)
**PRD:** [0031-terminal-app-profile](../prd/0031-terminal-app-profile.md) (Approved)
**Architecture:** [0027-terminal-app-profile-architecture](../architecture/0027-terminal-app-profile-architecture.md) (Approved)
**Files reviewed:** Revised Plan 0035, PRD 0031, Architecture 0027, reviews 0096 and 0097, and cited repository rules.

## Summary

Strict third review of Plan 0035. All three blocking issues from review 0097 are resolved. The prior three non-blocking suggestions are resolved. One new blocking issue remains: Task 14's status-block clause still describes deployment behavior, which exceeds the status-sync rule's allowed phase and stowed-vs-not prose. Plan 0035 remains Draft and is not approved by this review.

## Blocking Issues

1. `docs/plans/0035-terminal-app-profile.md:118-124` requires adding a clause that explains ignored-file behavior and deployment by a Task to both status blocks. `.claude/rules/status-sync.md:11-16` limits those blocks to phase and stowed-vs-not prose and directs them to leave package/deployment details to package directories. The clause names no package, but still adds implementation/deployment behavior to tracked status prose. Revise the block update to state only the applicable phase and stowed-vs-not status, while retaining the PRD requirement that both blocks change in the same commit.

## Resolution of Review 0097 Findings

| Review 0097 finding | Status | Plan evidence and reasoning |
|---|---|---|
| Blocking 1 — live-domain check could perform a write | Resolved | Task 10 now limits the live-domain check to default report mode and invalid-domain rejection, and explicitly prohibits agent/test `--apply` and `--set-default` against `com.apple.Terminal` (`:97-100`). Task 8 preserves guard and backup for the live domain (`:85-90`). |
| Blocking 2 — uncommitted rollback could erase pre-existing work | Resolved | Assumptions put the planning documents in a separate Task 0 commit and say later rollback concerns only build work (`:17-20`). Files Affected identifies those planning documents as committed in Task 0 (`:153-155`); rollback limits restore/delete steps to build changes and explicitly protects the planning documents (`:194-198`). |
| Blocking 3 — package-specific status clause conflicts with status-sync | Partially resolved | Task 14 removes the package name and avoids a per-package list (`:118-124`), but the new clause still describes ignored-file and deployment behavior, beyond status-sync's phase and stowed-vs-not scope. See Blocking Issue 1. |
| Non-blocking 1 — restore defaults when prior keys were absent | Resolved | Task 7 now requires printing `defaults delete` restore commands for absent keys, rather than `defaults write` (`:80-84`). |
| Non-blocking 2 — staging must separate prior work from plan changes | Resolved | Task 0 stages an explicit list of planning documents (`:40-46`); Files Affected names the same documents as the Task 0 commit (`:153-155`); Task 15 says they are not restaged (`:125-128`). |
| Non-blocking 3 — README line-number references are fragile | Resolved | Task 12 refers to the package table and “Per-package setup guides” list by section, and uses the Ghostty row as a model (`:107-112`). It no longer depends on README line numbers. |

## Checks

| Check | Result | Evidence |
|---|---|---|
| New Task 0 commit: message, file list, workflow | Partial | `docs(plans): add Terminal.app profile PRD, architecture and plan` follows Conventional Commits syntax (`:40-46`). The list matches Files Affected's planning-document list (`:40-46`, `:153-155`), and requires explicit user plan approval first (`:20`, `:42-43`). It does not override the reviewer approval gate: this review must pass before the user approves and Task 0 runs. No commit may be made before reviewer approval under AGENTS.md §5 and §13. |
| Task 14 and PRD status-block acceptance | Fail | PRD 0031 requires both blocks updated in the same commit (`docs/prd/0031-terminal-app-profile.md:109`). Task 14 ensures both are changed together (`:118-124`), but its added deployment detail violates `.claude/rules/status-sync.md:11-16`. The criterion does not require that specific clause. |
| Task 10 live-domain isolation | Met | Task 10 explicitly restricts its live-domain check to read-only report and invalid-domain rejection and forbids live `--apply`/`--set-default` (`:93-103`). Task 8's guard and backup remain enabled for the live domain (`:85-90`). |
| Rollback and prior work | Met | Task 0 isolates planning docs in a prior commit; uncommitted rollback targets only build changes, preserves those planning docs, and avoids `git clean` (`:17-20`, `:194-202`). Live rollback uses the printed backup with `defaults import` and is marked manual (`:204-214`). |
| Safety, Files Affected, and Tasks consistency | Partial | Task 0 and Files Affected agree on the planning docs (`:40-46`, `:153-155`); the later task list is represented in Files Affected, and Safety Checks limit automated preference writes to the scratch domain (`:165-175`). However, Task 14 and Safety Checks claim the status clause complies with status-sync when it does not (`:118-124`, `:170-171`). |
| Privacy and cross-platform scope | Met | Plan restricts profile work to `stow/macos/`, uses the repository OS detector before preference reads, and calls for auditing secrets, usernames, and absolute paths (`:52-62`, `:159-175`). No plan text introduces a cross-platform package-manager mix or private data. |
| Rollback commit range | Met | Rollback calls for reverting the selected committed range and describes the repository's rebase merge practice (`:199-202`). This is a documented recovery step, not an automated action. |

## Non-Blocking Suggestions

None.

## Safety Verdict

PASS — live-domain validation is explicitly read-only, and rollback preserves pre-existing planning work.

## Privacy Verdict

PASS — the plan requires a privacy audit and specifies no secret or private machine data.

## Documentation Verdict

FAIL — Task 14 adds deployment detail to status blocks beyond the status-sync rule's allowed prose (`:118-124`).

## Recommended Next Action

Planner: revise Task 14 to keep status-block changes within phase and stowed-vs-not state. Reviewer: re-review the revised plan. Operator: explicitly approve Plan 0035 only after a passing review. This review does not approve the plan.
