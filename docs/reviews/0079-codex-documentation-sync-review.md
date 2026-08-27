# Review: Codex Documentation Sync

**Number:** 0079
**Status:** Complete
**Date:** 2026-08-27

## Summary

Reviewed the documentation sync after Codex was stowed and the Catppuccin Macchiato blue custom
theme became active. The update brings the repository status blocks, root README, package README,
Stow references, Codex setup guide, public website pages, and Codex screenshot into line with the
current state.

## Blocking Issues

None.

## Non-Blocking Notes

- The new Codex setup guide lives under `docs/guides/`, which is internal repository documentation.
  The public website instead has a curated Codex section under `website/features/packages.md`.
- A post-stow Codex run appended local `[projects]` trust entries to the symlinked repository config;
  those entries were removed and the setup guidance now requires a diff check after trust or doctor
  operations.
- Historical PRDs, plans, architectures, and reviews may still mention earlier states such as
  "not yet stowed"; those are retained as historical records unless they are current-facing docs.

## Safety Verdict

PASS — the documentation sync includes cleanup of machine-specific `[projects]` entries from the
repo-managed config and adds a static screenshot with no credentials. No Stow operation, symlink
change, or additional `$HOME` mutation is part of this sync.

## Privacy Verdict

PASS — the docs continue to exclude Codex auth, `[projects]` trust entries, transcripts, caches,
plugins, and runtime databases. Backup examples use generated timestamp placeholders.

## Cross-Platform Verdict

PASS — status and Stow docs now consistently refer to macOS, Arch / EndeavourOS, and Debian. Codex
stays in `stow/common`.

## Documentation Verdict

PASS — current docs no longer describe Codex as awaiting installation, describe the custom
`catppuccin-macchiato-blue.tmTheme`, include `codex` in `--no-folding` guidance for `~/.codex`, and
show the active customization in the screenshot gallery and package page.

## Recommended Next Action

Run repository and website validation, then commit the documentation sync with the palette changes.
