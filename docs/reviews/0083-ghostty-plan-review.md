# Review: Ghostty Configuration Plan

**Number:** 0083
**Status:** Complete
**Date:** 2026-10-17
**Reviews:** `docs/plans/0031-implement-ghostty-configuration.md` (Draft)
**Against:** `docs/prd/0028-ghostty-configuration.md` (Approved),
`docs/architecture/0026-ghostty-configuration-architecture.md` (Approved)

## Summary

Reviewed Plan 0031 against PRD 0028, Architecture 0026, reviews 0080 to 0082, and the repository
safety, privacy, Stow, status-sync, cross-platform, and documentation rules. Ghostty was not run
and no plan command was executed during this review. No plan is completed by this review; Plan 0031
stays Draft.

The plan is complete and safely ordered. Every PRD acceptance criterion and every file and change
in Architecture 0026 maps to a task (see Coverage). Validation (Tasks 10 to 14) runs before the
first commit (Task 17). Both packages and the `AGENTS.md`, `CLAUDE.md`, and `README.md` status
lines go into one commit. The Builder never runs `stow` against `$HOME`, never writes to `$HOME`,
and never launches Ghostty; Tasks 12, 13, 22, and 23 are the operator's. Every fake-home block is a
`( set -eu; … )` subshell with `${FAKE_HOME:?}` on every `stow --target`, `XDG_CONFIG_HOME`, and
`rm`, and a `trap` that removes the `mktemp -d` directory. Review 0082 suggestion 1 is applied:
checks test exit codes explicitly, print `FAIL: …`, and end with one `PASS: …` line. The icon copy
refuses an existing target, uses `/bin/cp -n`, and checks the SHA-256
`6796c0f423a066009fef4f69ab7800a086627304fc633d3cba69a4ca173632ac`, the size, and the file type. No
committed file carries a user-specific path. No rollback uses `git reset --hard` or a force push.
All five planned commit messages follow Conventional Commits.

Two issues block approval: several macOS-only blocks carry no platform label, and one is labelled
as the Arch case (B1); and every after-commit rollback creates a commit whose message does not
follow Conventional Commits (B2).

## Coverage

PRD 0028 acceptance criteria:

| Criterion | Task / check |
|---|---|
| `config.ghostty` sets the Configuration Summary; Decisions 8–10 | Task 2 (Architecture content), Task 14 |
| Theme hex values match Alacritty | Task 3, check 4 |
| Theme by name, not bundled, not absolute | Task 2 content, check 3 step 2 (`palette = 0=#494d64`) |
| `+validate-config` reports no errors | Checks 1, 2, 3 |
| No secrets in package files | Check 5, Task 17 privacy checklist |
| No symlinks in `$HOME` during implementation | Assumptions, Safety Checks; only operator Task 23 stows |
| No automatic `stow` install | Tasks 22–23 are operator-only, marked |
| Application Support file untouched | Assumptions, Safety Checks (see suggestion 3) |
| No-equivalent settings not invented | Tasks 2–3 copy Architecture content exactly |
| Dry-run and install documented | Task 18 (guide), Task 20 (`docs/stow-usage.md`, `terminal.md`) |
| No `macos-*` in common; last line `config-file = ?macos.ghostty` | Task 2, check 6 |
| `macos.ghostty` content, no `macos-custom-icon` | Task 7, check 6 |
| Validation with `macos.ghostty` absent and present | Check 3 steps 2 and 3 |
| `Ghostty.icns` SHA-256 | Task 8, check 6 |
| macOS README lists files, source, SHA-256, licence | Task 9 |
| macOS `.stow-local-ignore` equals common | Task 6, check 6 |
| App bundle not modified | Assumptions, Safety Checks (see suggestion 3) |
| [macOS] Dock icon after stow and restart | Task 23 (check 7b), Task 12 (check 7a) |
| Status blocks in the package commit | Tasks 15–17 |

