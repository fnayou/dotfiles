# Plan: Implement Dotfiles Foundation

**Number:** 0005
**Status:** Complete
**Date:** 2026-06-15
**PRD:** [0002-dotfiles-foundation](../prd/0002-dotfiles-foundation.md)
**Architecture:** [0002-dotfiles-foundation-architecture](../architecture/0002-dotfiles-foundation-architecture.md)
**Review:** [0003-dotfiles-foundation-prd-architecture-review](../reviews/0003-dotfiles-foundation-prd-architecture-review.md)

> **Note on numbering:** Plans 0001–0004 exist. This plan is 0005.
> The requested filename `0003-implement-dotfiles-foundation.md` conflicts with existing `0003-add-initial-prd.md`.

> **Correction (2026-06-15):** The original single-variable design (`PACKAGE=common/git`) was invalid.
> GNU Stow does not permit slashes in package names — `stow --dir=stow --simulate common/git` exits with error.
> Corrected interface: `task dry-run AREA=common PACKAGE=git` → `stow --dir=stow/common --target="$HOME" --simulate git`.
> ADR-0011 superseded by ADR-0012. Taskfile, stow-usage.md, and this plan updated accordingly.
> Validation commands in this plan that reference the old form are superseded by: `task dry-run AREA=common PACKAGE=git`.

---

## Objective

Create the minimal dotfiles foundation: ADRs, helper scripts, Taskfile, Stow directory structure with placeholder files, and Stow usage documentation — with no home directory modifications.

---

## Assumptions

- Repository is on branch `docs/add-pre-commit-review` or a new implementation branch.
- No stow package has ever been installed on this machine from this repository.
- `git`, `bash`, and `stow` are installed on the dev machine.
- `go-task` (`task`) is installed — required to validate Taskfile tasks.
- PRD 0002 and Architecture 0002 have been reviewed (review 0003). B1–B3 are resolved in the source documents.
- ADRs 0009, 0010, 0011 do not yet exist (confirmed: `docs/decisions/` contains 0001–0008 only).
- `docs/plans/0005` is the correct next number (0001–0004 exist).

---

## Implementation Constraints

Captured from review 0003:

| Constraint | Source | Rule |
|------------|--------|------|
| `check.sh` must not use `set -e` | Review B1 | Use explicit `if/else` per check; exit with `${FAILED:-0}` |
| `task list` strips `stow/` prefix | Review B2 | `find stow ... \| sed 's\|^stow/\|\|'` |
| `task dry-run` forbids mutating stow | Review B3 | `--simulate` hardcoded; no install variant |
| ADRs 0009–0011 written first | Review N1 | Before any implementation files are committed |
| `.gitconfig.example` covers `[user]` and `[core]` only | Review N3 | No `[user] signingkey`; no signing section |
| `docs/stow-usage.md` warns on `.gitkeep` packages | Review N4 | `stow/macos/` and `stow/arch/` are dir markers, not stowable packages |

---

## Ordered Tasks

### Phase 1 — Write ADRs (before any implementation files)

#### Task 1 — Write ADR-0009: Foundation Taskfile excludes install/mutating tasks

Create `docs/decisions/0009-foundation-taskfile-no-install-tasks.md`.

Content: record that the foundation-phase `Taskfile.yml` contains only read-only and `--simulate` tasks (`detect`, `check`, `list`, `dry-run`). Install/mutating tasks (`stow:install`, `stow:uninstall`) are explicitly absent. Adding them in a future phase requires a new PRD that lifts this restriction. Reference Architecture 0002 Decision 1.

**Validation:**
```bash
ls docs/decisions/0009-foundation-taskfile-no-install-tasks.md
```

---

#### Task 2 — Write ADR-0010: `packages/` directory deferred until Brewfile scope approved

Create `docs/decisions/0010-packages-dir-deferred.md`.

Content: record that `packages/macos/` (Brewfiles) is not created in the foundation phase. Creating it before a Brewfile PRD invites accidental commits of real Brewfile content. The directory is created only when the Brewfile scope is approved. Reference Architecture 0002 Decision 2.

**Validation:**
```bash
ls docs/decisions/0010-packages-dir-deferred.md
```

---

#### Task 3 — Write ADR-0011: `task dry-run` accepts single `PACKAGE=<platform>/<name>` argument

Create `docs/decisions/0011-task-dry-run-single-package-var.md`.

