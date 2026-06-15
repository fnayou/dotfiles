# Plan: Initial Repository Scaffold

**Number:** 0001
**Date:** 2026-06-15
**Status:** Approved
**Architecture:** docs/architecture/0001-dotfiles-repository-architecture.md

---

## Objective

Create the foundational repository structure — directories, a Taskfile stub, .gitignore, OS detection script, and git config example files — without modifying the home directory or stowing anything.

---

## Assumptions

- Architecture document `0001-dotfiles-repository-architecture.md` is approved.
- ADRs 0001–0007 are written and accepted.
- No existing `stow/`, `packages/`, or `scripts/` directories exist yet.
- No home directory modifications will occur during this plan.
- Builder does not run `stow`, `rm`, `mv`, or `ln -s` against `$HOME`.

---

## Ordered Tasks

1. Create `.gitignore` at repository root covering secrets, local overrides, SSH keys, and common junk files.
2. Create `Taskfile.yml` stub at repository root with stow dry-run, install, uninstall, check, and lint:secrets tasks. Tasks must not auto-execute against `$HOME`.
3. Create directory structure under `stow/`:
   - `stow/common/git/`
   - `stow/common/zsh/` (empty — future)
   - `stow/common/nvim/` (empty — future)
   - `stow/macos/zsh/` (empty — future)
   - `stow/arch/zsh/` (empty — future)
4. Create directory structure under `packages/`:
   - `packages/macos/` (empty — future Brewfiles)
5. Create directory structure under `scripts/`:
   - `scripts/macos/`
   - `scripts/arch/`
6. Create `scripts/detect-os.sh` — prints `macos` or `arch`, exits 1 on unknown OS. Informational only.
7. Create `stow/common/git/.gitconfig.example` — placeholder values for name, email, signing key, core settings.
8. Create `stow/common/git/.gitignore_global.example` — safe global gitignore patterns.

---

## Files Affected

- `.gitignore` — created
- `Taskfile.yml` — created
- `stow/common/git/.gitconfig.example` — created
- `stow/common/git/.gitignore_global.example` — created
- `scripts/detect-os.sh` — created
- `stow/common/git/` — directory created
- `stow/common/zsh/` — directory created (empty)
- `stow/common/nvim/` — directory created (empty)
- `stow/macos/zsh/` — directory created (empty)
- `stow/arch/zsh/` — directory created (empty)
- `packages/macos/` — directory created (empty)
- `scripts/macos/` — directory created (empty)
- `scripts/arch/` — directory created (empty)

---

## Safety Checks

- Verify no file is created outside the repository root.
- Verify `.gitconfig.example` contains only placeholder values — no real name, email, or signing key.
- Verify `Taskfile.yml` tasks do not auto-execute `stow` — all stow tasks require explicit invocation with PLATFORM and PACKAGE variables.
- Verify `scripts/detect-os.sh` does not modify any file or directory.
- Verify no `stow` command is run during this plan.
- Verify no `rm`, `mv`, or `ln -s` is run against `$HOME`.

---

## Validation Commands

```bash
# Verify structure created correctly
git status

# Verify no secrets in staged files
git diff --staged

# Verify detect-os.sh is safe to read
cat scripts/detect-os.sh

# Verify gitconfig example uses placeholder values only
cat stow/common/git/.gitconfig.example

# Verify Taskfile syntax
task --list
```

---

## Rollback Strategy

All changes are new files within the repository. Rollback is a clean git reset:

```bash
# Remove all untracked files added during this plan
git clean -n          # dry run — review what would be removed
git clean -f -d       # remove untracked files and directories
```

⚠️  MANUAL STEP — review `git clean -n` output before running `git clean -f -d`.

No home directory changes are made, so no $HOME rollback is needed.

---

## Completion Criteria

- [ ] `.gitignore` exists at repository root and covers secrets, SSH keys, local overrides.
- [ ] `Taskfile.yml` exists and `task --list` shows all tasks without error.
- [ ] `stow/common/git/.gitconfig.example` exists with placeholder values only.
- [ ] `stow/common/git/.gitignore_global.example` exists with safe patterns.
- [ ] `scripts/detect-os.sh` exists and prints `macos` on macOS, `arch` on Arch, exits 1 on unknown.
- [ ] All empty stow and packages directories exist.
- [ ] `git status` shows only the expected new files — no unintended changes.
- [ ] Reviewer has approved this plan's output before any commit.
- [ ] No home directory was modified.
