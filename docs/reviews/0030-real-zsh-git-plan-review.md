# Review: Real Zsh and Git Configuration Plan

**Number:** 0030
**Date:** 2026-06-18
**Scope:** docs/plans/0013-real-zsh-git-configuration-plan.md
**Verdict:** CHANGES REQUIRED

---

## Summary

Plan 0013 is well-structured overall and correctly scopes the work: replacing placeholder tokens in zsh config, creating committed Git XDG files, removing legacy templates, adding bootstrap tasks, and writing ADRs. However, the plan has critical scope misalignment with current repository state. The git config files (config-common, aliases, ignore) and supporting ADRs have already been partially created in the working tree but are not yet staged or committed. The plan assumes these do not exist yet and treats their creation as work to be done. Additionally, ADR-0028 (human setup guides) was established AFTER this plan was written but mandates a guide for any manually-activated package — the Git package requires manual activation (`git:bootstrap`, identity configuration), making a guide a blocking completion requirement. The plan must be revised to (1) account for existing work in the feature branch, (2) describe the actual current state accurately, and (3) include the setup guide requirement from ADR-0028 before Builder implementation proceeds.

---

## Findings

### Lifecycle Correctness

docs/plans/0013-real-zsh-git-configuration-plan.md:4: 🟢 PASS: Status is correctly marked "Draft" — appropriate, as implementation has not been reviewed and approved.

docs/plans/0013-real-zsh-git-configuration-plan.md (overall): 🟡 NOTE: Manual real-home steps (Tasks 10, 12) are correctly marked with `⚠️ MANUAL STEP`. However, the plan does not distinguish repository-only completion from local-machine setup completion. Per AGENTS.md §5, manual Stow and bootstrap steps are local machine setup, not repository implementation completion. The plan correctly separates these but could explicitly state "Repository-only completion criteria" vs. "Local machine setup criteria" to avoid confusion for a Builder who might think the plan is complete after pushing code.

### ADR Numbering

docs/plans/0013-real-zsh-git-configuration-plan.md (Tasks 15-18): 🔴 BLOCKING: The plan refers to ADR-0024 through ADR-0027. A listing of `docs/decisions/` shows that 0024–0027 do NOT exist. The plan assumes these numbers are available. Checking the last existing ADR: 0023 exists (zsh-local-override-slot.md), and 0028 exists (require-human-setup-guides-for-manually-activated-packages.md, dated 2026-06-18). ADR-0028 was added AFTER this plan was written, creating a numbering gap: 0024–0027 are not yet created, but 0028 already is.

**Fix required:** The plan must either (a) renumber Tasks 15-18 to use 0024–0027 (assuming 0028 was written in a parallel session and the plan was drafted first), or (b) acknowledge that 0028 was established and adjust the ADR write tasks accordingly. Given that 0028 is checked into the repository and is dated 2026-06-18 (same day), the most likely scenario is that 0028 was written as part of PRD/Architecture review, and the plan should reference it.

Additionally, the plan does not address whether the new guide requirement in ADR-0028 applies to this work. It does: the Git package has manual steps (`git:bootstrap`, identity configuration), so a `docs/guides/git-setup.md` is now mandatory per ADR-0028.

### Scope

docs/plans/0013-real-zsh-git-configuration-plan.md (overall): 🟡 NOTE: The scope is appropriate in content (zsh placeholder fix, Git config creation, legacy file removal, bootstrap tasks, ADRs) but the plan does NOT account for work already in the working tree. **Critical finding:** Tasks 2-5 describe creating `stow/common/git/.config/git/config-common`, `aliases`, and `ignore` — but these files ALREADY exist at those paths in the working tree (untracked, not staged). The plan was written assuming these do not exist, but they do. Either:
  (a) The plan was drafted before these files were added to the feature branch (out of order), or
  (b) The plan is incomplete/stale and needs revision.

This creates a serious problem for a Builder: following the plan's Task 2-5 literally would attempt to create files that already exist, causing confusion or errors.

**Fix required:** The plan must be revised to state "The files already exist in the working tree. This plan audits them, stages them, and commits them — it does not create them." Task descriptions should shift from "create" to "audit, verify, and stage."

### Git Config Safety

