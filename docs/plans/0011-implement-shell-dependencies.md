# Plan: Implement Shell Dependency Management

**Number:** 0011
**Status:** Complete
**Date:** 2026-06-17
**PRD:** 0006-shell-dependencies.md
**Architecture:** 0006-shell-dependencies-architecture.md
**Review:** 0019-shell-dependencies-prd-architecture-review.md

---

## Objective

Create the macOS Brewfile manifests, the zsh dependency checker script, three ADR records, and the Taskfile `deps:` namespace — giving the repository a safe, declarative, non-installing dependency management layer for shell tooling.

---

## Assumptions

- PRD 0006 and Architecture 0006 are approved before this plan is executed.
- `packages/macos/` does not yet exist (deferred per ADR-0010; PRD 0006 lifts that deferral).
- `scripts/check-zsh-deps.sh` does not yet exist.
- `Taskfile.yml` currently has four flat tasks: `detect`, `check`, `list`, `dry-run`.
- `scripts/detect-os.sh` exists and works — `check-zsh-deps.sh` will reuse its detection logic.
- `scripts/check.sh` exists and covers core tooling (`stow`, `git`, `task`) — `check-zsh-deps.sh` covers the shell tier only and does not replace it.
- No Homebrew `brew bundle` command is run during implementation.
- No package is installed during implementation.
- No file outside the repository is created or modified.
- No Stow command is run (fake-home `--simulate` excluded from this plan — not needed here since no Stow packages are created).
- ADR numbers 0018, 0019, 0020 are available (last ADR in `docs/decisions/` is 0017).

---

## Ordered Tasks

### Task 1 — Create `packages/macos/` directory scaffold

Create the directory and three Brewfile manifests. The directory contains only package-list files — never stowed into `$HOME`.

**Files to create:**

`packages/macos/Brewfile.core`

```ruby
# macOS — core repository prerequisites
# Install: brew bundle --file=packages/macos/Brewfile.core
#
# These tools are required to manage this dotfiles repository.
# Also checked by: scripts/check.sh

brew "git"
brew "stow"
brew "go-task", tap: "go-task/tap"
```

`packages/macos/Brewfile.shell`

```ruby
# macOS — zsh shell runtime dependencies
# Install: brew bundle --file=packages/macos/Brewfile.shell
#
# These tools are expected by the managed zsh configuration.
# Check status: task deps:check:zsh
#
# Note: zinit is NOT listed here. It is installed via a one-time manual git clone.
# See: docs/shell-dependencies.md

brew "fzf"
brew "zoxide"
brew "eza"
brew "oh-my-posh", tap: "jandedobbeleer/oh-my-posh"
```

`packages/macos/Brewfile.optional`

```ruby
# macOS — optional extras
# Install: brew bundle --file=packages/macos/Brewfile.optional
#
# Not required for a working shell. Add tools here as needed.
# This file is intentionally empty — contents are deferred.
```

**Validation:**

```bash
ls -1 packages/macos/
# Expected: Brewfile.core  Brewfile.shell  Brewfile.optional

# Syntax-check: brew bundle list is read-only (lists what would be managed)
brew bundle list --file=packages/macos/Brewfile.core
brew bundle list --file=packages/macos/Brewfile.shell
brew bundle list --file=packages/macos/Brewfile.optional
```

---

### Task 2 — Create `scripts/check-zsh-deps.sh`

Read-only checker for the shell tier. Same `PASS`/`FAIL` format as `scripts/check.sh`. Detects `zinit` by directory, not `$PATH`. Prints OS-detected install hints on failure without executing them.

**File to create:**

`scripts/check-zsh-deps.sh`

