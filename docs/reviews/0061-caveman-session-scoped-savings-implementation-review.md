# Review 0061 — Caveman session-scoped savings implementation

**Date:** 2026-07-31
**Reviewed:** Plan `docs/plans/0024-implement-caveman-session-scoped-savings.md` (all tasks)
**PRD:** `docs/prd/0021-caveman-session-scoped-savings.md`
**Architecture:** `docs/architecture/0020-caveman-session-scoped-savings-architecture.md`

---

## Summary

Reviewed the implementation of Plan 0024: replacing the status line's machine-wide
caveman savings suffix with a session-scoped figure derived from the current
transcript, plus a repository-scoped cumulative figure from a status-line-owned
ledger.

Files created:

- `stow/common/claude/.claude/statusline-caveman.js`
- `stow/common/claude/tests/statusline-caveman.test.js`
- `docs/prd/0021-…`, `docs/architecture/0020-…`, `docs/plans/0024-…`
- `docs/decisions/0056-…` through `0060-…`

Files modified:

- `stow/common/claude/.claude/statusline-command.sh` — caveman segment replaced;
  explicit `exit 0` added
- `stow/common/claude/.stow-local-ignore` — exclude `tests/`
- `stow/common/claude/README.md`, `docs/guides/claude-setup.md`
- `Taskfile.yml` — `test:statusline`
- `.github/workflows/ci.yml` — run the segment tests

## Blocking issues

None outstanding. Three were found and fixed during implementation:

1. **`accumulate` threw on a bare `null` JSONL record.** `JSON.parse("null")`
   succeeds and returns `null`, so the `try/catch` around the parse does not
   cover the subsequent property access. Caught by the malformed-input test.
   Fixed with an explicit null check. Caveman's own `parseSession` has the same
   defect, so the cold path's call to it is now wrapped as well.

2. **The status line could exit non-zero on an ordinary render.** The final
   statement was a `[[ -n "$badge" ]] && printf …` short-circuit, which returns 1
   whenever the badge is empty — the normal case when caveman is inactive or
   absent. Pre-existing, surfaced by the caveman-absent test. Fixed with an
   explicit `exit 0`.

3. **`tests/` would have been stowed to `$HOME/tests`.** The package installs
   with `--no-folding`, so a new top-level directory in the package becomes a
   link target in `$HOME`. Caught by the mandatory dry-run before any install.
   Fixed by adding `^/tests$` to `.stow-local-ignore`; the dry-run now reports
   exactly one new link.

## Non-blocking observations

- Caveman's price table (`MODEL_OUTPUT_PRICE_PER_M`) matches `claude-*-4`
  prefixes only, so `claude-opus-5` yields `est_saved_usd: 0`. Harmless here —
  the segment renders tokens, never currency. Worth reporting upstream, along
  with the `null`-record defect in (1).
- Repository totals begin accumulating at install; earlier sessions cannot be
  counted because caveman never recorded their mode. Documented in ADR 0058 and
  in the package README rather than papered over with an estimate.
- The segment adds roughly 50–70 ms per render, dominated by Node start-up
  rather than by parsing. Measured below.

## Verdicts

### Safety — PASS

- No file under `~/.claude/plugins/` is read-write; the caveman checkout is
  untouched (`git -C ~/.claude/plugins/marketplaces/caveman status` stays clean).
- No caveman state file is written or deleted. `.caveman-active` is read through
  caveman's own `readFlag`, which enforces symlink refusal, a 64-byte cap and a
  mode whitelist. `.caveman-history.jsonl` and `.caveman-statusline-suffix` are
  never opened.
- The only writes outside the repository are under
  `${XDG_CACHE_HOME:-$HOME/.cache}/claude-statusline/caveman/`, created 0700 with
  0600 files, written atomically via temp + rename.
- No `rm`, `mv` or `ln -s` against `$HOME` in any shipped file. Stow is not run by
  any script; the re-stow is a documented manual step with a dry-run first.
- Every failure path in the segment prints nothing and exits 0; `main()` is
  wrapped so the status line cannot fail because of it. Verified with a missing
  transcript, a malformed transcript, a corrupt cache, a corrupt ledger, an empty
  payload, an absent plugin and an absent `node`.
- One stray cache file (`sessions/e2e-session.json`) created by an early test run
  was removed, and the e2e tests now redirect `XDG_CACHE_HOME` for the subprocess
  so they cannot touch the real cache again.

### Privacy — PASS