docs/plans/0013-real-zsh-git-configuration-plan.md (Task 3, lines 173-214): 🟢 PASS: Inspected the specified `config-common` content. Matches expected structure:
  - No `[user]` block.
  - No `signingkey`, `gpgsign`, `[gpg]`, or `[commit]` sections.
  - No `[includeIf]` blocks.
  - No credential helpers (`osxkeychain`, `libsecret`).
  - No `[alias]` section in `config-common`.
  - `core.excludesfile = ~/.config/git/ignore` present and correct.

Actual file `/Users/fnayou/works/dotfiles/stow/common/git/.config/git/config-common` verified: contains `[core]` (editor=vim, excludesfile correct), `[rerere]`, `[push]`, `[color]`, `[diff]`, `[difftool]`. No forbidden sections. ✓

docs/plans/0013-real-zsh-git-configuration-plan.md (Task 4, lines 237-284): 🟡 NOTE: Inspected the specified `aliases` content. The plan lists four safe aliases: `st`, `co`, `br`, `lg`. Actual file `/Users/fnayou/works/dotfiles/stow/common/git/.config/git/aliases` contains 50+ aliases, including many beyond the four listed in the plan. 

**Examples of plan-unlisted aliases in the file:**
  - `a = add --all`, `ai = add -i` (add shortcuts — safe).
  - `b = branch`, `ba = branch -a` (branch shortcuts — safe).
  - `c = commit`, `ca = commit -a`, `cd = commit --amend` (commit shortcuts — safe).
  - `d = diff`, `dc = diff --cached` (diff shortcuts — safe).
  - All appear safe, but plan does not document them as expected.

**No risky aliases found:** Grep for `force`, `hard`, `purge`, `nuke`, `svn`, `filter-branch`, `daemon`, `master` produces no output. ✓

**Finding:** The actual aliases file is significantly more comprehensive than the plan documents. This is not a safety issue (aliases are safe), but it is a scope mismatch: the plan describes a minimal four-alias file as the expected output, but the actual file has 50+. A Builder following the plan literally and creating aliases manually would produce something different from what already exists, causing confusion.

docs/plans/0013-real-zsh-git-configuration-plan.md (Task 5, lines 287-355): 🟢 PASS: Inspected the specified `ignore` content. Actual file exists and contains well-known tool patterns (macOS `.DS_Store`, Linux `.Trash-*`, editor `.idea/`, `.vscode/`, build `*.pyc`, `Thumbs.db`, environment `.env.local`). No machine-specific patterns. Safe to commit. ✓

### Bootstrap Task Safety

docs/plans/0013-real-zsh-git-configuration-plan.md (Task 8, lines 444-542): 🔴 BLOCKING: The `git:bootstrap:dry-run` and `git:bootstrap` tasks are NOT present in the current `Taskfile.yml`. The plan specifies exact YAML syntax for both tasks. Inspected current Taskfile.yml: only contains `detect`, `check`, `list`, `dry-run`, `deps:check:zsh`, `deps:macos:shell` tasks. No `git:bootstrap:dry-run` or `git:bootstrap`. 

**Verification:** The plan shows bootstrap task code in a `yaml` block (lines 460-517). This code must be added to `Taskfile.yml`. Current Taskfile ends at line 57 (with `deps:macos:shell`). The tasks are not yet written.

**Specific safety check findings:**

- Task 8 specifies `git:bootstrap:dry-run` — read-only, correct. ✓
- Task 8 specifies `git:bootstrap` — uses `git config --global --add` only (not direct file overwrite), creates timestamped backup before modifying existing `~/.gitconfig`, idempotent via check-before-add pattern. ✓
- Neither task has a `deps:` field — correct, they must be standalone. ✓
- Both tasks have `desc:` field — correct. ✓
- Task 12 validation checks `git config --global --get-all include.path | sort | uniq -d` for duplicates — correct. ✓
- The `2>/dev/null` in `git config --global --get-all include.path 2>/dev/null` correctly suppresses error if `~/.gitconfig` doesn't exist. ✓

**Finding:** The bootstrap tasks as described in the plan are safe. They are not yet in the Taskfile, so a Builder must add them. The plan provides the exact code, which is good.

### Stow Safety

docs/plans/0013-real-zsh-git-configuration-plan.md (Task 9, lines 546-582): 🟢 PASS: Fake-home validation uses `stow --dir=stow/common --target="$TEST_HOME" --simulate git` — correct form (uses `stow/common`, not `stow/`). ✓

