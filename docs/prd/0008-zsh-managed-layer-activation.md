# PRD: Zsh Managed-Layer Activation

**Number:** 0008
**Status:** Approved
**Date:** 2026-06-18
**Platform:** Common (macOS + Arch/EndeavourOS)
**Related:** PRD 0004 (zsh configuration), PRD 0007 (zsh activation migration), Review 0024 (manual migration validation)

## Problem Statement

The common zsh package is stowed and `~/.zshrc` is wired, but the managed layer is **inert**. Validation 0024 confirmed:

- `~/.config/zsh` is stowed as a **directory fold** — one directory symlink → `stow/common/zsh/.config/zsh`, not per-file symlinks.
- `~/.zshrc` exists as a **user-managed regular file** (not a symlink) and **contains the guarded include block**:
  `[[ -r "$HOME/.config/zsh/index.zsh" ]] && source "$HOME/.config/zsh/index.zsh"`.
- Only `*.example` templates exist in the package. The real `index.zsh` (and `shared.zsh`, platform files, `omp.zsh`, `local.zsh`) were **never created**.
- Therefore the include block's guard evaluates false → **no-op**. Nothing managed loads.

Safety and privacy passed. Two gaps remain:

1. **Functional (not a defect):** real managed files do not exist, so the layer cannot activate.
2. **Strategy drift:** Stow folded the directory. With folding, `~/.config/zsh` **is** the repo package dir — any non-managed file dropped there lands inside the repo tree, and there is no `local.zsh` boundary between managed (versioned) and private (unversioned) content.

This PRD switches the intended strategy to **`--no-folding`** (explicit per-file symlinks), keeps **local/private files as real files outside the repo**, and defines how to **migrate from the current folded state** and **activate the layer safely**. It implements nothing.

## Goals

- Select **`--no-folding`** as the intended stow behavior for zsh packages; folding is explicitly not intended.
- Make managed zsh files **explicit per-file symlinks** under `~/.config/zsh/` (e.g. `index.zsh`, `shared.zsh` → repo).
- Keep **local/private files (`local.zsh`) as real files outside the repository**, git-ignored, never symlinked into the repo.
- Define a safe, reviewable, reversible path to activate the managed layer.
- Define the **example-to-real-file** strategy (which `.example` become real, when, by whom).
- Define a safe **migration from the current folded state** to per-file symlinks (documented, not executed).
- Define validation that proves activation without dumping `$HOME` content, and a one-step rollback.
- Preserve the fail-safe guard: a partially-adopted machine still starts a clean shell.

## Non-Goals

- Implementing activation, copying any `.example` → real file, running Stow, or creating symlinks. (Later plan.)
- Modifying `~/.zshrc` or any `$HOME` file in this PRD or any agent action.
- Keeping directory folding — explicitly rejected here.
- Adding new managed shell features, aliases, plugins, or prompt config beyond PRD 0004 / 0005.
- Installing or bootstrapping dependencies (fzf, zoxide, eza, zinit, Oh My Posh) — they stay guarded/opt-in.
- Changing the `~/.zshrc` wiring model (user-managed regular file + guarded include block) — confirmed working.
- `$ZDOTDIR` redirection — interactive config stays in `~/.zshrc`.

## User Stories

- As the dotfiles owner, I want managed files as explicit per-file symlinks so I can see exactly what is repo-managed vs local.
- As the dotfiles owner, I want `local.zsh` to stay a real file outside the repo so private/machine-specific values never enter version control.
- As the dotfiles owner, I want a documented `--no-folding` migration so the stow result matches the intended model.
- As a cautious user, I want migration and activation steps shown but never auto-run, with a one-step rollback.
- As a user on a fresh machine, I want activation that fails safe if I only copy some files.

## Scope

Affected paths (decisions only — no writes):

- `stow/common/zsh/.config/zsh/` — `*.example` templates; future **versioned** real files (`index.zsh`, `shared.zsh`, `macos.zsh`, `arch.zsh`, `omp.zsh`) that become per-file symlink sources. (Versioning decision deferred to plan/ADR; `.gitignore` currently excludes them.)
- `~/.config/zsh/` — currently a directory-fold symlink; target state is a **real directory** containing per-file symlinks for managed files plus a **real, unversioned `local.zsh`**.
- `~/.zshrc` — user-managed regular file with the guarded include block. **Read/decision only; never modified.**
- Documentation: this PRD, plus future updates to `docs/stow-usage.md` / `docs/zsh-migration.md` and an ADR recording the `--no-folding` decision (later plan, not here).

## Safety Requirements

