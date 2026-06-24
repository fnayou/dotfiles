# Architecture: Interactive Herdr Session Completion (herdr + fzf-tab)

**Number:** 0019
**Status:** Approved
**Date:** 2026-06-24
**PRD:** 0019 (`docs/prd/0019-herdr-completion.md`)

## Context

The user wants `herdr session attach <Tab>` (and `stop`/`delete`, plus the global
`herdr --session <Tab>`) to present a contextual `fzf-tab` picker of the host's real Herdr
sessions, with a read-only preview, selection inserting only. This mirrors the
taskfile-completion milestone (PRD/Arch 0015) for a different tool.

Probing the live macOS machine established the decisive facts:

- **Herdr ships no native zsh completion.** No `_herdr` exists on any `fpath`
  site-functions dir (`/usr/local/share/zsh/site-functions`, `/usr/share/zsh/site-functions`),
  and there is no `herdr completion` subcommand. This is the **inverse** of go-task, which
  ships `_task` so PRD 0015 only needed presentation tuning. Here the managed layer must
  **author** the completion function and register it with `compdef`.
- `herdr session list --json` emits a stable, scriptable shape (verified):

  ```json
  {"sessions":[
    {"default":true,"name":"default","running":false,"session_dir":"...","socket_path":"..."},
    {"default":false,"name":"home","running":true,"session_dir":"...","socket_path":"..."}
  ]}
  ```

  `jq -r '.sessions[].name'` yields the session names. Plain `herdr session list` prints a
  table whose first column is the name (header on line 1).
- All top-level subcommands the user listed were checked against `herdr --help` and direct
  `herdr <cmd> --help` probes. `config` exists and was **missing** from the user's draft
  list; `terminal` and `plugin` exist (real, though absent from the `--help` usage block).
  `--remote-keybindings` accepts `<local|server>` (default `local`).

This reframes the work: unlike taskfile, the feature is **not** delivered by the package
manager. The managed layer owns a guarded `herdr.zsh` that defines `_herdr`, sources session
candidates live, and adds a read-only `fzf-tab` preview.

## Proposed Structure

```
stow/common/zsh/.config/zsh/
├── index.zsh        # adds a guarded source of herdr.zsh after taskfile.zsh
└── herdr.zsh        # NEW — guarded _herdr + compdef + read-only session preview
```

`index.zsh` source order becomes:

```
... 6)  completions.zsh   # completion STYLES only (compinit ran in plugins.zsh)
    6b) taskfile.zsh      # task zstyles + preview → after compinit
    6c) herdr.zsh   NEW   # _herdr + compdef + session preview → after compinit
    7)  keybindings.zsh ...
```

No `plugins.zsh`/`compinit` change is needed — `compinit` already runs in `plugins.zsh`
(ADR-0049), and `compdef` is valid after it. This milestone is purely additive: one new
file + one source line (+ a README note). Much smaller than 0015.

## Design Decisions

### Decision 1: Author `_herdr` + `compdef`, because Herdr ships no native completion

```
Option A: Tune only (mirror taskfile.zsh: zstyle-only, rely on a native _herdr).
  Pro: Smallest, lowest-maintenance file.
  Con: Impossible — no _herdr exists on fpath and there is no `herdr completion`
       subcommand. There is nothing to tune.

Option B: Author a guarded _herdr function and register it with `compdef _herdr herdr`.
  Pro: The only way to get herdr completion at all; gives full control over the dynamic
       session surface and the static command list.
  Con: The managed layer now owns completion logic that can drift if herdr's CLI changes.

Decision: Option B. herdr.zsh defines `_herdr` and calls `compdef _herdr herdr`. It is
guarded by `command -v herdr` and sourced after compinit (so compdef is available).
```

### Decision 2: Dynamic session candidates via `herdr session list`, jq-preferred with awk fallback

```
Option A: jq on `herdr session list --json`, parse `.sessions[].name`.
  Pro: Robust, exact field; matches the verified JSON shape.
  Con: Requires jq.

Option B: Plain `herdr session list` → `awk 'NR>1 {print $1}'`.
  Pro: No jq dependency; name is column 1.
  Con: Brittle if the table format changes.

Decision: Both — jq when available, awk fallback otherwise (graceful degradation per the
PRD). The `_herdr_sessions` helper picks the path at runtime via `command -v jq`. Both
paths run only the read-only `herdr session list`; neither mutates a session.
```