Architecture 0026: all eight inventory files (Tasks 2–9); `docs/guides/ghostty-setup.md`
(Task 18); `AGENTS.md` §1 and §2 and `CLAUDE.md` (Task 15); every `README.md` row, including
`:15-16`, `:24`, `:25`, `:28-29`, `:33-34`, the package table, `:60`, `:85`, and `:105` (Task 16);
every "Yes" row of "Documentation and Website Mentions" and every row of "Statements made false by a
populated `stow/macos/`" (Task 20); validation checks 1 to 6 (Tasks 10–11) and check 7 (Tasks 12
and 23); the "first stowed" follow-up (Task 25). `website/philosophy.md` is correctly left
unchanged. The copied `.stow-local-ignore` source (`stow/common/alacritty/.stow-local-ignore`)
matches the six entries in Architecture 0026.

## Blocking Issues

1. **B1 — macOS-only blocks are not labelled, and check 3 step 2 is labelled as the Arch case.**
   `.claude/rules/cross-platform.md` requires a `# macOS` / `# Arch` / `# Debian` comment on the
   first line of every code block that is not portable, and `.claude/rules/documentation.md`
   requires commands that are correct when copy-pasted. These blocks hardcode
   `/Applications/Ghostty.app/Contents/MacOS/ghostty`, `$HOME/Downloads/ghosty.icns`, or both, and
   carry no platform label:
   - Task 1 preflight (plan `:67-81`);
   - Task 8 icon copy (`:200-218`);
   - checks 1 and 2 (`:722-728`);
   - the Task 23 read-only check (`:594-600`).

   Check 3 step 2 (`:755-781`) is worse: its first line says "common package only (Arch case)",
   but the block sets `GHOSTTY=/Applications/Ghostty.app/Contents/MacOS/ghostty`, so it fails when
   copied on Arch. It is the Arch *layout* simulated on macOS.
   Fix: add `# macOS` as the first line of each block above, and reword check 3 step 2 to
   `# macOS — Step 2: common package only (simulates the Arch layout)`. Architecture 0026
   (`:808-811`) already gives the Arch binary (`GHOSTTY=ghostty`) if an Arch variant is wanted.

2. **B2 — after-commit rollbacks create commits that break Conventional Commits.**
   `git -C "$REPO" revert --no-edit HEAD` (Task 17 `:445`, Task 19 `:486`, Task 21 `:547`, Task 25
   `:647`), `git -C "$REPO" revert --no-edit <review commit>` (Task 24 `:631`), and the Rollback
   Strategy (`:902`) all commit git's default subject `Revert "<original subject>"`. That does not
   match `<type>[optional scope][!]: <description>`, which the user's global rules require for
   every commit in every repository. A Builder who follows the rollback verbatim creates a
   non-conforming commit.
   Fix: replace each with a revert that does not commit, followed by a Conventional Commits
   message, for example:

   ```bash
   git -C "$REPO" revert --no-commit <sha>
   git -C "$REPO" commit -m "revert(ghostty): remove Ghostty stow packages" -m "Refs: <sha>"
   ```

   Use a matching `revert:` subject per task (setup guide, website pages, status follow-up, review).

## Non-Blocking Suggestions

1. Task 12 (`:286-288`) prints `PASS: fake-home launch session ended` even when Ghostty exits at
   once. Launching the GUI by running the bundle binary from a shell is not verified by PRD 0028 or
   Architecture 0026. If the binary refuses or returns immediately, the block still prints `PASS:`
   with no window opened. Rename the line to a neutral `DONE:` and make "a new Ghostty window
   opened" an explicit operator answer. Do not switch to `open -na Ghostty.app --env …`: `open`
   returns at once, so the `trap` would delete the fake home while Ghostty still reads it. Also say
   to run the block from Alacritty or Terminal.app, since Ghostty must be fully quit first.
2. Task 14 (`:352-353`) asks the operator to repeat Task 13 after a numpad change, but Task 13 runs
   inside the Task 12 window, whose fake home the `trap` already removed. Say "re-run Task 12, then
   Task 13 for the changed keys".
3. The plan states that the Application Support file and the app bundle stay untouched but records
   no evidence. Add read-only checks to Task 1 and before Task 24, both `# macOS`:
   `wc -c < "$HOME/Library/Application Support/com.mitchellh.ghostty/config.ghostty"` (expect `0`)
   and `codesign --verify --deep --strict /Applications/Ghostty.app; echo "exit=$?"` (expect
   `exit=0`). Record both outputs in the implementation review.
