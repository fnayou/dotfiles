# Architecture: Zsh Managed-Layer Activation (`--no-folding`)

**Number:** 0008
**Status:** Approved
**Date:** 2026-06-18
**Platform:** Common (macOS + Arch/EndeavourOS)
**PRD:** [0008-zsh-managed-layer-activation.md](../prd/0008-zsh-managed-layer-activation.md)
**Related:** Architecture 0007 (zsh activation & migration), Review 0024 (manual migration validation), ADR-0016, ADR-0017, ADR-0020, ADR-0021, ADR-0023

---

## Context

PRD 0008 closes the two gaps Review 0024 confirmed against the **actual filesystem state**:

1. **Functional gap (not a defect):** the real managed files (`index.zsh`, `shared.zsh`, …) were never created — only `*.example` templates exist — so the `~/.zshrc` include guard `[[ -r "$HOME/.config/zsh/index.zsh" ]]` evaluates false and the layer is inert. The guard behaving as a no-op is correct, safe design.
2. **Strategy drift:** Stow claimed `~/.config/zsh` as a **directory fold** — one directory symlink `~/.config/zsh → …/stow/common/zsh/.config/zsh` — not the per-file symlinks `docs/stow-usage.md` depicts (Review 0024, Issue 3). With folding, `~/.config/zsh` **is** the repo package directory: any non-managed file dropped there is written inside the repo tree, and there is no place for a real, unversioned `local.zsh` boundary between managed (versioned) and private (unversioned) content.

Confirmed start state (Review 0024):

- `~/.config/zsh` — single directory-fold symlink into the repo package dir. **Not** per-file symlinks.
- `~/.zshrc` — user-managed **regular file** (7 lines, not a symlink), containing the guarded include block (`[[ -r "$HOME/.config/zsh/index.zsh" ]] && source …`). `$ZDOTDIR` unset.
- Only `*.example` templates in the package; real managed files absent → layer inert. Safety **PASS**, Privacy **PASS**.

PRD 0008 **decision:** switch the intended stow strategy to **`--no-folding`** (explicit per-file symlinks), keep `local.zsh` as a **real file outside the repo** (unversioned), and define a safe, reviewable, reversible migration from the current folded state. This document translates that into concrete structure, commands, and decisions. It **implements nothing, modifies no `$HOME` file, runs no Stow, creates no symlink, installs nothing, and never auto-activates Oh My Posh or auto-clones Zinit.**

### Established decisions entering this architecture

- **ADR-0001** — Platform-first Stow layout (`stow/<area>/<package>/`); `common/` requires identical path, portable values, no platform tool at package level.
- **ADR-0003** — `.example` files for any config that may carry identity/sensitive values.
- **ADR-0016** — All zsh-sourced files live in `stow/common/zsh/`; runtime OS detection governs what loads; `~/.zshrc` is never stowed.
- **ADR-0017** — Fake-home (`mktemp -d`) `--simulate` validation when the real `~/.config/<pkg>/` already exists; a real-home conflict is a stop signal, never an `--adopt` trigger.
- **ADR-0020** — Zinit installed by a documented one-time manual `git clone`; sourced behind a guard; never auto-cloned at startup.
- **ADR-0021** — Single guarded `~/.zshrc` include block + managed `index.zsh` entry point; `~/.zshrc` never auto-edited, never stowed.
- **ADR-0023** — `local.zsh` is the git-ignored, last-sourced override slot.
- **Architecture 0007** — Model 4 → Model 3 activation; `index.zsh` owns source order; every source guarded.

### What this architecture changes vs. Architecture 0007

Architecture 0007 left folding-vs-`--no-folding` unstated and assumed `local.zsh` could sit as a git-ignored real file *inside the folded repo dir*. This architecture supersedes that detail: it makes **`--no-folding` the intended stow shape** for the zsh package and relocates `local.zsh` to a **real, unversioned file outside the repo**, created directly under `~/.config/zsh/`. Everything else from 0007 (guarded include block, `index.zsh` orchestration, guarded layers) is preserved unchanged.

---

## Constraints

Carried from PRD 0008:

- Must NOT modify `~/.zshrc`, or modify/create/move/delete any file under `$HOME`.
- Must NOT run Stow (no install, `--restow`, `--delete`, or `--no-folding` execution).
- Must NOT create or overwrite symlinks; must NOT use `stow --adopt` ever.
- Must NOT install dependencies or clone Zinit.
- Migration/activation are **manual user steps** — no script, bootstrap, or shell init may auto-copy, auto-stow, or auto-create symlinks.
- Every risky command carries the `⚠️  MANUAL STEP` marker, with a `--simulate` dry-run shown before any real `--delete` / `--no-folding` stow.
- No `$HOME` file content quoted in docs/validation — presence/resolution/load-marker checks only (mirror Review 0024).
- macOS and Arch material never mixed in one file or command.

---

## 1. Using `--no-folding` for Zsh

**Intended command shape** (later plan, user-run; shown, not executed):

```
⚠️  MANUAL STEP — review dry-run output before running
stow --dir=stow/common --target="$HOME" --no-folding zsh
```

`--no-folding` forces Stow to create the target directory `~/.config/zsh/` as a **real directory** and then symlink **each tracked file individually** into it, instead of collapsing the whole directory into one symlink.

**Resulting per-file layout** (only files physically present are linked — see Section 4 for which files exist):

```
~/.config/zsh/                         (REAL directory — created by Stow, owned by Stow)
├── index.zsh        -> …/works/dotfiles/stow/common/zsh/.config/zsh/index.zsh
├── shared.zsh       -> …/works/dotfiles/stow/common/zsh/.config/zsh/shared.zsh
├── macos.zsh        -> …/works/dotfiles/stow/common/zsh/.config/zsh/macos.zsh
├── arch.zsh         -> …/works/dotfiles/stow/common/zsh/.config/zsh/arch.zsh
├── omp.zsh          -> …/works/dotfiles/stow/common/zsh/.config/zsh/omp.zsh   (only if real omp.zsh exists)
├── *.example        -> …  (the .example templates also symlink in; harmless reference copies)
└── local.zsh        (REAL FILE — created by the user directly here; NOT a symlink, NOT in repo)
```

Each new managed file requires a re-stow to create its link:

```
⚠️  MANUAL STEP — review dry-run output before running
stow --dir=stow/common --target="$HOME" --no-folding --restow zsh
```

This per-file re-stow cost is accepted and explicit by design (PRD 0008 trade-off).

---

## 2. Why Folding Is NOT Preferred

Folding is Stow's default when the target directory does not pre-exist: it replaces the whole `~/.config/zsh/` with one directory symlink into the repo. Review 0024 Issue 3 confirmed this is the current state. Concrete drawbacks:

| Drawback | Detail |
|---|---|
| **`~/.config/zsh` *is* the repo dir** | The folded symlink means writing to `~/.config/zsh/anything` writes into `…/stow/common/zsh/.config/zsh/anything` — inside the repo tree. There is no separation between "what the OS writes here" and "what the repo owns." |
| **No managed/private boundary** | There is no place for a real, unversioned `local.zsh`. Anything created in `~/.config/zsh/` lands in the repo and is subject to `git status`; the only thing keeping it uncommitted is `.gitignore`, not a filesystem boundary. PRD 0008 requires `local.zsh` to live *outside* the repo. |
| **Non-managed drops pollute the repo** | A tool (or the user) dropping a cache/state/scratch file into `~/.config/zsh/` silently creates a file in the repo working tree (Review 0024, Issue 3). |
| **Diverges from documented model** | `docs/stow-usage.md` depicts per-file symlinks (`~/.config/zsh/shared.zsh → …`); folding produces a directory-level link instead (Review 0024, Issue 3). |
| **Coarse revert granularity** | `stow --delete` removes the *entire* directory link at once; there is no per-file managed surface to reason about. |

`--no-folding` resolves all five: `~/.config/zsh/` is a **real directory** Stow owns, managed files are individual symlinks, and a real `local.zsh` can live alongside them without entering the repo.

---

## 3. Safe Migration From the Folded State

Target: real `~/.config/zsh/` directory + per-file symlinks + real `local.zsh`. Ordered manual steps; **none executed here**. `~/.zshrc` is never touched by any step below.

**Step 0 — Pre-migration verification (read-only, see Section 12).** Confirm `~/.config/zsh` is the folded directory symlink, `~/.zshrc` contains the guarded block, `$ZDOTDIR` unset.

**Step 1 — Dry-run the delete of the fold:**

```
⚠️  MANUAL STEP — review before running
stow --dir=stow/common --target="$HOME" --simulate --delete zsh
```

Expected: Stow reports it would remove the single `~/.config/zsh` directory symlink. `~/.zshrc` is not mentioned (it is not stowed). If anything else appears, **STOP**.

