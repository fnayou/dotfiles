# Decision: Minimal `ls='eza'` Alias Only in Committed Template

**Number:** 0042
**Date:** 2026-06-19
**Status:** Superseded by 0044
**Related:** PRD-0010, Architecture-0010 §12, ADR-0037

## Context

eza is a modern replacement for `ls` with an extensive alias ecosystem. Common patterns include `alias ll='eza -lh'`, `alias la='eza -lha'`, `alias lt='eza --sort=modified'`, `alias tree='eza --tree'`, and many flag variations. These are personal preferences — different users prefer different flag sets, different color options, and different column layouts.

ADR-0037 established that only minimal, guarded, uncontroversial aliases appear in committed templates. eza is the primary example of a tool where this principle has practical impact.

## Decision

The committed `shared.zsh.example` sets only the minimal redirect alias:

```zsh
command -v eza >/dev/null 2>&1 && alias ls='eza'
```

`--color=auto` is not added — eza enables color by default. Adding it would be redundant; omitting it keeps the alias minimal.

Extended aliases (`ll`, `la`, `lt`, tree variants, and any eza-specific flags) are user preference and belong in:
- The user's real `shared.zsh` (if they want them on all machines).
- `local.zsh` (if machine-specific).

The `shared.zsh.example` comment notes this pattern and gives examples of common extended aliases.

## Consequences

- Users who copy `shared.zsh.example` get a working `ls` → `eza` redirect with no extra flags.
- Users who want `ll`, `la`, `lt` add them in their own `shared.zsh` or `local.zsh`.
- No committed template enforces a specific eza flag set on all machines.
- This decision follows directly from ADR-0037 but is specific to eza; eza's extensive alias ecosystem makes this a recurring question for future contributors.
