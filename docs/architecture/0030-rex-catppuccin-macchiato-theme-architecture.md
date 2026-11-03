# Architecture: Rex Catppuccin Macchiato Theme with Blue Accent

**Number:** 0030
**Status:** Approved
**Date:** 2026-11-03
**PRD:** [0034](../prd/0034-rex-catppuccin-macchiato-theme.md)

## Context

PRD 0034 asks for a Catppuccin Macchiato theme in Rex with a blue `#8aadf4` accent, tracked in the
repository as `stow/common/rex`, with activation decided by an investigation.

The investigation (read-only, Rex Beta 0.1.0 on macOS, 2026-11-03) found:

1. **Rex already runs Macchiato.** On first launch Rex migrated the Ghostty theme
   `catppuccin-macchiato` from the repository's `stow/common/ghostty` package. It is stored as a
   custom theme with `source: ghosttyMigration` and is selected as the dark theme.
2. **Imported themes are not files.** Custom themes live as a JSON value, `Workspace.customThemes`,
   in the app's preferences (`~/Library/Preferences/com.superlogical.rex.plist`). That plist also
   holds the selected theme IDs and the interface style. It is not a stowable file and holds
   machine-specific data.
3. **No `init.lua` theme key.** The Lua reference lists no theme or color setting for the config file.
   `rex.block.call(terminal, "set_theme", …)` and the `com.superlogical.terminal.set_theme` action
   replace a terminal block's default colors at runtime; they do not persist.
4. **Two ways to load a theme file, both user-run:** Settings > Themes > Import Theme, and the
   `client.theme.import` action (it takes the absolute path of a Ghostty theme or iTerm color file
   and selects it).
5. **A theme has no accent field.** A theme holds `background`, `foreground`, `cursor`, `cursorText`,
   `selectionBackground`, `selectionForeground`, the 16 `ansi` colors and palette options. The
   accent-aware controls are Rex settings: Active Pane > Highlight color (accent, a palette color, or
   terminal text) and Shell icon theme (default, theme, or theme accent). They are set in the Settings
   UI. Whether Rex derives its "accent" from the cursor, the blue ANSI slot or the system accent was
   not determinable without changing live settings, so it stays an open question.
6. **The existing Ghostty Macchiato file** (`stow/common/ghostty/.config/ghostty/themes/catppuccin-macchiato`)
   uses rosewater `#f4dbd6` for cursor and selection, per ADR 0068. The PRD wants these blue in Rex.

Consequences: the repository can carry only the theme file and a guide. The accent settings and the
final selection are manual and cannot be tracked.

## Proposed Structure

```
stow/common/rex/
├── README.md                                   # files, targets, activation pointer
└── .config/rex/themes/
    └── catppuccin-macchiato-blue               # Ghostty-format theme, import source

docs/guides/rex-setup.md                        # human setup guide (ADR-0028)
docs/decisions/00NN-rex-theme-imported-manually.md
```

- The theme file is named `catppuccin-macchiato-blue`, with no extension, matching the Ghostty
  theme naming. It keeps Macchiato values from the shared Ghostty and Alacritty files, except:
  `cursor-color`, `selection-background` set to Blue `#8aadf4`; `cursor-text` and
  `selection-foreground` stay Base `#24273a`.
- The target path `~/.config/rex/themes/` is a convention for a stable on-disk import source. Rex
  does not read it by itself.
- The package contains no `init.lua`, so Rex's own `~/.config/rex/init.lua` stays an unmanaged real file.
- `.stow-local-ignore` excludes `README.md` from linking.

## Design Decisions

### Decision 1: How the theme reaches Rex

Option A: Stow the file and let the user import it once (Settings > Themes > Import Theme or
`client.theme.import`).
  Pro: Uses Rex's supported path; the file is versioned and reproducible on a new Mac; no write to
  Rex state by agents or scripts.
  Con: Import is manual, and the result lives in the app plist, not the repo.

Option B: Script `rex api call client.action` to import and select the theme, wrapped in a
`task rex:sync` target.
  Pro: One command on a new Mac.
  Con: Changes live Rex state; beta action names may change; PRD 0034 puts this out of scope unless
  nothing else works.

Option C: Write `Workspace.customThemes` into the preferences plist.
  Pro: Fully scripted.
  Con: Edits an app's private data format, breaks on app updates, and risks corrupting settings.
  Rejected.

Option D: Reuse the existing Ghostty Macchiato theme, no new package.
  Pro: No new file; Rex already migrated it.
  Con: Cannot carry the blue cursor and selection; fails the PRD goal.

