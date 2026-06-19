# Plan: Real Zsh Configuration Adoption

**Number:** 0014
**Status:** Complete
**Date:** 2026-06-19
**PRD:** [0010-real-zsh-configuration.md](../prd/0010-real-zsh-configuration.md)
**Architecture:** [0010-real-zsh-configuration-architecture.md](../architecture/0010-real-zsh-configuration-architecture.md)
**Review:** [0033-real-zsh-prd-architecture-review.md](../reviews/0033-real-zsh-prd-architecture-review.md)

---

## Overview

This plan fills in real, safe, portable content into the five `.example` templates (`macos.zsh.example`, `arch.zsh.example`, `omp.zsh.example`, `shared.zsh.example`, `index.zsh.example`), writes the ten ADR records (ADR-0033 through ADR-0042) established by Architecture-0010 §17, and produces the human setup guide required by ADR-0028. It does not modify `~/.zshrc`, does not run Stow against `$HOME`, does not install any dependency (Zinit, fzf, zoxide, eza, oh-my-posh), and does not commit any private, secret, or machine-specific value — all of which are explicit non-goals of PRD-0010.

---

## Prerequisites

The following tools must be installed on the machine used for validation:

| Tool | Minimum version | Verify command |
|---|---|---|
| `zsh` | 5.8 | `zsh --version` |
| `stow` | 2.3 | `stow --version` |
| `git` | 2.x | `git --version` |

```bash
zsh --version
stow --version
git --version
```

All three must return a version string without error before beginning any task.

---

## Ordered Tasks

---

### Group A — `.example` template updates (repo changes only; safe, no $HOME)

---

#### A1 — Audit and complete `macos.zsh.example`

**Files changed:**
- `stow/common/zsh/.config/zsh/macos.zsh.example` — modified

**Safety check:** No `$HOME` file is touched. No Stow run. Repository file only.

**Current state:** The file already has `command -v brew >/dev/null 2>&1 && eval "$(brew shellenv)"` (confirmed by Review-0033 follow-up). The `alias o='open'` line is commented out. `YOUR_MACOS_TOOL_PATH` placeholder is present.

**Steps:**

1. Open `stow/common/zsh/.config/zsh/macos.zsh.example`.
2. Confirm the Homebrew guard is present and correct (not using `YOUR_HOMEBREW_PREFIX`):
   ```zsh
   command -v brew >/dev/null 2>&1 && eval "$(brew shellenv)"
   ```
3. Confirm or uncomment the `alias o='open'` line. It must be active (not commented out). No guard is needed — this file is only sourced on macOS.
4. Confirm the `YOUR_MACOS_TOOL_PATH` placeholder is present with an explanatory comment above it. The comment must explain that the user should replace this placeholder with their actual tool path or delete the line if unused.
5. Confirm `YOUR_HOMEBREW_PREFIX` does NOT appear anywhere in the file.
6. If any of the above is missing or wrong, edit the file to match. Final expected content:

   ```zsh
   # macos.zsh.example — macOS-specific zsh config
   # Copy to macos.zsh, review, then stow. Do NOT stow this .example directly.
   # Sourced only on macOS (via $OSTYPE detection in index.zsh).

   # --- Homebrew ---
   # Guard: activates only when Homebrew is installed; no-op otherwise.
   # Works on both Apple Silicon (/opt/homebrew) and Intel (/usr/local) without hardcoding a prefix.
   command -v brew >/dev/null 2>&1 && eval "$(brew shellenv)"

   # --- macOS-specific PATH additions ---
   # Replace YOUR_MACOS_TOOL_PATH with your actual tool path, or delete this line if unused.
   export PATH="YOUR_MACOS_TOOL_PATH:$PATH"

   # --- macOS tool aliases ---
   # 'open' is always available on macOS; no guard needed (this file is macOS-only).
   alias o='open'
   ```

**Validation:**

```bash
zsh -n stow/common/zsh/.config/zsh/macos.zsh.example
# Expected: exit 0, no output

grep 'YOUR_HOMEBREW_PREFIX' stow/common/zsh/.config/zsh/macos.zsh.example
# Expected: no output

grep "alias o='open'" stow/common/zsh/.config/zsh/macos.zsh.example
# Expected: the alias line (not commented out)

grep 'command -v brew' stow/common/zsh/.config/zsh/macos.zsh.example
# Expected: the guard line
```

**Rollback:**

```bash
git checkout -- stow/common/zsh/.config/zsh/macos.zsh.example
```

---

#### A2 — Audit and complete `arch.zsh.example`

**Files changed:**
- `stow/common/zsh/.config/zsh/arch.zsh.example` — modified

**Safety check:** No `$HOME` file is touched. Repository file only.

**Current state:** The file has `YOUR_ARCH_TOOL_PATH` placeholder and a commented-out `alias aur='YOUR_AUR_HELPER'` line. AUR helper guards and systemctl aliases are absent.

**Steps:**

1. Open `stow/common/zsh/.config/zsh/arch.zsh.example`.
2. Confirm or add the `YOUR_ARCH_TOOL_PATH` placeholder with an explanatory comment.
3. Replace the commented-out `alias aur='YOUR_AUR_HELPER'` with the following guarded AUR helper detection block (active, not commented out):
   ```zsh
   command -v yay  >/dev/null 2>&1 && alias aur='yay'
   command -v paru >/dev/null 2>&1 && alias aur='paru'
   ```
4. Add the following systemctl aliases (active, not commented out):
   ```zsh
   alias sc='systemctl'
   alias scu='systemctl --user'
   ```
5. Final expected content:

   ```zsh
   # arch.zsh.example — Arch / EndeavourOS-specific zsh config
   # Copy to arch.zsh, review, then stow. Do NOT stow this .example directly.
   # Sourced only on Arch (via /etc/arch-release detection in index.zsh).

   # --- Arch-specific PATH additions ---
   # Replace YOUR_ARCH_TOOL_PATH with your actual tool path, or delete this line if unused.
   export PATH="YOUR_ARCH_TOOL_PATH:$PATH"

   # --- AUR helper alias (guarded — no-op when neither is installed) ---
   command -v yay  >/dev/null 2>&1 && alias aur='yay'
   command -v paru >/dev/null 2>&1 && alias aur='paru'

   # --- systemd aliases (systemctl is always present on Arch) ---
   alias sc='systemctl'
   alias scu='systemctl --user'
   ```

**Validation:**

```bash
zsh -n stow/common/zsh/.config/zsh/arch.zsh.example
# Expected: exit 0, no output

grep "alias sc='systemctl'" stow/common/zsh/.config/zsh/arch.zsh.example
# Expected: the alias line

grep 'command -v yay' stow/common/zsh/.config/zsh/arch.zsh.example
# Expected: the guard line

grep 'command -v paru' stow/common/zsh/.config/zsh/arch.zsh.example
# Expected: the guard line
```

**Rollback:**

```bash
git checkout -- stow/common/zsh/.config/zsh/arch.zsh.example
```

---

#### A3 — Audit and complete `omp.zsh.example`

**Files changed:**
- `stow/common/zsh/.config/zsh/omp.zsh.example` — modified

**Safety check:** No `$HOME` file is touched. Repository file only.

**Current state:** The file has the double-guarded eval block commented out. The header comment contains an outdated step 3 ("Add the guard source call to `~/.config/zsh/shared.zsh` or `~/.zshrc`") — this is wrong because `index.zsh` already sources `omp.zsh` (step 3 of the source order). That instruction must be removed.

**Steps:**

1. Open `stow/common/zsh/.config/zsh/omp.zsh.example`.
2. Uncomment the double-guarded eval block so it is active. The block must use `command -v oh-my-posh` and `[[ -f … omp.toml ]]` with XDG fallback:
   ```zsh
   if command -v oh-my-posh >/dev/null 2>&1 && [[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/omp/omp.toml" ]]; then
     eval "$(oh-my-posh init zsh --config "${XDG_CONFIG_HOME:-$HOME/.config}/omp/omp.toml")"
   fi
   ```
3. Remove the outdated instruction in the header comment that tells the user to add a guard source call to `shared.zsh` or `~/.zshrc`. That is already handled by `index.zsh`.
4. Final expected content:

   ```zsh
   # omp.zsh.example — Oh My Posh prompt activation
   # Copy to omp.zsh (git-ignored, never committed), then re-stow the zsh package.
   # index.zsh sources this file automatically (step 3 of the source order).
   #
   # Prerequisites before using this file:
   #   - Oh My Posh installed (see docs/guides/zsh-setup.md)
   #   - stow/common/omp/ stowed so that ~/.config/omp/omp.toml exists
   #   - A Nerd Font installed and selected in your terminal emulator
   #
   # Double guard: both conditions must be true to activate.
   #   1. oh-my-posh binary is in $PATH.
   #   2. omp.toml config file exists (managed by the common/omp Stow package).
   # If either condition is false, this file is a no-op and the default zsh prompt remains.

   if command -v oh-my-posh >/dev/null 2>&1 && [[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/omp/omp.toml" ]]; then
     eval "$(oh-my-posh init zsh --config "${XDG_CONFIG_HOME:-$HOME/.config}/omp/omp.toml")"
   fi
   ```

