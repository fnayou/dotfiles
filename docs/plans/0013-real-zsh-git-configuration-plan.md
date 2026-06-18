# Plan: Real Zsh and Git Configuration Adoption

**Number:** 0013
**Status:** Complete
**Date:** 2026-06-18
**PRD:** [0009-real-zsh-git-configuration.md](../prd/0009-real-zsh-git-configuration.md)
**Architecture:** [0009-real-zsh-git-configuration-architecture.md](../architecture/0009-real-zsh-git-configuration-architecture.md)

---

## Objective

Replace placeholder values in the managed zsh layer, audit and stage existing XDG-style Git config files, remove superseded legacy templates, add idempotent bootstrap Taskfile tasks, write a human setup guide for the Git package, and document every decision in ADR-0024 through ADR-0027 — without modifying any file outside the repository.

---

## Assumptions

- `task`, `stow`, `git`, and `zsh` are installed on the machine used to validate.
- The zsh package (`stow/common/zsh`) is already stowed and the managed include block is active in `~/.zshrc` (established by PRD-0007 implementation).
- `~/.config/git/` does not yet exist (or may exist but not contain `config-common`, `aliases`, or `ignore`).
- `~/.gitconfig` may or may not exist; the bootstrap task handles both cases.
- All work stays inside the repository root. No file in `$HOME` is created or modified by any task below except where an explicit `⚠️ MANUAL STEP` marker is shown.
- ADR numbers 0024–0027 are confirmed available (a listing of `docs/decisions/` shows that 0024–0027 do not yet exist).
- ADR-0028 (`docs/decisions/0028-require-human-setup-guides-for-manually-activated-packages.md`) already exists and is Accepted. It requires a human setup guide for any package with manual activation steps. The Git package has manual steps (Stow, `git:bootstrap`, identity configuration); therefore `docs/guides/git-setup.md` is a mandatory deliverable for this plan.
- The git config files `stow/common/git/.config/git/config-common`, `stow/common/git/.config/git/aliases`, and `stow/common/git/.config/git/ignore` already exist in the working tree (untracked, not staged). This plan audits, verifies, and stages those files — it does not create them from scratch. The directory `stow/common/git/.config/git/` already exists and requires no creation step.
- Repository implementation is complete when all repository files are committed. Manual real-home steps (Tasks 9 and 11) are local machine setup steps, not repository implementation steps. Builder must not execute Tasks 9 or 11.

---

## Idempotency Explanation

The `git:bootstrap` task achieves idempotency as follows:

1. Before each `git config --global --add include.path <value>` call, the task runs:
   ```bash
   git config --global --get-all include.path | grep -qxF "<value>"
   ```
2. `--get-all` returns all current `include.path` values, one per line.
3. `grep -qxF` matches the exact full-line string (`-x` = full line, `-F` = literal string, `-q` = quiet).
4. If the value is already present, `--add` is skipped and "skip (already present): `<path>`" is printed.
5. If the value is absent, `git config --global --add include.path <value>` appends it and "added: `<path>`" is printed.
6. A second run of `git:bootstrap` produces identical output ("skip") with no `~/.gitconfig` changes.
7. Post-run validation: `git config --global --get-all include.path | sort | uniq -d` must produce no output.

---

## Alias Safety Rules

The `aliases` file must contain ONLY safe, current-workflow aliases. The following categories are explicitly forbidden and must not appear in any form:

**Forbidden alias patterns:**
- Force-push wrappers (any alias calling `push --force` or `push -f`).
- Hard-reset shortcuts (any alias calling `reset --hard`).
- `git clean` shortcuts or `git purge`/nuke variants.
- `git-svn` workflow aliases.
- `filter-branch` aliases (replaced by `git filter-repo`).
- Aliases that hardcode `master` as a branch name.
- `git-daemon` shortcuts.
- Any alias that could silently destroy work history.

The actual `aliases` file in the working tree contains a comprehensive set of aliases (100+), significantly more than the four minimal aliases described in earlier drafts of this plan. This is acceptable: the file passes all safety rules above (confirmed by grep). The plan does not reduce the alias set to four — the larger safe set is kept. Validation must check ALL aliases in the file against the forbidden patterns, not only a minimal listed subset.

---

## Ordered Tasks

---

### Task 1: Replace placeholder values in `shared.zsh`

**Files changed:**
- `stow/common/zsh/.config/zsh/shared.zsh` — modified

**Safety check:**
- `~/.zshrc` is NOT modified. This task edits only the repository file.
- `$HOME` is NOT modified. Stow is not run.

**Steps:**

1. Open `stow/common/zsh/.config/zsh/shared.zsh`.
2. Find the line:
   ```zsh
   export EDITOR="YOUR_EDITOR"
   ```
   Replace with:
   ```zsh
   export EDITOR="nvim"
   ```
3. Find the line:
   ```zsh
   export PAGER="YOUR_PAGER"
   ```
   Replace with:
   ```zsh
   export PAGER="less"
   ```
4. Save the file. No other changes to this file.

**Validation:**

```bash
# No YOUR_* placeholders remain
grep 'YOUR_' stow/common/zsh/.config/zsh/shared.zsh
# Expected: no output

# EDITOR and PAGER have real values
grep -E '^export (EDITOR|PAGER)' stow/common/zsh/.config/zsh/shared.zsh
# Expected:
#   export EDITOR="nvim"
#   export PAGER="less"

# Syntax check
zsh -n stow/common/zsh/.config/zsh/shared.zsh
# Expected: exit 0, no output

# No forbidden content introduced
grep -E '(brew |pacman |yay |pbcopy|pbpaste|apt |systemctl|git clone|curl |wget )' \
  stow/common/zsh/.config/zsh/shared.zsh
# Expected: no output

# ~/.zshrc modification timestamp unchanged
stat ~/.zshrc
```

**Rollback:**

```bash
git checkout -- stow/common/zsh/.config/zsh/shared.zsh
```

---

### Task 2: Audit and verify `stow/common/git/.config/git/config-common`

**Files changed:**
- `stow/common/git/.config/git/config-common` — staged (file already exists untracked)

**Safety check:**
- `~/.config/git/config-common` is NOT created. This task audits and stages the repository-side source file only.
- `$HOME` is NOT modified.

**Current state note:**
The file already exists in the working tree (untracked). Do NOT delete and recreate it. Audit the existing content, verify it passes safety checks, optionally update content if needed, then stage it.

**Steps:**

1. Check current state:
   ```bash
   git status --short stow/common/git/.config/git/
   # Expected: ?? stow/common/git/.config/ (untracked)
   ```

2. Review content:
   ```bash
   cat stow/common/git/.config/git/config-common
   ```