docs/plans/0013-real-zsh-git-configuration-plan.md (Task 10, lines 585-628): 🟢 PASS: Real-home Stow step correctly marked with `⚠️ MANUAL STEP` marker. ✓

docs/plans/0013-real-zsh-git-configuration-plan.md (overall): 🟢 PASS: No `stow --adopt` appears anywhere in the plan. ✓

docs/plans/0013-real-zsh-git-configuration-plan.md (Task 10 rollback, lines 623-626): 🟢 PASS: Rollback uses `--delete`, which is correct. ✓

### Validation Accuracy

docs/plans/0013-real-zsh-git-configuration-plan.md (Task 14, lines 792-849): 🟡 NOTE: Privacy audit commands check for identity-revealing patterns. Line 810-812 grep for `signingkey\|\[user\]\|\[gpg\]\|gpgsign\|osxkeychain\|token\|password` in config files.

**Concern:** Line 810 comment says "no identity values" but the actual files (`config-common`, `aliases`) contain no comments with these patterns. Verifying actual content of `stow/common/git/.config/git/config-common`:
  - First line is a comment: `[core]` (a section header inside a config file, not a comment starting with `#`).
  - The grep pattern includes `\[user\]` which would match a comment like `# No [user] identity here` — this would produce a false positive.
  
**Actual test:** `grep -in 'signingkey\|\[user\]\|\[gpg\]\|gpgsign\|osxkeychain\|token\|password' /Users/fnayou/works/dotfiles/stow/common/git/.config/git/config-common /Users/fnayou/works/dotfiles/stow/common/git/.config/git/aliases` produces no output. The files do not contain these patterns, so the audit passes. However, if someone added a comment saying `# [user] is configured locally` to document the separation, the audit would falsely fail. 

**Fix suggested:** Consider adding a comment above the grep command: "Note: this grep will match literal section headers in comments. Inspect any matches to confirm they are false positives rather than actual forbidden sections."

Alternatively, use a stricter pattern like `'^\[user\]'` to match only actual section headers at line start (config files have section headers at line start, not in comments). But the current plan is safe for the current files, so this is a NOTE, not a blocker.

docs/plans/0013-real-zsh-git-configuration-plan.md (Task 1, lines 75-136): 🟢 PASS: Validation for shared.zsh includes syntax check (`zsh -n`), placeholder check (`grep 'YOUR_'`), forbidden content check (grep for brew, pacman, etc.). All correct patterns. ✓

docs/plans/0013-real-zsh-git-configuration-plan.md (Task 9 validation, lines 564-574): 🟢 PASS: Fake-home dry-run expected output format is stated clearly: three symlink creation lines with no conflicts, exit code 0. Correct. ✓

### Documentation Requirements (ADR-0028)

docs/plans/0013-real-zsh-git-configuration-plan.md (overall): 🔴 BLOCKING: ADR-0028 (require-human-setup-guides-for-manually-activated-packages.md) establishes that any package with manual setup steps must include a guide under `docs/guides/`. The Git package in this plan has two manual steps:
  1. Task 10: `stow --dir=stow/common --target="$HOME" git` (Stow manual step).
  2. Task 12: `task git:bootstrap` (bootstrap manual step).
  3. Identity configuration (implied by Git design — user must set `user.name`, `user.email`).

Per ADR-0028 §1, the guide must cover:
  - What the package manages (files stowed, symlink targets).
  - What it does NOT manage (especially `~/.gitconfig`, which remains unmanaged).
  - Prerequisites (tools that must be installed).
  - Dry-run step.
  - Apply step (Stow).
  - Manual activation steps (running bootstrap, setting identity).
  - Validation steps.
  - Rollback steps.
  - Troubleshooting.
  - Expected final file layout.

**The plan does not include any ADR task to write `docs/guides/git-setup.md`.** This is a blocking issue. ADR-0028 states: "Future package implementations — Git, Zsh, Alacritty, Neovim, and any other package that requires manual action — must include or update their `docs/guides/<package>-setup.md` as part of the implementation PR. A package PR without a required guide is incomplete and must not be merged."

The plan must be revised to add a task: **Write `docs/guides/git-setup.md`** covering all sections required by ADR-0028. This task should be added before the completion criteria (not marked Complete without it).

### Taskfile Style

docs/plans/0013-real-zsh-git-configuration-plan.md (Task 8, lines 460-517): 🟢 PASS: The two new task YAML blocks follow existing style: 2-space indentation under `tasks:`, `desc:` field on first line, `cmds:` with `|` block scalar. Matches style of existing `dry-run` task and `deps:check:zsh` task. ✓

