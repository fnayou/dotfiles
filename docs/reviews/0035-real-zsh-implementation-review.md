# Review: Real Zsh Configuration Adoption — Final Implementation

**Document:** docs/reviews/0035-real-zsh-implementation-review.md
**Reviewed:** implementation on branch feat/real-zsh-configuration (final state)
**Scope:** zsh package restructure, omp package integration, bootstrap tasks, setup guide
**Against:** docs/plans/0014-real-zsh-configuration-plan.md + referenced documents
**Reviewer:** Claude Code
**Date:** 2026-06-19
**Status:** Complete

---

## Verdict

**Changes required**

The implementation represents a valid and well-considered architectural evolution — promoting 12 real managed `.zsh` files to committed status (replacing the git-ignored `.example`-copy workflow) — but three correctness issues block approval:

1. **`completions.zsh` calls `compinit` unconditionally.** When Zinit is loaded (via `plugins.zsh`, which is sourced before `completions.zsh`), `compinit` runs twice. This violates ADR-0039, causes startup latency, and can produce security warnings about insecure completion directories. The `typeset -f zinit` guard must be added.

2. **`aliases.zsh` ships extended eza aliases (`ls='eza --long --icons'`, `ll='eza --long --all --header --icons'`).** ADR-0037 and ADR-0042 explicitly restrict committed templates to minimal, uncontroversial aliases only. `ls='eza'` (minimal redirect) is the permitted form; `eza --long --icons` with flags is an opinionated workflow choice that must live in `local.zsh`.

3. **`aliases.zsh` and `tools.zsh` both define an `ls='eza'` alias.** When eza is present, `aliases.zsh` sets `alias ls='eza --long --icons'` and `tools.zsh` later (it is sourced before `aliases.zsh`) sets `alias ls='eza'`. Actually tools.zsh is sourced BEFORE aliases.zsh per index.zsh, so aliases.zsh overwrites tools.zsh. The two files have overlapping responsibilities for the `ls` alias; one must be authoritative.

The structural deviation from Plan-0014 (`.example`-copy approach → 12 committed real files) is an evolution beyond the plan scope. It is not itself a blocker, but it requires confirming all safety and privacy invariants under the new model, and several non-blocking issues arise from this deviation.

---

## Blockers

### Blocker 1 — `completions.zsh`: unconditional `compinit` causes double-init with Zinit

**File:** `stow/common/zsh/.config/zsh/completions.zsh`, lines 3–4

```zsh
autoload -Uz compinit
compinit
```

**Problem:** `plugins.zsh` is sourced at step 5 and loads Zinit (if installed). Zinit manages `compinit` internally. `completions.zsh` is sourced at step 6 and calls `compinit` unconditionally. On machines where Zinit is installed, `compinit` runs twice per shell startup. ADR-0039 explicitly forbids this pattern and requires the `typeset -f zinit` guard.

**Required fix:**

```zsh
# completions.zsh — zsh completion initialization and styles
# Guard: run compinit only when Zinit is not loaded (Zinit manages compinit internally).
if ! typeset -f zinit >/dev/null 2>&1; then
  autoload -Uz compinit && compinit
fi
```

The `zstyle` lines below the compinit call are fine and do not need to change.

---

### Blocker 2 — `aliases.zsh`: extended eza aliases violate ADR-0037 and ADR-0042

**File:** `stow/common/zsh/.config/zsh/aliases.zsh`, lines 4–8

```zsh
if command -v eza >/dev/null 2>&1; then
  alias ls='eza --long --icons'
  alias ll='eza --long --all --header --icons'
else
  alias ll='ls -ahl'
fi
```

**Problem:** ADR-0037 restricts committed templates to "minimal, guarded, uncontroversial aliases". ADR-0042 specifies `alias ls='eza'` as the only permitted eza alias in committed files. `eza --long --icons` is opinionated (enables long format and icons by default for the `ls` command), and `ll='eza --long --all --header --icons'` is an extended alias that ADR-0042 explicitly reserves for `local.zsh`. Committing these aliases imposes workflow choices on all machines.

The `else` branch (`alias ll='ls -ahl'`) compounds the issue: it creates a non-guarded `ll` alias that shadows any `ll` function the user may have defined.

**Required fix:**

```zsh
# aliases.zsh — portable aliases
alias grep='grep --color=auto'
command -v eza >/dev/null 2>&1 && alias ls='eza'
```