3. Verify the file content against the following rules:
   - Must have a `[core]` section with at least `editor` and `excludesfile = ~/.config/git/ignore`.
   - Must NOT contain `[user]`, `[alias]`, `[gpg]`, `[commit]`, `[includeIf]` sections.
   - Must NOT contain `signingkey`, `gpgsign`, `osxkeychain`, `libsecret`, `token`, or `password` values.
   - Must NOT contain hardcoded absolute paths with usernames.

   **Difference from plan's original specified content:** The actual file on disk differs from the minimal config-common described in the Architecture (which showed only `[core]`, `[pull]`, `[merge]`, `[diff]`, `[color]`, `[init]`). The actual file contains additional sections: `[rerere]`, `[push]`, `[color "branch"]`, `[color "diff"]`, `[color "status"]`, `[difftool]`. It also uses `editor = vim` (not `nvim`). All additional sections are portable, safe, and contain no forbidden values. The file is acceptable as-is. Do NOT rewrite it to match the Architecture's minimal example — keep the actual content.

4. Verify against safety rules using the comment-ignoring grep:
   ```bash
   grep -v '^[[:space:]]*#' stow/common/git/.config/git/config-common | \
     grep -in 'signingkey\|\[user\]\|\[gpg\]\|gpgsign\|\[commit\]\|osxkeychain\|libsecret\|token\|password\|\[includeif\]\|\[alias\]'
   # Expected: no output
   ```

5. Stage the file:
   ```bash
   git add stow/common/git/.config/git/config-common
   ```

**Validation:**

```bash
# File is staged
git status --short stow/common/git/.config/git/config-common
# Expected: A  stow/common/git/.config/git/config-common

# excludesfile points to XDG path
grep 'excludesfile' stow/common/git/.config/git/config-common
# Expected: excludesfile = ~/.config/git/ignore

# No forbidden sections (comment-ignoring)
grep -v '^[[:space:]]*#' stow/common/git/.config/git/config-common | \
  grep -in 'signingkey\|\[user\]\|\[gpg\]\|gpgsign\|\[commit\]\|osxkeychain\|libsecret\|token\|password\|\[includeif\]\|\[alias\]'
# Expected: no output
```

**Rollback:**

```bash
git restore --staged stow/common/git/.config/git/config-common
```

---

### Task 3: Audit and verify `stow/common/git/.config/git/aliases`

**Files changed:**
- `stow/common/git/.config/git/aliases` — staged (file already exists untracked)

**Safety check:**
- `~/.config/git/aliases` is NOT created. This task audits and stages the repository-side source file only.
- `$HOME` is NOT modified.

**Current state note:**
The file already exists in the working tree (untracked) with a comprehensive alias set (100+ aliases). Do NOT delete and recreate it with a minimal four-alias set. Audit all aliases against the safety rules, then stage the file.

**Steps:**

1. Check current state:
   ```bash
   git status --short stow/common/git/.config/git/aliases
   ```

2. Review content:
   ```bash
   cat stow/common/git/.config/git/aliases
   ```

3. Audit ALL aliases against the forbidden patterns (this grep checks every alias in the file, not only a predefined short list):
   ```bash
   grep -in 'force\|hard\|purge\|nuke\|svn\|filter-branch\|daemon\|master' \
     stow/common/git/.config/git/aliases
   # Expected: no output
   ```

   **Note on `reset --mixed` and `reset --soft`:** The file contains `rem = reset --mixed` and `res = reset --soft`. These are NOT in the forbidden list: `--mixed` moves HEAD to unstage changes (safe, preserves working tree), `--soft` moves HEAD while keeping changes staged (safe, preserves working tree). Only `reset --hard` (which discards working tree changes) is forbidden. These aliases are acceptable.

   **Note on `push` aliases:** The file contains `ps = push`, `psu = push -u`, `pso = push origin`, `psao = push --all origin`, `psuo = push -u origin`. None of these use `--force` or `-f`. They are safe.

4. Verify the file contains only an `[alias]` section (no identity or settings sections):
   ```bash
   grep -in '\[user\]\|\[core\]\|\[pull\]\|\[merge\]\|\[diff\]\|\[color\]\|\[init\]\|\[rerere\]\|\[push\]' \
     stow/common/git/.config/git/aliases
   # Expected: no output (only [alias] section may appear)
   ```

5. Stage the file:
   ```bash
   git add stow/common/git/.config/git/aliases
   ```

**Validation:**

```bash
# File is staged
git status --short stow/common/git/.config/git/aliases
# Expected: A  stow/common/git/.config/git/aliases

# No risky aliases across ALL aliases in the file
grep -in 'force\|hard\|purge\|nuke\|svn\|filter-branch\|daemon\|master' \
  stow/common/git/.config/git/aliases
# Expected: no output

# No identity or settings sections
grep -in '\[user\]\|\[core\]\|\[pull\]\|\[merge\]\|\[diff\]\|\[color\]\|\[init\]\|\[rerere\]\|\[push\]' \
  stow/common/git/.config/git/aliases
# Expected: no output
```

**Rollback:**

```bash
git restore --staged stow/common/git/.config/git/aliases
```

---

### Task 4: Audit and verify `stow/common/git/.config/git/ignore`

**Files changed:**
- `stow/common/git/.config/git/ignore` — staged (file already exists untracked)

**Safety check:**
- `~/.config/git/ignore` is NOT created. This task audits and stages the repository-side source file only.
- `$HOME` is NOT modified.

**Current state note:**
The file already exists in the working tree (untracked). Do NOT delete and recreate it. Audit the existing content, verify it is safe to commit, then stage it.

**Steps:**

1. Check current state:
   ```bash
   git status --short stow/common/git/.config/git/ignore
   ```

2. Review content:
   ```bash
   cat stow/common/git/.config/git/ignore
   ```

3. Verify the file contains only well-known, portable ignore patterns. It must NOT contain:
   - Hardcoded absolute paths.
   - Patterns referencing usernames, hostnames, or private directories.
   - Machine-specific patterns.

   **Difference from plan's original specified content:** The actual file on disk differs from the minimal ignore list described in the Architecture. The actual file contains archive patterns (`*.7z`, `*.dmg`, `*.gz`, etc.), log/database patterns (`*.log`, `*.sql`, `*.sqlite`), Windows artifacts, and a Claude local settings pattern (`**/.claude/settings.local.json`). It does not contain some patterns the Architecture listed (`.AppleDouble`, `.LSOverride`, `.Trash-*`, `lost+found`, `__pycache__/`, etc.). All patterns in the actual file are safe to commit — they are well-known portable tool artifacts and no pattern contains private data.

   The Claude local settings pattern (`**/.claude/settings.local.json`) is appropriate for a dotfiles repo: it prevents accidentally committing local Claude settings from any stow package directory.

4. Verify no private paths:
   ```bash
   grep -i '/Users/\|/home/' stow/common/git/.config/git/ignore
   # Expected: no output
   ```

5. Stage the file:
   ```bash
   git add stow/common/git/.config/git/ignore
   ```

**Validation:**

```bash
# File is staged
git status --short stow/common/git/.config/git/ignore
# Expected: A  stow/common/git/.config/git/ignore

# .DS_Store pattern present (macOS coverage)
grep -c '\.DS_Store' stow/common/git/.config/git/ignore
# Expected: 1 or more

# No private absolute paths
grep -i '/Users/\|/home/' stow/common/git/.config/git/ignore
# Expected: no output
```

**Rollback:**

```bash
git restore --staged stow/common/git/.config/git/ignore
```

