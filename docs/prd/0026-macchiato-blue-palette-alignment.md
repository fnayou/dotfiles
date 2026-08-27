# PRD: Macchiato Blue Palette Alignment

**Number:** 0026
**Status:** Approved
**Date:** 2026-08-27

## Goals

- Align the managed Herdr and Codex visual configuration with the repository's Catppuccin
  Macchiato blue palette.
- Keep Alacritty as the terminal ANSI reference because its managed theme already matches the
  published Catppuccin Macchiato palette.
- Update Herdr from the older small `[theme.custom]` override set to Herdr's current custom color
  token surface.
- Make Codex CLI theming more explicit when the bundled `catppuccin-macchiato` syntax theme does
  not visually match the rest of the repo.
- Document the difference between terminal ANSI colors, Herdr UI tokens, and Codex TextMate syntax
  themes so future changes do not conflate them.

## Non-Goals

- Changing the Alacritty color file unless validation proves it has drifted from upstream.
- Styling the Codex desktop app, importing `codex-theme-v1` payloads, or applying runtime skins.
- Running Stow or modifying `$HOME`.
- Installing or upgrading Herdr, Alacritty, Codex, or any package manager dependency.
- Changing `rtk` or caveman status line savings behavior.
- Patching Codex internals or relying on undocumented binary behavior.

## Scope

- `stow/common/herdr/.config/herdr/config.toml`
- `stow/common/herdr/README.md`
- `docs/guides/herdr-setup.md`
- `stow/common/codex/.codex/config.toml`
- `stow/common/codex/.codex/themes/` if a repo-owned Codex CLI `.tmTheme` is approved
- `stow/common/codex/README.md`
- Current workflow documentation for this palette decision under `docs/architecture/`,
  `docs/plans/`, `docs/reviews/`, and optionally `docs/decisions/`

## Safety Requirements

- Do not modify `$HOME`, run Stow, create symlinks, or run `stow --adopt`.
- Do not copy local Codex runtime files, project trust entries, auth files, caches, transcripts, or
  state databases.
- Codex custom themes must be static `.tmTheme` files with color/scope metadata only.
- Herdr changes must remain portable across macOS, Arch / EndeavourOS, and Debian.
- Any validation against host binaries must be read-only.

## Acceptance Criteria

- [x] Alacritty is verified unchanged against the Catppuccin Macchiato reference values.
- [x] Herdr config uses the current Herdr custom token names instead of claiming only eight slots
      exist.
- [x] Herdr's custom colors map to Catppuccin Macchiato with blue `#8aadf4` as the primary accent.
- [x] Codex either remains on the bundled `catppuccin-macchiato` theme with documented limits, or
      uses a repo-owned `catppuccin-macchiato-blue.tmTheme` with the same palette values.
- [x] Documentation clearly explains why Alacritty, Herdr, and Codex do not use identical theme file
      formats.
- [x] No secrets, credentials, project paths, or runtime state are introduced.
- [x] Validation commands pass or any skipped validation is documented with reason.

## Resolved Questions

- Codex uses a repo-owned `catppuccin-macchiato-blue.tmTheme`.
- Herdr uses opaque `panel_bg = "#24273a"` for deterministic UI surfaces.
