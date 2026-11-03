# PRD: Rex Catppuccin Macchiato Theme with Blue Accent

**Number:** 0034
**Status:** Approved
**Date:** 2026-11-03

## Goals

- Give Rex (the Superlogical terminal, in beta) the repository's Catppuccin Macchiato palette, so its
  background, foreground, cursor, selection and 16 ANSI colors match Alacritty, Ghostty and
  Terminal.app (PRD 0031).
- Use Macchiato Blue `#8aadf4` as the accent wherever Rex exposes one: the theme's cursor and
  selection colors, the active pane highlight color, and the shell icon theme accent.
- Track the theme in the repository as a Ghostty-format theme file, the format Rex's theme import
  accepts, so a new Mac can be set up from the repo instead of by hand.
- Record how Rex loads a theme (Settings > Themes > Import Theme, the `client.theme.import` action,
  the `com.superlogical.terminal.set_theme` action, or `init.lua`) and which of these can be
  automated safely. The architecture step settles the activation method from this finding.
- Ship the package as `stow/common/rex`, with a README and a human setup guide, following the
  existing package conventions (ADR-0028).
- Document the activation steps, rollback, and the known limits of Rex's accent controls.

## Non-Goals

- A light variant (Catppuccin Latte) for Rex's light mode. Dark Macchiato only, matching the
  Alacritty and bat setup.
- Other Rex settings: keybindings, fonts, layout, sidebar, onboarding. `init.lua` is a comment-only
  file today and stays out of scope unless the architecture finds the theme needs it.
- Changing any other terminal's theme (Alacritty, Ghostty, Terminal.app, herdr).
- Rex on Arch or Debian. Rex ships Linux packages, but this repository only runs it on macOS today.
- A custom Rex plugin, Lua theme engine, or a generator for themes.
- Persisting the Rex server state, sessions or account files under
  `~/Library/Application Support/rex/`.

## User Stories

- As a Rex user, I want Rex to use Catppuccin Macchiato so that it looks the same as my other
  terminals.
- As a Rex user, I want a blue accent on the active pane and tab icons so that focus is visible and
  matches my existing blue `#8aadf4` accent.
- As the repository owner, I want the theme tracked in the repo so that a new Mac gets the same
  Rex look from a documented setup guide.
- As the repository owner, I want activation to stay a manual, user-run step so that no agent or script
  changes my Rex settings or my home directory.

## Constraints

- **Platform:** Rex runs on macOS here. The package goes under `stow/common/rex` by the owner's
  decision, so the theme file and README must be platform-neutral and any macOS-only step (Settings UI
  path, `~/Library/Application Support/rex/`) is labeled `[macOS]`. `arch/` and `debian/` are not
  touched.
- **Rex is a beta.** Settings names, action names and file locations can change. The docs may lag the
  app. Findings are verified against the installed build with `rex version` and recorded with that
  version.
- **Theme format:** Rex imports Ghostty themes and iTerm `.itermcolors` files. Ghostty ships
  `catppuccin-macchiato`. The file must use Catppuccin's published Macchiato values and nothing else.
- **Accent is partly outside the theme file.** The active pane highlight color and the shell icon theme
  are Rex settings (Settings > Interface), not theme keys. They may be settable only through the
  Settings UI.
- **Config location:** Rex reads `~/.config/rex/init.lua` (or `REX_CONFIG`). No documented
  `init.lua` theme key was found. The architecture confirms this before relying on it.
- **Stow status:** a new package is not stowed by this PRD. First stowing is a separate user-approved
  step, and it triggers the status-block update in `AGENTS.md` and `CLAUDE.md` (status-sync rule).
- **Privacy:** theme colors are public values. No account IDs, host IDs, server socket paths or session
  IDs from `~/Library/Application Support/rex/` enter the repository.
- **Dependencies:** the `rex` CLI for read-only inspection. Nothing else.

## Safety Requirements

- Must not delete, move or overwrite `~/.config/rex/init.lua` or anything under
  `~/Library/Application Support/rex/`.
- Must not run `stow` against this package without explicit user approval, and must dry-run first
  (`stow --simulate`). Must not use `stow --adopt`.
- Must not run `rex config reload`, `client.theme.import`, `set_theme`, or any command that changes the
  live Rex UI, theme or settings without explicit user approval. Read-only inspection (`rex ... ls`,
  `rex api list`, `rex api describe`, `rex config check`) is allowed.
- Must not modify files outside the repository. The theme file is activated by the user, from the
  repository, through a documented step.
- Must not commit real account, host, server or session identifiers.
- Must mark every command that changes the live Rex configuration with the `MANUAL STEP` marker.
- Must provide a rollback: how to select the previous theme and, if the file was stowed, how to unstow
  it with a dry run first.

## Acceptance Criteria

- [ ] An investigation record states, for the installed Rex build, how a theme can be loaded and
      which of the accent controls are available through the theme file, `init.lua`, actions or the
      Settings UI only.
- [ ] `stow/common/rex/` exists with a Catppuccin Macchiato theme file in Ghostty format and a
      `README.md` that lists each file and its target path.
- [ ] Every color in the theme file matches Catppuccin's published Macchiato values; the blue accent
      is `#8aadf4`.
- [ ] The theme file passes Rex's own import check on the user's machine (the user imports it and
      reports the result), and the palette is visibly Macchiato in Rex.
- [ ] A human setup guide under `docs/guides/` gives the activation steps, with dry-run before any
      stow install, the Settings UI path for the accent settings, and a rollback (ADR-0028).
- [ ] The setup guide states which accent settings cannot be tracked in the repository and must be set
      by hand.
- [ ] A decision record in `docs/decisions/` captures the chosen activation method and why.
- [ ] No identifiers from `~/Library/Application Support/rex/` appear anywhere in the repository.
- [ ] If the package is first stowed, `AGENTS.md` and `CLAUDE.md` status blocks are updated in the
      same commit.
- [ ] `task check:decisions` passes, and `task brand:check` passes or the generated art is
      regenerated.
- [ ] A Reviewer pass returns PASS for safety, privacy and documentation.

## Out of Scope

- Everything listed under Non-Goals.
- Automating activation from bootstrap, install, shell init or provisioning scripts.
- Syncing Rex settings between machines, including a `task rex:sync` target, unless the architecture
  finds activation cannot work any other way and the owner approves it in a separate PRD.
- Reporting Rex bugs or missing theme features to Superlogical.
- Making Rex the default terminal or changing how Rex is installed.

## Open Questions

- Does `init.lua` or the Lua API (`https://www.superlogical.com/rex/docs/reference/lua.md`) expose a
  theme or color setting that could replace the manual import?
- Can the active pane highlight color and shell icon theme accent be set outside the Settings UI?
- Does Rex store imported custom themes in a user-visible directory that could be stowed directly?
- Is the `stow/common/` placement still right if Rex only runs on macOS? The owner chose `common`; the
  architecture should record the consequence for `stow/macos/` and the status blocks.
