# Architecture: Delete History Entries from the fzf Ctrl+R Picker

**Number:** 0031
**Status:** Approved
**Date:** 2026-11-06
**PRD:** [0035](../prd/0035-fzf-history-delete-keybind.md)

## Context

PRD 0035 adds a `ctrl-x` key to fzf's Ctrl+R history picker that deletes the highlighted entry from
`~/.zsh_history`, keeping fzf's own widget (`fzf --zsh`, ADR-0040) and changing only
`FZF_CTRL_R_OPTS`.

A spike on this machine (fzf 0.74.5, zsh, temporary files only, the real history untouched) found:

1. **The widget maps a chosen entry back to a command by event number, in the live shell's memory.**
   With `perl` it builds `N<TAB>command` records (NUL-separated) from the `history` array and later
   reads `history[N]`; without `perl` it uses `fc -rl 1` and `vi-fetch-history -n N`.
2. **A reload would break that mapping.** `reload` runs in a separate process and can only rebuild the
   list from the history file. Event numbers in a long-lived shell keep growing, and `SHARE_HISTORY`,
   `HIST_IGNORE_ALL_DUPS` and `HISTSIZE=5000` trimming make them differ from positions in the file. After
   a reload, choosing an entry could insert a different command, or none. The PRD's open question about
   rebuilding the list "so the widget's parsing still works" has no safe answer.
3. **fzf 0.74.5 has an `exclude` action** that removes the current item from the list without a reload
   (listed in `man fzf`). It keeps every other item and its original number, so the widget's lookup stays
   correct. I could not drive it headless (`--listen` needs a real terminal), so the first plan task
   verifies it by hand. The fzf version that introduced it is not known yet and is recorded in the plan.
4. **The in-memory history cannot be edited.** In zsh the `history` array is read-only: `unset
   'history[2]'` fails with `read-only variable`. This confirms the PRD non-goal: the entry stays in the
   running shell's memory.
5. **Rewriting the file through zsh is not safe.** A round trip with `fc -R` and `fc -W` did not reload
   every entry in a test file that had a multi-line command and a command ending in `\\`; one entry was
   missing. The helper must edit the raw file text, not rewrite the file from zsh's parsed history.
6. **`execute` and `reload` run in a child shell.** Functions defined in the interactive shell are
   invisible to them, so the delete logic must be a standalone script.

## Proposed Structure

```
stow/common/zsh/.config/zsh/
├── fzf.zsh                      # modified: sets FZF_CTRL_R_OPTS (guarded)
└── scripts/
    └── fzf-history-delete       # new: deletes one entry from $HISTFILE (zsh script)

docs/guides/zsh-setup.md         # modified
docs/decisions/00NN-fzf-history-delete-ctrl-x-exclude.md   # new
```

`fzf.zsh` sets, only when `fzf` and `perl` are present:

```zsh
FZF_CTRL_R_OPTS="--bind 'ctrl-x:execute-silent(zsh \"$HOME/.config/zsh/scripts/fzf-history-delete\" {2..})+exclude'"
```

The exact quoting is settled in the plan's first task. If `FZF_CTRL_R_OPTS` is already set (for example
in `local.zsh`), the bind is appended, not overwritten.

## Design Decisions

### Decision 1: Remove the item with `exclude`, not `reload`

Option A: `ctrl-x:execute-silent(delete)+reload(rebuild from file)`.
  Pro: The list is rebuilt from the real data.
  Con: Renumbers entries, so a later selection can insert the wrong command (finding 2). Needs a copy
  of the widget's own list logic for both modes.

Option B: `ctrl-x:execute-silent(delete)+exclude`.
  Pro: No list rebuild, no renumbering, no copy of widget internals. Smallest change.
  Con: Needs an fzf with the `exclude` action. The item is hidden for that picker session only; the
  entry stays in memory (finding 4), so it can reappear in the next Ctrl+R in the same shell.

Option C: A wrapper widget that snapshots the list and filters it on reload.
  Pro: Safe numbering and a clean list.
  Con: That is the custom widget the PRD excludes (option 2).

