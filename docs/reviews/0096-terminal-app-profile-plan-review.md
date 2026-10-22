# Review: macOS Terminal.app Profile Plan

**Number:** 0096
**Status:** Complete
**Date:** 2026-10-22
**Plan reviewed:** [0035-terminal-app-profile](../plans/0035-terminal-app-profile.md) (Draft)
**PRD:** [0031-terminal-app-profile](../prd/0031-terminal-app-profile.md) (Approved)
**Architecture:** [0027-terminal-app-profile-architecture](../architecture/0027-terminal-app-profile-architecture.md) (Approved)
**Files reviewed:** `docs/plans/0035-terminal-app-profile.md`, PRD 0031, Architecture 0027, repository rules, and cited paths

## Summary

Strict plan review before approval. PRD acceptance coverage and architecture decisions were checked against the plan, including referenced repository files. Plan 0035 is not ready for operator approval. Repository numbering is ADR 0080 and review 0095; review 0096 is the next review number.

## Blocking Issues

1. `docs/plans/0035-terminal-app-profile.md:54-57` lets any `TERMINAL_SYNC_DOMAIN` value disable both the running-Terminal guard and backup. Setting it to `com.apple.Terminal` therefore permits an unguarded live write with no backup, contrary to Architecture Decision 3 and 7 and PRD safety requirements. Restrict the override to a fixed scratch domain or preserve protections whenever the selected domain is live.
2. `docs/plans/0035-terminal-app-profile.md:38-44` and `:41-44` require reading “Clear Dark” but do not name a committed source or specify how to obtain the reference profile. A local live profile makes `--build` and its validation machine-dependent, despite Architecture Decision 5 defining `--build` as repository-only. State a committed fixture/source and compare against that, or make the one-time captured value explicit and no longer read local preferences during build.
3. `docs/plans/0035-terminal-app-profile.md:76-78` proposes adding a specific package fact to both status blocks. `.claude/rules/status-sync.md:14-16` forbids a hand-maintained per-package list and says the package directories are the source of truth. The proposed wording is also underspecified: no exact replacement text is supplied. Require only prose state (phase and stowed-vs-not) and leave package enumeration to the directories.
4. `docs/plans/0035-terminal-app-profile.md:140-146` does not provide a safe, complete rollback sequence for repository work: it suggests `git reset HEAD~1` without establishing one commit, and `git clean -n` only previews deletions but does not perform the rollback. It also says after-merge PR revert without naming the exact revert mechanism. Specify a reviewable rollback for the expected multi-commit/working-tree state; keep destructive commands as manual steps. The user’s live-profile rollback is separately described, but Task 7 only prints previous default values and does not specify how to restore them if the profile is removed.

## Checks

