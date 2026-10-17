# Review: Ghostty Follow-ups Plan (Re-review)

**Number:** 0087
**Status:** Complete
**Date:** 2026-10-17
**Documents reviewed:**
- `docs/plans/0032-ghostty-follow-ups.md` (staged revision)

## Summary

Re-review of the staged revision of Plan 0032 against the findings of review 0086. Scope is B1 and
suggestions 1 to 13; suggestion 14 is recorded as out of scope by the plan (`:262-267`). The
revision was read against `scripts/doctor.sh`, `Taskfile.yml:66-75`, `docs/guides/doctor.md`, and
the repository safety, privacy, Stow, status-sync, cross-platform, and documentation rules. No plan
command was executed during this review. No plan is completed by this review; Plan 0032 stays Draft
(`:4`), and `docs/plans/README.md:92` lists it as Draft.

B1 and all thirteen suggestions are resolved. The planner's correction of the lane caveat is
consistent with `scripts/doctor.sh:114-165`. The revision introduces no blocking issue. Four small
points in the new text are listed as suggestions.

## Lane Caveat Correction

Review 0086 B1 assumed that, run from the lane, doctor reports each package stowed from the primary
checkout as `link(s) point outside this repo` and exits `1`. The plan now says those packages show
as `SKIP: <pkg> (not stowed — …)` with exit `0` (`:29-32`, observed on 2026-10-17).

The correction is right; review 0086 misread the branch order. In this section, line numbers refer
to `scripts/doctor.sh`:

- Each link of such a package resolves into the primary checkout, not `"$REPO_ROOT"/*` (`:134`), so
  it increments `foreign` (`:137`) and never `linked`.
- With `linked` still `0`, the `elif [[ $linked -eq 0 ]]` branch (`:148`) fires before the
  missing/foreign branch and prints `skip "$pkg (not stowed — $managed file(s) available)"`
  (`:149`).
- The `fail "$pkg — $foreign link(s) point outside this repo"` line (`:160-161`) is reachable only
  when at least one link points into this repository (`linked > 0`). So these packages add no
  `FAIL` and do not set exit `1`.
- With `--verbose`, each foreign link still prints a `note "foreign link: …"` line (`:138`). Those
  lines are the same before and after the change, so the Task 1 diff ignores them as intended.

The plan does not depend on the exact exit code. Its Expected requires "the same exit code before
and after" (`:90-91`), which holds whatever the rest of the machine reports.

## Review 0086 Item Resolution

- **B1 (no command for "non-ghostty output unchanged"; cannot run in the given order; lane caveat):
  Resolved.** Step 0 captures a baseline into a `mktemp -d` dir **before any edit** (`:44-50`). The
  after block re-runs doctor and diffs both outputs through a `strip()` filter that drops the
  Version section, `ghostty` lines, the stowed count, and `uncommitted changes` (`:72-82`). It prints
  `PASS:` or `FAIL:`. The `uncommitted changes` line already falls inside the deleted Version range,
  so that extra filter is redundant but harmless. The Expected requires the same exit code before
  and after (`:90-91`). The lane caveat is stated and corrected (`:29-32`; see above). The
  Completion Criteria point to the Task 1 diff (`:271`).
- **S1 (bare package name in the re-stow command): Resolved.** The `<area>/<pkg>` label is used "in
  the PASS/FAIL/SKIP text only" (`:56-57`). The hint keeps the bare `$pkg`
  (`--dir=stow/macos … --simulate ghostty`, never `macos/ghostty`) (`:58-59`).
- **S2 (`# macOS` on macOS-only expectations): Resolved.** The ghostty grep block starts with
  `# macOS — both ghostty packages stowed from this lane` (`:85`). The Task 3 dry-run block starts
  with `# macOS` (`:146`), and Arch is told not to dry-run the macOS package (`:153`). The syntax,
  area-glob, and diff blocks (`:66-82`) are portable and correctly carry no label.