Content: record that `task dry-run` uses a single `PACKAGE=<platform>/<name>` variable (e.g., `PACKAGE=common/git`), not two separate `PLATFORM` and `PACKAGE` variables. The single-var form forces the user to specify the exact stow path; `task list` output matches this format directly (after stripping `stow/` prefix). Reference Architecture 0002 Decision 3.

**Validation:**
```bash
ls docs/decisions/0011-task-dry-run-single-package-var.md
```

---

### Phase 2 — Scripts

#### Task 4 — Create `scripts/detect-os.sh`

Create `scripts/detect-os.sh`. Must be executable (`chmod +x`).

Required content:
- Shebang: `#!/usr/bin/env bash`
- Leading usage comment: `# Usage: bash scripts/detect-os.sh — prints "macos" or "arch"; exits 1 on unsupported OS`
- `set -euo pipefail`
- OS detection block:
  ```bash
  if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "macos"
  elif [[ -f /etc/arch-release ]]; then
    echo "arch"
  else
    echo "unsupported: $OSTYPE" >&2
    exit 1
  fi
  ```
- No other logic. No side effects.
- **Future scope only:** generic Linux / Docker container support (e.g., detecting `ubuntu` or `debian`) is not in scope for this phase. If Docker testing is added in a future PRD, extend `detect-os.sh` at that time with its own ADR.

**Validation:**
```bash
bash -n scripts/detect-os.sh          # syntax check — must exit 0
bash scripts/detect-os.sh             # must print "macos" on dev machine
ls -la scripts/detect-os.sh           # must show executable bit (x)
```

---

#### Task 5 — Create `scripts/check.sh`

Create `scripts/check.sh`. Must be executable (`chmod +x`).

Required content:
- Shebang: `#!/usr/bin/env bash`
- Leading usage comment: `# Usage: bash scripts/check.sh — prints PASS/FAIL for each required tool; exits 1 if any fail`
- `set -uo pipefail` — **no `set -e`** (review B1: early exit prevents printing all results)
- Tool checks via explicit `if/else` with a `FAILED` accumulator:
  ```bash
  FAILED=0

  if command -v stow >/dev/null 2>&1; then
    echo "PASS: stow"
  else
    echo "FAIL: stow (not installed)"
    FAILED=1
  fi

  if command -v git >/dev/null 2>&1; then
    echo "PASS: git"
  else
    echo "FAIL: git (not installed)"
    FAILED=1
  fi

  if command -v task >/dev/null 2>&1; then
    echo "PASS: task"
  else
    echo "FAIL: task (not installed)"
    FAILED=1
  fi

  exit "${FAILED}"
  ```
- No other logic. No side effects.

**Validation:**
```bash
bash -n scripts/check.sh              # syntax check — must exit 0
bash scripts/check.sh                 # must print PASS for stow, git, task on dev machine
ls -la scripts/check.sh              # must show executable bit (x)
```

---

### Phase 3 — Taskfile

#### Task 6 — Create `Taskfile.yml`

Create `Taskfile.yml` at repository root.

Required content (exact task set — no additions):

```yaml
version: "3"

tasks:
  detect:
    desc: "Print detected OS (macos or arch)"
    cmds:
      - bash scripts/detect-os.sh

  check:
    desc: "Verify prerequisites (stow, git, task) are installed"
    cmds:
      - bash scripts/check.sh

  list:
    desc: "List Stow packages available under stow/ (output is ready for use with dry-run)"
    cmds:
      - find stow -mindepth 2 -maxdepth 2 -type d -print | sed 's|^stow/||'

  dry-run:
    desc: "Dry-run a Stow package — usage: task dry-run PACKAGE=<platform>/<name>"
    preconditions:
      - sh: '[ -n "{{.PACKAGE}}" ]'
        msg: "PACKAGE is required, e.g. PACKAGE=common/git"
    cmds:
      - stow --dir=stow --target="$HOME" --simulate {{.PACKAGE}}
```

No other tasks. No `install`, `uninstall`, `adopt`, or any task mutating `$HOME`.

**Validation:**
```bash
task --list                           # must show exactly: check, detect, dry-run, list
task detect                           # must print "macos" on dev machine
task check                            # must print PASS for stow, git, task
task list                             # must print "common/git" (after stow/ dir exists)
grep -E "^[[:space:]]{2}(install|uninstall|adopt|unlink):" Taskfile.yml
# must return empty — checks task name keys only, not description text
```

