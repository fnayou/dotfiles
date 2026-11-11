# Review: fzf History Delete Key Implementation

**Number:** 0111
**Status:** Complete
**Date:** 2026-11-06
**Plan reviewed:** 0039 — Delete History Entries from the fzf Ctrl+R Picker
**Files reviewed:**
`stow/common/zsh/.config/zsh/scripts/fzf-history-delete`, `stow/common/zsh/.config/zsh/fzf.zsh`,
`scripts/test-fzf-history-delete.sh`, `docs/guides/zsh-setup.md`, `website/guides/zsh-setup.md`,
`website/features/shell.md`, `docs/decisions/0087-fzf-history-delete-ctrl-x-exclude.md`,
`docs/decisions/README.md`, PRD 0035, Architecture 0031, Plan 0039.

## Summary

Reviewed the implementation of Plan 0039 — Delete History Entries from the fzf Ctrl+R Picker. The
unrelated `stow/common/herdr/.config/herdr/config.toml` change is in the working tree and must not be
staged with this work.

Checks run:

- `bash scripts/test-fzf-history-delete.sh` passes (68 checks) against history files that zsh itself
  writes, in a temporary directory: single, duplicate, multi-line (with and without a backslash before
  the newline), trailing backslash, a command ending in `\\`, special characters, Unicode, a look-alike
  prefix pair, no match, partial text, empty input, missing prefix, missing arguments, missing file,
  permissions, backup, and a failed write in a read-only directory. The helper prints nothing in every
  case, never adds or changes a line, and leaves the original untouched on failure.
- Timing on a synthetic 5,000-entry history (with multi-line entries) is 0.19 seconds per delete.
- `fzf.zsh` and the helper pass `zsh -n`. In a fake home that holds the helper, `fzf.zsh` produces the
  expected `FZF_CTRL_R_OPTS`, and fzf accepts it (`--filter` run). Without the helper there is no key.
- The stow dry run in a fake home lists links for `fzf.zsh` and `scripts/fzf-history-delete` and no
  conflict.
- `task check:decisions` passes (76 ADRs). `task brand:check` passes. The CI secret patterns find
  nothing in the new files.
- The real `~/.zsh_history` was never read or written by any test or command; no `~/.zsh_history.bak`
  exists. The real `~/.config/zsh/scripts/` does not exist, so nothing changes on this machine until the
  user re-stows.

Two fixes during build: the continuation rule first treated an even run of backslashes at the end of a
line as the end of an entry, which the test for a backslash before a newline caught (zsh stores that
case as `\\` plus newline; every line ending in a backslash continues). A first copy of the guide to the
site overwrote newer site content; it was restored from git and the guide edits were applied to each
file separately (see below).

## Blocking Issues

- None.

## Non-Blocking Suggestions

- `docs/guides/zsh-setup.md` and `website/guides/zsh-setup.md` were already different before this work:
  the site copy documents the herdr, ssh, lms and docker completions that the docs copy lacks. The plan
  assumed identical copies. This change edits both separately and leaves that older gap alone. Bringing
  them back in sync is a separate task.
- The `{f}` placeholder, and how fzf writes a multi-line item into that file, are verified only against
  fzf's manual and by the tests, which write the item file themselves. The user's real-picker check
  (plan Task 9) is the first end-to-end test of the helper with the key.
- Arch and Debian are untested. The helper uses `zsh`, `mktemp`, `cp -p`, `chmod` and `mv`; the
  `zsh/stat` module reads the file mode.
- A rolling single backup means two deletes in a row overwrite the backup of the first. The guide says
  the backup holds the history before the last delete.
- The key is lost if `local.zsh` overwrites `FZF_CTRL_R_OPTS`; the guide and `fzf.zsh` say to append.
- Consider running `scripts/test-fzf-history-delete.sh` in CI (needs `zsh` on the runner).

## Safety Verdict

PASS — No `stow` install, `rm`, `mv` or `ln -s` against `$HOME` runs or ships as automated behavior.
Stow and restore steps are `MANUAL STEP`, with a dry run first. The helper changes the history file
only at the user's key press, keeps a backup, writes a same-directory temporary file and replaces the
original in one step; on any failure it leaves the original untouched. No match means no change.

## Privacy Verdict

PASS — The helper prints and logs nothing and passes the command through a temporary file that fzf
creates and removes. Test commands are made up. No history content, backup or path from `$HOME` is in
the repository.

## Documentation Verdict

PASS — The guide gives the key, requirements, re-stow with dry run, what the key does, the limits (the
entry stays in the running shell's memory; other open shells; `local.zsh`), restore from the backup and
rollback, with platform labels. PRD, architecture, plan and ADR references are accurate. No status
block change is needed: no package was added.

## Recommended Next Action

Approve and commit with `ship-change` on `feat/fzf-history-delete`, staging only the paths above plus
the PRD, architecture, plan and this review (not the `herdr` change). Then re-stow `zsh` (dry run first),
open a new terminal, delete a throwaway entry such as `echo delete-me-test` with `ctrl-x`, and report.
