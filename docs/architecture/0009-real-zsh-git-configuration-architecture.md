# Architecture: Real Zsh and Git Configuration Adoption

**Number:** 0009
**Status:** Approved
**Date:** 2026-06-18 (revised 2026-06-18)
**PRD:** [0009-real-zsh-git-configuration.md](../prd/0009-real-zsh-git-configuration.md)

---

## Context

PRDs 0003, 0004, 0006, and 0007 established the structure for managed zsh and Git configuration. All those phases produced scaffolding only: placeholder `.example` files, `.gitignore` guards, the activation wiring, and the `index.zsh` orchestrator. No managed file has yet been filled with real, safe, portable configuration.

The current state entering this architecture:

- `stow/common/zsh/.config/zsh/index.zsh` — tracked, valid source-order logic, no placeholders.
- `stow/common/zsh/.config/zsh/shared.zsh` — tracked, contains `YOUR_EDITOR` and `YOUR_PAGER` placeholders. All structural patterns (XDG, history, tool guards) are already present.
- `stow/common/zsh/.config/zsh/shared.zsh.example` — tracked template for new machines.
- `stow/common/zsh/.config/zsh/index.zsh.example` — tracked template for new machines.
- `stow/common/zsh/.config/zsh/.gitignore` — guards `shared.zsh`, `index.zsh`, `macos.zsh`, `arch.zsh`, `omp.zsh`, `local.zsh`.
- `stow/common/git/.gitconfig.example` — tracked legacy template. Superseded by this revision.
- `stow/common/git/.gitignore_global.example` — tracked legacy template. Superseded by this revision.
- Root `.gitignore` guards `stow/common/git/.gitconfig.common` and `stow/common/git/.gitignore_global` — those paths are now obsolete; root `.gitignore` must be updated.

**Revision note:** The initial draft of this architecture used home-level Git files (`.gitconfig.common`, `.gitignore_global`). This revision adopts an XDG-based layout (`~/.config/git/`) with three committed files (`config-common`, `aliases`, `ignore`) and a Taskfile bootstrap task for wiring. Sections 4–12 below supersede the initial draft entirely.

### Established decisions entering this architecture

- **ADR-0001** — Platform-first Stow layout.
- **ADR-0002** — go-task as task runner. Taskfile.yml already exists at repo root.
- **ADR-0003** — `.example` files for identity-sensitive config.
- **ADR-0009** — Foundation Taskfile restricted to read-only tasks; mutating tasks require new PRD scope.
- **ADR-0012** — `AREA` and `PACKAGE` variables for Stow task interface.
- **ADR-0013** — Include-based Git config strategy. *(superseded in part by Section 5 below — include targets change)*
- **ADR-0016** — All zsh files in `stow/common/zsh/` with runtime OS detection.
- **ADR-0020** — Zinit installed via documented manual clone; never auto-cloned.
- **ADR-0021** — Single guarded `~/.zshrc` include block + `index.zsh` entry point.
- **ADR-0022** — Zsh migration: Model 4 start, Model 3 target.
- **ADR-0023** — `local.zsh` is the git-ignored, last-sourced override slot.

---

## 1. Zsh File Layout

All files live under `stow/common/zsh/.config/zsh/`.

| Filename | Committed | Purpose | Who owns it |
|---|---|---|---|
| `shared.zsh.example` | Yes | Template for new machines; shows full portable structure with `YOUR_*` placeholders | Repository (tracked) |
| `shared.zsh` | Yes — see Section 3 | Portable env, history, options, tool guards, aliases. Currently contains `YOUR_EDITOR` / `YOUR_PAGER` placeholders to be replaced | Repository (tracked, real values to be added) |
| `index.zsh.example` | Yes | Template for new machines; source order only, four guarded lines | Repository (tracked) |
| `index.zsh` | Yes — see Section 3 | Managed entry point; sources shared → platform → omp → local. Currently valid, no placeholders | Repository (tracked) |
| `macos.zsh.example` | Yes | macOS-specific config template | Repository (tracked) |
| `macos.zsh` | No (git-ignored) | Real macOS config — user-local; platform scope deferred per PRD-0009 | User (local only) |
| `arch.zsh.example` | Yes | Arch-specific config template | Repository (tracked) |
| `arch.zsh` | No (git-ignored) | Real Arch config — user-local; platform scope deferred per PRD-0009 | User (local only) |
| `omp.zsh.example` | Yes | Oh My Posh activation template (guarded eval) | Repository (tracked) |
| `omp.zsh` | No (git-ignored) | Real OMP activation — user-local; OMP scope deferred per PRD-0009 | User (local only) |
| `zshrc.example` | Yes | Reference `~/.zshrc` template with the guarded managed include block. Never stowed | Repository (tracked) |
| `local.zsh` | No (git-ignored, no `.example`) | Machine-specific overrides, private values. Sourced last | User (local only, never committed) |
| `.gitignore` | Yes | Guards `shared.zsh`, `index.zsh`, `macos.zsh`, `arch.zsh`, `omp.zsh`, `local.zsh` | Repository (tracked) |

