# PRD: eza Configuration Adoption

**Number:** 0014
**Status:** Approved
**Date:** 2026-06-21

> **Process note:** Unlike the bat package (PRD 0013), this change follows the
> `AGENTS.md` §6 chain in order — PRD → Architecture → Review → Plan → Build → Review →
> Commit. Documents precede the implementation.

## Goals

- Adopt a managed [eza](https://github.com/eza-community/eza) theme into the dotfiles
  repository as a Stow package under `stow/common/`.
- Activate the Catppuccin Macchiato theme (Blue accent), consistent with the repository-wide
  color scheme already used by Alacritty, Herdr, Oh My Posh, and bat.
- Ship the theme as a real `theme.yml` inside the package — the filename eza reads by default.
- Vendor the theme in-repo so activation is offline and reproducible (no network fetch at
  install time), consistent with the bat package.
- Include a `.stow-local-ignore` and a package `README.md`.

## Non-Goals

- Installing or upgrading eza on any machine (already installed and in use).
- Running `stow` or creating symlinks in `$HOME`.
- Modifying any existing live `~/.config/eza/` content on the host.
- Defining eza CLI flags or shell aliases — those live in the zsh package (`aliases.zsh`),
  not here.
- Adopting multiple alternate theme variants with a switchable symlink (the inspiration repo
  does this; we ship a single active theme — see architecture).

## User Stories

- As a user, I want my eza theme tracked in the dotfiles repository so I can reproduce my
  `ls` colors on any machine.
- As a user, I want the Catppuccin Macchiato (Blue) theme active so eza output matches my
  terminal, prompt, and bat theme.
- As a user, I want the theme file committed in-repo so activation works offline and is
  reproducible regardless of upstream availability.
- As a user, I want the package under `stow/common/` since eza and its config path are
  identical on macOS and Arch.

## Constraints

- **Platform:** eza is cross-platform — `brew install eza` (macOS), `pacman -S eza` (Arch).
  Config path (`~/.config/eza/`) is identical via XDG. The theme format is platform-neutral.
  Package goes in `stow/common/`.
- **Theme activation:** eza reads `~/.config/eza/theme.yml` directly at runtime. Unlike bat,
  there is **no cache-build step** — stowing the file is sufficient for activation. (eza honors
  `EZA_CONFIG_DIR` if set, but defaults to `~/.config/eza`; we rely on the default.)
- **Stow layout rule:** Package must live under `stow/common/`, `stow/macos/`, or
  `stow/arch/`. Decision: `stow/common/`.
- **Safety:** No symlinks created, no files written to `$HOME`, no `stow --adopt`.
- **Privacy:** The theme file contains only color values and styling keys. No secrets.
- **File pattern:** Real managed `theme.yml` committed directly, with `.stow-local-ignore`
  and `README.md` at the package root, consistent with Alacritty, Herdr, and bat.

## Configuration Reference

The managed theme is the upstream `catppuccin-macchiato-blue.yml` from
[catppuccin/eza](https://github.com/catppuccin/eza), committed as `theme.yml`. Blue accent
(`#8aadf4`) is chosen to match the repository color scheme.

## Safety Requirements

- Must not delete or overwrite any existing `~/.config/eza/` content on the host.
- Must not run `stow` automatically during build.
- Must not create symlinks in `$HOME` without explicit per-session user approval.
- Must not use `stow --adopt` at any point.
- Must provide a dry-run command for the user to verify before any activation.
- Must not run `rm`, `mv`, or `ln -s` targeting `$HOME`.

## Acceptance Criteria

- [ ] `stow/common/eza/.stow-local-ignore` created.
- [ ] `stow/common/eza/.config/eza/theme.yml` created as a real managed file (Macchiato Blue).
- [ ] `stow/common/eza/README.md` created.
- [ ] `docs/guides/eza-setup.md` created (dry-run → install workflow; notes no cache step).
- [ ] Stow dry-run command documented for the user.
- [ ] No secrets, tokens, or machine-specific values in any committed file.
- [ ] PRD/Architecture approved before the plan; plan approved before build.

## Open Questions

- **Accent color:** Defaulted to Blue to match the established repo scheme. If the user
  prefers another Macchiato accent (mauve, teal, etc.), swap the vendored file — no structural
  change.

## Out of Scope

- Automating eza installation.
- eza CLI flags / shell aliases (owned by the zsh package).
- Multiple switchable theme variants.
- Splitting config into per-platform overlays.
- Activating the Stow package (stowing to `$HOME`) in this milestone.
