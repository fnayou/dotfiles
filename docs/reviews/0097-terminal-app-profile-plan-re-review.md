# Review: macOS Terminal.app Profile Plan Re-review

**Number:** 0097
**Status:** Complete
**Date:** 2026-10-22
**Plan reviewed:** [0035-terminal-app-profile](../plans/0035-terminal-app-profile.md) (Draft)
**Previous review:** [0096](0096-terminal-app-profile-plan-review.md)
**PRD:** [0031-terminal-app-profile](../prd/0031-terminal-app-profile.md) (Approved)
**Architecture:** [0027-terminal-app-profile-architecture](../architecture/0027-terminal-app-profile-architecture.md) (Approved)
**Files reviewed:** Revised Plan 0035, PRD 0031, Architecture 0027, review 0096, cited repository rules and paths.

## Summary

Strict re-review of revised Plan 0035 against review 0096, PRD 0031, Architecture 0027, and repository facts. Plan 0035 remains Draft and is not ready for approval. Two prior blockers remain unresolved or partial, and the revision adds a live-domain validation ambiguity and an unsafe uncommitted rollback instruction.

## Blocking Issues

1. `docs/plans/0035-terminal-app-profile.md:87-91` asks validation to check `TERMINAL_SYNC_DOMAIN=com.apple.Terminal` “as specified in Task 8” but does not constrain that check to read-only/report behavior or prove that `--apply` is never invoked. Task 8 expressly accepts the live domain and permits writes there with the guard and backup. Task 10's heading says “without touching the live domain,” but this is not an executable constraint on each check. Specify a read-only live-domain assertion and explicitly prohibit live-domain `--apply` and `--set-default` during agent/test validation.
2. `docs/plans/0035-terminal-app-profile.md:180-183` tells the Builder to `git restore` each modified file in an uncommitted rollback. The plan's assumptions say PRD, architecture, plan, and review 0096 are already uncommitted (`:17-18`); those are included among the modified files (`:138-140`). Restoring them would erase pre-existing work. Limit rollback to changes made by this plan, preserving the pre-existing diff, and spell out a safe method for distinguishing those edits.
3. `docs/plans/0035-terminal-app-profile.md:106-110` still prescribes adding a package-specific fact about the Terminal.app profile to both status blocks. The clause names a specific `stow/macos/` profile and its deployment mechanism. `.claude/rules/status-sync.md:11-16` permits prose state only and forbids reintroducing hand-maintained per-package lists. The claim that this clause is prose does not resolve the conflict. Update only phase and aggregate stowed-vs-not state, with package directories remaining the source of truth.

## Resolution of Review 0096 Findings

| Previous finding | Status | Plan evidence and reasoning |
|---|---|---|
| Blocking 1 — override could bypass live guard and backup | Partially resolved | Task 8 now limits accepted domains to `com.apple.Terminal` or `com.example.terminal-sync-test*` and explicitly keeps the guard and backup for the live domain (`:75-80`). That resolves the described arbitrary-domain bypass. But Task 10 does not state that its live-domain check is read-only and forbids `--apply`; see Blocking Issue 1. |
| Blocking 2 — `--build` depended on local “Clear Dark” profile | Resolved | Assumptions make `ProfileCurrentVersion` a committed constant captured once and state the build never reads local preferences (`:22-23`). Task 3 says `--build` reads no preference domain and writes only in the repo (`:49-54`). Task 4 makes the live profile comparison optional, validation-only, and read-only (`:55-61`). |
| Blocking 3 — status wording contradicted status-sync rule | Not resolved | Task 14 still requires a package-specific Terminal.app status clause in both blocks (`:106-110`). The status-sync rule bars per-package status lists (`.claude/rules/status-sync.md:14-16`). |
| Blocking 4 — repository/live rollback incomplete or unsafe | Partially resolved | Rollback now separates uncommitted, committed-not-pushed, merged, and live preference states, and documents `defaults import` (`:178-199`). However, the uncommitted rollback would restore pre-existing PRD/architecture/plan/review edits from the branch assumptions (`:17-18`, `:138-140`, `:180-183`), and default restoration does not address previously absent values (`:72-74`, `:197-199`). See Blocking Issue 2. |
| Non-blocking 1 — stale ADR number | Resolved | Plan states highest ADR 0080 and directs the Builder to confirm the next free number (`:24-25`). Read-only listing confirms ADR 0080 is highest. |
| Non-blocking 2 — selection exception should be recorded against PRD | Resolved | Task 4 explicitly records Surface2 as a deliberate exception to PRD 0031's palette criterion (`:58-61`), and completion criteria repeat the documented exception (`:203-206`). |
| Non-blocking 3 — manual deployment is post-build acceptance | Resolved | Task 17 places deployment after review and says it is user acceptance, not a Reviewer prerequisite (`:116-118`). |

## Checks