```bash
#!/usr/bin/env bash
# Usage: bash scripts/check-zsh-deps.sh
# Checks that zsh shell-tier dependencies are installed.
# Prints PASS/FAIL per tool. Exits 1 if any required tool is missing.
# Never installs anything. Read-only.
#
# For core repo tooling (git, stow, task), run: bash scripts/check.sh

set -uo pipefail

FAILED=0

# --- Detect OS for install hints ---
if [[ "$OSTYPE" == "darwin"* ]]; then
  OS="macos"
elif [[ -f /etc/arch-release ]]; then
  OS="arch"
else
  OS="unknown"
fi

hint_install() {
  local tool="$1"
  if [[ "$OS" == "macos" ]]; then
    echo "  → Install hint (macOS): brew bundle --file=packages/macos/Brewfile.shell"
  elif [[ "$OS" == "arch" ]]; then
    echo "  → Install hint (Arch): install via pacman or AUR — see docs/shell-dependencies.md"
  else
    echo "  → Install hint: see docs/shell-dependencies.md"
  fi
}

hint_zinit() {
  echo "  → Install hint: one-time manual clone — see docs/shell-dependencies.md"
  echo "    git clone https://github.com/zdharma-continuum/zinit.git \\"
  echo "      \"\${XDG_DATA_HOME:-\$HOME/.local/share}/zinit/zinit.git\""
}

# --- Check shell-tier tools ---

for tool in fzf zoxide eza oh-my-posh; do
  if command -v "$tool" >/dev/null 2>&1; then
    echo "PASS: $tool"
  else
    echo "FAIL: $tool (not installed)"
    hint_install "$tool"
    FAILED=1
  fi
done

# --- Check zinit (not a $PATH binary — check install directory) ---
ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
if [[ -f "${ZINIT_HOME}/zinit.zsh" ]]; then
  echo "PASS: zinit"
else
  echo "FAIL: zinit (not found at ${ZINIT_HOME})"
  hint_zinit
  FAILED=1
fi

exit "${FAILED}"
```

**Validation:**

```bash
# Syntax check — must produce no errors
bash -n scripts/check-zsh-deps.sh

# Confirm script is read-only (no brew/git/network calls in the source)
grep -E 'brew |git clone|curl|wget|pip|npm|cargo' scripts/check-zsh-deps.sh
# Expected: no output (those strings must not appear outside of comments/hints)

# Run the checker — expected output depends on what is installed; exit code is the signal
bash scripts/check-zsh-deps.sh
# PASS for each installed tool; FAIL with hint for each missing tool

# Confirm executable permission will be set
ls -l scripts/check-zsh-deps.sh
```

> Note: The grep above checks the live code path. Install hints print `brew bundle ...` as a string (an `echo` argument), which is acceptable — the script never executes it.

---

### Task 3 — Add `deps:` namespace tasks to `Taskfile.yml`

Extend `Taskfile.yml` with two non-mutating tasks. Neither task installs anything.

- `deps:check:zsh` — runs `scripts/check-zsh-deps.sh` (read-only).
- `deps:macos:shell` — prints the manual install commands; exits without executing them.

**File to modify:** `Taskfile.yml`

Append the following tasks to the existing file:

```yaml
  deps:check:zsh:
    desc: "Check zsh shell-tier dependencies (fzf, zoxide, eza, oh-my-posh, zinit) — read-only, never installs"
    cmds:
      - bash scripts/check-zsh-deps.sh

  deps:macos:shell:
    desc: "Print manual install commands for macOS zsh shell dependencies — prints only, does not install"
    cmds:
      - |
        echo ""
        echo "Shell dependency install commands (macOS)"
        echo "=========================================="
        echo ""
        echo "Step 1 — Install Homebrew-managed shell tools:"
        echo ""
        echo "  ⚠️  MANUAL STEP — review before running"
        echo "  brew bundle --file=packages/macos/Brewfile.shell"
        echo ""
        echo "Step 2 — Install zinit (one-time manual clone):"
        echo ""
        echo "  ⚠️  MANUAL STEP — review before running"
        echo "  git clone https://github.com/zdharma-continuum/zinit.git \\"
        echo "    \"\${XDG_DATA_HOME:-\$HOME/.local/share}/zinit/zinit.git\""
        echo ""
        echo "Step 3 — Verify:"
        echo ""
        echo "  task deps:check:zsh"
        echo ""
```