Extended eza aliases (`ll`, `la`, `lt`, tree variants) belong in `local.zsh` or the user's personal config.

---

### Blocker 3 — `aliases.zsh` and `tools.zsh` both define `ls='eza'` alias (redundant overlap)

**Files:** `stow/common/zsh/.config/zsh/tools.zsh` (line 4) and `stow/common/zsh/.config/zsh/aliases.zsh` (lines 4–6)

Both files guard `ls` with `command -v eza`. Since `tools.zsh` is sourced at step 8 and `aliases.zsh` at step 9, `aliases.zsh` overwrites `tools.zsh`'s alias. This means:
- `tools.zsh` sets `alias ls='eza'` (minimal, correct per ADR-0042).
- `aliases.zsh` then overwrites with `alias ls='eza --long --icons'` (extended, violates ADR-0042).

Once Blocker 2 is fixed (aliases.zsh reduced to `alias ls='eza'`), the `ls` alias in `tools.zsh` becomes redundant. **Recommended:** remove `alias ls='eza'` from `tools.zsh` and keep it in `aliases.zsh` as the single authoritative location. Or vice versa — one of the two must own it.

---

## Non-Blocking Notes

### Note 1 — Structural deviation: 12 committed real files vs plan's `.example`-copy model

The plan (Plan-0014) called for `.example` files where the user copies each to its real name, fills in placeholders, and the real file is git-ignored. The implementation instead commits 12 real managed `.zsh` files directly, removes the `.example` files (except `local.zsh.example` and `zshrc.example`), and updates `.gitignore` to ignore only `local.zsh`. The architecture doc (0010) was written for the 4-file `.example` model.

This is a legitimate architectural evolution. The new model is arguably simpler (no copy step, no placeholder replacement, no `--restow` required for new files) and consistent with how most dotfile repositories work. However:
- The architecture document (0010) is now out of sync with the implementation (still describes the `.example`-copy workflow).
- ADR-0025 ("Real managed files linked by physical presence; `.example` templates are the only versioned source of truth") is superseded by this change.
- ADR-0033 through ADR-0042 remain valid in spirit but their references to `.example` templates may be misleading.

**Recommended:** After this review, update the architecture doc §1 file layout table to reflect the 12-file committed model, and mark ADR-0025 as superseded. These are documentation clean-ups, not blocking.

---

### Note 2 — `plugins.zsh`: Zinit plugin declarations are in scope of this PR

`plugins.zsh` declares four Zinit plugins:

```zsh
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab
```

PRD-0010 explicitly states "Do not configure Zinit plugins in this PRD — Zinit plugin adoption is a separate initiative." Architecture §8 says "Plugin adoption is out of scope for PRD-0010." This is a scope expansion. However, the plugins are inside the `[[ -r "$ZINIT_HOME/zinit.zsh" ]]` guard, so they are a no-op when Zinit is absent, and they are reasonable, widely-used plugins. The safety constraint is met.

**Status:** Non-blocking. The plugins are safe and guarded. The scope violation is minor. If the user accepts this addition as part of the final implementation, no further action is required. If strict scope is enforced, these four lines should move to `local.zsh` until a dedicated plugin-adoption plan is approved.

---

### Note 3 — `VISUAL="${VISUAL:-zed}"` in `shared.zsh` may not be portable to Arch

`shared.zsh` exports `VISUAL` with `zed` as the default. `zed` is a GUI editor available on macOS and Linux but requires separate installation and a graphical environment. On a headless Arch server or a machine without Zed installed, `VISUAL="zed"` is set but resolves to a missing binary. The `${VISUAL:-zed}` pattern prevents overwriting an existing `VISUAL`, but it does set it on machines where `VISUAL` is not pre-set.

For comparison, `EDITOR="nvim"` is guarded the same way and has the same portability concern (nvim may not be installed). However, `nvim` is widely understood as a placeholder that the user would override in `local.zsh`.

**Recommendation:** Add a comment to `shared.zsh` noting that `zed` and `nvim` should be overridden in `local.zsh` if the respective tools are not installed.

---

### Note 4 — `prompt.zsh` uses `[[ -r ... ]]` instead of `[[ -f ... ]]` for `omp.toml`

`prompt.zsh` line 5:
```zsh
if command -v oh-my-posh >/dev/null 2>&1 && [[ -r "$HOME/.config/omp/omp.toml" ]]; then
```

