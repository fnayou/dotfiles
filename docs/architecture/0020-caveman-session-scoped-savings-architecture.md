# Architecture 0020 — Caveman session-scoped savings

**Status:** Approved
**PRD:** `docs/prd/0021-caveman-session-scoped-savings.md`
**Amended by:** `docs/decisions/0066-caveman-seam-detected-by-capability-not-version.md`

> **Amendment (2026-08-18, ADR 0066).** This document describes caveman 1.x's
> module seam. Caveman 2.0 changed `deriveSavings` from
> `({ outputTokens, mode, model })` to `({ byMode, model })` and added
> `attributeByMode` / `readModeLog` to bucket tokens by the mode active when each
> message was written. Both contracts are supported, selected by capability
> probe. The architecture below is otherwise unchanged; the v1 signatures it
> quotes are now one of two. Sections affected are marked inline.

---

## Context

The status line is a single bash script, `stow/common/claude/.claude/statusline-command.sh`,
stowed to `~/.claude/statusline-command.sh` with `--no-folding`. Claude Code
2.1.220 pipes a JSON payload to it on stdin. The script reads it once into
`$input` and queries it with `jq`.

The observed payload (captured on this machine, 2.1.220) contains:

```json
{
  "session_id":     "5e7b3c0d-…",
  "transcript_path":"/home/…/.claude/projects/-home-fnayou-work-dotfiles/5e7b3c0d-….jsonl",
  "cwd":            "/home/fnayou/work/dotfiles",
  "model":          { "id": "claude-opus-5", "display_name": "Opus 5" },
  "workspace":      { "current_dir": "…", "project_dir": "…",
                      "repo": { "host": "github.com", "owner": "fnayou", "name": "dotfiles" } },
  "context_window": { … }
}
```

`workspace.repo` is present only when the workspace has a recognised remote.

Caveman is installed as an **upstream git checkout** at
`~/.claude/plugins/marketplaces/caveman` (remote `juliusbrussee/caveman`, branch
`main`, clean tree), mirrored to a hash-named copy under
`~/.claude/plugins/cache/caveman/caveman/<sha>/`. Both are marketplace-managed
and are replaced on plugin upgrade.

Caveman's relevant surface:

| File | Role |
|---|---|
| `src/hooks/caveman-config.js` | `readFlag` (symlink-safe, whitelisted mode read), `readHistory`, `safeWriteFlag`, `appendFlag` |
| `src/hooks/caveman-stats.js` | `parseSession`, `deriveSavings`, `humanizeTokens`, `aggregateHistory` — all exported. **2.x adds** `attributeByMode`, `readModeLog`, `deriveNet`, `ruleOverheadPerTurn`, `outputReductionPct` |
| `src/hooks/caveman-statusline.sh` | mode badge + savings suffix; the current integration seam |
| `~/.claude/.caveman-active` | single global file holding the active mode |
| `~/.claude/.caveman-history.jsonl` | append log, written **only** by `/caveman-stats` |
| `~/.claude/.caveman-statusline-suffix` | pre-rendered machine-wide lifetime figure |
| `~/.claude/.caveman-mode-log.jsonl` | **2.x only** — append log of mode transitions, used for per-message attribution |

`deriveSavings` is the estimator:
`estNormal = round(outputTokens / (1 - ratio))`, `saved = estNormal - outputTokens`,
with `ratio = 0.65` for mode `full` and **undefined for every other mode** — so
`lite`, `ultra` and the `wenyan-*` modes legitimately produce no figure.

Its input shape differs by version (ADR 0066):

```
1.x  deriveSavings({ outputTokens, mode, model })   one mode for the whole session
2.x  deriveSavings({ byMode, model })               tokens pre-bucketed per mode
```

Under 2.x the bucketing comes from `attributeByMode`, which slices the session's
per-message records against `.caveman-mode-log.jsonl`, falls back to the mode
flag's mtime when no log exists, and declines to attribute at all when neither is
available — a session that switched modes partway is never credited wholesale.

## Proposed architecture

A new Node segment script, `statusline-caveman.js`, shipped in the same stow
package. `statusline-command.sh` reads stdin once (it already does) and pipes the
stored payload into the segment. The segment prints the finished, coloured
segment text, or nothing.

