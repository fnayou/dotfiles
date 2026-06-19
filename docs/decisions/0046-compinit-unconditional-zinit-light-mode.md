# Decision: `compinit` Runs Unconditionally — Zinit Guard Removed

**Number:** 0046
**Date:** 2026-06-19
**Status:** Accepted
**Supersedes:** 0039

## Context

ADR-0039 placed a `typeset -f zinit` guard before `compinit` in `completions.zsh` to
prevent double-initialization when Zinit is loaded:

```zsh
if ! typeset -f zinit >/dev/null 2>&1; then
  autoload -Uz compinit && compinit
fi
```

Two factors make this guard unnecessary in the current configuration:

1. **Zinit light-mode does not call `compinit`.** All plugins in `plugins.zsh` use
   `zinit light`. The `zinit light` mode does not trigger `compinit` internally. It is
   the `zinit load` + `zinit cdreplay` pattern that would. Under `zinit light`, Zinit
   calls `compinit` zero times — the guard prevented a problem that did not exist.

2. **Load order is correct.** `completions.zsh` is sourced at step 6, after `plugins.zsh`
   at step 5 (`index.zsh`). The guard would have fired correctly based on the function
   check, but since Zinit never calls `compinit` in light mode, the guard's protection
   was vacuous.

## Decision

Remove the Zinit guard. `completions.zsh` calls `compinit` unconditionally:

```zsh
autoload -Uz compinit && compinit
```

This is simpler and more honest — the guard implied a risk that did not apply to the
current `zinit light` setup.

## Consequences

- One unconditional `compinit` call per shell start. No double-init risk.
- `completions.zsh` no longer needs to know whether Zinit is loaded.
- If plugin configuration ever switches to `zinit load + cdreplay`, this ADR must be
  revisited and the guard re-introduced.