**Validation:**

```bash
zsh -n stow/common/zsh/.config/zsh/omp.zsh.example
# Expected: exit 0, no output

grep 'command -v oh-my-posh' stow/common/zsh/.config/zsh/omp.zsh.example
# Expected: the guard line (not commented out)

grep 'XDG_CONFIG_HOME' stow/common/zsh/.config/zsh/omp.zsh.example
# Expected: the XDG fallback pattern in the if condition
```

**Rollback:**

```bash
git checkout -- stow/common/zsh/.config/zsh/omp.zsh.example
```

---

#### A4 — Verify `shared.zsh.example` is complete

**Files changed:**
- `stow/common/zsh/.config/zsh/shared.zsh.example` — verified; modified only if any required element is missing

**Safety check:** No `$HOME` file is touched. Repository file only.

**Current state:** The file already contains all required elements (confirmed by reading it above). This task verifies each element is present and adds any that are missing.

**Steps:**

1. Open `stow/common/zsh/.config/zsh/shared.zsh.example`.
2. Verify each of the following is present (if any is missing, add it in the correct position):

   | Required element | Must be present |
   |---|---|
   | XDG exports with `:-` fallback | `export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"`, same for DATA and CACHE |
   | `export EDITOR="YOUR_EDITOR"` | Placeholder value (not `nvim`) |
   | `export PAGER="YOUR_PAGER"` | Placeholder value (not `less`) |
   | HISTFILE | `export HISTFILE="$HOME/.zsh_history"` |
   | HISTSIZE | `export HISTSIZE=10000` |
   | SAVEHIST | `export SAVEHIST=10000` |
   | HIST_IGNORE_DUPS | `setopt HIST_IGNORE_DUPS` |
   | SHARE_HISTORY | `setopt SHARE_HISTORY` |
   | AUTO_CD | `setopt AUTO_CD` |
   | Zinit ZINIT_HOME | `ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"` |
   | Zinit source guard | `[[ -f "${ZINIT_HOME}/zinit.zsh" ]] && source "${ZINIT_HOME}/zinit.zsh"` |
   | compinit guard | `if ! typeset -f zinit >/dev/null 2>&1; then autoload -Uz compinit && compinit; fi` |
   | fzf guard | `command -v fzf >/dev/null 2>&1 && eval "$(fzf --zsh)"` |
   | zoxide guard | `command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"` |
   | eza guard | `command -v eza >/dev/null 2>&1 && alias ls='eza'` |
   | grep alias | `alias grep='grep --color=auto'` |

3. Confirm the file contains NO platform-specific content: no `brew`, `pacman`, `yay`, `paru`, `pbcopy`, `pbpaste`, `open` (as a command), or `systemctl`.

**Validation:**

```bash
zsh -n stow/common/zsh/.config/zsh/shared.zsh.example
# Expected: exit 0, no output

grep 'YOUR_EDITOR' stow/common/zsh/.config/zsh/shared.zsh.example
# Expected: the placeholder export line

grep 'YOUR_PAGER' stow/common/zsh/.config/zsh/shared.zsh.example
# Expected: the placeholder export line

grep 'command -v fzf' stow/common/zsh/.config/zsh/shared.zsh.example
# Expected: the fzf guard line

grep 'command -v zoxide' stow/common/zsh/.config/zsh/shared.zsh.example
# Expected: the zoxide guard line

grep 'command -v eza' stow/common/zsh/.config/zsh/shared.zsh.example
# Expected: the eza guard line

grep -E '(brew |pacman |yay |paru |pbcopy|pbpaste|systemctl)' \
  stow/common/zsh/.config/zsh/shared.zsh.example
# Expected: no output
```

**Rollback:**

```bash
git checkout -- stow/common/zsh/.config/zsh/shared.zsh.example
```

---

#### A5 — Verify `index.zsh.example` and `index.zsh`

**Files changed:**
- `stow/common/zsh/.config/zsh/index.zsh.example` — verified; modified only if required elements are missing
- `stow/common/zsh/.config/zsh/index.zsh` — verified; modified only if required elements are missing

**Safety check:** No `$HOME` file is touched. Repository files only. (`index.zsh` is tracked per ADR-0029.)

**Current state:** Both files are identical and already contain the correct 4-step source order (confirmed by reading them above). This task verifies the structure and confirms no drift between the two files.

**Steps:**

1. Open both files.
2. Confirm each contains exactly 4 guarded source lines:
   - Step 1: `[[ -r "$HOME/.config/zsh/shared.zsh" ]] && source "$HOME/.config/zsh/shared.zsh"`
   - Step 2: OS detection block — `if [[ "$OSTYPE" == "darwin"* ]]` → sources `macos.zsh`; `elif [[ -f /etc/arch-release ]]` → sources `arch.zsh`
   - Step 3: `[[ -r "$HOME/.config/zsh/omp.zsh" ]] && source "$HOME/.config/zsh/omp.zsh"`
   - Step 4: `[[ -r "$HOME/.config/zsh/local.zsh" ]] && source "$HOME/.config/zsh/local.zsh"`
3. Confirm both files contain no logic, no env exports, and no aliases — only source calls and the OS detection `if/elif`.
4. Confirm `index.zsh.example` and `index.zsh` are identical in content (aside from the header comment indicating which is the template).
5. If any element is missing or the two files have diverged, update to match the correct structure.

**Validation:**

```bash
zsh -n stow/common/zsh/.config/zsh/index.zsh.example
# Expected: exit 0, no output

zsh -n stow/common/zsh/.config/zsh/index.zsh
# Expected: exit 0, no output

grep -c '^\[\[.*\]\] && source ' stow/common/zsh/.config/zsh/index.zsh
# Expected: 4 (one per guarded source call)
```

**Rollback:**

```bash
git checkout -- stow/common/zsh/.config/zsh/index.zsh.example
git checkout -- stow/common/zsh/.config/zsh/index.zsh
```

---

#### A6 — Verify `zshrc.example`

**Files changed:**
- `stow/common/zsh/.config/zsh/zshrc.example` — verified; modified only if the meteo alias or other personal content remains

**Safety check:** No `$HOME` file is touched. Repository file only.

**Current state:** Review-0033 found a personal `meteo` alias (`curl -4 http://wttr.in/Paris`) and confirmed it was removed in a pre-plan fix. This task verifies the fix is in place and the file contains only safe content.

**Steps:**

1. Open `stow/common/zsh/.config/zsh/zshrc.example`.
2. Confirm the `meteo` alias is absent.
3. Confirm no `wttr.in`, `Paris`, or other personal content is present.
4. Confirm the file contains only: the guarded include block, explanatory comments, and safe starter-machine comments.
5. If the `meteo` alias is still present, remove it now.

**Validation:**

```bash
grep 'meteo\|wttr\|Paris' stow/common/zsh/.config/zsh/zshrc.example
# Expected: no output

zsh -n stow/common/zsh/.config/zsh/zshrc.example
# Expected: exit 0, no output
```

**Rollback:**

```bash
git checkout -- stow/common/zsh/.config/zsh/zshrc.example
```

---

### Group B — ADR records (one file per ADR; repo changes only; safe)

Each ADR uses the standard format from `docs/decisions/`. Status: Accepted. Date: 2026-06-19. Each includes Context, Decision, and Consequences sections. Each references PRD-0010 and Architecture-0010.

---

#### B1 — Write `docs/decisions/0033-shared-zsh-content-scope.md`

**Files changed:**
- `docs/decisions/0033-shared-zsh-content-scope.md` — created

**Content:**