Decision: Option B. Raise the minimum fzf version for this key only; the rest of the zsh package keeps
ADR-0040's 0.48 minimum. If the installed fzf lacks `exclude`, the key is not registered.

### Decision 2: Edit the raw history file, in zsh

Option A: Load with `fc -R`, drop the entry, write with `fc -W`.
  Pro: Uses zsh's own parser.
  Con: Lost an entry in the spike (finding 5) and cannot unset in memory; unsafe for a file the user
  cannot recreate.

Option B: A zsh script that reads `$HISTFILE` line by line, groups lines into entries (an entry starts
at `: <time>:<duration>;` and continues while a line ends in an odd number of backslashes), removes the
entries whose command equals the chosen text, and writes the result to a temporary file in the same
directory.
  Pro: Lossless for everything except the removed entries; no extra dependency (zsh is already the
  shell).
  Con: The matching rule must follow zsh's escaping exactly; it is written and tested against a copy.

Option C: `perl` or `awk` one-liner.
  Pro: Short.
  Con: Adds a tool dependency to the helper, and `awk` differs across macOS, Arch and Debian.

Decision: Option B. The script is fail-safe: if the chosen text matches no entry, or more than the
expected entries, it changes nothing and exits non-zero. It deletes every entry with that exact
command text, because `HIST_IGNORE_ALL_DUPS` makes duplicates rare and the user means the command.

### Decision 3: How the key passes the entry

`{2..}` gives the command part of the current item (fzf shell-quotes it). In `perl` mode a multi-line
command arrives with a tab after each newline (the widget adds `\n\t`); the helper removes that tab
before matching. The helper reads the command from its argument and never prints, logs or stores it.

Option A: `{2..}` as an argument. Visible in the process list for the instant the helper runs.
Option B: Put the text in an environment variable, or use fzf's file placeholder.
  Pro: Not visible in `ps`.
  Con: Placeholder support differs between fzf versions; one more thing to verify.

Decision: Option A, with the exposure noted in the guide. The text is the user's own command on their
own machine. The plan's first task tests option B and the plan switches to it if it works on 0.74.5.

### Decision 4: Supported modes

The key is registered only when `perl` is available, because only that mode gives the helper a clean,
numbered record. Without `perl` the widget's list is `fc -rl 1` output, where multi-line commands show
as `\n` text and the match would be guesswork. A missing key is safe; a wrong delete is not.

### Decision 5: Backup and write

The helper copies `$HISTFILE` to `$HISTFILE.bak` (owner-only permissions, overwritten each time),
writes the new content to a temporary file in the same directory with the same permissions, checks it is
non-empty and has fewer entries than the original, then replaces the original in one step. Any failure
leaves the original untouched and removes the temporary file. A rolling single backup bounds disk use;
a timestamped backup would keep secrets around.

### Decision 6: New file means a re-stow

`scripts/fzf-history-delete` is a new file, so the zsh package must be stowed again to link it. The PRD
says no re-stow is needed; that is only true for edits to existing files. The guide gives the dry run
first (`stow --dir=stow/common --target="$HOME" --no-folding --simulate zsh`) and a `MANUAL STEP`
install. `scripts/` is not excluded in `.stow-local-ignore`. The status blocks do not change, because
no package is added.

## Risks

- **Wrong entry deleted.** Escaping rules for backslashes and multi-line commands may not match.
  Mitigation: raw-text matching tested on a copy with multi-line, backslash and look-alike entries;
  a no-match or unexpected match changes nothing.
- **History file damage.** Mitigation: same-directory temp file, one-step replace, single backup,
  size and entry-count checks.
- **Concurrent shells.** With `SHARE_HISTORY`, another open shell can append an entry while the helper
  rewrites the file, or write the deleted entry back from memory. The guide states both. The backup
  keeps the previous content.
- **Stale in-memory entry.** Remains until the shell restarts (PRD non-goal).
- **fzf upgrades.** `exclude` or the widget's record format could change. The key is guarded by a
  version-independent feature check where possible, and the guide says to re-test after an fzf update.
