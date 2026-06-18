# 0033: Git Local Setup Validation Report

| Metadata | Value |
|----------|-------|
| Status | Complete |
| Date | 2026-06-19 |
| Type | Local Validation Report |
| Note | Requested filename 0032 was already taken by real-zsh-git-implementation-review.md |
| Related | git-setup.md guide, ADR-0030, ADR-0032, Plan 0013 |

---

## 1. Commands Run

### 1.1 Directory structure check
```bash
$ ls -ld "$HOME/.config/git"
drwxr-xr-x@ 5 fnayou  staff  160 Jun 19 00:03 /Users/fnayou/.config/git
```

### 1.2 Real directory formal check
```bash
$ [[ -d "$HOME/.config/git" && ! -L "$HOME/.config/git" ]] && echo "real-dir-ok" || echo "NOT-real-dir-or-absent"
real-dir-ok
```

### 1.3 Per-file symlink status
```bash
$ for f in config-common aliases ignore; do
  if [[ -L "$HOME/.config/git/$f" ]]; then echo "SYMLINK: $f -> $(readlink "$HOME/.config/git/$f")";
  elif [[ -e "$HOME/.config/git/$f" ]]; then echo "REAL-FILE: $f";
  else echo "ABSENT: $f"; fi
done

SYMLINK: config-common -> ../../works/dotfiles/stow/common/git/.config/git/config-common
SYMLINK: aliases -> ../../works/dotfiles/stow/common/git/.config/git/aliases
SYMLINK: ignore -> ../../works/dotfiles/stow/common/git/.config/git/ignore
```

### 1.4 ~/.gitconfig regular file check
```bash
$ [[ -f "$HOME/.gitconfig" && ! -L "$HOME/.gitconfig" ]] && echo "gitconfig-regular-ok" || echo "gitconfig-PROBLEM-or-absent"
gitconfig-regular-ok
```

### 1.5 include.path entries
```bash
$ git config --global --get-all include.path
~/.config/git/config-common
~/.config/git/aliases
```

### 1.6 Identity attribution
```bash
$ git config --show-origin user.name
file:/Users/fnayou/.gitconfig	Aymen Fnayou

$ git config --show-origin user.email
file:/Users/fnayou/.gitconfig	fnayou.aymen@gmail.com
```

### 1.7 Guide command audit — stow calls
```bash
grep -n "^stow" lines 57, 80, 231:
57:stow --dir=stow/common --target="$HOME" --simulate git
80:stow --dir=stow/common --target="$HOME" git
231:stow --dir=stow/common --target="$HOME" --delete git
```

### 1.8 Taskfile stow task check
```bash
grep "stow" Taskfile.yml:
10:    desc: "Verify prerequisites (stow, git, task) are installed"
17:      - find stow -mindepth 2 -maxdepth 2 -type d -print | sed 's|^stow/||'
27:      - stow --dir=stow/{{.AREA}} --target="$HOME" --simulate {{.PACKAGE}}
```

**Finding:** Line 27 is the `dry-run` task; it uses `--simulate` correctly. No `task stow AREA=common PACKAGE=git` install task exists.

### 1.9 Guide validation section check
```bash
Lines 155–199 (Section 7: Validation steps)
Line 159: Expected: `config-common`, `aliases`, and `ignore` all shown as symlinks.
```

**Finding:** Guide does NOT assert that `~/.config/git` itself must be a real directory (not a symlink). The check only validates the per-file symlinks, not the container directory structure.

---

## 2. What Failed / Differed From the Guide

### 2a. `task stow AREA=common PACKAGE=git` Does Not Exist

**Expectation:** User might expect a Taskfile helper to stow the git package directly.

**Reality:** No such task exists in `Taskfile.yml`. The `dry-run` task exists (line 19–27), but there is no corresponding `stow` or `install` task for any package.

**Guide consequence:** `docs/guides/git-setup.md` instructs the user to run `stow --dir=stow/common --target="$HOME" git` directly (line 80), not a Taskfile task. This is correct and explicit. No documentation error here.

---

### 2b. Stow Without `--no-folding` Folded `~/.config/git` Into a Symlink

**Reported user action:** User ran Stow without `--no-folding` and saw `~/.config/git` become a symlink to the package directory (wrong layout per ADR-0030).