---

### Task 5: Remove legacy template files

**Files changed:**
- `stow/common/git/.gitconfig.example` — deleted
- `stow/common/git/.gitignore_global.example` — deleted

**Safety check:**
- These are tracked `.example` files in the repository, NOT user dotfiles. Removing them does not affect `$HOME`.
- `~/.gitconfig` and `~/.gitignore_global` in `$HOME` are NOT touched.

**Current state note:**
Both files are already deleted in the working tree (shown as `D` in `git status`). They need to be staged for deletion.

**Steps:**

1. Verify current state:
   ```bash
   git status --short stow/common/git/
   # Expected: D stow/common/git/.gitconfig.example
   #            D stow/common/git/.gitignore_global.example
   ```

2. Stage the deletions:
   ```bash
   git rm stow/common/git/.gitconfig.example
   git rm stow/common/git/.gitignore_global.example
   ```
   (If git rm complains that files are already removed from the working tree, use `git rm --cached` instead and then confirm the working tree deletion is already done.)

**Validation:**

```bash
# Both staged for deletion
git status stow/common/git/
# Expected: both shown as "deleted"

# New files present
ls stow/common/git/.config/git/
# Expected: aliases  config-common  ignore

# Old files gone from working tree
ls stow/common/git/
# Expected: .config/ only
```

**Rollback:**

```bash
git checkout -- stow/common/git/.gitconfig.example
git checkout -- stow/common/git/.gitignore_global.example
```

---

### Task 6: Update root `.gitignore`

**Files changed:**
- `.gitignore` — modified (two obsolete entries removed)

**Safety check:**
- This file is inside the repository. No `$HOME` file is modified.
- The entries being removed refer to paths that no longer exist after Task 5.

**Steps:**

1. Open `.gitignore`.
2. Find and remove this block entirely (comment + both path entries):
   ```
   # Stow local copies — populated by user; must never be committed
   stow/common/git/.gitconfig.common
   stow/common/git/.gitignore_global
   ```
3. Save the file.

**Validation:**

```bash
grep 'gitconfig.common' .gitignore
# Expected: no output

grep 'gitignore_global' .gitignore
# Expected: no output

# File still has expected remaining entries
grep -c 'DS_Store' .gitignore
# Expected: 1
```

**Rollback:**

```bash
git checkout -- .gitignore
```

---

### Task 7: Add `git:bootstrap:dry-run` and `git:bootstrap` tasks to `Taskfile.yml`

**Files changed:**
- `Taskfile.yml` — modified (two tasks appended)

**Safety check:**
- `Taskfile.yml` is inside the repository. No `$HOME` file is modified.
- The tasks are defined but NOT executed by this task.
- These tasks must NEVER be called by another task and must NEVER run automatically.

**Steps:**

1. Open `Taskfile.yml`.
2. Append the following two tasks at the end of the `tasks:` block, following the exact indentation and YAML style of the existing tasks (2-space indent for task names under `tasks:`, `desc` on first line, `cmds` with `|` block scalar):

```yaml
  git:bootstrap:dry-run:
    desc: "Show include.path entries that would be added to ~/.gitconfig — no changes made"
    cmds:
      - |
        echo ""
        echo "git:bootstrap dry-run — no changes will be made"
        echo "================================================="
        echo ""
        if [[ -f "$HOME/.gitconfig" ]]; then
          echo "~/.gitconfig exists: yes"
        else
          echo "~/.gitconfig exists: no (will be created by git on first --add)"
        fi
        echo ""
        echo "Current include.path values:"
        git config --global --get-all include.path 2>/dev/null || echo "  (none)"
        echo ""
        echo "Required entries:"
        for inc in "~/.config/git/config-common" "~/.config/git/aliases"; do
          if git config --global --get-all include.path 2>/dev/null | grep -qxF "$inc"; then
            echo "  already present: include.path = $inc"
          else
            echo "  would add:       include.path = $inc"
          fi
        done
        echo ""
        if [[ -f "$HOME/.gitconfig" ]]; then
          echo "Backup: yes — a timestamped backup would be created before any change"
        else
          echo "Backup: not needed — ~/.gitconfig does not exist yet"
        fi
        echo ""

  git:bootstrap:
    desc: "Wire ~/.gitconfig to managed Git config — idempotent, creates timestamped backup"
    cmds:
      - |
        GITCONFIG="$HOME/.gitconfig"
        if [[ -f "$GITCONFIG" ]]; then
          BACKUP="${GITCONFIG}.bak.$(date +%Y%m%d%H%M%S)"
          cp "$GITCONFIG" "$BACKUP"
          echo "Backup created: $BACKUP"
        else
          echo "~/.gitconfig does not exist — git will create it on first --add"
        fi
        echo ""
        for inc in "~/.config/git/config-common" "~/.config/git/aliases"; do
          if git config --global --get-all include.path 2>/dev/null | grep -qxF "$inc"; then
            echo "skip (already present): $inc"
          else
            git config --global --add include.path "$inc"
            echo "added: $inc"
          fi
        done
        echo ""
        echo "Final include.path values:"
        git config --global --get-all include.path 2>/dev/null || echo "  (none)"
        echo ""
```

**Validation:**

```bash
# Tasks appear in list
task --list | grep 'git:bootstrap'
# Expected:
#   git:bootstrap:dry-run   Show include.path entries that would be added...
#   git:bootstrap           Wire ~/.gitconfig to managed Git config...

# Taskfile YAML is valid
task --list > /dev/null
# Expected: exit 0

# Neither task has a deps: block (must be standalone only)
grep -A3 'git:bootstrap:$' Taskfile.yml | grep 'deps:'
# Expected: no output
```

**Rollback:**

```bash
git checkout -- Taskfile.yml
```

---

### Task 8: Validate Git Stow package layout with fake-home

**Files changed:** none (read-only validation)

**Safety check:**
- Uses a temporary directory as the Stow target. Real `$HOME` is NOT touched.
- `$TEST_HOME` is cleaned up immediately after the simulation.

**Steps:**

1. Run the fake-home stow simulation:

```bash
TEST_HOME="$(mktemp -d)"
stow --dir=stow/common --target="$TEST_HOME" --simulate git
echo "Exit code: $?"
rm -rf "$TEST_HOME"
```

**Expected output:** Three symlink creation lines:

```
LINK: .config/git/config-common => <repo>/stow/common/git/.config/git/config-common
LINK: .config/git/aliases => <repo>/stow/common/git/.config/git/aliases
LINK: .config/git/ignore => <repo>/stow/common/git/.config/git/ignore
```

No conflicts. Exit code 0.

Or using the Taskfile:

```bash
task dry-run AREA=common PACKAGE=git
```

**Rollback:** No changes were made — nothing to roll back.

---

### Task 9: Stow the Git package against real `$HOME`

⚠️  MANUAL STEP — review dry-run output from Task 8 before running

**Files changed:**
- `~/.config/git/config-common` — symlink created (points into repository)
- `~/.config/git/aliases` — symlink created
- `~/.config/git/ignore` — symlink created

