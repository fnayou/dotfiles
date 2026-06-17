# Plan: Implement Git Configuration Stow Package

**Number:** 0006
**Status:** Complete
**Date:** 2026-06-17
**PRD:** [0003-git-package](../prd/0003-git-package.md)
**Architecture:** [0003-git-package-architecture](../architecture/0003-git-package-architecture.md)
**Review:** [0006-git-package-prd-architecture-review](../reviews/0006-git-package-prd-architecture-review.md)

---

## Objective

Produce the `stow/common/git/` package with safe, placeholder-only example files, wire the required `.gitignore` safety entries, write the three architecture-proposed ADRs, fix the architecture document's marker formatting, and deliver complete adoption documentation — without modifying any file outside the repository root and without running any Stow install command.

---

## Assumptions

- Repository is on a feature branch (not `main`).
- `git status` is clean or all uncommitted changes are understood.
- `git`, `stow`, and `task` (go-task) are installed on the dev machine.
- PRD 0003 and Architecture 0003 have been reviewed (review 0006, status: APPROVED WITH NOTES).
- Plans 0001–0005 exist; 0006 is the next available number.
- ADRs 0001–0012 exist; 0013 is the next available ADR number.
- `stow/common/git/.gitconfig.example` is the only file currently in `stow/common/git/`.
- The repository `.gitignore` does not yet contain entries for `.gitconfig.common` or `.gitignore_global`.
- `docs/stow-usage.md` exists and must be updated, not replaced.
- No `stow install` command will be run at any point in this plan.

---

## Pre-Implementation Checklist

Before creating any file, verify all of the following:

```bash
# 1. Confirm working directory is the repository root
pwd
git rev-parse --show-toplevel

# 2. Confirm current branch is not main
git branch --show-current

# 3. Confirm git status is clean (or all open changes are understood)
git status

# 4. Confirm ADRs 0001–0012 exist and 0013 does not yet exist
ls docs/decisions/
# Must show 0001–0012 and README.md; must NOT show 0013, 0014, 0015

# 5. Confirm plans 0001–0005 exist and 0006 does not yet exist
ls docs/plans/
# Must show 0001–0005 and README.md; must NOT show 0006

# 6. Confirm stow/common/git/ contains only .gitconfig.example
ls stow/common/git/
# Expected: .gitconfig.example only

# 7. Confirm .gitignore does not yet have .gitconfig.common or .gitignore_global entries
grep -n "gitconfig.common\|gitignore_global" .gitignore
# Must return empty

# 8. Confirm no forbidden values in existing .gitconfig.example
grep -i "signingkey\|gpg\|osxkeychain\|token\|password" stow/common/git/.gitconfig.example
# Must return empty
```

All eight checks must pass. Stop and resolve any failure before proceeding.

---

## Ordered Tasks

### Phase 1 — Fix Architecture Document (Pre-Requirement from Review 0006)

#### Task 1 — Fix marker placement in `docs/architecture/0003-git-package-architecture.md`

**Files affected:**
- `docs/architecture/0003-git-package-architecture.md` — modified

**What to do:**

Review 0006 identified three locations where the `⚠️  MANUAL STEP` marker is separated from its code fence by a blank line, violating `documentation.md` rule: "the marker must be on the line directly preceding the code block fence."

Locate and fix all three occurrences. In every case the correct form is:

```
⚠️  MANUAL STEP — review before running
```bash
stow --dir=stow/common --target="$HOME" git
```

No blank line between the marker and the fence.

**Validation:**
```bash
git diff docs/architecture/0003-git-package-architecture.md

grep -n "MANUAL STEP" docs/architecture/0003-git-package-architecture.md
# Manually verify each matched line is immediately followed by a ```bash line
```

**Rollback:**
```bash
git checkout -- docs/architecture/0003-git-package-architecture.md
```

---

### Phase 2 — Write ADRs (Before Any Implementation Files)

#### Task 2 — Write ADR-0013: Include-based Git config strategy

**Files affected:**
- `docs/decisions/0013-include-based-git-config-strategy.md` — created

**What to do:**

Create the file with the following content:

```markdown
# Decision: Include-Based Git Config Strategy — .gitconfig.common as Managed Layer

