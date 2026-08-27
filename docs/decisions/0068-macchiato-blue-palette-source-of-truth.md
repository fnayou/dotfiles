# Decision: Macchiato Blue Palette Source of Truth

**Number:** 0068
**Date:** 2026-08-27
**Status:** Accepted

## Context

The repository uses Catppuccin Macchiato with blue accent across terminal and agent tooling.
Alacritty already has a managed Catppuccin Macchiato terminal color file that matches the published
palette values: base `#24273a`, mantle `#1e2030`, crust `#181926`, text `#cad3f5`, and blue
`#8aadf4`.

Herdr and Codex consume themes differently:

- Alacritty uses terminal ANSI and UI color tables.
- Herdr uses named UI tokens under `[theme.custom]`.
- Codex CLI uses syntax-highlighting themes selected by `tui.theme`; official OpenAI Docs describe
  this setting as a syntax-highlighting theme override.

Using the same theme name in all tools is therefore insufficient. The surfaces are related by
palette, not by file format or exact rendering model.

## Decision

Alacritty's managed Catppuccin Macchiato file is the local terminal palette reference.

Herdr maps that palette into its current custom UI tokens, with `accent` and `blue` set to
Macchiato blue `#8aadf4`.

Codex CLI uses a repo-owned TextMate theme at
`stow/common/codex/.codex/themes/catppuccin-macchiato-blue.tmTheme`, derived from the already
vendored Catppuccin Macchiato TextMate theme used by the bat package. Codex `config.toml` sets
`tui.theme = "catppuccin-macchiato-blue"` so the syntax palette is controlled by this repository
instead of by Codex's bundled approximation.

## Consequences

- Theme consistency is defined by Catppuccin Macchiato color values, not by requiring every tool to
  use an identical theme file.
- Alacritty remains unchanged unless its file drifts from the published palette.
- Herdr docs must describe the current token set, not the older eight-token subset.
- Codex custom themes live under `.codex/themes/` and must remain static color/scope metadata only.
- Vendored TextMate themes can drift from upstream; future refreshes should be explicit,
  reviewable commits.
