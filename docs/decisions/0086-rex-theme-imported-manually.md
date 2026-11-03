# Decision: Rex Theme Is Tracked as an Import Source and Activated by Hand

**Number:** 0086
**Date:** 2026-11-04
**Status:** Accepted
**PRD:** 0034 — Rex Catppuccin Macchiato Theme with Blue Accent
**Architecture:** 0030 — Rex Catppuccin Macchiato Theme with Blue Accent

## Context

Rex (Superlogical terminal, beta) imports Ghostty themes and iTerm color files. It stores imported
themes as data in its own app preferences, not as files. Its `init.lua` has no theme or color key,
and the `set_theme` terminal method only changes a running block. The theme itself has no accent
field; the accent comes from the cursor, the blue ANSI slot and two Rex settings (Active Pane
highlight color, shell icon theme).

## Decision

- Track the theme as `stow/common/rex/.config/rex/themes/catppuccin-macchiato-blue`, a Ghostty-format
  file with the shared Macchiato palette and a blue `#8aadf4` cursor and selection.
- The user imports it into Rex (Settings or command palette) and sets the two accent settings by hand.
  No script, Task target or stow step does this.
- Stowing the file is optional and separate. The package is not stowed by default.
- Do not edit Rex's preferences or call state-changing `rex` commands from the repository.

## Consequences

- A new Mac needs a few manual steps, listed in `docs/guides/rex-setup.md`.
- The repository cannot prove the accent settings are applied; the guide has a visual check.
- The palette exists in two files (Ghostty and Rex). The header comment names the source, and the
  two differing keys.
- If Rex gains a theme folder or an `init.lua` theme key, activation can be automated by a new
  decision. A `task rex:sync` target would need its own PRD.