**Number:** 0013
**Date:** 2026-06-17
**Status:** Accepted
**PRD:** 0003-git-package
**Architecture:** 0003-git-package-architecture

## Context

The dotfiles repository needs a managed Git configuration package. Two options were evaluated:

- **Option A:** Stow `.gitconfig` directly to `~/.gitconfig`, replacing the user's existing file.
- **Option B:** Stow `.gitconfig.common` as a separate file; the user adds a `[include]` directive to their existing `~/.gitconfig` to pull in the managed settings.

The user has an existing `~/.gitconfig` with Git identity, signing configuration, and machine-specific settings. Option A would overwrite these irreversibly without a backup. ADR-0006 and PRD-0003 both prohibit modifying the user's existing `~/.gitconfig`.

## Decision

Use **Option B: include-based strategy**.

The managed file is named `.gitconfig.common`. When stowed, it appears at `~/.gitconfig.common`. The user manually adds:

```
[include]
    path = ~/.gitconfig.common
```

to their real `~/.gitconfig`. Identity, signing, credential helpers, and machine-specific settings remain in the user's local `~/.gitconfig` — never tracked by this repository.

The `[include]` directive has been supported since Git 1.7.10 (2012) and is present on all current macOS and Arch installations.

## Consequences

- The user's existing `~/.gitconfig` is never overwritten, replaced, or read by the repository.
- Adopting the managed config requires one manual step — accepted trade-off.
- Disabling is reversible by removing the `[include]` line.
- New settings in `.gitconfig.common` are picked up automatically once the include is active.
- Clean separation: portable settings are managed; identity and private settings are local.
```

**Validation:**
```bash
ls docs/decisions/0013-include-based-git-config-strategy.md
grep "Status: Accepted" docs/decisions/0013-include-based-git-config-strategy.md
grep -iE "signingkey|gpg|password|token" docs/decisions/0013-include-based-git-config-strategy.md
# Last grep must return empty
```

**Rollback:**
```bash
rm docs/decisions/0013-include-based-git-config-strategy.md
```

---

#### Task 3 — Write ADR-0014: `.gitconfig.common` filename chosen over `.gitconfig`

**Files affected:**
- `docs/decisions/0014-gitconfig-common-filename.md` — created

**What to do:**

Create the file with the following content:

```markdown
# Decision: .gitconfig.common Filename Chosen Over .gitconfig to Avoid Home Directory Conflict

**Number:** 0014
**Date:** 2026-06-17
**Status:** Accepted
**PRD:** 0003-git-package
**Architecture:** 0003-git-package-architecture

## Context

Two filenames were evaluated for the managed Git config file:

- **Option A:** `.gitconfig` — stows to `~/.gitconfig`.
- **Option B:** `.gitconfig.common` — stows to `~/.gitconfig.common`.

The user has an existing `~/.gitconfig`. With Option A, Stow refuses to create the symlink because `~/.gitconfig` already exists. The only workarounds are `stow --adopt` (forbidden by safety rules) or manually deleting `~/.gitconfig` first (irreversible data loss risk).

## Decision

Name the managed file **`.gitconfig.common`** — stows to `~/.gitconfig.common`.

Combined with ADR-0013 (include-based strategy), the user's existing `~/.gitconfig` is left entirely untouched. The managed config is layered in via `[include]`.

## Consequences