### The no-folding strategy: why `~/.zshrc` is not stowed

The package stows only into `~/.config/zsh/`. If `~/.zshrc` were in the package, Stow would conflict with the user's existing file — requiring `--adopt`, which is forbidden. The include-based activation model (ADR-0021) achieves the same result without touching `~/.zshrc`.

---

## 2. Zsh Content Boundaries

### `shared.zsh` — what belongs here

- XDG base directory exports: `$XDG_CONFIG_HOME`, `$XDG_DATA_HOME`, `$XDG_CACHE_HOME` (`:-` default pattern).
- `$EDITOR` and `$PAGER` exports — real portable values. `YOUR_EDITOR` → `nvim`; `YOUR_PAGER` → `less`.
- History: `$HISTFILE`, `$HISTSIZE`, `$SAVEHIST`, `setopt HIST_IGNORE_DUPS`, `setopt SHARE_HISTORY`.
- Shell options portable on macOS and Arch: `AUTO_CD`.
- Completion: guarded `compinit` block that skips when Zinit is loaded.
- Zinit source guard: `ZINIT_HOME` assignment + `[[ -f "${ZINIT_HOME}/zinit.zsh" ]]`. No clone fallback (ADR-0020).
- Tool integration guards: `command -v <tool> >/dev/null 2>&1 && eval "$(…)"` for `fzf`, `zoxide`; `command -v eza >/dev/null 2>&1 && alias ls='eza'`.
- Portable aliases: `alias grep='grep --color=auto'` and aliases valid on both BSD and GNU.

**Forbidden in `shared.zsh`:**

- Install commands (`brew install`, `pacman -S`, `apt install`).
- Clone commands (`git clone`).
- Network operations.
- Platform-specific calls: `brew`, `pbcopy`, `pbpaste`, `open`; `pacman`, `yay`, `systemctl`.
- Hardcoded absolute paths that differ between platforms.
- Plugin loading beyond the Zinit guard.
- Prompt engine initialization (belongs in `omp.zsh`).

### `index.zsh` — what belongs here

Source order only. No logic, no aliases, no env, no function definitions:

```
1. [[ -r "...shared.zsh" ]] && source
2. OS detection: if darwin → macos.zsh; elif arch-release → arch.zsh
3. [[ -r "...omp.zsh" ]] && source
4. [[ -r "...local.zsh" ]] && source
```

### `local.zsh` — what belongs here

Machine-specific overrides and private values. Sourced last, wins over everything. Git-ignored, never committed, no `.example` template (ADR-0023).

### `macos.zsh` / `arch.zsh` / `omp.zsh` — scope

Scope deferred to a future PRD. Remain `.example`-only committed files for now.

---

## 3. Zsh Tracking Decision

Both `shared.zsh` and `index.zsh` are already tracked in git (established by PRD-0007 implementation). `shared.zsh` contains `YOUR_EDITOR` and `YOUR_PAGER` placeholders; `index.zsh` is already final.

**Decision: replace placeholder tokens in the tracked `shared.zsh` directly (Option A).**

Reasons:
1. `shared.zsh` is already tracked — un-tracking requires `git rm --cached` and adds confusion.
2. Pattern is established: `index.zsh` is tracked with real content.
3. `shared.zsh` content is safe to commit: no identity, no machine-specific path, no secret.
4. `.example` counterpart stays as a new-machine template.

**What "safe to commit" means:** works on both macOS and Arch, no real name/email/hostname/token/key, no machine-specific absolute path, no install/clone/network call.

Replacements: `YOUR_EDITOR` → `nvim`; `YOUR_PAGER` → `less`.

---

## 4. Git File Layout