The architecture document (§5) and PRD specified `[[ -f … omp.toml ]]`. `[[ -r ]]` checks readability rather than file existence. On well-configured systems these are equivalent, but `[[ -f ]]` is more precise (tests that the path is a regular file). Also, `prompt.zsh` uses the hardcoded `$HOME/.config/omp/omp.toml` path instead of the XDG fallback `${XDG_CONFIG_HOME:-$HOME/.config}/omp/omp.toml` specified in the architecture. Since `shared.zsh` exports `XDG_CONFIG_HOME` before `prompt.zsh` is sourced, this works in practice but is inconsistent with the double-guard pattern documented in ADR-0035.

**Impact:** Very low. `[[ -r ]]` works correctly in all practical cases. Path hardcoding works because `shared.zsh` sets `XDG_CONFIG_HOME` before `prompt.zsh` is sourced.

---

### Note 5 — `local.zsh.example` exists (ADR-0036 said no example for `local.zsh`)

ADR-0036 explicitly decided: "No `.example` template exists for `local.zsh` in the repo. This is intentional." The rationale: a template implies canonical structure for private, machine-specific content.

The implementation introduces `local.zsh.example` as a "skeleton showing what private overrides look like." The guide instructs the user to `cp stow/common/zsh/.config/zsh/local.zsh.example ~/.config/zsh/local.zsh`.

This is a pragmatic departure from ADR-0036. The file contains only comment lines with no active code, which mitigates the risk of a user accidentally committing private content. However, the setup guide now directs a copy workflow that places `local.zsh` via `cp` from the example rather than via `$EDITOR` directly — this slightly weakens the ADR-0036 rationale (the example could be mistakenly copied into the repo and committed).

**Status:** Non-blocking. The example file is harmless (comments only). If the user wishes to maintain ADR-0036, the example should be removed. Otherwise ADR-0036 should be updated to reflect this decision.

---

### Note 6 — `omp.toml` committed: approach change from "git-ignored local copy" to "committed real file"

The old `omp` package had `omp.toml.example` (committed) and `omp.toml` (git-ignored, user fills in). The new implementation commits `omp.toml` directly (a real theme file, no placeholders). The `omp/.gitignore` was updated accordingly.

This is consistent with the new approach of committing real managed files. The `omp.toml` content is reviewed: it contains no secrets, no private paths, and no machine-specific values — it is a portable TOML theme configuration with only UI colors and formatting rules. The commit is safe from a privacy standpoint.

**Consequence:** Any machine that stows the `omp` package gets the same theme. Users who want a different theme must create a local override (not currently documented in the guide). This is acceptable but worth noting.

---

### Note 7 — `zsh:bootstrap` block syntax differs from `zshrc.example` block syntax

`zsh:bootstrap` appends:
```zsh
# >>> dotfiles managed zsh layer >>>
if [[ -r "$HOME/.config/zsh/index.zsh" ]]; then
  source "$HOME/.config/zsh/index.zsh"
fi
# <<< dotfiles managed zsh layer <<<
```

`zshrc.example` shows:
```zsh
# >>> dotfiles managed (zsh) — added manually; delete this block to disable >>>
[[ -r "$HOME/.config/zsh/index.zsh" ]] && source "$HOME/.config/zsh/index.zsh"
# <<< dotfiles managed (zsh) <<<
```

The block markers differ (`dotfiles managed zsh layer` vs `dotfiles managed (zsh) — added manually; delete this block to disable`). Both are functionally correct, but a user who manually added the `zshrc.example` block before running `task zsh:bootstrap` would have two different blocks. The idempotency check looks for `# >>> dotfiles managed zsh layer >>>`, so it would not detect the manual block and would append a second block.

**Recommended fix:** Align `zshrc.example` and `zsh:bootstrap` to use identical markers.

---

### Note 8 — `keybindings.zsh` autosuggest guard uses `zle -l` which may suppress errors

```zsh
if typeset -f _zsh_autosuggest_accept >/dev/null 2>&1 || zle -l autosuggest-accept >/dev/null 2>&1; then
  bindkey '^L' autosuggest-accept
fi
```

