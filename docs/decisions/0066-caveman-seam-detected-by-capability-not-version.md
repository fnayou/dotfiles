# ADR 0066 — The caveman seam is detected by capability, not by version

**Status:** Accepted
**Date:** 2026-08-18
**Context:** ADR 0056, ADR 0057, ADR 0058

## Context

ADR 0057 pinned the status line to two of caveman's exports, used unmodified:

```
parseSession(transcript_path)                    → { outputTokens, model, turns }
deriveSavings({ outputTokens, mode, model })     → estSavedTokens
```

Caveman 2.0 changed the second one:

```js
// caveman 1.x
function deriveSavings({ outputTokens, mode, model })
// caveman 2.x
function deriveSavings({ byMode, model })
```

The reason upstream changed it is sound. A session can switch modes partway
through, and crediting the whole session to whichever mode the flag names *now*
invents savings that were never made. v2 buckets tokens by the mode that was
active when each message was written — `attributeByMode` slices the per-message
array against a transition log at `~/.claude/.caveman-mode-log.jsonl`, falling
back to the flag file's mtime, and declining to guess when neither is available.

The failure mode this creates for us is the dangerous kind. Passing v1 arguments
to v2 does not throw: `byMode` arrives `undefined`, the loop over its entries
never runs, and `estSavedTokens` comes back `0`. The status line keeps rendering,
the badge stays lit, and the savings figure silently disappears. The repository
ledger stops accumulating too, because `updateLedger` is only reached when
`sessionSaved > 0`.

Our existing guard did not catch it. It checked `typeof deriveSavings ===
'function'`, which is true for both shapes.

Worse, the break does not wait for a deliberate upgrade. `findHooksDir()` prefers
`plugins/marketplaces/caveman/src/hooks`, and that path is a live git checkout
that Claude Code updates when the marketplace is refreshed. The statusline can
therefore load v2 code while the plugin itself is still pinned to an older
commit.

Verified against upstream `766dce6` (v2.1.0) with `CAVEMAN_HOOKS_DIR` pointed at
a real v2 checkout: the pre-change script rendered `[CAVEMAN]`, the current one
renders `[CAVEMAN] ⛏ 3.7k`, and v1 renders `⛏ 3.7k` as before.

## Decision

`deriveSessionSavings()` calls whichever contract the installed caveman exposes,
choosing between them by probing for members, not by reading a version:

```js
const v2 = typeof cav.attributeByMode === 'function'
        && typeof cav.readModeLog    === 'function';
```

`attributeByMode` and `readModeLog` were added in the same change that altered
`deriveSavings`, so their presence is a reliable proxy for the new signature.

Both branches are wrapped so that any throw returns `0` — a bare badge, never a
wrong number. Nonsense return values (`NaN`, negative, non-numeric) are rejected
the same way.

To feed the v2 branch, the session cache now stores the per-message
`{ ts, outputTokens }` array that v2's `parseSession` returns. `accumulate()`
builds it unconditionally, so the cache shape does not depend on which caveman
was installed when the entry was written. A cache entry without it — one written
by the previous version of this script — is treated as cold and reparsed.

## Rationale

- **No version string exists.** Caveman ships no version to its hooks. The plugin
  manifest records a git SHA, not a semver, so there is nothing to compare
  against even if we wanted to.
- **Capability probing degrades honestly.** If upstream removes
  `attributeByMode`, the probe fails closed to the v1 branch; if it removes
  `deriveSavings` entirely, the existing seam check returns before we render.
- **Both paths stay covered by tests.** Only one caveman can be installed at a
  time, so `tests/statusline-caveman.test.js` drives faithful stand-ins for both
  contracts, copied from upstream's implementations. The v2 stub returns `0` for
  v1-shaped arguments exactly as the real one does, which is what makes the
  regression assertion load-bearing rather than decorative.
- **Still no fork of the estimator.** ADR 0057's rule holds — we call caveman's
  functions, we do not reimplement them. This change only picks the right call.

## Consequences

- ADR 0057's stated call signature is now one of two. That record is amended
  rather than superseded: its decision (derive from `transcript_path`, never from
  `.caveman-history.jsonl`) is unchanged.
- Session cache entries are larger — one record per assistant turn, roughly 40
  bytes each. Past `MAX_CACHED_MESSAGES` (20 000 turns) the messages are dropped
  from the cache rather than allowed to grow without bound, and renders for that
  session fall back to a full reparse: slower, still correct.
- All cache entries written before this change are invalidated once. The next
  render per session reparses in full.
- Under v2 the figure can legitimately be **lower** than under v1 for the same
  session. Tokens produced before the mode flag was written are no longer
  credited, which is the point of the upstream change.
- `deriveNet` and `ruleOverheadPerTurn`, new in v2, are deliberately not used.
  They subtract the rules' own prompt overhead from gross savings. Adopting them
  would make the badge inconsistent with itself across versions; that is a
  separate decision, to be taken once v2 is actually installed.
- We remain on caveman 1.x. This change makes the upgrade safe to perform at any
  time rather than requiring the status line to be fixed in the same step.
