# Review: Macchiato Blue Palette Implementation

**Number:** 0078
**Status:** Complete
**Date:** 2026-08-27
**Plan reviewed:** [0029-implement-macchiato-blue-palette-alignment](../plans/0029-implement-macchiato-blue-palette-alignment.md)

## Summary

Reviewed the implementation of Plan 0029. The change expands Herdr's Catppuccin Macchiato blue
mapping to the current Herdr custom token surface, switches Codex CLI to a repo-owned
`catppuccin-macchiato-blue.tmTheme`, updates current package documentation, adds ADR 0068, and
records the workflow artifacts for PRD 0026 / Architecture 0024 / Plan 0029.

Plan 0029 is complete.

## Blocking Issues

None.

## Non-Blocking Notes

- `herdr config check` only validates the live `~/.config/herdr/config.toml`; it has no file
  argument. It was not run against the managed repo file to avoid reading or relying on live host
  state.
- The approved plan listed Alacritty mantle/crust values as if they appeared in the Alacritty theme
  file. The managed Alacritty ANSI file is unchanged and contains the values it actually uses
  directly, including base `#24273a`, text `#cad3f5`, and blue `#8aadf4`; mantle/crust are not named
  slots in that file.
- `codex doctor --json` against a temporary `CODEX_HOME` failed overall because the temporary home
  had no credentials and network reachability was unavailable. The relevant `config.load` check was
  `ok` and reported `config.toml parse: ok`.
- Ruby `tomlrb`, Python `tomllib`, `taplo`, `tomlq`, and `yq` were unavailable locally, so TOML
  parsing was validated through the owning tools instead of a standalone parser.

## Validation

- `rtk rg -n "eight slots Herdr exposes|all eight custom slots" stow/common/herdr docs/guides stow/common/codex` — no matches.
- `rtk rg -n "#24273a|#cad3f5|#8aadf4" stow/common/alacritty/.config/alacritty/catppuccin-macchiato.toml` — expected Alacritty values present.
- `rtk herdr --default-config` — current Herdr default config lists the expanded custom theme token surface.
- `rtk plutil -lint stow/common/codex/.codex/themes/catppuccin-macchiato-blue.tmTheme` — PASS.
- `env CODEX_HOME=/private/tmp/codex-dotfiles-validate codex doctor --json` — `config.load` PASS; overall FAIL from missing temp credentials and network.
- `rtk stow --dir=stow/common --target=/private/tmp/dotfiles-stow-check --no-folding --simulate --verbose herdr` — PASS, simulation only.
- `rtk stow --dir=stow/common --target=/private/tmp/dotfiles-stow-check --no-folding --simulate --verbose codex` — PASS, simulation only.
- `rtk git diff --check` — PASS.
- `rtk task check` — PASS.
- `rtk task check:decisions` — PASS.
- Secret pattern scan for common private-key/API-token shapes across changed package/docs paths — no matches.

## Safety Verdict

PASS — no Stow activation, symlink creation, `$HOME` writes, dependency installation, destructive
commands, or `stow --adopt` were run. The only writes outside the repo were temporary validation
copies under `/private/tmp`.

## Privacy Verdict

PASS — changed package files contain static display preferences and TextMate color/scope metadata.
No Codex auth, project trust entries, transcripts, caches, plugins, runtime databases, hostnames, or
credentials were introduced.

## Cross-Platform Verdict

PASS — Herdr and Codex remain under `stow/common`. The values are portable display settings and do
not introduce OS-specific paths or package-manager commands.

## Documentation Verdict

PASS — current docs now distinguish Alacritty ANSI colors, Herdr UI tokens, and Codex TextMate
syntax themes. ADR 0068 records the source-of-truth decision. Historical review 0060 now notes that
its token-count assumption was superseded by ADR 0068.

## Recommended Next Action

User: confirm whether to commit and push these changes to the existing draft PR branch.