```markdown
# Decision: `shared.zsh` Content Scope

**Number:** 0033
**Date:** 2026-06-19
**Status:** Accepted
**Related:** PRD-0010, Architecture-0010 §3, ADR-0016, ADR-0029

## Context

The managed zsh layer places all sourced files in `stow/common/zsh/`. `shared.zsh` is the portable layer — sourced on every platform, every machine. Without an explicit content boundary, future contributors may add platform-specific configuration, tool installation commands, or private values to `shared.zsh`, breaking portability and violating privacy requirements.

PRD-0010 and Architecture-0010 §3 define what belongs in the portable layer and what is forbidden. This ADR records that boundary as a standing decision.

## Decision

`shared.zsh` (and its `.example` template) is restricted to content that is:

- Portable across macOS and Arch without modification.
- Free of platform-specific tool references.
- Free of network access or tool installation.
- Free of private values, tokens, hostnames, or credentials.

Permitted content: XDG base directory exports, `$EDITOR`/`$PAGER` exports, `$HISTFILE`/`$HISTSIZE`/`$SAVEHIST` and history options, `setopt AUTO_CD`, Zinit source guard, compinit fallback guard, `command -v` guards for fzf/zoxide/eza, `alias grep='grep --color=auto'`.

Forbidden content (must not appear):

| Content | Correct location |
|---|---|
| `brew`, `/opt/homebrew`, `brew install` | `macos.zsh` |
| `pacman`, `yay`, `paru`, `systemctl` | `arch.zsh` |
| `pbcopy`, `pbpaste`, `open` | `macos.zsh` |
| Oh My Posh `eval` block | `omp.zsh` |
| Zinit plugin declarations (`zinit light`, `zinit snippet`) | deferred to a future PRD |
| Private tokens, API keys, hostnames | `local.zsh` |
| `git clone`, `curl … | sh`, package manager install | forbidden everywhere at shell startup |
| Hardcoded absolute paths with OS differences | `macos.zsh` or `arch.zsh` |

## Consequences

- `shared.zsh` remains safe to commit and safe to source on both platforms without any runtime branching.
- Content boundary is enforced at review time: the pre-commit `grep` check in Architecture-0010 §15 flags violations automatically.
- Future contributors adding a portable tool integration add a guarded `command -v` line to `shared.zsh`; platform-specific additions go to the correct platform layer.
- Extended personal aliases (`ll`, `la`, `lt`) go in `local.zsh` or the user's real `shared.zsh` — not in the committed template (see ADR-0037).
```

**Validation:**

```bash
ls docs/decisions/0033-shared-zsh-content-scope.md
# Expected: file exists
```

**Rollback:**

```bash
rm docs/decisions/0033-shared-zsh-content-scope.md
```

---

#### B2 — Write `docs/decisions/0034-platform-layers-runtime-selected.md`

**Files changed:**
- `docs/decisions/0034-platform-layers-runtime-selected.md` — created

**Content:**

```markdown
# Decision: `macos.zsh` and `arch.zsh` as Runtime-Selected Platform Layers

**Number:** 0034
**Date:** 2026-06-19
**Status:** Accepted
**Related:** PRD-0010, Architecture-0010 §4, ADR-0016

## Context

ADR-0016 established the single-package layout: all zsh config lives in `stow/common/zsh/`. Both macOS and Arch platform files (`macos.zsh`, `arch.zsh`) are part of this common package and are therefore symlinked on every machine, regardless of platform.

This creates a question: what happens when an Arch file is symlinked on macOS, or vice versa? And what is the explicit content scope for each platform layer?

## Decision

Both `macos.zsh` and `arch.zsh` are always symlinked by Stow on every machine. OS detection happens at runtime inside `index.zsh`:

```zsh
if [[ "$OSTYPE" == "darwin"* ]]; then
  [[ -r "$HOME/.config/zsh/macos.zsh" ]] && source "$HOME/.config/zsh/macos.zsh"
elif [[ -f /etc/arch-release ]]; then
  [[ -r "$HOME/.config/zsh/arch.zsh" ]] && source "$HOME/.config/zsh/arch.zsh"
fi
```

The unused platform file is symlinked but never sourced. It is harmless.

**`macos.zsh` scope:** Homebrew environment (`command -v brew` guard), macOS-only aliases (`alias o='open'`), macOS-specific PATH additions (`YOUR_MACOS_TOOL_PATH` placeholder).

**`arch.zsh` scope:** AUR helper aliases (guarded with `command -v yay`/`command -v paru`), systemctl aliases (`sc`, `scu`), Arch-specific PATH additions (`YOUR_ARCH_TOOL_PATH` placeholder).

Neither file may contain content from `shared.zsh`'s scope (portable config), `omp.zsh`'s scope (prompt), or `local.zsh`'s scope (private values).

## Consequences

- A single Stow operation (`stow common/zsh`) works on both macOS and Arch.
- No platform-specific Stow packages are needed for zsh config.
- Adding a new macOS-only or Arch-only tool is a one-line change in the correct platform file.
- The unused platform symlink (e.g., `arch.zsh` on macOS) has no runtime cost and no side effect.
- OS detection uses `$OSTYPE` (zsh built-in, always reliable) with `/etc/arch-release` as the Arch guard (authoritative on EndeavourOS too).
```

**Validation:**

```bash
ls docs/decisions/0034-platform-layers-runtime-selected.md
# Expected: file exists
```

**Rollback:**

```bash
rm docs/decisions/0034-platform-layers-runtime-selected.md
```

---

#### B3 — Write `docs/decisions/0035-omp-zsh-double-guarded-prompt-file.md`

**Files changed:**
- `docs/decisions/0035-omp-zsh-double-guarded-prompt-file.md` — created

**Content:**

