# Plan: Implement Herdr Session Completion (herdr + fzf-tab)

**Number:** 0022
**Status:** Complete
**Date:** 2026-06-24
**PRD:** 0019
**Architecture:** 0019

## Objective

Add a guarded, authored `_herdr` zsh completion presented through `fzf-tab`: dynamic
session-name completion for `herdr --session`, `herdr session attach|stop|delete`, a
verified static top-level command list, and a read-only session preview. Purely additive —
one new file + one `index.zsh` source line + a herdr `README.md` note. No `plugins.zsh`/
`compinit` change (compinit already runs in `plugins.zsh`, ADR-0049).

## Assumptions

- `herdr` is installed on machines that want completion; it ships **no** native `_herdr`
  and has no `herdr completion` subcommand (verified). The managed layer authors `_herdr`.
- `herdr session list --json` returns `{"sessions":[{"name":...}, ...]}` (verified). `jq`
  parses `.sessions[].name`; without `jq`, `herdr session list | awk 'NR>1 {print $1}'`.
- `compdef` is valid because `compinit` already ran in `plugins.zsh`; `herdr.zsh` is sourced
  after the completion layer, like `taskfile.zsh`.
- No package is added, removed, or first-stowed → **no status-block change** required
  (status-sync self-check passes).
- No implementation runs until this plan is approved.

## Ordered Tasks

### Task 1 — Create `herdr.zsh` (guarded; `_herdr` + `compdef` + read-only preview)

New file `stow/common/zsh/.config/zsh/herdr.zsh`:

```zsh
# herdr.zsh — Herdr completion. Guarded; no-op without `herdr`.
#
# Herdr ships NO native zsh completion (no _herdr on fpath, no `herdr completion`
# subcommand), so this file AUTHORS the completion and registers it with compdef —
# unlike taskfile.zsh, which only tunes the package-shipped _task. Sourced after
# compinit (owned by plugins.zsh, ADR-0049). jq is preferred for parsing; an awk
# fallback keeps session completion working without jq. Nothing here starts, stops,
# attaches, or otherwise mutates a session — only read-only `herdr session list`.

command -v herdr >/dev/null 2>&1 || return

# Dynamic session-name candidates from the live, read-only session list.
_herdr_sessions() {
  local -a sessions

  if command -v jq >/dev/null 2>&1; then
    sessions=("${(@f)$(herdr session list --json 2>/dev/null \
      | jq -r '.sessions[]?.name // empty' 2>/dev/null)}")
  else
    sessions=("${(@f)$(herdr session list 2>/dev/null | awk 'NR > 1 {print $1}')}")
  fi

  compadd -a sessions
}

_herdr() {
  local context state line
  typeset -A opt_args

  _arguments -C \
    '--session[attach to a named Herdr session]:session:_herdr_sessions' \
    '--remote[attach to a remote Herdr host]:remote host:_hosts' \
    '--remote-keybindings[choose keybindings source]:(local server)' \
    '--handoff[use live handoff when supported]' \
    '--no-session[single-process escape hatch]' \
    '--default-config[print default config]' \
    '--version[print version]' \
    '1:command:(session config server status workspace worktree tab pane agent terminal wait integration plugin update channel notification)' \
    '*::arg:->args'

  case "$line[1]" in
    session)
      _arguments -C \
        '1:session command:(list attach stop delete)' \
        '2:session name:_herdr_sessions' \
        '--json[print JSON]'
      ;;
  esac
}

compdef _herdr herdr

# fzf-tab preview for session names. Read-only: lists sessions and filters to the
# highlighted word; never mutates. Falls back to the plain table without jq.
zstyle ':fzf-tab:complete:herdr:*' fzf-preview \
  'herdr session list --json 2>/dev/null | jq -C --arg s "$word" '\''.sessions[]? | select(.name == $s)'\'' 2>/dev/null || herdr session list 2>/dev/null'
```

### Task 2 — Source `herdr.zsh` from `index.zsh`

Add a guarded source line immediately after the `taskfile.zsh` source (step 6b), matching
the existing `[[ -r ... ]] && source` pattern:

```zsh
# 6c) Herdr completion — guarded; no-op without `herdr`.
[[ -r "$HOME/.config/zsh/herdr.zsh" ]] && source "$HOME/.config/zsh/herdr.zsh"
```

### Task 3 — Note in the herdr package README

Add a short section to `stow/common/zsh/README.md` (or the herdr package `README.md`,
whichever documents shell integration) stating: herdr completion is **authored** here
(herdr ships none); `jq` is recommended for best session parsing (awk fallback otherwise);
completion is read-only; and the manual interactive test steps below.

### Task 4 — Validation (read-only)

Run the validation commands below. No build step beyond editing files; no stow, no `$HOME`.

## Files Affected

- `stow/common/zsh/.config/zsh/herdr.zsh` — created
- `stow/common/zsh/.config/zsh/index.zsh` — modified (source line)
- `stow/common/zsh/README.md` (or herdr package README) — modified (note)

No files deleted. No package added/removed/first-stowed → status blocks unchanged.

## Safety Checks

- No `stow`, no symlinks, no writes to `$HOME` anywhere in this plan.
- No `stow --adopt`.
- No dependency install; no network access added to any sourced file.
- Every runtime path is guarded (`command -v herdr`; `command -v jq`; `[[ -r ... ]]`).
- Every herdr invocation is the read-only `herdr session list` (optionally `--json`) —
  never attach/stop/delete/start.
- Audit `git diff` for secrets / machine-specific paths before any commit.

## Validation Commands

```bash
# Syntax-check every managed zsh file (no execution of sourced logic).
zsh -n stow/common/zsh/.config/zsh/*.zsh

# Confirm only the expected files changed.
git status

# Confirm no network/install primitives were introduced into the zsh layer.
grep -REn 'curl|wget|git clone|brew install|pacman|yay|npm i|pip install' \
  stow/common/zsh/.config/zsh/ || echo "clean: no install/network primitives"

# Confirm only read-only `herdr session list` is invoked (no mutating subcommands).
grep -En 'herdr (session attach|session stop|session delete|session start|server stop)' \
  stow/common/zsh/.config/zsh/herdr.zsh && echo "FAIL: mutating call" \
  || echo "clean: no mutating herdr calls"

# Confirm the herdr completion guard is present.
grep -n "command -v herdr" stow/common/zsh/.config/zsh/herdr.zsh
```

Manual interactive test (real machine, after implementation — user-run, optional):

1. Type `herdr session attach ` then press `Tab`.
2. Verify `fzf-tab` lists the host's real sessions; the preview shows the highlighted
   session's status/dir/socket.
3. Select a session; verify the command line becomes `herdr session attach <name>`
   (inserted only, not executed).
4. Verify `herdr --session <Tab>` completes the same list.
5. Verify `herdr <Tab>` offers the top-level command list (incl. `config`).

## Rollback Strategy

All changes are tracked edits; nothing touches `$HOME`. To undo before commit:

```bash
git checkout -- stow/common/zsh/.config/zsh/index.zsh \
                stow/common/zsh/README.md
# Created file (remove if checkout leaves it untracked):
rm -f stow/common/zsh/.config/zsh/herdr.zsh
```

(If already committed and not pushed: `git reset HEAD~1`.)

## Completion Criteria

- [ ] `herdr.zsh` created, guarded by `command -v herdr`, defining `_herdr_sessions`,
      `_herdr`, `compdef _herdr herdr`, and the read-only preview; no execution of
      mutating herdr subcommands, no network, no install.
- [ ] `index.zsh` sources `herdr.zsh` after `taskfile.zsh`.
- [ ] Top-level command list contains only verified-real subcommands (includes `config`).
- [ ] herdr README notes the authored completion, `jq` recommendation, read-only nature,
      and manual test.
- [ ] `zsh -n stow/common/zsh/.config/zsh/*.zsh` passes for all files.
- [ ] `git status` shows only the files listed above; no `$HOME` or stow side effects.
- [ ] No secrets, private, or work-specific values added.
