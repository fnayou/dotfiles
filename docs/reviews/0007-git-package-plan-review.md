# Review: Git Package Implementation Plan

**Number:** 0007
**Status:** APPROVED
**Date:** 2026-06-17
**Reviewer:** Plan Review Agent
**Documents reviewed:**
- docs/plans/0006-implement-git-package.md
- docs/prd/0003-git-package.md
- docs/architecture/0003-git-package-architecture.md
- docs/reviews/0006-git-package-prd-architecture-review.md

---

## Verdict

**APPROVED**

The implementation plan comprehensively addresses all PRD 0003 acceptance criteria and architecture 0003 design decisions. Task ordering is correct, safety measures are comprehensive, privacy protections are enforced at multiple checkpoints, and no modifications to `$HOME` are performed. The plan is ready for Builder execution.

---

## Findings

### Completeness
- ✓ All PRD 0003 acceptance criteria covered by at least one task.
- ✓ All three architecture-proposed ADRs (0013, 0014, 0015) have dedicated write tasks (tasks 2, 3, 4).
- ✓ `.gitconfig.example` full content task exists with correct architecture-sourced content (task 5, lines 304-335).
- ✓ `.gitignore_global.example` creation task with correct pattern categories (task 6, lines 370-406).
- ✓ `.gitignore` safety entries task exists (task 7).
- ✓ `docs/stow-usage.md` adoption section task exists with six numbered steps (task 8, lines 480-573).
- ✓ Status field update tasks for PRD and architecture (tasks 10, 11).
- ✓ Pre-commit privacy audit task with multiple grep vectors (task 12).
- ✓ Staging and commit tasks (tasks 13, 14).
- ✓ Taskfile assessment checkpoint task (task 9).

### Safety
- ✓ No task modifies `$HOME` or files outside repository root.
- ✓ No task executes `stow` commands — all Stow operations documented for manual review only.
- ✓ All documented stow install commands have `⚠️  MANUAL STEP` marker immediately preceding the code fence (lines 531, per stow.md rule).
- ✓ All documented dry-run steps precede install steps.
- ✓ No `stow --adopt` suggested or documented.
- ✓ No `rm`, `mv`, or `ln -s` targeting `$HOME`.
- ✓ Rollback strategy exists for every task, with per-task and full-plan rollback sequences (lines 932-969).
- ✓ Pre-implementation checklist comprehensive — eight conditions must pass before starting (lines 38-69).

### Privacy
- ✓ No task reads, inspects, or references user's real `~/.gitconfig` or global gitignore.
- ✓ Proposed `.gitconfig.example` content (task 5) uses only approved placeholders: `Your Name` and `your-email@example.com`.
- ✓ No signing keys, GPG config, credential helpers, or tokens in proposed `.gitconfig.example` content.
- ✓ `.gitignore_global.example` content (task 6) contains no real paths or identity.
- ✓ Pre-commit privacy audit (task 12) includes six grep checks covering signing keys, credentials, personal identity, and private key material (lines 679-712).
- ✓ Staged diff privacy check in commit task (lines 925 implied by validation).

### Stow Layout and Commands
- ✓ All `.example` files are non-stowable — user renames locally before stowing (correctly stated in task 8).
- ✓ ADR-0003 (`.example` files) enforcement clear.
- ✓ `.gitconfig.common` and `.gitignore_global` added to `.gitignore` (task 7) prevents accidental commit of populated local files.
- ✓ Stow command form uses architecture 0003 approved explicit form: `stow --dir=stow/common --target="$HOME" git`.
- ✓ No flat `stow .` or unsafe patterns proposed.

### Documentation Quality
- ✓ All commands copy-pasteable and correct.
- ✓ Multi-line `git add` command (lines 729-739) clear with proper continuation.
- ✓ Marker placement in task 8 (lines 531) correct — no blank line between marker and fence.
- ✓ Validation commands present for each task (all 14 tasks have validation sections).
- ✓ End-to-end validation sequence provided (lines 835-893) with structure, content, safety, and git state checks.
- ✓ Privacy checks included before staging and commit.