---

### Phase 4 — Stow directory structure

#### Task 7 — Create `stow/` directory skeleton

Create directories:
- `stow/common/git/`
- `stow/macos/`
- `stow/arch/`

Git tracks files, not empty directories. `stow/common/git/` will get a file in task 8. `stow/macos/` and `stow/arch/` get `.gitkeep` markers in task 9.

**Validation:**
```bash
find stow -type d | sort
# Expected output:
# stow
# stow/arch
# stow/common
# stow/common/git
# stow/macos
```

---

#### Task 8 — Create `stow/common/git/.gitconfig.example`

Create `stow/common/git/.gitconfig.example`.

Required content — `[user]` and `[core]` sections only. No signing key. No real identity:

```ini
# Example only. Do not stow directly.
# Use this as a reference when creating a future managed Git config.
# Keep real identity, email, signing keys, and work settings out of this repository.

[user]
	name = Your Name
	email = your-email@example.com

[core]
	editor = vim
	autocrlf = input
	# Create ~/.gitignore_global before enabling this line.
	excludesfile = ~/.gitignore_global
```

No other sections. No `[user] signingkey`. No `[gpg]`. No `[includeIf]` (future scope).

**Validation:**
```bash
cat stow/common/git/.gitconfig.example
grep -i "fnayou\|aymen\|real-email\|signingkey\|BEGIN" stow/common/git/.gitconfig.example
# grep must return empty — no real identity, no keys
```

---

#### Task 9 — Create `.gitkeep` markers for empty platform directories

Create:
- `stow/macos/.gitkeep` — empty file
- `stow/arch/.gitkeep` — empty file

These are git markers only. They are **not stowable packages**. `task dry-run PACKAGE=macos` and `task dry-run PACKAGE=arch` must not be used — documented in task 10.

**Validation:**
```bash
ls stow/macos/.gitkeep stow/arch/.gitkeep
find stow -name ".gitkeep"            # must show both files
```

---

### Phase 5 — Documentation

#### Task 10 — Create `docs/stow-usage.md`

Create `docs/stow-usage.md`.

Required sections (in order):

1. **Purpose** — Stow with package-based layout; why this repository uses it.
2. **Layout** — platform directories (`common/`, `macos/`, `arch/`) and what belongs in each.
3. **Dry-run a package** — copy-pasteable command; explain `task list` → `task dry-run` workflow.
4. **Install a package** (manual step):

   ```
   ⚠️  MANUAL STEP — review dry-run output before running
   ```

   ```bash
   stow --dir=stow --target="$HOME" <platform>/<package>
   ```

5. **Conflict handling** — stop on any conflict; never use `--adopt`; resolve manually.
6. **Platform directories are not packages** — warn that `stow/macos/` and `stow/arch/` contain only `.gitkeep` markers. Do not run `task dry-run PACKAGE=macos` or `task dry-run PACKAGE=arch`.
7. **Adding a new package** — three-step process: create directory under correct platform, add config files, dry-run before stowing. Reference ADR-0001 for common-package criteria.
8. **Forbidden** — `stow .`, `stow --adopt`, and running stow without dry-run first.

All install examples must be preceded by the `⚠️  MANUAL STEP` marker. All copy-pasteable commands must be correct and safe by default.

**Validation:**
```bash
ls docs/stow-usage.md
grep "MANUAL STEP" docs/stow-usage.md      # must match at least once
grep "\-\-adopt" docs/stow-usage.md        # must appear only in "forbidden" context
grep "\-\-simulate" docs/stow-usage.md     # must appear in dry-run examples
```

---

#### Task 11 — Update `README.md` with stow-usage link

Add a link to `docs/stow-usage.md` in the existing `README.md`. Add it under a "Documentation" or "Usage" section if one exists; otherwise add a short section.

Do not restructure or rewrite the README. Minimal addition only.

**Validation:**
```bash
grep "stow-usage" README.md           # must match
git diff README.md                    # review — must be a minimal addition only
```

---

### Phase 6 — Mark documents Approved and pre-commit audit

#### Task 12 — Mark PRD 0002 status Approved

Edit `docs/prd/0002-dotfiles-foundation.md`:

Change:
```
**Status:** Draft
```
To:
```
**Status:** Approved
```

**Validation:**
```bash
grep "Status" docs/prd/0002-dotfiles-foundation.md
# Must show: **Status:** Approved
```

---