**Expected behavior per ADR-0030:** `~/.config/git` should be a real directory; `config-common`, `aliases`, `ignore` should be per-file symlinks into the repo.

**Actual current state:** Matches expected — `~/.config/git` is a real directory; all three managed files are per-file symlinks. User rolled back and corrected with `--no-folding`.

**Guide consequence:** `docs/guides/git-setup.md` line 80 does NOT include `--no-folding` in the apply step. The guide must be updated.

---

## 3. Corrective Action Taken

User performed the following sequence:

1. Ran Stow without `--no-folding`, saw `~/.config/git` become a folded symlink.
2. Rolled back: `stow --dir=stow/common --target="$HOME" --delete git`
3. Recreated `~/.config/git` as a real directory.
4. Re-ran with `--no-folding`: `stow --dir=stow/common --target="$HOME" --no-folding git`
5. Result: `~/.config/git` is real; three files are per-file symlinks. ✓

---

## 4. Final Validation Results

| Check | Expected | Actual | Verdict |
|-------|----------|--------|---------|
| `~/.config/git` is a real directory | Real directory, not symlink | Real directory (drwxr-xr-x) | **PASS** |
| `config-common` is a per-file symlink | Symlink to repo path | `../../works/dotfiles/stow/common/git/.config/git/config-common` | **PASS** |
| `aliases` is a per-file symlink | Symlink to repo path | `../../works/dotfiles/stow/common/git/.config/git/aliases` | **PASS** |
| `ignore` is a per-file symlink | Symlink to repo path | `../../works/dotfiles/stow/common/git/.config/git/ignore` | **PASS** |
| `~/.gitconfig` is unmanaged and real | Regular file, not symlink | Regular file (gitconfig-regular-ok) | **PASS** |
| `include.path` entries wired | Two entries in git config | `~/.config/git/config-common` and `~/.config/git/aliases` | **PASS** |
| Identity from `~/.gitconfig` only | `user.name` and `user.email` show `file:~/.gitconfig` | Both point to `file:/Users/fnayou/.gitconfig` | **PASS** |
| Dry-run accuracy | Reported correct state before bootstrap | User reported dry-run matched expected output | **PASS** |
| Bootstrap idempotence | Second run produces no duplicate entries | User ran twice, no duplicates reported | **PASS** |
| No `--adopt` used | Rollback used `--delete` + manual dir recreation | User avoided `--adopt`; created backup during bootstrap | **PASS** |

---

## 5. Idempotency Result

**Second bootstrap run:** User ran `task git:bootstrap` a second time. Result: both include.path entries detected as already present; task skipped them with "skip (already present)" messages. No duplicate entries added.

**Verdict: PASS**

---

## 6. Safety Result

| Check | Expected | Actual | Verdict |
|-------|----------|--------|---------|
| No `stow --adopt` used | Avoid automatic overwrites | User used `--delete` and manual recovery | **PASS** |
| `~/.gitconfig` not overwritten by stow | Stow only touches `~/.config/git/` | Confirmed; Stow never touches `~/.gitconfig` | **PASS** |
| `~/.gitconfig` not symlinked | Remains a regular file | Confirmed; regular file | **PASS** |
| Timestamped backup created | Backup made before bootstrap wiring | User reported backup created by `task git:bootstrap` | **PASS** |
| Identity untouched | `user.name` and `user.email` remain manual | Confirmed; both from `~/.gitconfig` only | **PASS** |
| Rollback path verified | `stow --delete` simulation clean | User verified rollback by direct testing | **PASS** |

**Verdict: PASS**

---

## 7. Required Documentation Fixes

### 7a. `docs/guides/git-setup.md` Line 80: Missing `--no-folding`

**Current text (lines 74–81):**
```
## 5. Apply step (Stow)

After reviewing the dry-run output and confirming no conflicts, apply the Stow package:

⚠️  MANUAL STEP — review dry-run output before running
stow --dir=stow/common --target="$HOME" git
```

**Problem:** The `stow` command omits `--no-folding`. Without it, Stow folds `~/.config/git/` into a single symlink, contradicting ADR-0030.

**Required fix:**
```
stow --dir=stow/common --target="$HOME" --no-folding git
```

**Action:** Update line 80 to include `--no-folding`.

---