**Step 2 — Delete the fold** (removes only the `~/.config/zsh` directory symlink; the repo files are untouched, `~/.zshrc` untouched):

```
⚠️  MANUAL STEP — review dry-run output first
stow --dir=stow/common --target="$HOME" --delete zsh
```

**Step 3 — Dry-run the `--no-folding` restow, then execute** (only after the dry-run is clean):

```
⚠️  MANUAL STEP — review before running
stow --dir=stow/common --target="$HOME" --no-folding --simulate zsh
```
```
⚠️  MANUAL STEP — review dry-run output before running
stow --dir=stow/common --target="$HOME" --no-folding zsh
```

Expected: Stow creates the real directory `~/.config/zsh/` and a per-file symlink for each file present (the managed real files plus the `.example` templates).

**Step 4 — Copy templates to real managed files, then re-stow** (Section 4). At minimum `index.zsh` to activate.

**Step 5 — Create `local.zsh` as a REAL file directly in `~/.config/zsh/`** (Section 5) — not copied from the repo, never symlinked.

**Conflict handling (all steps):** if any dry-run reports a conflict — including `existing target is not owned by stow: .config/zsh` after a partial state — **STOP and resolve manually** per `docs/stow-usage.md` → "Conflict handling." **Never use `--adopt`** (AGENTS §8, ADR-0017): it silently overwrites and cannot be undone. A directory-ownership conflict is a stop signal, not a flag to bypass. Use fake-home validation (Section 12) to confirm package layout independently of the real-home conflict.

---

## 4. Which `.example` Files Become Real MANAGED (Symlinked) Files

Based on the actual package contents (`ls stow/common/zsh/.config/zsh/`): `index.zsh.example`, `shared.zsh.example`, `macos.zsh.example`, `arch.zsh.example`, `omp.zsh.example`, `zshrc.example`, `.gitignore`.

| `.example` | Real managed file | Role | Become real & symlinked? |
|---|---|---|---|
| `index.zsh.example` | `index.zsh` | Entry point; owns source order; referenced by the `~/.zshrc` block. **Minimum to activate.** | **Yes** |
| `shared.zsh.example` | `shared.zsh` | Portable env/history/completion + guarded fzf/zoxide/eza/zinit. | **Yes (recommended)** |
| `macos.zsh.example` | `macos.zsh` | macOS-only (Homebrew `shellenv`, macOS aliases); sourced on macOS only. | **Yes on macOS** (harmless symlink on Arch) |
| `arch.zsh.example` | `arch.zsh` | Arch-only (PATH, AUR helper); sourced on Arch only. | **Yes on Arch** (harmless symlink on macOS) |
| `omp.zsh.example` | `omp.zsh` | Guarded Oh My Posh `eval`; opt-in. | **Optional** — only if the user wants OMP |
| `zshrc.example` | *(none — reference only)* | Template for `~/.zshrc`; **never** linked to `~/.zshrc` (ADR-0021). | No — stays a tracked `.example`, symlinks only to `~/.config/zsh/zshrc.example` |

**Copy commands** (one-way `.example` → real; the `.example` stays as reference). After copying, re-stow with `--no-folding` so each new real file gets its own link:

```
⚠️  MANUAL STEP — review each copy; minimum is index.zsh
cp stow/common/zsh/.config/zsh/index.zsh.example  stow/common/zsh/.config/zsh/index.zsh
cp stow/common/zsh/.config/zsh/shared.zsh.example stow/common/zsh/.config/zsh/shared.zsh
# macOS only:
cp stow/common/zsh/.config/zsh/macos.zsh.example  stow/common/zsh/.config/zsh/macos.zsh
# Arch only:
cp stow/common/zsh/.config/zsh/arch.zsh.example   stow/common/zsh/.config/zsh/arch.zsh
# Optional OMP:
cp stow/common/zsh/.config/zsh/omp.zsh.example    stow/common/zsh/.config/zsh/omp.zsh
```
```
⚠️  MANUAL STEP — review dry-run output before running
stow --dir=stow/common --target="$HOME" --no-folding --restow zsh
```

### Open question resolved: `.gitignore` vs. `--no-folding` needing files present

PRD 0008 raised that `--no-folding` symlinks from files that must exist in the package, but worried the package `.gitignore` excludes them. **Inspection of `stow/common/zsh/.config/zsh/.gitignore` shows this is already correct and needs no change:**

