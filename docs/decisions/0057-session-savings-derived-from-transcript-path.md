# ADR 0057 — Session savings are derived from `transcript_path`, not from caveman's history

**Status:** Accepted
**Date:** 2026-07-31
**Context:** PRD 0021, Architecture 0020

## Context

Caveman records sessions in `~/.claude/.caveman-history.jsonl`:

```json
{"ts":1781138973863,"session_id":"885cfba4-…","mode":"full","model":"claude-opus-4-8",
 "output_tokens":79668,"est_saved_tokens":147955,"est_saved_usd":11.096625}
```

Each row carries a `session_id`, so filtering the current session out of it looks
like the obvious source for a session-scoped figure.

It is not. Rows are appended **only** by `caveman-stats.js`, which runs only when
the user types `/caveman-stats`. On this machine the file holds two rows for its
entire history, neither of them for a session that is currently running. A status
line reading that file would show nothing for almost every session, and a stale
number for the rest.

Claude Code 2.1 supplies `transcript_path` in the status line payload, pointing at
`~/.claude/projects/<encoded-cwd>/<session-id>.jsonl`.

## Decision

Session savings are computed on every render from `transcript_path` alone:

```
parseSession(transcript_path) → { outputTokens, model, turns }
deriveSavings({ outputTokens, mode, model }) → estSavedTokens
```

Both functions are caveman's own exports, used unmodified.
`.caveman-history.jsonl` and `.caveman-statusline-suffix` are never read.

## Rationale

- **Correct by construction.** The transcript is per-session — Claude Code names
  it after the session id. No other session's tokens can enter the number, so no
  filtering, deduplication or aggregation logic exists to get wrong.
- **Always available.** Works from the first assistant turn, with no dependency
  on the user ever having run `/caveman-stats`.
- **Always current.** Recomputed each render instead of frozen until the next
  manual stats run.
- **No fork of the estimator.** `deriveSavings` is the algorithm
  (`round(t / (1 - 0.65)) - t` for mode `full`); we call it rather than
  reimplementing it, so a change to caveman's benchmark ratio is picked up for
  free.

## Consequences

- The full transcript must be read. Measured at 43 ms for a 5.0 MB transcript,
  plus ~48 ms of node start-up. An append-only byte-offset cache under
  `${XDG_CACHE_HOME:-$HOME/.cache}/claude-statusline/caveman/sessions/` keeps warm
  renders proportional to the appended tail rather than the file size.
- `deriveSavings` has benchmark data for mode `full` only. `lite`, `ultra` and
  the `wenyan-*` modes return 0 and render as a bare badge — the same behaviour
  caveman's own stats output has, and honest about what has been measured.
- Caveman's price table matches `claude-*-4` prefixes only, so `claude-opus-5`
  yields `est_saved_usd: 0`. Irrelevant here: the segment displays tokens, never
  currency. Worth reporting upstream.
- `caveman-stats.js` keeps appending to its history and rewriting its suffix file
  when the user runs `/caveman-stats`. We neither prevent nor rely on that.
