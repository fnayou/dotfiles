# Decision: HISTFILE at `$HOME/.zsh_history`, Not XDG

**Number:** 0038
**Date:** 2026-06-19
**Status:** Accepted
**Related:** PRD-0010, Architecture-0010 §10

## Context

The XDG Base Directory specification defines `$XDG_STATE_HOME` (defaulting to `~/.local/state`) as the conventional location for application state files, including shell history. A strict XDG-first approach would place `$HISTFILE` at `${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history`.

However, `$HISTFILE` is not exported by this managed layer as an XDG path. Three reasons drive this choice.

## Decision

`$HISTFILE` is set to `$HOME/.zsh_history`:

```zsh
export HISTFILE="$HOME/.zsh_history"
```

Reasons:

1. **zsh default.** `$HOME/.zsh_history` is zsh's built-in default. Users who have existing history files at this path do not lose history on switching to the managed layer. Moving to an XDG path would silently orphan existing history.

2. **No directory-creation side effect.** Setting `$HISTFILE` to `${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history` requires `~/.local/state/zsh/` to exist. Creating directories at shell startup is a side effect. `$HOME/.zsh_history` requires no directory creation — `$HOME` always exists.

3. **`XDG_STATE_HOME` complexity.** This managed layer does not export `$XDG_STATE_HOME` (it is not part of the commonly-supported XDG trio: config, data, cache). Using it for `$HISTFILE` would introduce a dependency on a variable that may not be set, requiring an additional `:-` fallback and a directory-creation guard.

## Consequences

- History files remain at `$HOME/.zsh_history` — the location most users already have and most tools expect.
- Users who want XDG-style history placement override `$HISTFILE` in `local.zsh`.
- No directory is created at shell startup as a side effect of this setting.
- This is a conservative default. The XDG alternative is documented in a comment in `shared.zsh.example` for users who prefer it.
