# PRD: Dotfiles Repository Foundation

**Number:** 0002
**Status:** Approved
**Date:** 2026-06-15

---

## Problem Statement

The Claude Code operating layer is complete. The repository has no dotfiles content yet. Before any real configuration is introduced, the repository needs a safe, structured foundation: directory layout, placeholder packages, helper scripts, Taskfile, and Stow usage documentation.

This PRD defines the minimal foundation required before any real dotfiles are added.

---

## Goals

- Establish the `stow/` directory and package-based layout.
- Create placeholder packages for future dotfiles adoption.
- Create a Taskfile with safe, non-destructive commands only.
- Create helper scripts (`detect-os.sh`, `check.sh`) for cross-platform use.
- Document GNU Stow usage correctly for this repository.
- Ensure the foundation supports incremental, per-package adoption on both macOS and Arch.
- Keep the repository in a safe, committable state throughout.

---

## Non-Goals

- No real dotfiles are added in this phase.
- No home directory modifications.
- No symlinks created in `$HOME`.
- No Stow install commands executed.
- SSH config is out of scope (managed manually per host).
- Neovim configuration is out of scope (future phase).
- Git config implementation is out of scope; only `.example` templates are permitted.
- Secrets management tools (e.g., `pass`) are out of scope.
- Docker-based testing is out of scope (future option).
- Bootstrap or provisioning scripts are out of scope.
- No real zsh configuration — current macOS zsh setup must not be touched.

---

## User Stories

- As a user, I want a `stow/` directory structure so that I can adopt dotfiles one package at a time without disrupting my current setup.
- As a user, I want placeholder `.example` files so that I can see the intended structure without stowing anything real.
- As a user, I want a Taskfile with safe commands so that I can verify repository state and prepare for future stow operations.
- As a user, I want helper scripts so that I can detect my current OS and check repository prerequisites.
- As a user, I want Stow usage documentation so that I always know the correct, safe way to install a package when the time comes.

---

## Scope

### Repository structure

```
stow/
├── common/         # Configs that work on both macOS and Arch without modification
│   └── git/        # Git config (example files only)
├── macos/          # macOS-specific configs only
└── arch/           # Arch / EndeavourOS-specific configs only

scripts/
├── detect-os.sh    # Detect macOS vs Arch; print platform name
└── check.sh        # Verify repository prerequisites (stow installed, etc.)

Taskfile.yml        # Safe, non-destructive tasks only

docs/
└── stow-usage.md   # How to use Stow in this repository (dry-run first, etc.)
```

### Initial packages

| Package path         | Platform | Content             |
|----------------------|----------|---------------------|
| `stow/common/git/`   | Both     | `.gitconfig.example` |
| `stow/macos/`        | macOS    | Empty with `.gitkeep` |
| `stow/arch/`         | Arch     | Empty with `.gitkeep` |

All packages use `.example` files. No real config is stowed.

### Taskfile tasks (non-destructive only)

| Task           | Description                                          |
|----------------|------------------------------------------------------|
| `task check`   | Run `scripts/check.sh` — verify prerequisites        |
| `task detect`  | Run `scripts/detect-os.sh` — print detected OS       |
| `task list`    | List all Stow packages available in `stow/`           |
| `task dry-run` | Dry-run a named package (requires `PACKAGE=<name>`)   |

`task dry-run` must use `--simulate` and must not install anything.

`task install` must **not** exist in this phase. Stow install commands are manual-only.

### Scripts

**`scripts/detect-os.sh`**

- Detects macOS or Arch Linux.
- Prints the platform name to stdout.
- Exits with error on unsupported OS.
- No side effects.

**`scripts/check.sh`**

- Verifies `stow` is installed.
- Verifies `git` is installed.
- Verifies `task` (Taskfile runner) is installed.
- Prints pass/fail for each check.
- No side effects.

---

## Safety Requirements

- Must not delete any file in `$HOME`.
- Must not overwrite any file in `$HOME`.
- Must not create symlinks in `$HOME`.
- Must not run `stow` without `--simulate` in scripts, hooks, or Taskfile tasks. Stow install operations require explicit manual invocation by the user.
- Must not use `stow --adopt`.
- Must not run `rm`, `mv`, or `ln -s` against `$HOME`.
- `task dry-run` must use `--simulate` — never the real install.
- No Taskfile task may execute a destructive command.
- Scripts must be read-only inspection tools — no write operations.
- No file outside the repository root may be modified.

---

## Privacy Requirements