- Zero conflict risk with any existing `~/.gitconfig` at stow time.
- The stowed path is non-standard but valid — Git follows include paths regardless of filename.
- The `.example` file in the repository is named `.gitconfig.example` — the user renames to `.gitconfig.common` locally.
- Repository `.gitignore` must include `stow/common/git/.gitconfig.common` to prevent accidental commit.
```

**Validation:**
```bash
ls docs/decisions/0014-gitconfig-common-filename.md
grep "Status: Accepted" docs/decisions/0014-gitconfig-common-filename.md
```

**Rollback:**
```bash
rm docs/decisions/0014-gitconfig-common-filename.md
```

---

#### Task 4 — Write ADR-0015: Git credential helpers deferred to platform-specific packages

**Files affected:**
- `docs/decisions/0015-git-credential-helpers-deferred.md` — created

**What to do:**

Create the file with the following content:

```markdown
# Decision: Git Credential Helpers Deferred to Platform-Specific Packages

**Number:** 0015
**Date:** 2026-06-17
**Status:** Accepted
**PRD:** 0003-git-package
**Architecture:** 0003-git-package-architecture

## Context

Git credential helpers are platform-specific:

- macOS uses `osxkeychain` (Xcode Command Line Tools) or `store`.
- Arch / EndeavourOS uses `libsecret`, `gnome-keyring`, or `store`.

Including any credential helper in `stow/common/git/` would violate ADR-0001's third criterion: "No platform-specific tool or behavior is referenced."

## Decision

Git credential helpers are **not included in the common package**. No `[credential]` section appears in `stow/common/git/`.

When credential helper configuration is needed, it will be added in:
- `stow/macos/git/` — for macOS-specific credential helpers.
- `stow/arch/git/` — for Arch-specific credential helpers.

Each platform package will require its own PRD and architecture document.

## Consequences

- The common Git package satisfies all three ADR-0001 common-package criteria without exception.
- Users who need credential helpers must configure them manually in their local `~/.gitconfig` until platform packages exist.
- Future platform-layer Git packages are isolated; the common package is unaffected.
- Trade-off accepted: reduced out-of-the-box convenience in exchange for correct platform separation.
```

**Validation:**
```bash
ls docs/decisions/0015-git-credential-helpers-deferred.md
grep "Status: Accepted" docs/decisions/0015-git-credential-helpers-deferred.md
grep "^\[credential\]" docs/decisions/0015-git-credential-helpers-deferred.md
# Must return empty
```

**Rollback:**
```bash
rm docs/decisions/0015-git-credential-helpers-deferred.md
```

---

### Phase 3 — Stow Package Files

#### Task 5 — Update `stow/common/git/.gitconfig.example` with full architecture content

**Files affected:**
- `stow/common/git/.gitconfig.example` — modified

**What to do:**

Replace the current minimal placeholder with the complete example defined in architecture 0003. The final file must contain exactly the following — placeholder values only, no real identity, no signing config, no credential section:

```ini
# Example only — do not stow directly.
# Copy to .gitconfig.common, verify placeholders, then stow.

[user]
    name = Your Name
    email = your-email@example.com

[core]
    editor = vim
    autocrlf = input
    whitespace = trailing-space,space-before-tab
    excludesfile = ~/.gitignore_global

[pull]
    rebase = false

[merge]
    conflictstyle = diff3

[diff]
    colorMoved = default

[color]
    ui = auto

[alias]
    st = status
    co = checkout
    br = branch
    lg = log --oneline --graph --decorate --all
```

Sections explicitly forbidden: `[credential]`, `[gpg]`, `[commit]` (signing), `[user] signingkey`.

**Validation:**
```bash
grep -E "^\[(user|core|pull|merge|diff|color|alias)\]" stow/common/git/.gitconfig.example
# Must match all 7 section headers

grep -iE "signingkey|gpg|credential|commit\.gpg|osxkeychain" stow/common/git/.gitconfig.example
# Must return empty

grep "Your Name" stow/common/git/.gitconfig.example
grep "your-email@example.com" stow/common/git/.gitconfig.example
# Both must match

git diff stow/common/git/.gitconfig.example
```

**Rollback:**
```bash
git checkout -- stow/common/git/.gitconfig.example
```

---

#### Task 6 — Create `stow/common/git/.gitignore_global.example`

**Files affected:**
- `stow/common/git/.gitignore_global.example` — created

**What to do:**

Create the file with the following content — safe, generic patterns only, no real paths:

```gitignore
# Global gitignore — example only. Do not stow directly.
# Copy to .gitignore_global, add personal patterns, then stow.

