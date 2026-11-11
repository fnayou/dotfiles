# PRD: Delete History Entries from the fzf Ctrl+R Picker

**Number:** 0035
**Status:** Approved
**Date:** 2026-11-06

## Goals

- Let the user delete the highlighted history entry from inside the fzf Ctrl+R picker, with `ctrl-x`,
  without leaving the picker.
- After the key press, the picker refreshes and the deleted entry is gone from the list.
- The deletion removes the entry from the history file (`~/.zsh_history`, `HISTFILE`), so it does not
  come back in new shells.
- Deliver the change as a small, tracked addition to the zsh package (`stow/common/zsh`), set through
  fzf's own `FZF_CTRL_R_OPTS` hook, so fzf's built-in Ctrl+R widget (`fzf --zsh`, ADR-0040) stays in use.
- Document the key, what it does, the limits and the rollback in the zsh setup guide.

## Non-Goals

- Replacing fzf's Ctrl+R widget with a custom widget (the "option 2" discussed earlier).
- Removing the entry from the running shell's in-memory history. The entry may remain findable with
  Ctrl+R, `history` and the up arrow in that same shell until it is restarted or the history is
  reloaded. The guide states this.
- Deleting several entries at once with multi-select. The picker runs with `--multi`; the delete key
  acts on the highlighted entry only, unless the architecture finds a safe way to do more.
- Bulk cleanup tools, history editing outside the picker, or redaction of secrets already in history.
- Changing any other fzf binding, `FZF_DEFAULT_OPTS`, or history options (`history.zsh`).
- `Ctrl+T` and `Alt+C` pickers.

## User Stories

- As a shell user, I want to press `ctrl-x` on a history entry in the Ctrl+R picker so that I can remove
  a typo, a failed command or a command with a secret without hunting for it elsewhere.
- As a shell user, I want the deletion to need a deliberate key that fzf does not already use so that I
  never delete an entry by habit (for example by pressing Ctrl+D to leave the picker).
- As the repository owner, I want the setting tracked in the zsh package so that every machine gets the
  same behavior from a normal stow.

## Constraints

- **Platform:** the `zsh` package is common. The history file is `$HISTFILE` (default
  `~/.zsh_history`) and uses the `EXTENDED_HISTORY` format (`: <time>:<duration>;<command>`). Multi-line
  commands are stored with a backslash at the end of each continued line. The solution must work on
  macOS, Arch and Debian without Homebrew-, pacman- or apt-specific commands. Debian ships older tools
  by default, so any extra tool (for example `perl`, `awk`) must exist on all three or be avoided.
- **fzf version:** ADR-0040 sets a minimum of fzf 0.48 for `fzf --zsh`. This machine has 0.74.5. The
  widget builds its list differently when `perl` is present (NUL-separated `N<TAB>command` records) and
  when it is not (`fc -rl 1`). The change must work in both modes or state which one it supports.
- **Why `reload` is needed:** fzf can only drop an item by reloading its list. The reload runs in a
  separate process that does not see the interactive shell's in-memory history, so it must rebuild the
  list from the history file.
- **Existing options:** `history.zsh` sets `SHARE_HISTORY`, `HIST_IGNORE_ALL_DUPS`, `HIST_SAVE_NO_DUPS`,
  `HIST_FIND_NO_DUPS` and `EXTENDED_HISTORY`. With `SHARE_HISTORY`, other open shells may write an
  entry back to the file after it was deleted.
- **Placement:** `FZF_CTRL_R_OPTS` must be set before the widget runs. It belongs in
  `stow/common/zsh/.config/zsh/fzf.zsh`, which is sourced after `compinit` and guarded by
  `command -v fzf`. ADR-0040 keeps `FZF_DEFAULT_OPTS` out of the committed files; this change sets only
  the Ctrl+R-specific option and does not touch the defaults.
- **Privacy:** history files can hold secrets. The deletion must not copy, print or log the deleted
  command anywhere (no temp files left behind, no debug output, no repository content).
