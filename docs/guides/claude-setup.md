# Claude Code Statusline Package Setup Guide

This guide explains how to set up the managed [Claude Code](https://code.claude.com)
status line on a new machine. It is written for a human user, not for implementation agents.

---

## 1. What this package manages

The `stow/common/claude/` package manages **two** files, stowed into `~/.claude/`:

| Repository file | Symlink created at | Purpose |
|---|---|---|
| `stow/common/claude/.claude/statusline-command.sh` | `~/.claude/statusline-command.sh` | Status line script (mirrors the Oh My Posh Catppuccin Macchiato theme) |
| `stow/common/claude/.claude/statusline-caveman.js` | `~/.claude/statusline-caveman.js` | Caveman segment — mode badge + tokens saved for this session and repository |

`statusline-command.sh` reads the Claude Code status line JSON from stdin once and passes that
copy to the caveman segment, which it finds as its own sibling. Both files must be linked for the
savings figures to appear; with only the first, the segment degrades to a mode badge without a
number.

`stow/common/claude/tests/` holds the segment's tests. It is excluded by `.stow-local-ignore` and
is **never** linked into `$HOME`.

The script renders these segments: **OS icon · model · path · git branch+status · PR/MR ·
context % · optional rtk savings · optional caveman badge**. Its colors are taken from the `omp`
package theme — `omp` remains the theme source of truth.

### What this package deliberately does NOT manage

`~/.claude/` also holds secrets and machine state. **None of the following is ever tracked:**

- `.credentials.json` — authentication tokens
- `settings.local.json` — machine-local overrides
- `projects/`, `sessions/` — session transcripts
- `plugins/` — marketplace-managed, reinstallable
- `history.jsonl`, `*.log`, `stats-cache.json`, caveman runtime files (`.caveman-*`)
- `cache/`, `shell-snapshots/`, `file-history/`, `backups/`, `daemon/`, `jobs/`

Only `statusline-command.sh` is a stow source, so these can never be swept into version control.

---

## 2. Platform notes

This package lives under `stow/common/` and is shared across macOS and Arch. The script is
OS-portable: it detects the platform at runtime (macOS / Arch / EndeavourOS / generic Linux) to
pick the OS glyph, and uses `$HOME` everywhere. The path `~/.claude/statusline-command.sh` is
identical on both platforms.

---

## 3. Prerequisites

GNU Stow, plus `jq` and `git` (used by the script at runtime). A Nerd Font in your terminal is
required for the OS icon and git glyphs to render.

`node` is required only for the caveman savings segment, and only if you use the caveman plugin —
which needs `node` for its own hooks anyway. Without `node` the rest of the status line is
unaffected and the caveman segment falls back to a mode badge with no number.

### macOS

⚠️  MANUAL STEP — review before running
```bash
brew install stow jq git
```

### Arch / EndeavourOS

⚠️  MANUAL STEP — review before running
```bash
sudo pacman -S stow jq git
```

Verify:

```bash
jq --version && git --version && stow --version
```

---

## 4. Dry-run step

Always dry-run the Stow package before applying it.

```bash
stow --dir=stow/common --target="$HOME" --no-folding --simulate claude
```

**On most machines you will see a CONFLICT**, because Claude Code already created a real
`~/.claude/statusline-command.sh`:

```
WARNING! stowing claude would cause conflicts:
  * cannot stow .../stow/common/claude/.claude/statusline-command.sh over existing target .claude/statusline-command.sh since neither a link nor a directory and --adopt not specified
All operations aborted.
```

This is expected. Resolve it manually (Section 8) before applying. Do **not** use
`stow --adopt`.

On a machine with no existing file, you instead see a single `LINK:` line and exit code 0.

---

## 5. Apply step (Stow)

After the dry-run reports no conflicts, apply the package:

⚠️  MANUAL STEP — review dry-run output before running
```bash
stow --dir=stow/common --target="$HOME" --no-folding claude
```

**`--no-folding` is required.** `~/.claude` holds your credentials and session data. Without
`--no-folding`, if `~/.claude` did not already exist Stow would create it as a single symlink
pointing at the package directory — shadowing real Claude data behind a repo symlink.
`--no-folding` forces a per-file symlink so only `statusline-command.sh` is linked.

**`stow --adopt` is forbidden.** It silently overwrites the file in `$HOME` with the repository
version, destroying your existing content without a backup.

---

## 6. Wire the status line in Claude Code

Stowing only places the script. Claude Code must be told to run it, via `~/.claude/settings.json`
(this file is **not** managed by the package — keep it local):

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash \"$HOME/.claude/statusline-command.sh\""
  }
}
```

Using `$HOME` (not a hard-coded `/home/<user>` path) keeps it portable across machines. Restart
Claude Code or start a new session to see the status line.

---

## 7. Validation steps

```bash
# ~/.claude must remain a REAL directory, never a folded symlink
test ! -L "$HOME/.claude" && echo "OK: ~/.claude is a real directory"
```

```bash
# Both files should be symlinks resolving into the repository
readlink ~/.claude/statusline-command.sh
readlink ~/.claude/statusline-caveman.js
```

```bash
# Render it directly with a sample payload (should print a colored line)
echo '{"model":{"display_name":"Opus"},"workspace":{"current_dir":"'"$HOME"'"},"context_window":{"used_percentage":12}}' \
  | bash ~/.claude/statusline-command.sh; echo