# macOS artifacts
.DS_Store
.AppleDouble
.LSOverride
._*

# Linux desktop artifacts
.Trash-*
lost+found

# Editor artifacts
.idea/
.vscode/
*.swp
*.swo
*~
*.orig

# Compiled / build artifacts
*.pyc
__pycache__/
*.class
*.o
*.out

# Thumbnail caches
Thumbs.db
ehthumbs.db

# Environment files (generic)
.env.local
.env.*.local
```

**Validation:**
```bash
ls -la stow/common/git/.gitignore_global.example

grep ".DS_Store" stow/common/git/.gitignore_global.example
grep ".swp" stow/common/git/.gitignore_global.example
grep "Thumbs.db" stow/common/git/.gitignore_global.example
grep ".env.local" stow/common/git/.gitignore_global.example
# All four must match

grep -iE "/Users/|/home/[a-zA-Z]|fnayou|aymen" stow/common/git/.gitignore_global.example
# Must return empty
```

**Rollback:**
```bash
rm stow/common/git/.gitignore_global.example
```

---

### Phase 4 — Repository Safety

#### Task 7 — Add `.gitconfig.common` and `.gitignore_global` to `.gitignore`

**Files affected:**
- `.gitignore` — modified (two entries appended)

**What to do:**

Append the following block at the end of `.gitignore`. Do not modify any existing entry.

```gitignore
# Stow local copies — populated by user; must never be committed
stow/common/git/.gitconfig.common
stow/common/git/.gitignore_global
```

**Validation:**
```bash
grep "gitconfig.common" .gitignore
grep "stow/common/git/.gitignore_global" .gitignore
# Both must match

git diff .gitignore
# Must show only the appended block as additions; no deletions

git check-ignore -v stow/common/git/.gitconfig.common
git check-ignore -v stow/common/git/.gitignore_global
# Both must produce output (gitignore match found)
```

**Rollback:**
```bash
git checkout -- .gitignore
```

---

### Phase 5 — Documentation Updates

#### Task 8 — Update `docs/stow-usage.md` with git package adoption section

**Files affected:**
- `docs/stow-usage.md` — modified (new section appended)

**What to do:**

Append the following section at the end of `docs/stow-usage.md`. Do not modify any existing section.

```markdown
---

## Git package adoption

The `stow/common/git/` package provides two example files. Neither is stowed directly — copy each locally, fill in any personal additions, then stow.

### Files in this package

| Repository file | Purpose |
|---|---|
| `stow/common/git/.gitconfig.example` | Portable common Git settings (copy to `.gitconfig.common` before stowing) |
| `stow/common/git/.gitignore_global.example` | Common global ignore patterns (copy to `.gitignore_global` before stowing) |

After copying and stowing:

| Local file (user-created, git-ignored) | Symlink created at |
|---|---|
| `stow/common/git/.gitconfig.common` | `~/.gitconfig.common` |
| `stow/common/git/.gitignore_global` | `~/.gitignore_global` |

### Step 1 — Copy the example files locally

```bash
cp stow/common/git/.gitconfig.example stow/common/git/.gitconfig.common
cp stow/common/git/.gitignore_global.example stow/common/git/.gitignore_global
```

Both copied files are git-ignored and will not be committed.

### Step 2 — Review the copies

Open each file and confirm:

- `.gitconfig.common` contains only placeholder values (`Your Name`, `your-email@example.com`) — do not replace placeholders with real values.
- `.gitignore_global` — add any personal ignore patterns you need.

### Step 3 — Dry-run the package

```bash
task dry-run AREA=common PACKAGE=git
```

Or directly:

```bash
stow --dir=stow/common --target="$HOME" --simulate git
```

Expected output shows two symlinks that would be created. If you see a conflict, stop — do not use `--adopt`. See the "Conflict handling" section above.

### Step 4 — Stow the package