- **Dependencies:** `fzf` only, plus tools already required by the zsh package.
- **Stow status:** the zsh package is already stowed with `--no-folding`; the file is a symlink into the
  repository, so the change takes effect in new shells without a new stow. No package is added, so the
  status blocks do not change.

## Safety Requirements

- Must not delete or truncate `~/.zsh_history` as a whole. The file may only change by removing the
  chosen entry.
- Must write the history file safely: build the new content in a temporary file in the same directory
  and replace the original in one step, and keep the previous file as a backup (for example
  `.zsh_history.bak`) until the architecture shows a better recovery path. Failure to write must leave
  the original untouched.
- Must remove only the exact chosen command, including its multi-line continuations, and not other
  entries that merely contain the same text.
- Must do nothing when no entry is highlighted (empty list).
- Must not be bound to a key that already has a fzf meaning the user relies on. `ctrl-x` is unused in
  the picker; `ctrl-d` is deliberately not used (it deletes a character or quits).
- Must not make any change to `$HOME` from an agent. The agent edits only files in the repository;
  testing uses a copy of a history file in a temporary directory, never the real `~/.zsh_history`.
- Must not run `stow` on its own. If the change needs a re-stow, the guide shows a dry run first.
- Must not print or store deleted commands in the repository, the plan, the review or the ADR.

## Acceptance Criteria

- [ ] Pressing `ctrl-x` on a highlighted entry in the Ctrl+R picker removes it from the list and from
      the history file, and the picker stays open.
- [ ] Opening a new shell and pressing Ctrl+R no longer lists the deleted entry.
- [ ] The key works for a multi-line command (all of its lines are removed) and for a command that
      shares text with another entry (only the exact entry is removed). Verified on a copy of a history
      file in a temporary directory.
- [ ] A failed write leaves the original history file unchanged, and a backup of the previous file
      exists after a successful delete.
- [ ] Pressing `ctrl-x` with an empty list does nothing and shows no error.
- [ ] Ctrl+R still inserts the chosen command as before, and all other fzf keys behave as before.
- [ ] Behavior is checked with and without `perl` available to the widget, or the unsupported mode is
      stated.
- [ ] The change is limited to `FZF_CTRL_R_OPTS` and helpers in the zsh package; `FZF_DEFAULT_OPTS`
      is untouched.
- [ ] `docs/guides/zsh-setup.md` documents the key, the in-memory limit, the backup, and how to roll back.
- [ ] A decision record in `docs/decisions/` captures the key choice (`ctrl-x`, not `ctrl-d`) and the
      "file only, not in-memory" scope.
- [ ] `task check:decisions` passes and `task brand:check` passes or the art is regenerated.
- [ ] A Reviewer pass returns PASS for safety, privacy and documentation.

## Out of Scope

- Everything listed under Non-Goals.
- Removing entries from the in-memory history (for example with `fc -p`, `history` array edits or a
  custom widget). A later PRD can cover it if the stale in-memory entry becomes a problem.
- Confirmation prompts, undo beyond the single backup file, and a history-cleaning Task target.
- Other shells (bash, fish) and other history tools (atuin, mcfly).

## Open Questions

- Which tool rewrites the history file in a form that works on macOS, Arch and Debian with no extra
  dependency? The architecture picks between `awk`, `perl` and a zsh helper function and checks the
  multi-line case.
- How does the reload rebuild the list so that the widget's own parsing of the chosen entry still
  works? The reload output must match what the widget expects in each mode, including the NUL-separated
  `N<TAB>command` form used when `perl` is present.
- How does the key find the exact entry? Candidates are fzf's `{2..}` placeholder with a safe quote, or
  the entry number; multi-line commands and `--multi` need checking.
- Should the helper live as a small script under the zsh package or as a function in `fzf.zsh`? A
  function in the interactive shell is not visible to fzf's reload process, so the helper may need to
  be a standalone script. If so, where is it stowed, and does that add a new file to the package?
- Should the backup be a single rolling `.zsh_history.bak` or timestamped, and what limits its growth?
