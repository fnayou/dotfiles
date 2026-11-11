# Decision: Delete History Entries in the fzf Ctrl+R Picker with `ctrl-x` and `exclude`

**Number:** 0087
**Date:** 2026-11-06
**Status:** Accepted
**PRD:** 0035 — Delete History Entries from the fzf Ctrl+R Picker
**Architecture:** 0031 — Delete History Entries from the fzf Ctrl+R Picker

## Context

fzf's Ctrl+R widget (`fzf --zsh`, ADR-0040) lists history entries as numbered records and, when you
pick one, looks the number up in the running shell's memory. A way to delete an entry from the picker
must not break that lookup. fzf can only drop an item by `reload`, which rebuilds the list in another
process from the history file; its numbers then differ from the shell's, and a later selection could
insert the wrong command. zsh cannot remove one entry from a running shell's memory (the `history`
array is read-only), and rewriting the file through `fc -W` lost an entry in testing.

## Decision

- The key is **`ctrl-x`**. `ctrl-d` is not used: in fzf it deletes a character or quits, so a habitual
  press would delete an entry.
- The key runs a helper, then fzf's **`exclude`** action: `execute-silent(helper {f})+exclude`. `exclude`
  hides the item without a reload, so every other entry keeps its number.
- The helper, `stow/common/zsh/.config/zsh/scripts/fzf-history-delete`, **edits the raw history file**:
  it groups lines into entries, removes those whose command exactly equals the highlighted one, and
  copies every other line unchanged. It keeps one backup (`$HISTFILE.bak`), writes a temporary file in
  the same directory and replaces the original in one step. No match means no change.
- The key is set through `FZF_CTRL_R_OPTS` in `fzf.zsh`, only when fzf is 0.60.0 or newer (the version
  that added `exclude`), `perl` is installed (so the widget lists numbered records) and the helper is
  readable. Otherwise there is no key.
- Deletion is **file only**. The running shell keeps the entry in memory until it restarts.

## Consequences

- The entry can reappear in the next Ctrl+R in the same shell, and with `SHARE_HISTORY` another open
  shell can write it back. The guide says so.
- The zsh package gains one new file, so the user re-stows it (dry run first).
- The key needs fzf 0.60.0 or newer; the rest of the package keeps ADR-0040's 0.48 minimum.
- Tested only on macOS (fzf 0.74.5). Arch and Debian are untested.
- A wrapper widget that also clears the in-memory entry stays possible as a later decision. The
  helper would not change.
