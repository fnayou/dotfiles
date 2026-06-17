# Review: Zsh Manual Migration — Validation Report

**Number:** 0024
**Status:** Complete
**Date:** 2026-06-18
**Type:** Manual migration validation (user performed the stow + `~/.zshrc` edit; this report verifies actual state)
**Related:** PRD 0007, Architecture 0007, Plan 0012, Reviews 0021–0023

---

## Summary

The user reported: manually stowed the common zsh package, manually added the guarded
include block at the end of their real `~/.zshrc`, no `--adopt`, no auto-modification, no
startup install. This report validates that against the **actual filesystem state** via
read-only checks.

**Verdict: INCOMPLETE — safety is intact and `~/.zshrc` is now confirmed, but the managed
layer is NOT active.** One reported fact does not match the observed state:

1. The real managed files (`index.zsh`, `shared.zsh`, …) were **never created** (only
   `.example` templates exist), so the include block's guard is a **no-op** — nothing
   managed loads. The package is stowed but the layer is inert.

> **Re-validation 2026-06-18 (supersedes the original Issue 2):** `~/.zshrc` now **exists**
> as a **regular file** (7 lines, not a symlink) and **contains the guarded include block**
> (2 delimiter/source matches). `$ZDOTDIR` remains unset. The original report was written
> before the user created `~/.zshrc`; that finding is now stale and resolved. The only
> remaining gap is Issue 1 (real managed files not yet created).

Safety properties all hold (no `--adopt`, no broad destructive command, shell starts
clean, no dependency install). No action was taken to change any `$HOME` file or `~/.zshrc`.

---

## What Was Tested

1. Whether the zsh package is actually stowed, and in what form (per-file vs directory fold).
2. Which managed targets exist under `~/.config/zsh/` and which resolve into the repo.
3. Whether the real (non-`.example`) managed files exist.
4. Whether `~/.zshrc` exists and contains the guarded include block (delimiter match only — no content dumped).
5. Whether `$ZDOTDIR` or `~/.zprofile` redirect zsh startup elsewhere.
6. Basic zsh startup sanity and absence of `--adopt` / broad destructive commands.

Privacy: no file content from `$HOME` was copied into the repo. The `~/.zshrc` check used
a delimiter **count** only; `~/.zprofile` used a targeted `grep` for keywords, not a dump.

---

## Commands Run (read-only)

```bash
# Stow form + target resolution
ls -ld "$HOME/.config/zsh"                 # is it a directory-fold symlink?
ls -l  "$HOME/.config/zsh/"
for f in index.zsh shared.zsh macos.zsh arch.zsh omp.zsh local.zsh; do
  p="$HOME/.config/zsh/$f"; [[ -L $p ]] && echo "$f -> $(readlink $p)" || { [[ -e $p ]] && echo "$f (file)" || echo "$f (absent)"; }
done

# Real managed files in the repo package dir
ls -la stow/common/zsh/.config/zsh/ | grep -vE '\.example|\.gitignore'

# ~/.zshrc presence + include block (count only) + redirects
ls -la "$HOME/.zshrc"; echo "ZDOTDIR='${ZDOTDIR:-<unset>}'"
grep -c '>>> dotfiles managed (zsh)' "$HOME/.zshrc" 2>/dev/null
grep -nE "ZDOTDIR|zshrc|dotfiles managed|source" "$HOME/.zprofile"

# Sanity / safety
zsh --no-rcs -c 'echo zsh-norc-ok'
git status --short
```

---

## Results

| Check | Result |
|---|---|
| `~/.config/zsh` is stowed | **Yes**, but as a **directory fold**: `~/.config/zsh` → `../works/dotfiles/stow/common/zsh/.config/zsh` (one directory symlink, not per-file symlinks). |
| Per-file managed symlinks (`~/.config/zsh/shared.zsh` → repo) | **None** — folding replaced the whole dir; individual real files do not exist. |
| Real `index.zsh` present | **No** — absent. Only `index.zsh.example` exists. |
| Real `shared.zsh` / `macos.zsh` / `arch.zsh` / `omp.zsh` / `local.zsh` | **All absent** — only `.example` templates in the repo package dir. |
| Managed layer active | **No** — include block guard `[[ -r ~/.config/zsh/index.zsh ]]` evaluates false → no-op. |
| `~/.zshrc` exists | **Yes (re-validated)** — regular file, 7 lines, **not a symlink**. |
| `$ZDOTDIR` redirect | **Unset.** Interactive config loads from `~/.zshrc`. |
| Include block in `~/.zshrc` | **Present (re-validated)** — guarded block found (2 delimiter/source matches), count-only check. |
| `~/.zprofile` references zshrc/ZDOTDIR/managed/source | **None** (44-byte file, no matching lines). |
| `--adopt` used | **No evidence** — folding only happens when the target dir did not pre-exist; no overwrite occurred. |
| Dependency install at startup | **None observed** — templates contain only guarded activation. |
| `zsh --no-rcs` starts | **OK** (`zsh-norc-ok`). |
| Repo working tree | **Clean** (`git status` empty) — prior implementation was committed. |

