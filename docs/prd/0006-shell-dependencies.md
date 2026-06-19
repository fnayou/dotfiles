# PRD: Shell Dependency Management

**Number:** 0006
**Status:** Approved — partially superseded by ADR-0045
**Date:** 2026-06-17

> **Amendment (ADR-0045 — 2026-06-19):** The tiered Brewfile strategy (`packages/macos/Brewfile.core/.shell/.optional`) described in this PRD was superseded. Implementation consolidated to a single `packages/Brewfile` covering all tools (including `bat`, which was missing from the original scope). Arch/EndeavourOS support was implemented (not deferred) via `packages/arch/packages.txt`. The `task deps:macos:shell` target was implemented as `task deps:brew`; `task deps:arch` was added. All other constraints, check strategy, and safety rules remain in force.

---

## Problem Statement

The user's zsh configuration depends on external tools that are not part of a default shell install — `fzf`, `zoxide`, `eza`, `oh-my-posh`, and the `zinit` plugin manager — plus baseline repository tooling (`git`, `stow`, `go-task`). On macOS these are installed via Homebrew today, but nothing in the dotfiles repository records, verifies, or reproduces that dependency set.

This creates two problems:

1. **Reproducibility:** A new machine has no declarative list of what shell tooling must be present.
2. **Safety:** It is tempting to make shell startup auto-install missing tools or auto-clone `zinit`. That pattern is slow, opaque, and dangerous — it runs network and package-manager operations on every shell launch and can silently mutate the user's environment.

This PRD defines a safe dependency-management strategy: declarative dependency lists, a non-installing checker script, and a manual bootstrap path. macOS (Homebrew) is the first-class target; EndeavourOS/Arch is planned but deferred. Nothing is implemented in this PRD.

---

## Goals

- Define a declarative way to record shell dependencies for macOS using Homebrew Brewfiles.
- Define a dependency **check** strategy that reports missing tools clearly and never installs them.
- Define a manual **bootstrap** strategy that the user runs deliberately — never shell startup.
- Separate dependencies into tiers: core repository tooling, shell runtime tooling, and optional extras.
- Plan an Arch/EndeavourOS strategy (pacman/paru/yay) without implementing it.
- Keep shell startup free of any install, clone, or network side effects.
- Cover the explicit tool set: `git`, `stow`, `go-task`, `fzf`, `zoxide`, `eza`, `oh-my-posh`, `zinit`.

---

## Non-Goals

- Do not implement any script, Brewfile, or Taskfile target in this PRD.
- Do not install any package.
- Do not modify `~/.zshrc` or any shell startup file.
- Do not modify `$HOME` or any path outside the repository.
- Do not run GNU Stow (a safe fake-home dry-run is permitted only if validation later requires it).
- Do not add automatic installs to shell startup files.
- Do not clone `zinit` automatically from shell startup.
- Do not implement the Arch package strategy yet.
- Do not pin exact tool versions (version pinning is a later decision).

---

## User Stories

- As a user, I want a declarative list of my shell dependencies so that I can reproduce my environment on a new macOS machine.
- As a user, I want a checker script that tells me exactly which tools are missing so that I know what to install before using my shell config.
- As a user, I want installs to be explicit and manual so that my shell never silently runs Homebrew or clones repositories on startup.
- As a user, I want dependencies grouped into core, shell, and optional tiers so that I can install only what I need.
- As a user, I want the Arch strategy planned but separate so that macOS work is not blocked and platforms never get mixed.

---

## Constraints

- **Platform:** macOS first (Homebrew). EndeavourOS/Arch planned, implemented later. The two must never be mixed in one file or one command.
- **Shell:** Targets zsh only.
- **Safety:** No file outside the repository may be created, modified, or deleted without explicit per-session user approval.
- **No startup side effects:** Dependency logic must never run from `~/.zshrc` or any shell init file.
- **Check, don't install:** Scripts may detect and explain missing tools; they must not install them.
- **Privacy:** No real personal values, paths, or secrets in any committed file.
- **Tooling baseline:** `git`, `stow`, and `go-task` are repository-level prerequisites already partially checked by `scripts/check.sh`; shell tools extend, not replace, that baseline.