```
Claude Code ──stdin──▶ statusline-command.sh
                          │ input=$(cat)          (read once)
                          │
                          ├─▶ jq  … existing segments, unchanged …
                          │
                          └─▶ printf '%s' "$input" | node statusline-caveman.js
                                       │
                                       ├─ require(caveman-config.js)  → readFlag  [2.x: + MODE_LOG_BASENAME]
                                       ├─ require(caveman-stats.js)   → parseSession, deriveSavings, humanizeTokens
                                       │                                [2.x: + attributeByMode, readModeLog]
                                       ├─ transcript_path             → session totals
                                       └─ ledger dir                  → repository total
```

### Why Node rather than bash + jq

The estimator and the transcript parser are Node functions caveman already
exports. Calling them directly is exact reuse; reimplementing
`round(t/(1-0.65)) - t` and the compression table in bash would fork the
algorithm and drift on the next caveman release. Node is already a hard
dependency of the caveman plugin itself, so it costs nothing new.

`jq` stays the tool for the existing segments — it is already a documented
prerequisite of this package.

### Session savings — the primary figure

Computed **only** from `payload.transcript_path`:

```
parseSession(transcript) → { outputTokens, model, turns }   [2.x: + messages[]]

# caveman 1.x
deriveSavings({ outputTokens, mode, model }) → estSavedTokens

# caveman 2.x — see ADR 0066
attributeByMode({ messages, modeLog, mode, flagMtimeMs, outputTokens }) → { byMode }
deriveSavings({ byMode, model }) → estSavedTokens
```

The transcript is per-session by construction — Claude Code names it
`<projects>/<encoded-cwd>/<session-id>.jsonl`. Nothing about any other session
can enter this number. This satisfies the primary requirement with zero
dependence on caveman's history file, and therefore zero dependence on the user
having ever run `/caveman-stats`.

`mode` is read with caveman's own `readFlag`, which enforces the symlink refusal,
the 64-byte cap and the mode whitelist. We do not re-implement that check.

### Cost and the incremental cache

Full parse of the largest transcript on this machine (5.0 MB) costs 43 ms, plus
48 ms of node start-up. Acceptable today at the status line's 300 ms debounce,
but transcripts grow without bound.

The segment therefore keeps a per-session cache under
`${XDG_CACHE_HOME:-$HOME/.cache}/claude-statusline/caveman/sessions/` holding the
byte offset already accounted for plus the running totals. Transcripts are
append-only, so a warm render parses only the new tail.

Correctness is protected two ways: the cold path calls caveman's `parseSession`
verbatim, and a full reparse is forced whenever the file is shorter than the
cached offset (rewrite, rotation, or a different file at the same path). An
automated test asserts the incremental path and `parseSession` agree on a real
transcript.

### Repository savings — the secondary figure

Caveman's `.caveman-history.jsonl` cannot support this. It carries `session_id`
but no project or repository field, and it is appended **only** when the user
runs `/caveman-stats` — two rows exist for this machine's entire history.
Aggregating it per repository would require both patching caveman (an upstream
checkout that plugin upgrades overwrite) and accepting that almost every session
is missing. Either way the total would be wrong.

Instead the status line keeps its **own ledger**, which it is uniquely well
placed to maintain: it runs constantly, and every render already knows the
session id, the project and the exact session figure it just computed.

```
${XDG_CACHE_HOME:-$HOME/.cache}/claude-statusline/caveman/repos/<key-hash>/<session-id>.json
```

One file per session. The repository total is the sum over the directory. This
makes double-counting structurally impossible — a session cannot contribute twice
because it owns exactly one file, rewritten in place with its latest value. No
snapshot-versus-final ambiguity, no "latest per session" reduction, no dedup
logic to get wrong. Malformed files are skipped individually.

### Project identity

`<key-hash>` is `sha1(identity)[0:16]`, with `identity` resolved in this order:

1. `workspace.repo` from the payload → `host/owner/name`, lower-cased
   (`github.com/fnayou/dotfiles`). Free — no subprocess.
2. `git remote get-url origin` from the workspace dir, normalised the same way,
   covering Claude Code versions that omit `workspace.repo`.
3. `git rev-parse --show-toplevel`, `realpath`-canonicalised, prefixed `path:`.
4. `workspace.project_dir`, canonicalised, prefixed `path:`.
5. `workspace.current_dir` / `cwd`, canonicalised, prefixed `path:`.