The user's draft jq had defensive branches for array shapes and `.session`/`.id` keys. The
real shape is always `{"sessions":[{"name":...}]}`, so the helper is trimmed to the verified
`.sessions[].name` (with `// empty`) — accurate over speculative.

### Decision 3: Static top-level command list — verified, not guessed

```
Option A (lean): Complete only --session and the session subcommand surface; offer no
                 top-level command list. `herdr <Tab>` gives nothing.
  Pro: Nothing static to rot.
  Con: `herdr <Tab>` is a dead key; weaker UX.

Option B (verified static list): Offer the full top-level command list, but only after
                 confirming every entry exists on this host.
  Pro: `herdr <Tab>` is useful; herdr's command set is stable.
  Con: Could drift if herdr removes/renames a command (low; ADR-tracked, easy to edit).

Decision: Option B. The earlier "lean" reasoning was that a static list is drift-prone
guesswork — but every entry was verified real (and `config`, missing from the draft, was
added). With verification the drift risk drops to "herdr changes its CLI," which is a
cheap one-line edit. Dynamic **session** completion remains the primary value; the static
command list is a verified convenience.
```

Final command list (all verified to exist):
`session config server status workspace worktree tab pane agent terminal wait integration
plugin update channel notification`.

### Decision 4: Read-only fzf-tab session preview (filter the live list by selected word)

```
Option A: zstyle ':fzf-tab:complete:herdr:*' fzf-preview filters `herdr session list --json`
          to the highlighted session via jq, falling back to the plain table.
  Pro: Shows status/dir/socket for the highlighted session while browsing; read-only.
  Con: Spawns `herdr session list` per preview render (cheap, local socket read).

Option B: No preview.
  Con: No inline info — rejected; the user explicitly wants the taskfile-style preview.

Decision: Option A. The preview runs only `herdr session list [--json] | jq` — never
attach/stop/delete/start. Mirrors taskfile.zsh's read-only `--summary` preview philosophy.
```

### Decision 5: Scope limited to the session surface

Deep-completing every subcommand's flags/positionals (workspace, pane, agent, worktree,
plugin, channel, integration, tab, notification, wait, terminal) is explicitly out of scope
(PRD Non-Goals). Those get only the static top-level token; their sub-surface is left to
herdr's own future completion. This caps the maintenance surface to the part with real,
dynamic value (sessions).

## Risks

- **CLI drift:** herdr adds/renames a top-level command or changes the `session list --json`
  shape → static list or jq filter goes stale. Mitigation: every entry verified now; small,
  isolated, one-file edit to fix; guarded so a mismatch never errors the shell.
- **Per-completion subprocess:** each TAB/preview spawns `herdr session list` (socket read).
  Heavier than taskfile's local `--summary`, but local and fast. Acceptable for interactive
  use; not run at shell startup.
- **No-herdr / no-jq machines:** guarded by `command -v herdr` (no-op) and `command -v jq`
  (awk fallback). Clean shell either way.
- **Ordering:** `compdef` needs compinit first; satisfied by sourcing after the completion
  layer in `index.zsh` (compinit owned by `plugins.zsh`, ADR-0049). No `plugins.zsh` change.
- **Reversibility:** one new file + one source line; trivially reversible, no `$HOME` change.
- **Privacy:** file holds only completion logic; session metadata is read live at runtime,
  never committed.

## Extensibility

- Additional dynamic surfaces (e.g. `herdr workspace <Tab>` from `workspace list --json`) can
  be added to `_herdr` later without touching source order — same guarded file.
- If herdr ships a native `_herdr` upstream someday, this file can be reduced to tuning-only
  (the taskfile model) or removed.

## Open Questions

- None. Scope (verified static list + dynamic session completion + read-only preview),
  data source (jq/awk), and ordering (additive, after compinit) are all resolved.

## Recommended Next Step

Approve PRD 0019 + this architecture, then produce **`docs/plans/0022-implement-herdr-completion.md`**:

1. Create guarded `herdr.zsh` — `_herdr_sessions` (jq/awk), `_herdr` (global flags + verified
   command list + `session` subcommand with dynamic name), `compdef`, read-only preview.
2. Source `herdr.zsh` from `index.zsh` after `taskfile.zsh`.
3. Note in the herdr package `README.md`: completion is authored (herdr ships none), needs
   `jq` for best parsing, read-only; manual interactive test steps.
4. Validation (`zsh -n`, no install/network primitives, guard present); `stow --simulate`
   dry-run shown to the user (no stow run by any agent).

No package added/removed/first-stowed → **no status-block change**. No implementation until
the plan is approved.
