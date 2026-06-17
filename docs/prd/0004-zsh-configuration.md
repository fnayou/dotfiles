# PRD: Zsh Configuration Management

**Number:** 0004
**Status:** Approved
**Date:** 2026-06-17

---

## Problem Statement

The user currently relies on the default macOS zsh configuration with no version-controlled dotfiles for zsh. As the dotfiles repository matures, zsh configuration must eventually be captured, shared across platforms (macOS and EndeavourOS/Arch), and safely managed via GNU Stow.

This PRD defines the design goals and constraints for that future zsh configuration layer — without implementing it yet.

---

## Goals

- Define a safe, incremental approach to managing zsh configuration across macOS and Arch.
- Design a structure that separates shared logic from platform-specific logic.
- Establish the template and example file strategy for zsh adoption.
- Choose between the Stow package layout and the XDG-style layout at a high level.
- Ensure future adoption does not risk the user's existing zsh configuration.

---

## Non-Goals

- Do not implement any zsh configuration files.
- Do not inspect, copy, or read `~/.zshrc` or any existing zsh configuration.
- Do not create symlinks in `$HOME`.
- Do not modify `$HOME` or any path outside the repository.
- Do not change the user's shell.
- Do not run GNU Stow (other than a safe dry-run if already available).
- Do not define specific zsh plugin or prompt choices.
- Do not define aliases, functions, or environment variables for zsh yet.

---

## User Stories

- As a user, I want my zsh configuration version-controlled so that I can restore it on a new machine without manually recreating it.
- As a user, I want shared zsh logic in one place so that I do not duplicate configuration across macOS and Arch.
- As a user, I want platform-specific zsh config in separate files so that macOS-only and Arch-only settings do not conflict.
- As a user, I want to adopt this structure incrementally so that my existing zsh setup is never broken during migration.
- As a user, I want `.example` files to guide adoption so that I can review and customize before stowing anything.

---

## Constraints

- **Platform:** Must support both macOS (primary) and EndeavourOS/Arch Linux.
- **Shell:** Must target zsh only. No bash, fish, or other shell considerations.
- **Safety:** Must not modify any existing file outside the repository until explicit user approval.
- **Stow:** Must follow the established Stow safety rules (dry-run before install, no `--adopt`).
- **Privacy:** No real personal values in committed files — use `.example` files with placeholder values.
- **Incremental:** Real zsh adoption is a later phase. This PRD covers design only.

---

## Safety Requirements

- Must not delete, move, or overwrite `~/.zshrc` or any other existing zsh file.
- Must not create symlinks in `$HOME` without explicit per-session user approval.
- Must not run `stow --adopt` at any point.
- Any future stow install command must be preceded by `stow --simulate` dry-run and user review.
- All example files must use placeholder values only — no real hostnames, tokens, or paths.
- Any file that might capture sensitive shell configuration must include a note recommending `.gitignore` for the user's real version.

---

## Privacy Requirements

- No real API keys, tokens, or credentials in any zsh config file.
- No real private hostnames, internal IP addresses, or work-specific values.
- No real `$HOME`-based paths that reveal the user's username or machine configuration.
- Use `$HOME`, `$USER`, and `YOUR_VALUE` as placeholders in all examples.
- Files containing sensitive values must be documented as `.example` files only.

---

## Cross-Platform Requirements

- macOS and Arch configurations must be kept in separate files or Stow packages.
- Shared zsh logic must be explicitly designed to be portable — no platform-specific shell builtins in shared files.
- Package manager references (Homebrew, pacman) must never appear in shared config.
- OS detection must be explicit when required:

  ```zsh
  if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
  elif [[ -f /etc/arch-release ]]; then
    # Arch / EndeavourOS
  fi
  ```

---

## Zsh Configuration Strategy

Two high-level layout approaches are compared below. The PRD does not select one — that decision belongs to a future Architecture document.

### Option A — Stow Package Layout

```
stow/
├── common/
│   └── zsh/
│       └── .zshrc             # Sources shared.zsh, then platform file
├── macos/
│   └── zsh/
│       └── .config/zsh/macos.zsh
└── arch/
    └── zsh/
        └── .config/zsh/arch.zsh
```

- Stow manages symlinks per platform.
- Shared logic lives in `common/zsh/`.
- Platform-specific logic lives in `macos/zsh/` or `arch/zsh/`.
- `~/.zshrc` is version-controlled and symlinked by Stow.

**Tradeoffs:**
- Cleaner Stow package separation.
- Requires stowing multiple packages when deploying a machine.
- `~/.zshrc` itself is managed, which risks conflict with an existing file.

### Option B — XDG-Style Layout

```
stow/
└── common/
    └── zsh/
        └── .config/
            └── zsh/
                ├── shared.zsh
                ├── macos.zsh
                └── arch.zsh
```

