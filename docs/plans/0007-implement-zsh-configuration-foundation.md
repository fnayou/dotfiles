# Plan: Implement Zsh Configuration Foundation

**Number:** 0007
**Status:** Complete
**Date:** 2026-06-17
**PRD:** [0004-zsh-configuration](../prd/0004-zsh-configuration.md)
**Architecture:** [0004-zsh-configuration-architecture](../architecture/0004-zsh-configuration-architecture.md)
**Review:** [0009-zsh-prd-architecture-review](../reviews/0009-zsh-prd-architecture-review.md)

---

## Objective

Produce the `stow/common/zsh/.config/zsh/` package with three placeholder-only `.example` files, a directory-level `.gitignore` protecting the real (filled-in) files, the architecture-proposed ADR-0016, and complete adoption documentation in `docs/stow-usage.md` — without modifying any file outside the repository root, without inspecting or copying the user's real `~/.zshrc`, without creating symlinks, and without running any Stow install command.

This is a **template-first** foundation. It does not configure, optimize, or activate zsh. No plugin manager or framework is introduced.

---

## Assumptions

- Repository is on a feature branch (not `main`).
- `git status` is clean or all uncommitted changes are understood.
- `git`, `stow`, and `task` (go-task) are installed on the dev machine.
- PRD 0004, Architecture 0004, and Review 0009 are complete (verdict: APPROVED).
- Plans 0001–0006 exist; 0007 is the next available number.
- ADRs 0001–0015 exist; 0016 is the next available ADR number.
- `stow/common/zsh/` does not yet exist.
- `docs/stow-usage.md` exists and must be updated, not replaced.
- No `stow install` command will be run at any point in this plan.
- The user's `~/.zshrc` is never read, copied, or modified by this plan.

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

# 4. Confirm ADRs 0001–0015 exist and 0016 does not yet exist
ls docs/decisions/
# Must show 0001–0015 and README.md; must NOT show 0016

# 5. Confirm plans 0001–0006 exist and 0007 does not yet exist
ls docs/plans/
# Must show 0001–0006 and README.md; must NOT show 0007

# 6. Confirm the zsh package does not yet exist
ls stow/common/zsh/ 2>/dev/null
# Expected: no such directory

# 7. Confirm stow-usage.md exists and has no zsh section yet
grep -n -i "zsh" docs/stow-usage.md
# Must return empty (or only incidental references)
```

All seven checks must pass. Stop and resolve any failure before proceeding.

---

## Proposed Package Layout

```
stow/
└── common/
    └── zsh/
        └── .config/
            └── zsh/
                ├── .gitignore             # Ignores real filled-in files; keeps .example tracked
                ├── shared.zsh.example     # Portable cross-platform zsh config (placeholder only)
                ├── macos.zsh.example      # macOS-specific zsh config (placeholder only)
                └── arch.zsh.example       # Arch-specific zsh config (placeholder only)