**Safety check:**
- `~/.gitconfig` is NOT modified by Stow. Stow creates only the three symlinks.
- This is the only Stow task that writes to `$HOME`. It is a manual step.
- Builder must NOT execute this task. This is a local machine setup step.

**Steps:**

```
⚠️  MANUAL STEP — review before running
stow --dir=stow/common --target="$HOME" git
```

**Validation:**

```bash
# Symlinks exist and resolve correctly
ls -la ~/.config/git/
# Expected: config-common, aliases, ignore all as symlinks into the repository

readlink ~/.config/git/config-common
readlink ~/.config/git/aliases
readlink ~/.config/git/ignore
# Expected: each resolves into stow/common/git/.config/git/<name>

# ~/.gitconfig modification timestamp unchanged by Stow
stat ~/.gitconfig
```

**Rollback:**

```
⚠️  MANUAL STEP — review before running
stow --dir=stow/common --target="$HOME" --delete git
```

---

### Task 10: Run `git:bootstrap:dry-run` to preview wiring

**Files changed:** none (read-only)

**Safety check:**
- `git:bootstrap:dry-run` never modifies `~/.gitconfig` or any file.
- This task is run before `git:bootstrap` to confirm what will change.

**Steps:**

```bash
task git:bootstrap:dry-run
```

**Expected output** (if `~/.gitconfig` exists and no includes are wired yet):

```
git:bootstrap dry-run — no changes will be made
=================================================

~/.gitconfig exists: yes

Current include.path values:
  (none)

Required entries:
  would add:       include.path = ~/.config/git/config-common
  would add:       include.path = ~/.config/git/aliases

Backup: yes — a timestamped backup would be created before any change
```

**Validation:** Output matches expected format above. `~/.gitconfig` is unchanged.

**Rollback:** No changes were made.

---

### Task 11: Run `git:bootstrap` to wire `~/.gitconfig`

⚠️  MANUAL STEP — review dry-run output from Task 10 before running

**Files changed:**
- `~/.gitconfig` — two `[include]` entries appended; timestamped backup created

**Safety check:**
- Existing `~/.gitconfig` content is fully preserved. A timestamped backup is created before any modification.
- `user.name`, `user.email`, signing keys, existing `[includeIf]` blocks, and existing `include.path` entries are never removed.
- Uses `git config --global --add` only — never overwrites the file directly.
- Builder must NOT execute this task. This is a local machine setup step.

**Steps:**

```
⚠️  MANUAL STEP — review before running
task git:bootstrap
```

**Expected output (first run):**

```
Backup created: ~/.gitconfig.bak.20260618HHMMSS

added: ~/.config/git/config-common
added: ~/.config/git/aliases

Final include.path values:
~/.config/git/config-common
~/.config/git/aliases
```

**Expected output (second run — idempotency verification):**

```
Backup created: ~/.gitconfig.bak.20260618HHMMSS2

skip (already present): ~/.config/git/config-common
skip (already present): ~/.config/git/aliases

Final include.path values:
~/.config/git/config-common
~/.config/git/aliases
```

**Validation:**

```bash
# No duplicate include.path entries
git config --global --get-all include.path | sort | uniq -d
# Expected: no output

# Managed config is active
git config --list --show-origin | grep 'config/git/config-common'
# Expected: lines attributed to ~/.config/git/config-common

# excludesfile active
git config --global core.excludesfile
# Expected: ~/.config/git/ignore

# Identity NOT in managed files
git config --show-origin user.name
git config --show-origin user.email
# Expected: both attributed to ~/.gitconfig, never to config-common or aliases

# Idempotency check — run a second time
task git:bootstrap
# Expected: both entries show "skip (already present)"
```

**Rollback:**

```bash
# Restore from backup (replace TIMESTAMP with actual value printed during Task 11)
cp ~/.gitconfig.bak.TIMESTAMP ~/.gitconfig
```

---

### Task 12: Validate zsh managed layer with real values

**Files changed:** none (read-only)

**Safety check:**
- Shell startup test only. `~/.zshrc` is not modified.
- Assumes Task 1 is complete and the zsh package is already stowed.

**Steps:**

```bash
# Syntax check
zsh -n stow/common/zsh/.config/zsh/shared.zsh
# Expected: no output (exit 0)

# No placeholder tokens
grep 'YOUR_' stow/common/zsh/.config/zsh/shared.zsh
# Expected: no output

# Shell startup test
zsh -ic 'echo zsh-ok'
# Expected: prints "zsh-ok" with no errors

# EDITOR and PAGER exported correctly
zsh -ic 'echo $EDITOR'
# Expected: nvim

zsh -ic 'echo $PAGER'
# Expected: less

# ~/.zshrc unchanged
stat ~/.zshrc
```

**Rollback:** If shell errors appear, check `shared.zsh` syntax. If the managed layer is misbehaving:

```
Edit ~/.zshrc and comment out or remove the guarded managed block:
# >>> dotfiles managed (zsh) — added manually; delete this block to disable >>>
[[ -r "$HOME/.config/zsh/index.zsh" ]] && source "$HOME/.config/zsh/index.zsh"
# <<< dotfiles managed (zsh) <<<
Open a new shell — managed layer is inert immediately.
```

---

### Task 13: Run pre-commit privacy audit

**Files changed:** none (read-only audit)

**Safety check:**
- All commands below are read-only. Nothing is staged or committed by this task.

**Steps:**

Run all audit commands. Every command must produce no output before proceeding to Task 14.

```bash
# 1. No YOUR_* placeholders in shared.zsh
grep 'YOUR_' stow/common/zsh/.config/zsh/shared.zsh
# Expected: no output

# 2. No identity values in Git config files (comment-ignoring grep)
# Note: the grep -v line strips comment lines first so that documentation
# comments like "# No [user] identity here" do not produce false positives.
grep -v '^[[:space:]]*#' stow/common/git/.config/git/config-common \
  stow/common/git/.config/git/aliases | \
  grep -in 'signingkey\|\[user\]\|\[gpg\]\|gpgsign\|osxkeychain\|token\|password'
# Expected: no output

# 3. No risky aliases — checks ALL aliases in the file
grep -in 'force\|hard\|purge\|nuke\|svn\|filter-branch\|daemon\|master' \
  stow/common/git/.config/git/aliases
# Expected: no output

# 4. No private zsh files staged
git diff --staged --name-only | \
  grep -E '(macos\.zsh|arch\.zsh|omp\.zsh|local\.zsh)$'
# Expected: no output

# 5. No real paths with username in any committed file
grep -r '/Users/fnayou' \
  stow/common/git/.config/git/ \
  stow/common/zsh/.config/zsh/shared.zsh
# Expected: no output

# 6. Confirm staged files match expected set
git diff --staged --name-only
# Expected: only these files (in any order):
#   stow/common/zsh/.config/zsh/shared.zsh
#   stow/common/git/.config/git/config-common
#   stow/common/git/.config/git/aliases
#   stow/common/git/.config/git/ignore
#   stow/common/git/.gitconfig.example            (deleted)
#   stow/common/git/.gitignore_global.example     (deleted)
#   .gitignore
#   Taskfile.yml
#   docs/decisions/0024-*.md                      (new)
#   docs/decisions/0025-*.md                      (new)
#   docs/decisions/0026-*.md                      (new)
#   docs/decisions/0027-*.md                      (new)
#   docs/guides/git-setup.md                      (new)
#   docs/plans/0013-real-zsh-git-configuration-plan.md (new or modified)
```

