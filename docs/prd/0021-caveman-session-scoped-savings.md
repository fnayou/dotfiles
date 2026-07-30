# PRD 0021 — Caveman session-scoped savings in the status line

**Status:** Approved
**Package:** `stow/common/claude`
**Supersedes:** the caveman segment behaviour defined in PRD 0017 (Claude statusline package)

---

## Problem

The status line's caveman segment calls caveman's own
`src/hooks/caveman-statusline.sh`, which renders two things:

1. the active mode badge (`[CAVEMAN]`, `[CAVEMAN:ULTRA]`, …), and
2. a savings suffix read from `~/.claude/.caveman-statusline-suffix`.

That suffix is written by `caveman-stats.js` as the **sum of every session ever
recorded on this machine**, across every project. It is displayed inside a
project-scoped status line, next to a project-scoped `rtk` figure, where it reads
as "tokens saved here". It is not. On this machine it currently reads `421.7k`,
which is the lifetime total of two unrelated sessions.

The number is also stale by construction: the suffix file only changes when the
user runs `/caveman-stats`. Between runs the status line shows a frozen figure.

## Goals

1. Show caveman's **current mode** (unchanged behaviour).
2. Show **estimated tokens saved by the current Claude Code session**, computed
   live from that session's own transcript.
3. Show **cumulative estimated tokens saved for the current repository /
   project**, when it can be derived accurately.
4. Never display a machine-wide lifetime total as though it were project-scoped.

## Non-goals

- Redesigning caveman. The plugin is an upstream git checkout under
  `~/.claude/plugins/`; we do not patch it.
- Replacing caveman's token-estimation model. We reuse its estimator verbatim.
- Fixing caveman's global-mode-flag concurrency limitation (documented, not solved).
- Adding a runtime dependency the repository does not already assume.
- Managing `~/.claude/settings.json` (stays machine-local, per PRD 0017).

## Scope

**Affected:**

- `stow/common/claude/.claude/statusline-command.sh` — caveman segment replaced.
- `stow/common/claude/.claude/statusline-caveman.js` — new segment implementation.
- `stow/common/claude/README.md`, `docs/guides/claude-setup.md` — documentation.
- New ADRs and architecture/plan/review records.

**Not affected:** every other status line segment (OS, model, path, git, PR/MR,
ctx %, rtk) keeps its current logic, formatting, colours and glyphs.

**Not affected:** anything under `~/.claude/plugins/`. Caveman's own files —
`.caveman-active`, `.caveman-history.jsonl`, `.caveman-statusline-suffix` — are
read-only inputs at most; none is written or deleted.

## Safety requirements

1. The caveman segment must never break the status line. Any failure — missing
   node, missing plugin, unreadable transcript, malformed JSON, malformed cache —
   renders nothing and exits 0.
2. Stdin is read exactly once by the top-level script; the payload is handed to
   the segment. No segment reads the original stream.
3. No transcript content, prompt text, or credential ever reaches a cache file,
   a log, or the terminal. Only integer token counts and path/repo identifiers.
4. No file outside the repository is modified except the status line's own cache
   directory under `${XDG_CACHE_HOME:-$HOME/.cache}/claude-statusline/`.
5. No hardcoded username, home path, or repository name. `$HOME`,
   `$CLAUDE_CONFIG_DIR` and `$XDG_CACHE_HOME` only.
6. Degradation must never be *misleading*: if session savings cannot be computed,
   the segment shows the mode badge alone — never a machine-wide number as a
   substitute.

## Acceptance criteria

1. In a session with caveman `full` active, the segment shows a savings figure
   derived only from that session's transcript.
2. Two concurrent sessions in the same repository report **different** session
   figures and the **same** repository figure.
3. A session in repository B never shows repository A's savings.
4. Outside a git repository the segment still renders (path-keyed project).
5. With caveman inactive the segment renders `[CAVEMAN:OFF]` when caveman is
   installed, and renders nothing when it is not installed.
6. A missing, truncated or malformed transcript renders the mode badge alone.
7. A malformed ledger entry is skipped; the rest still aggregate.
8. Deleting the whole cache directory changes nothing except that repository
   history restarts from the sessions still on disk.
9. `bash -n` passes; `node --check` passes; the repository CI hygiene job passes.
10. Removing the new file and reverting one commit restores the previous
    behaviour exactly.