⚠️  MANUAL STEP — review dry-run output before running
```bash
stow --dir=stow/common --target="$HOME" git
```

### Step 5 — Add the include directive to your real `~/.gitconfig`

Open your real `~/.gitconfig` in an editor and add:

```ini
[include]
    path = ~/.gitconfig.common
```

Your existing identity, signing setup, and machine-specific settings are unaffected.

### Step 6 — Verify adoption

```bash
# Confirm symlinks exist
ls -la ~/.gitconfig.common ~/.gitignore_global

# Confirm Git resolves the include
git config --list --show-origin | grep -i 'gitconfig.common'

# Confirm excludesfile is active
git config --global core.excludesfile

# Confirm identity is NOT coming from .gitconfig.common (must point to ~/.gitconfig)
git config --show-origin user.name
git config --show-origin user.email
```

### What stays in your local `~/.gitconfig`

Never put any of the following into `.gitconfig.common`:

- `user.name` and `user.email` (identity)
- Any signing configuration
- Credential helpers (platform-specific — not in the common package)
- Work-specific `[includeIf]` blocks
- Machine-specific paths
```

**Validation:**
```bash
grep "Git package adoption" docs/stow-usage.md

grep -A1 "MANUAL STEP" docs/stow-usage.md
# Line immediately after marker must be a code fence (```bash)

grep "\-\-simulate" docs/stow-usage.md

grep -iE "fnayou|aymen|signingkey|gpg" docs/stow-usage.md
# Must return empty
```

**Rollback:**
```bash
git checkout -- docs/stow-usage.md
```

---

### Phase 6 — Taskfile Assessment

#### Task 9 — Confirm no Taskfile changes are required

**Files affected:** none

**What to do:**

The existing `Taskfile.yml` already provides `task dry-run AREA=common PACKAGE=git`. No new tasks are needed. Verify the Taskfile is unchanged and still shows exactly the expected four-task set:

```bash
task --list
# Must show exactly: check, detect, dry-run, list

grep -E "^[[:space:]]{2}(install|uninstall|adopt|unlink):" Taskfile.yml
# Must return empty
```

No file change. Checkpoint only.

**Rollback:** N/A — no change made.

---

### Phase 7 — Mark Status Fields Approved

#### Task 10 — Mark PRD 0003 status Approved

**Files affected:**
- `docs/prd/0003-git-package.md` — modified (status field only)

**What to do:**

Change `**Status:** Draft` to `**Status:** Approved`. No other changes.

**Validation:**
```bash
grep "Status" docs/prd/0003-git-package.md
# Must show: **Status:** Approved

git diff docs/prd/0003-git-package.md
# Must show exactly one changed line (Draft → Approved)
```

**Rollback:**
```bash
git checkout -- docs/prd/0003-git-package.md
```

---

#### Task 11 — Mark Architecture 0003 status Approved

**Files affected:**
- `docs/architecture/0003-git-package-architecture.md` — modified (status field only; task 1 marker fixes already applied — no conflict)

**What to do:**

Change `**Status:** Draft` to `**Status:** Approved`. No other changes.

**Validation:**
```bash
grep "Status" docs/architecture/0003-git-package-architecture.md
# Must show: **Status:** Approved
```

**Rollback:**
```bash
git checkout -- docs/architecture/0003-git-package-architecture.md
```

---

### Phase 8 — Privacy and Safety Audit

#### Task 12 — Pre-commit privacy audit

**Files affected:** none

**What to do:**

Run all privacy and safety checks. All must pass with zero findings before proceeding to staging.

```bash
# 1. Check stow package files for secrets
grep -riE "signingkey|gpg|credential|osxkeychain|token|password|BEGIN" \
  stow/common/git/.gitconfig.example \
  stow/common/git/.gitignore_global.example
# Must return empty

# 2. Check for real personal values
grep -iE "fnayou|aymen|@gmail|@work" \
  stow/common/git/.gitconfig.example \
  stow/common/git/.gitignore_global.example
