# ADR 0056 — The caveman status line segment lives in dotfiles, not in the plugin

**Status:** Accepted
**Date:** 2026-07-31
**Context:** PRD 0021, Architecture 0020

## Context

Caveman is installed as a Claude Code plugin. On this machine that means a git
checkout at `~/.claude/plugins/marketplaces/caveman` (remote
`juliusbrussee/caveman`, branch `main`), plus a hash-named mirror at
`~/.claude/plugins/cache/caveman/caveman/<sha>/`.

Making the status line show session-scoped savings could have been done in three
places:

1. Patch `caveman-stats.js` / `caveman-statusline.sh` in place.
2. Fork caveman, install from the fork, carry the change there.
3. Implement it in this repository, in the `claude` stow package, reading
   caveman's exported functions.

## Decision

Option 3. `stow/common/claude/.claude/statusline-caveman.js` is ours; caveman's
checkout is read-only to us.

## Rationale

Both plugin directories are managed by Claude Code's marketplace machinery and
are **replaced on upgrade**. A local patch there is not version-controlled by
this repository, is invisible to `git status`, and disappears without warning the
next time the plugin updates — the exact "package-manager cache" hazard the
repository's safety rules exclude.

A fork would survive upgrades but makes us the maintainer of a plugin we
otherwise only consume, and would have to be rebased on every upstream release
to keep the caveman skill itself current.

Implementing here keeps the change in the repository that already owns the status
line, reviewed and reverted by the same commit as everything else in the package,
with no effect on how the plugin is installed or upgraded.

## Consequences

- The segment depends on caveman's exported functions across upgrades. Every
  `require` and every export is checked at runtime; a missing export degrades to
  the mode badge alone. `stow/common/claude/tests/statusline-caveman.test.js`
  pins the expectation so a breaking upgrade surfaces as a test failure.
- Caveman's own `caveman-statusline.sh` remains installed and usable; we simply
  stop calling it on the primary path, and call it with
  `CAVEMAN_STATUSLINE_SAVINGS=0` as the degraded fallback.
- The repository-metadata improvement that would benefit every caveman consumer
  (ADR 0058) is a proposal to upstream, not a local patch.