---

## Issues Found

### Issue 1 — Managed layer is inert: real files never created (functional, not safety)

Stowing alone does not activate anything. The adoption steps require copying each
`*.example` to its real (git-ignored) filename **before** stowing
(`docs/stow-usage.md` Step 1 / `docs/zsh-migration.md` Step 2). Those copies were not made,
so `~/.config/zsh/index.zsh` does not exist and the include block — wherever it is — is a
guarded no-op. The guard behaving as a no-op is correct, safe design; but the migration is
not actually in effect.

**Fix (user, manual):** copy the templates to real filenames, then re-verify:
```bash
cp stow/common/zsh/.config/zsh/index.zsh.example  stow/common/zsh/.config/zsh/index.zsh
cp stow/common/zsh/.config/zsh/shared.zsh.example stow/common/zsh/.config/zsh/shared.zsh
# (macos.zsh / arch.zsh / omp.zsh / local.zsh as desired)
```
Because the dir is folded, these land in the repo and appear under `~/.config/zsh/`
automatically (they are git-ignored).

### Issue 2 — RESOLVED (re-validated 2026-06-18): `~/.zshrc` present with guarded block

Originally this issue reported `~/.zshrc` absent. **Re-validation supersedes that finding.**
`~/.zshrc` now exists as a **regular file** (7 lines, not a symlink), `$ZDOTDIR` is unset
(so interactive zsh loads `~/.zshrc`), and the file **contains the guarded include block**
(2 matches on `dotfiles managed (zsh)` / `.config/zsh/index.zsh`, count-only check — no
content dumped). The user created `~/.zshrc` after the original report was written; the
report of "added the guarded include block to my real `~/.zshrc`" is now confirmed.

No further action on this issue. The guard remains a fail-safe no-op until Issue 1 is done.

### Issue 3 — Stow used directory folding, not the per-file symlinks the docs depict

`docs/stow-usage.md` shows the expected result as **per-file** symlinks
(`~/.config/zsh/shared.zsh → …`). The actual result is a **directory-level** symlink
(`~/.config/zsh → …/stow/common/zsh/.config/zsh`), Stow's default folding when the target
directory does not pre-exist. Consequence: `~/.config/zsh` is now the repo directory; any
**non-managed** file you drop into `~/.config/zsh` is actually written inside the repo
tree. Functionally the managed files still resolve, but this differs from the documented
model and is worth deciding deliberately.

**Options (user choice, not changed here):**
- Accept folding (simplest; works), or
- Re-stow with per-file links to match the docs:
  ```
  ⚠️  MANUAL STEP — review before running
  stow --dir=stow/common --target="$HOME" --restow --no-folding zsh
  ```
- A future docs/ADR note could state whether folding or `--no-folding` is the intended
  outcome for this package (non-blocking; recommend deciding during the next docs pass).

---

## Rollback Path (unchanged, confirmed safe)

1. **Disable managed layer:** remove or comment the delimited include block in your
   interactive zsh file (once it exists). One-step, no data loss.
2. **Unstow the package:**
   ```
   ⚠️  MANUAL STEP — review before running
   stow --dir=stow/common --target="$HOME" --delete zsh
   ```
   This removes the `~/.config/zsh` symlink (or per-file links). Your interactive zsh file
   is untouched.
3. **Remove copied real files (if any were created), by name — never `rm -rf ~/.config/zsh`:**
   ```
   ⚠️  MANUAL STEP — review before running; remove only these named files
   rm -f ~/.config/zsh/index.zsh ~/.config/zsh/shared.zsh ~/.config/zsh/macos.zsh \
         ~/.config/zsh/arch.zsh ~/.config/zsh/omp.zsh ~/.config/zsh/local.zsh
   ```
4. **Verify:** `zsh --no-rcs -c 'echo ok'` and `ls -l ~/.config/zsh`.

---

## Verdicts

- **Safety: PASS** — No `--adopt`, no overwrite, no broad destructive command, no
  dependency install, no auto-edit of any shell file. `~/.zshrc` not modified by anything
  here. Guards behave as no-ops (fail-safe).
- **Privacy: PASS** — No `$HOME` content copied into the repo; checks used counts/keyword
  greps only.
- **Migration completeness: INCOMPLETE** — Package stowed and `~/.zshrc` confirmed present
  with the guarded include block (Issue 2 resolved on re-validation). Remaining blocker:
  real managed files not created → layer inert (Issue 1). The migration is not yet in effect.

---

## Recommended Next Action

One manual step remains (Issue 2 already resolved):
1. Copy the `*.example` files to their real filenames (Issue 1) — at minimum `index.zsh`.
2. Decide folding vs `--no-folding` for the stow (Issue 3) — non-blocking.

Then re-run the read-only checks above; expect `~/.config/zsh/index.zsh` to resolve and
`zsh -ic 'echo zsh-ok'` to load the managed layer. No repository change is required to fix
this — it is a local adoption gap, not a defect in the shipped templates (Plan 0012
remains correctly Complete).