**Rollback:** If any audit step produces output, fix the offending file before continuing. Use `git checkout -- <file>` to revert a specific file.

---

### Task 14: Write ADR-0024

**Files changed:**
- `docs/decisions/0024-shared-index-zsh-tracked-with-real-content.md` — created

**Safety check:** Documentation file only. No `$HOME` modification.

**Content:**

```markdown
# Decision: `shared.zsh` and `index.zsh` Tracked with Real Safe Content

**Number:** 0024
**Date:** 2026-06-18
**Status:** Accepted
**Related:** ADR-0016, ADR-0021, Architecture-0009

## Context

Prior to this decision, the zsh package convention established by Architecture-0004 was
`.example`-only for files that might contain machine-specific values. `shared.zsh` and
`index.zsh` were already tracked as real filenames (not `.example`) by PRD-0007's
implementation, but `shared.zsh` still contained placeholder tokens (`YOUR_EDITOR`,
`YOUR_PAGER`) that prevented it from functioning as real configuration.

The question was: should `shared.zsh` be untracked (moved to git-ignored status, with
only `shared.zsh.example` committed) or should it be kept tracked and populated with
real safe values?

## Decision

Keep both `shared.zsh` and `index.zsh` tracked in git, and populate `shared.zsh` with
real, portable, safe values — replacing `YOUR_EDITOR` with `nvim` and `YOUR_PAGER`
with `less`.

"Safe to commit" is defined as: works on both macOS and Arch Linux without modification,
contains no real identity (name, email, hostname), no machine-specific absolute paths,
no secrets, tokens, or keys, and no install/clone/network calls.

## Consequences

- `shared.zsh` with `nvim` and `less` is safe to commit: both are portable tool names,
  not paths, and neither reveals any private information.
- The `.example` counterpart (`shared.zsh.example`) remains for new-machine documentation.
- Un-tracking would require `git rm --cached shared.zsh` and add confusion about which
  file is authoritative.
- `index.zsh` is already final and has no placeholders — its tracked status is unchanged.
- Future contributors see the real operating file, not only a template.
- If a user prefers a different editor or pager, they override in `local.zsh` (ADR-0023).
- Trade-off accepted: a committed tool preference (`nvim`) is a minor opinion but
  completely safe, portable, and overridable.
```

**Validation:**

```bash
ls docs/decisions/ | grep 0024
# Expected: 0024-shared-index-zsh-tracked-with-real-content.md
```

**Rollback:**

```bash
rm docs/decisions/0024-shared-index-zsh-tracked-with-real-content.md
```

---

### Task 15: Write ADR-0025

**Files changed:**
- `docs/decisions/0025-xdg-style-git-config-layout.md` — created

**Safety check:** Documentation file only. No `$HOME` modification.

**Content:**

```markdown
# Decision: XDG-Style Git Config Layout (`~/.config/git/`)

**Number:** 0025
**Date:** 2026-06-18
**Status:** Accepted
**Supersedes:** ADR-0013 (include-based Git config strategy, in part), ADR-0014 (gitconfig-common filename)
**Related:** Architecture-0009, PRD-0009

## Context

ADR-0013 defined an include-based Git config strategy where `~/.gitconfig` includes a
managed common file. ADR-0014 named that file `.gitconfig.common` (home-level dotfile).
ADR-0006 established `.example`-only templates for all Git config files.

The initial revision of Architecture-0009 proposed continuing with home-level files
(`.gitconfig.common`, `.gitignore_global`). A revision adopted XDG layout
(`~/.config/git/`) instead. This ADR records that revision decision.

Three options were considered:

1. **Home-level dotfiles** — `~/.gitconfig.common`, `~/.gitignore_global`. Familiar,
   but clutters `$HOME`, uses legacy naming conventions.
2. **XDG layout** — `~/.config/git/config-common`, `~/.config/git/aliases`,
   `~/.config/git/ignore`. Clean, modern, already used by Git natively for
   `~/.config/git/config`.
3. **Single combined file** — one file with both settings and aliases. Simpler to
   manage but harder to audit.

## Decision

Use the XDG-style layout with three committed files under `~/.config/git/`:

- `config-common` — portable settings (no identity, no aliases).
- `aliases` — Git aliases only.
- `ignore` — global ignore patterns (referenced via `core.excludesfile`).

The Stow package tree mirrors this at `stow/common/git/.config/git/`.
`~/.gitconfig` includes `config-common` and `aliases` via `[include] path = ...`.
`ignore` is referenced by `core.excludesfile = ~/.config/git/ignore` inside
`config-common` — no separate include needed.

## Consequences

- Supersedes the home-level path decisions in ADR-0013 and ADR-0014. Those ADRs
  remain for historical context but their path choices are no longer active.
- `stow/common/git/.gitconfig.example` and `.gitignore_global.example` are removed.
- Root `.gitignore` entries for `stow/common/git/.gitconfig.common` and
  `stow/common/git/.gitignore_global` are removed (those paths no longer exist).
- `~/.config/git/` is created on the user's machine when Stow runs.
- Bootstrap task wires the includes into `~/.gitconfig` (see ADR-0027).
- Each file has a single clear responsibility and can be audited independently.
- Trade-off accepted: slightly more files than a single combined config.
```

**Validation:**

```bash
ls docs/decisions/ | grep 0025
# Expected: 0025-xdg-style-git-config-layout.md
```

**Rollback:**

```bash
rm docs/decisions/0025-xdg-style-git-config-layout.md
```

---

### Task 16: Write ADR-0026

**Files changed:**
- `docs/decisions/0026-git-aliases-separate-file.md` — created

**Safety check:** Documentation file only. No `$HOME` modification.

**Content:**

```markdown
# Decision: Git Aliases Extracted to a Separate `aliases` File

**Number:** 0026
**Date:** 2026-06-18
**Status:** Accepted
**Related:** ADR-0025, Architecture-0009

## Context

In the XDG Git layout established by ADR-0025, two approaches existed for organizing
aliases relative to settings:

1. **Combined** — one `config-common` file with both settings and `[alias]` section.
2. **Separated** — `config-common` for settings only; `aliases` as a separate file.

The legacy `.gitconfig.example` combined everything into one file.

## Decision

Extract Git aliases into a dedicated `aliases` file. `config-common` contains ONLY
non-alias configuration sections. `aliases` contains ONLY the `[alias]` section.

Both files are included from `~/.gitconfig` via separate `[include] path = ...` entries.

**Alias safety policy — permanently forbidden:**

- Force-push wrappers (any alias calling `push --force` or `push -f`).
- Hard-reset shortcuts (any alias calling `reset --hard`).
- `git clean` shortcuts or `git purge`/nuke variants.
- `git-svn` workflow aliases.
- `filter-branch` aliases (superseded by `git filter-repo`).
- Aliases that hardcode `master` as a branch name.
- `git-daemon` shortcuts.
- Any alias that could silently destroy work history.

Forbidden aliases are removed completely — not preserved in any legacy file.

The `aliases` file may contain a comprehensive set of safe aliases beyond a minimal
shorthand list. The set committed at initial adoption was audited against all forbidden
patterns and passed. New aliases may be added in future commits provided they pass
the same safety audit.

## Consequences

- Settings and aliases have different change rates; separate files make diffs cleaner.
- Security audits of `aliases` are focused: a reviewer scans one file for risky shorthand.
- `config-common` is easier to read without an `[alias]` section growing over time.
- New aliases are added to `aliases` only; `config-common` is not touched for alias changes.
- Trade-off accepted: two include entries in `~/.gitconfig` instead of one.
```

