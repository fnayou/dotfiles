# Review: Dotfiles Foundation — Implementation Plan

**Number:** 0004
**Date:** 2026-06-15
**Reviewer:** Claude Code (Reviewer role per AGENTS.md §4)
**Artifact reviewed:** `docs/plans/0005-implement-dotfiles-foundation.md`

> **Filename note:** User requested review of `docs/plans/0003-implement-dotfiles-foundation.md`.
> That number is taken by `0003-add-initial-prd.md`. The actual plan is at `0005`. Reviewed `0005`.

---

## Summary

Reviewed implementation plan 0005 for safety, privacy, GNU Stow correctness, macOS/Arch separation, scope discipline, validation command correctness, and rollback clarity. Plan is well-structured and minimal. One blocking issue found in validation commands. Five non-blocking issues found. No $HOME modifications, no destructive operations, no secrets in plan content.

---

## Blocking Issues

### B1 — `grep "install" Taskfile.yml` is a false-positive check

**Location:** Task 6 § Validation, and § Validation Commands (end-to-end section)

Task 6 validation:
```bash
grep -i install Taskfile.yml          # must return empty — no install task
```

End-to-end validation:
```bash
grep -c "install" Taskfile.yml        # must be 0
```

Both checks will always fail. The `check` task's `desc` field contains:

```yaml
desc: "Verify prerequisites (stow, git, task) are installed"
```

The word "installed" matches both `grep -i install` and `grep -c "install"`. These checks will always return a match, causing a false failure on a correct Taskfile.

The same false positive applies to the Safety Checks section:
```
After task 6: `grep -i install Taskfile.yml` must return empty.
```

**Required fix:** Replace both grep patterns with one that targets task name lines only:

```bash
grep -E "^  install:" Taskfile.yml    # must return empty — checks task name, not desc
```

Or equivalently:

```bash
grep "^  install:" Taskfile.yml && echo "FAIL: install task exists" || echo "OK: no install task"
```

This anchors to the YAML task name key (two-space indent + `install:`) and cannot match text inside `desc` strings.

---

## Non-Blocking Issues

### N1 — `task dry-run PACKAGE=common/git` will link `.gitconfig.example`, not `.gitconfig`

**Location:** Task 6 Validation + End-to-end Validation Commands

```bash
task dry-run PACKAGE=common/git       # must print stow dry-run output (no actual links)
```

The plan states "no actual links" (correct — `--simulate`), but does not clarify what output to expect. Since the only file in `stow/common/git/` is `.gitconfig.example`, stow's dry-run output will show a simulated link for `~/.gitconfig.example` — not `~/.gitconfig`. This is unexpected to a user who thinks they are dry-running a git config package.

This is safe (no actual links) and expected given the `.example`-first approach. But the validation comment should say:

```bash
task dry-run PACKAGE=common/git
# Expected: stow reports simulated link ~/.gitconfig.example -> stow/common/git/.gitconfig.example
# This is correct — the package contains only the .example template, not a real dotfile.
# Real dry-run output changes when .gitconfig is added in a future phase.
```

Also: `docs/stow-usage.md` § Dry-run (task 10) should include this note — the example dry-run output in the foundation phase shows `.gitconfig.example`, not `.gitconfig`.

---

### N2 — `.gitconfig.example` `excludesfile` references a file not in scope

**Location:** Task 8 § Required content

```ini
[core]
    excludesfile = ~/.gitignore_global
```

`~/.gitignore_global` will not exist after this phase (deferred to the git package PRD). Git handles missing `excludesfile` gracefully, but a user who copies `.gitconfig.example` → `.gitconfig` will silently have no global gitignore protection until they create the file.

**Suggestion:** Add a comment to the example:

```ini
[core]
    editor = vim
    autocrlf = input
    # Create ~/.gitignore_global (or change this path) before using this config.
    excludesfile = ~/.gitignore_global
```

Or use the XDG path instead (`~/.config/git/ignore`), which aligns with ADR-0004 mixed-mode XDG adoption — that path is the git default when XDG_CONFIG_HOME is set. Non-blocking; either approach is acceptable.

---

### N3 — Task 11 (README update) placement underspecified

**Location:** Task 11

> "Add it under a 'Documentation' or 'Usage' section if one exists; otherwise add a short section."

The current `README.md` has no "Documentation" or "Usage" section. Nearest relevant section is `## Planned future direction`, which already mentions `stow/`. Without guidance on placement, the Builder will choose arbitrarily.

**Suggestion:** Specify: "Add a `## Documentation` section before `## Basic commands`, containing a link to `docs/stow-usage.md`." This prevents the Builder from inserting the link in an inconsistent location.

---

### N4 — Rollback `git clean -n` lacks warning about `-f`

**Location:** § Rollback Strategy

```bash
git clean -n                          # preview what would be removed
```

