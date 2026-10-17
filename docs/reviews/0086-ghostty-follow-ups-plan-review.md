# Review: Ghostty Follow-ups Plan

**Number:** 0086
**Status:** Complete
**Date:** 2026-10-17
**Reviews:** `docs/plans/0032-ghostty-follow-ups.md` (Draft)
**Against:** `docs/prd/0028-ghostty-configuration.md`,
`docs/architecture/0026-ghostty-configuration-architecture.md`, reviews 0083 and 0085

## Summary

Reviewed Plan 0032 against `scripts/doctor.sh` (Stow linkage `:104-167`, directory folding
`:169-189`), the `dry-run` task in `Taskfile.yml:66-75`, `docs/guides/doctor.md`,
`docs/guides/codex-setup.md`, `stow/common/codex/README.md`, `stow/common/nvim/README.md`,
`stow/common/nvim/.config/nvim/lua/custom/plugins/colorscheme.lua`, and the repository safety,
privacy, Stow, status-sync, cross-platform, and documentation rules. No plan command was executed;
the Reviewer had no shell access beyond git. No plan is completed by this review; Plan 0032 stays
Draft.

The plan is small, correctly scoped, and safe:

- **Doctor stays read-only.** Task 1 only adds a loop over a second area and a second test in the
  folding condition; step 5 forbids new writes and new commands that touch `$HOME`.
- **Common output is kept.** Packages in `common` keep the bare name, and the re-stow hint for
  `common` still reads `--dir=stow/common`. Only the `N of M package(s) stowed` count changes on
  macOS, and the plan says so.
- **`.gitkeep`-only areas are handled.** `stow/arch/` and `stow/debian/` hold only `.gitkeep`. The
  glob `stow/<area>/*/` matches directories only; with no match it stays literal and the existing
  `[[ -d "$pkg_dir" ]] || continue` skips it. On `OS=unknown` no second area is added.
- **`~/.config/ghostty` is counted once.** The folding loop iterates `~/.config/*/`, so each
  directory is visited once whatever the number of source packages; an either/or condition cannot
  double-count it.
- **Line references are correct.** `codex-setup.md:23`, `codex/README.md:65`, `nvim/README.md:5`,
  and `colorscheme.lua:2` hold the quoted phrases. `stow/macos/ghostty/` has one managed file
  (`macos.ghostty`) and `stow/common/ghostty/` has two, which matches the expected `1/1` and `2/2`.
- **Commits and rollback.** The three commit messages follow Conventional Commits. The rollback
  uses `git restore` or a `--no-commit` revert with a `revert(...)` subject; no `reset --hard`, no
  force push.
- **No status-block change.** No package is added, removed, or first stowed
  (`.claude/rules/status-sync.md`), so `AGENTS.md` and `CLAUDE.md` stay as they are.
- **No missed Alacritty-only statement.** A sweep of `docs/guides/*.md`, `stow/*/*/README.md`,
  and `website/**/*.md` found none besides the four in Task 3. `website/features/packages.md:113`
  already names Alacritty and Ghostty; `website/index.md:13` and `website/features/index.md:18`
  use Alacritty as one example in a list; `website/reference/supported-systems.md:31` and
  `website/usage/daily-workflow.md:8-9` name both terminals. The `Taskfile.yml` "future areas"
  wording appears in no user doc; `website/usage/taskfile.md:30` already uses `AREA=<area>`.

One issue blocks approval: the check that non-ghostty doctor output is unchanged has no command,
and the Builder cannot run it in the order the plan gives (B1).

## Blocking Issues

1. **B1 — Task 1 "unchanged output" check has no command and cannot be run as ordered.**
   Task 1 Expected (`:52-55`) says to compare doctor output with "the same command on `e9547f7`",
   and the Completion Criteria (`:139`) require "other output unchanged". This is the only
   evidence for that criterion, but no command is given. The validation runs after the edit, and
   the lane has no unedited copy of the script. Running the old script from another path does not
   work: `REPO_ROOT` comes from `BASH_SOURCE` (`doctor.sh:32`), so a copy in a temp dir or
   `bash <(git show e9547f7:scripts/doctor.sh)` checks the wrong repository. The shared stash is
   not an option in a lane. The comparison also includes lines that change for other reasons: the
   Version section, and "working tree has uncommitted changes" after the edit.
   The Expected is also incomplete for this lane. Review 0085 records that the Ghostty links point
   into this lane. If the other packages were stowed from the primary checkout, the doctor run from
   the lane reports each of them as `link(s) point outside this repo` and exits `1`, before and
   after the change. The Expected must say that, or the Builder stops on a correct result.
   Fix: capture a baseline before the edit, compare after it, and state the lane caveat, for
   example:

   ```bash
   # Before editing scripts/doctor.sh (HEAD = e9547f7)
   REPO="$(git rev-parse --show-toplevel)"
   BASE="$(mktemp -d)"; echo "BASE=$BASE"
   bash "$REPO/scripts/doctor.sh" --verbose > "$BASE/before.txt" 2>&1; echo "exit=$?"
   ```

   ```bash
   # After editing — set BASE to the value printed above
   REPO="$(git rev-parse --show-toplevel)"
   BASE="<value printed above>"
   bash "$REPO/scripts/doctor.sh" --verbose > "$BASE/after.txt" 2>&1; echo "exit=$?"
   strip() { sed '/^── Version/,/^── Summary/d' "$1" | grep -vE 'ghostty|package\(s\) stowed'; }
   if diff <(strip "$BASE/before.txt") <(strip "$BASE/after.txt"); then
     echo "PASS: non-ghostty output unchanged"
   else
     echo "FAIL: non-ghostty output changed"
   fi
   ```

   Add the baseline block as Task 1 step 0, before any edit.