**Validation:**

```bash
ls docs/decisions/ | grep 0026
# Expected: 0026-git-aliases-separate-file.md
```

**Rollback:**

```bash
rm docs/decisions/0026-git-aliases-separate-file.md
```

---

### Task 17: Write ADR-0027

**Files changed:**
- `docs/decisions/0027-git-bootstrap-taskfile-tasks.md` — created

**Safety check:** Documentation file only. No `$HOME` modification.

**Content:**

```markdown
# Decision: `git:bootstrap` and `git:bootstrap:dry-run` as First Mutating Taskfile Tasks

**Number:** 0027
**Date:** 2026-06-18
**Status:** Accepted
**Supersedes:** N/A (lifts the ADR-0009 restriction for this specific, bounded case)
**Related:** ADR-0002, ADR-0009, ADR-0025, Architecture-0009

## Context

ADR-0009 restricted the foundation-phase Taskfile to read-only tasks, stating:
"Adding a mutating task in a future phase requires a new PRD that explicitly lifts
this restriction."

PRD-0009 defines Git configuration adoption. After Stow links managed Git files into
`~/.config/git/`, the user's `~/.gitconfig` must be wired with two `[include] path = ...`
entries pointing to those files. Without a task for this, the wiring is a manual,
error-prone multi-step operation that is hard to make idempotent.

## Decision

Add two tasks to `Taskfile.yml`:

- `git:bootstrap:dry-run` — shows current `include.path` state and what would be added.
  Never modifies any file.
- `git:bootstrap` — adds missing `include.path` entries to `~/.gitconfig` using
  `git config --global --add`. Idempotent via check-before-add. Creates a timestamped
  backup before modifying an existing file.

**Safety invariants (all must hold):**

- Never overwrites `~/.gitconfig` — uses `--add` to append only.
- Timestamped backup (`~/.gitconfig.bak.YYYYMMDDHHMMSS`) created before any write.
- Idempotent: checks `git config --global --get-all include.path | grep -qxF <value>`
  before each `--add`. A second run produces only "skip (already present)" lines.
- Never touches `user.name`, `user.email`, signing keys, credentials, or existing
  `include.path` entries.
- Never removes existing `include.path` entries.
- Never called by another task, never triggered automatically.

**ADR-0009 scope lift:** This decision explicitly authorizes the first mutating Taskfile
tasks under these conditions. The conditions are: user-invoked only, idempotent,
backup-creating, scoped to `[include]` entries only, and never automatic. These
conditions must hold for any future mutating Taskfile task added in this repository.

## Consequences

- Users run `task git:bootstrap:dry-run` first to preview, then `task git:bootstrap`.
- The backup provides a guaranteed rollback path.
- Running `git:bootstrap` twice is safe — no duplicates, no errors.
- The Taskfile now contains one mutating task. The mutating-task boundary is explicit
  and documented. ADR-0009's safety default remains; this ADR records the exception.
- Trade-off accepted: the convenience of idempotent, auditable wiring outweighs the
  added complexity of a mutating task.
```

**Validation:**

```bash
ls docs/decisions/ | grep 0027
# Expected: 0027-git-bootstrap-taskfile-tasks.md
```

**Rollback:**

```bash
rm docs/decisions/0027-git-bootstrap-taskfile-tasks.md
```

---

### Task 18: Write `docs/guides/git-setup.md`

**Files changed:**
- `docs/guides/git-setup.md` — created

**Safety check:** Documentation file only. No `$HOME` modification. Required by ADR-0028.

**Purpose:**
This guide is the user-facing reference for setting up the Git package on a new machine. It is required by ADR-0028 because the Git package has manual activation steps: Stow creates symlinks, `git:bootstrap` wires includes, and the user must configure identity. The guide must be written for a human performing the setup, not for an implementation agent.

**The guide must cover all sections in the following order, as required by ADR-0028:**

1. **What this package manages** — three files stowed to `~/.config/git/`: `config-common` (portable settings), `aliases` (Git aliases), `ignore` (global ignore patterns).

2. **What it does NOT manage** — must state explicitly:
   - `~/.gitconfig` remains unmanaged and is never stowed or overwritten.
   - `~/.gitconfig` is not symlinked by this package.
   - Existing `~/.gitconfig` content is fully preserved.
   - `user.name`, `user.email`, signing keys, and credentials are not managed by this repository.

3. **Prerequisites** — `git`, `stow`, and `task` must be installed. Include the check command: `task check`.

4. **Dry-run step** — the Stow dry-run command to run before applying:
   ```
   task dry-run AREA=common PACKAGE=git
   ```
   Describe what to look for: three `LINK:` lines for `config-common`, `aliases`, `ignore`. No conflict lines. Exit code 0.

5. **Apply step (Stow)** — must be marked `⚠️  MANUAL STEP`:
   ```
   ⚠️  MANUAL STEP — review dry-run output before running
   stow --dir=stow/common --target="$HOME" git
   ```
   Must explicitly state that `stow --adopt` is forbidden and explain why (it silently overwrites files in `$HOME` without a backup, destroying existing content).

6. **Manual activation steps** — two steps, both marked `⚠️  MANUAL STEP`:
   a. Preview bootstrap:
      ```
      task git:bootstrap:dry-run
      ```
   b. Apply bootstrap (marked ⚠️  MANUAL STEP):
      ```
      ⚠️  MANUAL STEP — review dry-run output before running
      task git:bootstrap
      ```
      Explain: this adds two `[include] path = ...` entries to `~/.gitconfig`. A timestamped backup of `~/.gitconfig` is created before any change. Must state: existing `~/.gitconfig` content is preserved.
   c. Configure identity (marked ⚠️  MANUAL STEP — uses placeholder values):
      ```
      ⚠️  MANUAL STEP — replace placeholder values with your own
      git config --global user.name "Your Name"
      git config --global user.email "your-email@example.com"
      ```
      Must state that this writes to `~/.gitconfig` directly, which is correct — identity is never managed by this repository.

7. **Validation steps** — copy-pasteable commands to verify setup:
   - `ls -la ~/.config/git/` — confirm three symlinks exist.
   - `readlink ~/.config/git/config-common` — confirm resolves into repository.
   - `git config --global --get-all include.path` — confirm both paths appear.
   - `git config --global core.excludesfile` — confirm prints `~/.config/git/ignore`.
   - `git config --global --get-all include.path | sort | uniq -d` — must produce no output (no duplicates).
   - `git config --show-origin user.name` — confirm attributed to `~/.gitconfig`.