#### Task 13 — Mark Architecture 0002 status Approved

Edit `docs/architecture/0002-dotfiles-foundation-architecture.md`:

Change:
```
**Status:** Draft
```
To:
```
**Status:** Approved
```

**Validation:**
```bash
grep "Status" docs/architecture/0002-dotfiles-foundation-architecture.md
# Must show: **Status:** Approved
```

---

#### Task 14 — Pre-commit safety and privacy audit

Run the full pre-commit checklist before staging:

Run before `git add` (unstaged):

```bash
# 1. Confirm no file outside the repo was modified
git status

# 2. Inspect all new and modified files (unstaged)
git diff

# 3. Verify no real identity in .gitconfig.example
grep -ri "fnayou\|aymen\|BEGIN\|signingkey\|password\|token\|secret" stow/

# 4. Confirm no install task in Taskfile (checks task name keys only)
grep -E "^[[:space:]]{2}(install|uninstall|adopt|unlink):" Taskfile.yml
# must return empty

# 5. Confirm no stow command without --simulate in scripts
grep -n "stow " scripts/*.sh | grep -v simulate || echo "OK: no bare stow in scripts"

# 6. Confirm scripts are executable
ls -la scripts/detect-os.sh scripts/check.sh

# 7. Run check.sh one final time
bash scripts/check.sh
```

All pre-staging checks must pass. If any fail, stop and fix before proceeding.

After `git add` (staged), verify staged content:

```bash
git diff --staged
```

Review the staged diff carefully before committing. If anything unexpected appears, unstage and fix.

**Validation:** All grep commands above return expected results (empty or "OK").

---

#### Task 15 — Commit

Stage only the files created or modified by this plan:

```bash
git add \
  docs/decisions/0009-foundation-taskfile-no-install-tasks.md \
  docs/decisions/0010-packages-dir-deferred.md \
  docs/decisions/0011-task-dry-run-single-package-var.md \
  scripts/detect-os.sh \
  scripts/check.sh \
  Taskfile.yml \
  stow/common/git/.gitconfig.example \
  stow/macos/.gitkeep \
  stow/arch/.gitkeep \
  docs/stow-usage.md \
  README.md \
  docs/prd/0002-dotfiles-foundation.md \
  docs/architecture/0002-dotfiles-foundation-architecture.md \
  docs/plans/0005-implement-dotfiles-foundation.md
```

Commit message format (per AGENTS.md §13):

```
feat(stow): add dotfiles foundation — scripts, Taskfile, placeholder packages

- Add scripts/detect-os.sh and scripts/check.sh (read-only, no side effects)
- Add Taskfile.yml with detect, check, list, dry-run tasks only
- Add stow/ layout: common/git/.gitconfig.example, macos/.gitkeep, arch/.gitkeep
- Add docs/stow-usage.md with dry-run-first workflow and conflict guidance
- Write ADRs 0009–0011 for foundation decisions
- Mark PRD 0002 and Architecture 0002 as Approved
```

**Validation:**
```bash
git log --oneline -3                  # confirm commit landed
git show --stat HEAD                  # confirm expected files only
```

---

## Files Affected

| File | Action |
|------|--------|
| `docs/decisions/0009-foundation-taskfile-no-install-tasks.md` | created |
| `docs/decisions/0010-packages-dir-deferred.md` | created |
| `docs/decisions/0011-task-dry-run-single-package-var.md` | created |
| `scripts/detect-os.sh` | created |
| `scripts/check.sh` | created |
| `Taskfile.yml` | created |
| `stow/common/git/.gitconfig.example` | created |
| `stow/macos/.gitkeep` | created |
| `stow/arch/.gitkeep` | created |
| `docs/stow-usage.md` | created |
| `README.md` | modified (link added) |
| `docs/prd/0002-dotfiles-foundation.md` | modified (status: Approved) |
| `docs/architecture/0002-dotfiles-foundation-architecture.md` | modified (status: Approved) |
| `docs/plans/0005-implement-dotfiles-foundation.md` | created (this file) |

**Files that must not be created or modified:**
- Anything under `$HOME`
- Any real dotfile (`~/.gitconfig`, `~/.zshrc`, `~/.ssh/config`, etc.)
- `packages/macos/` (deferred — ADR-0010)
- `test/` (deferred — future Docker PRD)
- `stow/common/zsh/`, `stow/macos/zsh/`, `stow/arch/zsh/` (zsh deferred)
- `stow/common/git/.gitignore_global.example` (deferred — git package PRD)

