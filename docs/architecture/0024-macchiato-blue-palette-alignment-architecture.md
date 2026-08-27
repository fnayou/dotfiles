# Architecture: Macchiato Blue Palette Alignment

**Number:** 0024
**Status:** Approved
**Date:** 2026-08-27
**PRD:** [0026-macchiato-blue-palette-alignment](../prd/0026-macchiato-blue-palette-alignment.md)

## Context

The repository already uses Catppuccin Macchiato with blue accent across several packages. The
managed Alacritty file uses the published Macchiato terminal palette: base `#24273a`, text
`#cad3f5`, blue `#8aadf4`, lavender `#b7bdf8`, and the matching ANSI slots.

Herdr currently has a narrower override set:

- `panel_bg`
- `surface_dim`
- `accent`
- `mauve`
- `green`
- `yellow`
- `red`
- `peach`

Current Herdr `0.8.2` exposes more custom theme tokens, including `sidebar_bg`, `active_row_bg`,
`selection_bg`, `surface0`, `surface1`, `overlay0`, `overlay1`, `text`, `subtext0`, `blue`, and
`teal`. The existing comments describing only the old small override set are therefore stale.

Codex CLI theming is a different surface. Official OpenAI documentation defines `tui.theme` as a
syntax-highlighting theme override. Community Codex CLI theme documentation says the CLI accepts
bundled theme names or custom TextMate `.tmTheme` files under `$CODEX_HOME/themes/`. That means the
Codex theme name can match Catppuccin Macchiato while still rendering differently from terminal ANSI
or Herdr UI colors.

## Proposed Architecture

### Alacritty

Leave `stow/common/alacritty/.config/alacritty/catppuccin-macchiato.toml` unchanged. Treat it as
the local reference for terminal-facing Catppuccin Macchiato blue values.

### Herdr

Keep Herdr as a single managed TOML file because Herdr does not support a separate theme include.
Expand `[theme.custom]` to the current token surface:

```toml
[theme.custom]
panel_bg      = "#24273a"  # Base
sidebar_bg    = "#1e2030"  # Mantle
active_row_bg = "#363a4f"  # Surface0
selection_bg  = "#494d64"  # Surface1
surface0      = "#363a4f"  # Surface0
surface1      = "#494d64"  # Surface1
surface_dim   = "#1e2030"  # Mantle
overlay0      = "#6e738d"  # Overlay0
overlay1      = "#8087a2"  # Overlay1
text          = "#cad3f5"  # Text
subtext0      = "#a5adcb"  # Subtext0
accent        = "#8aadf4"  # Blue
mauve         = "#c6a0f6"  # Mauve
green         = "#a6da95"  # Green
yellow        = "#eed49f"  # Yellow
red           = "#ed8796"  # Red
blue          = "#8aadf4"  # Blue
teal          = "#8bd5ca"  # Teal
peach         = "#f5a97f"  # Peach
```

This keeps Herdr's UI deterministic instead of partially inheriting colors from its built-in
`catppuccin` base.

### Codex CLI

Vendor a custom TextMate theme:

- Add `stow/common/codex/.codex/themes/catppuccin-macchiato-blue.tmTheme`, derived from the already
  vendored Catppuccin Macchiato TextMate theme used by `bat`.
- Set `theme = "catppuccin-macchiato-blue"`.

This is stronger than only documenting bundled theme limits because the repo owns the syntax theme
values and can keep them consistent with the rest of the palette.

## Decisions

1. **Do not change Alacritty.** Its managed file already matches the Catppuccin Macchiato values.
2. **Expand Herdr inline tokens.** Herdr's current API supports enough tokens to avoid stale
   built-in inheritance for most UI surfaces.
3. **Keep Herdr in `stow/common`.** The chosen values are display preferences and remain portable
   across macOS, Arch / EndeavourOS, and Debian.
4. **Use a Codex custom `.tmTheme`.** A custom `.tmTheme` is the documented Codex CLI mechanism for
   repo-owned syntax colors.
5. **Do not touch Codex desktop theming.** Desktop app theme payloads and runtime skins are separate
   products/surfaces from Codex CLI config.

## Risks

- **Herdr schema drift:** future Herdr releases may add or rename tokens. Mitigation: keep the
  package comments tied to the validated Herdr version and avoid undocumented keys.
- **Codex `.tmTheme` drift:** a vendored TextMate theme can drift from upstream Catppuccin. Mitigation:
  document provenance and keep the file static/reviewable.
- **False visual equivalence:** terminal ANSI colors, Herdr UI tokens, and syntax scopes cannot be
  perfectly identical because they drive different UI surfaces. Mitigation: document the mapping and
  expected differences.
- **Stow risk:** adding `.codex/themes/` increases the number of files under a sensitive runtime
  directory. Mitigation: keep `--no-folding` and exclude all runtime files.

## Resolved Questions

- Codex uses the custom `.tmTheme` mode.
- Herdr `panel_bg` is opaque base `#24273a`.

## Recommended Next Step

Reviewer: validate this PRD/architecture pair. If there are no blocking issues and the user approves
PRD 0026 and Architecture 0024, Planner should create an implementation plan that updates Herdr,
Codex docs/theme files, validation, and the implementation review.