8. **Rollback steps** — how to undo in reverse order:
   - Undo bootstrap: comment out the two `[include]` entries in `~/.gitconfig` or restore from backup (`~/.gitconfig.bak.TIMESTAMP`).
   - Undo Stow (marked ⚠️  MANUAL STEP):
     ```
     ⚠️  MANUAL STEP
     stow --dir=stow/common --target="$HOME" --delete git
     ```

9. **Troubleshooting** — at minimum cover:
   - Stow conflict: a real file already exists at `~/.config/git/config-common` (not a symlink). Resolution: move it out of the way, then re-run Stow dry-run to confirm no conflict.
   - Bootstrap duplicate: if `git config --global --get-all include.path | sort | uniq -d` shows duplicates, remove the duplicate manually from `~/.gitconfig` and run `git:bootstrap` again (it will skip already-present entries).
   - Identity not set: `git config --show-origin user.name` shows no output — run the identity step above.

10. **Expected final file layout** — show what `~/.config/git/` and `~/.gitconfig` look like after successful setup. Use placeholder values in the `~/.gitconfig` example:
    ```
    ~/.config/git/
      config-common  -> /path/to/dotfiles/stow/common/git/.config/git/config-common
      aliases        -> /path/to/dotfiles/stow/common/git/.config/git/aliases
      ignore         -> /path/to/dotfiles/stow/common/git/.config/git/ignore

    ~/.gitconfig (managed portions only — placeholder values):
      [user]
          name = Your Name
          email = your-email@example.com
      [include]
          path = ~/.config/git/config-common
      [include]
          path = ~/.config/git/aliases
    ```

**Guide rules (required by ADR-0028 — all must be satisfied):**
- Must not include secrets, private values, real email addresses, real names, or tokens. All examples use placeholder values only.
- Must not encourage `stow --adopt` — it must be explicitly forbidden with explanation.
- Must mark every command that modifies `$HOME` with `⚠️  MANUAL STEP — review before running`.
- Must state `~/.gitconfig` remains unmanaged.
- Must state `~/.gitconfig` is not symlinked.
- Must state existing `~/.gitconfig` content is preserved.
- Must state a backup is created before `git:bootstrap` modifies `~/.gitconfig`.

**Validation:**

```bash
ls docs/guides/git-setup.md
# Expected: file exists

# Must explicitly say ~/.gitconfig is not symlinked
grep -i 'not symlinked\|not stowed\|remains unmanaged' docs/guides/git-setup.md
# Expected: at least one match

# Must explicitly say stow --adopt is forbidden
grep -i 'adopt' docs/guides/git-setup.md
# Expected: at least one line (the warning against it)

# Must have MANUAL STEP markers
grep 'MANUAL STEP' docs/guides/git-setup.md
# Expected: at least three lines (Stow apply, bootstrap apply, identity config)

# Must not contain real private values
grep -i 'fnayou\|gmail\.com' docs/guides/git-setup.md
# Expected: no output
```

**Rollback:**

```bash
rm docs/guides/git-setup.md
```

---

## Files Affected Summary

| Path | Action |
|---|---|
| `stow/common/zsh/.config/zsh/shared.zsh` | modified — `YOUR_EDITOR` → `nvim`, `YOUR_PAGER` → `less` |
| `stow/common/git/.config/git/config-common` | staged — file already exists (audited and staged) |
| `stow/common/git/.config/git/aliases` | staged — file already exists (audited and staged, comprehensive alias set) |
| `stow/common/git/.config/git/ignore` | staged — file already exists (audited and staged) |
| `stow/common/git/.gitconfig.example` | deleted — superseded (already deleted in working tree, staged for deletion) |
| `stow/common/git/.gitignore_global.example` | deleted — superseded (already deleted in working tree, staged for deletion) |
| `.gitignore` | modified — two obsolete entries removed |
| `Taskfile.yml` | modified — two tasks appended |
| `docs/decisions/0024-shared-index-zsh-tracked-with-real-content.md` | created |
| `docs/decisions/0025-xdg-style-git-config-layout.md` | created |
| `docs/decisions/0026-git-aliases-separate-file.md` | created |
| `docs/decisions/0027-git-bootstrap-taskfile-tasks.md` | created |
| `docs/guides/git-setup.md` | created — required by ADR-0028 |
| `docs/plans/0013-real-zsh-git-configuration-plan.md` | created/updated — this file |
| `~/.config/git/config-common` | created (symlink) — Task 9 manual step only |
| `~/.config/git/aliases` | created (symlink) — Task 9 manual step only |
| `~/.config/git/ignore` | created (symlink) — Task 9 manual step only |
| `~/.gitconfig` | modified (includes appended) — Task 11 manual step only |

---

## Safety Checks

- `~/.zshrc` must never be modified by any task in this plan.
- `$HOME` must never be modified except by the two explicit manual steps (Tasks 9 and 11).
- `stow --adopt` must never be used.
- No task may call `git:bootstrap` or `git:bootstrap:dry-run` as a dependency.
- No install command (`brew install`, `pacman -S`, `npm install`) may be run.
- No `git clone` may be run.
- All committed Git config files must pass the privacy audit in Task 13 before any commit.
- The Stow fake-home simulation (Task 8) must succeed before the real Stow step (Task 9).
- The `git:bootstrap:dry-run` (Task 10) must be reviewed before `git:bootstrap` (Task 11).
- Builder must NOT execute Tasks 9 or 11. Those are local machine setup steps, not repository implementation steps. Repository implementation is complete when all files listed in the Files Affected Summary (excluding `~/` paths) are committed.

---

## Rollback Strategy

**Per-task rollback:** Each task above includes a specific rollback note.

**Full plan rollback (before any manual steps):**

```bash
git checkout -- \
  stow/common/zsh/.config/zsh/shared.zsh \
  .gitignore \
  Taskfile.yml

git checkout -- \
  stow/common/git/.gitconfig.example \
  stow/common/git/.gitignore_global.example

git restore --staged \
  stow/common/git/.config/git/config-common \
  stow/common/git/.config/git/aliases \
  stow/common/git/.config/git/ignore

rm -f docs/decisions/0024-*.md
rm -f docs/decisions/0025-*.md
rm -f docs/decisions/0026-*.md
rm -f docs/decisions/0027-*.md
rm -f docs/guides/git-setup.md
```

**After Task 9 (Stow) rollback:**

```
⚠️  MANUAL STEP
stow --dir=stow/common --target="$HOME" --delete git
```

**After Task 11 (bootstrap) rollback:**

```bash
# Restore from the timestamped backup created by git:bootstrap
cp ~/.gitconfig.bak.TIMESTAMP ~/.gitconfig
# Replace TIMESTAMP with the actual value printed during Task 11
```

**Zsh layer rollback (if shell misbehaves):**

