# Plan 0024 — Implement caveman session-scoped savings

**Status:** Complete — implementation review [0061](../reviews/0061-caveman-session-scoped-savings-implementation-review.md), no blocking issues
**PRD:** `docs/prd/0021-caveman-session-scoped-savings.md`
**Architecture:** `docs/architecture/0020-caveman-session-scoped-savings-architecture.md`
**Later amended by:** ADR [0066](../decisions/0066-caveman-seam-detected-by-capability-not-version.md) — caveman 2.0 changed the `deriveSavings` signature; the seam is now selected by capability probe. Does not reopen this plan.

---

## Objective

Replace the status line's machine-wide caveman savings suffix with a
session-scoped figure computed from the current transcript, plus a
repository-scoped cumulative figure from a status-line-owned ledger.

## Assumptions

- Claude Code ≥ 2.1 supplies `session_id` and `transcript_path` in the status
  line payload (verified on 2.1.220).
- `node` is on `PATH` when the caveman plugin is in use (caveman's own hooks
  require it).
- The caveman checkout is read-only to us.

## Ordered tasks

1. Add `stow/common/claude/.claude/statusline-caveman.js` — the segment
   implementation (payload on stdin, segment text on stdout, always exit 0).
2. Replace the caveman block in `stow/common/claude/.claude/statusline-command.sh`
   so it pipes the already-captured `$input` to the new segment, with the
   `CAVEMAN_STATUSLINE_SAVINGS=0` fallback when `node` is absent.
3. Add `stow/common/claude/tests/statusline-caveman.test.js` — automated
   assertions for the parser equivalence, ledger aggregation, identity
   resolution, and the malformed-input cases.
4. Add a `test:statusline` Taskfile task that runs the test with `node --test`.
5. Update `stow/common/claude/README.md` and `docs/guides/claude-setup.md`:
   new segment behaviour, the new file, the cache locations, the concurrency
   limitation, and the re-stow step.
6. Add ADRs 0056–0060.
7. Validate (below). Record results in `docs/reviews/0061-…`.

## Files affected

- `stow/common/claude/.claude/statusline-caveman.js` — created
- `stow/common/claude/.claude/statusline-command.sh` — modified (caveman block only)
- `stow/common/claude/tests/statusline-caveman.test.js` — created
- `stow/common/claude/README.md` — modified
- `docs/guides/claude-setup.md` — modified
- `Taskfile.yml` — modified (one task)
- `docs/prd/0021-…`, `docs/architecture/0020-…`, `docs/plans/0024-…`,
  `docs/decisions/0056-…`–`0060-…`, `docs/reviews/0061-…` — created

No status block change: no stow package is added, removed, or first stowed. The
existing `claude` package gains one file.

## Safety checks

- No file under `~/.claude/plugins/` is written.
- No caveman state file (`.caveman-active`, `.caveman-history.jsonl`,
  `.caveman-statusline-suffix`) is written or deleted.
- The only writes outside the repository are under
  `${XDG_CACHE_HOME:-$HOME/.cache}/claude-statusline/`.
- No `rm`, `mv`, or `ln -s` against `$HOME`.
- Stow is not run by any script; the re-stow is a documented manual step.
- No secrets: the new file contains no tokens, hostnames, or usernames.

## Validation commands

Read-only / repository-local:

```bash
bash -n stow/common/claude/.claude/statusline-command.sh
node --check stow/common/claude/.claude/statusline-caveman.js
node --test stow/common/claude/tests/statusline-caveman.test.js
task test:statusline
```

End-to-end, driving the real script with a synthetic payload (writes only to the
status line cache dir):

```bash
printf '%s' "$PAYLOAD" | bash stow/common/claude/.claude/statusline-command.sh
```

Scenario matrix to cover: current session; second session, same repo; different
repo; no git repo; caveman disabled; caveman absent; missing transcript;
malformed transcript; malformed ledger entry; node absent.

## Rollback strategy

```bash
git revert <commit>
```

Then remove the now-unreferenced symlink and cache:

```bash
rm -f "$HOME/.claude/statusline-caveman.js"
rm -rf "${XDG_CACHE_HOME:-$HOME/.cache}/claude-statusline/caveman"
```

Both targets are files this feature created; neither is a user dotfile. The
status line reverts to caveman's own badge + lifetime suffix with no further
action.

## Completion criteria

- All ten PRD acceptance criteria demonstrated.
- Automated test passes.
- Existing segments byte-identical in output for an unchanged payload, except the
  caveman segment.
- Review recorded with no blocking issues.