```

Decision basis (Architecture 0004): single `common` package; runtime OS detection in the user's `~/.zshrc` selects the platform file. No `stow/macos/zsh/` or `stow/arch/zsh/` packages are created. `~/.zshrc` is never managed by Stow.

---

## Ordered Tasks

### Phase 1 — Write ADR-0016

#### Task 1 — Create `docs/decisions/0016-zsh-common-package-runtime-os-detection.md`

**Files affected:**
- `docs/decisions/0016-zsh-common-package-runtime-os-detection.md` — new

**What to do:**

Write the ADR proposed by Architecture 0004. Follow the format of existing ADRs (`0013`, `0014`). Required sections: Context, Decision, Consequences, Status.

Content must record:

- **Context:** Zsh config spans portable, macOS-only, and Arch-only logic. `~/.config/zsh/` is the same path on both platforms. ADR-0001 common-package criteria are satisfied (same path, same structure, no platform tool at package level).
- **Decision:** Place all three zsh files (`shared.zsh`, `macos.zsh`, `arch.zsh`) in a single `stow/common/zsh/` package. Platform selection happens at runtime via OS detection (`$OSTYPE`, `/etc/arch-release`) in the user's `~/.zshrc` source block. `~/.zshrc` is never stowed. `$ZDOTDIR` is not set (deferred — see Architecture Decision 4).
- **Consequences:** One Stow invocation per machine. `arch.zsh` is symlinked on macOS and vice versa (unused, harmless, not sourced). Adding a third platform = add one file + one `elif` branch.
- **Status:** Accepted.

**Validation:**

```bash
ls docs/decisions/0016-*.md
grep -n "Status" docs/decisions/0016-*.md   # Must show: Accepted
```

---

### Phase 2 — Create the Zsh Package Scaffold

#### Task 2 — Create the package directory tree

**Files affected:**
- `stow/common/zsh/.config/zsh/` — new directory tree (created implicitly by writing files into it)

**What to do:**

Create the directory path `stow/common/zsh/.config/zsh/` by writing the files in Tasks 3–6 into it. Do not create any `.gitkeep` — the `.example` files and `.gitignore` populate the directory.

**Validation:**

```bash
test -d stow/common/zsh/.config/zsh && echo "OK: package dir exists"
```

---

#### Task 3 — Create `stow/common/zsh/.config/zsh/shared.zsh.example`

**Files affected:**
- `stow/common/zsh/.config/zsh/shared.zsh.example` — new

**What to do:**

Create the portable, cross-platform zsh layer. Placeholder values only. No plugin manager, no framework, no prompt theme. Restrict to portable, broadly-safe defaults documented in Architecture 0004 (Shared Zsh Logic).

Required contents (structure, not optimization):

```zsh
# shared.zsh.example — portable zsh config (macOS + Arch)
# Copy to shared.zsh, review, then stow. Do NOT stow this .example directly.
# All YOUR_* tokens are literal placeholders, not shell variables.

# --- XDG base directories ---
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

# --- Portable environment ---
# Replace YOUR_EDITOR / YOUR_PAGER with your preferred tools (e.g. vim, less).
export EDITOR="YOUR_EDITOR"
export PAGER="YOUR_PAGER"

# --- History ---
export HISTFILE="$XDG_STATE_HOME/zsh/history"   # adjust if XDG_STATE_HOME unset
export HISTSIZE=10000
export SAVEHIST=10000
setopt HIST_IGNORE_DUPS
setopt SHARE_HISTORY

# --- Shell options (portable) ---
setopt AUTO_CD

# --- Completion ---
autoload -Uz compinit && compinit

# --- Portable aliases (flags valid on both BSD and GNU) ---
alias grep='grep --color=auto'

# NOTE: No Homebrew, pacman/yay, pbcopy/open, systemctl, plugin manager,
# or prompt theme here. Those belong in macos.zsh / arch.zsh or a later phase.
```

> If `XDG_STATE_HOME` handling adds risk, the implementer may default `HISTFILE` to `$HOME/.zsh_history` with a comment. Keep it simple and portable.

**Validation:**

```bash
# Must contain only placeholders, no forbidden platform tokens
grep -n -i "brew\|homebrew\|pacman\|yay\|systemctl\|pbcopy\|/opt/homebrew\|oh-my-zsh\|starship\|zinit\|prezto\|antidote" stow/common/zsh/.config/zsh/shared.zsh.example
# Must return empty
```

---

#### Task 4 — Create `stow/common/zsh/.config/zsh/macos.zsh.example`

**Files affected:**
- `stow/common/zsh/.config/zsh/macos.zsh.example` — new

**What to do:**

Create the macOS-only layer. Placeholder values only. Per Review 0009 (ARCH-L223), the Homebrew placeholder must be explicitly marked as a literal token.

Required contents:

```zsh
# macos.zsh.example — macOS-specific zsh config
# Copy to macos.zsh, review, then stow. Do NOT stow this .example directly.
# Sourced only on macOS (see the ~/.zshrc source block in stow-usage.md).