- No API keys, tokens, passwords, or SSH private key content committed.
- No private hostnames, internal IP addresses, or work-specific secrets.
- `.gitconfig.example` must use placeholder values only:
  - `Your Name`
  - `your-email@example.com`
  - `github-username`
- No real user data in any `.example` file.
- Audit `git diff --staged` before every commit.

---

## Cross-Platform Requirements

- `stow/common/` contains only config that works on both macOS and Arch without modification.
- `stow/macos/` is strictly for macOS-specific config.
- `stow/arch/` is strictly for Arch / EndeavourOS-specific config.
- `scripts/detect-os.sh` must detect both platforms correctly.
- `scripts/check.sh` must work on both platforms.
- Taskfile tasks must work on both platforms (or state platform restriction explicitly).
- Homebrew commands must not appear in Arch-facing documentation.
- pacman/yay commands must not appear in macOS-facing documentation.
- `docs/stow-usage.md` must specify platform context for any non-portable command.

---

## GNU Stow Requirements

- Package-based layout only — `stow .` is forbidden.
- All Stow commands use explicit flags:
  ```bash
  stow --dir=stow --target="$HOME" <package>
  ```
- Dry-run always precedes install:
  ```bash
  stow --dir=stow --target="$HOME" --simulate <package>
  ```
- `stow --adopt` must never be used in scripts, documentation examples, or Taskfile.
- Stow is never run automatically by any script, hook, or task.
- `docs/stow-usage.md` must document the above rules and include copy-pasteable examples.

---

## Documentation Requirements

- `docs/stow-usage.md` must be created covering:
  - How to dry-run a package.
  - How to install a package (manual step, marked with `⚠️ MANUAL STEP`).
  - How to add a new package.
  - Conflict handling guidance.
- All commands must be copy-pasteable and safe by default.
- Dangerous commands (install steps) must be marked:
  ```
  ⚠️  MANUAL STEP — review dry-run output before running
  ```
- Taskfile tasks must have `desc:` fields explaining what they do.
- Scripts must include a usage comment at the top.

---

## Initial Packages to Create

| Path                                       | Type     | Note                          |
|--------------------------------------------|----------|-------------------------------|
| `stow/common/git/.gitconfig.example`       | Template | Placeholder values only       |
| `stow/macos/.gitkeep`                      | Marker   | Empty package placeholder     |
| `stow/arch/.gitkeep`                       | Marker   | Empty package placeholder     |
| `scripts/detect-os.sh`                     | Script   | Read-only, no side effects    |
| `scripts/check.sh`                         | Script   | Read-only, no side effects    |
| `Taskfile.yml`                             | Taskfile | Non-destructive tasks only    |
| `docs/stow-usage.md`                       | Doc      | Stow usage and safety guide   |

---

## Out of Scope

- Real zsh configuration (current macOS setup must not be touched).
- SSH configuration (managed manually per host, not in this repository).
- Neovim configuration (future phase).
- Git config beyond `.example` template.
- Secrets management (`pass` or equivalent) — may be evaluated later.
- Docker-based testing environment.
- Bootstrap or provisioning scripts.
- Any `task install` command or automated Stow execution.
- Any file modifications outside the repository root.
- Any symlinks in `$HOME`.
- Homebrew bundle or `Brewfile`.

---

## Acceptance Criteria

- [ ] `stow/` directory exists with `common/git/`, `macos/`, and `arch/` subdirectories.
- [ ] `stow/common/git/.gitconfig.example` exists and contains only placeholder values.
- [ ] `stow/macos/.gitkeep` exists.
- [ ] `stow/arch/.gitkeep` exists.
- [ ] `scripts/detect-os.sh` exists, is executable, and prints `macos` or `arch` correctly.
- [ ] `scripts/check.sh` exists, is executable, and checks for `stow`, `git`, and `task`.
- [ ] `Taskfile.yml` exists with `check`, `detect`, `list`, and `dry-run` tasks.
- [ ] `task dry-run PACKAGE=<name>` runs `stow --simulate` only — never installs.
- [ ] No `task install` task exists.
- [ ] `docs/stow-usage.md` exists and documents dry-run, install (as manual step), and conflict handling.
- [ ] All install-step examples in `docs/stow-usage.md` are preceded by `⚠️ MANUAL STEP` marker.
- [ ] No file outside the repository root was created or modified.
- [ ] No symlinks exist in `$HOME`.
- [ ] No real credentials, tokens, or private data exist in any committed file.
- [ ] Reviewer approves: Safety PASS, Privacy PASS, Documentation PASS.

---

## Recommended Next Step

Architect reviews this PRD and produces an architecture proposal under `docs/architecture/`.