# Must return empty

# 3. Confirm placeholder values present
grep "Your Name" stow/common/git/.gitconfig.example
grep "your-email@example.com" stow/common/git/.gitconfig.example
# Both must match

# 4. Confirm .gitignore protects local stow copies
git check-ignore -v stow/common/git/.gitconfig.common
git check-ignore -v stow/common/git/.gitignore_global
# Both must produce output

# 5. Check new ADRs for forbidden content
grep -riE "signingkey|gpg\.|commit\.gpg|gpgsign" \
  docs/decisions/0013-include-based-git-config-strategy.md \
  docs/decisions/0014-gitconfig-common-filename.md \
  docs/decisions/0015-git-credential-helpers-deferred.md
# Must return empty

# 6. Confirm no stow install command appears without a dry-run gate
# (manual review of docs/stow-usage.md new section)
grep -n "stow.*--dir.*git$" docs/stow-usage.md
# Every matched line must be in a code block preceded by ⚠️  MANUAL STEP
```

**Rollback:** If a finding is discovered, `git checkout -- <file>` the affected file, fix, re-run the audit.

---

### Phase 9 — Staging and Commit

#### Task 13 — Stage files and verify staged diff

**Files affected:** (staging only — no new content changes)

**What to do:**

Stage exactly the files created or modified by this plan:

```bash
git add \
  docs/architecture/0003-git-package-architecture.md \
  docs/decisions/0013-include-based-git-config-strategy.md \
  docs/decisions/0014-gitconfig-common-filename.md \
  docs/decisions/0015-git-credential-helpers-deferred.md \
  stow/common/git/.gitconfig.example \
  stow/common/git/.gitignore_global.example \
  .gitignore \
  docs/stow-usage.md \
  docs/prd/0003-git-package.md \
  docs/plans/0006-implement-git-package.md
```

Then review:

```bash
git diff --staged
git diff --staged --name-only
# Confirm only expected files; no .gitconfig.common or .gitignore_global (local copies)
```

**Rollback:**
```bash
git reset HEAD
```

---

#### Task 14 — Commit

**Files affected:** (commit only)

**What to do:**

After staged diff review passes, commit:

```bash
git commit -m "feat(stow): add git config package — example files, ADRs, adoption docs

- Update stow/common/git/.gitconfig.example with full portable settings
- Add stow/common/git/.gitignore_global.example with common ignore patterns
- Add stow/common/git/ local copies to .gitignore (safety net)
- Write ADRs 0013-0015 (include strategy, filename choice, deferred credential helpers)
- Update docs/stow-usage.md with git package adoption workflow
- Fix architecture marker formatting (review 0006 finding)
- Mark PRD 0003 and Architecture 0003 as Approved"
```

**Validation:**
```bash
git log --oneline -3
git show --stat HEAD
git show HEAD -- stow/common/git/.gitconfig.example | grep -iE "signingkey|gpg|password|credential"
# Last grep must return empty
```

**Rollback (before push):**
```bash
git reset HEAD~1
```

**Rollback (after push):**
```bash
git revert HEAD
```

---

## Files Affected

| File | Action |
|---|---|
| `docs/architecture/0003-git-package-architecture.md` | modified — marker formatting (task 1); status Approved (task 11) |
| `docs/decisions/0013-include-based-git-config-strategy.md` | created (task 2) |
| `docs/decisions/0014-gitconfig-common-filename.md` | created (task 3) |
| `docs/decisions/0015-git-credential-helpers-deferred.md` | created (task 4) |
| `stow/common/git/.gitconfig.example` | modified — full content from architecture 0003 (task 5) |
| `stow/common/git/.gitignore_global.example` | created (task 6) |
| `.gitignore` | modified — two safety entries appended (task 7) |
| `docs/stow-usage.md` | modified — git adoption section appended (task 8) |
| `docs/prd/0003-git-package.md` | modified — status: Approved (task 10) |
| `docs/plans/0006-implement-git-package.md` | created (this file) |

**Files that must NOT be touched:**
- Anything under `$HOME`
- `~/.gitconfig` and `~/.gitignore_global`
- `stow/common/git/.gitconfig.common` (git-ignored local copy)
- `stow/common/git/.gitignore_global` (git-ignored local copy)
- `stow/macos/` and `stow/arch/` contents
- `Taskfile.yml`

---

## Safety Checks

- `git status` clean before starting.
- Branch is not `main`.
- ADRs 0013–0015 do not yet exist.
- After each task, run `git status` — only expected files appear.
- Never run any `stow` command without `--simulate`.
- Never run any `stow` install at all — all stow commands in this plan are documentation only.
- Never run `rm`, `mv`, or `ln -s` against any path under `$HOME`.
- Never read, inspect, or reference the user's real `~/.gitconfig` or `~/.gitignore_global`.

---

## Validation Commands (End-to-End)

Run after task 14 to confirm completion:

```bash
# Structure
ls stow/common/git/
# Expected: .gitconfig.example  .gitignore_global.example

