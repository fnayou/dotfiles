# PRD: Zsh Activation & Migration Strategy

**Number:** 0007
**Status:** Draft
**Date:** 2026-06-17

---

## Problem Statement

The repository now contains a zsh configuration foundation (PRD 0004), Oh My Posh support as template/example-only (PRD 0005), and shell dependency management with safe checks and macOS manifests (PRD 0006). None of it is active. The user's real `~/.zshrc` is a working, hand-tuned file that currently relies on Homebrew, Zinit, Oh My Posh, fzf, zoxide, eza, aliases, history settings, completions, and local overrides.

There is no defined, safe path from "managed config exists in the repo but unused" to "managed config is the source of truth" without risking the user's working shell. An abrupt replacement of `~/.zshrc` could break the user's primary environment (macOS), lose customizations, or trigger automatic tool installation / plugin-manager bootstrapping at shell startup — all of which violate the repository's safety rules.

This PRD defines **how** the managed zsh configuration should be activated and **how** the user migrates from the existing `~/.zshrc` to managed config — incrementally, reversibly, and without ever modifying `$HOME` as part of this work. It evaluates four activation models and recommends a direction. It does **not** implement anything.

---

## Goals

- Define a safe, reversible migration path from the user's existing `~/.zshrc` to managed zsh configuration.
- Evaluate four activation models and recommend the safest direction.
- Guarantee the user's working shell on macOS is never broken during migration.
- Keep all tool installation and plugin-manager bootstrapping **out** of shell startup files.
- Keep Oh My Posh activation explicit and guarded (never automatic).
- Keep Zinit cloning explicit and manual (never triggered from shell startup).
- Define a rollback strategy that restores the prior shell state quickly.
- Keep macOS (primary) and Arch (planned) activation concerns separated.
- Define verifiable acceptance criteria for when migration design is "done."

---

## Non-Goals

- Do not implement any activation code, include block, or migration script.
- Do not modify `~/.zshrc` or any file in `$HOME`.
- Do not inspect, re-read, or copy the user's real `~/.zshrc` (unless the user explicitly pastes it into the conversation).
- Do not create symlinks in `$HOME`.
- Do not run GNU Stow against the real `$HOME` (fake-home dry-run validation only, if needed).
- Do not install dependencies (Homebrew, Zinit, fzf, zoxide, eza, Oh My Posh, etc.).
- Do not clone Zinit.
- Do not activate Oh My Posh.
- Do not change the user's login shell (`chsh`).
- Do not decide the final file structure — that belongs to the Architecture document.
- Do not proceed to architecture or planning in this PRD.

---

## User Stories

- As the user, I want a defined migration path so that I can move to managed zsh config without an abrupt cutover.
- As the user, I want my existing `~/.zshrc` left untouched until I personally choose to migrate, so that my primary macOS shell keeps working.
- As the user, I want managed config to be opt-in and incremental, so that I can adopt one piece at a time and verify each step.
- As the user, I want no tool to install itself and no plugin manager to clone itself at shell startup, so that opening a shell is fast, predictable, and offline-safe.
- As the user, I want a fast rollback, so that if a managed piece misbehaves I can return to my previous working shell immediately.

---

## Scope

### In scope

- Migration strategy from existing `~/.zshrc` to managed config.
- Activation strategy: evaluation of four models and a recommendation.
- Rollback strategy.
- Safety, privacy, dependency assumptions, and cross-platform (macOS/Arch) considerations specific to activation.
- Guardrails ensuring no auto-install and no auto-clone from shell startup.

### Out of scope

- Final file/layout decisions (Architecture).
- Concrete `.zshrc` content, include-block text, or migration script (Implementation).
- Plugin/prompt feature choices beyond what already exists in PRDs 0004–0006.
- Terminal emulator, font installation, or non-zsh shells.

---

## Activation Model Evaluation

Four activation models are evaluated against the same criteria: **safety** (risk to the working shell), **reproducibility** (new-machine setup), **reversibility** (rollback ease), **auto-install/auto-clone risk**, and **maintenance burden**.

### Model 1 — User-managed `~/.zshrc` sources managed files manually

The user keeps full ownership of `~/.zshrc`. They add explicit `source` lines pointing at managed files under `~/.config/zsh/` themselves.

