# PRD: Alacritty Configuration

**Number:** 0011
**Status:** Approved
**Date:** 2026-06-19

## Problem Statement

The repository has no managed configuration for Alacritty, the GPU-accelerated terminal
emulator used on both macOS and EndeavourOS. The real personal configuration exists
locally but is not version-controlled, not portable, and not reproducible on a fresh
machine. This PRD establishes a managed Stow package for the Alacritty configuration,
adopting the real personal config directly (not as an `.example` file), under the
`stow/common/alacritty/` package.

## Goals

- Add the real Alacritty configuration (`alacritty.toml`) to the repository as a
  managed dotfile.
- Add the Catppuccin Macchiato theme file (`catppuccin-macchiato.toml`) to the
  repository alongside the main config.
- Define the Stow package layout for the Alacritty config under `stow/common/`.
- Resolve and document the four portability decisions (shell path, `option_as_alt`,
  font, import path) so they are recorded for future sessions.
- Keep the repository safe and private throughout.

## Non-Goals

- Installing Alacritty on macOS or Arch automatically.
- Installing JetBrainsMono Nerd Font automatically.
- Creating symlinks in `$HOME` (Stow install is a future manual step).
- Running `stow` against the real home directory during implementation.
- Adding an Arch-specific or macOS-specific Alacritty override package in this phase.
- Supporting any terminal emulator other than Alacritty.
- Configuring keybindings beyond the numpad bindings already present in the user config.
- Integrating Alacritty configuration with zsh or Oh My Posh configuration.

## User Stories

- As a user, I want my Alacritty configuration in version control so that I can
  reproduce my exact terminal appearance on any machine.
- As a user, I want the Catppuccin Macchiato theme committed alongside the main config
  so that the import path resolves correctly after stowing.
- As a user, I want the portability decisions for `option_as_alt` and `/bin/zsh`
  documented so that I do not need to re-evaluate them in future sessions.
- As a user, I want to know the manual Stow commands to link the config when ready.

## Scope

This PRD covers:

- One Stow package: `stow/common/alacritty/`.
- Two config files: `alacritty.toml` and `catppuccin-macchiato.toml`.
- Documentation of the four portability decisions.
- Stow dry-run and install commands for future reference (not executed during
  implementation).

This PRD does not create symlinks in `$HOME` or run Stow install commands.

## Target Structure

```
stow/
└── common/
    └── alacritty/
        └── .config/
            └── alacritty/
                ├── alacritty.toml
                └── catppuccin-macchiato.toml
```

After stowing, this maps to:

```
~/.config/alacritty/alacritty.toml
~/.config/alacritty/catppuccin-macchiato.toml
```

## Cross-Platform Requirements

Both macOS and Arch Linux (EndeavourOS) are supported. The package is placed under
`stow/common/` because the configuration is portable across both platforms with the
caveats documented below.

**macOS installation (manual, future phase):**

```bash
brew install --cask alacritty
```

**Arch / EndeavourOS installation (manual, future phase):**

```bash
sudo pacman -S alacritty
```

## Portability Decisions

### 1. Shell path: `/bin/zsh`

The config sets the shell to `/bin/zsh` with login args.

| Platform | Path | Status |
|---|---|---|
| macOS | `/bin/zsh` | Valid — macOS ships zsh at this path |
| Arch / EndeavourOS | `/usr/bin/zsh` (actual binary); `/bin/zsh` is a symlink via `usr-merge` | Valid — Arch performs `usr-merge` so `/bin` → `/usr/bin`; `/bin/zsh` resolves correctly |

**Decision:** `/bin/zsh` is acceptable in the common config for both platforms. No
change required. Document this decision so it is not re-evaluated in future sessions.

**Alternative (not adopted):** Use the env shim: `program = "/usr/bin/env"` with
`args = ["zsh", "-l"]`. Deferred — adds complexity without practical benefit given
`usr-merge` on Arch.

### 2. `option_as_alt = "Both"` (macOS-specific behavior)

This setting controls whether the macOS Option key sends Alt sequences. It is processed
only by Alacritty on macOS. On Linux, Alacritty parses the setting without error and
silently ignores it — no effect, no crash.

**Decision:** Keep `option_as_alt = "Both"` in the common config. No platform
separation required. The setting is harmless on Linux.

**Documentation note:** If a future Arch-specific override package is created, this
setting need not be duplicated there.

### 3. JetBrainsMono Nerd Font