```gitignore
# Ignore real (filled-in) zsh files; keep .example templates tracked.
shared.zsh
macos.zsh
arch.zsh
omp.zsh
index.zsh
# local.zsh has no .example — machine-specific/sensitive overrides, never committed (ADR-0023).
local.zsh
```

**This is the intended design, not a problem to fix.** Stow does **not** require a file to be *git-tracked* to symlink it — it links any file physically present in the package directory, tracked or not. The real managed files (`index.zsh`, `shared.zsh`, …) are created locally by the user copying from `.example`, exist on disk in the package dir, and are linked by `--no-folding` from there. They stay **git-ignored** so the user's filled-in values (machine-specific paths, or personal tool paths in `macos.zsh`/`arch.zsh`) are never committed (ADR-0003, ADR-0016, ADR-0023). The tracked, committed sources of truth are the `*.example` templates with placeholder-only values.

**Recommendation: keep the current `.gitignore` exactly as-is.** Do **not** un-ignore `index.zsh`/`shared.zsh`/etc.:

- "Versioned" in PRD 0008 means *the template is versioned* (the `.example`), not the filled-in real file. Committing a filled-in `shared.zsh` would risk personal values entering version control, violating AGENTS §9 and ADR-0003.
- `--no-folding` linking works regardless of git-tracking status, so there is no functional need to track the real files.
- `local.zsh` correctly remains ignored and additionally lives outside the repo (Section 5).

If a future requirement genuinely demands committing a fully-portable managed file (no personal values), that would be a separate ADR un-ignoring **only that one specific filename** while keeping `local.zsh` and the personal-valued layers ignored — but this is **not** recommended now and not needed for `--no-folding`.

---

## 5. Which Files Remain LOCAL / PRIVATE

| File | Where it lives | Tracked? | Symlinked? | Sourced |
|---|---|---|---|---|
| `local.zsh` | **Real file directly under `~/.config/zsh/`** (outside the repo) | No (git-ignored *and* physically outside the repo) | **Never** | **Last**, by `index.zsh`, only if present |

`local.zsh` is the sole home for machine-specific or sensitive values (tokens, private hosts, work paths). Under `--no-folding`, `~/.config/zsh/` is a **real directory Stow owns**, so the user creates `local.zsh` there directly with an editor — it is **not** copied from the repo and has **no** `.example` (ADR-0023). Because it physically lives outside the repo working tree, it can never be `git add`-ed by accident; the `.gitignore` entry is a belt-and-suspenders second line of defence.

`index.zsh` already sources it last (verified in `index.zsh.example` line 23):

```zsh
# 4) Local overrides — machine-specific/sensitive, git-ignored, sourced LAST so it wins.
[[ -r "$HOME/.config/zsh/local.zsh" ]] && source "$HOME/.config/zsh/local.zsh"
```

Creating it (user, manual; shown):

```
⚠️  MANUAL STEP — create a REAL private file (not from the repo); put secrets only here
$EDITOR "$HOME/.config/zsh/local.zsh"
```

---

## 6. How `~/.zshrc` Remains UNMANAGED

- `~/.zshrc` is a **user-owned regular file** at the `$HOME` root. The zsh package only covers `.config/zsh/`, so `~/.zshrc` is **outside the package's reach** — Stow can never link or touch it (ADR-0016, ADR-0021).
- It is **never stowed**, **never symlinked**, and **never auto-edited** by any tool, script, or agent in this repository.
- Review 0024 confirmed it is already present as a real 7-line file containing the guarded block; this architecture **does not change it**.
- The only edits to `~/.zshrc` are **manual, by the user** — adding/removing the single delimited include block (ADR-0021). `--no-folding` migration changes nothing about this: it only alters the shape of `~/.config/zsh/`, which `~/.zshrc` references through a guard.

---

## 7. How the Guarded Include Block Works

The single block the user added by hand to `~/.zshrc` (confirmed present, Review 0024):

```zsh
# >>> dotfiles managed (zsh) — added manually; delete this block to disable >>>
[[ -r "$HOME/.config/zsh/index.zsh" ]] && source "$HOME/.config/zsh/index.zsh"
# <<< dotfiles managed (zsh) <<<
```

Semantics:

- `[[ -r "$HOME/.config/zsh/index.zsh" ]]` tests that `index.zsh` exists **and is readable**. `&&` short-circuits: if the test fails, `source` never runs.
- **Fail-safe no-op:** while `index.zsh` is absent (current state — only `.example` exists), the guard is false → the line does nothing → the shell still starts cleanly. This is exactly the inert-but-safe state Review 0024 verified.
- **Why it lives in `~/.zshrc`:** `~/.zshrc` is the interactive-shell entry point zsh reads (`$ZDOTDIR` unset, so `~/.zshrc` is the rc file). Placing the trigger there — and **only** there — keeps the managed layer's activation under the user's direct control, gives migration exactly one revert point (delete the three delimited lines), and keeps `~/.zshrc` unmanaged (Section 6).
- Recommended placement: **last** in `~/.zshrc`, so managed defaults and `local.zsh` apply after the user's own lines (ADR-0023 "wins end-to-end" scope).

After `index.zsh` becomes a real per-file symlink (Section 4) and resolves, the same guard passes and the managed layer loads — no `~/.zshrc` edit required to activate.

---

## 8. How `index.zsh` Owns Source Order

`index.zsh` (template at `index.zsh.example`, verified) is the **only** file the `~/.zshrc` block references. It owns **source order only**; each layer file owns its own guarded logic, and **every source is independently guarded** so partial adoption still starts a clean shell:

```zsh
# 1) Portable layer
[[ -r "$HOME/.config/zsh/shared.zsh" ]] && source "$HOME/.config/zsh/shared.zsh"

# 2) Platform layer: OS-detected, sourced only if present
if [[ "$OSTYPE" == "darwin"* ]]; then
  [[ -r "$HOME/.config/zsh/macos.zsh" ]] && source "$HOME/.config/zsh/macos.zsh"
elif [[ -f /etc/arch-release ]]; then
  [[ -r "$HOME/.config/zsh/arch.zsh" ]] && source "$HOME/.config/zsh/arch.zsh"
fi

# 3) Prompt: Oh My Posh — opt-in, guarded inside omp.zsh. Never auto-activated here.
[[ -r "$HOME/.config/zsh/omp.zsh" ]] && source "$HOME/.config/zsh/omp.zsh"

# 4) Local overrides — sourced LAST so it wins.
[[ -r "$HOME/.config/zsh/local.zsh" ]] && source "$HOME/.config/zsh/local.zsh"
```

Order: `shared.zsh` → (`macos.zsh` | `arch.zsh`, OS-detected, only the matching one) → `omp.zsh` → `local.zsh` (last, wins). Each `[[ -r … ]]` guard means a machine that copied only `index.zsh` (and not, say, `macos.zsh`) still starts a clean shell — absent layers are no-ops (ADR-0016, ADR-0021). Cross-platform: the unused platform file (`arch.zsh` on macOS) is symlinked but never sourced — harmless (ADR-0016).

---

## 9. How Oh My Posh Stays Optional / Guarded

- OMP activation is its own file, `omp.zsh` (from `omp.zsh.example`), and is **opt-in**: `index.zsh` sources it only `[[ -r … ]]`. A user who never creates the real `omp.zsh` has no prompt layer and an unaffected shell.
- Inside `omp.zsh.example` (verified) the activation is **double-guarded** and ships **commented out** — the file is inert until the user deliberately copies it and uncomments:

  ```zsh
  # [[ -x "$(command -v oh-my-posh)" ]] && \
  #   [[ -f "${HOME}/.config/omp/omp.toml" ]] && \
  #   eval "$(oh-my-posh init zsh --config "${HOME}/.config/omp/omp.toml")"
  ```

  Guards on **both** the binary (`command -v oh-my-posh`) **and** the config (`omp.toml` present) mean OMP never activates automatically and never errors when absent.
- Installation of Oh My Posh (Homebrew tap on macOS / AUR on Arch) is manual and out-of-band (`docs/stow-usage.md`), never at shell startup, never part of the include block (Architecture 0007, "shell startup must not install").

---

## 10. How fzf / zoxide / eza Stay Guarded

In `shared.zsh.example` (verified), each integration is a **command-exists guard** that activates an already-installed tool and is a no-op when absent — **no install, no clone, no network at startup**:

```zsh
command -v fzf    >/dev/null 2>&1 && eval "$(fzf --zsh)"
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"
command -v eza    >/dev/null 2>&1 && alias ls='eza'
```

Installation stays manual and out-of-band (Homebrew on macOS / pacman on Arch), surfaced by the read-only `scripts/check-zsh-deps.sh` / `task deps:check:zsh` checker (Architecture 0006), never triggered by activation. A machine missing all three still starts a clean shell — the capabilities simply do not light up.

---

## 11. How Zinit Is Handled WITHOUT Auto-Clone

