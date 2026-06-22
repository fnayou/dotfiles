# Plan: Implement Native Taskfile Completion (go-task + fzf-tab)

**Number:** 0019
**Status:** Complete
**Date:** 2026-06-22
**PRD:** 0015
**Architecture:** 0015

## Objective

Add guarded native go-task zsh completion presented through `fzf-tab` (type `task `, `Tab`
shows tasks, selecting inserts `task <name>`, `Enter` runs it), and in the same milestone
correct the `fzf-tab` load order to the upstream-documented sequence (Architecture Decision
4, Option C).

## Assumptions

- `task` is installed via Homebrew/pacman on machines that want completion, so the package
  ships `_task` into the default `fpath` site-functions dir; `compinit` autoloads it via
  `#compdef task`. (Verified on this host: `/usr/local/share/zsh/site-functions/_task`.)
- `zinit` plugins use `zinit light` only — `zinit light` never calls `compinit` internally,
  so moving `compinit` into `plugins.zsh` keeps exactly one `compinit` per startup path
  (the basis ADR-0046 relied on; this plan supersedes 0046 only for compinit *location*).
- No package is added, removed, or first-stowed → **no status-block change** required
  (status-sync rule self-check passes).
- No implementation runs until this plan is approved.

## Ordered Tasks

Each task is independently verifiable and safe to stop after.

### Task 1 — Reorder `plugins.zsh` to the canonical fzf-tab sequence (Option C)

Move `compinit` into `plugins.zsh`, interleaved so `fpath` is populated before `compinit`
and `fzf-tab` loads after `compinit` but before the widget-wrapping plugins.

Zinit-present branch becomes (in this order):

```zsh
source "$ZINIT_HOME/zinit.zsh"

# Completions onto fpath BEFORE compinit.
zinit blockf for zsh-users/zsh-completions

# Completion system: after fpath plugin, before fzf-tab (ADR supersedes 0046).
autoload -Uz compinit && compinit

# fzf-tab: after compinit, before widget-wrapping plugins.
zinit light Aloxaf/fzf-tab

# Widget-wrapping plugins: after fzf-tab.
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-autosuggestions
```

No-zinit `else` branch keeps the existing error print **and** adds a fallback so native
completion still works without zinit, before `return 1`:

```zsh
print -P "%F{red}%B[ERROR]: Zinit is not installed!%b%f"
print -P "Please install it to load your configuration properly."
autoload -Uz compinit && compinit   # fallback: native completion without zinit
return 1
```

### Task 2 — Trim `compinit` out of `completions.zsh`

Remove the `autoload -Uz compinit && compinit` line (now owned by `plugins.zsh`). Keep all
`zstyle` blocks, the eza/ls fzf-tab previews, and `_comp_options+=(globdots)`. Update the
file's lead comment to state compinit now runs in `plugins.zsh`.

### Task 3 — Create `taskfile.zsh` (guarded; styling + conservative preview)

New file `stow/common/zsh/.config/zsh/taskfile.zsh`:

```zsh
# taskfile.zsh — go-task (Taskfile) completion tuning. Guarded; no-op without `task`.
#
# Native completion comes from the package-shipped `_task` file on the default fpath
# (Homebrew: .../share/zsh/site-functions/_task; Arch: /usr/share/zsh/site-functions/_task),
# autoloaded by compinit via its `#compdef task` tag. This file only tunes presentation.
# Sourced after compinit. Nothing here installs, fetches, or executes a task.

command -v task >/dev/null 2>&1 || return

# Show task descriptions in completion candidates (fzf-tab renders this list).
zstyle ':completion:*:*:task:*' verbose true

# Conservative fzf-tab preview: read-only. `--summary` prints the highlighted task's
# summary; falls back to `--list-all` when the task has no summary so the pane is never
# empty. Both print text only and never execute a task. Used when fzf-tab/fzf are active;
# harmless zstyle otherwise.
zstyle ':fzf-tab:complete:task:*' fzf-preview \
  'task --summary "$word" 2>/dev/null || task --list-all 2>/dev/null'
