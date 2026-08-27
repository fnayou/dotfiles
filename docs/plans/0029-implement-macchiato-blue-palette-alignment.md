# Plan: Implement Macchiato Blue Palette Alignment

**Number:** 0029
**Status:** Complete
**Date:** 2026-08-27
**PRD:** [0026-macchiato-blue-palette-alignment](../prd/0026-macchiato-blue-palette-alignment.md)
**Architecture:** [0024-macchiato-blue-palette-alignment-architecture](../architecture/0024-macchiato-blue-palette-alignment-architecture.md)

## Objective

Update the managed Herdr and Codex CLI theme configuration so they align with the repository's
Catppuccin Macchiato blue palette, while leaving Alacritty unchanged and avoiding any `$HOME`
modification.

## Assumptions

- PRD 0026 is Approved by the user.
- Architecture 0024 is Approved by the user.
- The user chooses Codex Mode B unless they explicitly ask for Mode A.
- The user chooses opaque Herdr `panel_bg = "#24273a"` unless they explicitly ask for reset
  inheritance.
- Builder does not run Stow against real `$HOME`.
- Builder does not install or upgrade any tools.

## Ordered Tasks

1. Verify the current Alacritty file still contains the Catppuccin Macchiato reference values:
   `#24273a`, `#cad3f5`, `#8aadf4`, `#1e2030`, and `#181926`.
2. Update `stow/common/herdr/.config/herdr/config.toml`:
   - replace stale comments that describe only the old small Herdr override set;
   - add current Herdr custom tokens from Architecture 0024;
   - keep `name = "catppuccin"`.
3. Update Herdr docs:
   - `stow/common/herdr/README.md`;
   - `docs/guides/herdr-setup.md`;
   - any current references that claim Herdr exposes only eight custom slots.
4. If Codex Mode B is approved, add
   `stow/common/codex/.codex/themes/catppuccin-macchiato-blue.tmTheme` by reusing the existing
   vendored Catppuccin Macchiato TextMate theme from the bat package, with name/provenance adjusted
   for Codex CLI.
5. If Codex Mode B is approved, set `tui.theme = "catppuccin-macchiato-blue"` in
   `stow/common/codex/.codex/config.toml`.
6. Update `stow/common/codex/README.md` to document bundled themes versus repo-owned `.tmTheme`
   themes and the `$CODEX_HOME/themes/` target.
7. Add an ADR recording the palette source-of-truth decision and the distinction between ANSI,
   Herdr UI tokens, and Codex TextMate themes.
8. Write an implementation review under `docs/reviews/`.
9. Reviewer marks Plan 0029 Complete only if the implementation review has no blocking issues.

## Files Affected

- `stow/common/herdr/.config/herdr/config.toml` — modified
- `stow/common/herdr/README.md` — modified
- `docs/guides/herdr-setup.md` — modified
- `stow/common/codex/.codex/config.toml` — modified if Codex Mode B is approved
- `stow/common/codex/.codex/themes/catppuccin-macchiato-blue.tmTheme` — created if Codex Mode B is
  approved
- `stow/common/codex/README.md` — modified
- `docs/decisions/0068-macchiato-blue-palette-source-of-truth.md` — created
- `docs/decisions/README.md` — modified
- `docs/reviews/0078-macchiato-blue-palette-implementation-review.md` — created
- `docs/plans/0029-implement-macchiato-blue-palette-alignment.md` — status changed by Reviewer only

## Safety Checks

- No command may write to `$HOME`.
- No Stow install command may run; fake-target `--simulate` only.
- No Codex auth, project trust, runtime database, transcript, cache, or plugin file may be staged.
- Theme files must contain only static color/scope metadata.
- Run secret-pattern checks before staging.

## Validation Commands

```bash
rtk herdr --default-config
rtk rg -n "eight slots Herdr exposes|all eight custom slots" stow/common/herdr docs/guides stow/common/codex
rtk codex doctor --json
rtk stow --dir=stow/common --target=/private/tmp/dotfiles-stow-check --no-folding --simulate --verbose herdr
rtk stow --dir=stow/common --target=/private/tmp/dotfiles-stow-check --no-folding --simulate --verbose codex
rtk git diff --check
rtk task check
```

`codex doctor --json` may fail for unrelated auth/network/runtime-state reasons; Builder must report
whether config loading itself succeeded.

## Rollback Strategy

Use git to revert only this change's files before commit. Do not run cleanup commands in `$HOME`.
If a fake target under `/private/tmp` is created for validation, leave it in place or remove it only
after explicit review of the path.

## Completion Criteria

- Herdr uses current custom theme tokens with Catppuccin Macchiato blue values.
- Codex either uses the approved custom `.tmTheme` or explicitly documents why the bundled theme
  remains.
- Current docs no longer claim Herdr exposes only eight custom slots.
- ADR 0068 records the palette decision.
- Validation has been run and recorded in review 0078.
- Reviewer marks this plan Complete after a passing implementation review.
