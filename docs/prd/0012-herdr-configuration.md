# PRD: Herdr Configuration Adoption

**Number:** 0012
**Status:** Approved
**Date:** 2026-06-20

## Goals

- Adopt the current `~/.config/herdr/config.toml` into the dotfiles repository as a managed Stow package.
- Preserve all existing configuration values and inline comments.
- Apply Catppuccin Macchiato theme overrides consistent with the repository-wide color scheme (already applied to Alacritty).
- Produce a real managed `config.toml` (no `.example` suffix), consistent with the Alacritty package pattern.
- Include a `.stow-local-ignore` at the package root.
- Place the package under `stow/common/` — config is fully cross-platform (Herdr is available via Homebrew on both macOS and Arch/Linux).

## Non-Goals

- Installing or upgrading Herdr on any machine.
- Running `stow` or creating symlinks in `$HOME`.
- Modifying the live `~/.config/herdr/config.toml` on the host.
- Creating a Homebrew formula or pacman package entry for Herdr.
- Automating the activation of this package.

## User Stories

- As a user, I want my Herdr configuration tracked in the dotfiles repository so that I can reproduce my terminal environment on any machine.
- As a user, I want the Catppuccin Macchiato color overrides preserved so that my terminal multiplexer matches my Alacritty theme.
- As a user, I want a real managed `config.toml` committed to the repository so that activation requires no rename step.
- As a user, I want the package placed under `stow/common/` since Herdr runs on both macOS and Arch via Homebrew.

## Constraints

- **Platform:** Herdr is cross-platform — available via `brew install herdr` on both macOS and Arch/Linux. All config values (theme, terminal, scrollback, ui) are platform-neutral. Package goes in `stow/common/`.
- **Config correction:** The final managed config must use `delivery = "herdr"` (Herdr-internal toast UI), not `delivery = "system"`. The original `delivery = "system"` value is discarded.
- **Stow layout rule:** Package must live under `stow/common/`, `stow/macos/`, or `stow/arch/`. Decision: `stow/common/`.
- **Safety:** No symlinks created, no files written to `$HOME`, no `stow --adopt`.
- **Privacy:** Config contains only UI preferences and color values. No secrets. Inline comments documenting rationale are safe to commit.
- **File pattern:** Real managed `config.toml` committed directly, consistent with the Alacritty package (PRD 0011). A `.stow-local-ignore` is included at the package root.

## Configuration Reference

The managed config to be committed (with corrected `delivery` value):

```toml
onboarding = false

[theme]
name = "catppuccin"

[theme.custom]
panel_bg = "#24273a"   # Base
accent    = "#8aadf4"  # Blue
green     = "#a6da95"  # Green
red       = "#ed8796"  # Red
yellow    = "#eed49f"  # Yellow

[terminal]
default_shell = "zsh"
new_cwd = "follow"

[scrollback]
history = 20000

[ui]
show_agent_labels_on_pane_borders = true

[ui.sidebar]
initial_split_width = 25

[ui.toast]
delivery = "herdr"
```

## Safety Requirements

- Must not delete or overwrite `~/.config/herdr/config.toml` on the host.
- Must not run `stow` automatically during build.
- Must not create any symlinks in `$HOME` without explicit per-session user approval.
- Must not use `stow --adopt` at any point.
- Must provide a dry-run command for the user to verify before any future activation.
- Must not run `rm`, `mv`, or `ln -s` targeting `$HOME`.

## Acceptance Criteria

- [ ] `stow/common/herdr/.stow-local-ignore` created.
- [ ] `stow/common/herdr/.config/herdr/config.toml` created as a real managed file.
- [ ] Config uses `delivery = "herdr"` (not `delivery = "system"`).
- [ ] All Catppuccin Macchiato color overrides present and correct.
- [ ] All inline comments preserved (rationale for each setting).
- [ ] Stow dry-run command documented for the user to run at activation time.
- [ ] No secrets, tokens, or machine-specific values present in the committed file.
- [ ] PRD status updated to Approved before architecture begins.

## Open Questions

None. All platform and config questions resolved.

## Out of Scope

- Automating Herdr installation via Homebrew or any other package manager.
- Adding Herdr to a bootstrap or install script.
- Creating any Herdr keybinding or plugin configuration beyond what is already in the provided config.
- Splitting the config into a common base plus per-platform overlay.
- Activating the Stow package (stowing to `$HOME`) in this milestone.