Per ADR-0020, the upstream auto-clone-on-startup snippet is **forbidden**. `shared.zsh.example` (verified) only **sources** an already-installed Zinit behind a directory-existence guard:

```zsh
ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
[[ -f "${ZINIT_HOME}/zinit.zsh" ]] && source "${ZINIT_HOME}/zinit.zsh"
```

If Zinit is not installed, the guard is false → no-op → clean shell. Completion handling avoids a double `compinit` (the template runs a standalone `compinit` only when Zinit is not loaded).

**User-manual install path** (one-time, out-of-band, cross-platform; shown, not executed):

```
⚠️  MANUAL STEP — one-time manual install; never run at shell startup (ADR-0020)
git clone https://github.com/zdharma-continuum/zinit.git \
  "${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
```

The checker detects the `${ZINIT_HOME}` directory and prints this hint; it never runs the clone.

---

## 12. Validation Commands

All read-only. No `$HOME` content dumped — presence / resolution / load-marker / count-only checks (mirrors Review 0024). Run from the repo root.

**Pre-migration form check (confirm the folded start state):**

```bash
ls -ld "$HOME/.config/zsh"                                 # expect: a SYMLINK (the fold) -> …/stow/common/zsh/.config/zsh
echo "ZDOTDIR='${ZDOTDIR:-<unset>}'"                       # expect: <unset>
grep -c '>>> dotfiles managed (zsh)' "$HOME/.zshrc"        # expect: 1 (count only — no content dumped)
[[ -L "$HOME/.config/zsh" ]] && echo "folded(dir-symlink)" || echo "not-a-fold"
```

**Post-migration form check (real dir + per-file symlinks + real local.zsh):**

```bash
ls -ld "$HOME/.config/zsh"                                 # expect: a real DIRECTORY (not a symlink)
[[ -d "$HOME/.config/zsh" && ! -L "$HOME/.config/zsh" ]] && echo "real-dir-ok" || echo "NOT-real-dir"
for f in index.zsh shared.zsh macos.zsh arch.zsh omp.zsh; do
  p="$HOME/.config/zsh/$f"
  if [[ -L $p ]]; then echo "$f -> $(readlink "$p")"          # expect: resolves into …/stow/common/zsh/.config/zsh/$f
  elif [[ -e $p ]]; then echo "$f (real file — unexpected for managed)"
  else echo "$f (absent)"; fi
done
# local.zsh MUST be a real file, never a symlink:
p="$HOME/.config/zsh/local.zsh"
if   [[ -L $p ]]; then echo "local.zsh (SYMLINK — WRONG)"
elif [[ -e $p ]]; then echo "local.zsh (real file — ok)"
else echo "local.zsh (absent — ok, optional)"; fi
```

**Real-managed-file presence (name/resolution only):**

```bash
[[ -r "$HOME/.config/zsh/index.zsh" ]] && echo "index.zsh present (activation enabled)" \
                                       || echo "index.zsh absent (layer inert — safe)"
```

**Activation load-marker check (prove the layer loads — no content dump):**

```bash
zsh -ic 'echo zsh-ok'              # after index.zsh resolves, expect a clean interactive load + "zsh-ok"
# Optional sentinel: a known managed alias resolves, e.g. (only if you defined one in shared.zsh):
zsh -ic 'alias ls' 2>/dev/null | grep -q eza && echo "shared-layer-loaded" || echo "shared-layer-not-loaded"
```

**Guard fail-safe check (no real files → clean shell):**

```bash
zsh --no-rcs -c 'echo zsh-norc-ok' # zsh starts with no rc files at all
zsh -ic 'echo guard-ok'            # with index.zsh absent, the ~/.zshrc guard is a no-op; shell still starts
```

**git-not-tracking-`local.zsh` check:**

```bash
git -C "$(git rev-parse --show-toplevel)" check-ignore stow/common/zsh/.config/zsh/local.zsh \
  && echo "local.zsh ignored-ok"   # confirms the pattern matches
git ls-files --error-unmatch stow/common/zsh/.config/zsh/local.zsh 2>/dev/null \
  && echo "TRACKED — WRONG" || echo "local.zsh not tracked — ok"
# local.zsh lives OUTSIDE the repo (under ~/.config/zsh/) so it can never be git-added anyway.
```

**Safety re-check:**

```bash
git status --short                 # expect: clean; no unintended changes, no real managed file staged
# confirm no real managed file (filled-in) is tracked:
git ls-files stow/common/zsh/.config/zsh/ | grep -vE '\.example$|\.gitignore$' \
  && echo "TRACKED real file(s) — investigate" || echo "only .example tracked — ok"
```