# ADRs
ls docs/decisions/0013-include-based-git-config-strategy.md \
   docs/decisions/0014-gitconfig-common-filename.md \
   docs/decisions/0015-git-credential-helpers-deferred.md

grep "Status: Accepted" \
  docs/decisions/0013-include-based-git-config-strategy.md \
  docs/decisions/0014-gitconfig-common-filename.md \
  docs/decisions/0015-git-credential-helpers-deferred.md
# All three must match

# .gitconfig.example content
grep -E "^\[(user|core|pull|merge|diff|color|alias)\]" stow/common/git/.gitconfig.example
# Must match all 7 sections

grep -iE "signingkey|gpg|credential|osxkeychain|password|token|BEGIN" stow/common/git/.gitconfig.example
# Must return empty

# .gitignore_global.example content
grep ".DS_Store\|.swp\|Thumbs.db\|.env.local" stow/common/git/.gitignore_global.example
# Must match

grep -iE "/Users/|/home/[a-zA-Z]|fnayou|aymen" stow/common/git/.gitignore_global.example
# Must return empty

# .gitignore safety entries
git check-ignore -v stow/common/git/.gitconfig.common
git check-ignore -v stow/common/git/.gitignore_global
# Both must produce output

# Documentation
grep "Git package adoption" docs/stow-usage.md
grep "MANUAL STEP" docs/stow-usage.md
grep "\-\-simulate" docs/stow-usage.md

# Status fields
grep "Status" docs/prd/0003-git-package.md
grep "Status" docs/architecture/0003-git-package-architecture.md
# Both must show: **Status:** Approved

# Taskfile unchanged
task --list
# Must show exactly: check, detect, dry-run, list

grep -E "^[[:space:]]{2}(install|uninstall|adopt|unlink):" Taskfile.yml
# Must return empty

# Git state
git show --stat HEAD
```

---

## Privacy Checks

Run before staging (task 12) and before commit (task 14):

```bash
# No signing references in stow package files
grep -riE "signingkey|gpg\.|commit\.gpg|gpgsign" stow/common/git/
# Must return empty

# No credential helpers in stow package files
grep -riE "osxkeychain|libsecret|credential\s*=" stow/common/git/
# Must return empty

# No real identity values in any new/modified file
grep -riE "fnayou|aymen|@gmail\.com|@work\." \
  stow/common/git/ \
  docs/decisions/0013-include-based-git-config-strategy.md \
  docs/decisions/0014-gitconfig-common-filename.md \
  docs/decisions/0015-git-credential-helpers-deferred.md \
  docs/stow-usage.md
# Must return empty

# No private key material
grep -riE "BEGIN (OPENSSH|RSA|EC|PGP) PRIVATE" stow/ docs/
# Must return empty

