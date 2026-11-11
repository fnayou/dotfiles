# Plan: Delete History Entries from the fzf Ctrl+R Picker

**Number:** 0039
**Status:** Complete
**Date:** 2026-11-06
**PRD:** [0035](../prd/0035-fzf-history-delete-keybind.md)
**Architecture:** [0031](../architecture/0031-fzf-history-delete-keybind-architecture.md)

## Objective

Add a `ctrl-x` key to the fzf Ctrl+R picker that removes the highlighted entry from `~/.zsh_history`
through a tested helper script and fzf's `exclude` action, without touching the real history during
development.

## Assumptions

- PRD 0035 and Architecture 0031 are Approved.
- fzf is 0.74.5 on this machine and `perl` is installed. Arch and Debian are not available to test; the
  guide says so.
- All development and tests use copies of a history file in a temporary directory. The real
  `~/.zsh_history` is never read by tests or written by an agent.
- The `zsh` package is already stowed with `--no-folding`. A new file in it needs the user to re-stow
  (dry run first). This plan does not run `stow`.
- No package is added or removed, so the status blocks in `AGENTS.md` and `CLAUDE.md` do not change.
- Work happens on a new branch `feat/fzf-history-delete`, created from `main` when the first file is
  written. The unrelated `herdr` change stays unstaged.

## Ordered Tasks

1. **Spike, no repository changes.** On temporary files only:
   1. Ask the user to run `export FZF_CTRL_R_OPTS="--bind 'ctrl-x:exclude'"` in a real terminal and
      confirm that `ctrl-x` hides an entry and that Enter still inserts the right command. Record the
      result and fzf version.
   2. Write a throwaway history file with: a single-line entry, a multi-line entry, an entry ending in
      a backslash, an entry containing `\\`, `$`, quotes and a backtick, a look-alike pair (one command
      is the prefix of another), and a duplicate. Work out how zsh stores each one.
   3. Check how `{2..}` reaches a child process for each of those entries, and whether fzf's file
      placeholder is available in 0.74.5 (a way to avoid putting the command in the argument list).
   4. Write the findings into the architecture's Open Questions as resolved answers (a short
      "Spike results" note), and stop if the matching rule cannot be made exact; report to the user.
2. **Write the test script** `scripts/test-fzf-history-delete.sh` first. It builds the Task 1 history
   file in a temporary directory, runs the helper against it, and checks: only the chosen entries are
   gone; every other byte is unchanged; multi-line and backslash entries behave; a no-match leaves the
   file identical and exits non-zero; the backup exists; a failed write (read-only directory) leaves the
   original untouched; permissions are preserved. It never reads `$HOME/.zsh_history`.
3. **Write the helper** `stow/common/zsh/.config/zsh/scripts/fzf-history-delete` (zsh script, mode 0755):
   takes the command text as its one argument, removes the tab the widget adds after newlines, reads
   `$HISTFILE` (default `~/.zsh_history`), groups raw lines into entries, removes exact matches, writes
   a same-directory temporary file, checks it, keeps `$HISTFILE.bak`, replaces the original in one step.
   It prints nothing about the command and logs nothing. Run Task 2's tests until they pass.
4. **Set the key in `stow/common/zsh/.config/zsh/fzf.zsh`**: after `eval "$(fzf --zsh)"`, and only when
   `fzf` supports `exclude`, `perl` exists and the helper is readable, set `FZF_CTRL_R_OPTS` with the
   `ctrl-x` bind, appending to any value already set. `FZF_DEFAULT_OPTS` is untouched. Check the file
   still parses (`zsh -n`) and that a new interactive shell starts cleanly.
5. **Document in `docs/guides/zsh-setup.md`** (and copy to `website/guides/zsh-setup.md`, which is an
   identical copy): the key and what it does; the requirements (fzf with `exclude`, `perl`); the
   in-memory limit; the backup file; the concurrent-shell caveat; the file list entry for the helper;
   the re-stow with a dry run first and a `MANUAL STEP` install; rollback; after-fzf-update re-test.
   Add one line to `website/features/shell.md` if it lists the fzf integration.
6. **Write ADR `docs/decisions/0087-fzf-history-delete-ctrl-x-exclude.md`** (Accepted): `ctrl-x`, not
   `ctrl-d`; `exclude` instead of `reload` and why; file-only deletion; raw-text edit; perl-only mode.
   Add its row to `docs/decisions/README.md`.
7. **Validate** (Validation Commands): helper tests, syntax checks, a clean shell start, the fake-home
   stow dry run that lists the new file and no conflict, `task check:decisions`, `task brand:check`
   (regenerate and stage the art if stale), privacy audit of the diff.
8. **Review.** The Reviewer runs `review-change`, writes the report under `docs/reviews/`, and marks
   this plan Complete only after PASS with no blocking issues.