`~/.zshrc` is a minimal bootstrap file the user manages manually:

```zsh
# ~/.zshrc — not version controlled
source "$HOME/.config/zsh/shared.zsh"

if [[ "$OSTYPE" == "darwin"* ]]; then
  source "$HOME/.config/zsh/macos.zsh"
elif [[ -f /etc/arch-release ]]; then
  source "$HOME/.config/zsh/arch.zsh"
fi
```

- Stow only manages `~/.config/zsh/` — not `~/.zshrc`.
- `~/.zshrc` remains under user control and is not version-controlled.
- Safer adoption: existing `~/.zshrc` is never touched.

**Tradeoffs:**
- Safer initial adoption (no conflict with existing `~/.zshrc`).
- `~/.zshrc` bootstrap is manual — not fully reproducible on a new machine.
- XDG paths align with the project's established preference (see Git package).

> **Note:** The Git package established a preference for XDG-style paths and an include-based adoption model (see `docs/decisions/0013-include-based-git-config-strategy.md`). This is context for the Architecture document, not a decision made here.

---

## Shared Zsh Logic Strategy

Shared logic must be portable across macOS and Arch. Candidates include:

- Environment variable exports (`$EDITOR`, `$PAGER`, `$PATH` additions).
- Zsh options (`setopt`, `unsetopt`).
- History configuration.
- Completion initialization (`autoload -Uz compinit`).
- Prompt initialization (if a cross-platform prompt tool is used).
- Aliases that are portable (e.g., `ls`, `grep` with safe flags).

Shared logic must not include:

- Package manager references.
- Paths that differ between macOS and Arch.
- macOS-specific tools (e.g., `pbcopy`, `open`, `brew`).
- Arch-specific tools (e.g., `pacman`, `yay`, `systemctl`).

---

## macOS-Specific Zsh Strategy

macOS additions may include:

- Homebrew path initialization (`eval "$(YOUR_HOMEBREW_PREFIX/bin/brew shellenv)"`, where `YOUR_HOMEBREW_PREFIX` is a literal placeholder the user replaces with `/opt/homebrew` or `/usr/local` — not a shell variable).
- macOS-specific aliases (`alias open='open'`, `alias pbcopy='pbcopy'`).
- macOS tool integrations (e.g., iTerm2, 1Password CLI if applicable).
- Any macOS-only `$PATH` entries.

These must live exclusively in the macOS-specific file or Stow package.

---

## Arch-Specific Zsh Strategy

Arch additions may include:

- pacman/yay aliases if desired.
- Arch-specific `$PATH` entries.
- Arch-specific tool integrations (e.g., `systemctl` helpers).
- AUR helper configuration if applicable.

These must live exclusively in the Arch-specific file or Stow package.

---

## Adoption Strategy

Adoption must be incremental and safe:

1. **Phase 1 (this PRD):** Design only. No files created.
2. **Phase 2 (Architecture):** Choose layout (Option A or B). Define file structure. Create `.example` files only.
3. **Phase 3 (Implementation):** Populate `.example` files with documented patterns. No real values.
4. **Phase 4 (User adoption):** User manually copies `.example` files, fills in real values, and stows after dry-run approval.
5. **Phase 5 (Real use):** Stow active. Real zsh config sourced from version-controlled files.

Phase 4 and 5 are explicitly out of scope for this PRD.

---

## Out of Scope

- Implementing any zsh configuration file.
- Inspecting or copying `~/.zshrc` or any existing zsh dotfile.
- Choosing a zsh plugin manager (Oh My Zsh, Antigen, Zinit, etc.).
- Choosing a zsh prompt theme (Starship, Powerlevel10k, etc.).
- Defining specific aliases, functions, or environment variables.
- Creating symlinks in `$HOME`.
- Running GNU Stow.
- Modifying the user's shell (`chsh`).
- Fish, bash, or any other shell configuration.
- Zsh plugin installation or management.
- Terminal emulator configuration (iTerm2, Alacritty, etc.).

---

## Acceptance Criteria

- [ ] PRD document exists at `docs/prd/0004-zsh-configuration.md`.
- [ ] PRD defines problem statement, goals, non-goals, and user stories.
- [ ] PRD compares Stow package layout vs. XDG-style layout without deciding.
- [ ] PRD defines shared, macOS-specific, and Arch-specific zsh logic categories.
- [ ] PRD defines a safe, incremental adoption strategy with explicit phases.
- [ ] PRD lists explicit safety, privacy, and cross-platform requirements.
- [ ] PRD lists all out-of-scope items.
- [ ] No zsh configuration files are created.
- [ ] No changes are made to `$HOME` or any file outside the repository.
- [ ] No symlinks are created.
- [ ] No GNU Stow commands are executed.
- [ ] PRD is reviewed and approved before architecture work begins.