4. Task 24 (`:622-623`) expects the implementation review to be `0083`. This review takes `0083`;
   the implementation review is `0084`.
5. The Repository checks (`:881-891`, including `task check:decisions`) are not tied to a task. Run
   them in Tasks 17, 19, and 21 before each commit, and list `PASS: no whitespace errors` under the
   Task 17 Expected (`:439-440`).
6. Task 25 (`:640-643`) commits without the staged-diff review, privacy checklist, and operator
   approval that Tasks 17, 19, and 21 require. Add `git -C "$REPO" diff --staged` and the approval
   step there, and the status-sync self-check (it is a "first stowed" event).
7. The `git restore --` rollbacks (Tasks 15, 16, 20: `:380`, `:417`, `:528`; Rollback Strategy
   `:900`) discard uncommitted edits with no recovery, like `git clean -f`, which the plan does
   mark. Put `⚠️  MANUAL STEP — review before running` above them too. `git restore -- website/`
   also discards any unrelated edit under `website/`; prefer the explicit file list from Task 20.
8. Task 20 (`:492-495`) adds an "Installing the ghostty package" section to `docs/stow-usage.md`
   but only requires marked install fences for `website/features/terminal.md`. Require the marker
   above every install and `stow --delete` fence in both files, and reuse the Task 18
   `grep -B1 -n '^```bash'` check.
9. `REPO` is set in Task 1 (`:68`) only; a Builder whose shell does not keep variables runs later
   blocks with `git -C ""`, which works only because it runs from the repository root. Repeat
   `REPO="$(git rev-parse --show-toplevel)"` at the top of each block that uses it.
10. `Taskfile.yml:67` describes `task dry-run` as "AREA=<common> … (macos/arch/debian are future
    areas)". That becomes stale once `stow/macos/ghostty` exists, and `docs/stow-usage.md` will
    show `task dry-run AREA=macos PACKAGE=ghostty`. Architecture 0026 does not list the file, so it
    is outside this plan; record it as a follow-up in the implementation review.

## Safety Verdict

PASS — the Builder never runs `stow` against `$HOME`, never writes to `$HOME`, never launches
Ghostty, and never touches the Application Support file or the app bundle. The source icon is only
read. Every fake-home block is a `( set -eu; … )` subshell with `${FAKE_HOME:?}` on every
`stow --target`, `XDG_CONFIG_HOME`, and `rm`, and a `trap` cleanup of its own `mktemp -d`
directory. The icon copy refuses an existing target and uses `/bin/cp -n`. The real dry-run comes
before the real install; both are operator-only, and every install and `stow --delete` fence has
the marker on the line directly above it. No `--adopt`, no `rm`/`mv`/`ln -s` against `$HOME`, no
`git reset --hard`, no force push, no push or merge.

## Privacy Verdict

PASS — the plan and the files it creates contain no secrets, hostnames, or user-specific paths;
`$HOME`, `~`, `mktemp -d`, and `/path/to/dotfiles` placeholders are used. Check 5 and the Task 17
`git diff --staged` privacy checklist audit both packages. The icon's unknown licence is recorded
in the macOS README, as PRD Decision 11 requires.

## Documentation Verdict

FAIL — B1: macOS-only blocks lack the `# macOS` label, and check 3 step 2 is labelled as the Arch
case while it only runs on macOS. B2: the after-commit rollback commands produce commit messages
that break Conventional Commits. All other dangerous fences carry the marker on the line directly
above, and the planned commit messages are correct.

## Cross-Platform Verdict

FAIL — B1. The package split (common for macOS and Arch, `stow/macos/ghostty` for macOS only, none
on Debian) and the labelled Task 22 and Task 23 Stow commands are correct, but non-portable
validation blocks do not state their platform.

## Recommended Next Action

Planner: fix B1 and B2 in Plan 0031, optionally fold in the suggestions, and keep the plan Draft.
Reviewer: confirm the fixes in a short re-review. The plan stays Draft until the user explicitly
approves it; only then does the Builder start at Task 1.