**Validation:**

```bash
# List all tasks — new tasks must appear
task --list
# Expected lines include:
#   deps:check:zsh    Check zsh shell-tier dependencies ...
#   deps:macos:shell  Print manual install commands ...

# Run the check task (read-only)
task deps:check:zsh

# Run the print task — must print commands and exit, never install
task deps:macos:shell
# Expected: prints commands with ⚠️  MANUAL STEP markers, exits 0, no packages installed
```

---

### Task 4 — Write ADR-0018: Brewfile categories are an evolving per-PRD set

**File to create:** `docs/decisions/0018-brewfile-categories-evolving-per-prd.md`

```markdown
# Decision: Brewfile Categories Are an Evolving, Per-PRD Set

**Number:** 0018
**Date:** 2026-06-17
**Status:** Accepted
**PRD:** 0006-shell-dependencies
**Architecture:** 0006-shell-dependencies-architecture

## Context

ADR-0007 introduced split Brewfiles under `packages/macos/` and listed illustrative
categories: `core`, `cli`, `dev`, `gui`, `optional`. PRD 0006 scopes shell dependencies
and requires a `shell` category that maps 1:1 to zsh runtime needs. The `shell`
category does not appear in ADR-0007's illustrative list, which could appear to
contradict that ADR.

## Decision

ADR-0007's category list is **illustrative and non-exhaustive**, not a closed
enumeration. Brewfile categories are defined per-PRD as new dependency scopes are
introduced. Each category requires a PRD that explicitly scopes it before the file
is created.

For PRD 0006, the categories in use are:

- `Brewfile.core` — repository prerequisites (`git`, `stow`, `go-task`)
- `Brewfile.shell` — zsh shell runtime tools (`fzf`, `zoxide`, `eza`, `oh-my-posh`)
- `Brewfile.optional` — optional extras (placeholder; contents deferred)

Future categories (e.g. `Brewfile.cli`, `Brewfile.dev`, `Brewfile.gui`) may be added
when a PRD scopes them. No Brewfile is created without an authorizing PRD.

## Consequences

- ADR-0007 and ADR-0018 are consistent: ADR-0007 established the split-by-category
  principle; ADR-0018 clarifies the category set is open and evolves per-PRD.
- The `shell` category is not a renamed `cli` — it is a dedicated tier for zsh
  runtime tools, with a 1:1 mapping to `check-zsh-deps.sh`.
- Adding any new category still requires a PRD — the per-PRD gate is unchanged.
```

**Validation:**

```bash
ls docs/decisions/0018-brewfile-categories-evolving-per-prd.md
cat docs/decisions/0018-brewfile-categories-evolving-per-prd.md | head -5
# Expected: file exists, header correct
```

---

### Task 5 — Write ADR-0019: `deps:` Taskfile tasks are non-mutating

**File to create:** `docs/decisions/0019-deps-taskfile-tasks-non-mutating.md`

```markdown
# Decision: `deps:` Taskfile Tasks Are Non-Mutating (Check and Print Only)

**Number:** 0019
**Date:** 2026-06-17
**Status:** Accepted
**PRD:** 0006-shell-dependencies
**Architecture:** 0006-shell-dependencies-architecture

## Context

ADR-0009 establishes that the foundation-phase Taskfile contains only read-only and
`--simulate` tasks. Adding a mutating task (one that installs, removes, or modifies
the system) requires a new PRD that explicitly lifts this restriction.

PRD 0006 introduces two new Taskfile tasks in the `deps:` namespace:
`deps:check:zsh` and `deps:macos:shell`. The question is whether either task should
execute `brew bundle` to perform an actual install.

## Decision

Both `deps:` tasks are **non-mutating**:

- `deps:check:zsh` runs `scripts/check-zsh-deps.sh` — read-only, reports tool
  presence/absence, exits non-zero if any required tool is missing.
- `deps:macos:shell` **prints** the `brew bundle` and `git clone` commands with
  `⚠️  MANUAL STEP` markers and exits. It does not execute them.

PRD 0006 operates entirely within ADR-0009's mutation ban — it does not lift it.

If a genuinely executing install task is needed in future, that requires a separate
PRD and a separate ADR explicitly lifting the mutation restriction.

## Consequences

- No Taskfile task can install packages or clone repositories.
- The user always sees and approves the exact install command before running it.
- The Check/Install/Activate split (Architecture 0006) is preserved in the Taskfile
  interface: tasks stay on the Check side of the line.
- ADR-0009's safety boundary is unchanged and remains the default.
```