# --- Homebrew ---
# YOUR_HOMEBREW_PREFIX is a LITERAL placeholder, NOT a shell variable.
# Replace it with /opt/homebrew (Apple Silicon) or /usr/local (Intel).
eval "$(YOUR_HOMEBREW_PREFIX/bin/brew shellenv)"

# --- macOS-specific PATH additions ---
# Replace YOUR_MACOS_TOOL_PATH or delete if unused.
export PATH="YOUR_MACOS_TOOL_PATH:$PATH"

# --- macOS tool aliases (examples; uncomment/edit as needed) ---
# alias o='open'
```

**Validation:**

```bash
# Must not contain Arch tokens
grep -n -i "pacman\|yay\|/etc/arch-release\|systemctl" stow/common/zsh/.config/zsh/macos.zsh.example
# Must return empty

# Must mark YOUR_HOMEBREW_PREFIX as literal placeholder
grep -n "literal placeholder" stow/common/zsh/.config/zsh/macos.zsh.example
# Must return a match
```

---

#### Task 5 — Create `stow/common/zsh/.config/zsh/arch.zsh.example`

**Files affected:**
- `stow/common/zsh/.config/zsh/arch.zsh.example` — new

**What to do:**

Create the Arch-only layer. Placeholder values only.

Required contents:

```zsh
# arch.zsh.example — Arch / EndeavourOS-specific zsh config
# Copy to arch.zsh, review, then stow. Do NOT stow this .example directly.
# Sourced only on Arch (see the ~/.zshrc source block in stow-usage.md).

# --- Arch-specific PATH additions ---
# Replace YOUR_ARCH_TOOL_PATH or delete if unused.
export PATH="YOUR_ARCH_TOOL_PATH:$PATH"

# --- AUR helper alias (example; uncomment/edit as needed) ---
# alias aur='YOUR_AUR_HELPER'   # e.g. yay or paru
```

**Validation:**

```bash
# Must not contain macOS/Homebrew tokens
grep -n -i "brew\|homebrew\|/opt/homebrew\|pbcopy\|pbpaste" stow/common/zsh/.config/zsh/arch.zsh.example
# Must return empty
```

---

#### Task 6 — Create `stow/common/zsh/.config/zsh/.gitignore`

**Files affected:**
- `stow/common/zsh/.config/zsh/.gitignore` — new

**What to do:**

Per Review 0009 (ARCH-L334–340), use a directory-level `.gitignore` to protect the real filled-in files while keeping the `.example` templates tracked.

Required contents:

```gitignore
# Ignore real (filled-in) zsh files; keep .example templates tracked.
shared.zsh
macos.zsh
arch.zsh
```

**Validation:**

```bash
cat stow/common/zsh/.config/zsh/.gitignore
# Must list shared.zsh, macos.zsh, arch.zsh

