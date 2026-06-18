# Git Setup Guide Fix Review

**Number:** 0034
**Date:** 2026-06-19
**Status:** Complete
**Type:** Documentation fix review
**Related Documents:** docs/guides/git-setup.md, docs/reviews/0033-git-local-setup-validation.md, ADR-0030

---

## Review Scope

This review validates that `docs/guides/git-setup.md` addresses all corrective actions identified in validation report 0033. The 8-point checklist verifies:

1. No unsafe task references in guide
2. Apply step includes `--no-folding`
3. Dry-run step includes `--no-folding`
4. Rationale documented for `--no-folding` requirement
5. Real-directory validation present
6. Per-file symlink validation present
7. Rollback path documented for folded-symlink scenario
8. No `stow --adopt` instructions (only prohibitions)
9. Taskfile does not add live `stow` task
10. Dry-run task reference unchanged

---

## Checklist Results

| # | Item | Verdict | File:Line | Notes |
|---|---|---|---|---|
| 1 | No `task stow AREA=common PACKAGE=git` in guide | PASS | — | `grep` returns `no-task-stow-in-guide-ok` |
| 2 | Apply step uses `--no-folding` | PASS | git-setup.md:80 | `stow --dir=stow/common --target="$HOME" --no-folding git` ✓ |
| 3 | Dry-run step uses `--no-folding` | PASS | git-setup.md:57 | `stow --dir=stow/common --target="$HOME" --no-folding --simulate git` ✓ |
| 4 | Explains WHY `--no-folding` required | PASS | git-setup.md:83 | Explicit explanation: Stow collapses to single symlink without it; ADR-0030 requires real directory; always stow with `--no-folding` |
| 5 | Validates `~/.config/git` is real directory | PASS | git-setup.md:158 | Validation check: `test ! -L "$HOME/.config/git" && echo "OK: ~/.config/git is a real directory"` ✓ |
| 6 | Validates managed files are symlinks | PASS | git-setup.md:170–172 | Three `readlink` commands for config-common, aliases, ignore ✓ |
| 7 | Rollback for folded-symlink scenario | PASS | git-setup.md:298–329 | Dedicated troubleshooting section "~/.config/git became a symlink (directory folding)" with 4-step recovery using `--delete` + mkdir + re-apply `--no-folding` ✓ |
| 8 | No `--adopt` instructions (prohibitions OK) | PASS | git-setup.md:70, 85, 263 | Three prohibition statements: lines 70 (dry-run), 85 (apply), 263 (troubleshooting). Zero instructions to run `--adopt`. All statements say "DO NOT use" or "is forbidden" |
| 9 | Taskfile has NO live stow task | PASS | Taskfile.yml:27 | Only `dry-run` task exists (line 27, uses `--simulate`). No install/apply `stow` task defined. Tasks are: detect, check, list, dry-run, deps:check:zsh, deps:macos:shell, git:bootstrap:dry-run, git:bootstrap |
| 10 | Dry-run task reference unchanged | PASS | git-setup.md:51 | `task dry-run AREA=common PACKAGE=git` present in guide section 4 |

---

## Per-Check Findings

### Check 1: No unsafe task references
**PASS** — git-setup.md contains no references to `task stow AREA=...`. The guide directs users to `task dry-run AREA=common PACKAGE=git` for dry-run and to direct `stow` command for apply. This is correct and matches Taskfile design.

### Check 2: Apply step includes `--no-folding`
**PASS** — Line 80: `stow --dir=stow/common --target="$HOME" --no-folding git` ✓. Apply step properly flagged with `⚠️ MANUAL STEP` warning. Rollback at line 326 also includes `--no-folding`.

### Check 3: Dry-run step includes `--no-folding`
**PASS** — Line 57: `stow --dir=stow/common --target="$HOME" --no-folding --simulate git` ✓. Both task reference (line 51) and direct command (line 57) presented. Direct command includes `--no-folding` as required.

### Check 4: Rationale for `--no-folding`
**PASS** — Line 83 provides explicit, detailed explanation:

> **`--no-folding` is required.** Without it, Stow collapses `~/.config/git` into a single symlink pointing at the package directory (directory folding) instead of creating `~/.config/git` as a real directory with one symlink per managed file. The managed layout (ADR-0030) requires `~/.config/git` to be a real directory. Always stow this package with `--no-folding`.

This directly addresses the validation finding 0033 §2b (user encountered folding without `--no-folding` in guide).

### Check 5: Real-directory validation
**PASS** — Line 158: `test ! -L "$HOME/.config/git" && echo "OK: ~/.config/git is a real directory"` ✓

This directly addresses validation finding 0033 §7c (validation section missing real-directory check). Placed before per-file symlink checks, with explicit instruction to confirm container directory structure.

### Check 6: Per-file symlink validation
**PASS** — Lines 170–172 include three `readlink` commands for all three managed files. Combined with real-directory check (line 158), validation now fully covers both container and per-file structure.

### Check 7: Rollback for folded-symlink scenario
**PASS** — Lines 298–329 dedicated troubleshooting section titled "~/.config/git became a symlink (directory folding)":

1. Verification: `ls -ld ~/.config/git` to detect folded symlink (line 305)
2. Rollback: `stow --delete git` (line 313)
3. Recovery: `mkdir -p ~/.config/git` (line 319)
4. Re-apply: `stow --no-folding git` (line 326)
5. Final check: `test ! -L` (line 329)

All steps include `--no-folding` in re-apply. This is the exact scenario validation report 0033 identified as a user error path.

### Check 8: No `--adopt` instructions
**PASS** — Three locations mention `--adopt`:

- Line 70 (dry-run section): "Do NOT use `stow --adopt`"
- Line 85 (apply section): "`stow --adopt` is forbidden. The `--adopt` flag silently overwrites files in `$HOME` with the repository version, destroying your existing content without a backup. It must never be used."
- Line 263 (troubleshooting): "Do NOT use `stow --adopt` — it would silently overwrite your existing file with the repository version without any backup."

All three are **prohibitions**, not instructions. Zero "run this" statements. Compliant with privacy.md forbidding `--adopt`.

### Check 9: Taskfile has no live stow task
**PASS** — Taskfile.yml contains eight tasks: `detect`, `check`, `list`, `dry-run`, `deps:check:zsh`, `deps:macos:shell`, `git:bootstrap:dry-run`, `git:bootstrap`.

- `dry-run` (line 27) uses `--simulate` only — read-only.
- `git:bootstrap:dry-run` (line 58) is read-only (no `git config --add`).
- `git:bootstrap` (line 91) is marked "MANUAL USE ONLY: never run automatically" (line 92 desc).

No task named `stow` or `git:apply` exists. No task runs `stow` without `--simulate` or `--delete`. Matches guide design: Stow apply is manual `stow` command, not automated task.

### Check 10: Dry-run task reference present
**PASS** — Line 51: `task dry-run AREA=common PACKAGE=git` present in section 4 (Dry-run step). Unchanged from prior version. Correct reference.

---

## Verdict

**APPROVED**

The guide has been comprehensively fixed to address all three corrective actions from validation report 0033:

- ✓ Line 57 and 80: Both stow commands now include `--no-folding`
- ✓ Line 83: Explicit rationale for `--no-folding` requirement
- ✓ Line 158: Real-directory validation check added to section 7

All 8 safety and design checks pass. The guide is now safe for copy-paste execution without users encountering directory-folding errors. Rollback path for accidental folding is documented. Taskfile design remains safe (no live `stow` task, all manual steps marked).

**No further changes required.**

---

## Files Reviewed

- /Users/fnayou/works/dotfiles/docs/guides/git-setup.md (361 lines)
- /Users/fnayou/works/dotfiles/docs/reviews/0033-git-local-setup-validation.md (validation baseline)
- /Users/fnayou/works/dotfiles/Taskfile.yml (task definitions)
- /Users/fnayou/works/dotfiles/docs/decisions/0030-xdg-style-git-config-layout.md (layout requirement)

