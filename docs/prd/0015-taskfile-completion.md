# PRD: Interactive Taskfile Completion (go-task + fzf-tab)

**Number:** 0015
**Status:** Approved
**Date:** 2026-06-22

> **Process note:** Follows the `AGENTS.md` §6 chain — PRD → Architecture → Review →
> Plan → Build → Review → Commit. This document precedes any zsh implementation.

## Goals

- Enable interactive, contextual completion of [go-task](https://taskfile.dev) tasks
  in the managed zsh layer.
- Target workflow:
  1. Type `task ` and press `Tab`.
  2. See a contextual `fzf-tab` list of the current directory's Taskfile tasks (with
     descriptions where the Taskfile provides them).
  3. Select one.
  4. The selection is **inserted only**; the user presses `Enter` at the prompt to run
     `task <selected>`.
- Use **native** go-task zsh completion as the source of task candidates — no custom
  parser, no `fzf-make`, no standalone launcher command.
- Let `fzf-tab` render the native completion menu naturally (it already wraps the zsh
  completion UI repo-wide).
- Ship the behavior as a new managed file `stow/common/zsh/.config/zsh/taskfile.zsh`,
  sourced from `index.zsh`, fully guarded by `command -v task`.

## Non-Goals

- Installing go-task, `fzf`, `fzf-tab`, or `zinit` on any machine.
- Creating a standalone launcher command (e.g. a `taskmenu` widget). Deferred.
- Creating aliases for `task`. Deferred.
- Executing any task during completion or preview.
- Vendoring the upstream `_task` completion file into the repo.
- Running `stow`, creating symlinks, or modifying `$HOME`.

## User Stories

- As a user, I want `task <Tab>` to show my Taskfile's tasks in an fzf picker so I can
  pick a task without remembering its exact name.
- As a user, I want task descriptions shown in the picker so I can choose by intent.
- As a user, I want selection to only fill in the command line — never auto-run — so I
  stay in control of execution.
- As a user, I want this guarded so a machine without `task` installed starts a clean
  shell with no errors.

## Constraints

- **Platform:** go-task is cross-platform — `brew install go-task` (macOS),
  `pacman -S go-task` (Arch). Both package installs ship a native `_task` completion file
  into the default zsh `fpath` site-functions directory
  (`/usr/local/share/zsh/site-functions/_task` or `/opt/homebrew/...` on macOS;
  `/usr/share/zsh/site-functions/_task` on Arch). Package goes in `stow/common/`.
- **Completion mechanism:** `task --completion zsh` emits only a `compdef _task task`
  registration shim — it does **not** define the completion logic. The logic lives in the
  `_task` file shipped by the package manager. With `_task` on `fpath`, `compinit`
  autoloads it via its `#compdef task` tag with zero extra code. Sourcing
  `task --completion zsh` therefore adds nothing when `_task` is present and is useless
  when it is absent (it references a missing `_task`).
- **Install path assumption:** Native completion is available when `task` is installed via
  Homebrew or pacman. Non-package installs (`go install`, raw `install.sh` to
  `~/.local/bin`) do not ship `_task`; for those, native completion is unavailable without
  manually placing the upstream `_task` file — documented as a known limitation.
- **Ordering:** `taskfile.zsh` sets completion `zstyle`s only, so it must be sourced after
  `compinit`. It must not need to run before `compinit` (the `_task` autoload is handled by
  the package + `fpath`, not by this file).
- **Safety:** No symlinks, no writes to `$HOME`, no `stow --adopt`, no network access.
- **Privacy:** `taskfile.zsh` contains only completion configuration — no secrets, no
  machine-specific paths.

## Safety Requirements

- Must not execute any Taskfile task during completion or preview.
- Must not install `task`, `fzf`, `fzf-tab`, or `zinit`.
- Must not run `stow` automatically, create symlinks, or modify `$HOME`.
- Must not use `stow --adopt`.
- Must be a no-op on machines without `task` (guarded by `command -v task`).
- Must provide a dry-run `stow --simulate` command for the user before any activation.

## Acceptance Criteria

- [ ] `stow/common/zsh/.config/zsh/taskfile.zsh` created, guarded by `command -v task`.
- [ ] `index.zsh` sources `taskfile.zsh` after `completions.zsh` (after `compinit`),
      with the same `[[ -r ... ]] && source` guard used by every other layer.
- [ ] With `task` installed via brew/pacman, `task <Tab>` shows tasks through `fzf-tab`
      with descriptions; selection inserts only and does not execute.
- [ ] No-op clean shell on a machine without `task`.
- [ ] No secrets or machine-specific values in any committed file.
- [ ] The pre-existing `fzf-tab` load-order question (see architecture) is resolved as a
      **separate, decoupled** decision and does not block this feature.
- [ ] Stale `local.zsh.example` entries (extended eza aliases; zoxide `--cmd cd`) cleaned
      up or confirmed in scope.
- [ ] PRD/Architecture approved before the plan; plan approved before build.

## Open Questions

- Resolved (approved full scope). The `task` preview is included as a read-only
  `task --summary "$word" 2>/dev/null || task --list-all 2>/dev/null`, and the fzf-tab
  load-order fix is folded into this milestone with ADR-0049 superseding ADR-0046.

## Out of Scope

- Standalone task launcher command / widget.
- `task` aliases.
- Vendoring the `_task` completion file.
- Activating the Stow package (stowing to `$HOME`) in this milestone.
