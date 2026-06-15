# Review: Dotfiles Foundation Plan — Revision Check

**Number:** 0005
**Date:** 2026-06-15
**Reviewer:** Claude Code (Reviewer role per AGENTS.md §4)
**Artifact reviewed:** `docs/plans/0005-implement-dotfiles-foundation.md` (revised)
**Scope:** Five targeted concerns from review 0004 only.

---

## 1. Taskfile Validation Checks

**PASS.**

All three occurrences of the broken pattern have been replaced:

| Location | Old (broken) | New (correct) |
|----------|-------------|---------------|
| Task 6 validation | `grep -i install Taskfile.yml` | `grep -E "^[[:space:]]{2}(install\|uninstall\|adopt\|unlink):" Taskfile.yml` |
| Safety Checks section | `grep -i install Taskfile.yml` | same anchored pattern |
| End-to-end validation | `grep -c "install" Taskfile.yml` | same anchored pattern |

Pattern analysis: `^[[:space:]]{2}(install|uninstall|adopt|unlink):` matches only lines where exactly two whitespace characters precede one of the forbidden task names followed by `:`. In Taskfile v3 YAML with 2-space indentation, task name keys look like `  detect:` — the pattern matches task names, not description text like `"... are installed"`. False-positive from review 0004 B1 is resolved. ✓

---

## 2. `$HOME` Inspection

**PASS.**

`ls -la ~ | grep -v total` is gone. The Safety Checks "Before starting" block now reads:

```
- Confirm working directory is the repository root: `pwd` and `git status`.
```

Both commands are repo-local and read-only. No `$HOME` path appears in any validation or safety check command. The only plan command that references `$HOME` is `stow --dir=stow --target="$HOME" --simulate` — this is `--simulate` only, read-only, and explicitly sanctioned by PRD 0002. ✓

---

## 3. Pre-Commit Audit Flow

**PASS with minor ordering note.**

Task 14 is now correctly split into two blocks:

- **Before `git add`:** `git status`, `git diff`, repo-local greps, `check.sh`.
- **After `git add`:** `git diff --staged`.

`git diff` (unstaged) runs before staging. `git diff --staged` runs after staging. The intent and ordering logic are correct.

**Minor note (non-blocking):** The `git add` command lives in task 15, but the "after `git add`" instruction lives at the end of task 14. A Builder following tasks strictly in order would reach the `git diff --staged` instruction before running `git add`. In practice, no Builder will misread this — the instruction is self-labelled "After `git add`" — but the plan could be cleaner if `git diff --staged` moved to the top of task 15 (between `git add` and the commit). Not blocking implementation.

---

## 4. `.gitconfig.example` Wording

**PASS.**

Header comment is now:

```ini
# Example only. Do not stow directly.
# Use this as a reference when creating a future managed Git config.
# Keep real identity, email, signing keys, and work settings out of this repository.
```

No "Copy to ~/.gitconfig" instruction. No instruction that leads to `$HOME` modification. Placeholder values (`Your Name`, `your-email@example.com`) unchanged. `excludesfile` line carries an inline warning comment. No signing key, no `[gpg]`, no `[includeIf]`. Privacy grep in task 8 catches any real identity that slips in. ✓

---

## 5. Builder Safety to Implement

**PASS.**

- 15 tasks in phase order: ADRs first → scripts → Taskfile → stow dirs → docs → audit → commit. ✓
- All file operations target the repository root. ✓
- `git add` in task 15 names every file explicitly — no wildcards, no `git add -A`. ✓
- `stow --simulate` hardcoded in `dry-run` task; no install variant exists. ✓
- `check.sh` uses `set -uo pipefail` (no `set -e`) with explicit `if/else` accumulator — review 0004 B1 constraint honoured. ✓
- `task list` strips `stow/` prefix via `sed` — review 0004 B2 constraint honoured. ✓
- `detect-os.sh` is strict to macOS/Arch with Docker/Linux explicitly marked future scope. ✓
- "Files that must not be created" list is explicit and covers all deferred scope. ✓

Builder can proceed with tasks 1–15 in order.

---

## Overall Verdict

**APPROVED for implementation.**

All five targeted concerns are resolved. One non-blocking ordering note on `git diff --staged` placement (end of task 14 vs. start of task 15) — does not affect safety or correctness. The rollback `git clean -n` warning (review 0004 N4) remains unaddressed but is also non-blocking.

**Recommended next action:** Builder implements tasks 1–15 in order, running `git status` after each task.
