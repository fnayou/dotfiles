# PRD: Codex Customization Package

**Number:** 0025
**Status:** Approved
**Date:** 2026-08-27

## Goals

- Add a portable Codex CLI customization package under `stow/common/codex/`.
- Track the non-secret Codex configuration that controls model defaults, theme, feature flags, and
  the built-in TUI status line.
- Preserve the current Catppuccin Macchiato visual direction already used by Alacritty, bat, btop,
  eza, Neovim, Oh My Posh, Herdr, and the Claude Code status line.
- Investigate whether Codex can show `rtk` and caveman savings in its status line without using
  machine-wide lifetime totals.
- Correct known documentation drift around plan statuses and Debian support in Stow docs.
- Leave all `~/.codex` auth, project trust, transcripts, caches, plugins, and runtime databases
  outside the repository.

## Non-Goals

- Managing `~/.codex/auth.json`, SQLite state, logs, transcripts, app-server state, plugin caches, or
  any other Codex runtime file.
- Committing `[projects]` trust entries from the live config, because they contain machine-specific
  absolute paths.
- Stowing the new package into `$HOME` during implementation.
- Patching the Codex binary or relying on undocumented binary internals for a savings segment.
- Changing the existing Claude Code status line behaviour.

## Scope

- Create `stow/common/codex/.codex/config.toml`.
- Create `stow/common/codex/README.md`.
- Update root/package documentation to list the new package and its not-yet-stowed state.
- Add workflow documents for this change under `docs/architecture/`, `docs/plans/`,
  `docs/reviews/`, and `docs/decisions/`.
- Correct drift in `docs/plans/README.md`, `docs/stow-usage.md`, and related command descriptions.

## Safety Requirements

- Do not modify `$HOME` or run Stow.
- Do not copy the live `~/.codex/config.toml` verbatim.
- Do not commit `auth.json`, `version.json`, `models_cache.json`, `*.sqlite`, logs, rollout files,
  plugin caches, or trusted project paths.
- Use `--no-folding` in all documented Codex stow commands so `~/.codex` never becomes a symlink.
- Any future `rtk` or caveman Codex status line segment must be project, repository, or session
  scoped, never machine-lifetime scoped.

## Acceptance Criteria

- [x] A `codex` package exists under `stow/common/`.
- [x] The package contains only portable, non-secret files.
- [x] The managed config preserves the current theme and built-in status line choices.
- [x] Documentation explains why `[projects]` entries stay local.
- [x] `rtk` and caveman status line feasibility is documented against Codex `0.149.1` and the
      existing Claude Code status line design.
- [x] Status blocks reflect that `codex` has been added but not stowed.
- [x] Documentation drift is corrected.