docs/plans/0013-real-zsh-git-configuration-plan.md (Task 8): 🟢 PASS: Neither task has a `deps:` field — correct, per Taskfile expectations. ✓

### Working Tree State Mismatch

docs/plans/0013-real-zsh-git-configuration-plan.md (overall): 🔴 BLOCKING: The plan was written as if Tasks 2-5 (creating git config files) are future work. However, a `git status` check shows:
  - `stow/common/git/.config/git/aliases` — exists, untracked.
  - `stow/common/git/.config/git/config-common` — exists, untracked.
  - `stow/common/git/.config/git/ignore` — exists, untracked.
  - `stow/common/git/.gitconfig.example` — marked for deletion (deleted in working tree).
  - `stow/common/git/.gitignore_global.example` — marked for deletion (deleted in working tree).

The plan assumes these files do not yet exist and Tasks 2-5 must create them. In reality, they exist and must be staged/committed. This is a fundamental scope mismatch.

**Two possible interpretations:**
1. The plan was drafted BEFORE the files were created, and implementation started before the plan was finalized (out-of-order workflow).
2. The plan is accurate but the repository state is dirty — the files should be in a separate commit or stash.

Either way, the plan must be revised to describe the actual work: auditing existing files, staging them, and committing them — not creating them from scratch.

### Zsh Placeholder Status

docs/plans/0013-real-zsh-git-configuration-plan.md (Task 1, lines 75-136): Verified the current state of `stow/common/zsh/.config/zsh/shared.zsh`:
  - Line 16: `export EDITOR="YOUR_EDITOR"` — still contains placeholder. ✓
  - Line 17: `export PAGER="YOUR_PAGER"` — still contains placeholder. ✓

The plan correctly identifies these as needing to be replaced with `nvim` and `less` respectively. No issue here.

### ADR-0028 and Human Setup Guides

docs/plans/0013-real-zsh-git-configuration-plan.md (Tasks 15-18): The plan includes tasks to write ADRs 0024-0027. Per ADR-0028, a new ADR may be needed to document the human setup guide requirement for Git and Zsh packages. However, ADR-0028 is already established, so what is needed is:
  1. A task to write `docs/guides/git-setup.md` (mandatory per ADR-0028).
  2. Possibly a task to write `docs/guides/zsh-setup.md` (also mandatory per ADR-0028 — Zsh requires manual activation too).

The plan does not include these tasks.

---

## Verdict

**CHANGES REQUIRED**

The plan is conceptually sound and well-written, but has three blocking issues that must be resolved before Builder implementation:

1. **ADR numbering:** The plan refers to ADR-0024 through ADR-0027 without confirming they exist. They do not. ADR-0028 already exists. The plan must renumber or acknowledge the gap.

2. **Working tree state mismatch:** The plan assumes git config files (`config-common`, `aliases`, `ignore`) do not yet exist and must be created. They already exist in the working tree (untracked). The plan must be revised to describe auditing and staging existing files, not creating new ones.

3. **Missing guide requirement:** ADR-0028 (dated 2026-06-18, same day as the plan) mandates a setup guide (`docs/guides/git-setup.md`) for any package with manual activation steps. The Git package has manual steps (Stow, `git:bootstrap`, identity config). The plan does not include a task to write this guide. Per ADR-0028, the guide is mandatory and its absence blocks the PR from merging.

Additionally, a NOTE: consider whether `docs/guides/zsh-setup.md` should also be added, as Zsh also requires manual activation (adding the guarded include block to `~/.zshrc`). The plan assumes the zsh package is already stowed (per assumption, line 20), but a first-time user would need a guide.

---

## Blocking Issues Summary

- 🔴 ADR numbers 0024-0027 assumed available but do not exist; ADR-0028 already exists, creating numbering ambiguity.
- 🔴 Plan assumes git config files do not exist; they already exist in the working tree. Scope is misaligned with repository state.
- 🔴 Missing task to write `docs/guides/git-setup.md` — mandatory per ADR-0028.

Recommended action: Revise the plan to (1) renumber ADR tasks to match actual available numbers, (2) describe the work as auditing and staging existing files rather than creating them, (3) add tasks to write required setup guides. Do not proceed with Builder implementation until these changes are made and the plan is re-reviewed.