`git clean -n` is safe (dry-run only). But the rollback section does not warn that running `git clean -f` (the actual removal command) would permanently delete all untracked files — including the new scripts, Taskfile, and stow tree created by this plan.

Per AGENTS.md §8: dangerous commands must be marked. `git clean -f` is destructive and irreversible.

**Suggestion:** Add after the `git clean -n` line:

```
⚠️  MANUAL STEP — do NOT run `git clean -f` unless you intend to delete all untracked files.
```

---

### N5 — Branch guidance underspecified

**Location:** § Assumptions

> "Repository is on branch `docs/add-pre-commit-review` or a new implementation branch."

The plan does not instruct the Builder whether to implement on the current branch (`docs/add-pre-commit-review`) or create a new one. If the Builder creates a new branch, the current branch's work is preserved. If they stay on `docs/add-pre-commit-review`, the commit lands there.

Neither is wrong, but the Builder needs explicit direction to avoid making an ambiguous choice.

**Suggestion:** Add one sentence: "Implement on the current branch (`docs/add-pre-commit-review`). No new branch required for this phase."

---

## Safety Verdict

**PASS.**

No step in the plan modifies, creates, or deletes any file under `$HOME`. No `stow` command runs without `--simulate`. No `rm`, `mv`, or `ln -s` against `$HOME` appears anywhere. All file operations target the repository root. The pre-commit audit (task 14) is thorough. `git add` in task 15 names files explicitly — no `git add -A` or `git add .`. Safety is correctly enforced throughout.

---

## Privacy Verdict

**PASS.**

`.gitconfig.example` uses `Your Name` and `your-email@example.com` — no real identity. Privacy grep patterns in tasks 8 and 14 search for real username (`fnayou`, `aymen`) and forbidden patterns (`BEGIN`, `signingkey`, `password`, `token`, `secret`). No API keys, tokens, SSH key content, or private hostnames appear in any plan-specified file content.

---

## GNU Stow Correctness Verdict

**PASS.**

- `stow --dir=stow --target="$HOME" --simulate {{.PACKAGE}}` is the correct command form. ✓
- `--simulate` is hardcoded in the Taskfile `dry-run` task — cannot be bypassed. ✓
- `stow --adopt` appears nowhere in the plan. ✓
- `stow .` is explicitly forbidden in the `docs/stow-usage.md` content spec. ✓
- `stow/macos/` and `stow/arch/` `.gitkeep` warning is included in `docs/stow-usage.md` section 6. ✓
- Package path `common/git` with `--dir=stow` resolves to `stow/common/git/` — valid stow behavior. The Builder should confirm actual dry-run output during task 6 validation. ✓

---

## macOS / Arch Separation Verdict

**PASS.**

- `stow/common/git/` satisfies all three ADR-0001 common-package criteria (same path, same values, no platform-specific behavior). ✓
- `stow/macos/` and `stow/arch/` are empty markers only — no platform-specific config mixed in. ✓
- `detect-os.sh` uses the correct AGENTS.md §10 detection pattern for both platforms. ✓
- No Homebrew commands in Arch-facing context and vice versa. ✓
- `check.sh`, Taskfile tasks, and `docs/stow-usage.md` are all platform-agnostic. ✓

---

## Scope Verdict

**PASS.**

15 tasks, 14 files (11 created, 3 modified). Scope matches PRD 0002 acceptance criteria exactly. No zsh, no SSH, no Neovim, no Docker, no Brewfiles, no `packages/macos/`, no `test/`. No real dotfiles. The "Files that must not be created" list is explicit and correct.

---

## Rollback Clarity Verdict

**PASS with N4 resolved.**

Rollback covers pre-commit (file-by-file checkout), post-commit pre-push (reset), and post-push (revert). All operations are git-only because no `$HOME` changes exist to reverse. N4 (missing warning on `git clean -f`) should be added before plan is marked Approved.

---

## Validation Commands Verdict

**FAIL on B1 — pass otherwise.**

B1 (`grep "install" Taskfile.yml`) is a broken check that will always fail. All other validation commands are safe, read-only, and correct. End-to-end validation covers structure, scripts, Taskfile, privacy, docs, and git state.

---

## Recommended Next Action

1. **Fix B1** — replace both `grep -i install Taskfile.yml` / `grep -c "install" Taskfile.yml` with `grep "^  install:" Taskfile.yml`. Applies in: Task 6 validation, Safety Checks section, and end-to-end Validation Commands.
2. **Address N1** — clarify expected dry-run output in task 6 validation comment and in the `docs/stow-usage.md` content spec (task 10).
3. **Address N3** — specify exact placement for the README link in task 11.
4. **Address N4** — add `⚠️  MANUAL STEP` warning before rollback `git clean -n` line.
5. **Address N5** — state explicitly that implementation uses the current branch.
6. Mark plan 0005 **Approved** once B1 is resolved.
7. Builder proceeds with tasks 1–15 in order, running `git status` after each task.
