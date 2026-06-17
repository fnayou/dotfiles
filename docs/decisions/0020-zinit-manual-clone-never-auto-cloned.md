# Decision: Zinit Installed via Documented Manual Clone; Never Auto-Cloned from Shell Startup

**Number:** 0020
**Date:** 2026-06-17
**Status:** Accepted
**PRD:** 0006-shell-dependencies
**Architecture:** 0006-shell-dependencies-architecture

## Context

`zinit` is a zsh plugin manager. Its canonical upstream install is a `git clone`
into `${ZINIT_HOME}`. The upstream-suggested pattern includes an auto-clone block
in `~/.zshrc` that clones zinit on first run if it is not present.

This auto-clone pattern is explicitly rejected by PRD 0006 and Architecture 0006
(Architecture Decision 6) for these reasons:

- Shell startup latency: a `git clone` on first run is slow and blocks shell open.
- Network dependency: shell startup must work offline.
- Silent mutation: a clone is a system change the user should approve and see.
- Non-determinism: auto-clone pulls "latest" at an unpredictable time, causing drift
  between machines.
- Error blast radius: a failing clone in `~/.zshrc` can wedge every new shell.

## Decision

`zinit` is installed via a **documented one-time manual `git clone`** that the user
runs deliberately. The zsh config only **sources** zinit behind a directory-existence
guard and never clones it.

Install command (user-run, one time per machine):

```bash
git clone https://github.com/zdharma-continuum/zinit.git \
  "${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
```

Zsh activation guard (in the managed zsh config — never clones):

```zsh
ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
[[ -f "${ZINIT_HOME}/zinit.zsh" ]] && source "${ZINIT_HOME}/zinit.zsh"
```

`zinit` does not appear in any Brewfile. Detection in `scripts/check-zsh-deps.sh`
checks for the install directory, not a `$PATH` binary.

## Consequences

- Shell startup never performs network operations, package installs, or clones.
- A machine without zinit gets a clean shell — the guard is a no-op.
- The install step is explicit, visible, and user-approved (one-time).
- Plugin management via zinit is deferred to the zsh implementation phase (out of
  scope for PRD 0006 / Plan 0011).
- If zinit moves to a Homebrew formula or AUR package in future, the decision can be
  revisited with a new ADR.