- **Privacy.** The deleted command appears briefly as an argument. Nothing is logged. Backup files
  contain history and stay in `$HOME`, outside the repository; `.gitignore` already ignores
  `*.bak` in the zsh package folder only if one were placed there, so the plan checks that no history
  file is ever under the repository.
- **Cross-platform.** `zsh`, `perl` and `cp` options differ in small ways (BSD vs GNU). The helper
  uses only POSIX options and zsh builtins; the plan tests the permission-preserving copy on macOS and
  notes that Arch and Debian were not tested on this machine.

## Extensibility

- If in-memory removal becomes important, a later PRD can add a wrapper widget (the PRD's option 2);
  the helper script stays the same.
- The same helper can serve other pickers or a `task` that cleans history, with the matching rule
  already tested.
- `exclude-multi` can later delete the multi-selected items with a loop in the helper.

## Open Questions

- ~~Which fzf version introduced `exclude`?~~ Resolved: 0.60.0; the key checks the version.
- Does `{2..}` or an alternative placeholder survive every character a command can contain (quotes,
  `$`, backticks, newlines, non-UTF-8)?
- ~~Escaping rule for backslashes in the history file.~~ Resolved: see Spike Results.
- Is a single rolling `.bak` enough, or should the helper keep the last N?

## Spike Results

Plan 0039, Task 1. Run on 2026-11-06 with fzf 0.74.5 and zsh, on temporary files only.

- **`exclude` version.** The fzf changelog shows `exclude` and `exclude-multi` were added in **0.60.0**.
  The key is registered only when `fzf --version` is 0.60.0 or newer. The rest of the package keeps
  the 0.48 minimum (ADR-0040).
- **`exclude` in a real picker.** Not yet confirmed. fzf's `--listen` mode could not be driven headless,
  so the user runs the session-only check from the plan (`FZF_CTRL_R_OPTS="--bind 'ctrl-x:exclude'"`)
  and reports the result.
- **How zsh stores entries** (`EXTENDED_HISTORY`, written by zsh itself):
  - Header `: <time>:<duration>;` then the command. A newline inside a command is stored as a
    backslash followed by a real newline, so a command with a backslash before its newline and one
    without it look the same in the file.
  - A command ending in a backslash is stored with one trailing space added.
  - A literal `\\` pair in a command is stored unchanged. `$`, quotes and backticks are stored
    unchanged.
  - Bytes 0x83 to 0xA2 are escaped: a 0x83 marker byte, then the byte XOR 0x20. Non-ASCII UTF-8 text
    (tested with accented, CJK and symbol characters) therefore appears in the file in escaped form.
- **Matching rule.** The helper decodes each file entry the way zsh reads it (join continuation lines
  into newlines, reverse the byte escape) and compares it to the chosen text after removing the tab the
  widget adds after each newline. If the exact text does not match, it tries once more with one
  trailing space, for the trailing-backslash case. It copies every raw line it keeps byte for byte, so
  the escapes in other entries are untouched. A command typed in the current session with a backslash
  before a newline can differ from its file form; that is a no-match, and nothing is deleted.
- **Placeholder.** Per `man fzf`, a placeholder expands to a quoted string that is safe as an argument;
  a field expression such as `{2..}` strips leading and trailing whitespace unless the `s` flag is
  used (`{s2..}`), and the `f` flag passes a temporary file path instead of the text. The `f` form
  keeps the command out of the process list, so Decision 3 uses it if the picker test shows it works
  with multi-line entries; otherwise the argument form with the `s` flag.
- **Not verifiable headless.** How each placeholder form behaves for a multi-line entry in a live
  picker. The user's test of a multi-line throwaway entry covers it.

## Recommended Next Step

After approval, the Planner writes the plan. Task 1 is a spike with no repository changes: verify
`exclude` by hand in a real terminal, settle the escaping rule and placeholder quoting against a copy
of a history file in a temporary directory, and record the fzf version. The tasks after that create the
helper, the `fzf.zsh` change, the guide section, the ADR and tests on temporary files, with a manual
check in a real picker as the last step.
