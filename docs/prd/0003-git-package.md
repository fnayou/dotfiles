# PRD: Git Configuration Package

**Number:** 0003
**Status:** Approved
**Date:** 2026-06-17

## Problem Statement

The repository has a safe Stow scaffold and a dotfiles foundation, but no managed Git configuration package. An existing `.gitconfig.example` placeholder sits in `stow/common/git/` with no accompanying strategy, scope, or acceptance criteria. Without a formal plan, any future implementation risks overwriting the user's real Git identity, credentials, signing keys, or machine-specific settings.

## Goals

- Define a safe, portable Git configuration package for the common Stow layer.
- Produce template/example files that can be adopted without committing real identity or secrets.
- Design for an include-based strategy where the user's real `~/.gitconfig` can include a managed common config while keeping private settings local.
- Ensure the package works correctly on both macOS and EndeavourOS / Arch Linux.
- Establish a global gitignore strategy using a template/example file.
- Leave all irreversible or identity-sensitive decisions deferred until explicitly requested.

## Non-Goals

- Replacing or modifying the user's existing `~/.gitconfig`.
- Committing real user identity (name, email).
- Committing signing keys or signing configuration of any kind.
- Managing SSH configuration.
- GitHub CLI authentication or credential helpers.
- Work-specific Git identities or conditional includes for work profiles.
- Automatic Stow installation — no scripts may run Stow without explicit user approval.
- Any action that modifies `$HOME` or files outside the repository root.

## User Stories

- As a user, I want a portable Git config template so that I can adopt consistent settings across machines without exposing my real identity.
- As a user, I want a global gitignore template so that I can manage common ignore patterns (editor artifacts, OS files) without machine-specific noise.
- As a user, I want an include-based strategy so that my real `~/.gitconfig` can reference the managed config while keeping private settings local and untracked.
- As a user, I want dry-run output before any Stow command so that I can verify what will be linked before committing to any action.
- As a user, I want all example files to use placeholder values so that the repository remains safe to publish.

## Scope

### In Scope

- `stow/common/git/` package containing:
  - `.gitconfig.example` — common, portable Git settings using placeholder values only.
  - `.gitignore_global.example` — common global ignore patterns.
- Documentation for the include-based adoption strategy.
- Clear instructions for the user to rename/copy example files and fill in local values.
- Dry-run Stow instructions for review before install.

### Platform Scope

- **Common**: settings that work identically on macOS and EndeavourOS / Arch Linux.
- No macOS-specific or Arch-specific Git packages required at this stage.

## Safety Requirements

- Must not read, inspect, or copy the user's real `~/.gitconfig`.
- Must not read, inspect, or copy the user's real global gitignore.
- Must not modify any file outside the repository root.
- Must not create symlinks in `$HOME` without explicit per-session user approval.
- Must not run `stow --adopt` under any circumstances.
- Must not run Stow automatically — any install command must be shown to the user first.
- Must provide a dry-run step before any install command.
- Must not commit real identity, email, signing keys, or work-specific settings.
- Must mark any risky command with: `⚠️  MANUAL STEP — review before running`.

## Privacy Requirements

- All example files must use placeholder values only:
  - `Your Name` for `user.name`
  - `your-email@example.com` for `user.email`
  - No real hostnames, internal URLs, or tokens.
- No file may contain real credentials, API keys, or access tokens.
- Signing key references are explicitly forbidden — signing strategy is undecided.
- Pre-commit checklist must be followed before any staging or commit.

## Cross-Platform Requirements

- All settings in the common package must be valid on both macOS and Arch Linux.
- No macOS-only tools (e.g., `osxkeychain`) may appear in the common config.
- No Arch-only tools may appear in the common config.
- `excludesfile` path must use `$HOME`-relative notation or `~/.gitignore_global` (portable across both platforms).
- If platform-specific credential helpers are needed in the future, they belong in separate `stow/macos/` or `stow/arch/` packages — not in common.

## Git Configuration Strategy

### Approach: Example-First with Deferred Include

1. Maintain `.gitconfig.example` in `stow/common/git/` with safe placeholder values.
2. The user copies or renames `.gitconfig.example` locally (outside the repository) to build a real config.
3. Future option: the user's real `~/.gitconfig` includes the managed common config via Git's `[include]` directive:

   ```ini
   [include]
       path = ~/.gitconfig.common
   ```

   where `~/.gitconfig.common` is the Stow-managed file from this package.

4. Identity, signing, and machine-specific settings stay in the real local `~/.gitconfig` — never tracked.

### Rationale

- Avoids overwriting existing config.
- Separates managed (portable) settings from private (identity, machine-specific) settings.
- The include approach is non-destructive and reversible.
- The user retains full control of when and whether to adopt the managed config.

## Global Gitignore Strategy

### Approach: Example-First

1. Maintain `.gitignore_global.example` in `stow/common/git/` with common patterns.
2. Patterns to include: editor artifacts (`.DS_Store`, `Thumbs.db`, `*.swp`, `*.swo`, `.idea/`, `.vscode/`), OS files, compiled artifacts.
3. The user copies `.gitignore_global.example` locally and sets:

   ```ini
   [core]
       excludesfile = ~/.gitignore_global
   ```

4. Real global gitignore is never tracked in this repository.

## Out of Scope

- Git signing configuration (GPG, SSH signing, 1Password agent) — deferred, undecided.
- SSH configuration — separate scope, separate package if ever added.
- GitHub CLI (`gh`) authentication or credential helpers.
- Work-specific Git identities or `[includeIf]` conditionals for work directories.
- Automatic replacement of the user's existing `~/.gitconfig`.
- Any command that modifies the user's real Git config without explicit approval.
- Arch-specific or macOS-specific credential helper packages (deferred to platform layers).
- Git LFS configuration.
- Repository-level `.gitconfig` or per-project overrides.

## Acceptance Criteria

- [ ] `stow/common/git/.gitconfig.example` contains safe, portable common settings with placeholder values only.
- [ ] `stow/common/git/.gitignore_global.example` contains common ignore patterns, no real paths.
- [ ] No real identity, email, signing keys, or secrets appear anywhere in the package.
- [ ] Documentation describes the include-based adoption strategy clearly.
- [ ] Dry-run Stow instructions are provided and marked with the required safety marker.
- [ ] No Stow command is executed automatically — all commands are shown for manual review.
- [ ] No file outside the repository root is created, modified, or deleted.
- [ ] All example values use the approved placeholder format.
- [ ] Package verified correct on macOS and documented for Arch Linux compatibility.
- [ ] PRD reviewed and status updated to Approved before implementation begins.
