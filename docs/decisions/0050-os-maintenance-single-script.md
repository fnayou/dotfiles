# Decision: OS Maintenance Is One Detecting Script, Not Per-OS Files

**Number:** 0050
**Date:** 2026-06-24
**Status:** Accepted
**PRD:** 0018-os-maintenance
**Architecture:** 0018-os-maintenance-architecture

## Context

The OS maintenance helper (PRD 0018) must run different package-manager commands on Arch /
EndeavourOS (`pacman` / `yay`) and macOS (`brew`). The Cross-Platform rule (§10) requires per-OS
*logic* to be separated. That separation can be achieved either by multiple files or by named
per-OS functions inside one file. Existing helpers (`detect-os.sh`, `check.sh`) are single files
that branch internally.

## Decision

Implement one script, `scripts/os-maintenance.sh`, that detects the OS once and dispatches to
`arch_*` / `macos_*` functions. No per-OS script files, no separate dispatcher.

## Consequences

- One file for CI to `bash -n` and secret-scan; one usage/arg-parser to maintain.
- Per-OS logic stays separated by clearly named functions, satisfying §10 without file sprawl.
- Both OS code paths live in one file though only one runs per host — acceptable for a small
  helper; revisit only if either path grows large.
- Adding a third OS is a new detection arm plus `<os>_*` functions — no restructuring.