**Target layout** — all files under `stow/common/git/.config/git/`:

| Filename | Committed | Purpose | Symlink target |
|---|---|---|---|
| `config-common` | Yes | Portable Git settings — no identity, no aliases | `~/.config/git/config-common` |
| `aliases` | Yes | Git aliases only — no identity, no risky or legacy aliases | `~/.config/git/aliases` |
| `ignore` | Yes | Global ignore patterns — macOS, Linux, editor, build artifacts | `~/.config/git/ignore` |

**Files to remove from the repo as part of this adoption:**

| Filename | Status | Action |
|---|---|---|
| `stow/common/git/.gitconfig.example` | Tracked (legacy) | Remove — superseded by new layout |
| `stow/common/git/.gitignore_global.example` | Tracked (legacy) | Remove — superseded by `ignore` |

**Root `.gitignore` entries to remove** (paths no longer exist in new layout):

```
stow/common/git/.gitconfig.common
stow/common/git/.gitignore_global
```

**Identity management:** `user.name` and `user.email` are not managed by the repository. The user configures them manually:

```bash
git config --global user.name "Your Name"
git config --global user.email "your-email@example.com"
```

No `.gitconfig.local.example` is committed. No local identity template is provided.

---

## 5. Git Include Architecture

### Wiring diagram

```
~/.gitconfig           (user-owned, never stowed, never committed)
  [include]
      path = ~/.config/git/config-common  ← symlink → stow/common/git/.config/git/config-common
  [include]
      path = ~/.config/git/aliases        ← symlink → stow/common/git/.config/git/aliases
```

`core.excludesfile = ~/.config/git/ignore` is set inside `config-common`. No separate include needed for `ignore`.

### Include order

Git processes includes in file order; last definition wins. `config-common` first, `aliases` second. Neither contains identity values — order does not affect identity resolution.

Identity (`user.name`, `user.email`, signing) is set directly in `~/.gitconfig` by the user via `git config --global`, not via include.

### Example structure (placeholder values only)

`~/.gitconfig` (user-owned, after manual setup):

```gitconfig
[user]
    name = YOUR_NAME
    email = YOUR_EMAIL@example.com

[include]
    path = ~/.config/git/config-common

[include]
    path = ~/.config/git/aliases
```

`~/.config/git/config-common` (stowed, committed):

```gitconfig
[core]
    editor = nvim
    autocrlf = input
    whitespace = trailing-space,space-before-tab
    excludesfile = ~/.config/git/ignore

[pull]
    rebase = false

[merge]
    conflictstyle = diff3

[diff]
    colorMoved = default

[color]
    ui = auto

[init]
    defaultBranch = main
```

`~/.config/git/aliases` (stowed, committed):

```gitconfig
[alias]
    st = status
    co = checkout
    br = branch
    lg = log --oneline --graph --decorate --all
```

`~/.config/git/ignore` (stowed, committed — see Section 6 for full pattern list).

---

## 6. Git Content Boundaries

### `config-common` — what belongs here

- `[core]`: `editor`, `autocrlf`, `whitespace`, `excludesfile = ~/.config/git/ignore`.
- `[pull]`: `rebase = false`.
- `[merge]`: `conflictstyle = diff3`.
- `[diff]`: `colorMoved = default`.
- `[color]`: `ui = auto`.
- `[init]`: `defaultBranch = main`.

**Forbidden in `config-common`:**

- `[user]` block (`name`, `email`, `signingkey`).
- `[commit]` `gpgsign`.
- `[gpg]` block.
- `[includeIf]` blocks.
- `[alias]` — aliases belong in `aliases` only.
- Remote URLs with credentials.
- Platform-specific credential helpers (`osxkeychain`, `libsecret`).

### `aliases` — what belongs here

Safe, portable Git aliases only:

- Shorthand aliases: `st`, `co`, `br`, `lg`.
- No aliases that embed paths, usernames, tokens, or machine-specific values.
- No risky, destructive, or outdated workflow aliases (no `reset --hard` shortcuts, no `push --force` shortcuts, no legacy VCS aliases).

**Forbidden in `aliases`:**

- `[user]`, `[core]`, or any non-`[alias]` section.
- Aliases that call external commands with hardcoded paths.
- Aliases marked for legacy workflows.

### `ignore` — what belongs here

Global ignore patterns. All patterns are well-known tool artifacts, safe to commit:

- macOS artifacts: `.DS_Store`, `.AppleDouble`, `.LSOverride`, `._*`
- Linux desktop artifacts: `.Trash-*`, `lost+found`
- Editor artifacts: `.idea/`, `.vscode/`, `*.swp`, `*.swo`, `*~`, `*.orig`
- Build and compiled artifacts: `*.pyc`, `__pycache__/`, `*.class`, `*.o`, `*.out`
- Thumbnail caches: `Thumbs.db`, `ehthumbs.db`
- Environment files (generic): `.env.local`, `.env.*.local`

---

## 7. Stow Strategy

### Zsh — no-folding approach

The `common/zsh` package stows `~/.config/zsh/`. Stow links every tracked file in `stow/common/zsh/.config/zsh/` into `~/.config/zsh/`. The `.example` files stow harmlessly. `~/.zshrc` is not in the package.

Dry-run before install (always required):

```bash
# Fake-home validation (use when ~/.config/zsh/ already exists on the active machine)
TEST_HOME="$(mktemp -d)"
stow --dir=stow/common --target="$TEST_HOME" --simulate zsh
rm -rf "$TEST_HOME"
```

Or using the Taskfile:

```bash
task dry-run AREA=common PACKAGE=zsh
```

Install (manual step only):

```
⚠️  MANUAL STEP — review dry-run output before running
stow --dir=stow/common --target="$HOME" zsh
```

### Git — what the `common/git` package stows

The package tree is `stow/common/git/.config/git/`. Stow links:

- `~/.config/git/config-common` → `stow/common/git/.config/git/config-common`
- `~/.config/git/aliases` → `stow/common/git/.config/git/aliases`
- `~/.config/git/ignore` → `stow/common/git/.config/git/ignore`

Stow does NOT touch `~/.gitconfig`. The include entries are wired separately by the bootstrap task (Section 8).

Dry-run before install (always required):

```bash
task dry-run AREA=common PACKAGE=git
```

Or directly:

```bash
stow --dir=stow/common --target="$HOME" --simulate git
```

Expected output: three symlink creation lines (`~/.config/git/config-common`, `~/.config/git/aliases`, `~/.config/git/ignore`). No conflicts if `~/.config/git/` does not yet exist.

Install (manual step only):

```
⚠️  MANUAL STEP — review dry-run output before running
stow --dir=stow/common --target="$HOME" git
```

---

## 8. Git Bootstrap Tasks (Taskfile)

### Why a bootstrap task

Stow links files into `~/.config/git/` but does not modify `~/.gitconfig`. The user's `~/.gitconfig` needs two `[include]` entries pointing to the stowed files. Rather than documenting a manual edit, a Taskfile task provides a safe, idempotent, auditable wiring step.

go-task is already the adopted task runner (ADR-0002). The `Taskfile.yml` already exists at repo root. Adding bootstrap tasks is the natural pattern.

### ADR-0009 applicability

ADR-0009 restricted the foundation phase Taskfile to read-only tasks. The `git:bootstrap` task writes to `~/.gitconfig`. This requires a new ADR (0027, see Section 11) explicitly scoping this task as user-invoked and safe. The task is never called by any script, hook, or other task.

### Task design

**`git:bootstrap:dry-run`** — shows what would change, modifies nothing:

```yaml
git:bootstrap:dry-run:
  desc: "Show include.path entries that would be added to ~/.gitconfig — no changes made"
  cmds:
    - |
      for inc in "~/.config/git/config-common" "~/.config/git/aliases"; do
        if git config --global --get-all include.path 2>/dev/null | grep -qxF "$inc"; then
          echo "already present: include.path = $inc"
        else
          echo "would add:       include.path = $inc"
        fi
      done
```

**`git:bootstrap`** — adds missing include entries, creates backup, is idempotent:

```yaml
git:bootstrap:
  desc: "Wire ~/.gitconfig to managed Git config — idempotent, creates timestamped backup"
  cmds:
    - |
      GITCONFIG="$HOME/.gitconfig"
      # Create timestamped backup before any modification
      if [[ -f "$GITCONFIG" ]]; then
        BACKUP="${GITCONFIG}.bak.$(date +%Y%m%d%H%M%S)"
        cp "$GITCONFIG" "$BACKUP"
        echo "Backup: $BACKUP"
      fi
      # Add missing include.path entries — skip if already present
      for inc in "~/.config/git/config-common" "~/.config/git/aliases"; do
        if git config --global --get-all include.path 2>/dev/null | grep -qxF "$inc"; then
          echo "skip (already present): $inc"
        else
          git config --global --add include.path "$inc"
          echo "added: $inc"
        fi
      done
```

