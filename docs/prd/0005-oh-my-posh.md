# PRD: Oh My Posh Configuration

**Number:** 0005
**Status:** Approved
**Date:** 2026-06-17

## Problem Statement

The repository lacks a managed configuration for Oh My Posh, the prompt engine used
in zsh sessions on both macOS and EndeavourOS. The real personal config exists at
`~/.config/omp/omp.toml` but is not version-controlled, not portable, and not
documented. This PRD establishes a safe, template-first approach to managing the Oh
My Posh configuration within the dotfiles repository — without copying the real config,
without modifying any shell startup file, and without installing anything automatically.

## Goals

- Add an Oh My Posh config template (`.example` file) to the repository.
- Define the Stow package layout for the Oh My Posh config.
- Add a zsh integration snippet template that documents how activation would be done.
- Document manual installation steps for macOS and Arch separately.
- Document font requirements for Nerd Font rendering.
- Keep the repository safe, private, and template-first throughout.

## Non-Goals

- Copying the real `~/.config/omp/omp.toml` into the repository.
- Modifying `~/.zshrc` or any other shell startup file.
- Installing Oh My Posh automatically.
- Installing fonts automatically.
- Adding Oh My Zsh.
- Adding any plugin manager (zinit, zplug, antigen, etc.).
- Activating the prompt in any shell session.
- Creating symlinks in `$HOME`.
- Running `stow` (other than `--simulate` dry-run if already available).

## User Stories

- As a user, I want a version-controlled Oh My Posh config template so that I can
  reproduce my prompt configuration on any machine.
- As a user, I want macOS and Arch installation steps documented separately so that I
  can follow the correct path for each environment.
- As a user, I want to know what font to install so that the prompt renders correctly.
- As a user, I want a zsh integration snippet so that I know exactly what to add to my
  shell config when ready to activate.
- As a user, I want the template-first approach so that my real config is never
  accidentally committed to the repository.

## Scope

This PRD covers:

- Repository structure: one Stow package (`stow/common/omp/`) with an `.example` config.
- A zsh integration snippet template under `stow/common/zsh/.config/zsh/omp.zsh.example`.
- Documentation for manual Oh My Posh installation on macOS and Arch.
- Documentation for Nerd Font installation.
- Documentation for manual activation when the user is ready.

This PRD does not activate Oh My Posh in any shell session.

## Cross-Platform Requirements

Both macOS and Arch Linux (EndeavourOS) are supported. Installation steps differ and
must be documented separately.

**macOS installation (manual):**

```bash
# Option A — Homebrew
brew install jandedobbeleer/oh-my-posh/oh-my-posh

# Option B — direct binary
curl -s https://ohmyposh.dev/install.sh | bash -s
```

**Arch / EndeavourOS installation (manual):**

```bash
# AUR (via yay or paru)
yay -S oh-my-posh-bin

# Or direct binary
curl -s https://ohmyposh.dev/install.sh | bash -s
```

Both platforms: verify installation with `oh-my-posh --version`.

## Oh My Posh Configuration Strategy

The configuration is a TOML file (`omp.toml`) that controls the prompt appearance.

- Target path on disk: `~/.config/omp/omp.toml`
- Repository path: `stow/common/omp/.config/omp/omp.toml.example`
- The `.example` file is a safe minimal starter — not the user's real config.
- The user copies or renames the example locally before stowing.

Stow package layout:

```
stow/
└── common/
    └── omp/
        └── .config/
            └── omp/
                └── omp.toml.example
```

When ready to stow (future phase):

```bash
# Step 1 — dry run
stow --dir=stow/common --target="$HOME" --simulate omp

# Step 2 — install (manual step, after approving dry-run output)
⚠️  MANUAL STEP — run only after reviewing dry-run output
stow --dir=stow/common --target="$HOME" omp
```

## Zsh Integration Strategy

Oh My Posh is activated in zsh by sourcing an init expression. This must not be added
to any shell startup file during this phase.

The activation line is:

```zsh
eval "$(oh-my-posh init zsh --config "$HOME/.config/omp/omp.toml")"
```

A snippet template is stored at:

```
stow/common/zsh/.config/zsh/omp.zsh.example
```

This file documents the activation line in comment form so the user can source it
manually when ready. It is not sourced automatically.

Future zsh integration (out of scope for this PRD) will source this file from the main
zsh config file.

## Sample / Template Strategy

- All files committed to the repository are `.example` files.
- The `.example` config contains a minimal but functional Oh My Posh theme.
- The `.example` zsh snippet contains the activation line in commented form.
- No real personal config is inspected, referenced, or committed.
- The user is responsible for copying and customizing the `.example` files locally.

## Font Requirements

Oh My Posh requires a Nerd Font for correct rendering of prompt glyphs. Font
installation is manual and out of scope for automation.

**Recommended fonts:**

- [Meslo LGM NF](https://github.com/ryanoasis/nerd-fonts) — recommended by Oh My Posh
  documentation.
- Any other Nerd Font (FiraCode NF, JetBrainsMono NF, etc.) will work.

**macOS (manual):**

```bash
# Option A — Homebrew Cask
brew install --cask font-meslo-lg-nerd-font

# Option B — Oh My Posh font installer
oh-my-posh font install meslo
```

**Arch / EndeavourOS (manual):**

```bash
# AUR
yay -S ttf-meslo-nerd

# Or Oh My Posh font installer
oh-my-posh font install meslo
```

After installation, configure the terminal emulator to use the Nerd Font.

## Safety Requirements

- Must not copy or inspect `~/.config/omp/omp.toml`.
- Must not modify `~/.zshrc` or any shell startup file.
- Must not create symlinks in `$HOME` without explicit per-session user approval.
- Must not run `stow` install commands automatically (dry-run only if applicable).
- Must not delete or overwrite any existing dotfile.
- Must not install Oh My Posh automatically.
- Must not install fonts automatically.
- Must not run `rm`, `mv`, or `ln -s` against `$HOME` or any path outside the repo.
- All example files must use placeholder values, not real personal config.

## Privacy Requirements

- No real theme configuration, hostnames, or personal identifiers committed.
- The `.example` config uses generic placeholder values only.
- The repository is treated as private by default; no sensitive data may be committed.

## Acceptance Criteria

- [ ] `stow/common/omp/.config/omp/omp.toml.example` exists with a minimal starter theme.
- [ ] `stow/common/zsh/.config/zsh/omp.zsh.example` exists with the activation line
  documented in commented form.
- [ ] No real personal `~/.config/omp/omp.toml` content is present anywhere in the repo.
- [ ] No shell startup file (`~/.zshrc`, etc.) has been modified.
- [ ] No package (Oh My Posh or fonts) is installed automatically.
- [ ] No symlinks are created in `$HOME`.
- [ ] Documentation covers macOS and Arch installation steps separately.
- [ ] Documentation covers Nerd Font requirements and manual installation.
- [ ] Documentation explains the manual activation step and the exact eval line.
- [ ] The PRD is committed and the branch is ready for architecture and planning.

## Out of Scope

- Copying the real `~/.config/omp/omp.toml` now or in future phases without explicit
  user instruction.
- Modifying any shell startup file in this phase.
- Automatic installation of Oh My Posh, fonts, or any other tool.
- Oh My Zsh or any plugin manager.
- Activating the Oh My Posh prompt in any session.
- Creating symlinks or running `stow` install (non-simulate) without user approval.
- Powerlevel10k or any other prompt engine.
- Windows or WSL support.
- Terminal emulator configuration (iTerm2, Alacritty, Kitty, etc.).
- Integration with tools other than zsh (bash, fish, etc.) in this phase.