## Non-Blocking Suggestions

1. **Keep the bare package name in the re-stow command.** Task 1 step 2 makes the label
   `macos/ghostty`, and step 3 changes only `--dir`. Say explicitly that the printed command keeps
   the bare `$pkg` (`--dir=stow/macos … --simulate ghostty`) and that only the `PASS`/`FAIL`/`SKIP`
   text uses the label. Otherwise a Builder who swaps `$pkg` for the label prints
   `--simulate macos/ghostty`, which Stow rejects.
2. **Platform labels on macOS-only expectations.** The Task 1 and Task 2 validation commands are
   portable, but both Expected results hold only on the macOS machine. Add `# macOS` as the first
   line of both blocks (`.claude/rules/cross-platform.md`). On Arch, `task dry-run AREA=macos
   PACKAGE=ghostty` simulates a macOS-only package into an Arch `$HOME`.
3. **No check covers the Arch and Debian path.** The `.gitkeep`-only skip is correct by reading
   but is not exercised on macOS. Add a read-only check to Task 1:
   `for d in "$REPO"/stow/arch/*/ "$REPO"/stow/debian/*/; do [[ -d "$d" ]] && echo "FAIL: unexpected $d"; done; echo "DONE: area glob"`.
4. **`REPO` is never set.** Task 1 rollback (`:57`) and Task 3 validation (`:95`) use
   `git -C "$REPO"`, and Task 1 validation uses the relative `scripts/doctor.sh`. Set
   `REPO="$(git rev-parse --show-toplevel)"` at the top of each block and use `"$REPO/scripts/doctor.sh"`
   (as review 0083 suggestion 9).
5. **Rollback for Tasks 2–4.** The Rollback Strategy says "Per task as above", but only Task 1 has
   one. Add the same `git restore -- <files>` / `revert --no-commit` + `revert(...)` pair to Tasks
   2, 3, and 4, with the commit subject each reverts. Write the after-commit revert as commands, as
   review 0083 B2 did, not as prose.
6. **Mark `git restore`.** `git -C "$REPO" restore -- scripts/doctor.sh` discards uncommitted edits
   with no recovery. Put `⚠️  MANUAL STEP — review before running` above it (review 0083
   suggestion 7).
7. **Nvim check tests the wrong file.** `nvim --headless +qa` loads `~/.config/nvim`, whose links
   point into the checkout that stowed `nvim`, not necessarily this lane. Check the edited file
   directly: `nvim --headless -u NONE -c "luafile $REPO/stow/common/nvim/.config/nvim/lua/custom/plugins/colorscheme.lua" -c qa; echo "exit=$?"`.
   The file only returns a table, so `luafile` does not need the plugins.
8. **Ambiguous "(see task list)".** In the new `desc:` this reads as "the task list" (`task
   --list`), but it means the `task list` task. `website/usage/taskfile.md:16-18` warns about
   exactly this confusion. Write `(packages: task list)`.
9. **`docs/guides/doctor.md` markers.** Task 4 says "markers unchanged", but `doctor.md:99` and
   `:119` put a blank line between the marker and the fence, which
   `.claude/rules/documentation.md` forbids. Since Task 4 edits the re-stow block at `:95-103`,
   remove the blank line there and at `:119`. Use `stow/<area>` as a placeholder in both commands
   so they stay portable.
10. **Plan, index, and reviews have no commit.** Files Affected lists `docs/plans/0032-…md`,
    `docs/plans/README.md`, and the reviews, but Task 5 commits none of them. Add a commit such as
    `docs(plans): add Ghostty follow-ups plan` (plan, index, this review) and one for the
    implementation review with the plan status change.
11. **Review number.** This review takes `0086`; the Task 6 implementation review is `0087`.
12. **Privacy grep.** Task 5 names a "privacy grep" without a command. Give the pattern, or point
    to the one used in Plan 0031 Task 17.
13. **Push approval.** Task 6 relies on an earlier push request for PR #83. Confirm it with the
    operator at Task 6; approval in one context does not extend to the next.
14. **Out of scope, for a later change.** `website/reference/troubleshooting.md:45` lists `ghostty
    (common and macOS)` for the folded-directory fix, but the fix block (`:58-63`) hardcodes
    `--dir=stow/common`, which does not reach `stow/macos/ghostty`. After merge, the doctor run from
    the primary checkout reports the Ghostty links as foreign until they are restowed from there
    (review 0085 suggestion 3).

## Safety Verdict

PASS — `doctor.sh` stays read-only: Task 1 adds no write, no `stow`, and no command that touches
`$HOME`. `task dry-run` stays `--simulate`. No `stow` install, no `--adopt`, no `rm`/`mv`/`ln -s`
against `$HOME`. No `reset --hard`, no force push, no merge. The `git restore` rollback lacks a
marker (suggestion 6).

## Privacy Verdict

PASS — the plan and the files it changes contain no secrets, hostnames, or user-specific paths. The
temp files in B1 live under `mktemp -d`.

## Documentation Verdict

FAIL — B1: the only check for "other output unchanged" has no command and cannot run in the order
the plan gives. The planned commit messages and rollback subjects follow Conventional Commits, and
the Task 3 line references are correct.

## Cross-Platform Verdict

PASS — the area loop adds `stow/$OS` only for `macos`, `arch`, or `debian`, skips `.gitkeep`-only
areas, and keeps `common` on every platform. The folding check accepts the OS area without
double-counting. The macOS-only expectations should carry a `# macOS` label (suggestion 2).

## Recommended Next Action

Planner: fix B1 in Plan 0032, optionally fold in the suggestions, and keep the plan Draft.
Reviewer: confirm the fix in a short re-review. The plan stays Draft until the user explicitly
approves it; only then does the Builder start at Task 1.
