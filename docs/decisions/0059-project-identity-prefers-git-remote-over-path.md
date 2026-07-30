# ADR 0059 — Project identity prefers the git remote, falling back to canonical paths

**Status:** Accepted
**Date:** 2026-07-31
**Context:** PRD 0021, Architecture 0020, ADR 0058

## Context

The repository ledger needs a stable key for "this project". Candidates: the
working directory, the git top level, or an identity derived from the git remote.

Paths are unstable in ways that matter here. A repository cloned twice, checked
out as a `git worktree`, or moved between `~/work/` and `~/src/` would produce
several unrelated keys and split its totals. Symlinked paths (`/home/x` versus a
`realpath` through another mount) would do the same.

Remotes are stable but not universal: local-only repositories have none, and work
can happen outside a repository entirely.

## Decision

Resolve identity in this order, first match wins:

1. `workspace.repo` from the status line payload → `host/owner/name`, lower-cased
   (`github.com/fnayou/dotfiles`). Free — Claude Code 2.1 already supplies it.
2. `git remote get-url origin`, normalised the same way. Covers versions of
   Claude Code that omit `workspace.repo`.
3. `git rev-parse --show-toplevel`, `realpath`-canonicalised → `path:<real>`.
4. `workspace.project_dir`, canonicalised → `path:<real>`.
5. `workspace.current_dir` / `cwd`, canonicalised → `path:<real>`.

The key stored on disk is `sha1(identity)[0:16]`; the readable identity is kept
inside each ledger file so the cache can be inspected without reversing the hash.

`git@host:owner/name.git`, `https://host/owner/name.git` and
`ssh://git@host:22/owner/name` all normalise to `host/owner/name`.

## Rationale

- Remote identity is the only key that survives re-cloning, moving and worktrees,
  so "savings for this repository" means the repository rather than one checkout
  of it.
- It is preferred but never required — steps 3–5 keep the feature fully working
  in remote-less repositories and outside git, which the PRD requires.
- Canonicalising with `realpath` collapses symlinked equivalents to one key;
  falling back to `path.resolve` when the directory no longer exists means a
  deleted or moved project degrades to an unread stale directory rather than an
  error.
- Hashing keeps directory names fixed-length and filesystem-safe regardless of
  what the identity contains.

## Consequences

- Two clones of one repository aggregate into a single total. Intended; noted in
  the package README because it can surprise.
- A repository that gains an `origin` remote after sessions were recorded under a
  path key starts a new total. Acceptable — the alternative is maintaining a
  rename map for a cache.
- Step 2 spawns `git` only when the payload lacks `workspace.repo`, so the common
  path on Claude Code 2.1 costs no subprocess.