### Task Ordering
- ✓ Task 1 (architecture marker fix) placed first — resolves review 0006 finding before other work.
- ✓ ADR write tasks (2-4) complete before stow package file tasks (5-6).
- ✓ Safety entries task (7) before adoption documentation task (8).
- ✓ Privacy audit task (12) before staging task (13).
- ✓ Staging (13) before commit (14).
- ✓ Status field updates (10-11) placed after content creation but before staging.

### Cross-Platform Correctness
- ✓ No macOS-specific or Arch-specific commands proposed for common package.
- ✓ Placeholder paths (`~/.gitconfig.common`, `~/.gitignore_global`) portable across both platforms.
- ✓ Architecture 0003 compatibility analysis (lines 269-289) is cited and respected.

### Pre-Implementation Assumptions
- ✓ All nine assumptions clearly stated (lines 18-29).
- ✓ Assumption 7 (`.gitignore` does not yet contain entries) validated by pre-impl check.
- ✓ Assumption 8 (`docs/stow-usage.md` exists) reasonable — established in foundation plan.

---

## Recommended Actions

1. **Before execution:** Builder runs all eight pre-implementation checks (lines 38-69). Every check must pass.

2. **Task sequencing:** Execute tasks in strict order. Do not skip task 1 (marker fix) — it resolves review 0006 finding.

3. **Privacy audit gate:** Task 12 must pass with zero grep findings before staging. If any finding appears, `git checkout` the file, fix, and re-run the audit.

4. **Reviewer final gate:** Before commit, Reviewer runs `git diff --staged` and `git show` to verify:
   - No signing keys or GPG config in `.gitconfig.example` or ADRs.
   - No credential helpers in common package.
   - No real identity values anywhere.
   - All `.example` files use approved placeholders only.

---

## Notes

### Alignment with Project Decisions
- **ADR-0003** (`.example` files): Correctly applied — users rename locally before stowing, never direct stow.
- **ADR-0006** (templates only): Fully enforced — no signing config, no identity hardcoding, placeholders throughout.
- **ADR-0013, 0014, 0015** (new): Will be created by this plan, properly justifying include-based strategy, filename choice, and deferred credential helpers.

### Task 1 Importance
Review 0006 identified three marker placement violations in architecture 0003. Task 1 fixes these before any other work. This prevents downstream confusion about whether the plan or the architecture has the correct format.

### Task 9 (Taskfile Checkpoint)
No changes to `Taskfile.yml` needed — `task dry-run AREA=common PACKAGE=git` already works. This checkpoint prevents accidental task addition.

### Task 8 Adoption Documentation
The six-step workflow in task 8 (lines 499-562) is comprehensive and matches the include-based strategy in ADRs 0013-0014. Each step is numbered, copy-pasteable, and includes validation sub-steps. The warning about what stays local (lines 564-572) is clear and enforceable.

### Marker Placement in Task 8
Line 531 correctly shows `⚠️  MANUAL STEP` immediately followed by code fence with no blank line. This matches the corrected format established in task 1.

### Privacy Audit Scope (Task 12)
Six grep vectors used:
1. Signing/GPG references in stow package files.
2. Real personal identity in package files.
3. Placeholder values confirmed present (positive check).
4. `.gitignore` correctly protects local copies.
5. ADRs checked for forbidden content.
6. Stow install commands gated by dry-run steps.

This is thorough and well-documented.

### Rollback Completeness
Full plan rollback sequence (lines 950-969) includes git reset, git checkout, and rm commands in correct order. No orphaned files would remain.

### Commit Message Alignment
The proposed commit message (lines 766-774) accurately summarizes the work: package creation, ADR additions, marker fixes, status updates. Message follows project convention: `feat(stow): <verb> <noun>`.

---

## Safety Checklist (Pre-Builder)

Builder must verify before starting:

- [ ] Current branch is not `main`.
- [ ] `git status` is clean (all changes understood).
- [ ] All eight pre-implementation checks pass.
- [ ] No `.gitconfig.common` or `.gitignore_global` entries already in `.gitignore`.
- [ ] No other agents have modified architecture 0003 since review 0006.
- [ ] `stow/common/git/` contains only `.gitconfig.example`.

