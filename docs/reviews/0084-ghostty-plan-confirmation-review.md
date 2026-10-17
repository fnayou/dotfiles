# Review: Ghostty Configuration Plan (Confirmation)

**Number:** 0084
**Status:** Complete
**Date:** 2026-10-17
**Documents reviewed:**
- `docs/plans/0031-implement-ghostty-configuration.md`

## Summary

Confirmation review of commit `08e4faa` ("docs(plans): resolve review 0083 findings for plan
0031") against the findings of review 0083. Scope is the `08e4faa` diff and the 0083 items only;
unchanged content was not re-reviewed. Ghostty was not run and no plan command was executed during
this review. No plan is completed by this review; Plan 0031 stays Draft (`:4`).

The diff changes only Plan 0031 (154 insertions, 37 deletions). It adds `# macOS` labels, replaces
every `revert --no-edit` with `revert --no-commit` plus a Conventional Commits message, repeats
`REPO="$(git rev-parse --show-toplevel)"` in each block that uses it, adds read-only Application
Support and `codesign` checks, marks the `git restore --` rollbacks, and ties the Repository checks
to the commit tasks.

Both blocking issues and all ten suggestions of review 0083 are resolved. The diff introduces no
blocking issue. Two small correctness points in the new checks are listed as suggestions.

## Review 0083 Item Resolution

- **B1 (macOS-only blocks unlabelled; check 3 step 2 labelled as the Arch case): Resolved.** `# macOS`
  is the first line of the Task 1 preflight (`:71`), the Task 8 icon copy (`:217`), checks 1 and 2
  (`:831`), and the Task 23 read-only check (`:662`). Check 3 step 2 now reads
  `# macOS — Step 2: common package only (simulates the Arch layout)` (`:865`). The two new
  read-only blocks are labelled too (`:93`, `:699`).
- **B2 (after-commit rollbacks break Conventional Commits): Resolved.** Tasks 17 (`:479-483`), 19
  (`:528-532`), 21 (`:610-614`), 24 (`:717-721`), and 25 (`:751-755`) now use
  `git -C "$REPO" revert --no-commit <sha>` followed by a `revert(<scope>): <description>` subject
  and a `Refs: <sha>` footer. The Rollback Strategy (`:1016-1020`) states the same form and forbids
  `revert --no-edit`. Every new subject matches `<type>[optional scope][!]: <description>`; `revert`
  is an allowed type. No `revert --no-edit` remains in the plan.
- **S1 (Task 12 `PASS:` with no window): Resolved.** The block ends with
  `DONE: fake-home launch session ended` (`:311`). Answer 0 asks whether a window opened and stops
  the task if not (`:317-318`); Expected requires "yes" (`:328-330`). The prose explains the
  unverified launch, warns against `open -na … --env`, and says to run from Alacritty or
  Terminal.app (`:287-293`).
- **S2 (Task 14 repeats Task 13 alone): Resolved.** "re-run Task 12, then Task 13 for the changed
  keys", with the reason (`:378-380`).
- **S3 (no evidence for the Application Support file and app bundle): Resolved.** Read-only
  `wc -c` and `codesign --verify --deep --strict` checks in Task 1 (`:90-98`) and in Task 24 before
  the review (`:695-704`); both outputs are recorded in the implementation review (`:708-709`). See
  suggestion 1.
- **S4 (implementation review number): Resolved.** Task 24 expects `0085`, since `0084` is this
  review (`:690-692`). This file is `0084`, so the number is correct.
- **S5 (Repository checks not tied to a task): Resolved.** Run in Tasks 17 (`:463`), 19 (`:515`),
  and 21 (`:596`), stated in the section (`:993`); `PASS: no whitespace errors` is in the Task 17
  Expected (`:474`). See suggestion 2.
- **S6 (Task 25 without staged review and approval): Resolved.** `git diff --staged --stat` and
  `git diff --staged` (`:733-734`), the privacy checklist, the status-sync self-check naming the
  "first stowed" event, and operator approval before the commit (`:737-740`).
- **S7 (unmarked `git restore --` rollbacks; `website/` directory restore): Resolved.** The marker
  sits on the line directly above the fence in Tasks 15 (`:406`), 16 (`:445`), and 20 (`:578`).
  Task 20 restores an explicit list (`:581-585`) that matches the twelve files listed in Task 20
  (`:538-555`). The Rollback Strategy requires the marker and explicit files (`:1013-1015`).
- **S8 (markers in `docs/stow-usage.md`): Resolved.** Task 20 requires the marker above every install
  and `stow --delete` fence in both `docs/stow-usage.md` and `website/features/terminal.md`
  (`:561-562`), checked by `grep -B1 -n '^```bash'` (`:567`, Expected `:572-573`).
- **S9 (`REPO` set only in Task 1): Resolved.** The Assumptions say every block that uses `$REPO`
  repeats the line (`:31-32`), and every fenced block that uses `$REPO` now starts with it (`:72`,
  `:120`, `:126`, `:408`, `:447`, `:456`, `:468`, `:480`, `:510`, `:519`, `:529`, `:580`, `:591`,
  `:600`, `:611`, `:718`, `:731`, `:743`, `:752`, `:996`).
- **S10 (`Taskfile.yml:67` stale): Resolved.** Task 24 records it as a follow-up and states the plan
  does not change `Taskfile.yml` (`:711-713`).

## Blocking Issues

None.

## Non-Blocking Suggestions

1. The new `wc -c < "…/config.ghostty"` checks (`:94`, `:700`) expect `0`, but macOS `wc` pads its
   output with leading spaces (`       0`). A Builder who compares literally, as the plan requires
   (`:63-64`), sees a mismatch. Check 6 already strips the padding (`:975`). Use
   `wc -c < "…" | tr -d ' '`, or write the Expected as "the number `0` (macOS `wc` pads it with
   spaces)".