- **S3 (no Arch/Debian check): Resolved.** The read-only area-glob loop is added verbatim (`:69`),
  and the Expected requires `DONE: area glob` with no `FAIL:` (`:90`).
- **S4 (`REPO` never set): Resolved.** Every fenced block that runs a command sets
  `REPO="$(git rev-parse --show-toplevel)"` first (`:47`, `:67`, `:73`, `:86`, `:100`, `:107`,
  `:125`, `:147`, `:159`, `:166`, `:191`, `:202`, `:210`, `:218`), and the Assumptions say so
  (`:24-25`). Doctor runs as `"$REPO/scripts/doctor.sh"` (`:49`, `:68`, `:75`).
- **S5 (rollback for Tasks 2–4): Resolved.** Task 3 (`:155-169`) and Task 4 (`:198-213`) each have a
  marked `git restore --` block and a `revert --no-commit` + `revert(...)` + `Refs:` command pair.
  Task 2 shares commit 2 with Task 1, so the Task 1 revert (`:104-110`) covers it, as `:132-133`
  states. The Task 2 pre-commit restore is given as prose only (see suggestion 3).
- **S6 (mark `git restore`): Resolved.** `⚠️  MANUAL STEP — review before running` sits on the line
  directly above each `git restore --` fence (`:98`, `:157`, `:200`).
- **S7 (nvim check tests the wrong file): Resolved.** `nvim --headless -u NONE -c "luafile …" -c qa`
  on the lane file (`:193`), with a skip if nvim is absent (`:196`).
- **S8 (ambiguous "(see task list)"): Resolved.** The new `desc:` ends `(packages: task list)`
  (`:141`). The quoted old line matches `Taskfile.yml:67` exactly (`:139`).
- **S9 (`docs/guides/doctor.md` markers and placeholder): Resolved.** Task 2 uses `stow/<area>` in
  both re-stow commands (`:118`) and removes the blank line between marker and fence at the re-stow
  install and the `chsh` block (`:119-120`; today `doctor.md:99-101` and `:119-121`). The validation
  greps the fences and the placeholder (`:124-130`).
- **S10 (no commit for plan, index, reviews): Resolved.** Commit 1
  `docs(plans): add Ghostty follow-ups plan` covers the plan, `docs/plans/README.md`, review 0086,
  and this re-review (`:228-229`). The implementation review has its own commit (`:239`).
- **S11 (review numbers): Resolved.** 0086 is the plan review, 0087 the re-review, 0088 the
  implementation review (`:236-237`). This file is `0087`, so the numbers are correct.
- **S12 (privacy grep): Resolved.** Task 5 gives the command and Expected `PASS: privacy`
  (`:221`, `:224`). See suggestion 1.
- **S13 (push approval): Resolved.** Plan approval is separate from the earlier push request
  (`:35-36`). Task 7 asks the operator again before pushing; push only, no merge, no force push
  (`:240`, `:255`).
- **S14 (troubleshooting fix block, primary-checkout foreign links): Out of scope, recorded**
  (`:262-267`).

## Blocking Issues

None.

## Non-Blocking Suggestions

1. **Privacy grep matches the plan itself in commit 1.** Task 5 runs before every commit (`:215`),
   and commit 1 stages this plan (`:228`). The added plan line `:221` contains `password`, `token`,
   `/Users/`, and `/home/`, review 0086 adds "no secrets" (`0086:152`), and this re-review quotes
   the pattern words. So the grep prints matches, and `PASS: privacy` does not appear for commit 1.
   A Builder who stops at the first mismatch stops there. Reword the Expected: "for commit 1, only
   the Task 5 pattern line and review prose match; inspect each match", or exclude `docs/plans/` and
   `docs/reviews/` from the grep for that commit only.
