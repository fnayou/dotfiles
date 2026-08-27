# Decision: Codex Config Boundary and Status Line Savings

**Number:** 0067
**Date:** 2026-08-27
**Status:** Accepted
**PRD:** 0025 — Codex Customization Package
**Architecture:** 0023 — Codex Customization Package

## Context

The live Codex config mixes portable preferences with local state:

- portable: model default, reasoning effort, hooks feature flag, TUI theme, status line colors, and
  built-in status line item order
- local: `[projects]` trust entries containing absolute paths

Codex runtime/auth material lives under the same `~/.codex` directory. A Stow package must not risk
turning that directory into a symlink or pulling local state into the public repository.

The user also wants `rtk` and caveman savings in Codex's status line, scoped by project, repository,
or session rather than lifetime totals. The existing Claude Code status line already implements the
right scoping model, but Codex `0.149.1` does not expose a documented external status line command
payload equivalent to Claude Code's `statusLine` stdin JSON.

## Decision

Add a `stow/common/codex` package that manages only `.codex/config.toml`, with no `[projects]`
entries and no runtime files.

Document `rtk` and caveman status line savings as deferred:

- `rtk` should use `rtk gain --project --format json` or a future repository/session equivalent,
  never a lifetime total.
- caveman should reuse the Claude package's transcript/ledger model if Codex exposes a session
  transcript path or equivalent session identity.
- No unsupported Codex binary internals are used for rendering.

## Consequences

- The package captures useful Codex customization today without committing machine-specific paths.
- Stowing the package requires an operator to preserve or re-add local project trust entries.
- The status line remains built from Codex's supported built-in items.
- A future PRD can add custom `rtk`/caveman segments when Codex documents a stable custom segment
  interface.