Remote identity is preferred so that two clones or two worktrees of one
repository aggregate together, which is what "savings for this repository" should
mean. It is never *required* — steps 3–5 keep the feature working outside git and
in remote-less repositories. The human-readable identity is stored inside each
ledger file so the cache is debuggable without reversing the hash.

Canonicalisation is `fs.realpathSync`, falling back to `path.resolve` when the
directory has been deleted or moved — a stale ledger directory is then simply
never read again, which is the graceful outcome.

### Rendering

Same colour (256-colour 172) and same badge shape as caveman's own script, so the
segment is visually unchanged apart from the numbers:

| State | Output |
|---|---|
| mode `full`, session only | `[CAVEMAN] ⛏ 68.3k` |
| mode `full`, repo has more | `[CAVEMAN] ⛏ 68.3k sess · 844.7k repo` |
| mode `ultra` (no benchmark) | `[CAVEMAN:ULTRA]` |
| caveman installed, inactive | `[CAVEMAN:OFF]` |
| caveman not installed | *(nothing)* |
| any failure | *(nothing)* |

`⛏` is written as `'⛏'` in source, keeping the file pure ASCII — the same
rule the script already applies to its Nerd Font glyphs.

### Degradation without Node

If `node` is absent the script falls back to caveman's own
`caveman-statusline.sh` with `CAVEMAN_STATUSLINE_SAVINGS=0`. That yields the mode
badge and **no number** — degrading to less information rather than to the wrong
information, per PRD safety requirement 6.

## Decisions

1. Implement as a separate Node file in the `claude` stow package, not as a patch
   to the caveman checkout. See ADR 0056.
2. Session savings come from `transcript_path` alone, never from
   `.caveman-history.jsonl`. See ADR 0057.
3. Repository savings come from a status-line-owned one-file-per-session ledger,
   not from caveman's history. See ADR 0058.
4. Reuse `deriveSavings` / `parseSession` / `humanizeTokens` / `readFlag`
   verbatim; implement only the incremental tail accumulation locally, verified
   equal to `parseSession` by test. Select the `deriveSavings` contract by
   capability probe, never by version string. See ADR 0066.
5. Prefer remote-derived repository identity, with a canonicalised-path fallback
   chain. See ADR 0059.
6. Leave caveman's global mode flag alone. See ADR 0060.

## Risks

| Risk | Mitigation |
|---|---|
| Caveman upgrade renames or drops the exported functions | Every `require` and every property access is guarded; a missing export degrades to the mode badge alone. A test pins the expected exports so breakage surfaces as a test failure, not a broken status line. |
| Caveman upgrade changes an export's **arguments** while keeping its name | **This mitigation was missing and the risk materialised in caveman 2.0.** A `typeof x === 'function'` guard cannot see a signature change: v1 arguments passed to v2's `deriveSavings` return `0` without throwing, so the badge stayed lit while the figure silently vanished. Now handled by capability probing (`attributeByMode` / `readModeLog`) with both call shapes covered by tests that stand in for each version. See ADR 0066. |
| Caveman upgrade moves the hooks directory | Path is discovered, never hardcoded: `$CAVEMAN_HOOKS_DIR`, then `marketplaces/`, then newest `cache/` checkout by mtime. Same globbing the script already uses. |
| Transcript grows to tens of MB | Incremental byte-offset cache; warm renders parse only the tail. |
| Cache corruption | Every read is `try`-wrapped and validated; a bad file is ignored, a bad cache entry forces a full reparse. |
| Ledger grows unbounded | One small file per session. Entries older than 90 days are pruned opportunistically. |
| `deriveSavings` returns 0 USD for `claude-opus-5` | Upstream's price table only matches `claude-*-4` prefixes. We display tokens, never USD, so this does not affect us. Noted for upstream. |
| Two sessions in different caveman modes | Not solvable here — caveman's mode flag is global. Documented in ADR 0060 and in the package README. |

## Open questions

None blocking. One upstream opportunity is recorded in ADR 0058: caveman could
add `project_dir` / `repo` to its own history records, which would let any
consumer compute repository totals without a private ledger. That is a proposal
for upstream, not a prerequisite here.

## Recommended next step

Planner: produce `docs/plans/0024-implement-caveman-session-scoped-savings.md`.
