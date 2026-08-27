# Review: Macchiato Blue Palette PRD and Architecture

**Number:** 0076
**Status:** Complete
**Date:** 2026-08-27
**Documents reviewed:**
- `docs/prd/0026-macchiato-blue-palette-alignment.md`
- `docs/architecture/0024-macchiato-blue-palette-alignment-architecture.md`

## Summary

Reviewed PRD 0026 and Architecture 0024 for the Macchiato blue palette alignment change. The
documents correctly separate the three theming surfaces: Alacritty terminal ANSI colors, Herdr UI
tokens, and Codex CLI TextMate syntax themes. They keep host mutation out of scope and identify the
main current drift: Herdr now exposes more custom color tokens than the managed config describes.

## Blocking Issues

None.

## Non-Blocking Suggestions

1. Resolve the Codex mode before implementation starts. Mode B gives stronger visual parity, but it
   adds a vendored theme file that needs provenance and drift documentation.
2. Keep Herdr `panel_bg = "#24273a"` for deterministic screenshots unless the user explicitly wants
   terminal-background inheritance via `panel_bg = "reset"`.

## Safety Verdict

PASS — the PRD and architecture explicitly forbid Stow, symlink creation, `$HOME` edits,
installation, and runtime Codex state capture.

## Privacy Verdict

PASS — the scoped files contain display preferences and static color theme metadata only. The
documents exclude Codex auth, project trust entries, transcripts, caches, and databases.

## Cross-Platform Verdict

PASS — Herdr remains in `stow/common`, and no OS-specific package manager or path is introduced.
Codex theme files under `$CODEX_HOME/themes/` are portable when stowed with `--no-folding`.

## Documentation Verdict

PASS — the documents explain the existing drift and distinguish historical records from current
source-of-truth docs.

## Recommended Next Action

User: explicitly approve PRD 0026 and Architecture 0024 before planning/building. Suggested approval
text: `Approve PRD 0026 and Architecture 0024; use Codex Mode B and opaque Herdr panel_bg.`