The `zle -l autosuggest-accept` call lists zle widgets and checks if `autosuggest-accept` is present. `zle -l` outputs to stdout; redirecting to `/dev/null 2>&1` suppresses it. The guard is logically correct. However, `zle -l` can be slow on some zsh configurations (it lists all widgets). The `typeset -f _zsh_autosuggest_accept` check is faster and sufficient if `zsh-autosuggestions` is loaded via Zinit (which it is in `plugins.zsh`). The `||` means the `zle -l` fallback is only reached when `typeset -f` fails.

**Status:** Non-blocking. The guard is correct and functional.

---

## Checklist Results

| # | Check | Result | Notes |
|---|-------|--------|-------|
| 1 | All safe `.zsh.example` files promoted to real managed `.zsh` files (no `.zsh.example` files exist except `local.zsh.example`) | Pass | 12 real `.zsh` files committed. No `.zsh.example` files remain except `local.zsh.example` and `zshrc.example`. |
| 2 | `local.zsh.example` is the only remaining `.example` file in the zsh package | Pass | Only `local.zsh.example` and `zshrc.example` remain. `zshrc.example` is a reference template, not a config file. |
| 3 | `local.zsh` is not tracked by git | Pass | `git ls-files stow/common/zsh/.config/zsh/local.zsh` produces no output. File does not physically exist. |
| 4 | `zshrc.example` is kept as reference (not sourced) | Pass | `zshrc.example` is present. `index.zsh` does not source it. |
| 5 | `index.zsh` sources only real `.zsh` files — no `.example` files | Pass | `grep '\.example' index.zsh` returns no matches. |
| 6 | `index.zsh` sources `local.zsh` last | Pass | `local.zsh` is sourced at step 11 — the final source call in `index.zsh`. |
| 7 | `index.zsh` source order matches architecture spec (path → shared → history → platform → plugins → completions → keybindings → tools → aliases → prompt → local) | Pass | Actual order: path(1), shared(2), history(3), platform(4), plugins(5), completions(6), keybindings(7), tools(8), aliases(9), prompt(10), local(11). Matches checklist spec exactly. |
| 8 | No `$HOME` files were modified by Builder steps | Pass | Git diff shows no `$HOME` modifications. All changes are within the repository. |
| 9 | Real `~/.zshrc` was not modified | Pass | `~/.zshrc` is not in the working tree diff. `zsh:bootstrap` was not run. |
| 10 | No real-home Stow was run | Pass | No stow command against real `$HOME` was executed during implementation. |
| 11 | `zsh:bootstrap` was not run during implementation | Pass | No evidence of bootstrap execution. `~/.zshrc` unchanged. |
| 12 | `zsh:bootstrap:dry-run` contains no write operations to `$HOME` or any file | Pass | Task uses only echo, printf (to stdout), grep, and conditional checks. No `>>`, `cp`, `mv`, `rm`, or `cat >` in dry-run task body. |
| 13 | `zsh:bootstrap` refuses if `~/.zshrc` is a symlink (exit 1) | Pass | Taskfile.yml line 174: `if [[ -L "$ZSHRC" ]]; then` / `exit 1`. |
| 14 | `zsh:bootstrap` creates a timestamped backup before modifying existing `~/.zshrc` | Pass | Taskfile.yml line 183: `BACKUP="${ZSHRC}.bak.$(date +%Y%m%d%H%M%S)"`. |
| 15 | `zsh:bootstrap` checks for block marker before appending (idempotent) | Pass | Taskfile.yml line 179: `grep -qF "$BLOCK_MARKER" "$ZSHRC"` before any append. |
| 16 | `zsh:bootstrap` appends only the managed block — does not overwrite | Pass | Uses `printf ... >> "$ZSHRC"` (append). No overwrite. |
| 17 | No task lists `zsh:bootstrap` as a dependency | Pass | No `deps:` key references `zsh:bootstrap` in any task. |
| 18 | Setup guide marks `zsh:bootstrap` as `⚠️  MANUAL STEP` | Pass | Step 3b: "⚠️  MANUAL STEP — review dry-run output before running" precedes `task zsh:bootstrap`. |
| 19 | Setup guide uses direct `--no-folding` Stow commands for zsh (not `task dry-run`) | Pass | Step 1 and Step 2 both use direct `stow --dir=stow/common --target="$HOME" --no-folding ...` commands. Guide notes `task dry-run` does not pass `--no-folding`. |
| 20 | Setup guide uses `--no-folding` for omp Stow commands | Pass | Step 4 uses `stow --dir=stow/common --target="$HOME" --no-folding --simulate omp` and `stow --dir=stow/common --target="$HOME" --no-folding omp`. |
| 21 | Oh My Posh theme is in `stow/common/omp/.config/omp/omp.toml` (not in zsh package) | Pass | `omp.toml` is in the omp package. The zsh package contains `prompt.zsh` which references the omp path but does not own the theme file. |
| 22 | `prompt.zsh` guards OMP with `command -v oh-my-posh` AND `[[ -r … omp.toml ]]` | Pass | `prompt.zsh` line 5: `if command -v oh-my-posh >/dev/null 2>&1 && [[ -r "$HOME/.config/omp/omp.toml" ]]; then`. Both guards present. Uses `[[ -r ]]` instead of `[[ -f ]]` per architecture spec — minor deviation (see Note 4). |
| 23 | No shell startup file installs dependencies (no brew install, git clone, pacman etc.) | Pass | `plugins.zsh` comment references `git clone` for manual Zinit install but no active install code. `arch.zsh` has `alias paci='sudo pacman -S'` — this is an alias definition, not an active install command. No network access at startup. |
| 24 | No shell startup file performs network access at startup | Pass | All tool integrations are `command -v` or `[[ -r ]]` guards. No curl, wget, or git clone in active code. |
| 25 | Zinit sourced only if installed — no auto-clone, no auto-mkdir | Pass | `plugins.zsh`: `if [[ -r "$ZINIT_HOME/zinit.zsh" ]]; then source ... fi`. No auto-clone. No directory creation. |
| 26 | fzf guarded with `command -v fzf` | Pass | `tools.zsh` line 2: `command -v fzf >/dev/null 2>&1 && eval "$(fzf --zsh)"`. |
| 27 | zoxide guarded with `command -v zoxide` | Pass | `tools.zsh` line 3: `command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"`. |
| 28 | eza aliases guarded with `command -v eza` | Pass | Both `tools.zsh` (line 4) and `aliases.zsh` (lines 4–8) guard eza usage. However see Blocker 2 and Blocker 3. |
| 29 | autosuggest keybinding guarded by widget existence check | Pass | `keybindings.zsh` lines 5–7: `typeset -f _zsh_autosuggest_accept` OR `zle -l autosuggest-accept` before bindkey. |
| 30 | Homebrew uses `command -v brew >/dev/null 2>&1 && eval "$(brew shellenv)"` | Pass | `macos.zsh` lines 4–6: `if command -v brew >/dev/null 2>&1; then eval "$(brew shellenv)"; fi`. Equivalent if/fi form. |
| 31 | `~/.zshrc.local` convention is absent from all committed files | Pass | No reference to `zshrc.local` or `.zshrc.local` in any committed file. |
| 32 | No secrets, credentials, private hostnames, private paths, tokens, or machine-specific values in any committed file | Pass | `grep -rE '/Users/fnayou\|/home/fnayou'` returns nothing. No API keys, passwords, or private identifiers found. |
| 33 | OMP theme file (`omp.toml`) contains no secrets or private paths | Pass | `omp.toml` contains only TOML version, UI colors (hex values), and formatting templates. No hostnames, usernames, tokens. |
| 34 | `stow/common/zsh/.stow-local-ignore` protects `local.zsh` from being stowed | Pass | `.stow-local-ignore` line 7: `^/\.config/zsh/local\.zsh$`. |
| 35 | `stow/common/omp/.stow-local-ignore` exists | Pass | File present at `stow/common/omp/.stow-local-ignore`. |
| 36 | `zsh/.gitignore` only ignores `local.zsh` | Pass | Updated `.gitignore` contains only `local.zsh` (plus comment). All 12 managed `.zsh` files are now intended as tracked real files, not git-ignored. |
| 37 | All 12 managed `.zsh` files pass `zsh -n` syntax check | Pass | All 12 files (index, shared, path, history, completions, keybindings, aliases, tools, plugins, prompt, macos, arch) return exit 0 from `zsh -n`. |
| 38 | Fake-home Stow dry-run passes for zsh with `--no-folding` | Pass | `stow --dir=stow/common --target=$TEST_HOME --no-folding --simulate zsh` exits 0 with no conflict output (only the expected simulation mode warning). |
| 39 | Fake-home Stow dry-run passes for omp with `--no-folding` | Pass | `stow --dir=stow/common --target=$TEST_HOME --no-folding --simulate omp` exits 0. |
| 40 | Plan lifecycle status is `Complete` (per DOCUMENT-LIFECYCLE.md) | Pass | `docs/plans/0014-real-zsh-configuration-plan.md` `**Status:** Complete`. |