| Check | Result | Evidence |
|---|---|---|
| PRD acceptance criteria map to tasks, including conditional package-page criterion | Partial | Tasks 1–15 and completion criteria cover profile, script, deployment, docs, status, safety, and CI (`:39-115`, `:201-218`). `website/features/packages.md` describes a collection of Stow packages, and its entries describe stowed package content; the Terminal profile is deliberately not stowed (`:28-31`, `:101-105`; `docs/stow-usage.md` package tree). Thus the plan's determination not to list the profile there satisfies PRD 0031's “if it belongs there” condition. However, Task 10 has the live-domain execution ambiguity in Blocking Issue 1, and rollback has the issue above. |
| Architecture decisions 1–8 represented without contradiction | Partial | Tasks 1–10 cover Task deployment, `defaults`, running-app guard, opt-in default, repo-only build, selection exception, backup, and platform guard (`:39-91`). Task 10 does not tightly bound the live-domain check as read-only. Task 14 conflicts with the status rule, not Architecture. |
| Safety: live preference, home, `open`, Stow | Fail | Task 10's live-domain check is not constrained against live writes (`:87-91`). Task 6 explicitly plans a live backup under `$HOME` on user `--apply` (`:66-71`), and Safety Checks correctly acknowledges this user-only write (`:151-160`). Stow validation is simulate-only (`:42-43`, `:167`); the plan prohibits agent `open` and live apply in its assumptions (`:32-33`), but Task 10 fails to constrain its live-domain test. |
| Scratch-domain isolation and rollback | Fail | Scratch testing seeds unrelated state and scopes deletion to the test domain (`:83-91`). Live guard/backup protections are explicit (`:75-80`). Uncommitted rollback can discard pre-existing uncommitted work (`:17-18`, `:138-140`, `:180-183`). Previous default values are printed with restore commands, but no behavior is specified when a previous key is absent (`:72-74`, `:197-199`). |
| Cited repository facts | Met with caveats | README line 45 is the Ghostty package table row; line 62 is the guide-list row and currently lists guides through zsh. `docs/stow-usage.md` tree currently lists common packages and only Ghostty under macOS; Task 13 adds the planned terminal directory (`:101-105`). `website/features/packages.md` describes Stow packages and details package contents. `scripts/codex-sync.sh:219-223` creates backup adjacent to its live file. Highest ADR is 0080. `AGENTS.md:28` says all common packages plus macOS Ghostty are stowed. `CLAUDE.md:11` says all common packages and macOS Ghostty are stowed, then points to package directories as source of truth. Task 14's proposed named-profile clause would add package-specific status to both documents (`:106-110`). |
| Order, dependencies, and scope | Partial | Task order and dependencies are stated (`:37-118`). Task 15 says to stage exactly the Files Affected list (`:111-113`), but Files Affected includes already-written PRD, architecture, plan and review 0096 as “committed with the work” (`:138-140`) while assumptions say they are currently uncommitted (`:17-18`). This is an unresolved state contradiction and makes the staging direction unsafe. |
| Status-sync rule | Fail | Task 14 still requires adding named profile/deployment detail to both blocks (`:106-110`), which is package-specific status text under `.claude/rules/status-sync.md:11-16`. |
| Cross-platform scope and guard | Met | PRD and architecture require macOS-only behavior. Task 2 uses the repo OS detector before preference reads (`:44-48`), and Task 10 checks a faked non-macOS result (`:87-90`). Files Affected adds no Arch/Debian paths (`:120-142`). |
| Builder clarity | Partial | The Clear Dark build input, domain allowlist, seeded unrelated state, and guide index ambiguities from review 0096 are addressed (`:22-23`, `:75-80`, `:83-91`, `:95-100`). Remaining ambiguities: live-domain validation mode (`:87-91`), rollback of pre-existing changes (`:180-183`), package-specific status wording (`:106-110`), and absent prior default values (`:72-74`). |

## Non-Blocking Suggestions

1. Task 7 should specify handling when `Default Window Settings` or `Startup Window Settings` was absent, so the restore instructions remain exact in that case (`:72-74`, `:197-199`).
2. Task 15's staging instruction should distinguish current uncommitted PRD/architecture/plan/review work from changes introduced during the plan (`:17-18`, `:111-113`, `:138-140`). This also bears on the blocking rollback issue.
3. Task 12's references to README lines 45 and 62 are line-sensitive and will shift as README content changes (`:99-100`); identify the package table and guide list by section instead.

## Safety Verdict

FAIL — Task 10 does not guarantee read-only behavior for its live-domain check (`docs/plans/0035-terminal-app-profile.md:87-91`); uncommitted rollback can erase pre-existing work (`:180-183`).

## Privacy Verdict

PASS — the plan limits committed profile data to palette/font/profile content and requires auditing for secrets, usernames, and machine-specific paths (`:49-54`, `:160`, `:216`). No new privacy issue found in the plan text.

## Documentation Verdict

FAIL — Task 14's package-specific status clause conflicts with the status-sync rule (`docs/plans/0035-terminal-app-profile.md:106-110`), and rollback instructions risk removing pre-existing work (`:180-183`).

## Recommended Next Action

Planner: address Blocking Issues 1–3 and reconcile the uncommitted/staging state. The PRD website criterion is satisfied: the package page is for Stow packages, while this profile is deliberately not stowed. Operator: review the revised Plan 0035 and explicitly approve it before build work. This review does not approve the plan.