(No `--adopt`, no symlink overwrite, no dependency install occurs in any of the above — all read-only.)

**Fake-home layout validation (ADR-0017 — confirm `--no-folding` package layout without touching `$HOME`):**

```bash
TEST_HOME="$(mktemp -d)"
stow --dir=stow/common --target="$TEST_HOME" --no-folding --simulate zsh
rm -rf "$TEST_HOME"
```

---

## 13. Rollback Strategy

Ordered, reversible, no data loss. Returns to the inert-but-safe state Review 0024 verified. No step runs automatically; all risky lines marked `⚠️  MANUAL STEP`.

1. **Disable the layer (one step):** comment or delete the three delimited lines of the managed include block in `~/.zshrc`. New shells start clean; the layer is inert. This is the primary, instant revert.

2. **Unstow the per-file links:**

   ```
   ⚠️  MANUAL STEP — review dry-run output before running
   stow --dir=stow/common --target="$HOME" --simulate --delete zsh
   stow --dir=stow/common --target="$HOME" --delete zsh
   ```

   Removes the per-file symlinks (and, with `--no-folding`, leaves the real directory). `~/.zshrc` untouched.

3. **Remove copied managed files by name only — NEVER `rm -rf ~/.config/zsh`:**

   ```
   ⚠️  MANUAL STEP — review before running; removes ONLY these named files
   rm -f "$HOME/.config/zsh/index.zsh" "$HOME/.config/zsh/shared.zsh" \
         "$HOME/.config/zsh/macos.zsh" "$HOME/.config/zsh/arch.zsh" \
         "$HOME/.config/zsh/omp.zsh"   "$HOME/.config/zsh/local.zsh"
   ```

   The `.example` templates remain; `local.zsh` (your private file) is removed only if you choose to. Named-file removal avoids any chance of deleting the directory or repo contents.

4. **Re-fold fallback (optional):** to restore the prior folded behaviour, unstow then re-stow **without** `--no-folding` (dry-run first):

   ```
   ⚠️  MANUAL STEP — review dry-run output before running
   stow --dir=stow/common --target="$HOME" --simulate zsh
   stow --dir=stow/common --target="$HOME" zsh
   ```

5. **Verify:**

   ```bash
   zsh --no-rcs -c 'echo ok'
   ls -l "$HOME/.config/zsh"
   ```

---

## 14. ADRs To Create

Last existing ADR is **0023**, so new records start at **0024**. Status field per `docs/decisions/README.md` (`Proposed` → `Accepted`).

| Number | Title | One-line rationale |
|---|---|---|
| **ADR-0024** | `--no-folding` is the intended Stow strategy for the zsh package; folding is rejected | Records Sections 1–2: per-file symlinks give an explicit managed surface and a real `~/.config/zsh/` directory that can hold a private `local.zsh` without polluting the repo tree (Review 0024 Issue 3). |
| **ADR-0025** | Managed zsh real files are linked from the package via `--no-folding` while staying git-ignored; only `.example` templates are versioned | Records Section 4: Stow links files by presence, not git-tracking, so filled-in real files stay ignored (ADR-0003 privacy) and the committed source of truth remains the placeholder `.example` templates. |
| **ADR-0026** | `local.zsh` is a real, unversioned file created outside the repo under `~/.config/zsh/`, never symlinked | Records Section 5: refines ADR-0023 — under `--no-folding` the real directory lets `local.zsh` live physically outside the repo, a stronger privacy boundary than `.gitignore` alone. |
| **ADR-0027** | `~/.zshrc` stays an unmanaged, user-owned regular file; the `--no-folding` migration does not touch it | Records Section 6: reaffirms ADR-0021 against the new migration — the package covers only `.config/zsh/`, so `~/.zshrc` is never stowed/symlinked/auto-edited; the guarded include block is the sole, user-edited trigger. |

Existing ADRs already governing this work (no new record needed): ADR-0001, ADR-0003, ADR-0016, ADR-0017, ADR-0020, ADR-0021, ADR-0023.

---

## Decisions