---

## Safety Requirements

- Must not add any install, `brew bundle`, `git clone`, or network command to shell startup files.
- Must not auto-clone `zinit` from `~/.zshrc` or any sourced file.
- The checker script must be **read-only** — `command -v` style detection only, no mutation, no network.
- Any install command (Homebrew or future pacman/paru) must be **shown to the user, not executed** by an agent.
- Bootstrap must be a deliberate, manually-run step — never triggered by shell launch, login, or provisioning automatically.
- Must not delete, move, or overwrite existing files in `$HOME`.
- Any future Stow involvement must follow established Stow rules: `stow --simulate` first, no `--adopt`.
- Dangerous commands in documentation must carry the `⚠️  MANUAL STEP` marker.

---

## Privacy Requirements

- No API keys, tokens, passwords, or credentials in Brewfiles, scripts, or Taskfiles.
- No private hostnames, internal IPs, or internal service URLs.
- No real `$HOME`-based paths revealing username or machine layout — use `$HOME`/`$USER`.
- Brewfiles list public package names only — no tap URLs containing secrets.
- Any file that could capture sensitive values must be a `.example`/`.template` and noted for `.gitignore`.

---

## Cross-Platform Requirements

- macOS and Arch dependency definitions must live in separate files/directories — never mixed.
- Homebrew references must never appear in Arch files; pacman/paru/yay references must never appear in macOS files.
- The checker script must detect tool presence in a platform-neutral way (`command -v`), but any **install hint** it prints must be platform-specific and OS-detected.
- OS detection pattern when required:

  ```bash
  if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
  elif [[ -f /etc/arch-release ]]; then
    # Arch / EndeavourOS
  else
    echo "Unsupported OS"
    exit 1
  fi
  ```

---

## Dependency Tiers

Dependencies are grouped into three tiers so the user installs only what they need.

| Tier | Purpose | Tools |
|------|---------|-------|
| **Core** | Repository prerequisites needed to manage dotfiles at all | `git`, `stow`, `go-task` |
| **Shell** | Runtime tooling the zsh config expects | `fzf`, `zoxide`, `eza`, `oh-my-posh`, `zinit` |
| **Optional** | Nice-to-have extras, not required for a working shell | (deferred — e.g. additional CLI utilities) |

Notes on `zinit`: it is a zsh **plugin manager**, not a Homebrew formula in the typical setup. Its installation path (Homebrew formula vs. manual clone vs. user-managed) is an open question for the Architecture document. Regardless of choice, it must never be auto-cloned from shell startup.

---

## macOS Package Strategy

> **Superseded by ADR-0045.** See amendment note above.

~~Tiered Brewfiles under `packages/macos/`.~~ Replaced by a single `packages/Brewfile` covering all tiers.

- Use **Homebrew Brewfiles** as the declarative source of truth.
- Single Brewfile covering all tools (repo prerequisites + shell runtime):

  ```
  packages/Brewfile      # git, stow, go-task, fzf, zoxide, eza, bat, oh-my-posh
  ```

- Installation is performed by the user via `brew bundle --file=packages/Brewfile`, shown as a manual step — never executed automatically.
- `oh-my-posh` is installed via its Homebrew tap/formula; the Brewfile records the tap.
- `zinit` is not in the Brewfile — it is installed via manual `git clone` (Decision 6 in Architecture 0006).

Example manual install:

```
⚠️  MANUAL STEP — review before running
brew bundle --file=packages/Brewfile
```

---

## Arch Package Strategy

> **Implemented (ADR-0045).** No longer deferred.

- Declarative package list at `packages/arch/packages.txt` covering all tools.
- Pacman packages: `git stow go-task fzf zoxide eza bat`
- AUR packages (yay/paru): `oh-my-posh-bin`
- `zinit` installed via manual `git clone` (same as macOS).
- No pacman/paru/yay commands may be added to shell startup.