### Safety invariants

- Never overwrites `~/.gitconfig` — uses `git config --global --add` which only appends.
- Creates `~/.gitconfig` if missing (git handles this automatically).
- Creates a timestamped backup before any modification to an existing file.
- Idempotent: checks for existing include.path values before adding; running twice produces no duplicates.
- Never modifies `user.name`, `user.email`, signing keys, credentials, or existing include.path values.
- Never called automatically — only by explicit `task git:bootstrap`.

### Validation after bootstrap

```bash
# Confirm no duplicate include.path entries
git config --global --get-all include.path | sort | uniq -d
# Must produce no output

# Confirm managed config is active
git config --list --show-origin | grep 'config/git/config-common'
# Must show lines from ~/.config/git/config-common
```

---

## 9. Privacy Boundary

### Forbidden-to-commit vs. allowed-to-commit

| Category | Examples | Committed? |
|---|---|---|
| Real name | First name, last name, full name | Never |
| Real email | Personal or work email address | Never |
| Signing key | GPG key ID, fingerprint, key content | Never |
| SSH material | Private key content, `IdentityFile` path | Never |
| Work identity | Work hostname, work email, work Git remote URL | Never |
| Work paths | `/Users/fnayou/work/...`, work project paths | Never |
| API tokens | Any `TOKEN=`, `KEY=`, `SECRET=` value | Never |
| Machine hostname | Machine name in any config value | Never |
| Portable editor name | `nvim`, `vim`, `nano` | Yes |
| Portable pager name | `less`, `more` | Yes |
| History count | `10000` | Yes |
| Portable shell options | `HIST_IGNORE_DUPS`, `AUTO_CD` | Yes |
| Well-known ignore patterns | `.DS_Store`, `*.swp`, `*.pyc` | Yes |
| Portable Git settings | `pull.rebase = false`, `color.ui = auto` | Yes |
| Portable Git aliases | `st = status`, `lg = log --oneline --graph` | Yes |

### `.gitignore` guard for each package

**Zsh package** (`stow/common/zsh/.config/zsh/.gitignore`):

```gitignore
shared.zsh
macos.zsh
arch.zsh
omp.zsh
index.zsh
local.zsh
```

Note: `shared.zsh` and `index.zsh` are currently tracked despite this guard. The guard prevents future accidental staging of a locally-modified copy if `git rm --cached` is ever applied.

**Git package:** All three files (`config-common`, `aliases`, `ignore`) are committed directly. No git-ignored counterparts exist in the package. The root `.gitignore` entries for the old paths (`stow/common/git/.gitconfig.common`, `stow/common/git/.gitignore_global`) must be removed as part of this adoption.

### Pre-commit audit commands

```bash
# No YOUR_* placeholders remain in shared.zsh
grep 'YOUR_' stow/common/zsh/.config/zsh/shared.zsh

# No identity values in git config files
grep -in 'signingkey\|\[user\]\|\[gpg\]\|gpgsign\|osxkeychain\|token\|password' \
  stow/common/git/.config/git/config-common \
  stow/common/git/.config/git/aliases

# No alias contains risky flags or destructive shortcuts
grep -in 'force\|hard\|purge\|nuke' stow/common/git/.config/git/aliases

# No private zsh files staged
git diff --staged --name-only | grep -E \
  '(shared\.zsh|index\.zsh|macos\.zsh|arch\.zsh|omp\.zsh|local\.zsh)$'
```

All commands must produce no output before committing.

---

## 10. Rollback Strategy

### Zsh rollback (target: under 60 seconds)

1. Open `~/.zshrc`.
2. Remove or comment out the guarded managed block:
   ```zsh
   # >>> dotfiles managed (zsh) — added manually; delete this block to disable >>>
   [[ -r "$HOME/.config/zsh/index.zsh" ]] && source "$HOME/.config/zsh/index.zsh"
   # <<< dotfiles managed (zsh) <<<
   ```
3. Open a new shell. Managed layer is inert immediately.

No stow unstow required. No file deletion required. Managed files remain in place.

### Git rollback (target: under 60 seconds)