Decision: Option A. The import is a documented `MANUAL STEP`. Option B stays available through a later
PRD.

### Decision 2: Where "blue accent" lives

Option A: Blue cursor and selection in the theme file, and a documented Settings step for Active Pane
highlight color (blue palette slot) and shell icon theme (theme accent).
  Pro: Tracks everything the repo can track, and states what it cannot.
  Con: Part of the accent is manual and unverifiable from the repo.

Option B: Change the blue only in the theme and ignore the Settings.
  Pro: Simpler.
  Con: The pane highlight and tab icons could stay on the system accent, missing the PRD goal.

Decision: Option A. The guide lists each setting with its menu path.

### Decision 3: Separate theme file or copy of the Ghostty one

Option A: A separate Rex theme file with the blue variations.
  Pro: Leaves Ghostty, Alacritty and Terminal.app untouched; clear name.
  Con: Duplicates about 25 lines of palette data, so a palette change must be applied in two places.

Option B: Change the Ghostty theme to blue cursor and selection.
  Pro: One source.
  Con: Alters other terminals' look; out of scope (PRD Non-Goals).

Decision: Option A, with a comment in the file naming the shared source (ADR 0068) and the two
differing keys. A future check could compare the palette lines.

### Decision 4: `stow/common/` for a macOS-only app

The owner chose `stow/common/rex`. The theme file is platform-neutral, so it fits. macOS-only content
(Settings paths, `~/Library/...` locations) goes in the guide with `[macOS]` labels, not in the package.
No package manager commands are involved, because the Rex install is out of scope.

Decision: keep `stow/common/rex` as decided.

### Decision 5: Stowing is optional and separate

Stowing only puts the file at `~/.config/rex/themes/`. The import could equally use the repo path
directly. Stowing is a separate, user-approved step. If the user stows, it triggers the status-block
update in `AGENTS.md` and `CLAUDE.md` in the same commit.

Decision: the guide covers both: import straight from the repository checkout, or stow first.
The recommended path is import from the repo checkout, which avoids touching `$HOME`.

## Risks

- **Beta drift.** Setting names, the action name or the theme store can change between builds. The
  guide records the version tested (0.1.0) and says to re-check on update.
- **Accent not fully controllable.** Whether Rex's accent follows the cursor, the blue ANSI slot or the
  system accent is unverified. The guide treats the Settings values as the source of truth, and the
  user confirms visually.
- **Duplicate palette.** Two copies of Macchiato values can drift. Mitigated by a header comment and,
  optionally, a later check.
- **Name collision.** A theme named `catppuccin-macchiato-blue` imported twice may create two entries
  in Rex. The guide says to delete the old entry before re-importing.
- **Stow conflict.** `~/.config/rex/` exists as a real directory with a real `init.lua`. Stow links the
  `themes/` file inside it without touching `init.lua`, but needs a dry run. A conflict stops the work;
  `--adopt` is never used.
- **Privacy.** The Rex plist and `Application Support` hold account, host and server IDs. Nothing from
  them enters the repository, including in the guide's examples.
- **Reversibility.** Import and selection are reversible in Settings > Themes. Rollback restores the
  previous theme (the migrated `catppuccin-macchiato`, which this plan never deletes).

## Extensibility

- A Latte variant needs one more file under the same directory and a light-mode selection.
- If Rex adds a theme directory or an `init.lua` theme key, the theme file is already in place and
  only the guide changes. A `task rex:sync` target can follow the `task codex:sync` and
  `task terminal:sync` pattern (dry run by default) in a separate PRD.
- A `stow/macos/rex` package stays possible if Rex gains macOS-only files.

## Open Questions

- ~~Does the Rex accent follow the cursor color, the blue ANSI slot, or the system accent?~~ Resolved
  by the owner on 2026-11-04: it follows the cursor and the blue ANSI slot. Both are set to `#8aadf4`
  in the theme file (cursor in `cursor-color`, blue in `palette` 4 and 12), so the theme file alone
  carries the accent. The Active Pane highlight and shell icon settings stay as documented manual steps.
- Should a check compare the shared Macchiato palette lines across the Ghostty and Rex files?
- Should the theme be imported with `client.theme.import` or the Settings UI in the guide? The guide
  can list both; the owner may prefer one.

## Recommended Next Step

Review this architecture. After explicit approval, the Planner writes the plan: theme file, package
README, `.stow-local-ignore`, setup guide, ADR, README and docs index updates, a validation step that
checks the theme's hex values against the Ghostty theme, and the user-run import and visual check.
