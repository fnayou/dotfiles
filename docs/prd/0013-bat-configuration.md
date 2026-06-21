# PRD: bat Configuration Adoption

**Number:** 0013
**Status:** Approved
**Date:** 2026-06-21

> **Note on order:** This PRD was authored as a retroactive backfill. The implementation
> was built first (via the `add-dotfile-package` skill) before the PRD → Architecture →
> Plan → Review chain was produced. This document, the architecture, the plan, and the two
> reviews were written afterward to bring the change into compliance with `AGENTS.md` §6
> before commit. See review 0042 for the honest sequencing note.

## Goals

- Adopt a managed [bat](https://github.com/sharkdp/bat) configuration into the dotfiles
  repository as a Stow package under `stow/common/`.
- Activate the Catppuccin Macchiato theme, consistent with the repository-wide color scheme
  (already applied to Alacritty, Herdr, and Oh My Posh).
- Ship the theme as a real `.tmTheme` file inside the package, so activation does not depend
  on a network fetch at install time.
- Produce a real managed `config` file (no `.example` suffix), consistent with the Alacritty
  and Herdr package pattern (secret-free config committed directly).
- Include a `.stow-local-ignore` at the package root.
- Document the bat-specific `bat cache --build` activation step, which has no analogue in the
  Alacritty or Herdr packages.

## Non-Goals

- Installing or upgrading bat on any machine.
- Running `stow` or creating symlinks in `$HOME`.
- Modifying any existing live `~/.config/bat/` content on the host.
- Running `bat cache --build` against the user's machine automatically.
- Configuring bat integrations in other tools (fzf preview, `bat`-as-`MANPAGER`, etc.).

## User Stories

- As a user, I want my bat configuration tracked in the dotfiles repository so I can
  reproduce my pager setup on any machine.
- As a user, I want the Catppuccin Macchiato theme active so bat output matches my terminal
  and prompt theme.
- As a user, I want the theme file committed in-repo so activation works offline and is
  reproducible regardless of upstream availability.
- As a user, I want the package under `stow/common/` since bat and its config path are
  identical on macOS and Arch.

## Constraints

- **Platform:** bat is cross-platform — `brew install bat` on macOS, `pacman -S bat` on Arch.
  Config path (`~/.config/bat/`) is identical via XDG. All options used are platform-neutral.
  Package goes in `stow/common/`.
- **Theme activation:** bat reads themes from a compiled cache, not from `.tmTheme` files
  directly. The theme is not active on stow alone — `bat cache --build` must run once after
  stowing. This is a documented manual step, never run by an agent.
- **Stow layout rule:** Package must live under `stow/common/`, `stow/macos/`, or
  `stow/arch/`. Decision: `stow/common/`.
- **Safety:** No symlinks created, no files written to `$HOME`, no `stow --adopt`,
  no `bat cache --build` run against the host.
- **Privacy:** Config contains only display preferences and a theme name. The `.tmTheme`
  contains only color values and metadata. No secrets.
- **File pattern:** Real managed `config` committed directly, with `.stow-local-ignore` at
  the package root, consistent with Alacritty (PRD 0011) and Herdr (PRD 0012).

## Configuration Reference

The managed config to be committed:

```
# bat configuration
# https://github.com/sharkdp/bat
--theme="Catppuccin Macchiato"
--style="numbers,changes,header"
--wrap="auto"
--italic-text="always"
--paging="auto"
```

The theme file is `themes/Catppuccin Macchiato.tmTheme`, sourced from
[catppuccin/bat](https://github.com/catppuccin/bat).

## Safety Requirements

- Must not delete or overwrite any existing `~/.config/bat/` content on the host.
- Must not run `stow` automatically during build.
- Must not run `bat cache --build` against the host.
- Must not create symlinks in `$HOME` without explicit per-session user approval.
- Must not use `stow --adopt` at any point.
- Must provide a dry-run command for the user to verify before any activation.
- Must not run `rm`, `mv`, or `ln -s` targeting `$HOME`.

## Acceptance Criteria

- [x] `stow/common/bat/.stow-local-ignore` created.
- [x] `stow/common/bat/.config/bat/config` created as a real managed file.
- [x] `stow/common/bat/.config/bat/themes/Catppuccin Macchiato.tmTheme` committed.
- [x] Config sets `--theme="Catppuccin Macchiato"`.
- [x] Stow dry-run command documented for the user.
- [x] `bat cache --build` activation step documented as a manual step.
- [x] No secrets, tokens, or machine-specific values in any committed file.
- [x] PRD status Approved before architecture (retroactively, per backfill note).

## Open Questions

None.

## Out of Scope

- Automating bat installation.
- Adding bat to a bootstrap or install script.
- bat integration in fzf, git pager, or `MANPAGER`.
- Splitting config into a common base plus per-platform overlay.
- Activating the Stow package (stowing to `$HOME`) in this milestone.