9. **User validation (manual).** The user re-stows `zsh` (dry run, then install), opens a new terminal,
   presses Ctrl+R, deletes a throwaway entry made for the purpose (for example `echo delete-me-test`)
   with `ctrl-x`, closes the picker, and checks the entry is gone in a new shell and that
   `~/.zsh_history.bak` exists. The result is added to the guide's "tested" note.
10. **Ship** with `ship-change` on `feat/fzf-history-delete`, staging only the paths in Files Affected.

## Files Affected

- `stow/common/zsh/.config/zsh/scripts/fzf-history-delete` — created
- `stow/common/zsh/.config/zsh/fzf.zsh` — modified
- `scripts/test-fzf-history-delete.sh` — created
- `docs/guides/zsh-setup.md` — modified
- `website/guides/zsh-setup.md` — modified (identical copy)
- `website/features/shell.md` — modified only if it lists the fzf integration
- `docs/decisions/0087-fzf-history-delete-ctrl-x-exclude.md` — created
- `docs/decisions/README.md` — modified (index row)
- `docs/architecture/0031-fzf-history-delete-keybind-architecture.md` — modified (spike results)
- `docs/prd/0035-fzf-history-delete-keybind.md` — already created; ships in the same PR
- `docs/plans/0039-fzf-history-delete-keybind.md` — this file
- `docs/reviews/` — one review report created by the Reviewer
- `brand/generated/` — regenerated only if `task brand:check` reports stale art
- Nothing is deleted.

## Safety Checks

- Before starting: `git status` shows only the approved documents and the unrelated herdr change.
- No agent command reads, writes or copies the real `~/.zsh_history` or `~/.zsh_history.bak`. Tests use
  `mktemp -d` and remove it afterwards.
- No `stow` install, `ln -s`, `rm` or `mv` against `$HOME`. The helper's own `mv` into place runs only
  in the directory of the history file at the user's request through the key, and is exercised by tests
  in a temporary directory only.
- The helper never prints, logs or stores the command text; the tests use made-up commands only.
- The spike's fzf test runs in the user's terminal with a session-only variable.
- The key is not registered unless every requirement is met, so a missing tool means no key, not a bad
  delete.
- Staged diff audited for secrets and `.DS_Store` before commit.

## Validation Commands

```bash
git status --short
zsh -n stow/common/zsh/.config/zsh/scripts/fzf-history-delete
zsh -n stow/common/zsh/.config/zsh/fzf.zsh
bash scripts/test-fzf-history-delete.sh              # temp files only
ls -l stow/common/zsh/.config/zsh/scripts/           # helper is mode 755
zsh -i -c 'print -r -- "$FZF_CTRL_R_OPTS"' </dev/null   # shows the bind in a fresh shell
# Stow dry run in a fake home; no real $HOME touched
FAKE=$(mktemp -d) && stow -v --dir=stow/common --target="$FAKE" --no-folding --simulate zsh </dev/null
task check:decisions
task brand:check
git diff --staged | grep -iE "password|token|api[_-]?key|secret|BEGIN.*PRIVATE|/Users/|/home/"
git diff --staged --name-only | grep -i ds_store
```

The fake-home dry run is expected to list a link for `.config/zsh/scripts/fzf-history-delete` and no
conflict. The privacy audit must return nothing real.

## Rollback Strategy

Nothing outside the repository changes before Task 9, so rollback is git only:

- Before commit: `git restore --staged --worktree -- <path>` for modified files; delete the new files
  (all untracked, inside the repository).
- After commit, before push: `git reset HEAD~1`. After push: close the PR or `git revert`.
- After the user has stowed: remove the line that sets `FZF_CTRL_R_OPTS` by reverting `fzf.zsh`, open a
  new shell, and, if wanted, unstow the new file with `stow --dir=stow/common --target="$HOME"
  --no-folding --simulate -D zsh` first (this unstows the whole package, so re-stow afterwards).
- To recover a deleted entry: copy `~/.zsh_history.bak` back over `~/.zsh_history` (the guide marks it
  `MANUAL STEP`).

## Completion Criteria

- [ ] The spike results are recorded, and the matching rule is exact for multi-line, backslash and
      look-alike entries.
- [ ] `scripts/test-fzf-history-delete.sh` passes, and covers match, no-match, failed write, backup and
      permissions.
- [ ] The helper edits only the chosen entries and leaves every other byte of the file unchanged.
- [ ] `fzf.zsh` sets `FZF_CTRL_R_OPTS` only when the requirements are met and leaves
      `FZF_DEFAULT_OPTS` alone.
- [ ] The zsh guide and its website copy are updated and identical; ADR 0087 is added and indexed.
- [ ] `task check:decisions` and `task brand:check` pass; the stow dry run in a fake home is clean.
- [ ] No history content appears anywhere in the repository.
- [ ] The Reviewer returns PASS for safety, privacy and documentation and marks this plan Complete.
- [ ] The user confirms `ctrl-x` deletes an entry in a real picker and the entry stays gone in a new
      shell.