---

## Safety Checks

Before starting:
- `git status` must be clean (no uncommitted changes) or all changes understood.
- Confirm branch is not `main` — use a feature branch.
- Confirm working directory is the repository root: `pwd` and `git status`.

During execution:
- After each task, run `git status` — only expected new files should appear.
- After task 8: grep `.gitconfig.example` for real identity before proceeding.
- After task 6: `grep -E "^[[:space:]]{2}(install|uninstall|adopt|unlink):" Taskfile.yml` must return empty.
- Never run `stow` without `--simulate` at any point in this plan.
- Never run `rm`, `mv`, or `ln -s` against any path under `$HOME`.

Before staging (task 14):
- Full pre-commit checklist as specified in task 14.

---

## Validation Commands

Full end-to-end verification after task 15:

```bash
# Structure
find stow -type f | sort
# Expected:
# stow/arch/.gitkeep
# stow/common/git/.gitconfig.example
# stow/macos/.gitkeep

# Scripts
bash -n scripts/detect-os.sh && echo "syntax OK"
bash -n scripts/check.sh && echo "syntax OK"
bash scripts/detect-os.sh             # must print "macos"
bash scripts/check.sh                 # must print PASS x3

# Taskfile
task --list                           # must list exactly: check, detect, dry-run, list
task detect                           # must print "macos"
task check                            # must print PASS x3
task list                             # must print "common/git"
task dry-run PACKAGE=common/git       # must print stow dry-run output (no actual links)

# Privacy
grep -ri "fnayou\|aymen\|BEGIN\|password\|token\|secret" stow/
# must return empty

# No install task (checks task name keys only — not description text)
grep -E "^[[:space:]]{2}(install|uninstall|adopt|unlink):" Taskfile.yml
# must return empty

# Docs
grep "MANUAL STEP" docs/stow-usage.md
grep "stow-usage" README.md

# Git
git show --stat HEAD                  # must show only plan files
git log --oneline -5
```

---

## Rollback Strategy

All changes are local file creations and minor edits within the repository. Rollback options:

**Before commit (any task):**
```bash
# Remove a specific new file
git clean -n                          # preview what would be removed
git checkout -- README.md             # undo README edit
git checkout -- docs/prd/0002-dotfiles-foundation.md   # undo status change
```

**After commit, before push:**
```bash
git reset HEAD~1                      # unstage last commit, keep files
# then fix and re-commit
```

**After push (if applicable):**
- Revert the commit via PR or `git revert HEAD`.
- All files in this plan are within the repository — no `$HOME` changes to reverse.

No symlinks, no `$HOME` modifications, no package installs: rollback is always git-only.

---

## Completion Criteria

From PRD 0002 acceptance criteria, verified:

- [ ] `stow/` exists with `common/git/`, `macos/`, `arch/` subdirectories.
- [ ] `stow/common/git/.gitconfig.example` exists with placeholder values only (`Your Name`, `your-email@example.com`).
- [ ] `stow/macos/.gitkeep` exists.
- [ ] `stow/arch/.gitkeep` exists.
- [ ] `scripts/detect-os.sh` is executable and prints `macos` on macOS dev machine.
- [ ] `scripts/check.sh` is executable, prints PASS/FAIL for all three tools, and exits 0 when all present.
- [ ] `Taskfile.yml` has exactly `check`, `detect`, `list`, `dry-run` — no `install` task.
- [ ] `task dry-run PACKAGE=common/git` runs `stow --simulate` only.
- [ ] `task list` output is in `<platform>/<name>` form (no `stow/` prefix).
- [ ] `docs/stow-usage.md` exists with dry-run workflow, install as manual step, conflict guidance, and `.gitkeep` warning.
- [ ] All install examples in `docs/stow-usage.md` are preceded by `⚠️  MANUAL STEP`.
- [ ] `README.md` links to `docs/stow-usage.md`.
- [ ] ADRs 0009, 0010, 0011 exist under `docs/decisions/`.
- [ ] PRD 0002 status is `Approved`.
- [ ] Architecture 0002 status is `Approved`.
- [ ] No file outside the repository root was created or modified.
- [ ] No stow install operation was run. No new symlinks created in `$HOME`.
- [ ] No real credentials, tokens, or private data in any committed file.
- [ ] Pre-commit audit (task 14) passed with zero findings.