**Validation:**

```bash
ls docs/decisions/0019-deps-taskfile-tasks-non-mutating.md
cat docs/decisions/0019-deps-taskfile-tasks-non-mutating.md | head -5
```

---

### Task 6 — Write ADR-0020: Zinit installed via manual clone, never auto-cloned

**File to create:** `docs/decisions/0020-zinit-manual-clone-never-auto-cloned.md`

```markdown
# Decision: Zinit Installed via Documented Manual Clone; Never Auto-Cloned from Shell Startup

**Number:** 0020
**Date:** 2026-06-17
**Status:** Accepted
**PRD:** 0006-shell-dependencies
**Architecture:** 0006-shell-dependencies-architecture

## Context

`zinit` is a zsh plugin manager. Its canonical upstream install is a `git clone`
into `${ZINIT_HOME}`. The upstream-suggested pattern includes an auto-clone block
in `~/.zshrc` that clones zinit on first run if it is not present.

This auto-clone pattern is explicitly rejected by PRD 0006 and Architecture 0006
(Architecture Decision 6) for these reasons:

- Shell startup latency: a `git clone` on first run is slow and blocks shell open.
- Network dependency: shell startup must work offline.
- Silent mutation: a clone is a system change the user should approve and see.
- Non-determinism: auto-clone pulls "latest" at an unpredictable time, causing drift
  between machines.
- Error blast radius: a failing clone in `~/.zshrc` can wedge every new shell.

## Decision

`zinit` is installed via a **documented one-time manual `git clone`** that the user
runs deliberately. The zsh config only **sources** zinit behind a directory-existence
guard and never clones it.

Install command (user-run, one time per machine):

```bash
git clone https://github.com/zdharma-continuum/zinit.git \
  "${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
```

Zsh activation guard (in the managed zsh config — never clones):

```zsh
ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
[[ -f "${ZINIT_HOME}/zinit.zsh" ]] && source "${ZINIT_HOME}/zinit.zsh"
```

`zinit` does not appear in any Brewfile. Detection in `scripts/check-zsh-deps.sh`
checks for the install directory, not a `$PATH` binary.

## Consequences

- Shell startup never performs network operations, package installs, or clones.
- A machine without zinit gets a clean shell — the guard is a no-op.
- The install step is explicit, visible, and user-approved (one-time).
- Plugin management via zinit is deferred to the zsh implementation phase (out of
  scope for PRD 0006 / Plan 0011).
- If zinit moves to a Homebrew formula or AUR package in future, the decision can be
  revisited with a new ADR.
```

**Validation:**

```bash
ls docs/decisions/0020-zinit-manual-clone-never-auto-cloned.md
cat docs/decisions/0020-zinit-manual-clone-never-auto-cloned.md | head -5
```

---

### Task 7 — Create `docs/shell-dependencies.md`

Resolves Architecture Open Question 3. A dedicated user-facing reference for shell dependency setup — separate from `docs/stow-usage.md` since the content covers tool installation, not Stow symlinks.

**File to create:** `docs/shell-dependencies.md`