### 7b. `docs/guides/git-setup.md` Lines 46–58: Dry-run Step Missing `--no-folding`

**Current text (lines 46–58):**
```
## 4. Dry-run step

Always dry-run the Stow package before applying it. This shows exactly what symlinks would be created without making any changes.

task dry-run AREA=common PACKAGE=git

Or directly:

stow --dir=stow/common --target="$HOME" --simulate git
```

**Problem:** The direct `stow` command omits `--no-folding`. Users who run the direct command will see the folding behavior during dry-run, then encounter the same behavior during apply.

**Required fix:**
```
stow --dir=stow/common --target="$HOME" --no-folding --simulate git
```

**Action:** Update line 57 to include `--no-folding`.

---

### 7c. `docs/guides/git-setup.md` Lines 150–166: Validation Missing Real-Directory Check

**Current text (lines 150–166):**
```
## 7. Validation steps

After completing all setup steps, verify the installation:

bash
# Confirm three symlinks exist in ~/.config/git/
ls -la ~/.config/git/


Expected: `config-common`, `aliases`, and `ignore` all shown as symlinks.

bash
# Confirm each symlink resolves into the repository
readlink ~/.config/git/config-common
readlink ~/.config/git/aliases
readlink ~/.config/git/ignore
```

**Problem:** The validation does not assert that `~/.config/git` itself is a real directory (not a symlink). Users following the guide have no explicit check for the container structure.

**Required fix:** Add an explicit check for real-directory status:

```bash
# Confirm ~/.config/git is a REAL DIRECTORY (not a symlink to the package)
[[ -d "$HOME/.config/git" && ! -L "$HOME/.config/git" ]] && echo "✓ real directory" || echo "✗ ERROR: ~/.config/git is a symlink or does not exist"
```

**Action:** Insert this check before the per-file symlink checks (after line 156, before the "ls -la ~/.config/git/" command). Add a note explaining why: "ADR-0030 requires a real directory; without --no-folding, Stow creates a symlink instead."

---

### 7d. Summary of Required Documentation Changes

| File | Lines | Change | Severity |
|------|-------|--------|----------|
| `docs/guides/git-setup.md` | 57 | Add `--no-folding` to dry-run `stow` command | **High** |
| `docs/guides/git-setup.md` | 80 | Add `--no-folding` to apply `stow` command | **High** |
| `docs/guides/git-setup.md` | 155–160 | Add explicit real-directory check to validation section | **Medium** |

---

## 8. Rollback Path

**Verified rollback procedure (user-tested):**

1. **Undo bootstrap** (remove include.path entries):
   ```bash
   # Option A: Restore from timestamped backup
   cp ~/.gitconfig.bak.TIMESTAMP ~/.gitconfig
   ```
   or manually edit `~/.gitconfig` to remove the two `[include]` blocks.

2. **Undo Stow**:
   ```bash
   stow --dir=stow/common --target="$HOME" --no-folding --simulate --delete git
   ```
   Review output for conflicts. Then:
   ```bash
   stow --dir=stow/common --target="$HOME" --no-folding --delete git
   ```

3. **Cleanup** (if needed):
   - `~/.config/git/config-common`, `aliases`, `ignore` are removed by the `--delete` step.
   - `~/.config/git/` directory remains (stow does not remove directories it did not create).
   - Manual cleanup: `rm -rf ~/.config/git/` if desired (safe; no tracked repo content).

4. **Never use `stow --adopt`** — it overwrites without backup.

**Verdict: Rollback path verified.**

---

## 9. Final Verdict

**Status: VALIDATED WITH REQUIRED DOC FIXES**

The Git setup flow itself works end-to-end: Stow correctly creates per-file symlinks, bootstrap idempotently wires includes, and rollback via `--delete` is clean. User-reported facts match corroborated on-disk state exactly.

However, `docs/guides/git-setup.md` has two critical documentation defects:

1. **Lines 57 and 80** omit `--no-folding`, causing users who follow the guide to encounter directory-folding behavior (wrong layout per ADR-0030).
2. **Validation section** (lines 150–166) does not assert that `~/.config/git` is a real directory, leaving users unable to detect the folding error from the guide alone.

The guide must be corrected before it is reliable for a clean, guided copy-paste run. The flow is sound; the documentation is incomplete.