# Simulate the copy locally (in repo, NOT $HOME) and confirm git ignores it
cp stow/common/zsh/.config/zsh/shared.zsh.example stow/common/zsh/.config/zsh/shared.zsh
git check-ignore stow/common/zsh/.config/zsh/shared.zsh
# Must echo the path (= ignored). Then remove the test copy:
rm stow/common/zsh/.config/zsh/shared.zsh
```

---

### Phase 3 — Documentation

#### Task 7 — Add zsh package section to `docs/stow-usage.md`

**Files affected:**
- `docs/stow-usage.md` — modified (append section, do not replace)

**What to do:**

Per Review 0009 (ARCH-L232), this update is **mandatory**. Append a "Zsh package adoption" section mirroring the existing "Git package adoption" structure. Must document:

1. **Files in this package** — table of the three `.example` files and their copy targets.
2. **Copy step** — copy each `.example` to its real name (paths relative to repository root):

   ```bash
   cp stow/common/zsh/.config/zsh/shared.zsh.example stow/common/zsh/.config/zsh/shared.zsh
   cp stow/common/zsh/.config/zsh/macos.zsh.example  stow/common/zsh/.config/zsh/macos.zsh
   cp stow/common/zsh/.config/zsh/arch.zsh.example   stow/common/zsh/.config/zsh/arch.zsh
   ```

3. **Review step** — replace `YOUR_*` placeholders; confirm no real secrets.
4. **Dry-run step:**

   ```bash
   task dry-run AREA=common PACKAGE=zsh
   ```

   Or directly:

   ```bash
   stow --dir=stow/common --target="$HOME" --simulate zsh
   ```

5. **Stow step** — marked manual:

   ⚠️  MANUAL STEP — review dry-run output before running
   ```bash
   stow --dir=stow/common --target="$HOME" zsh
   ```

6. **`~/.zshrc` source-block step** — user manually appends to their existing `~/.zshrc` (this file is never managed by Stow):

   ```zsh
   # Managed zsh config — sourced from dotfiles
   source "$HOME/.config/zsh/shared.zsh"

   if [[ "$OSTYPE" == "darwin"* ]]; then
     source "$HOME/.config/zsh/macos.zsh"
   elif [[ -f /etc/arch-release ]]; then
     source "$HOME/.config/zsh/arch.zsh"
   fi
   ```

7. **Verify step** — confirm symlinks exist and zsh starts cleanly:

   ```bash
   ls -l ~/.config/zsh/shared.zsh ~/.config/zsh/macos.zsh ~/.config/zsh/arch.zsh
   zsh -ic 'echo zsh-ok'
   ```

Also update the layout tree at the top of `stow-usage.md` to show `zsh/` under `common/`.

**Validation:**

```bash
grep -n -i "Zsh package adoption" docs/stow-usage.md   # Must return a match
grep -n "source-block\|.config/zsh/shared.zsh" docs/stow-usage.md
```

---

#### Task 8 — Update document status fields and cross-links

**Files affected:**
- `docs/prd/0004-zsh-configuration.md` — set Status to Approved
- `docs/architecture/0004-zsh-configuration-architecture.md` — set Status to Accepted; mark ADR-0016 row Status as Accepted
- `docs/plans/README.md` — add 0007 entry
- `docs/decisions/README.md` — add 0016 entry

**What to do:**

Flip statuses now that the chain (PRD → Architecture → Review → Plan) is complete and ADR-0016 exists. Add index entries following existing README conventions.

**Validation:**

```bash
grep -n "Status" docs/prd/0004-zsh-configuration.md
grep -n "ADR-0016" docs/architecture/0004-zsh-configuration-architecture.md
grep -n "0007" docs/plans/README.md
grep -n "0016" docs/decisions/README.md
```

---

## Validation Commands (Full Suite)

Run after all tasks. All read-only except the temporary git-ignore check in Task 6.

```bash
# Package structure
test -d stow/common/zsh/.config/zsh && echo "OK: dir"
ls stow/common/zsh/.config/zsh/
# Expected: .gitignore  shared.zsh.example  macos.zsh.example  arch.zsh.example

# No forbidden framework / plugin-manager tokens anywhere in the package
grep -rn -i "oh-my-zsh\|prezto\|starship\|antidote\|zinit\|zplug\|antigen" stow/common/zsh/
# Must return empty

# Shared layer is platform-clean
grep -n -i "brew\|homebrew\|pacman\|yay\|systemctl\|pbcopy\|open " stow/common/zsh/.config/zsh/shared.zsh.example
# Must return empty

# No real secrets / identity in any file
grep -rn -i "token\|password\|secret\|ssh-rsa\|BEGIN OPENSSH" stow/common/zsh/
# Must return empty

# Only .example files are tracked candidates; real names are ignored
git status --porcelain stow/common/zsh/
# Must NOT list shared.zsh / macos.zsh / arch.zsh (only .example + .gitignore)