- No token, key, password, hostname or credential in any added file.
- Cache and ledger records contain only integers, a session UUID and a project
  identifier. No prompt text, no transcript content, no message bodies. The
  transcript is read for `usage` counters only.
- Nothing is written to stderr on a normal render; verified empty.
- The only `fnayou/dotfiles` strings are in test fixtures asserting remote
  normalisation — the repository's own public identity, already in the README.
- No hardcoded home path or username in shipped code: `$HOME`,
  `$CLAUDE_CONFIG_DIR`, `$XDG_CACHE_HOME` and payload-supplied paths only.

### Cross-platform — PASS

- No package-manager commands introduced. `node` is documented as a prerequisite
  only for this segment, and only when caveman is in use — which already requires
  `node` for its own hooks.
- Path handling is `path.join` / `os.homedir()` throughout; no `/` literals in
  constructed paths.
- The segment resolves as a sibling of `statusline-command.sh` via `BASH_SOURCE`,
  with the no-slash case guarded, so it works stowed, from the repository, and on
  macOS's bash 3.2 (no negative array subscripts, no bash-4-only syntax added).
- `findHooksDir` handles both plugin layouts and picks the newest cache checkout
  by mtime, matching the rule the script already used.

### Documentation — PASS

- Commands in the README and guide are copy-pasteable; the install step keeps the
  dry-run-first pattern and the `⚠️ MANUAL STEP` marker.
- The guide gains four troubleshooting entries covering the states a user will
  actually hit: badge without a number, `[CAVEMAN:OFF]`, a low repository total,
  and two sessions showing one mode.
- Both the "what this package manages" tables now list two files, and the
  expected final layout shows both symlinks plus the cache directory.
- ADRs 0056–0060 record why the plugin is not patched, why the transcript is the
  session source, why the ledger exists, how project identity resolves, and the
  accepted concurrency limitation with a concrete upstream-shaped fix.

## Validation performed

`task test:statusline` — 27 tests, 27 pass, 0 fail.
With the plugin hidden (CI simulation) — 23 pass, 4 skip, 0 fail.
`bash -n` on all shell scripts, `node --check` on both JS files — pass.

End-to-end matrix, driving the real `statusline-command.sh` with synthetic
payloads against a sandboxed `XDG_CACHE_HOME`:

| # | Scenario | Result |
|---|---|---|
| 1 | Repo A, session 1 | `[CAVEMAN] ⛏ 290.0k` — session figure only |
| 2 | Repo A, session 2 | `⛏ 776.4k sess · 1.1M repo`; re-render of session 1 gives `290.0k sess · 1.1M repo`. Distinct sessions, shared and correctly summed repo total (289 985 + 776 418) |
| 3 | Repo B | `⛏ 18.4k` — no trace of repo A |
| 4 | Outside git | renders, keyed `path:/tmp/tmp.…` |
| 5 | Caveman installed, no mode | `[CAVEMAN:OFF]` |
| 6 | Caveman absent | no caveman segment; rest of line intact |
| 7 | `node` absent | `[CAVEMAN]` bare badge, no number |
| 8 | Corrupt `.caveman-history.jsonl` | unaffected — never read |
| 9 | Ledger inspection | one file per session; no duplicates |
| 10 | stderr on normal render | empty |
| 11 | Exit code, plugin present and absent | 0 in both |

Repeat renders are idempotent: re-rendering a session does not inflate its own
or the repository's total.

Stow dry-run (`--no-folding --simulate`) reports exactly one new link,
`.claude/statusline-caveman.js`, with `tests/` excluded and the existing
`statusline-command.sh` link untouched.

Timing, measured directly:

| Case | Cold | Warm |
|---|---|---|
| 1.0 MB transcript | 74 ms | 57 ms |
| 5.0 MB transcript | 122 ms | 68 ms |
| bare `node -e 0` (floor) | 50 ms | — |

The incremental cache does its job: the 5 MB case drops from 122 ms to 68 ms, and
the residue is Node start-up rather than parsing. Whole-status-line render is
~114 ms warm, against a 300 ms debounce.

## Status block check

Per `.claude/rules/status-sync.md`: this change adds no Stow package, removes
none, and first-stows none. The existing `claude` package gains one file.
**No status block update required** in `AGENTS.md` or `CLAUDE.md`.

## Recommended next action

The `claude` package needs a re-stow to link the new file — a manual step for the
user, dry-run first, per `.claude/rules/stow.md`. Until then the status line
degrades correctly to a bare `[CAVEMAN]` badge, which was confirmed live.

**Plan 0024: Complete.** No blocking issues.
