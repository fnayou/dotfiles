# ADR 0058 — Repository savings use a status-line-owned ledger

**Status:** Accepted
**Date:** 2026-07-31
**Context:** PRD 0021, Architecture 0020

## Context

The status line should also show cumulative savings for the current repository.
Caveman's history rows contain `ts`, `session_id`, `mode`, `model`,
`output_tokens`, `est_saved_tokens`, `est_saved_usd` — and **no project or
repository field**. There is no way to attribute an existing row to a repository.

Making caveman record one would mean patching a marketplace-managed checkout that
upgrades overwrite (see ADR 0056). Even with the patch, rows are only written on
`/caveman-stats`, so almost every session would still be missing and the total
would understate reality by an unknown factor.

Reconstructing history from `~/.claude/projects/<encoded-cwd>/*.jsonl` was also
considered — the directory name does identify the project. But `deriveSavings`
needs the caveman **mode** each past session ran in, and that was never recorded
anywhere per session. Assuming today's mode for every historical transcript would
manufacture a number rather than measure one.

## Decision

The status line keeps its own ledger, one file per session:

```
${XDG_CACHE_HOME:-$HOME/.cache}/claude-statusline/caveman/repos/<sha1(identity)[0:16]>/<session-id>.json
```

```json
{"ts":1785453973222,"session_id":"sess-A1",
 "project":"github.com/fnayou/dotfiles","est_saved_tokens":211560}
```

The repository figure is the sum over the directory. Entries older than 90 days
are pruned opportunistically. Malformed entries are skipped individually.

## Rationale

- The status line is the right writer: it runs on every render, and already knows
  the session id, the project and the exact figure it just computed. No new hook,
  no new process, no dependency on the user running a command.
- **One file per session makes double-counting structurally impossible.** A
  session cannot contribute twice because it owns exactly one file, rewritten in
  place with its latest value. This removes the entire class of bug that an
  append-only log invites — no snapshot-versus-final ambiguity, no "keep the
  latest row per session" reduction, no dedup pass to get wrong.
- Corruption is contained: one unreadable file costs one session, not the total.
- It is a cache, not state. Deleting it loses history and nothing else; the
  current session's own figure is recomputed from its transcript regardless.

## Consequences

- Repository totals start accumulating **from installation**. Sessions that ran
  before this change are not represented and cannot be, because their mode was
  never recorded. The figure is honestly "since this segment was installed"
  rather than "all time" — stated in the package README.
- The ledger lives under `XDG_CACHE_HOME`, so it does not survive a cache wipe.
  That is the correct tier for a derived, regenerable-going-forward number.
- Two clones or two worktrees of the same repository share one identity and
  therefore one total (see ADR 0059). That is intended.
- **Upstream proposal.** The cleanest fix for every caveman consumer is for
  caveman to record project metadata on its own rows:
  ```json
  {"session_id":"…","project_dir":"/canonical/path","repo":"github.com/owner/name","est_saved_tokens":12345}
  ```
  and to write a row per session rather than only on `/caveman-stats`. If that
  lands upstream, this ledger can be deleted and the figure read from caveman
  directly. Filed as a note here so the local ledger is understood as a
  workaround with a known exit, not a permanent parallel datastore.