---

## Validation Results

| Check | Command | Result |
|---|---|---|
| 1. Syntax — all 12 managed `.zsh` files | `zsh -n` on each of 12 files | PASS — all 12 return exit 0 |
| 2. `index.zsh` sources no `.example` files | `grep '\.example' index.zsh` | PASS — no matches |
| 3. `local.zsh` not tracked | `git ls-files stow/.../local.zsh` (check empty output) | PASS — no output (file does not exist, not tracked) |
| 4. No install/network commands in startup files | `grep -rE '(git clone\|brew install\|pacman -S\|yay -S\|...)' .../*.zsh` | PASS — matches are: (a) comment-only `git clone` reference in `plugins.zsh`; (b) `alias paci='sudo pacman -S'` in `arch.zsh` (alias definition, not active install); (c) `alias pacu='sudo pacman -Syu'` same. No active network commands. |
| 5. Optional tool guards | `grep 'command -v brew'` in macos.zsh | PASS |
| 5. Optional tool guards | `grep 'command -v oh-my-posh'` in prompt.zsh | PASS |
| 5. Optional tool guards | `grep 'command -v fzf'` in tools.zsh | PASS |
| 5. Optional tool guards | `grep 'command -v zoxide'` in tools.zsh | PASS |
| 5. Optional tool guards | `grep 'command -v eza'` in tools.zsh | PASS |
| 6. No hardcoded brew prefix | `grep -r '/usr/local/bin/brew\|/opt/homebrew/bin/brew' .../zsh/` | PASS |
| 7. No `.zshrc.local` pattern | `grep -r 'zshrc\.local\|\.zshrc\.local' .../zsh/*.zsh` | PASS |
| 8. No private paths | `grep -rE '/Users/fnayou\|/home/fnayou' .../zsh/ .../omp/` | PASS |
| 9. Fake-home Stow dry-run — zsh | `stow ... --no-folding --simulate zsh` against `mktemp -d` | PASS |
| 10. Fake-home Stow dry-run — omp | `stow ... --no-folding --simulate omp` against `mktemp -d` | PASS |
| 11. Taskfile bootstrap tasks present | `task --list` shows `zsh:bootstrap` and `zsh:bootstrap:dry-run` | PASS |
| 12. No task depends on `zsh:bootstrap` | `grep 'deps:.*zsh:bootstrap'` in Taskfile.yml | PASS |
| 13. `zsh:bootstrap:dry-run` has no write operations | `awk ... grep -E '(>>\|cp \|mv \|rm \|cat >)'` on dry-run section | PASS |
| 14. `zsh:bootstrap` has symlink check | `grep '\-L.*ZSHRC\|symlink' Taskfile.yml` | PASS — lines 136, 174 |
| 15. `zsh:bootstrap` has timestamped backup | `grep 'bak.*date\|BACKUP.*date' Taskfile.yml` | PASS — line 183 |

---

## Required Fixes Before Commit

The following changes must be made before this implementation may be committed:

**Fix 1 — `completions.zsh` (Blocker 1):**

Replace:
```zsh
autoload -Uz compinit
compinit
```
With:
```zsh
if ! typeset -f zinit >/dev/null 2>&1; then
  autoload -Uz compinit && compinit
fi
```

**Fix 2 — `aliases.zsh` (Blocker 2 + Blocker 3):**

Replace the entire eza block with:
```zsh
# aliases.zsh — portable aliases
alias grep='grep --color=auto'
command -v eza >/dev/null 2>&1 && alias ls='eza'
```

**Fix 3 — `tools.zsh` (Blocker 3 — remove redundant `ls` alias):**

Remove the `alias ls='eza'` line from `tools.zsh` so that `aliases.zsh` is the single authoritative location. Or, alternatively, remove the eza alias from `aliases.zsh` and keep it in `tools.zsh` alongside the other tool guards — either arrangement is acceptable, but both must not define the same alias.

After applying these three fixes, re-run the checklist items for items 28, 37, and any item affected by the Zinit double-compinit issue.