2. **`rm -rf` of the baseline dir is unmarked.** `rm -rf "${BASE:?}"` (`:93-94`) is prose, with no
   fence and no marker, and `.claude/rules/safety.md` forbids `rm` outside the repository. The
   `:?` guard and the `mktemp -d` origin make it safe, and doctor itself removes its own `mktemp`
   dir. Either put it in a fenced block with `⚠️  MANUAL STEP — review before running` on the line
   above, or drop it and leave the temp dir for the OS to clean.
3. **Task 2 pre-commit rollback is prose.** `:132` says "as Task 1 (`restore --
   docs/guides/doctor.md` under the marker …)". For a copy-pasteable step, give the block, with the
   marker on the line directly above the fence:
   `REPO="$(git rev-parse --show-toplevel)"` / `git -C "$REPO" restore -- docs/guides/doctor.md`.
4. **Placeholder and unused `REPO` in the ghostty grep block.** `:86-87` sets `REPO` but does not
   use it, and writes `"<BASE>/after.txt"`. The diff block writes `BASE="<value printed in step 0>"`
   (`:74`). Use the same form in both blocks (`BASE="<value printed in step 0>"` then
   `"$BASE/after.txt"`) so the Builder substitutes the value once per block in the same way.

Optional, for Task 2 or later: the correction above shows that `docs/guides/doctor.md:108`
(`link(s) point outside this repo` — "another dotfiles checkout owns those links") holds only for a
package with some links into this repository. A package fully owned by another checkout shows
`SKIP: … (not stowed — …)`. One sentence there would stop a user from reading that `SKIP` as "not
installed".

## Safety Verdict

PASS — `doctor.sh` stays read-only (`:26`, `:62`, `:252`). The new step 0 and diff blocks write
only into a `mktemp -d` dir. `task dry-run` stays `--simulate` (`:152`, `Taskfile.yml:75`). No
`stow` install, no `--adopt`, no `mv`/`ln -s` against `$HOME`, no `reset --hard`, no force push, no
merge. The three `git restore --` rollbacks are marked. The `rm -rf "${BASE:?}"` cleanup is guarded
but unmarked (suggestion 2).

## Privacy Verdict

PASS — the revision adds no secrets, hostnames, or user-specific paths; it uses `$REPO`, `$HOME`,
`<sha>`, and `<BASE>` placeholders. The `/Users/` and `/home/` strings at `:221` are grep patterns,
not paths. The new privacy grep gives a false positive on commit 1 (suggestion 1); that is an
Expected-wording issue, not a leak.

## Documentation Verdict

PASS — the B1 check now has commands, runs in a valid order, and has a `PASS:`/`FAIL:` result. Each
new `⚠️  MANUAL STEP — review before running` marker sits on the line directly above its fence
(`:98`, `:157`, `:200`). All commit subjects (`:228-232`, `:239`) and revert subjects (`:109`,
`:168`, `:212`) follow Conventional Commits; `revert` is an allowed type, and each revert carries a
`Refs: <sha>` footer. Suggestions 1 to 4 are wording and copy-paste fixes. No status-block change is
needed (`:253-254`; `.claude/rules/status-sync.md`).

## Cross-Platform Verdict

PASS — the macOS-only expectations carry `# macOS` (`:85`, `:146`). Arch is told not to dry-run the
macOS package (`:153`). The area loop adds `stow/$OS` only for `macos`, `arch`, or `debian`
(`:54-55`), and the area-glob check covers the `.gitkeep`-only areas on every platform (`:69`). The
diff, syntax, revert, and pre-commit blocks use only `bash`, `git`, `sed`, `grep`, `diff`, and
`task`, and are portable.

## Recommended Next Action

Operator: review Plan 0032 and approve it explicitly; it stays Draft until then. The Planner can
fold suggestions 1 to 4 in before approval, or the Builder can apply them at the affected tasks;
they do not need another review. After approval, the Builder starts at Task 1 step 0, before any
edit to `scripts/doctor.sh`.
