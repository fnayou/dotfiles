# Decision: `zoxide init zsh` With `--cmd cd` Override

**Number:** 0047
**Date:** 2026-06-19
**Status:** Accepted
**Supersedes:** 0041

## Context

ADR-0041 decided the committed `tools.zsh` would use bare `zoxide init zsh` (no
`--cmd cd`), reserving the override for `local.zsh` as a personal preference.

ADR-0044 (accepted after ADR-0041) explicitly permits personal daily-use preferences in
committed managed zsh files, provided they have no secrets and work safely on both
platforms. The `--cmd cd` override satisfies all ADR-0044 criteria:

- No secrets or credentials.
- Portable: works identically on macOS and Arch.
- Guarded: `command -v zoxide` makes it a no-op when zoxide is absent.

## Decision

`tools.zsh` uses `--cmd cd`:

```zsh
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init --cmd cd zsh)"
```

This makes `cd` invoke zoxide's jump function globally in interactive shells, so the
user benefits from smart directory history without remembering to type `z` instead.

## Consequences

- `cd` is aliased to `z` (zoxide) in all interactive shells where zoxide is installed.
- `z` and `zi` remain available as explicit zoxide commands.
- Scripts using `cd` are unaffected — zsh aliases do not propagate to subshells.
- Users who prefer no override can revert in `local.zsh`:
  ```zsh
  command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"
  ```