```zsh
# ~/.zshrc — user-owned, NOT version controlled
source "$HOME/.config/zsh/shared.zsh"   # user adds this line by hand
```

- **Safety:** High. `~/.zshrc` is never managed or overwritten; the user controls every line.
- **Reproducibility:** Low. The bootstrap `~/.zshrc` is manual and not version-controlled.
- **Reversibility:** High. Remove the `source` line to revert.
- **Auto-install/clone risk:** None added by design — managed files must not bootstrap tools.
- **Maintenance:** Medium. User manually keeps `source` lines in sync with new managed files.

### Model 2 — Tiny managed `~/.zshrc` that sources `~/.config/zsh/*.zsh`

A minimal, version-controlled `~/.zshrc` (stowed) whose only job is to source managed fragments.

```zsh
# ~/.zshrc — managed/stowed, minimal loader
for f in "$HOME/.config/zsh"/*.zsh; do
  [[ -r "$f" ]] && source "$f"
done
```

- **Safety:** Low for migration. Requires replacing the user's existing `~/.zshrc` — the exact abrupt cutover the user wants to avoid. Stow will refuse/conflict against the existing real file.
- **Reproducibility:** High. Full setup is one stow command on a new machine.
- **Reversibility:** Medium. Requires unstowing and restoring the prior `~/.zshrc` from backup.
- **Auto-install/clone risk:** None if fragments stay declarative — but the loader pattern invites future "just bootstrap here" temptation.
- **Maintenance:** Low once adopted.

### Model 3 — Unmanaged `~/.zshrc` with one managed include block

The user keeps their own `~/.zshrc`, but adds a single, clearly delimited managed include block (guarded) that sources managed config. The block is the only managed-controlled region; everything else stays user-owned.

```zsh
# >>> dotfiles managed (zsh) >>>
# Single guarded include. User adds this block once, by hand.
[[ -r "$HOME/.config/zsh/index.zsh" ]] && source "$HOME/.config/zsh/index.zsh"
# <<< dotfiles managed (zsh) <<<
```

- **Safety:** High. `~/.zshrc` stays user-owned; no Stow conflict; existing config preserved. Incremental — the included `index.zsh` can start nearly empty and grow.
- **Reproducibility:** Medium. The block is documented and copy-pasteable, but the user adds it manually (acceptable: aligns with the Git package include-based precedent).
- **Reversibility:** High. Delete the block (or comment it) to revert instantly; managed files remain inert.
- **Auto-install/clone risk:** None — the included files must remain declarative; guards prevent activation when tools/configs are absent.
- **Maintenance:** Low. New managed fragments are wired up inside `index.zsh`, not in `~/.zshrc`.

This mirrors the include-based model already established for the Git package (XDG paths + include over replacement).

### Model 4 — `.zshrc.example` only, until manual migration

Ship a `~/.zshrc.example` in the repo. The user manually diffs it against their real `~/.zshrc` and migrates by hand whenever they choose. No include, no loader, no stow of `~/.zshrc`.

- **Safety:** Highest. Nothing is wired up; zero risk to the working shell.
- **Reproducibility:** Low. Migration is fully manual and undocumented per-machine.
- **Reversibility:** N/A — nothing is activated.
- **Auto-install/clone risk:** None.
- **Maintenance:** High long-term — the example drifts from reality; no real adoption path.

### Comparison summary

| Model | Safety | Reproducible | Reversible | Auto-install risk | Incremental |
|-------|--------|--------------|------------|-------------------|-------------|
| 1 — manual source | High | Low | High | None | Yes |
| 2 — tiny managed `~/.zshrc` | Low (abrupt cutover) | High | Medium | Low | No |
| 3 — unmanaged + include block | High | Medium | High | None | Yes |
| 4 — `.example` only | Highest | Low | N/A | None | No (no path) |

**Recommendation:** **Model 3 (unmanaged `~/.zshrc` + one guarded managed include block)** as the migration target, using **Model 4 (`.example` only)** as the starting state during early adoption. Model 3 preserves the working shell, is fully reversible, adds no auto-install/auto-clone risk, stays incremental, and matches the repository's established include-based Git precedent. Model 2 is rejected for migration because it requires the abrupt `~/.zshrc` replacement the user explicitly wants to avoid; it may be reconsidered later for fresh-machine provisioning only.