```

### Task 4 — Source `taskfile.zsh` from `index.zsh`

Add a guarded source line immediately after the `completions.zsh` source (after compinit
ordering is satisfied), matching the existing `[[ -r ... ]] && source` pattern, e.g.:

```zsh
# 6b) Taskfile (go-task) completion tuning — guarded; no-op without `task`.
[[ -r "$HOME/.config/zsh/taskfile.zsh" ]] && source "$HOME/.config/zsh/taskfile.zsh"
```

Renumber the trailing comments if the house style requires strict sequential numbers.

### Task 5 — Clean stale `local.zsh.example` guidance

Remove the two outdated example blocks (Architecture Decision 5):

- Extended eza aliases (`alias ll='eza -lh' && alias la='eza -lha'`) — contradicts ADR-0042
  / ADR-0044 and duplicates `aliases.zsh`'s `ll`.
- zoxide `--cmd cd` override — redundant; `tools.zsh` already does this (ADR-0047).

Keep the location-specific weather alias example.

### Task 6 — Write ADR superseding 0046 (compinit location)

Create `docs/decisions/0049-compinit-moves-to-plugins-for-fzf-tab-order.md`: context (fzf-tab
must load after compinit and before widget plugins; zsh-completions must precede compinit;
both live in `plugins.zsh`), decision (compinit interleaved in `plugins.zsh`, fallback in the
no-zinit branch, `completions.zsh` becomes styles-only), consequences, and `Supersedes: 0046`.
Update ADR-0046 `Status:` to `Superseded` with a pointer to 0049.

### Task 7 — Update zsh setup guide

Add a short note to the zsh setup guide (`docs/guides/zsh-setup.md` if present) / the zsh
package `README.md`: native `task` completion requires a brew/pacman install (ships `_task`);
note the fzf-tab order change; document the manual interactive test.

### Task 8 — Validation (read-only)

Run the validation commands below. No build step beyond editing files; no stow, no `$HOME`.

## Files Affected

- `stow/common/zsh/.config/zsh/taskfile.zsh` — created
- `stow/common/zsh/.config/zsh/index.zsh` — modified (source line)
- `stow/common/zsh/.config/zsh/plugins.zsh` — modified (reorder + compinit + fallback)
- `stow/common/zsh/.config/zsh/completions.zsh` — modified (remove compinit; comment)
- `stow/common/zsh/.config/zsh/local.zsh.example` — modified (remove 2 stale examples)
- `docs/decisions/0049-compinit-moves-to-plugins-for-fzf-tab-order.md` — created
- `docs/decisions/0046-compinit-unconditional-zinit-light-mode.md` — modified (Superseded)
- `docs/guides/zsh-setup.md` and/or `stow/common/zsh/README.md` — modified (note)

No files deleted. No package added/removed/first-stowed → status blocks unchanged.

## Safety Checks

- No `stow`, no symlinks, no writes to `$HOME` anywhere in this plan.
- No `stow --adopt`.
- No dependency install; no network access added to any sourced file.
- Every new runtime path is guarded (`command -v task`; zinit presence; `[[ -r ... ]]`).
- Preview uses `task --summary` (text only) — never `--dry`/`-n`, never executes a task.
- Audit `git diff` for secrets / machine-specific paths before any future commit.

## Validation Commands

```bash
# Syntax-check every managed zsh file (no execution of sourced logic).
zsh -n stow/common/zsh/.config/zsh/*.zsh

# Confirm only the expected files changed.
git status

# Confirm no network/install primitives were introduced into the zsh layer.
grep -REn 'curl|wget|git clone|brew install|pacman|yay|npm i|pip install' \
  stow/common/zsh/.config/zsh/ || echo "clean: no install/network primitives"

# Confirm compinit appears only in plugins.zsh (both branches), not completions.zsh.
grep -RIn 'compinit' stow/common/zsh/.config/zsh/

# Confirm the task completion guard is present.
grep -n "command -v task" stow/common/zsh/.config/zsh/taskfile.zsh
```

Manual interactive test (real machine, after implementation — user-run, optional):

1. `cd` into a project containing a `Taskfile.yml`.
2. Type `task ` then press `Tab`.
3. Verify `fzf-tab` lists the Taskfile's tasks (with descriptions where defined).
4. Select a task; verify the command line becomes `task <selected-task>` (inserted only).
5. Press `Enter` only for a known-safe task to confirm execution.

## Rollback Strategy

All changes are tracked edits; nothing touches `$HOME`. To undo before commit:

```bash
git checkout -- stow/common/zsh/.config/zsh/taskfile.zsh \
                stow/common/zsh/.config/zsh/index.zsh \
                stow/common/zsh/.config/zsh/plugins.zsh \
                stow/common/zsh/.config/zsh/completions.zsh \
                stow/common/zsh/.config/zsh/local.zsh.example
# Created files (remove if checkout leaves them as untracked):
rm -f stow/common/zsh/.config/zsh/taskfile.zsh \
      docs/decisions/0049-compinit-moves-to-plugins-for-fzf-tab-order.md
```

(If already committed and not pushed: `git reset HEAD~1`.)

## Completion Criteria

- [ ] `taskfile.zsh` created, guarded by `command -v task`, with `verbose true` and the
      read-only `--summary` → `--list-all` preview; no execution, no network, no install.
- [ ] `index.zsh` sources `taskfile.zsh` after `completions.zsh`.
- [ ] `plugins.zsh` loads in order: zsh-completions → compinit → fzf-tab →
      syntax-highlighting → autosuggestions; no-zinit branch has a fallback `compinit`.
- [ ] `completions.zsh` no longer calls `compinit`; styles/previews retained.
- [ ] `local.zsh.example` no longer suggests daily eza aliases or zoxide `--cmd cd`.
- [ ] ADR-0049 created; ADR-0046 marked `Superseded`.
- [ ] zsh setup guide / package README notes the brew/pacman requirement + order change.
- [ ] `zsh -n stow/common/zsh/.config/zsh/*.zsh` passes for all files.
- [ ] `git status` shows only the files listed above; no `$HOME` or stow side effects.
- [ ] No secrets, private, or work-specific values added.
