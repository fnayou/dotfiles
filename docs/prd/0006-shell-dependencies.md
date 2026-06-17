# PRD: Shell Dependency Management

**Number:** 0006
**Status:** Approved
**Date:** 2026-06-17

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

- Use **Homebrew Brewfiles** as the declarative source of truth.
- Tiered Brewfiles, one per dependency tier:

  ```
  packages/macos/Brewfile.core      # git, stow, go-task
  packages/macos/Brewfile.shell     # fzf, zoxide, eza, oh-my-posh (+ zinit if formula-managed)
  packages/macos/Brewfile.optional  # optional extras
  ```

- Installation is performed by the user via `brew bundle --file=...`, shown as a manual step — never executed automatically.
- `oh-my-posh` is installed via its Homebrew tap/formula; the Brewfile records the tap if required.
- The exact mapping of `zinit` (formula vs. manual) is deferred to Architecture.

Example manual install (documentation only — not executed here):

```
⚠️  MANUAL STEP — review before running
brew bundle --file=packages/macos/Brewfile.shell
```

---

## Arch Package Strategy

- **Planned, not implemented.** No Arch files are created in this PRD or its first implementation phase.
- Future approach: a declarative package list installed via `pacman` for repo packages and `paru`/`yay` for AUR packages (e.g. `oh-my-posh`, which is typically AUR on Arch).
- Likely future layout (illustrative only):

  ```
  packages/arch/pkglist.core
  packages/arch/pkglist.shell
  packages/arch/pkglist.optional
  ```

- Tool name and availability differences between macOS and Arch must be resolved per-tool when implemented (e.g. `oh-my-posh` AUR vs. Homebrew formula; `eza` availability).
- No pacman/paru/yay commands may be added to shell startup.

---

## Brewfile Strategy

- One Brewfile per tier (`core`, `shell`, `optional`) under `packages/macos/`.
- Brewfiles contain only public formula/cask/tap entries — no secrets, no private taps.
- Brewfiles are **declarative records**, not auto-applied. The user chooses when to run `brew bundle`.
- A combined install is achieved by running `brew bundle` against the tiers the user wants — there is no single all-in-one auto-run.
- Version pinning is out of scope for now; Brewfiles list package names without versions unless a later decision requires pinning.

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
  3. Manually run `brew bundle --file=...` for the desired tier(s).
  4. Re-run the checker to confirm `PASS` for all required tools.
- An optional future convenience target may wrap the macOS install as a manual command:

  ```
  task deps:macos:shell
  ```

  This target, if added later, must only run when the user invokes it explicitly — it must not be wired into shell init, login, or any auto-trigger. It is out of scope for this PRD.

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
- [ ] PRD defines the macOS Brewfile strategy (`Brewfile.core`, `Brewfile.shell`, `Brewfile.optional`).
- [ ] PRD defines the dependency check strategy (`scripts/check-zsh-deps.sh`, read-only, reports clearly).
- [ ] PRD defines a manual bootstrap strategy with the optional future `task deps:macos:shell`.
- [ ] PRD plans the Arch strategy separately without implementing it.
- [ ] PRD states no automatic package installation happens.
- [ ] PRD states no shell startup file installs tools or clones `zinit`.
- [ ] PRD keeps macOS and Arch separated throughout.
- [ ] PRD requires missing tools to be reported clearly.
- [ ] PRD lists explicit safety, privacy, and cross-platform requirements.
- [ ] No package is installed and no file outside the repository is modified.
- [ ] PRD and Architecture 0006 are reviewed together before planning begins.