# Optional stow dry-run (safe — makes no changes). Requires .example copied first;
# this is a USER step documented in stow-usage.md, NOT run by this plan.
# stow --dir=stow/common --target="$HOME" --simulate zsh
```

---

## Safety Checks

Confirm every item before considering the plan complete:

- [ ] No file outside the repository root was created, modified, or deleted.
- [ ] `~/.zshrc` was never read, copied, opened, or modified.
- [ ] No symlink was created in `$HOME`.
- [ ] No `stow` install command was run. (`--simulate` only, and only if explicitly chosen.)
- [ ] No `stow --adopt` anywhere.
- [ ] No plugin manager or framework (Oh My Zsh, Prezto, Starship, Antidote, Zinit) introduced.
- [ ] No zsh optimization or behavior tuning beyond portable safe defaults.
- [ ] All three config files committed as `.example` only; real names git-ignored.
- [ ] All `YOUR_*` placeholders documented in-file as literal tokens.
- [ ] No secrets, identity, hostnames, or machine-specific paths in any committed file.

---

## Rollback Strategy

This plan only adds files inside the repository. Rollback is fully local and low-risk — `$HOME` is never touched, so there is nothing to unwind there.

### If uncommitted

```bash
# Remove the new package and ADR (review first)
git status
rm -rf stow/common/zsh
rm -f docs/decisions/0016-zsh-common-package-runtime-os-detection.md
rm -f docs/plans/0007-implement-zsh-configuration-foundation.md

# Revert doc edits (stow-usage.md, READMEs, status flips)
git checkout -- docs/stow-usage.md docs/plans/README.md docs/decisions/README.md \
  docs/prd/0004-zsh-configuration.md docs/architecture/0004-zsh-configuration-architecture.md
```

### If committed (not yet pushed)

```bash
git log --oneline -5
git revert <commit-sha>     # or: git reset --hard HEAD~1 on the feature branch
```

### User-side adoption rollback

Not applicable to this plan — adoption (copy, stow, `~/.zshrc` edit) is a later user-driven phase. Its rollback is documented in Architecture 0004 → Rollback Strategy (`stow --delete zsh` + remove the source block from `~/.zshrc`).

---

## Completion Criteria

- [ ] `docs/decisions/0016-zsh-common-package-runtime-os-detection.md` exists, Status: Accepted.
- [ ] `stow/common/zsh/.config/zsh/` contains exactly: `.gitignore`, `shared.zsh.example`, `macos.zsh.example`, `arch.zsh.example`.
- [ ] `.gitignore` ignores `shared.zsh`, `macos.zsh`, `arch.zsh`; `.example` files remain tracked.
- [ ] `shared.zsh.example` contains no platform-specific or framework tokens.
- [ ] `macos.zsh.example` marks `YOUR_HOMEBREW_PREFIX` as a literal placeholder; contains no Arch tokens.
- [ ] `arch.zsh.example` contains no macOS/Homebrew tokens.
- [ ] `docs/stow-usage.md` has a complete "Zsh package adoption" section + updated layout tree.
- [ ] PRD 0004 Status = Approved; Architecture 0004 Status = Accepted; READMEs updated.
- [ ] All full-suite validation commands pass.
- [ ] All Safety Checks ticked.
- [ ] No `$HOME` change, no symlink, no stow install, no framework, no `~/.zshrc` access.

---

## Out of Scope (Reaffirmed)

- Replacing, reading, or copying the user's real `~/.zshrc`.
- Any `$HOME` modification or symlink creation.
- Running `stow` install (`--simulate` only, optional).
- Plugin managers / frameworks (Oh My Zsh, Prezto, Starship, Antidote, Zinit, zplug, antigen).
- Prompt themes, completion tuning, performance optimization.
- Setting `$ZDOTDIR` (deferred — Architecture Decision 4).
- Defining real aliases, functions, or environment values beyond placeholders.
- `chsh` or any default-shell change.
- Terminal emulator config.