- Must NOT modify `~/.zshrc`.
- Must NOT modify, create, move, or delete any file under `$HOME` as part of this PRD.
- Must NOT run Stow (no install, no `--restow`, no `--delete`, no `--no-folding` execution).
- Must NOT create or overwrite symlinks.
- Must NOT use `stow --adopt` ever — it overwrites existing files.
- Must NOT install dependencies.
- Migration and activation, when later implemented, MUST be **manual user steps** — no script, bootstrap, or shell init may auto-copy, auto-stow, or auto-create symlinks.
- Migration MUST `--simulate` (dry-run) before any real `--delete` / `--no-folding` stow; output reviewed before executing.
- Every managed source MUST stay guarded (`[[ -r … ]] && source …`) so partial adoption still starts a clean shell.
- All risky commands in the future plan MUST carry the `⚠️  MANUAL STEP` marker.

## Privacy Requirements

- No `$HOME` file content (especially `~/.zshrc`, `local.zsh`) may be copied into the repo or quoted in docs/reviews. Use delimiter counts / keyword greps only, as Review 0024 did.
- **`local.zsh` is a real file outside the repo** — git-ignored, never symlinked from the repo, sole home for machine-specific or sensitive values.
- All `.example` templates and any versioned managed files use placeholder values only — no secrets, no private hosts/IPs/tokens.
- Validation output must not dump file bodies — presence/resolution/load-marker checks only.

## Activation Strategy

Decision: **user-driven, per-file-symlink activation under a `--no-folding` stow.** The include block in `~/.zshrc` (confirmed present) is the trigger and stays as-is.

Activation contract (executed manually by the user; defined in a later plan):

1. Migrate the stow from folded to `--no-folding` (see Migration section) so `~/.config/zsh` is a real directory of per-file symlinks.
2. Copy `index.zsh.example` → versioned `index.zsh` (minimum to activate), plus desired layer files (`shared.zsh`, platform file, `omp.zsh`). Each becomes a per-file symlink into the repo on re-stow.
3. Create `local.zsh` directly in `~/.config/zsh/` as a **real, unversioned** file for private/machine-specific overrides — not from the repo.
4. On next interactive shell, the `~/.zshrc` guard passes → `index.zsh` sources present layer files in order; absent files stay no-ops; `local.zsh` sources last and wins.

Rationale: per-file symlinks make repo-managed vs local explicit, keep private content out of the repo via a real `local.zsh`, and preserve the shipped guarded design.

## Example-to-Real-File Strategy

- `.example` files are **never stowed or sourced directly**; the user copies each to its real name before it can load.
- **Two classes of real file:**
  - **Versioned, symlinked (managed):** `index.zsh`, `shared.zsh`, `macos.zsh`, `arch.zsh`, `omp.zsh` — copied from `.example` into the repo package dir, then linked per-file by `--no-folding` stow.
  - **Unversioned, real, outside repo (private):** `local.zsh` — created directly under `~/.config/zsh/`, git-ignored, never symlinked.
- **Minimum to activate:** `index.zsh` (source-order owner). With only `index.zsh`, all layer sources are guarded no-ops → clean shell.
- **Recommended layers, in source order:** `shared.zsh` → `macos.zsh`/`arch.zsh` (OS-detected, only matching one loads) → `omp.zsh` (opt-in prompt, guarded) → `local.zsh` (last, wins).
- Copy direction is one-way (`.example` → real); the `.example` stays as reference.
- No agent performs any copy or symlink.

## `--no-folding` Strategy

**Decision: `--no-folding` is the intended stow behavior for zsh packages. Folding is not intended.**

- Intended command shape (later plan, not executed here):
  ```
  ⚠️  MANUAL STEP — review dry-run output before running
  stow --dir=stow/common --target="$HOME" --no-folding --restow zsh
  ```
- Result: `~/.config/zsh` is a **real directory**; each managed file is its **own symlink** into the repo (`~/.config/zsh/index.zsh → …/stow/common/zsh/.config/zsh/index.zsh`).
- Benefits: explicit per-file visibility of what is repo-managed; a real `~/.config/zsh` directory can hold the **real, unversioned `local.zsh`** alongside symlinks without that file living in the repo; dropping a non-managed file into `~/.config/zsh` no longer writes into the repo tree.
- Trade-off: each new managed file needs a re-stow to create its link (acceptable; explicit by design).

## Migration From Current Folded State

Current state acknowledged: `~/.config/zsh` is a single directory symlink → repo package dir (folded). Target: real directory + per-file symlinks + real `local.zsh`.

Documented manual steps (NOT executed in this PRD):