```
Edit ~/.zshrc and comment out the guarded managed block:
# >>> dotfiles managed (zsh) — added manually; delete this block to disable >>>
[[ -r "$HOME/.config/zsh/index.zsh" ]] && source "$HOME/.config/zsh/index.zsh"
# <<< dotfiles managed (zsh) <<<
Open a new shell — managed layer is inert immediately.
```

---

## Completion Criteria

- [ ] `shared.zsh` contains `export EDITOR="nvim"` and `export PAGER="less"` — no `YOUR_*` tokens.
- [ ] `zsh -n stow/common/zsh/.config/zsh/shared.zsh` exits 0 with no output.
- [ ] `stow/common/git/.config/git/config-common` exists and is committed with no `[user]` or `[alias]` section.
- [ ] `stow/common/git/.config/git/aliases` exists and is committed; all aliases pass the safety audit (no `force`, `hard`, `purge`, `nuke`, `svn`, `filter-branch`, `daemon`, `master` patterns across the full alias set).
- [ ] `stow/common/git/.config/git/ignore` exists and is committed with portable ignore patterns.
- [ ] `stow/common/git/.gitconfig.example` is removed from git tracking.
- [ ] `stow/common/git/.gitignore_global.example` is removed from git tracking.
- [ ] Root `.gitignore` no longer contains entries for `stow/common/git/.gitconfig.common` or `stow/common/git/.gitignore_global`.
- [ ] `Taskfile.yml` contains `git:bootstrap:dry-run` and `git:bootstrap` tasks.
- [ ] `git:bootstrap:dry-run` task modifies no files.
- [ ] `git:bootstrap` task is idempotent — a second run produces only "skip" lines.
- [ ] ADR-0024 through ADR-0027 exist under `docs/decisions/`.
- [ ] `docs/guides/git-setup.md` exists and covers all ten sections required by ADR-0028.
- [ ] Privacy audit (Task 13) passes: all six audit commands produce no output.
- [ ] Privacy audit uses the comment-ignoring grep form (strips `#` comment lines before matching `[user]` and similar patterns).
- [ ] Fake-home Stow simulation (Task 8) shows three symlink creation lines with no conflicts.
- [ ] After manual steps: `~/.config/git/` contains three symlinks into the repository.
- [ ] After manual steps: `git config --global --get-all include.path | sort | uniq -d` produces no output.
- [ ] After manual steps: `git config --global core.excludesfile` prints `~/.config/git/ignore`.
- [ ] After manual steps: `git config --show-origin user.name` attributes to `~/.gitconfig`, not to any managed file.
- [ ] `~/.zshrc` modification timestamp is unchanged throughout this plan.

---

## Follow-Up Items (Out of Scope for This Plan)

- `docs/guides/zsh-setup.md` — required by ADR-0028 (Zsh also has manual activation steps: the user must add the guarded include block to `~/.zshrc`). This guide is out of scope for this plan and must be created in a separate documentation task or PR.

---

## Change Summary

The following corrections were applied to the original plan. Each correction addresses one or more blockers identified in review 0030.

### Correction 1 — ADR numbering and ADR-0028 acknowledgement (Blocker: ADR numbering)
Updated the Assumptions section to confirm that ADR-0024–0027 are not yet created (available), that ADR-0028 already exists and is Accepted, and that ADR-0028 makes `docs/guides/git-setup.md` a mandatory deliverable for this plan. No renumbering was needed — 0024–0027 remain the target numbers.

### Correction 2 — Working tree state mismatch (Blocker: scope misalignment with repository state)
Old Task 2 ("Create the Git Stow package directory structure") removed — the directory already exists.

Old Tasks 3, 4, 5 ("Create config-common / aliases / ignore") rewritten as Tasks 2, 3, 4 ("Audit and verify config-common / aliases / ignore"). The new tasks describe checking current state, reviewing content, noting differences between the plan's original specified content and the actual file content, verifying against safety rules, and staging — not creating from scratch.

Key differences discovered between the plan's original specified content and the actual files:
- `config-common` uses `editor = vim` (not `nvim`) and has additional sections (`[rerere]`, `[push]`, `[color "branch"]`, `[color "diff"]`, `[color "status"]`, `[difftool]`) — all safe, kept as-is.
- `aliases` has 100+ aliases (not four) — all pass safety audit, kept as-is.
- `ignore` has different pattern set than the plan specified — safe, kept as-is.

Task 5 (remove legacy files) updated to note that `.gitconfig.example` and `.gitignore_global.example` are already deleted in the working tree and only need to be staged.

Rollback strategy updated: uses `git restore --staged` for the git config files (since they are existing untracked files, not newly created files).

### Correction 3 — Missing Git human setup guide (Blocker: ADR-0028 compliance)
Added Task 18: Write `docs/guides/git-setup.md`. The task specifies all ten sections required by ADR-0028 in order, lists all required guide rules (unmanaged `~/.gitconfig`, no symlink, preserve existing content, backup before bootstrap, forbid `stow --adopt`, mark all `$HOME`-modifying commands). Updated Files Affected Summary and Completion Criteria to include the guide.

### Correction 4 — Alias scope mismatch (Review NOTE)
Updated the Alias Safety Rules section to state that the actual aliases file contains a comprehensive safe alias set. Removed the claim of "exactly four aliases" as the expected output. Updated Task 3 to validate all aliases in the file using the same safety audit grep (not a predefined short list). Added note clarifying why `reset --mixed`, `reset --soft`, and non-force `push` aliases are acceptable.

### Correction 5 — Grep false positives for comment lines (Review NOTE)
Updated privacy audit grep in Task 13 (pre-commit audit) and within individual task validation steps to use the comment-ignoring form:
```bash
grep -v '^[[:space:]]*#' <files> | grep -in 'signingkey\|\[user\]\|...'
```
This prevents comments like `# No [user] identity here` from producing false positive matches. Added a completion criteria checkbox confirming the comment-ignoring form is used.

### Correction 6 — Zsh guide follow-up note (Review recommendation)
Added a "Follow-Up Items (Out of Scope for This Plan)" section after Completion Criteria noting that `docs/guides/zsh-setup.md` is also required by ADR-0028 and must be created in a separate task or PR.

### Correction 7 — Builder must not run manual steps (Review lifecycle note)
Updated the Assumptions section with the explicit statement: "Repository implementation is complete when all repository files are committed. Manual real-home steps (Tasks 9 and 11) are local machine setup steps, not repository implementation steps. Builder must not execute Tasks 9 or 11." Added corresponding note to the Safety Checks section.

### Correction 8 — Status remains Draft
Status left as `**Status:** Draft` — unchanged.

### Task renumbering
Due to the removal of old Task 2 (directory creation) and the addition of Task 18 (git-setup.md guide), all subsequent task numbers shifted. Old tasks 3–18 became tasks 2–17, and the new guide task is Task 18. All internal cross-references to task numbers were updated accordingly.

### Open questions
None remaining from the review blockers. The alias content question (keep comprehensive set vs. minimal four) is resolved: keep the comprehensive set. The ADR numbering question is resolved: 0024–0027 are available, 0028 exists and is referenced. The guide requirement is now addressed by Task 18.