# Staged diff clean (after git add, before commit)
git diff --staged | grep -iE "signingkey|gpg\.|osxkeychain|password|token|BEGIN PRIVATE"
# Must return empty
```

---

## Rollback Strategy

All changes are confined to the repository root. No `$HOME` modifications. Rollback is always git-based.

| Task | Rollback command |
|---|---|
| Task 1 (architecture marker fix) | `git checkout -- docs/architecture/0003-git-package-architecture.md` |
| Task 2 (ADR-0013) | `rm docs/decisions/0013-include-based-git-config-strategy.md` |
| Task 3 (ADR-0014) | `rm docs/decisions/0014-gitconfig-common-filename.md` |
| Task 4 (ADR-0015) | `rm docs/decisions/0015-git-credential-helpers-deferred.md` |
| Task 5 (.gitconfig.example update) | `git checkout -- stow/common/git/.gitconfig.example` |
| Task 6 (.gitignore_global.example creation) | `rm stow/common/git/.gitignore_global.example` |
| Task 7 (.gitignore update) | `git checkout -- .gitignore` |
| Task 8 (stow-usage.md update) | `git checkout -- docs/stow-usage.md` |
| Task 10 (PRD status) | `git checkout -- docs/prd/0003-git-package.md` |
| Task 11 (architecture status) | `git checkout -- docs/architecture/0003-git-package-architecture.md` |
| Task 13 (unstage all) | `git reset HEAD` |
| Task 14 (undo commit, before push) | `git reset HEAD~1` |
| Task 14 (revert commit, after push) | `git revert HEAD` |

### Full plan rollback (before commit)

```bash
git reset HEAD

git checkout -- \
  docs/architecture/0003-git-package-architecture.md \
  stow/common/git/.gitconfig.example \
  .gitignore \
  docs/stow-usage.md \
  docs/prd/0003-git-package.md

rm docs/decisions/0013-include-based-git-config-strategy.md
rm docs/decisions/0014-gitconfig-common-filename.md
rm docs/decisions/0015-git-credential-helpers-deferred.md
rm stow/common/git/.gitignore_global.example
rm docs/plans/0006-implement-git-package.md

git status
```

---

## Completion Criteria

- [ ] `stow/common/git/.gitconfig.example` contains all seven sections: `[user]`, `[core]`, `[pull]`, `[merge]`, `[diff]`, `[color]`, `[alias]`.
- [ ] `stow/common/git/.gitconfig.example` placeholder values are `Your Name` and `your-email@example.com`.
- [ ] `stow/common/git/.gitconfig.example` contains no signing, credential, or GPG config.
- [ ] `stow/common/git/.gitignore_global.example` exists with macOS, Linux, editor, build, thumbnail, and env file patterns.
- [ ] `stow/common/git/.gitignore_global.example` contains no real paths or identity.
- [ ] `stow/common/git/.gitconfig.common` and `stow/common/git/.gitignore_global` are in `.gitignore`.
- [ ] `git check-ignore` confirms both local copy paths are ignored.
- [ ] ADR-0013 exists, status Accepted.
- [ ] ADR-0014 exists, status Accepted.
- [ ] ADR-0015 exists, status Accepted.
- [ ] `docs/stow-usage.md` contains "Git package adoption" section with numbered steps.
- [ ] Dry-run instruction precedes every stow install command in `docs/stow-usage.md`.
- [ ] Every stow install command in `docs/stow-usage.md` is preceded by `⚠️  MANUAL STEP` with no blank line before the code fence.
- [ ] Architecture 0003 marker formatting fixed (no blank lines) at all three locations.
- [ ] PRD 0003 status is `Approved`.
- [ ] Architecture 0003 status is `Approved`.
- [ ] `task --list` shows exactly: `check`, `detect`, `dry-run`, `list`.
- [ ] `Taskfile.yml` is unchanged.
- [ ] No file outside the repository root was created, modified, or deleted.
- [ ] No Stow install command was executed during implementation.
- [ ] No symlinks were created in `$HOME`.
- [ ] Privacy audit (task 12) passed with zero findings.
- [ ] Staged diff (task 13) reviewed and confirmed clean.
- [ ] `git show --stat HEAD` shows only files in the "Files Affected" table.