1. **Dry-run delete** the folded link:
   ```
   ⚠️  MANUAL STEP — review before running
   stow --dir=stow/common --target="$HOME" --simulate --delete zsh
   ```
2. **Delete** the fold (removes only the `~/.config/zsh` directory symlink; `~/.zshrc` untouched):
   ```
   ⚠️  MANUAL STEP — review dry-run output first
   stow --dir=stow/common --target="$HOME" --delete zsh
   ```
3. **Dry-run** the `--no-folding` restow, then execute:
   ```
   ⚠️  MANUAL STEP — review before running
   stow --dir=stow/common --target="$HOME" --no-folding --simulate zsh
   stow --dir=stow/common --target="$HOME" --no-folding zsh
   ```
4. **Create `local.zsh`** as a real file directly in `~/.config/zsh/` (not from repo); keep private values here.
5. **Conflict handling:** if dry-run reports a conflict, STOP and resolve manually. Never `--adopt`.

## Validation Strategy

All checks read-only; no `$HOME` content dumped (mirrors Review 0024).

- **Pre-migration:** confirm `~/.config/zsh` is the folded directory symlink; `~/.zshrc` contains the guarded block (delimiter count only); `$ZDOTDIR` unset.
- **Post-migration form:** confirm `~/.config/zsh` is a **real directory** and managed files are **per-file symlinks** resolving into the repo; confirm `local.zsh`, if present, is a **real file (not a symlink)**.
- **Real-file presence:** `index.zsh` required for activation; others optional — name/resolution only.
- **Guard fail-safe:** with no real files, `zsh -ic 'echo zsh-ok'` starts clean.
- **Activation success:** after `index.zsh` exists, an interactive shell loads the layer — prove via a load marker (sentinel echo / known alias), not a content dump.
- **Order check:** if `local.zsh` present, confirm it sources last (overrides win).
- **Safety re-check:** `git status` clean of unintended changes; `local.zsh` not tracked by git; no `--adopt`; no symlink overwrite; no dependency install at startup.

## Rollback Strategy

Returns to a clean, safe state; ordered, reversible, no data loss.

1. **Disable layer (one step):** comment/remove the delimited include block in `~/.zshrc`. Shell still starts clean.
2. **Unstow per-file links:**
   ```
   ⚠️  MANUAL STEP — review before running
   stow --dir=stow/common --target="$HOME" --delete zsh
   ```
3. **Remove copied managed files by name** (in repo dir) and the private file (outside repo) — never `rm -rf ~/.config/zsh`:
   `rm -f ~/.config/zsh/{index,shared,macos,arch,omp,local}.zsh` removes only the named files; `.example` templates remain.
4. **Re-fold (optional fallback):** if needed, re-stow without `--no-folding` to restore prior folded state.
5. **Verify:** `zsh --no-rcs -c 'echo ok'` and `ls -l ~/.config/zsh`.

All steps marked `⚠️  MANUAL STEP` in the future plan; none executed by an agent.

## Acceptance Criteria

- [ ] Zsh managed-layer activation strategy is documented (user-driven, per-file symlinks, guarded include block as trigger).
- [ ] `--no-folding` is selected as the intended stow behavior for zsh; folding is explicitly not intended.
- [ ] Managed zsh files are defined as explicit per-file symlinks under `~/.config/zsh/`.
- [ ] Current folded state is acknowledged.
- [ ] Safe migration steps (delete fold → `--no-folding` restow, with dry-runs) are documented but not executed.
- [ ] Real managed files required to activate are identified (`index.zsh` minimum; `shared`/platform/`omp` optional, in order).
- [ ] Local/private files (`local.zsh`) remain real files outside the repository, git-ignored, never symlinked.
- [ ] Example-to-real-file strategy distinguishes versioned/symlinked managed files from the unversioned real `local.zsh`.
- [ ] Validation proves post-migration link form + activation via load markers without dumping `$HOME` content.
- [ ] Rollback returns to a clean state in one disabling step plus named-file cleanup, with no data loss.
- [ ] No `~/.zshrc` change, no `$HOME` change, no Stow run, no symlink, no dependency install occurred while producing this PRD.

## Out of Scope

- Performing migration, activation, template copies, Stow runs, or symlink creation.
- Modifying `~/.zshrc` or any `$HOME` file.
- Keeping directory folding (rejected).
- `$ZDOTDIR` redirection or relocating interactive config out of `~/.zshrc`.
- Installing/bootstrapping fzf, zoxide, eza, zinit, or Oh My Posh.
- New managed shell features beyond PRD 0004 / 0005.
- Writing the implementation plan or `--no-folding` ADR (separate later documents referencing this PRD).
