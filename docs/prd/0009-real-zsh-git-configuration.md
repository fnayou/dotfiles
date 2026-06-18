# PRD: Real Zsh and Git Configuration Adoption

**Number:** 0009
**Status:** Approved
**Date:** 2026-06-18
**Supersedes:** N/A
**Related:** PRD-0003 (Git package), PRD-0004 (Zsh configuration), PRD-0006 (Shell dependencies), PRD-0007 (Zsh activation migration)

---

## Problem Statement

The zsh managed-layer activation strategy has been defined and merged (PRD-0007). The managed zsh layer is stowed and active: `~/.zshrc` sources the guarded include block, which sources `index.zsh`, which loads the managed layer. However, the managed zsh files (`shared.zsh`, `index.zsh`) still contain placeholder values (`YOUR_EDITOR`, `YOUR_PAGER`) and are not yet populated with the user's real configuration.

Separately, the Git package (`stow/common/git/`) contains only `.example` templates. No real managed Git config exists. The user's real `~/.gitconfig` contains identity values (name, email, signing keys), work-specific includes, and private configuration that must never be committed.

This PRD defines how the user safely moves from placeholder-only managed config to real managed configuration for both zsh and Git, without committing secrets, credentials, or machine-specific values — and without modifying `$HOME` as part of this work.

---

## Goals

- Replace placeholder values in managed zsh files with real, safe, portable configuration.
- Create a managed, committable `~/.gitconfig.common` containing only portable, public-safe Git settings.
- Create a managed, committable `~/.gitignore_global` containing real global ignore patterns.
- Define which configuration is managed (repository-tracked) vs. local (git-ignored, machine-specific).
- Ensure no shell startup file triggers dependency installation, network access, or plugin-manager cloning.
- Ensure all optional tools (fzf, zoxide, eza, Oh My Posh, Zinit) remain guarded and no-op when absent.
- Keep `~/.zshrc` unmanaged — the user controls it directly; the managed layer is sourced from it, not a replacement for it.
- Keep all identity, credentials, signing keys, and work-specific config in local-only (git-ignored) override files.
- Produce verifiable acceptance criteria so architecture and planning can proceed.

---

## Non-Goals

- Do not implement any configuration changes in this PRD.
- Do not modify `$HOME` or any file outside the repository.
- Do not run GNU Stow.
- Do not install or upgrade any dependencies.
- Do not clone Zinit or any plugin.
- Do not inspect, copy, or re-read the user's real `~/.zshrc` or `~/.gitconfig`.
- Do not change the user's login shell.
- Do not manage SSH configuration.
- Do not manage GitHub CLI authentication.
- Do not manage GPG keys or signing infrastructure.
- Do not create a macOS-specific or Arch-specific zsh configuration (in this PRD — belongs to a future package).
- Do not handle `omp.zsh` (Oh My Posh layer) configuration — that is a separate adoption concern.
- Do not define the final file naming for `.gitconfig.common` vs. other names — that belongs to Architecture.

---

## User Stories

- As the user, I want my real portable zsh config (editor, pager, history, aliases, tool integrations) to live in managed files so that the managed layer is the actual source of truth, not a placeholder.
- As the user, I want `~/.zshrc` to remain untouched so that I keep full direct control over my shell entry point.
- As the user, I want a managed, committable Git config for portable settings (editor, pull strategy, diff settings, aliases) so that a new machine gets sensible Git defaults without manual setup.
- As the user, I want identity, email, signing keys, and work-specific includes in a local-only file so that private values never reach the repository.
- As the user, I want all tool integrations in managed zsh files to be guarded so that opening a shell on a machine where a tool is missing does not produce errors.
- As the user, I want a clear rollback path so that if a managed config misbehaves I can revert without shell breakage.

---

## Scope

### In Scope

**Zsh:**
- Populating `shared.zsh` with real portable config: XDG vars, editor, pager, history settings, shell options, Zinit source guard, completion init, tool integration guards (fzf, zoxide, eza), portable aliases.
- Populating `index.zsh` with the real source order: shared → platform → omp → local.
- Defining what goes in `local.zsh` (machine-specific, git-ignored, not provided as a template with secrets).
- Confirming that `macos.zsh` and `arch.zsh` remain as `.example`-only in this adoption (platform-specific real configs are a future step).

**Git:**
- Creating a managed `~/.gitconfig.common` (or equivalent name decided in Architecture) with safe portable settings: core editor, whitespace, `excludesfile` pointer, pull strategy, merge conflict style, diff options, color, and curated aliases.
- Creating a managed `~/.gitignore_global` with real global ignore patterns: macOS artifacts, Linux artifacts, editor artifacts, build artifacts, environment files.
- Defining the local override file for: user identity (name, email), signing key, work-specific `[includeIf]` blocks, machine-specific settings.
- Defining how `~/.gitconfig` on a new machine wires `[include]` to the managed common file.

### Out of Scope