- **Decision 1 — `--no-folding` is the intended zsh stow shape; folding is rejected.** (Sections 1–2; ADR-0024.) Per-file symlinks under a real `~/.config/zsh/` directory are the target.
- **Decision 2 — Keep the package `.gitignore` as-is; do not un-ignore real managed files.** (Section 4; ADR-0025.) `--no-folding` links by file presence, not git-tracking; committing filled-in files would risk personal values (ADR-0003). The `.example` templates remain the only versioned sources.
- **Decision 3 — `local.zsh` is a real file outside the repo, created directly under `~/.config/zsh/`, never symlinked, sourced last.** (Section 5; ADR-0026, refining ADR-0023.)
- **Decision 4 — `~/.zshrc` remains unmanaged; migration alters only `~/.config/zsh/` shape.** (Sections 6–7; ADR-0027, reaffirming ADR-0021.)
- **Decision 5 — Migration is dry-run-gated, conflict-stops, never `--adopt`.** (Section 3; ADR-0017.)

---

## Risks and Tradeoffs

| Risk | Likelihood | Severity | Mitigation (ties to repo safety rules) |
|---|---|---|---|
| User runs `--delete` then forgets the `--no-folding` restow → managed layer disappears | Medium | Low | Guarded include block makes the absent state a clean no-op (AGENTS §8); Section 3 orders the steps; Section 12 post-migration check catches it. |
| A dry-run conflict is bypassed with `--adopt`, overwriting files | Low | High | AGENTS §8 + ADR-0017 forbid `--adopt`; every command shows `--simulate` first; "STOP on conflict" stated in Section 3. |
| `local.zsh` accidentally committed | Low | High | Lives **outside** the repo working tree (Section 5) **and** is git-ignored; Section 12 verifies both (AGENTS §9). |
| Filled-in `macos.zsh`/`shared.zsh` committed with personal values | Low | High | `.gitignore` keeps real files ignored; only `.example` placeholders are tracked (ADR-0003, ADR-0025); Section 12 safety re-check greps for tracked non-`.example` files. |
| `rm -rf ~/.config/zsh` used during rollback, destroying private `local.zsh` or repo links | Low | High | Rollback Step 3 mandates named-file removal only; `rm -rf` explicitly forbidden (AGENTS §8). |
| Each new managed file silently not linked (no re-stow) | Medium | Low | Guards make unlinked layers no-ops; Section 4 documents the `--restow` requirement; trade-off accepted (PRD 0008). |
| Re-stow auto-run by a script/hook | Low | High | No Stow in scripts/CI (AGENTS §11, `docs/stow-usage.md` "Forbidden"); all stow steps are manual `⚠️  MANUAL STEP`. |
| Auto-install/auto-clone re-introduced into a layer | Low | High | ADR-0020 + Architecture 0006/0007 forbid it; Sections 9–11 show guards-only patterns; Reviewer checklist. |
| Cross-platform mix (Homebrew on Arch, etc.) | Low | Medium | `macos.zsh`/`arch.zsh` are OS-gated by `index.zsh`; copy commands in Section 4 are platform-labelled (AGENTS §10). |
| Real-home `--simulate` conflict on `~/.config/zsh/` misread as a layout bug | Medium | Low | Fake-home validation (Section 12, ADR-0017) confirms package layout independently. |

**Tradeoff summary:** `--no-folding` trades a small recurring cost (re-stow per new managed file) for explicit per-file visibility, a real-directory boundary that keeps private content out of the repo, and alignment with the documented model — a net gain for a safety-first repo.

---

## Recommended Next Step

Planner converts this architecture into an ordered implementation plan under `docs/plans/0008-zsh-managed-layer-activation-plan.md` covering: the documented (not executed) migration runbook (Section 3), the example-to-real copy steps (Section 4), `local.zsh` creation guidance (Section 5), the four ADRs (Section 14), updates to `docs/stow-usage.md` / `docs/zsh-migration.md` reflecting `--no-folding` and the per-file layout, per-task read-only validation (Section 12), and the rollback note (Section 13). Every risky line marked `⚠️  MANUAL STEP`, dry-run before any real stow.

---

## Closing Note

**Nothing in this document was executed.** No `$HOME` file was created, modified, moved, or deleted; `~/.zshrc` was not touched; no Stow command was run (no `--delete`, `--restow`, `--no-folding`, or install); no symlink was created or overwritten; `--adopt` was never used; no dependency was installed and Zinit was not cloned. All exploration was read-only (file reads, `ls`, `grep -c`/count-only, `git` status/log). Every command above is shown for the user to run manually, with dangerous ones marked `⚠️  MANUAL STEP` and gated behind a `--simulate` dry-run, per AGENTS §8 and §11. This document is **Draft** until reviewed and approved.