| Check | Result | Evidence |
|---|---|---|
| PRD acceptance criteria each map to a plan task and validation | Partial | Profile, font, palette and plist: Tasks 3–4; deploy/report/default/idempotence/platform guard: Tasks 2, 5–10; guide/site/Stow/status/privacy/CI: Tasks 1, 11–15 and completion criteria. PRD 0031:85-111. Gap: PRD 0031:107-108 requires documented Stow behavior, but Task 1 only says create ignore and README; it does not require documenting the package’s ignored behavior in the README or validate the package tree/documentation. Task 13 covers `docs/stow-usage.md`, but does not explicitly validate it. |
| Architecture decisions 1–8 are represented without contradiction | Partial | Tasks 1, 5–10 cover Task not Stow, `defaults`, running-app refusal, separate default flag, committed generated profile, selection exception, backup and OS guard. Architecture 0027:56-147. The unrestricted domain override weakens decisions 3 and 7. `--build` reading a local “Clear Dark” profile conflicts with repository-only/reproducible build (Architecture 0027:106-127; Plan 0035:35-44). |
| Safety: live preference, home, `open`, Stow | Fail | Plan 0035:48-57 explicitly adds a bypassable guard/backup. Task 6 intentionally writes the live `com.apple.Terminal` domain only under user `--apply`; Task 17 labels deployment manual, and validation only uses `com.example.terminal-sync-test` at :60-64. No validation command runs `open`; Stow appears only with `--simulate` at :29-31 and :127. Safety Checks :115-121 incorrectly say no command writes under `$HOME`, although the planned live backup is next to the preferences file at :48-50. Reconcile this statement with the permitted user-only preferences write and ensure no agent/test writes there. |
| Scratch-domain isolation and rollback | Fail | Hardcoded test domain in Task 10 is distinct from `com.apple.Terminal`, but Task 8’s arbitrary override can select the live domain and disable safeguards (:54-64). Scratch domain deletion is scoped by name. Live rollback references a timestamped backup at :144-146, but gives no exact restore command there; Architecture requires `defaults import` and a manual guide step (0027:136-141). Repository rollback limitations are listed above. |
| Cited files exist; reported numbering is current | Met | `Taskfile.yml`, `scripts/codex-sync.sh`, `scripts/detect-os.sh`, all three `website/features/*.md` pages, `docs/stow-usage.md`, `docs/decisions/README.md`, and `.github/workflows/docs.yml` exist. Numbered decision files include `docs/decisions/0080-agent-token-tooling-and-shared-skills-directory.md`, so highest ADR is 0080, not 0068 as Plan 0035:23 says. Highest review is 0095. Task 11 correctly requires confirming the next free ADR number. |
| Order and task sizing | Partial | Package/script/build precede profile validation and sync; Task/guide/site/status and final review follow implementation. But Task 5 precedes Task 6 while reporting requires live profile state, and Task 10 depends on finished Tasks 5–8, which is implicit rather than stated. Tasks 3–4 rely on the unspecified Clear Dark source. Task 15 audits a “staged diff” while the plan lists no staging task. |
| Status-sync rule and proposed wording | Fail | `.claude/rules/status-sync.md:11-16` requires both blocks in the same commit, says they are prose-only, and prohibits hand-maintained package lists. Task 14’s specific “a macOS `terminal` package exists ...” is per-package status prose and conflicts with that rule (:76-78). Both blocks must remain consistent (rule :13). |
| Cross-platform scope and guard | Partial | PRD 0031:50, 55-57, 110 and Architecture 0027:143-147 require macOS-only behavior and no Arch/Debian edits. Task 2 plans the shared detector and Task 10 a fake non-macOS result. `scripts/detect-os.sh:14-22` returns `macos`, `arch`, `debian`, or unsupported; no Arch/Debian file is in the plan’s affected list. The planned guard must run before any preference read, but Task 2 does not explicitly validate the missing `defaults`/domain cases required by Architecture 0027:145-147. |
| Builder ambiguities | Fail | In addition to the Clear Dark source and status wording: Task 6 does not define the exact live preferences file resolution for backup; Architecture 0027:138-141 requires backup outside the repo following `codex-sync.sh`, whose backup is adjacent to its live file (`scripts/codex-sync.sh:219-223`). Task 8 does not define allowed override values. Task 10’s “other keys intact” does not specify seeding or asserting a pre-existing unrelated key. Task 12 says add to “any guide index” without identifying the index. Task 13 makes package-page inclusion conditional without specifying the page’s actual criterion. |

## Non-Blocking Suggestions

1. Plan 0035:23 says highest ADR is 0068, but 0080 exists. The explicit next-number confirmation in Task 11 limits the impact; update the stale assumption.
2. Plan 0035:41-44 checks selection against `#5b6078`, while PRD 0031:88-89 says selection matches Macchiato values. Architecture Decision 6 explains the deliberate Surface2 exception (0027:129-134); explicitly record this exception against the PRD criterion in the validation result.
3. User deployment at Task 17 is necessary to verify glyph rendering and real colors, but it is outside agent validation. Keep it as a post-build manual acceptance step, not a prerequisite for a reviewer to validate generated artifacts.

## Safety Verdict

FAIL — domain override can bypass the live-app guard and backup; safety statement conflicts with the planned live backup. See Blocking Issues 1 and 4.

## Privacy Verdict

PASS — planned committed profile data is palette, font and profile name. Backup is outside the repository. The privacy audit is planned, though its staged-diff prerequisite needs clarification under task sizing.

## Documentation Verdict

FAIL — status-block wording contradicts the active status-sync rule, and the plan leaves rollback and source/validation instructions ambiguous. See Blocking Issues 2–4.

## Recommended Next Action

Planner: revise the four blocking items, update the stale ADR assumption and make validation requirements explicit. Operator: review the revised Plan 0035 and explicitly approve it before build work. This review does not approve the plan.