- SSH configuration.
- GitHub CLI authentication.
- GPG key management.
- Zinit plugin list or plugin configuration.
- Oh My Posh theme or prompt configuration.
- macOS-specific zsh config (beyond what shared.zsh already covers portably).
- Arch-specific zsh config.
- Any `stow` execution against `$HOME`.

---

## Safety Requirements

- Must not delete, overwrite, or move any file in `$HOME`.
- Must not run `stow --adopt` or any Stow command automatically.
- Must not commit any file containing real name, email, hostname, token, API key, password, SSH private key, or signing key.
- Must not place any install command, `brew install`, `pacman -S`, `git clone`, or network call inside a shell startup file.
- Must not trigger Zinit cloning at shell startup — Zinit must be sourced only if its directory already exists.
- All optional tool integration lines must be individually guarded with `command -v <tool> >/dev/null 2>&1` before any `eval` or `alias`.
- Any Stow dry-run or install command shown to the user must be explicitly marked:
  ```
  ⚠️  MANUAL STEP — review before running
  ```
- Git config adoption must not break the user's existing `~/.gitconfig` — the managed file is included, not a replacement.

---

## Privacy Requirements

The following must never appear in any committed file:

| Category | Examples |
|---|---|
| Identity | Real name, real email address |
| Credentials | API keys, tokens, passwords, passphrases |
| SSH material | Private key content, `IdentityFile` paths with real paths |
| Signing | GPG key IDs, signing key fingerprints |
| Work config | Work hostnames, work Git remotes, work `[includeIf]` paths |
| Machine-specific | Machine hostname, username, absolute paths with username |

All committed files must use placeholder values wherever a real value could exist:
- `YOUR_EDITOR`, `YOUR_PAGER`, `YOUR_NAME`, `YOUR_EMAIL`
- `hostname.example.com`, `your-token-here`

Real values live only in local, git-ignored override files.

---

## Zsh Adoption Strategy

### Managed files (committed)

| File | Purpose | Committed |
|---|---|---|
| `shared.zsh` | Portable env, history, options, tool guards, aliases | Yes — placeholder values replaced with safe real values |
| `index.zsh` | Source order only: shared → platform → omp → local | Yes |
| `shared.zsh.example` | Template for new machines | Yes |
| `index.zsh.example` | Template for new machines | Yes |
| `macos.zsh.example` | Platform template | Yes |
| `arch.zsh.example` | Platform template | Yes |
| `omp.zsh.example` | OMP activation template | Yes |

### Local-only files (git-ignored)

| File | Purpose | Committed |
|---|---|---|
| `local.zsh` | Machine-specific overrides, private values, work config | No |
| `macos.zsh` | Real macOS config when adopted | No (until scope expands) |
| `arch.zsh` | Real Arch config when adopted | No (until scope expands) |
| `omp.zsh` | Real OMP activation when adopted | No (until scope expands) |

### Invariants

- `shared.zsh` must contain no install commands, no clone commands, no network calls.
- Every tool integration line uses a `command -v` guard — no unconditional `eval`.
- Zinit is sourced only if `${ZINIT_HOME}/zinit.zsh` exists — no auto-clone fallback.
- `compinit` is called only when Zinit is not loaded (to avoid double init).
- No Homebrew calls, no `pacman`, no `pbcopy`/`open`, no `systemctl` in `shared.zsh`.
- Platform-specific logic belongs in `macos.zsh` / `arch.zsh`, not in `shared.zsh`.

---

## Git Adoption Strategy

### Managed files (committed)

| File | Purpose | Committed |
|---|---|---|
| `.gitconfig.common` | Portable Git settings (no identity) | Yes |
| `.gitignore_global` | Real global ignore patterns | Yes |
| `.gitconfig.example` | Template showing expected structure | Yes |
| `.gitignore_global.example` | Template | Yes |

### Local-only files (git-ignored, provided via `.local` convention)

| File | Purpose | Committed |
|---|---|---|
| `.gitconfig.local` | Identity, signing key, work includes | No |

### `.gitconfig.common` scope (safe to commit)

- `[core]` — editor (placeholder if machine-specific), `autocrlf`, `whitespace`, `excludesfile` path
- `[pull]` — rebase strategy
- `[merge]` — `conflictstyle`
- `[diff]` — `colorMoved`
- `[color]` — `ui = auto`
- `[alias]` — curated portable aliases (no identity-dependent aliases)
- `[init]` — `defaultBranch`

### `.gitconfig.common` exclusions (goes in `.gitconfig.local`)

- `[user]` name, email, signingkey
- `[gpg]` format
- `[commit]` gpgsign
- `[includeIf]` for work directories
- Any remote URL with credentials

### Wiring on a new machine

The user's real `~/.gitconfig` includes the managed common file:

```gitconfig
[include]
    path = ~/.gitconfig.common
```

The local override file is included after:

```gitconfig
[include]
    path = ~/.gitconfig.local
```

Include order ensures `.gitconfig.local` wins over `.gitconfig.common` for any conflicting keys.

---

## Local/Private Override Strategy

### Zsh