1. Open `~/.gitconfig`.
2. Remove the include lines:
   ```gitconfig
   [include]
       path = ~/.config/git/config-common

   [include]
       path = ~/.config/git/aliases
   ```
3. Git immediately uses only remaining `~/.gitconfig` settings.

Managed files (`~/.config/git/config-common`, `~/.config/git/aliases`, `~/.config/git/ignore`) remain as symlinks but are not applied. No stow unstow required.

If rollback is needed before bootstrap ran, there is nothing to revert — `~/.gitconfig` was never modified.

---

## 11. Validation Steps

### Zsh validation (ordered)

1. **Syntax check** — before stowing:
   ```bash
   zsh -n stow/common/zsh/.config/zsh/shared.zsh
   zsh -n stow/common/zsh/.config/zsh/index.zsh
   ```
   Both must exit 0 with no output.

2. **No placeholder tokens:**
   ```bash
   grep 'YOUR_' stow/common/zsh/.config/zsh/shared.zsh
   ```
   Must produce no output.

3. **No forbidden content:**
   ```bash
   grep -E '(brew |pacman |yay |pbcopy|pbpaste|apt |systemctl|git clone|curl |wget )' \
     stow/common/zsh/.config/zsh/shared.zsh
   ```
   Must produce no output.

4. **Package layout validation — fake home:**
   ```bash
   TEST_HOME="$(mktemp -d)"
   stow --dir=stow/common --target="$TEST_HOME" --simulate zsh
   rm -rf "$TEST_HOME"
   ```
   Must produce no output (no conflicts).

5. **Shell startup error check** — after stowing and confirming include block in `~/.zshrc`:
   ```bash
   zsh -ic 'echo zsh-ok'
   ```
   Must print `zsh-ok` with no errors.

6. **`~/.zshrc` unchanged:**
   ```bash
   stat ~/.zshrc  # modification timestamp should be unchanged from before this work
   ```

### Git validation (ordered)

1. **No identity in committed config files:**
   ```bash
   grep -in 'signingkey\|\[user\]\|\[gpg\]\|gpgsign' \
     stow/common/git/.config/git/config-common \
     stow/common/git/.config/git/aliases
   ```
   Must produce no output.

2. **No risky aliases:**
   ```bash
   grep -in 'force\|hard\|purge\|nuke' stow/common/git/.config/git/aliases
   ```
   Must produce no output.

3. **Package layout dry-run:**
   ```bash
   task dry-run AREA=common PACKAGE=git
   ```
   Expected: three symlink creation lines. No conflicts.

4. **Bootstrap dry-run:**
   ```bash
   task git:bootstrap:dry-run
   ```
   Must show "would add" for both paths (before bootstrap runs).

5. **Config origin check** — after `task git:bootstrap`:
   ```bash
   git config --list --show-origin | grep 'config/git/config-common'
   ```
   Must show lines attributed to `~/.config/git/config-common`.

6. **Identity resolution check:**
   ```bash
   git config --show-origin user.name
   git config --show-origin user.email
   ```
   Both must show `~/.gitconfig` — never `~/.config/git/config-common` or `~/.config/git/aliases`.

7. **`excludesfile` active:**
   ```bash
   git config --global core.excludesfile
   ```
   Must print `~/.config/git/ignore` (or its expanded absolute path).

8. **No duplicate includes after bootstrap:**
   ```bash
   git config --global --get-all include.path | sort | uniq -d
   ```
   Must produce no output.

9. **Privacy audit before any commit:**
   ```bash
   git diff --staged stow/common/git/ | \
     grep -i 'signingkey\|gpgsign\|token\|password'
   ```
   Must produce no output.

---

## 12. ADRs to Create

Next available ADR number: **0024** (confirmed from `docs/decisions/` listing).

| ADR | Title | Decision | Why it matters |
|---|---|---|---|
| 0024 | `shared.zsh` and `index.zsh` are tracked with real safe content | Both files committed as real filenames with safe portable content — not `.example`-only | Breaks from Architecture 0004 `.example`-only intent; auditable for future contributors |
| 0025 | XDG-style Git config layout (`~/.config/git/`) | Managed Git files live at `~/.config/git/config-common`, `~/.config/git/aliases`, `~/.config/git/ignore` instead of home-level dotfiles | Supersedes ADR-0013/0014 scope; records the filename and path choices and why XDG is preferred |
| 0026 | Git aliases extracted to a separate `aliases` file | Aliases isolated in their own file; `config-common` holds only settings | Records the separation principle: settings and shortcuts have different change rates and review needs |
| 0027 | `git:bootstrap` and `git:bootstrap:dry-run` added to Taskfile | First mutating Taskfile tasks; user-invoked only; creates timestamped backup; idempotent via `--get-all` check before `--add` | ADR-0009 required explicit scope lift for mutating tasks; this ADR records the conditions under which it is safe |

