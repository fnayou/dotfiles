# Decision: `zoxide init zsh` Without `--cmd` Override

**Number:** 0041
**Date:** 2026-06-19
**Status:** Accepted
**Related:** PRD-0010, Architecture-0010 §7

## Context

zoxide is a smarter `cd` replacement. Its `init` command accepts a `--cmd` flag that lets the user alias `cd` to zoxide's `z` function (e.g., `--cmd cd`). This alias replaces the built-in `cd` globally, affecting all scripts and interactive sessions.

The committed template must represent a safe, uncontroversial default. Aliasing `cd` to `z` is a significant muscle-memory and compatibility decision that differs by user preference.

## Decision

The committed `shared.zsh.example` initializes zoxide without the `--cmd` override:

```zsh
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"
```

This provides the `z` and `zi` commands without replacing `cd`. The standard `cd` built-in remains available.

Users who prefer `cd` aliased to `z` add the override in `local.zsh`:

```zsh
# In local.zsh — personal preference, not committed:
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh --cmd cd)"
```

This local override takes effect last (step 4 of the source order) and wins over the `shared.zsh` init.

Note: if both `shared.zsh` and `local.zsh` run a `zoxide init` call, the second call re-initializes zoxide with the new settings. This is safe; zoxide's init output is idempotent at the function-definition level.

## Consequences

- New users get `z` and `zi` without any change to `cd` behavior.
- Power users who want `--cmd cd` add it in `local.zsh` — no committed template change needed.
- Scripts that use `cd` are unaffected by the default committed configuration.
- The setup guide (`docs/guides/zsh-setup.md`) documents the `--cmd cd` override as a local.zsh pattern.