`local.zsh` is always sourced last by `index.zsh`. It wins over everything else. It is git-ignored and never committed. It holds:
- Work-specific `$PATH` additions
- Work aliases or functions
- Machine-specific environment variables
- Private API tokens (if managed in shell at all)

No `.example` template is provided for `local.zsh` — its contents are by definition machine-specific and must not be templated in the repository.

### Git

`.gitconfig.local` is included after `.gitconfig.common` and wins over it. It holds:
- `[user]` name, email, signingkey
- `[commit]` gpgsign
- `[gpg]` settings
- `[includeIf]` work directory conditionals

A `.gitconfig.local.example` template may be provided in the repository using placeholder values only, to document expected structure without committing real values.

---

## Validation Strategy

### Zsh validation

1. After stowing the zsh package, open a new shell and verify:
   - Shell starts without errors.
   - `$EDITOR` and `$PAGER` are set to expected values.
   - `$HISTFILE`, `$HISTSIZE`, `$SAVEHIST` are set correctly.
   - `fzf`, `zoxide`, `eza` integrations activate when the tools are installed and are silent no-ops when absent.
   - Zinit loads when installed; no error when absent.
   - `local.zsh` overrides take effect.
2. Verify no `brew install`, `pacman`, `git clone`, or network call appears in shell startup (`set -x` trace if needed).
3. Verify `~/.zshrc` is unchanged.

### Git validation

1. After stowing the Git package, verify:
   - `git config --list --show-origin` shows `.gitconfig.common` values active.
   - `git config user.name` and `git config user.email` resolve from `.gitconfig.local`, not `.gitconfig.common`.
   - `git config core.excludesfile` points to `~/.gitignore_global`.
   - Common ignore patterns from `.gitignore_global` are active (`git check-ignore -v <file>`).
2. Verify no identity values appear in `.gitconfig.common`.
3. Verify `git diff --staged` on any staged managed file shows no real name, email, token, or key.

---

## Rollback Strategy

### Zsh rollback

The managed zsh layer is loaded via a guarded include block in `~/.zshrc`. Rollback:

1. Remove or comment out the guarded include block in `~/.zshrc`.
2. Shell immediately reverts to pre-managed behavior on next session.
3. No managed file deletion required — the files exist but are not sourced.

This is the same rollback defined in PRD-0007. No new rollback mechanism needed.

### Git rollback

1. Remove the `[include] path = ~/.gitconfig.common` line from `~/.gitconfig`.
2. Git immediately uses only the remaining `~/.gitconfig` settings.
3. The managed files remain in place but are not applied.

---

## Acceptance Criteria

### Zsh

- [ ] `shared.zsh` contains no placeholder `YOUR_*` tokens — all values are real or omitted.
- [ ] `shared.zsh` contains no install command, clone command, or network call.
- [ ] Every tool integration line in `shared.zsh` is guarded with `command -v`.
- [ ] Zinit is sourced only behind an existence check for `${ZINIT_HOME}/zinit.zsh`.
- [ ] `index.zsh` sources: shared → platform (OS-detected) → omp → local.
- [ ] `local.zsh` is listed in `.gitignore` and not committed.
- [ ] A new shell session starts without errors on a machine where all tools are installed.
- [ ] A new shell session starts without errors on a machine where no optional tools are installed.
- [ ] `~/.zshrc` is not modified as part of this work.
- [ ] No macOS-specific commands (`pbcopy`, `open`, `brew`) appear in `shared.zsh`.

### Git

- [ ] `.gitconfig.common` exists and is committed.
- [ ] `.gitconfig.common` contains no `[user]` name, email, or signingkey.
- [ ] `.gitconfig.common` contains no `[includeIf]` blocks.
- [ ] `.gitignore_global` exists and is committed with real ignore patterns.
- [ ] `.gitconfig.local` (or `.gitconfig.local.example`) documents the local identity structure using placeholder values.
- [ ] `.gitconfig.local` is listed in `.gitignore` and not committed.
- [ ] `git config --list --show-origin` shows `.gitconfig.common` values active after stowing.
- [ ] `git config user.email` resolves from `.gitconfig.local`, not `.gitconfig.common`.
- [ ] Staged managed Git files pass privacy audit (no real name, email, token, key).

### General

- [ ] No file in `$HOME` is modified as part of implementing this work.
- [ ] All Stow install commands are presented as manual steps with `⚠️  MANUAL STEP` markers.
- [ ] Dry-run (`stow --simulate`) output is reviewed before any stow install.

---

## Out of Scope

- SSH configuration of any kind (`~/.ssh/config`, SSH keys, SSH agents).
- GitHub CLI authentication (`~/.config/gh/`).
- GPG key generation or management.
- Zinit plugin list or plugin configuration files.
- Oh My Posh theme or prompt configuration (covered by PRD-0005 and future adoption PR).
- macOS-specific zsh configuration beyond what `shared.zsh` covers portably.
- Arch Linux-specific zsh configuration.
- Automated bootstrap or provisioning scripts.
- Any CI/CD or remote validation.
- `chsh` or login shell changes.
