# Decision: Completion Guard — Avoid Double `compinit` When Zinit Is Present

**Number:** 0039
**Date:** 2026-06-19
**Status:** Superseded by 0046
**Related:** PRD-0010, Architecture-0010 §11, ADR-0020

## Context

`compinit` initializes the zsh completion system. When Zinit is loaded, it calls `compinit` internally at the appropriate point in its initialization sequence. If `shared.zsh` also calls `compinit` unconditionally, two problems arise:

1. **Startup latency.** `compinit` scans all completion function directories (`$fpath`). Running it twice doubles that cost.
2. **Correctness.** A second `compinit` call can trigger security warnings about insecure completion directories and can reset completion state built up by Zinit plugins loaded between the two calls.

## Decision

`shared.zsh` calls `compinit` only when the `zinit` function is not defined:

```zsh
if ! typeset -f zinit >/dev/null 2>&1; then
  autoload -Uz compinit && compinit
fi
```

`typeset -f zinit` returns 0 (true) if and only if the `zinit` function was successfully defined by the Zinit source guard earlier in `shared.zsh`. If Zinit was absent or failed to source, `zinit` is undefined and `typeset -f zinit` returns non-zero — the standalone `compinit` runs.

This guard must be placed after the Zinit source guard in `shared.zsh`. Its position is load-order-sensitive.

Platform-specific completions (Homebrew completions on macOS, AUR helper completions on Arch) belong in `macos.zsh` and `arch.zsh` respectively. They must not call `compinit` — they extend `$fpath` before or after Zinit/compinit has already run.

## Consequences

- Shell startup on machines with Zinit: one `compinit` call (by Zinit).
- Shell startup on machines without Zinit: one `compinit` call (standalone guard).
- Security warnings about insecure completion directories are avoided.
- Removing the guard (reducing to an unconditional `compinit`) is a blocking review issue — it introduces the double-compinit problem on machines with Zinit.
- Future contributors adding completions to platform layers must not call `compinit` directly — they extend `$fpath` only.