2. The Repository checks are now run before each commit (`:993`), but their Expected (`:1003-1004`)
   says "the commits of Tasks 17, 19, and 21 appear in order". Before the Task 17 commit none of
   them exists, and before the Task 19 commit only the first does. A Builder who stops at the first
   mismatch (`:63-64`) stops at Task 17. Also, after `git add`, `git diff --check` compares only
   unstaged changes, so it prints `PASS:` without checking the staged files; Task 17 has its own
   `diff --staged --check` (`:460`), Tasks 19 and 21 do not. Reword the Expected to "the commits
   made so far by Tasks 17, 19, and 21 appear in order", and use `git -C "$REPO" diff --staged
   --check` in the Repository checks (or add it to Tasks 19 and 21).
3. Task 21 still stages `website/` as a directory (`:592`), while Task 20 now restores an explicit
   list so that unrelated `website/` edits are not touched (`:575-576`). The Task 21 Expected
   ("only the files listed in Task 20 are staged") catches an extra file, but staging the same
   explicit list would match the new rationale.

## Safety Verdict

PASS — the diff adds only read-only checks (`wc -c`, `codesign --verify`, `git diff --staged`) and
replaces rollback commands with non-destructive `revert --no-commit` plus a new commit. No write to
`$HOME`, no `stow` against `$HOME`, no `--adopt`, no `rm`/`mv`/`ln -s` outside the fake home, no
`git reset --hard`, no force push, push, or merge. The Task 20 rollback now names explicit files,
so it no longer discards unrelated `website/` edits. The Task 12 change keeps the `trap` and
explicitly rejects `open -na`, which would delete the fake home early.

## Privacy Verdict

PASS — the diff adds no secrets, hostnames, or user-specific paths. New paths use `$HOME`,
`/Applications/Ghostty.app`, and `<sha>` placeholders. Task 25 now runs the privacy checklist on its
staged diff.

## Documentation Verdict

PASS — the three new `⚠️  MANUAL STEP — review before running` markers (`:406`, `:445`, `:578`) sit
on the line directly above their fences. The new blocks are copy-pasteable from the repository root
in a shell that keeps no variables. All new commit subjects, including the five revert subjects,
follow Conventional Commits; commit `08e4faa` itself follows it. Suggestions 1 and 2 are
Expected-wording fixes, not unsafe commands.

## Cross-Platform Verdict

PASS — every non-portable block named in review 0083 B1 now carries `# macOS` on its first line,
and check 3 step 2 is described as the Arch layout simulated on macOS. The new `codesign` and
Application Support checks are labelled `# macOS`. The revert, `REPO`, and Repository-check blocks
use only `git` and `task` and are portable.

## Recommended Next Action

Operator: review Plan 0031 and approve it explicitly; it stays Draft until then. Suggestions 1 to 3
can be folded in by the Planner before approval or applied by the Builder at the affected tasks;
they do not need another review. After approval, the Builder starts at Task 1.