---

## Brewfile Strategy

> **Updated by ADR-0045.** Single file replaces tiered layout.

- One `packages/Brewfile` covering all tools.
- Brewfiles contain only public formula/cask/tap entries — no secrets, no private taps.
- Brewfiles are **declarative records**, not auto-applied. The user chooses when to run `brew bundle`.
- One command installs everything: `brew bundle --file=packages/Brewfile`.
- Version pinning is out of scope; Brewfiles list package names without versions.

---

## Dependency Check Strategy

- A dedicated script reports shell dependency status without installing anything:

  ```
  scripts/check-zsh-deps.sh
  ```

- Behavior:
  - Detects each shell tool with `command -v` (read-only).
  - Prints `PASS` / `FAIL` per tool, consistent with the existing `scripts/check.sh` format.
  - On failure, prints a **platform-specific install hint** (OS-detected) — but does not run it.
  - Exits non-zero if any required tool is missing, so it can gate manual workflows.
- The script must never install, clone, or perform network operations.
- Relationship to `scripts/check.sh`: that script covers core repo tooling (`git`, `stow`, `task`). `check-zsh-deps.sh` covers the shell tier (`fzf`, `zoxide`, `eza`, `oh-my-posh`, `zinit`). Whether they stay separate or one calls the other is an Architecture decision.

---

## Bootstrap Strategy

- Bootstrap is a **deliberate, manually-run** step — never automatic, never from shell startup or provisioning.
- Recommended flow:
  1. Run `scripts/check-zsh-deps.sh` to see what is missing.
  2. Review the printed Brewfile / install commands.
  3. Manually run `brew bundle --file=packages/Brewfile` (macOS) or the pacman/AUR commands (Arch).
  4. Re-run the checker to confirm `PASS` for all required tools.
- Convenience print-only targets are implemented:

  ```
  task deps:brew    # print macOS / Homebrew install commands
  task deps:arch    # print Arch / EndeavourOS install commands
  ```

  These targets only print instructions — they do not install anything.

---

## Out of Scope

- Implementing any Brewfile, script, or Taskfile target.
- Installing any package on any platform.
- Modifying `~/.zshrc` or any shell startup file.
- Adding install, clone, or network operations to shell startup.
- Auto-cloning `zinit`.
- Implementing the Arch/EndeavourOS package strategy.
- Implementing the `task deps:macos:shell` target.
- Version pinning of any dependency.
- Defining the optional-tier tool list in detail.
- Choosing how `zinit` is installed (formula vs. manual clone) — deferred to Architecture.
- Creating symlinks in `$HOME` or running GNU Stow installs.
- Modifying `$HOME` or any path outside the repository.

---

## Acceptance Criteria

- [ ] PRD exists at `docs/prd/0006-shell-dependencies.md`.
- [ ] Dependency strategy is documented (check, document, install paths defined).
- [ ] PRD defines problem statement, goals, non-goals, and user stories.
- [ ] PRD defines core / shell / optional dependency tiers covering `git`, `stow`, `go-task`, `fzf`, `zoxide`, `eza`, `oh-my-posh`, `zinit`.
- [x] PRD defines the macOS Brewfile strategy — updated to single `packages/Brewfile` (ADR-0045).
- [x] PRD defines the dependency check strategy (`scripts/check-zsh-deps.sh`, read-only, reports clearly).
- [x] PRD defines a manual bootstrap strategy — `task deps:brew` and `task deps:arch` implemented.
- [x] PRD plans the Arch strategy — implemented via `packages/arch/packages.txt` (ADR-0045).
- [ ] PRD states no automatic package installation happens.
- [ ] PRD states no shell startup file installs tools or clones `zinit`.
- [ ] PRD keeps macOS and Arch separated throughout.
- [ ] PRD requires missing tools to be reported clearly.
- [ ] PRD lists explicit safety, privacy, and cross-platform requirements.
- [ ] No package is installed and no file outside the repository is modified.
- [ ] PRD and Architecture 0006 are reviewed together before planning begins.