---

## Safety Requirements

- Must not modify, move, delete, or overwrite `~/.zshrc` or any file in `$HOME`.
- Must not re-read or copy the user's real `~/.zshrc` unless the user pastes it into the conversation.
- Must not create symlinks in `$HOME`.
- Must not run `stow` against the real `$HOME`; only fake-home (temp dir) `--simulate`/dry-run validation is permitted.
- Must never use `stow --adopt`.
- No managed shell file may install tools (no `brew install`, `pacman -S`, `git clone` of Zinit, downloads, etc.) at startup.
- No managed shell file may clone Zinit or any plugin manager automatically.
- Oh My Posh activation must remain explicit and guarded — only `eval` the prompt when the binary **and** the config file exist.
- Every managed include and source must be guarded (`command -v`, `[[ -r ... ]]`, `[[ -x ... ]]`) so an absent tool/config never breaks shell startup.
- The managed include block (Model 3) must be added by the user by hand, never written into `$HOME` by an agent or script.
- Any risky step shown to the user must carry the `⚠️  MANUAL STEP` marker.

---

## Privacy Requirements

- No real API keys, tokens, passwords, or credentials in any committed zsh file.
- No real private hostnames, internal IPs, or work-specific values.
- No real `$HOME`-revealing absolute paths; use `$HOME`, `$XDG_CONFIG_HOME`, `$USER`.
- Local overrides (the user's machine-specific or sensitive settings) must live in a git-ignored local file (e.g. `~/.config/zsh/local.zsh`), sourced only if present and never committed.
- All committed templates remain `.example`/placeholder-only, consistent with PRD 0004.

---

## Migration Strategy

Incremental, opt-in, reversible. Each phase is independently safe and stops at a working shell.

1. **Phase 0 — Inventory (design only):** Catalog what the existing `~/.zshrc` provides (Homebrew init, Zinit, Oh My Posh, fzf, zoxide, eza, aliases, history, completions, local overrides) based on user-provided context only. No file inspection.
2. **Phase 1 — Example parity:** Ensure managed `.example` files cover each capability with guarded, declarative snippets (Model 4 starting state). Nothing activated.
3. **Phase 2 — Side-by-side, no wiring:** User copies `.example` files to real (git-ignored) managed files under `~/.config/zsh/` and reviews them. `~/.zshrc` still untouched; managed files inert.
4. **Phase 3 — Single include (Model 3):** User manually adds the one guarded managed include block to their existing `~/.zshrc`. The included `index.zsh` starts minimal. User opens a new shell to verify.
5. **Phase 4 — Incremental cutover:** User moves capabilities one at a time from their hand-written `~/.zshrc` lines into managed fragments (history, then completions, then aliases, then tool integrations, then prompt), verifying after each move. Tool installs and Zinit clone remain manual, out-of-band steps.
6. **Phase 5 — Steady state:** Managed config is the source of truth for migrated capabilities; `~/.zshrc` retains only the include block plus any user-chosen personal lines and the git-ignored local override source.

Phases 2–5 are user-driven and out of scope for this PRD's implementation. The PRD defines the path, not the code.

---

## Activation Strategy

- **Default state:** inert. Managed files do nothing until the user adds the include block by hand (Model 3).
- **Guarded activation:** every integration checks for its prerequisite before acting:
  - Oh My Posh: `command -v oh-my-posh` **and** `[[ -f "$HOME/.config/omp/omp.toml" ]]` before `eval`.
  - Zinit: sourced only if already installed; **never** cloned from startup. A missing Zinit must be a no-op, not a bootstrap.
  - fzf / zoxide / eza: integration/aliases applied only if the binary is present (`command -v`).
- **No auto-install / no auto-clone:** shell startup must never run a package manager or `git clone`. Installation is documented as a separate manual step (see PRD 0006 dependency checks).
- **Local overrides last:** managed `index.zsh` sources `~/.config/zsh/local.zsh` (git-ignored) at the end, if present, so the user's machine-specific settings win.

---

## Rollback Strategy

- **Instant revert (Model 3):** comment out or delete the managed include block in `~/.zshrc`; open a new shell. Managed files become inert immediately. No data loss.
- **Backup before any include:** before adding the include block, the user copies `~/.zshrc` to a timestamped backup (e.g. `~/.zshrc.bak.YYYYMMDD`). `⚠️  MANUAL STEP`.
- **Per-capability rollback:** because cutover is incremental (Phase 4), reverting one capability means restoring that one block in `~/.zshrc` from the backup — the rest stays managed.
- **Full abort:** restore `~/.zshrc` from backup; optionally remove the git-ignored managed files under `~/.config/zsh/`. No symlinks were created, so nothing in `$HOME` is left dangling.
- **Stow note:** since Model 3 does not stow `~/.zshrc`, there is no unstow step for the loader; only the user's manual edits and backups are involved.

---

## Dependency Assumptions

- Tools the existing shell uses — Homebrew, Zinit, Oh My Posh, fzf, zoxide, eza — are assumed **already installed** by the user on their primary macOS machine. Managed config integrates with them only when present.
- Dependency **presence** is verified by guards at runtime (`command -v`) and by the PRD 0006 dependency-check tooling out-of-band — never installed at startup.
- Zinit is assumed user-installed; managed config sources it if found and does nothing if absent. No clone, ever, from startup.
- Oh My Posh requires its binary, a Nerd Font in the terminal, and `~/.config/omp/omp.toml`; activation stays guarded per PRD 0005.
- On a fresh machine where tools are absent, the shell must still start cleanly with every integration skipped.

---

## macOS Considerations

- Primary, frequently-used environment — migration must never break it; this drives the Model 3 / incremental recommendation.
- Homebrew prefix differs (`/opt/homebrew` Apple Silicon vs `/usr/local` Intel); brew `shellenv` init belongs in a macOS-specific managed fragment, guarded by `command -v brew`, not in shared config.
- macOS-only tools/aliases (`pbcopy`, `open`) stay in the macOS fragment.
- Validation may use a fake `$HOME` temp dir with `stow --simulate`; never the real macOS `$HOME`.

## Arch Considerations

- EndeavourOS/Arch remains **planned**, not active. The same activation model (Model 3 + guards) must apply unchanged so behavior is consistent across platforms.
- No Homebrew assumptions on Arch; package presence is detected, not assumed. pacman/yay aliases live in an Arch-specific fragment only.
- Zinit/Oh My Posh install paths differ on Arch; guards (`command -v`, file-exists) must make fragments portable without per-OS auto-install.
- Arch fragments must not leak into shared or macOS files (cross-platform rule).

---

## Acceptance Criteria

- [ ] PRD exists at `docs/prd/0007-zsh-activation-migration.md`.
- [ ] PRD defines problem statement, goals, non-goals, user stories, and scope.
- [ ] PRD evaluates all four activation models against safety, reproducibility, reversibility, auto-install risk, and incrementality.
- [ ] PRD recommends a safest direction (Model 3 target, Model 4 starting state) with rationale.
- [ ] PRD defines migration, activation, and rollback strategies.
- [ ] PRD states dependency assumptions, macOS considerations, and Arch considerations.
- [ ] PRD lists explicit safety and privacy requirements, including no auto-install and no Zinit auto-clone from startup.
- [ ] PRD confirms Oh My Posh activation stays explicit and guarded.
- [ ] No file in `$HOME` is modified; no `~/.zshrc` inspection beyond user-provided context.
- [ ] No symlinks created; no Stow run against real `$HOME`; no dependencies installed.
- [ ] PRD does not proceed to architecture.
- [ ] PRD reviewed and approved before architecture work begins.

---

## Out of Scope

- Implementing the include block, `index.zsh`, loader, or any migration script.
- Writing final managed fragment contents (history, completions, aliases, tool integrations, prompt).
- Choosing final file structure/layout (Architecture document).
- Inspecting, copying, or editing the user's real `~/.zshrc`.
- Creating symlinks, running Stow against real `$HOME`, or changing the login shell.
- Installing or cloning any tool, including Zinit and Oh My Posh.
- Non-zsh shells, terminal emulators, and font installation.