```

```bash
# Render with a real session payload — the caveman segment needs session_id and
# transcript_path. Substitute a transcript that exists under ~/.claude/projects/.
TX=$(ls -t ~/.claude/projects/*/*.jsonl 2>/dev/null | head -1)
echo '{"session_id":"validate","transcript_path":"'"$TX"'","model":{"display_name":"Opus"},'\
'"workspace":{"current_dir":"'"$PWD"'","project_dir":"'"$PWD"'"}}' \
  | bash ~/.claude/statusline-command.sh; echo
```

```bash
# Run the caveman segment's unit tests (temp cache; never touches $HOME)
task test:statusline
```

```bash
# End-to-end check with synthetic transcripts — sandboxes CLAUDE_CONFIG_DIR and
# XDG_CACHE_HOME, so your real caveman mode flag and cache are never touched.
# Prints PASS/FAIL per assertion; exits 1 if any fail.
task check:statusline
```

---

## 8. Rollback steps

To undo the setup:

⚠️  MANUAL STEP — review before running
```bash
stow --dir=stow/common --target="$HOME" --delete claude
```

This removes the symlink. If you backed up the original file (Section 8 troubleshooting), restore
it. Claude Code falls back to no status line (or its default) until re-wired.

---

## 9. Troubleshooting

### Stow conflict: real file exists at target

Symptom: the dry-run reports `cannot stow ... over existing target .claude/statusline-command.sh`.
This is the normal case — Claude Code wrote a real file there.

Resolution:
1. Inspect the existing file: `ls -la ~/.claude/statusline-command.sh`
2. Compare with the repository version:
   ```bash
   diff ~/.claude/statusline-command.sh stow/common/claude/.claude/statusline-command.sh
   ```
3. If the home file has changes you want, update the repository file first.
4. Back the existing file out of the way:
   ```bash
   mv ~/.claude/statusline-command.sh ~/.claude/statusline-command.sh.bak
   ```
5. Re-run the dry-run to confirm the conflict is gone, then apply (Section 5).

Do NOT use `stow --adopt` — it overwrites without a backup.

### `~/.claude` became a symlink (directory folding)

Symptom: `ls -ld ~/.claude` shows a leading `l` (it is a symlink). This is dangerous — it
shadows your real credentials/sessions. Caused by stowing without `--no-folding`.

Resolution:
1. Remove the fold: `stow --dir=stow/common --target="$HOME" --delete claude`
2. Confirm your real `~/.claude` contents are intact (they live in the repo's package dir only
   for `statusline-command.sh`; everything else should still be your real files — if `~/.claude`
   was folded, restore from backup as needed).
3. Re-apply WITH `--no-folding` (Section 5).
4. Verify: `test ! -L "$HOME/.claude" && echo "OK: real directory"`

### OS icon or git glyphs are blank

Cause: the terminal font is not a Nerd Font, or the glyph is missing. Use a Nerd Font (the
`omp` prompt uses the same glyphs, so if the prompt renders them, the status line will too).

### `ctx` segment missing

`context_window.used_percentage` is `null` before the first API call in a session and right
after `/compact`. The segment is intentionally hidden until a value is available. Requires
Claude Code ≥ 2.1.

### Caveman segment shows a badge but no number

Expected when any of these is true:

- `statusline-caveman.js` is not linked yet — re-run the dry-run and apply steps above.
- `node` is not on `PATH`.
- The active caveman mode is `lite`, `ultra` or a `wenyan-*` variant. Caveman only has
  benchmark data for `full`, so no estimate exists for the others. This is upstream behaviour,
  not a fault in the segment.

### Caveman segment shows `[CAVEMAN:OFF]`

Caveman is installed but no mode is active. Activate one with `/caveman full`.

### Repository total looks too low

It counts only sessions recorded **since this segment was installed**. Earlier sessions cannot be
counted — caveman never recorded which mode they ran in, so their savings are not reconstructable.
See `docs/decisions/0058-repository-savings-use-a-statusline-owned-ledger.md`.

### Two sessions show the same caveman mode

Caveman keeps one mode flag for the whole machine (`~/.claude/.caveman-active`), so concurrent
sessions cannot run different modes and `/caveman off` in one disables it in the other. Upstream
behaviour, documented in `docs/decisions/0060-caveman-global-mode-flag-limitation-accepted.md`.
The **token figures** stay independent per session — those come from separate transcripts.

---

## 10. Expected final file layout

```
~/.claude/
  statusline-command.sh  ->  /path/to/dotfiles/stow/common/claude/.claude/statusline-command.sh
  statusline-caveman.js  ->  /path/to/dotfiles/stow/common/claude/.claude/statusline-caveman.js
  .credentials.json          (real file — NOT managed)
  settings.json              (real file — NOT managed; wires the status line)
  projects/ plugins/ ...     (real dirs — NOT managed)
```

Both `statusline-*.sh|js` entries are symlinks (`->` arrow). `~/.claude` itself is a real
directory, never a symlink.

The segment also writes a cache — a plain directory, not managed by Stow, safe to delete:

```
${XDG_CACHE_HOME:-$HOME/.cache}/claude-statusline/caveman/
  sessions/<session-id>.json   parse offset + running totals for one session
  repos/<hash>/<session-id>.json   one ledger row per session, summed per repository
```