Content must cover:
- What this doc is for (shell dependency setup, not Stow).
- The check → install → verify flow.
- macOS install steps: `brew bundle` per tier + zinit manual clone, each marked `⚠️  MANUAL STEP`.
- Arch install steps: placeholder pointing to future Arch PRD.
- Tool-by-tool quick reference (tier, macOS source, Arch status).
- `brew bundle cleanup --dry-run` for macOS cleanup.
- A note that `task deps:check:zsh` is the check entry point and `task deps:macos:shell` prints install commands.

**Validation:**

```bash
ls docs/shell-dependencies.md

# No secrets, real paths, or credentials
grep -iE 'password|token|secret|api.key' docs/shell-dependencies.md
# Expected: no output

# All install examples use MANUAL STEP markers
grep -c 'MANUAL STEP' docs/shell-dependencies.md
# Expected: ≥ 2 (one for brew bundle, one for zinit clone)
```

---

### Task 8 — Update `docs/stow-usage.md` with a zsh deps cross-reference

Add a short cross-reference note to the existing "Zsh package adoption" section pointing users to `docs/shell-dependencies.md` for tool installation before stowing. This is a one- or two-sentence addition — not a content rewrite.

**File to modify:** `docs/stow-usage.md`

Location: the start of the "Zsh package adoption" section, before Step 1.

Addition:

```
Before stowing the zsh package, ensure all shell-tier dependencies are installed.
See [docs/shell-dependencies.md](shell-dependencies.md) for the check and install steps.
```

**Validation:**

```bash
grep -n 'shell-dependencies' docs/stow-usage.md
# Expected: shows the cross-reference line in the zsh adoption section
```

---

### Task 9 — Final self-check: confirm no $HOME changes, no installs, no secrets

After all tasks are complete, verify the full change set is clean before presenting to the Reviewer.

**Validation:**

```bash
git status
# Expected: only files under docs/, scripts/, packages/, Taskfile.yml — nothing under $HOME

git diff --stat
# Confirm only expected files appear

# No secrets in staged/changed files
git diff | grep -iE 'password|token|api.key|private.key|secret'
# Expected: no output

# Confirm no brew, pacman, or network commands run automatically in any new script
grep -E '^(brew|pacman|paru|yay|curl|wget|git clone)' scripts/check-zsh-deps.sh
# Expected: no output (those commands are only inside echo strings)

# Confirm Brewfiles contain no private taps or credentials
grep -iE 'token|secret|password|@.*\.git' packages/macos/Brewfile.*
# Expected: no output
```

---

## Files Affected

| File | Action |
|---|---|
| `packages/macos/Brewfile.core` | created |
| `packages/macos/Brewfile.shell` | created |
| `packages/macos/Brewfile.optional` | created |
| `scripts/check-zsh-deps.sh` | created |
| `Taskfile.yml` | modified — two tasks added |
| `docs/decisions/0018-brewfile-categories-evolving-per-prd.md` | created |
| `docs/decisions/0019-deps-taskfile-tasks-non-mutating.md` | created |
| `docs/decisions/0020-zinit-manual-clone-never-auto-cloned.md` | created |
| `docs/shell-dependencies.md` | created |
| `docs/stow-usage.md` | modified — one cross-reference line added |

No files deleted. No files under `stow/` or `$HOME` touched.

---

## Safety Checks

- [ ] `packages/macos/` contains only Brewfile text manifests — no executable scripts.
- [ ] `scripts/check-zsh-deps.sh` contains no `brew`, `git clone`, `curl`, `wget`, or other network/mutating commands in its execution path (hints are inside `echo` strings only).
- [ ] `Taskfile.yml` `deps:macos:shell` uses only `echo` — no `brew bundle` call is executed.
- [ ] No file outside the repository is created or modified.
- [ ] No `stow`, `stow --adopt`, `rm`, `mv`, or `ln -s` targeting `$HOME` is run.
- [ ] No package is installed during implementation.
- [ ] No `brew bundle` is executed during implementation (only `brew bundle list` for validation — read-only).
- [ ] All dangerous install commands in documentation are preceded by `⚠️  MANUAL STEP`.

