# Review: macOS Terminal.app Profile Plan Fourth Review

**Number:** 0099
**Status:** Complete
**Date:** 2026-10-22
**Plan reviewed:** [0035-terminal-app-profile](../plans/0035-terminal-app-profile.md) (Draft)
**Previous review:** [0098](0098-terminal-app-profile-plan-third-review.md)
**PRD:** [0031-terminal-app-profile](../prd/0031-terminal-app-profile.md) (Approved)
**Architecture:** [0027-terminal-app-profile-architecture](../architecture/0027-terminal-app-profile-architecture.md) (Approved)
**Files reviewed:** Revised Plan 0035, PRD 0031, Architecture 0027, reviews 0097 and 0098, status-sync and safety rules, lifecycle and reviewer guidance, and status blocks.

## Summary

Strict fourth review of Plan 0035. Review 0098's Task 14 wording issue is resolved. One new blocking issue remains: Task 14 does not require the status-block updates and package addition to land in the same commit, as PRD 0031 requires. Plan 0035 remains Draft and is not approved by this review.

## Blocking Issues

1. `docs/plans/0035-terminal-app-profile.md:118-124` says to update both status blocks “In the same change,” but does not require the update in the same commit as adding the `stow/macos/terminal/` package. PRD 0031 requires both status blocks to be updated “in the same commit” (`docs/prd/0031-terminal-app-profile.md:109`). Task 15 stages the Files Affected list but does not specify a commit boundary for the build changes (`:125-128`). Require the package addition and both status-block updates in one commit.

## Resolution of Review 0098 Finding

| Review 0098 finding | Status | Plan evidence and reasoning |
|---|---|---|
| Blocking — Task 14 status-block clause exceeded status-sync scope | Resolved | Task 14 now appends only `; other stow/macos/ packages are not stowed` (`:118-124`). It names no individual package and adds no deployment detail. The clause describes aggregate stowed-vs-not state, which `.claude/rules/status-sync.md` permits. AGENTS.md §2 currently says all common packages and `stow/macos/ghostty` are stowed; appending the clause reads correctly and is true with the current macOS package directory set, which contains only `ghostty`. In CLAUDE.md, it reads correctly after the ghostty sentence and is true for that same state. The clause preserves the PRD requirement to update both blocks, but the same-commit requirement remains blocking as listed above. |

## Checks

| Check | Result | Evidence |
|---|---|---|
| Resolution of review 0098 | Met, with commit-boundary caveat | Task 14 clause is aggregate status text and conforms to status-sync's prose-only rule (`.claude/rules/status-sync.md:11-16`; plan `:118-124`). Current AGENTS.md and CLAUDE.md statements support the clause; `stow/macos/` currently has only `ghostty`. |
| PRD acceptance criteria mapped to tasks | Partial | Tasks cover profile creation, verified font, palette validation and documented selection exception, dry-run/apply/default behavior, platform guard, guide, website, package docs, status blocks, and privacy (`:47-124`, `:216-233`). The same-commit criterion is not explicit; see Blocking Issue 1. Website packages page is conditionally unchanged under the stated rationale (`:29-32`, `:113-117`). |
| Architecture decisions 1–8 | Met | Tasks cover Task rather than Stow deployment, `defaults` writes without `open`, running-app guard, separate default flag, committed build source, Surface2 selection exception, backup, and macOS guard (`:47-103`). |
| Task order, Files Affected, and rollback consistency | Met | Task 0 isolates the planning documents in a prior commit (`:40-46`); Files Affected distinguishes those from build outputs (`:135-157`); rollback scopes uncommitted work to the clean post-Task-0 tree and preserves planning documents (`:194-202`). Task 14's commit boundary is the sole exception, above. |
| Safety and live-system boundaries | Met | Agent/test live-domain operations are constrained to read-only report and invalid-domain rejection; live writes are reserved for the user's marked manual deployment (`:33-34`, `:93-103`, `:165-175`). Stow validation uses `--simulate` (`:50-51`, `:179-182`). |
| Stale facts and references | Met | Review references run through 0098 (`:8`, `:25`); ADR numbering is checked before use (`:25-26`); dynamic ADR and implementation-review names are explicit (`:143-144`). Cited paths and profile names are consistent with PRD and architecture. |
| Cross-platform and privacy scope | Met | The work is contained in macOS paths, uses the repository OS detector, and audits staged changes for secrets, usernames, and absolute home paths (`:52-55`, `:159-175`). |

## Non-Blocking Suggestions

None.

## Safety Verdict

PASS — live writes are constrained to user-run manual deployment; validation uses the scratch domain.

## Privacy Verdict

PASS — the plan requires a privacy audit and introduces no secret or machine-specific data.

## Documentation Verdict

FAIL — Task 14 does not require the status updates in the same commit as the package addition (`:118-124`).

## Recommended Next Action

Planner: state that adding `stow/macos/terminal/` and updating both status blocks happen in the same commit. Reviewer: re-review the revised plan. Operator: explicitly approve Plan 0035 only after a passing review. This review does not approve the plan.