```markdown
# Decision: `omp.zsh` as Standalone Double-Guarded Prompt File

**Number:** 0035
**Date:** 2026-06-19
**Status:** Accepted
**Related:** PRD-0010, Architecture-0010 §5, ADR-0016

## Context

Oh My Posh (OMP) is a prompt engine that requires both its binary and a config file to be present before activation. Activating OMP unconditionally, or inside `shared.zsh`, would break shells where OMP is not installed or where the omp config package has not been stowed yet.

The current `omp.zsh.example` ships with the activation block commented out. PRD-0010 requires this block to be active (uncommented) so that users can simply copy the file without having to manually uncomment content.

## Decision

Oh My Posh activation is isolated in `omp.zsh` — a separate file sourced by `index.zsh` at step 3 (after `shared.zsh` and the platform layer, so `$PATH` is fully composed). The activation block uses two independent guards:

```zsh
if command -v oh-my-posh >/dev/null 2>&1 && [[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/omp/omp.toml" ]]; then
  eval "$(oh-my-posh init zsh --config "${XDG_CONFIG_HOME:-$HOME/.config}/omp/omp.toml")"
fi
```

Guard 1 (`command -v oh-my-posh`): confirms the OMP binary is in `$PATH`. Uses `command -v` rather than a path check because the binary install location differs between macOS (Homebrew bin) and Arch (AUR bin or `~/.local/bin`).

Guard 2 (`[[ -f … omp.toml ]]`): confirms the config file exists. OMP errors on startup without a config file, so this guard prevents a broken prompt when the binary is present but the omp Stow package has not been applied.

If either guard fails: the `if` block is skipped, no error is raised, and the default zsh prompt remains.

`omp.zsh` is git-ignored (ADR-0025). Only `omp.zsh.example` is committed. The template ships with the activation block active (not commented out), so a user copying the template gets a working file immediately upon stowing.

## Consequences

- Users who do not want OMP simply do not create `omp.zsh` — the `[[ -r … ]]` guard in `index.zsh` handles the absent case.
- Users who install OMP after initial setup copy `omp.zsh.example` to `omp.zsh` and re-stow; no code change is needed.
- A machine with OMP binary but without the omp Stow package applied starts cleanly — guard 2 fails safely.
- Performance profiling of shell startup is simplified because the prompt engine is isolated in one file.
- The double-guard pattern is mandatory; removing either guard is a blocking review issue per Architecture-0010 §17.
```

**Validation:**

```bash
ls docs/decisions/0035-omp-zsh-double-guarded-prompt-file.md
# Expected: file exists
```

**Rollback:**

```bash
rm docs/decisions/0035-omp-zsh-double-guarded-prompt-file.md
```

---

#### B4 — Write `docs/decisions/0036-local-zsh-created-by-editor-not-example.md`

**Files changed:**
- `docs/decisions/0036-local-zsh-created-by-editor-not-example.md` — created

**Content:**

```markdown
# Decision: `local.zsh` Created Directly by User with Editor, Not Copied from `.example`

**Number:** 0036
**Date:** 2026-06-19
**Status:** Accepted
**Related:** PRD-0010, Architecture-0010 §6, ADR-0023, ADR-0026

## Context

ADR-0023 established `local.zsh` as the git-ignored, last-sourced override slot. ADR-0026 established that `local.zsh` lives physically outside the repo working tree (at `~/.config/zsh/local.zsh`, a real directory under `--no-folding`). Neither ADR specified the creation workflow.

A `.example` template for `local.zsh` would imply a canonical structure for private content, which conflicts with the purpose of `local.zsh`: it is machine-specific, sensitive, and has no predictable shape across machines.

## Decision

`local.zsh` has no `.example` template and no documented default content. The user creates it directly at `~/.config/zsh/local.zsh` using their editor:

```
⚠️  MANUAL STEP — review before running
$EDITOR "$HOME/.config/zsh/local.zsh"
```

This workflow is preferred over copying from an `.example` for three reasons:

1. An `.example` would suggest a canonical structure, which is false — `local.zsh` content is machine-specific and arbitrary.
2. An `.example` could be accidentally committed if a user copies it into the repo directory and adds it with `git add .`. Physical location outside the repo is the primary safety boundary (ADR-0026); not providing a template removes one path to accidental commit.
3. The setup guide (`docs/guides/zsh-setup.md`) documents what `local.zsh` is for and gives example content categories (private PATH, tokens, machine-specific overrides) without providing a template that implies those are the only valid contents.

The absence of `local.zsh` is always safe. `index.zsh` guards the source:

```zsh
[[ -r "$HOME/.config/zsh/local.zsh" ]] && source "$HOME/.config/zsh/local.zsh"
```

## Consequences

- No `.example` file exists for `local.zsh` in the repo. This is intentional.
- `docs/guides/zsh-setup.md` documents the creation command and content categories.
- Users who need identical private config across machines must copy or sync `local.zsh` out-of-band — this repository does not manage that.
- The `.gitignore` entry for `local.zsh` (at `stow/common/zsh/.config/zsh/.gitignore`) provides a belt-and-suspenders second line of defence, but the primary boundary is physical location.
```

**Validation:**

```bash
ls docs/decisions/0036-local-zsh-created-by-editor-not-example.md
# Expected: file exists
```

**Rollback:**

```bash
rm docs/decisions/0036-local-zsh-created-by-editor-not-example.md
```

---

#### B5 — Write `docs/decisions/0037-extended-aliases-excluded-from-examples.md`

**Files changed:**
- `docs/decisions/0037-extended-aliases-excluded-from-examples.md` — created

**Content:**

```markdown
# Decision: Extended Aliases Excluded from Committed `.example` Files

**Number:** 0037
**Date:** 2026-06-19
**Status:** Accepted
**Related:** PRD-0010, Architecture-0010 §12, ADR-0033

## Context

Committed `.example` templates represent the minimum safe default for a new machine. Aliases are a point of personal preference — different users have different workflows, different tool flags, and different conventions. Including extended aliases (`ll`, `la`, `lt`, `tree`) in committed templates imposes workflow choices without a safety or portability justification.

## Decision

Only minimal, guarded, uncontroversial aliases appear in committed `.example` files:

| Alias | Location | Guard | Rationale |
|---|---|---|---|
| `alias grep='grep --color=auto'` | `shared.zsh.example` | None (grep always present; flag valid on BSD and GNU) | Universally safe; improves readability |
| `alias ls='eza'` | `shared.zsh.example` | `command -v eza` | Minimal redirect; no flags that express personal preference |
| `alias o='open'` | `macos.zsh.example` | None (open always present on macOS) | macOS-only file; `open` is always available |
| `alias sc='systemctl'` | `arch.zsh.example` | None (systemctl always present on Arch) | Arch-only file; systemctl is always present |
| `alias aur='yay'` / `alias aur='paru'` | `arch.zsh.example` | `command -v yay` / `command -v paru` | AUR helper shorthand; guarded correctly |

Extended aliases (`ll='ls -lh'`, `la='ls -lha'`, `lt='ls --sort=modified'`, `ll='eza -lh'`, tree variants) are personal preference and belong in:
- The user's real `shared.zsh` (if desired on all machines).
- `local.zsh` (if machine-specific or sensitive-context-dependent).

## Consequences

- Committed templates represent the minimum safe default. No user is forced into an alias they did not choose.
- Users who want extended aliases add them in their own `shared.zsh` or `local.zsh`. The setup guide (`docs/guides/zsh-setup.md`) notes this pattern.
- Future contributors who want to add a new alias to `.example` files must justify it against these criteria: is it portable, is it uncontroversial, is it guarded when it assumes tool presence?
- This decision complements ADR-0033 (content scope) and ADR-0042 (eza-specific alias scope).
```

**Validation:**

```bash
ls docs/decisions/0037-extended-aliases-excluded-from-examples.md
# Expected: file exists
```

**Rollback:**

```bash
rm docs/decisions/0037-extended-aliases-excluded-from-examples.md
```

---

#### B6 — Write `docs/decisions/0038-histfile-at-home-not-xdg.md`

**Files changed:**
- `docs/decisions/0038-histfile-at-home-not-xdg.md` — created

**Content:**

```markdown
# Decision: HISTFILE at `$HOME/.zsh_history`, Not XDG

**Number:** 0038
**Date:** 2026-06-19
**Status:** Accepted
**Related:** PRD-0010, Architecture-0010 §10

## Context

The XDG Base Directory specification defines `$XDG_STATE_HOME` (defaulting to `~/.local/state`) as the conventional location for application state files, including shell history. A strict XDG-first approach would place `$HISTFILE` at `${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history`.

However, `$HISTFILE` is not exported by this managed layer as an XDG path. Three reasons drive this choice.

## Decision

`$HISTFILE` is set to `$HOME/.zsh_history`:

```zsh
export HISTFILE="$HOME/.zsh_history"
```

Reasons:

1. **zsh default.** `$HOME/.zsh_history` is zsh's built-in default. Users who have existing history files at this path do not lose history on switching to the managed layer. Moving to an XDG path would silently orphan existing history.

2. **No directory-creation side effect.** Setting `$HISTFILE` to `${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history` requires `~/.local/state/zsh/` to exist. Creating directories at shell startup is a side effect. `$HOME/.zsh_history` requires no directory creation — `$HOME` always exists.

3. **`XDG_STATE_HOME` complexity.** This managed layer does not export `$XDG_STATE_HOME` (it is not part of the commonly-supported XDG trio: config, data, cache). Using it for `$HISTFILE` would introduce a dependency on a variable that may not be set, requiring an additional `:-` fallback and a directory-creation guard.

## Consequences

- History files remain at `$HOME/.zsh_history` — the location most users already have and most tools expect.
- Users who want XDG-style history placement override `$HISTFILE` in `local.zsh`.
- No directory is created at shell startup as a side effect of this setting.
- This is a conservative default. The XDG alternative is documented in a comment in `shared.zsh.example` for users who prefer it.
```

**Validation:**

```bash
ls docs/decisions/0038-histfile-at-home-not-xdg.md
# Expected: file exists
```

**Rollback:**

```bash
rm docs/decisions/0038-histfile-at-home-not-xdg.md
```

---

#### B7 — Write `docs/decisions/0039-completion-guard-avoid-double-compinit.md`

**Files changed:**
- `docs/decisions/0039-completion-guard-avoid-double-compinit.md` — created

**Content:**

```markdown
# Decision: Completion Guard — Avoid Double `compinit` When Zinit Is Present

**Number:** 0039
**Date:** 2026-06-19
**Status:** Accepted
**Related:** PRD-0010, Architecture-0010 §11, ADR-0020

## Context

`compinit` initializes the zsh completion system. When Zinit is loaded, it calls `compinit` internally at the appropriate point in its initialization sequence. If `shared.zsh` also calls `compinit` unconditionally, two problems arise:

1. **Startup latency.** `compinit` scans all completion function directories (`$fpath`). Running it twice doubles that cost.
2. **Correctness.** A second `compinit` call can trigger security warnings about insecure completion directories and can reset completion state built up by Zinit plugins loaded between the two calls.

## Decision

`shared.zsh` calls `compinit` only when the `zinit` function is not defined:

```zsh
if ! typeset -f zinit >/dev/null 2>&1; then
  autoload -Uz compinit && compinit
fi
```

`typeset -f zinit` returns 0 (true) if and only if the `zinit` function was successfully defined by the Zinit source guard earlier in `shared.zsh`. If Zinit was absent or failed to source, `zinit` is undefined and `typeset -f zinit` returns non-zero — the standalone `compinit` runs.

This guard must be placed after the Zinit source guard in `shared.zsh`. Its position is load-order-sensitive.

Platform-specific completions (Homebrew completions on macOS, AUR helper completions on Arch) belong in `macos.zsh` and `arch.zsh` respectively. They must not call `compinit` — they extend `$fpath` before or after Zinit/compinit has already run.

## Consequences

- Shell startup on machines with Zinit: one `compinit` call (by Zinit).
- Shell startup on machines without Zinit: one `compinit` call (standalone guard).
- Security warnings about insecure completion directories are avoided.
- Removing the guard (reducing to an unconditional `compinit`) is a blocking review issue — it introduces the double-compinit problem on machines with Zinit.
- Future contributors adding completions to platform layers must not call `compinit` directly — they extend `$fpath` only.
```

**Validation:**

```bash
ls docs/decisions/0039-completion-guard-avoid-double-compinit.md
# Expected: file exists
```

**Rollback:**

```bash
rm docs/decisions/0039-completion-guard-avoid-double-compinit.md
```

---

#### B8 — Write `docs/decisions/0040-fzf-zsh-integration-method.md`

**Files changed:**
- `docs/decisions/0040-fzf-zsh-integration-method.md` — created

**Content:**

```markdown
# Decision: `fzf --zsh` as the fzf Integration Method

**Number:** 0040
**Date:** 2026-06-19
**Status:** Accepted
**Related:** PRD-0010, Architecture-0010 §7

## Context

fzf provides multiple integration methods depending on version. Older approaches required the user to manually source shell scripts from fzf's installation directory (`~/.fzf.zsh`, `/usr/share/fzf/key-bindings.zsh`, etc.) and to manually configure `FPATH` and `bindkey` calls. These approaches are version-specific, install-path-specific, and require the user to know their exact fzf installation method.

Since fzf 0.48 (2024), fzf provides `fzf --zsh`, which outputs a self-contained shell script enabling key bindings (`Ctrl-R` for history search, `Ctrl-T` for file search, `Alt-C` for directory navigation) and completion in a single call.

## Decision

The committed `shared.zsh.example` template uses `fzf --zsh` as the integration method:

```zsh
command -v fzf >/dev/null 2>&1 && eval "$(fzf --zsh)"
```

Reasons:

1. **Single call.** No separate `FPATH`, `bindkey`, or script-sourcing steps.
2. **Install-path agnostic.** Works regardless of whether fzf was installed via Homebrew, pacman, AUR, `~/.fzf/`, or direct binary.
3. **Forward-compatible.** The upstream fzf project maintains `fzf --zsh`; it will stay correct as fzf evolves.

Minimum required fzf version: 0.48. Users on older versions must use the manual integration path (sourcing `~/.fzf.zsh` or the system scripts); this is documented in `docs/guides/zsh-setup.md` in the troubleshooting section.

`FZF_DEFAULT_OPTS` and `FZF_DEFAULT_COMMAND` are not set in the committed template — they are machine-specific preferences and belong in `local.zsh`.

## Consequences

- Machines with fzf >= 0.48 get key bindings and completion with no user action beyond copying the template.
- Machines with fzf < 0.48 or no fzf are unaffected (the `command -v fzf` guard is a no-op).
- Users who want custom fzf options add `FZF_DEFAULT_OPTS` in `local.zsh` — no committed template change needed.
- A version check (`fzf --version`) is recommended before relying on `fzf --zsh`; the setup guide documents this.
```

**Validation:**

```bash
ls docs/decisions/0040-fzf-zsh-integration-method.md
# Expected: file exists
```

**Rollback:**

```bash
rm docs/decisions/0040-fzf-zsh-integration-method.md
```

---

#### B9 — Write `docs/decisions/0041-zoxide-init-without-cmd-override.md`

**Files changed:**
- `docs/decisions/0041-zoxide-init-without-cmd-override.md` — created

**Content:**

```markdown
# Decision: `zoxide init zsh` Without `--cmd` Override

**Number:** 0041
**Date:** 2026-06-19
**Status:** Accepted
**Related:** PRD-0010, Architecture-0010 §7

## Context

zoxide is a smarter `cd` replacement. Its `init` command accepts a `--cmd` flag that lets the user alias `cd` to zoxide's `z` function (e.g., `--cmd cd`). This alias replaces the built-in `cd` globally, affecting all scripts and interactive sessions.

The committed template must represent a safe, uncontroversial default. Aliasing `cd` to `z` is a significant muscle-memory and compatibility decision that differs by user preference.

## Decision

The committed `shared.zsh.example` initializes zoxide without the `--cmd` override:

```zsh
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"
```

This provides the `z` and `zi` commands without replacing `cd`. The standard `cd` built-in remains available.

Users who prefer `cd` aliased to `z` add the override in `local.zsh`:

```zsh
# In local.zsh — personal preference, not committed:
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh --cmd cd)"
```

This local override takes effect last (step 4 of the source order) and wins over the `shared.zsh` init.

Note: if both `shared.zsh` and `local.zsh` run a `zoxide init` call, the second call re-initializes zoxide with the new settings. This is safe; zoxide's init output is idempotent at the function-definition level.

## Consequences

- New users get `z` and `zi` without any change to `cd` behavior.
- Power users who want `--cmd cd` add it in `local.zsh` — no committed template change needed.
- Scripts that use `cd` are unaffected by the default committed configuration.
- The setup guide (`docs/guides/zsh-setup.md`) documents the `--cmd cd` override as a local.zsh pattern.
```

**Validation:**

```bash
ls docs/decisions/0041-zoxide-init-without-cmd-override.md
# Expected: file exists
```

**Rollback:**

```bash
rm docs/decisions/0041-zoxide-init-without-cmd-override.md
```

---

#### B10 — Write `docs/decisions/0042-eza-minimal-alias-only.md`

**Files changed:**
- `docs/decisions/0042-eza-minimal-alias-only.md` — created

**Content:**

```markdown
# Decision: Minimal `ls='eza'` Alias Only in Committed Template

**Number:** 0042
**Date:** 2026-06-19
**Status:** Accepted
**Related:** PRD-0010, Architecture-0010 §12, ADR-0037

## Context

eza is a modern replacement for `ls` with an extensive alias ecosystem. Common patterns include `alias ll='eza -lh'`, `alias la='eza -lha'`, `alias lt='eza --sort=modified'`, `alias tree='eza --tree'`, and many flag variations. These are personal preferences — different users prefer different flag sets, different color options, and different column layouts.

ADR-0037 established that only minimal, guarded, uncontroversial aliases appear in committed templates. eza is the primary example of a tool where this principle has practical impact.

## Decision

The committed `shared.zsh.example` sets only the minimal redirect alias:

```zsh
command -v eza >/dev/null 2>&1 && alias ls='eza'
```

`--color=auto` is not added — eza enables color by default. Adding it would be redundant; omitting it keeps the alias minimal.

Extended aliases (`ll`, `la`, `lt`, tree variants, and any eza-specific flags) are user preference and belong in:
- The user's real `shared.zsh` (if they want them on all machines).
- `local.zsh` (if machine-specific).

The `shared.zsh.example` comment notes this pattern and gives examples of common extended aliases.

## Consequences

- Users who copy `shared.zsh.example` get a working `ls` → `eza` redirect with no extra flags.
- Users who want `ll`, `la`, `lt` add them in their own `shared.zsh` or `local.zsh`.
- No committed template enforces a specific eza flag set on all machines.
- This decision follows directly from ADR-0037 but is specific to eza; eza's extensive alias ecosystem makes this a recurring question for future contributors.
```

**Validation:**

```bash
ls docs/decisions/0042-eza-minimal-alias-only.md
# Expected: file exists
```

**Rollback:**

```bash
rm docs/decisions/0042-eza-minimal-alias-only.md
```

---

### Group C — Human setup guide (ADR-0028 requirement)

---

#### C1 — Write `docs/guides/zsh-setup.md`

**Files changed:**
- `docs/guides/zsh-setup.md` — created (file does not currently exist; `docs/guides/` directory exists with `git-setup.md`)

**Safety check:** No `$HOME` file is touched. Repository file only. Every `$HOME`-touching command in the guide is marked `⚠️  MANUAL STEP — review before running`.

**Required sections per ADR-0028:**

The file must contain all eleven sections in this order:

1. What this package manages
2. What it does NOT manage
3. Prerequisites
4. How to copy `.example` files and fill in values
5. Dry-run step — marked `⚠️  MANUAL STEP`
6. Apply step (Stow) — marked `⚠️  MANUAL STEP`
7. Manual activation steps (adding the guarded include block to `~/.zshrc`) — marked `⚠️  MANUAL STEP`
8. How to create `local.zsh` directly with editor — marked `⚠️  MANUAL STEP`
9. Validation steps (copy-pasteable)
10. Rollback steps — marked `⚠️  MANUAL STEP` where applicable
11. Troubleshooting
12. Expected final file layout

**Rules:**
- No secrets, real email, real hostnames, real credentials.
- All example values use placeholders (`YOUR_EDITOR`, `YOUR_MACOS_TOOL_PATH`, etc.).
- `stow --adopt` must not appear anywhere in the file.
- Every command that touches `$HOME` must be preceded by `⚠️  MANUAL STEP — review before running`.

**Content:**

```markdown
# Zsh Package Setup Guide

This guide explains how to set up the managed zsh configuration on a new machine. It is written for a human user performing the setup, not for implementation agents.

---

## 1. What this package manages

The `stow/common/zsh/` package manages files under `~/.config/zsh/`. After Stow, `~/.config/zsh/` is a **real directory** (not a symlink), and each managed file inside it is a per-file symlink into the repository.

| Repository file | Symlink created at | Purpose |
|---|---|---|
| `stow/common/zsh/.config/zsh/index.zsh` | `~/.config/zsh/index.zsh` | Entry point — sources the layers in order |
| `stow/common/zsh/.config/zsh/shared.zsh` | `~/.config/zsh/shared.zsh` | Portable config — env, history, tool guards |
| `stow/common/zsh/.config/zsh/macos.zsh` | `~/.config/zsh/macos.zsh` | macOS-specific config (sourced on macOS only) |
| `stow/common/zsh/.config/zsh/arch.zsh` | `~/.config/zsh/arch.zsh` | Arch-specific config (sourced on Arch only) |
| `stow/common/zsh/.config/zsh/omp.zsh` | `~/.config/zsh/omp.zsh` | Oh My Posh activation (optional, opt-in) |
| `stow/common/zsh/.config/zsh/*.example` | `~/.config/zsh/*.example` | Reference templates (harmless, not sourced) |

`index.zsh` and `shared.zsh` are tracked directly (ADR-0029). The platform files (`macos.zsh`, `arch.zsh`) and `omp.zsh` are git-ignored real files the user copies from `.example` templates and fills in locally.

---

## 2. What this package does NOT manage

- **`~/.zshrc` remains unmanaged.** This package never stows, symlinks, overwrites, or reads `~/.zshrc`. Your existing `~/.zshrc` is fully preserved. After Stow, you manually add one guarded include block to `~/.zshrc` (see Step 7).
- **`~/.zshenv`, `~/.zprofile`, `~/.zlogin`** are not managed.
- **`local.zsh`** is not a Stow symlink — you create it directly in `~/.config/zsh/` with your editor (see Step 8).
- **No tool is installed** by this package. Zinit, fzf, zoxide, eza, and oh-my-posh are optional and must be installed separately if you want them.

---

## 3. Prerequisites

The following tools must be installed before stowing:

| Tool | Purpose | Required? |
|---|---|---|
| `stow` | Symlink manager | Yes |
| `zsh` | Shell | Yes |
| `git` | Repository management | Yes |
| `task` | Task runner (optional convenience) | No |

Optional tools (not required to start; all integrations are guarded):

| Tool | Integration in |
|---|---|
| Zinit | `shared.zsh` — guarded source; no-op if absent |
| fzf (>= 0.48) | `shared.zsh` — `fzf --zsh` guard; no-op if absent |
| zoxide | `shared.zsh` — `zoxide init zsh` guard; no-op if absent |
| eza | `shared.zsh` — `alias ls='eza'` guard; no-op if absent |
| oh-my-posh | `omp.zsh` — double-guarded; no-op if absent or if omp.toml missing |

Verify required tools:

```bash
zsh --version
stow --version
git --version
```

---

## 4. Copy `.example` files and fill in values

Copy each `.example` file to its real filename (git-ignored). All copied files stay inside the repository directory — Stow will link them into `$HOME` in a later step.

```bash
# Required (entry point and portable layer):
cp stow/common/zsh/.config/zsh/index.zsh.example  stow/common/zsh/.config/zsh/index.zsh
cp stow/common/zsh/.config/zsh/shared.zsh.example stow/common/zsh/.config/zsh/shared.zsh

# macOS only:
cp stow/common/zsh/.config/zsh/macos.zsh.example  stow/common/zsh/.config/zsh/macos.zsh

# Arch / EndeavourOS only:
cp stow/common/zsh/.config/zsh/arch.zsh.example   stow/common/zsh/.config/zsh/arch.zsh

# Optional — Oh My Posh (copy only if you want OMP; see Oh My Posh section below):
cp stow/common/zsh/.config/zsh/omp.zsh.example    stow/common/zsh/.config/zsh/omp.zsh
```

All copied files are git-ignored and will not be committed.

Open each copied file and fill in or review placeholder values:

**`shared.zsh`:** Replace `YOUR_EDITOR` with your editor (e.g. `nvim`, `vim`, `nano`) and `YOUR_PAGER` with your pager (e.g. `less`, `more`). All other content is safe to use as-is.

**`macos.zsh` (macOS only):** Replace `YOUR_MACOS_TOOL_PATH` with any macOS-specific binary directory you need on `$PATH`, or delete that line if unused. The Homebrew guard is ready to use without changes.

**`arch.zsh` (Arch only):** Replace `YOUR_ARCH_TOOL_PATH` with any Arch-specific binary directory, or delete that line if unused. AUR helper and systemctl aliases are ready to use without changes.

**`omp.zsh` (optional):** The activation block is active and guarded. You only need to ensure oh-my-posh is installed and `~/.config/omp/omp.toml` exists (via the `common/omp` Stow package) before this file takes effect. See the Oh My Posh section below.

Confirm no `YOUR_*` placeholders remain before proceeding:

```bash
grep -r 'YOUR_' stow/common/zsh/.config/zsh/*.zsh 2>/dev/null
# Expected: no output (or only YOUR_MACOS_TOOL_PATH / YOUR_ARCH_TOOL_PATH if you are keeping the placeholder as a reminder)
```

---

## 5. Dry-run step

Always dry-run before stowing. This shows exactly what symlinks would be created without making any changes.

```bash
stow --dir=stow/common --target="$HOME" --no-folding --simulate zsh
# Note: `task dry-run` is not used here — the Taskfile dry-run task does not pass --no-folding, which is required for this package.
```

**What to look for:** Lines like `LINK: .config/zsh/index.zsh => …` for each managed file. No `CONFLICT` or `WARNING` lines.

**If you see a conflict:** Do not use `--adopt`. See the Troubleshooting section.

---

## 6. Apply step (Stow)

⚠️  MANUAL STEP — review dry-run output before running

```bash
stow --dir=stow/common --target="$HOME" --no-folding zsh
```

This creates `~/.config/zsh/` as a real directory and places per-file symlinks inside it. After this step, `~/.config/zsh/` exists but your shell does not yet use the managed config — see Step 7.

If you add new `.example` copies to the package after the initial Stow (e.g., you copy `omp.zsh.example` to `omp.zsh` later), re-stow to create the new symlink:

⚠️  MANUAL STEP — review dry-run output before running

```bash
stow --dir=stow/common --target="$HOME" --no-folding --simulate zsh
stow --dir=stow/common --target="$HOME" --no-folding --restow zsh
```

---

## 7. Manual activation — add the guarded include block to `~/.zshrc`

`~/.zshrc` is never managed by Stow. After stowing, add the following three-line block to your real `~/.zshrc`, placing it **last** (after your existing lines):

⚠️  MANUAL STEP — open your real ~/.zshrc in an editor and add this block at the end

```zsh
# >>> dotfiles managed (zsh) — added manually; delete this block to disable >>>
[[ -r "$HOME/.config/zsh/index.zsh" ]] && source "$HOME/.config/zsh/index.zsh"
# <<< dotfiles managed (zsh) <<<
```

This block is guarded: if `index.zsh` is absent (e.g., on a machine where you have not stowed yet), it is a no-op and your shell starts normally. To deactivate the managed layer, delete these three lines.

To back up `~/.zshrc` before editing:

⚠️  MANUAL STEP — review before running

```bash
cp "$HOME/.zshrc" "$HOME/.zshrc.bak.$(date +%Y%m%d%H%M%S)"
```

---

## 8. Create `local.zsh` for private overrides

`local.zsh` is the machine-specific, private layer. It is sourced last by `index.zsh` and wins over all managed layers. It has no `.example` template — create it directly in `~/.config/zsh/` with your editor:

⚠️  MANUAL STEP — create a real private file; put private values only here, never in the repo

```bash
$EDITOR "$HOME/.config/zsh/local.zsh"
```

Because `~/.config/zsh/` is a real directory (not a symlink into the repo), `local.zsh` lives physically outside the repository working tree and cannot be committed by accident.

Example content categories for `local.zsh` (not an exhaustive list):

```zsh
# Private PATH additions (internal tools, work-specific binaries):
export PATH="$HOME/.local/bin:$PATH"

# Private tokens (never committed):
export GITHUB_TOKEN="your-token-here"
export ANTHROPIC_API_KEY="your-key-here"

# Machine-specific overrides:
export EDITOR="vim"   # override shared.zsh value on this machine

# Extended eza aliases (personal preference, not in committed template):
command -v eza >/dev/null 2>&1 && alias ll='eza -lh'
command -v eza >/dev/null 2>&1 && alias la='eza -lha'

# zoxide --cmd cd override (if you want 'cd' to invoke z):
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh --cmd cd)"
```

`local.zsh` is absent by default. Its absence is safe — `index.zsh` guards the source with `[[ -r … ]]`.

---

## 9. Validation steps

After stowing and adding the include block, verify the setup with these copy-pasteable commands:

```bash
# 1. Confirm ~/.config/zsh is a real directory (not a symlink)
[[ -d "$HOME/.config/zsh" && ! -L "$HOME/.config/zsh" ]] && echo "real-dir-ok" || echo "NOT-real-dir"
# Expected: real-dir-ok

# 2. Confirm per-file symlinks exist
ls -la "$HOME/.config/zsh/index.zsh" "$HOME/.config/zsh/shared.zsh"
# Expected: two symlinks pointing into the repo

# 3. Confirm the managed layer loads cleanly
zsh --no-rcs -c 'source ~/.config/zsh/index.zsh; echo OK'
# Expected: OK (no errors)

# 4. Confirm EDITOR and PAGER are set
zsh --no-rcs -c 'source ~/.config/zsh/index.zsh; echo "$EDITOR $PAGER"'
# Expected: your editor and pager values (e.g. nvim less)

# 5. Confirm XDG_CONFIG_HOME is set
zsh --no-rcs -c 'source ~/.config/zsh/index.zsh; echo "$XDG_CONFIG_HOME"'
# Expected: /Users/YOUR_USERNAME/.config (or your custom value)

# 6. Confirm HISTFILE is set correctly
zsh --no-rcs -c 'source ~/.config/zsh/index.zsh; echo "$HISTFILE"'
# Expected: /Users/YOUR_USERNAME/.zsh_history

# 7. Confirm zoxide is available (if installed)
zsh --no-rcs -c 'source ~/.config/zsh/index.zsh; type z'
# Expected: z is a shell function (if zoxide installed), or "z not found" without error

# 8. Confirm eza alias is active (if eza installed)
zsh --no-rcs -c 'source ~/.config/zsh/index.zsh; type ls'
# Expected: ls is an alias for eza (if eza installed), or ls is /bin/ls

# 9. Open a new interactive shell and confirm no errors appear
zsh -il -c 'echo shell-ok'
# Expected: shell-ok (possibly after normal shell output)

# 10. Confirm local.zsh is a real file, not a symlink (if present)
p="$HOME/.config/zsh/local.zsh"
if   [[ -L $p ]]; then echo "SYMLINK — WRONG"
elif [[ -e $p ]]; then echo "real file — ok"
else echo "absent — ok"; fi
# Expected: real file — ok, or absent — ok
```

---

## 10. Rollback steps

To remove the managed zsh layer completely:

**Step 1 — Remove the include block from `~/.zshrc`:**

⚠️  MANUAL STEP — open ~/.zshrc and delete the three managed-block lines

Delete these lines from `~/.zshrc`:

```zsh
# >>> dotfiles managed (zsh) — added manually; delete this block to disable >>>
[[ -r "$HOME/.config/zsh/index.zsh" ]] && source "$HOME/.config/zsh/index.zsh"
# <<< dotfiles managed (zsh) <<<
```

After deleting, the managed layer is inert. Open a new shell to confirm.

**Step 2 — Remove Stow symlinks (optional):**

⚠️  MANUAL STEP — dry-run first to confirm what will be removed

```bash
stow --dir=stow/common --target="$HOME" --no-folding --simulate --delete zsh
```

⚠️  MANUAL STEP — run only after confirming the dry-run output

```bash
stow --dir=stow/common --target="$HOME" --no-folding --delete zsh
```

This removes the per-file symlinks from `~/.config/zsh/`. The `~/.config/zsh/` directory itself is not removed — it may still contain `local.zsh` and `.example` symlinks.

**Step 3 — Remove copied local files (optional):**

If you want a completely clean state, remove the git-ignored local copies inside the repo:

```bash
rm stow/common/zsh/.config/zsh/shared.zsh
rm stow/common/zsh/.config/zsh/index.zsh
rm stow/common/zsh/.config/zsh/macos.zsh   # if you created it
rm stow/common/zsh/.config/zsh/arch.zsh    # if you created it
rm stow/common/zsh/.config/zsh/omp.zsh     # if you created it
```

`local.zsh` lives at `~/.config/zsh/local.zsh` (outside the repo) and is not removed by the above. Remove it separately if desired:

⚠️  MANUAL STEP — this removes your private local overrides permanently

```bash
rm "$HOME/.config/zsh/local.zsh"
```

---

## 11. Troubleshooting

**Stow reports a conflict on `~/.config/zsh`:**

```
WARNING! stowing zsh would cause conflicts:
  * existing target is not owned by stow: .config/zsh
All operations aborted.
```

This means `~/.config/zsh/` already exists and was not created by Stow. Do not use `--adopt`.

Options:
- **Back up and remove the directory**, then re-run the dry-run:

  ⚠️  MANUAL STEP — back up first; confirm the directory can be removed safely

  ```bash
  cp -r "$HOME/.config/zsh" "$HOME/.config/zsh.bak.$(date +%Y%m%d%H%M%S)"
  rm -rf "$HOME/.config/zsh"
  stow --dir=stow/common --target="$HOME" --no-folding --simulate zsh
  ```

- **Defer stowing:** keep the existing directory, use the `.example` files for reference, and migrate manually when ready.

**`real-dir-ok` check fails (prints `NOT-real-dir`):**

`~/.config/zsh` is a symlink rather than a real directory. This happens if you previously stowed without `--no-folding`. Fix:

⚠️  MANUAL STEP — remove the old directory symlink first

```bash
stow --dir=stow/common --target="$HOME" --simulate --delete zsh
stow --dir=stow/common --target="$HOME" --delete zsh
stow --dir=stow/common --target="$HOME" --no-folding --simulate zsh
stow --dir=stow/common --target="$HOME" --no-folding zsh
```

**`fzf --zsh` reports an error:**

Your fzf version is older than 0.48. Check: `fzf --version`. Options:
- Upgrade fzf.
- In your `shared.zsh`, replace `eval "$(fzf --zsh)"` with the manual integration path for your fzf install method (see `~/.fzf.zsh` or `/usr/share/fzf/key-bindings.zsh`).

**Oh My Posh does not activate:**

Confirm both guards pass:

```bash
command -v oh-my-posh && echo "binary ok" || echo "binary missing"
ls "${XDG_CONFIG_HOME:-$HOME/.config}/omp/omp.toml" && echo "config ok" || echo "config missing"
```

If the config is missing, ensure the `common/omp` Stow package has been stowed and `omp.toml` exists.

**`local.zsh` changes not taking effect:**

Confirm `local.zsh` is at `~/.config/zsh/local.zsh` (not inside the repo):

```bash
ls -la "$HOME/.config/zsh/local.zsh"
# Expected: a regular file (not a symlink)
```

Open a new shell after saving changes — `local.zsh` is sourced at shell startup, not dynamically.

---

## 12. Expected final file layout

After all steps are complete, `~/.config/zsh/` should look like this:

```
~/.config/zsh/                             (real directory — created by Stow)
├── index.zsh          -> …/stow/common/zsh/.config/zsh/index.zsh
├── shared.zsh         -> …/stow/common/zsh/.config/zsh/shared.zsh
├── macos.zsh          -> …/stow/common/zsh/.config/zsh/macos.zsh   (macOS only)
├── arch.zsh           -> …/stow/common/zsh/.config/zsh/arch.zsh    (Arch only)
├── omp.zsh            -> …/stow/common/zsh/.config/zsh/omp.zsh     (if you copied omp.zsh.example)
├── index.zsh.example  -> …/stow/common/zsh/.config/zsh/index.zsh.example
├── shared.zsh.example -> …/stow/common/zsh/.config/zsh/shared.zsh.example
├── macos.zsh.example  -> …/stow/common/zsh/.config/zsh/macos.zsh.example
├── arch.zsh.example   -> …/stow/common/zsh/.config/zsh/arch.zsh.example
├── omp.zsh.example    -> …/stow/common/zsh/.config/zsh/omp.zsh.example
├── zshrc.example      -> …/stow/common/zsh/.config/zsh/zshrc.example
└── local.zsh                              (real file — created by you; NOT a symlink)
```

Key properties:
- `~/.config/zsh/` itself is a **real directory**, not a symlink.
- Every `*.zsh` and `*.example` file is a **per-file symlink** into the repository.
- `local.zsh` is a **real file**, physically outside the repository.
- `~/.zshrc` is unchanged and unmanaged by this package.
```

**Validation:**

```bash
ls docs/guides/zsh-setup.md
# Expected: file exists

grep 'stow --adopt' docs/guides/zsh-setup.md
# Expected: no output (stow --adopt must not appear in the guide)

grep -c 'MANUAL STEP' docs/guides/zsh-setup.md
# Expected: 8 or more (each $HOME-touching command is marked)
```

**Rollback:**

```bash
rm docs/guides/zsh-setup.md
# or: git checkout -- docs/guides/zsh-setup.md (if already committed)
```

---

### Group D — Final validation (run after all tasks complete)

These tasks are read-only verification steps. They do not modify any file.

---

#### D1 — Syntax validation

```bash
for f in stow/common/zsh/.config/zsh/shared.zsh \
          stow/common/zsh/.config/zsh/index.zsh \
          stow/common/zsh/.config/zsh/shared.zsh.example \
          stow/common/zsh/.config/zsh/index.zsh.example \
          stow/common/zsh/.config/zsh/macos.zsh.example \
          stow/common/zsh/.config/zsh/arch.zsh.example \
          stow/common/zsh/.config/zsh/omp.zsh.example \
          stow/common/zsh/.config/zsh/zshrc.example; do
  zsh -n "$f" && echo "OK: $f" || echo "FAIL: $f"
done
# Expected: OK for every file, no FAIL lines
```

---

#### D2 — No outdated placeholders

```bash
grep -R "YOUR_HOMEBREW_PREFIX" stow/common/zsh/.config/zsh/
# Must return nothing

grep "YOUR_EDITOR\|YOUR_PAGER" stow/common/zsh/.config/zsh/shared.zsh
# Must return nothing (placeholders acceptable only in shared.zsh.example, not shared.zsh)
```

---

#### D3 — No platform leaks in shared files

```bash
grep -E '(brew |pacman |yay |paru |pbcopy|pbpaste|open |systemctl|git clone|curl .* \||wget )' \
  stow/common/zsh/.config/zsh/shared.zsh \
  stow/common/zsh/.config/zsh/shared.zsh.example
# Must return nothing
```

---

#### D4 — No personal aliases

```bash
grep -rE '(meteo|wttr|Paris|paris)' stow/common/zsh/.config/zsh/
# Must return nothing
```

---

#### D5 — All optional tool guards present

```bash
grep 'command -v fzf'        stow/common/zsh/.config/zsh/shared.zsh.example
# Must return a match

grep 'command -v zoxide'     stow/common/zsh/.config/zsh/shared.zsh.example
# Must return a match

grep 'command -v eza'        stow/common/zsh/.config/zsh/shared.zsh.example
# Must return a match

grep 'command -v brew'       stow/common/zsh/.config/zsh/macos.zsh.example
# Must return a match

grep 'command -v oh-my-posh' stow/common/zsh/.config/zsh/omp.zsh.example
# Must return a match
```

---

#### D6 — No network or install commands in startup files

```bash
grep -rE '(git clone|brew install|pacman -S|yay -S|pip install|npm install|curl .* \| (ba)?sh)' \
  stow/common/zsh/.config/zsh/
# Must return nothing
```

---

#### D7 — Stow dry-run against fake home (no real $HOME)

```bash
TEST_HOME="$(mktemp -d)"
stow --dir=stow/common --target="$TEST_HOME" --no-folding --simulate zsh
echo "exit: $?"
rm -rf "$TEST_HOME"
# Expected: exit: 0, no conflict output
```

---

#### D8 — Git staging check: no private files

```bash
git ls-files stow/common/zsh/.config/zsh/ \
  | grep -vE '(\.example$|\.gitignore$|/(index|shared)\.zsh$)'
# Must return nothing
# (Only index.zsh and shared.zsh are intentionally tracked real files)
```

---

#### D9 — `local.zsh` not tracked

```bash
git ls-files stow/common/zsh/.config/zsh/local.zsh
# Must return nothing
```

---

#### D10 — ADR files created

```bash
ls docs/decisions/003{3..9}-*.md docs/decisions/004{0..2}-*.md
# Must list 10 files
```

---

## Files Affected

### Group A — `.example` template updates

| File | Action |
|---|---|
| `stow/common/zsh/.config/zsh/macos.zsh.example` | Modified — alias uncommented, `YOUR_HOMEBREW_PREFIX` confirmed absent |
| `stow/common/zsh/.config/zsh/arch.zsh.example` | Modified — AUR guards and systemctl aliases added |
| `stow/common/zsh/.config/zsh/omp.zsh.example` | Modified — activation block uncommented, outdated instruction removed |
| `stow/common/zsh/.config/zsh/shared.zsh.example` | Verified — modified only if any required element is missing |
| `stow/common/zsh/.config/zsh/index.zsh.example` | Verified — modified only if diverged from correct structure |
| `stow/common/zsh/.config/zsh/index.zsh` | Verified — modified only if diverged |
| `stow/common/zsh/.config/zsh/zshrc.example` | Verified — meteo alias confirmed absent |

### Group B — ADR records

| File | Action |
|---|---|
| `docs/decisions/0033-shared-zsh-content-scope.md` | Created |
| `docs/decisions/0034-platform-layers-runtime-selected.md` | Created |
| `docs/decisions/0035-omp-zsh-double-guarded-prompt-file.md` | Created |
| `docs/decisions/0036-local-zsh-created-by-editor-not-example.md` | Created |
| `docs/decisions/0037-extended-aliases-excluded-from-examples.md` | Created |
| `docs/decisions/0038-histfile-at-home-not-xdg.md` | Created |
| `docs/decisions/0039-completion-guard-avoid-double-compinit.md` | Created |
| `docs/decisions/0040-fzf-zsh-integration-method.md` | Created |
| `docs/decisions/0041-zoxide-init-without-cmd-override.md` | Created |
| `docs/decisions/0042-eza-minimal-alias-only.md` | Created |

### Group C — Setup guide

| File | Action |
|---|---|
| `docs/guides/zsh-setup.md` | Created |

---

## Safety Checks

Before starting:

- [ ] Confirm `git status` shows no uncommitted changes to `stow/common/zsh/.config/zsh/` that are not part of this plan.
- [ ] Confirm `$HOME` has not been modified since the last review.
- [ ] Confirm `git ls-files stow/common/zsh/.config/zsh/ | grep -vE '\.example$|\.gitignore$|/(index|shared)\.zsh$'` returns nothing (no unexpected tracked real files).

During execution:

- [ ] No `$HOME` file is modified at any step in Groups A, B, or C.
- [ ] No Stow command is run against the real `$HOME`.
- [ ] No dependency is installed.
- [ ] Every command that touches `$HOME` in the guide (Group C) is marked `⚠️  MANUAL STEP — review before running`.
- [ ] `stow --adopt` does not appear in any file written.

---

## Rollback Strategy

### Group A (`.example` files)

For each modified `.example` or tracked `.zsh` file, revert individually:

```bash
git checkout -- stow/common/zsh/.config/zsh/macos.zsh.example
git checkout -- stow/common/zsh/.config/zsh/arch.zsh.example
git checkout -- stow/common/zsh/.config/zsh/omp.zsh.example
git checkout -- stow/common/zsh/.config/zsh/shared.zsh.example
git checkout -- stow/common/zsh/.config/zsh/index.zsh.example
git checkout -- stow/common/zsh/.config/zsh/index.zsh
git checkout -- stow/common/zsh/.config/zsh/zshrc.example
```

### Group B (ADR files)

Remove created files:

```bash
rm docs/decisions/003{3..9}-*.md
rm docs/decisions/004{0..2}-*.md
```

If any have been staged:

```bash
git rm --cached docs/decisions/003{3..9}-*.md
git rm --cached docs/decisions/004{0..2}-*.md
```

### Group C (setup guide)

Remove or revert:

```bash
rm docs/guides/zsh-setup.md
# or, if already committed:
git checkout -- docs/guides/zsh-setup.md
```

### Group D (validation)

No rollback needed — these tasks are read-only.

### $HOME

Nothing to roll back. No `$HOME` file is touched during implementation (Groups A–D are repo-only).

---

## Privacy Checklist (run before every commit)

- [ ] `git diff --staged` — inspect all staged content in full.
- [ ] No API keys, tokens, passwords, or credentials anywhere in staged content.
- [ ] No private hostnames, internal URLs, or company-specific identifiers.
- [ ] No real email addresses or real usernames.
- [ ] No machine-specific absolute paths (e.g., `/Users/youractualname/…`).
- [ ] All example values use `YOUR_*` placeholders or clearly generic defaults (`nvim`, `less`).
- [ ] `git ls-files stow/common/zsh/.config/zsh/ | grep -vE '\.example$|\.gitignore$|/(index|shared)\.zsh$'` returns nothing.
- [ ] `git ls-files stow/common/zsh/.config/zsh/local.zsh` returns nothing.

---

## Completion Criteria

- [ ] A1: `macos.zsh.example` passes `zsh -n`; contains `alias o='open'` (active); contains `command -v brew` guard; does not contain `YOUR_HOMEBREW_PREFIX`.
- [ ] A2: `arch.zsh.example` passes `zsh -n`; contains AUR helper guards; contains `alias sc='systemctl'` and `alias scu='systemctl --user'`.
- [ ] A3: `omp.zsh.example` passes `zsh -n`; double-guarded `if` block is active (not commented out); `grep 'command -v oh-my-posh'` returns a match.
- [ ] A4: `shared.zsh.example` passes `zsh -n`; all required elements present; no platform-specific content.
- [ ] A5: Both `index.zsh` and `index.zsh.example` pass `zsh -n`; contain exactly 4 guarded source steps; no logic, no env, no aliases.
- [ ] A6: `zshrc.example` passes `zsh -n`; no `meteo`, `wttr`, or `Paris` content.
- [ ] B1–B10: All 10 ADR files exist at `docs/decisions/003{3..9}-*.md` and `docs/decisions/004{0..2}-*.md`.
- [ ] C1: `docs/guides/zsh-setup.md` exists; contains all 12 required sections; no `stow --adopt`; all `$HOME`-touching commands marked `⚠️  MANUAL STEP — review before running`.
- [ ] D1–D10: All final validation commands pass with expected output.
- [ ] Privacy checklist completed and no issues found.
- [ ] Reviewer has approved this plan before Builder begins implementation.

---
