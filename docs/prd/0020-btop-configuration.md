# PRD: btop Configuration Adoption

**Number:** 0020
**Status:** Approved
**Date:** 2026-07-03

## Goals

- Adopt a managed [btop](https://github.com/aristocratos/btop) configuration into the dotfiles
  repository as a Stow package under `stow/common/`.
- Activate the Catppuccin Macchiato theme (blue accent), consistent with the repository-wide
  color scheme already used by Alacritty, Herdr, Oh My Posh, bat, eza, and Neovim.
- Ship the theme as a real `.theme` file inside the package, vendored in-repo so activation is
  offline and reproducible (no network fetch at install time).
- Ship a small `btop.conf` that sets the active theme plus a handful of sensible options, leaving
  most options commented for the user to hand-tune.
- Include a `.stow-local-ignore` and a package `README.md`.

## Non-Goals

- Installing or upgrading btop on any machine.
- Running `stow` or creating symlinks in `$HOME`.
- Modifying any existing live `~/.config/btop/` content on the host.
- Exhaustively pinning every btop option — btop writes its own defaults for anything unset.

## User Stories

- As a user, I want my btop theme and key options tracked in the repository so I can reproduce my
  resource-monitor look on any machine.
- As a user, I want the Catppuccin Macchiato (blue) theme active so btop matches my terminal,
  prompt, and other tools.
- As a user, I want the theme committed in-repo so activation works offline and is reproducible.
- As a user, I want the package under `stow/common/` since btop and its config path are identical
  on macOS, Arch, and Debian.

## Constraints

- **Platform:** btop is cross-platform — `brew install btop` (macOS), `sudo pacman -S btop`
  (Arch), `sudo apt install btop` (Debian; binary name is `btop`, no quirk). Config path
  (`~/.config/btop/`) is identical via XDG. Package goes in `stow/common/`.
- **Theme activation:** btop reads `~/.config/btop/btop.conf` and `~/.config/btop/themes/`
  directly at runtime. Unlike bat, there is **no cache-build step** — stowing the files and
  restarting btop is sufficient.
- **Accent:** The [catppuccin/btop](https://github.com/catppuccin/btop) port ships one theme per
  flavor with **no separate accent selector**. The Macchiato theme already uses Blue (`#8aadf4`)
  for `hi_fg`, `selected_fg`, and `proc_box`, so the blue accent is built in.
- **Stow layout rule:** Package must live under `stow/common/`. Decision: `stow/common/`.
- **Safety:** No symlinks created, no files written to `$HOME`, no `stow --adopt`.
- **Privacy:** Config and theme contain only styling/behaviour values. No secrets.

## Configuration Reference

- Theme: upstream `catppuccin_macchiato.theme` from
  [catppuccin/btop](https://github.com/catppuccin/btop), committed verbatim.
- `btop.conf`: sets `color_theme = "catppuccin_macchiato"`, `theme_background = False`,
  `truecolor = True`, `vim_keys = True`; leaves common options (`update_ms`, `proc_sorting`,
  `proc_tree`, `shown_boxes`, `graph_symbol`, `temp_scale`, `clock_format`, `rounded_corners`)
  commented for the user.

## Safety Requirements

- Must not delete or overwrite any existing `~/.config/btop/` content on the host.
- Must not run `stow` automatically during build.
- Must not create symlinks in `$HOME` without explicit per-session user approval.
- Must not use `stow --adopt` at any point.
- Must provide a dry-run command for the user to verify before any activation.
- Must not run `rm`, `mv`, or `ln -s` targeting `$HOME`.

## Acceptance Criteria

- [ ] `stow/common/btop/.stow-local-ignore` created.
- [ ] `stow/common/btop/.config/btop/btop.conf` created (theme set + commented tweakables).
- [ ] `stow/common/btop/.config/btop/themes/catppuccin_macchiato.theme` created (upstream verbatim).
- [ ] `stow/common/btop/README.md` created.
- [ ] `docs/guides/btop-setup.md` created (dry-run → install workflow; notes no cache step).
- [ ] `packages/Brewfile`, `packages/arch/packages.txt`, `packages/debian/packages.txt` list btop.
- [ ] Website `features/packages.md` and `features/index.md` mention btop.
- [ ] Both status blocks (`AGENTS.md`, `CLAUDE.md`) updated in the same commit.
- [ ] No secrets, tokens, or machine-specific values in any committed file.

## Open Questions

- **Accent color:** Fixed to the upstream Macchiato flavor, which is already blue. The
  catppuccin/btop port has no accent switch; changing accent would mean hand-editing the theme.

## Out of Scope

- Automating btop installation.
- Activating the Stow package (stowing to `$HOME`) in this milestone.
- Splitting config into per-platform overlays.
