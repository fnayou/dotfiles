# PRD: Interactive Herdr Session Completion (herdr + fzf-tab)

**Number:** 0019
**Status:** Approved
**Date:** 2026-06-24

> **Process note:** Follows the `AGENTS.md` §6 chain — PRD → Architecture → Review →
> Plan → Build → Review → Commit. This document precedes any zsh implementation.
> Mirrors the taskfile-completion milestone (PRD 0015) for a different tool.

## Goals

- Enable interactive, contextual completion of [Herdr](https://herdr.dev) named
  **sessions** in the managed zsh layer, presented through `fzf-tab`.
- Target workflow:
  1. Type `herdr session attach ` (or `stop`/`delete`) and press `Tab`.
  2. See an `fzf-tab` list of the host's real Herdr sessions, sourced live from
     `herdr session list --json`.
  3. Select one — the selection is **inserted only**; the user presses `Enter` to run.
  4. The same dynamic session list backs the global launch flag `herdr --session <Tab>`.
- Provide a read-only `fzf-tab` preview that shows the highlighted session's metadata
  (status, directory, socket) — never starts, stops, or mutates a session.
- Author a guarded `_herdr` completion function, because **Herdr ships no native zsh
  completion** (no `_herdr` on `fpath`, no `herdr completion` subcommand). This differs
  from go-task, which ships `_task` and only needed presentation tuning (PRD 0015).
- Ship the behavior as a new managed file `stow/common/zsh/.config/zsh/herdr.zsh`,
  sourced from `index.zsh`, fully guarded by `command -v herdr`.

## Non-Goals

- Installing `herdr`, `jq`, `fzf`, `fzf-tab`, or `zinit` on any machine.
- Creating a standalone launcher command, widget, or `herdr` aliases.
- Starting, stopping, attaching, or otherwise mutating any session during
  completion or preview.
- Exhaustively completing every subcommand's flags and positionals (workspace, pane,
  agent, worktree, etc.). Only the high-value **session** surface is dynamic; the
  top-level command list is a static convenience.
- Running `stow`, creating symlinks, or modifying `$HOME`.

## User Stories

- As a user, I want `herdr session attach <Tab>` to show my real sessions in an fzf
  picker so I can attach without retyping awkward names like `working-ansiblify.server`.
- As a user, I want `herdr --session <Tab>` to complete the same live session list.
- As a user, I want a preview pane showing the highlighted session's status/directory so
  I can pick the right one by intent, not just name.
- As a user, I want selection to only fill the command line — never auto-run — so I keep
  control of execution.
- As a user, I want this guarded so a machine without `herdr` starts a clean shell with
  no errors, and degraded (but functional) when `jq` is absent.

## Constraints

- **Platform:** Herdr is cross-platform (macOS + Arch); the `herdr` package already lives
  in `stow/common/`. The completion file is platform-neutral and belongs in
  `stow/common/`. No package-manager-specific commands appear in the file.
- **No native completion to lean on:** Verified on this host — no `_herdr` exists on any
  `fpath` site-functions dir, and `herdr completion` is not a subcommand. Therefore the
  file must **author** `_herdr` and register it with `compdef`, not merely set `zstyle`s
  (the key structural difference from `taskfile.zsh`).
- **Data source:** `herdr session list --json` emits `{"sessions":[{"name":...,
  "running":...,"default":...,"session_dir":...,"socket_path":...}, ...]}` (verified).
  `jq` parses the `name` field. A plain-text fallback (`herdr session list` →
  `awk 'NR>1 {print $1}'`) is used when `jq` is absent — session name is column 1.
- **Ordering:** `herdr.zsh` calls `compdef`, which requires `compinit` to have already
  run. `compinit` runs in `plugins.zsh` (ADR-0049); `herdr.zsh` must be sourced after
  that, alongside the existing `taskfile.zsh` source line in `index.zsh`.
- **Safety:** No symlinks, no writes to `$HOME`, no `stow --adopt`, no network access.
  Every dynamic path spawns only read-only `herdr session list` (optionally piped to
  `jq`/`awk`) — never an attach/stop/delete/start.
- **Privacy:** `herdr.zsh` contains only completion logic — no secrets, no
  machine-specific paths. The preview reads live session metadata at runtime; nothing is
  committed.

## Safety Requirements

- Must not start, stop, attach, delete, or otherwise mutate any Herdr session during
  completion or preview — read-only `herdr session list` only.
- Must not install `herdr`, `jq`, `fzf`, `fzf-tab`, or `zinit`.
- Must not run `stow` automatically, create symlinks, or modify `$HOME`.
- Must not use `stow --adopt`.
- Must be a no-op on machines without `herdr` (guarded by `command -v herdr`).
- Must degrade gracefully without `jq` (plain-text `awk` fallback for session names).
- Must provide a dry-run `stow --simulate` command for the user before any activation.

## Acceptance Criteria

- [ ] `stow/common/zsh/.config/zsh/herdr.zsh` created, guarded by `command -v herdr`,
      defining `_herdr` + `compdef _herdr herdr`.
- [ ] `index.zsh` sources `herdr.zsh` after the completion layer (after `compinit`),
      with the same `[[ -r ... ]] && source` guard used by every other layer.
- [ ] `herdr session attach <Tab>` / `stop` / `delete` and `herdr --session <Tab>` show
      live sessions via `fzf-tab`; selection inserts only and does not execute.
- [ ] The top-level command list offered for `herdr <Tab>` contains only verified-real
      subcommands (includes `config`; no invented commands).
- [ ] An `fzf-tab` preview shows the highlighted session's metadata, read-only.
- [ ] No-op clean shell on a machine without `herdr`; functional (text fallback) without
      `jq`.
- [ ] No secrets or machine-specific values in any committed file.
- [ ] `zsh -n` passes for every managed zsh file.
- [ ] PRD/Architecture approved before the plan; plan approved before build.

## Out of Scope

- Standalone herdr launcher command / widget.
- `herdr` aliases.
- Dynamic completion of non-session subcommands' flags/positionals (workspace, tab,
  pane, agent, worktree, plugin, channel, integration, etc.).
- Activating/stowing the package to `$HOME` in this milestone (already stowed; no
  re-stow required for a new file inside an already-stowed package, but no stow command
  is run by any agent).