The config sets `family = "JetBrainsMono Nerd Font"` at size `13.0`. This is a
personal preference. If the font is not installed, Alacritty falls back silently to a
system monospace font.

**Decision:** Commit the font preference as-is. No installation step required during
this phase. Font installation remains a manual step documented separately.

**Manual font installation (for reference, not automated):**

```bash
# macOS
brew install --cask font-jetbrains-mono-nerd-font

# Arch / EndeavourOS
sudo pacman -S ttf-jetbrains-mono-nerd
```

### 4. Import path: `~/.config/alacritty/catppuccin-macchiato.toml`

The main config imports the theme file using an absolute `~`-expanded path:

```toml
import = [
  "~/.config/alacritty/catppuccin-macchiato.toml"
]
```

After stowing, both `alacritty.toml` and `catppuccin-macchiato.toml` land in
`~/.config/alacritty/`. The absolute path resolves correctly on both macOS and Arch.

**Alternative (relative import):** Alacritty supports relative imports since v0.13
(`./catppuccin-macchiato.toml`). However, relative imports are resolved relative to the
config file on disk — after stowing both files land in the same directory, so relative
imports also work. The existing absolute `~`-path is more explicit and has broader
version compatibility.

**Decision:** Keep the absolute `~/.config/alacritty/catppuccin-macchiato.toml` import
path. No change required.

## Configuration Summary

The committed `alacritty.toml` encodes the following personal preferences:

| Setting | Value | Notes |
|---|---|---|
| `TERM` | `xterm-256color` | Portable; widely supported |
| Window padding | `x = 8, y = 8` | Personal preference |
| `dynamic_padding` | `true` | Personal preference |
| `opacity` | `0.98` | Personal preference |
| `startup_mode` | `Windowed` | Portable |
| `option_as_alt` | `Both` | macOS behavior; ignored on Linux |
| Font family | `JetBrainsMono Nerd Font` | Personal preference; fallback if missing |
| Font size | `13.0` | Personal preference |
| Shell | `/bin/zsh` | Portable via `usr-merge` on Arch |
| Shell args | `["-l"]` | Login shell; portable |
| Numpad bindings | See config | Personal preference |
| Theme import | `catppuccin-macchiato.toml` | Absolute `~` path |

## Stow Commands (Future Reference — Not Executed During Implementation)

When ready to link the config:

```bash
# Step 1 — dry run
stow --dir=stow/common --target="$HOME" --simulate alacritty
```

⚠️  MANUAL STEP — run only after reviewing dry-run output

```bash
# Step 2 — install
stow --dir=stow/common --target="$HOME" --no-folding alacritty
```

## Safety Requirements

- Must not run `stow` install commands automatically.
- Must not create symlinks in `$HOME` without explicit per-session user approval.
- Must not delete or overwrite any existing dotfile.
- Must not run `rm`, `mv`, or `ln -s` against `$HOME` or any path outside the repo.
- Must not use `stow --adopt`.
- Must not install Alacritty or fonts automatically.
- Must not read files from `~/.config/alacritty/` — config content is provided by the
  user in this PRD.

## Privacy Requirements

- The Alacritty configuration contains no secrets, credentials, tokens, API keys, SSH
  keys, private hostnames, or work-specific settings.
- The configuration is safe personal daily-use preferences only.
- The repository is treated as private by default; no sensitive data is present in the
  config being adopted.

## Acceptance Criteria

- [ ] `stow/common/alacritty/.config/alacritty/alacritty.toml` exists with the full
  user configuration.
- [ ] `stow/common/alacritty/.config/alacritty/catppuccin-macchiato.toml` exists with
  the full Catppuccin Macchiato theme.
- [ ] No secrets, credentials, or private data are present in either file.
- [ ] No symlinks are created in `$HOME`.
- [ ] No `stow` install command is executed automatically.
- [ ] The four portability decisions are documented in this PRD.
- [ ] The Stow dry-run and install commands are documented for future reference.
- [ ] The PRD is committed and the branch is ready for architecture and planning.

## Out of Scope

- Installing Alacritty on any platform.
- Installing JetBrainsMono Nerd Font on any platform.
- Creating a macOS-specific or Arch-specific Alacritty override package.
- Modifying `$HOME` or creating any symlinks during implementation.
- Running `stow` install (non-simulate) without explicit user approval.
- Integrating the Alacritty config with the zsh or Oh My Posh packages.
- Any keybinding changes beyond those already in the user's config.
- Windows or WSL support.
- Supporting Kitty, iTerm2, or any other terminal emulator.