---

## 13. Open Questions

1. **`$EDITOR` in `shared.zsh`**: Proposed `nvim`. If the user prefers a different editor, confirm before implementation. Non-blocking.

2. **Additional zsh aliases in `shared.zsh`**: Beyond `grep --color=auto`, confirm whether to add `alias ll='ls -lh'` or similar portable aliases. Non-blocking.

3. **`diff.algorithm = histogram` in `config-common`**: Portable, safe to commit, improves diff output. Decide during implementation. Non-blocking.

4. **Aliases to include**: Beyond `st`, `co`, `br`, `lg` — confirm full alias list before writing `aliases` file. Non-blocking; zero risky/legacy aliases regardless.

5. **`task git:bootstrap` placement in Taskfile**: Decide whether bootstrap tasks live in the main `Taskfile.yml` or a separate `Taskfile.git.yml` included via `includes:`. Current Taskfile has all tasks in one file; follow that pattern unless the file grows large. Non-blocking.

---

## Risks

| Risk | Likelihood | Severity | Mitigation |
|---|---|---|---|
| `config-common` committed with a `[user]` block | Low | High | Validation step 1 (git); pre-commit `grep` check |
| `aliases` contains risky alias (`push --force`, `reset --hard`) | Low | High | Validation step 2; content boundary is explicit; no legacy aliases allowed |
| `shared.zsh` committed with a real editor path containing a username | Low | Medium | Portable editor names contain no paths; pre-commit `grep '/Users/'` check |
| `task git:bootstrap` run before stow (symlinks not yet in place) | Medium | Medium | Dry-run task shows `would add` but the pointed-to file won't exist; validation step 5 catches this |
| Duplicate include.path added if `git config --global --add` called directly without check | Low | Low | ADR-0027 and bootstrap task logic enforce check-then-add; user should always use the task |
| Zinit auto-clone reintroduced into `shared.zsh` | Low | High | ADR-0020 forbids it; validation step 3 checks for `git clone` |
| `index.zsh` gains logic beyond source order | Low | Low | Content boundary in Section 2 is explicit |
| Old root `.gitignore` entries for deleted paths cause confusion | Low | Low | Remove entries as part of implementation; old paths no longer exist |

---

## Extensibility

- New portable Git settings: add to `config-common`.
- New Git aliases: add to `aliases`; must be safe and current (no legacy aliases).
- New portable zsh aliases or options: add to `shared.zsh`.
- New tool integration in zsh: add a guarded `command -v` line to `shared.zsh`.
- Platform-specific zsh config (macOS/Arch): future PRD; files remain `.example`-only now.
- Work identity or signing: user configures directly in `~/.gitconfig` via `git config --global`; no repository change required.

---

## Recommended Next Step

Planner writes `docs/plans/0009-real-zsh-git-configuration-plan.md`. The plan must cover:

1. Replace `YOUR_EDITOR` → `nvim` and `YOUR_PAGER` → `less` in `stow/common/zsh/.config/zsh/shared.zsh`.
2. Create `stow/common/git/.config/git/config-common` with committed portable settings.
3. Create `stow/common/git/.config/git/aliases` with committed safe aliases.
4. Create `stow/common/git/.config/git/ignore` with committed global ignore patterns.
5. Remove `stow/common/git/.gitconfig.example` and `stow/common/git/.gitignore_global.example`.
6. Update root `.gitignore`: remove entries for `stow/common/git/.gitconfig.common` and `stow/common/git/.gitignore_global`.
7. Add `git:bootstrap:dry-run` and `git:bootstrap` tasks to `Taskfile.yml`.
8. Write ADR-0024, ADR-0025, ADR-0026, ADR-0027.
9. Per-step validation from Section 11.
10. Safety check per step: `~/.zshrc` not modified, `$HOME` not modified outside Stow target, no Stow run against real home, no dependency installed.
11. Rollback notes from Section 10.