---

## Privacy Checks

- [ ] Brewfiles contain only public formula/cask/tap names — no private taps, no credentials.
- [ ] `scripts/check-zsh-deps.sh` uses `$HOME`/`$XDG_DATA_HOME` — no hardcoded paths, no usernames.
- [ ] `docs/shell-dependencies.md` uses placeholder patterns and public URLs only.
- [ ] `git diff --staged` shows no tokens, passwords, API keys, or internal hostnames.

---

## Validation Commands

```bash
# --- Task 1 ---
ls -1 packages/macos/
brew bundle list --file=packages/macos/Brewfile.core
brew bundle list --file=packages/macos/Brewfile.shell

# --- Task 2 ---
bash -n scripts/check-zsh-deps.sh
grep -E '^(brew|git clone|curl|wget)' scripts/check-zsh-deps.sh  # expect no output
bash scripts/check-zsh-deps.sh  # shows PASS/FAIL per tool

# --- Task 3 ---
task --list
task deps:check:zsh
task deps:macos:shell  # must print commands only, exit 0

# --- Tasks 4–6 ---
ls docs/decisions/0018-brewfile-categories-evolving-per-prd.md
ls docs/decisions/0019-deps-taskfile-tasks-non-mutating.md
ls docs/decisions/0020-zinit-manual-clone-never-auto-cloned.md

# --- Task 7 ---
ls docs/shell-dependencies.md
grep -c 'MANUAL STEP' docs/shell-dependencies.md  # expect ≥ 2
grep -iE 'password|token|secret|api.key' docs/shell-dependencies.md  # expect no output

# --- Task 8 ---
grep -n 'shell-dependencies' docs/stow-usage.md  # expect cross-ref line

# --- Task 9 (final) ---
git status
git diff | grep -iE 'password|token|api.key|private.key|secret'  # expect no output
```

---

## Rollback Strategy

All changes are text files inside the repository. Rollback is simple git revert:

```bash
# Undo all uncommitted changes
git checkout -- Taskfile.yml
git checkout -- docs/stow-usage.md
git rm --cached packages/macos/Brewfile.core packages/macos/Brewfile.shell packages/macos/Brewfile.optional
git rm --cached scripts/check-zsh-deps.sh
git rm --cached docs/decisions/0018-brewfile-categories-evolving-per-prd.md
git rm --cached docs/decisions/0019-deps-taskfile-tasks-non-mutating.md
git rm --cached docs/decisions/0020-zinit-manual-clone-never-auto-cloned.md
git rm --cached docs/shell-dependencies.md
```

Or, if already committed:

```bash
git revert HEAD
```

No `$HOME` changes were made, so there is nothing to undo outside the repository.

---

## Completion Criteria

- [ ] `packages/macos/Brewfile.core` exists and lists `git`, `stow`, `go-task`.
- [ ] `packages/macos/Brewfile.shell` exists and lists `fzf`, `zoxide`, `eza`, `oh-my-posh` (no zinit).
- [ ] `packages/macos/Brewfile.optional` exists as a documented placeholder.
- [ ] `scripts/check-zsh-deps.sh` exists, is read-only (no mutation), passes `bash -n`.
- [ ] `task deps:check:zsh` runs the checker and exits non-zero if any tool is missing.
- [ ] `task deps:macos:shell` prints install commands with `⚠️  MANUAL STEP` markers and installs nothing.
- [ ] `task --list` shows both new tasks with correct descriptions.
- [ ] ADR-0018, ADR-0019, ADR-0020 exist under `docs/decisions/`.
- [ ] `docs/shell-dependencies.md` exists and covers check, install, verify flow for macOS and Arch (future).
- [ ] `docs/stow-usage.md` zsh adoption section references `docs/shell-dependencies.md`.
- [ ] No package was installed during implementation.
- [ ] No file outside the repository was modified.
- [ ] Reviewer has reviewed and found no blocking issues.
