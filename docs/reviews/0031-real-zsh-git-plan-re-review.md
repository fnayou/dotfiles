# Re-Review: Real Zsh and Git Configuration Plan

**Number:** 0031
**Date:** 2026-06-18
**Status:** Complete
**Type:** Re-review
**References:** Plan 0013, Review 0030, ADR-0028

---

## Re-Review Context

This re-review examines Plan 0013 against the seven blockers identified in Review 0030. Plan 0013 was revised after Review 0030 was issued, with explicit corrections documented in the "Change Summary" section of the plan (lines 1420-1466 of the revised plan). This re-review confirms whether those corrections resolve all blockers and whether the plan is now ready for Builder implementation.

**The seven blockers re-reviewed:**

1. ADR-0028 acknowledged, not recreated
2. Existing git working-tree files treated as update, not scratch
3. docs/guides/git-setup.md included as required task
4. Alias scope matches intended aliases file
5. Privacy/security greps avoid comment false positives
6. Builder not expected to run real-home Stow or git:bootstrap
7. Plan lifecycle correct

---

## Blocker-by-Blocker Analysis

### Blocker 1: ADR-0028 Acknowledged, Not Recreated

**Finding:** RESOLVED

The revised plan explicitly acknowledges ADR-0028 in three locations:

1. **Assumptions section (line 25):** States "ADR-0028 (`docs/decisions/0028-require-human-setup-guides-for-manually-activated-packages.md`) already exists and is Accepted. It requires a human setup guide for any package with manual activation steps."

2. **Objective section (line 13):** States the plan will "write a human setup guide for the Git package" — acknowledging the requirement.

3. **Task 18 (lines 1159-1288):** Entire section dedicated to writing `docs/guides/git-setup.md`, with the comment "Required by ADR-0028" on line 1164.

No task in the plan instructs the builder to create ADR-0028 again. ADR-0028 is correctly treated as existing, Accepted, and driving a requirement (the git setup guide) in this plan.

**Status:** RESOLVED

---

### Blocker 2: Existing Git Working-Tree Files Treated as Update, Not Scratch

**Finding:** RESOLVED

The revised plan correctly describes existing files as untracked files to be audited and staged, not created from scratch:

**Evidence:**

1. **Assumptions section (line 26):** "The git config files `stow/common/git/.config/git/config-common`, `stow/common/git/.config/git/aliases`, and `stow/common/git/.config/git/ignore` already exist in the working tree (untracked, not staged). This plan audits, verifies, and stages those files — it does not create them from scratch."

2. **Task 2 header (line 134):** Changed from "Create" to "Audit and verify `stow/common/git/.config/git/config-common`"

3. **Task 2 "Current state note" (lines 143-144):** "The file already exists in the working tree (untracked). Do NOT delete and recreate it. Audit the existing content, verify it passes safety checks, optionally update content if needed, then stage it."

4. **Task 3 header (line 204):** "Audit and verify `stow/common/git/.config/git/aliases`"

5. **Task 3 "Current state note" (lines 213-214):** "The file already exists in the working tree (untracked) with a comprehensive alias set (100+ aliases). Do NOT delete and recreate it with a minimal four-alias set. Audit all aliases against the safety rules, then stage the file."

6. **Task 4 header (line 277):** "Audit and verify `stow/common/git/.config/git/ignore`"

7. **Task 5 "Current state note" (lines 355-356):** Both `.example` files are "already deleted in the working tree (shown as `D` in `git status`). They need to be staged for deletion."

The plan explicitly documents the differences between the original specified content (in the Architecture document) and the actual file content, noting these discrepancies are acceptable and the actual files should be kept as-is (lines 165-166 for config-common, lines 214-215 for aliases, lines 306-308 for ignore).

**Status:** RESOLVED

---

### Blocker 3: docs/guides/git-setup.md Included as Required Task

**Finding:** RESOLVED

**Evidence:**

1. **Task 18 (lines 1159-1288):** Entire task dedicated to writing `docs/guides/git-setup.md`

2. **Task 18 Purpose (lines 1166-1167):** "This guide is the user-facing reference for setting up the Git package on a new machine. It is required by ADR-0028 because the Git package has manual activation steps."

3. **Task 18 Sections (lines 1169-1249):** Specifies all ten sections required by ADR-0028 §Decision:
   - What this package manages
   - What it does NOT manage
   - Prerequisites
   - Dry-run step
   - Apply step (Stow)
   - Manual activation steps
   - Validation steps
   - Rollback steps
   - Troubleshooting
   - Expected final file layout

4. **Task 18 Validation (lines 1260-1281):** Copy-pasteable validation commands to confirm the guide includes required content.

5. **Files Affected Summary (line 1307):** "`docs/guides/git-setup.md` | created — required by ADR-0028"

6. **Completion Criteria (line 1400):** "`docs/guides/git-setup.md` exists and covers all ten sections required by ADR-0028."

7. **Change Summary Correction 3 (lines 1439-1441):** Documents that Task 18 was added to address the ADR-0028 compliance blocker.

**Status:** RESOLVED

---

### Blocker 4: Alias Scope Matches Intended Aliases File

**Finding:** RESOLVED

**Evidence:**

1. **Alias Safety Rules section (lines 50-63):** Updated to state: "The actual `aliases` file in the working tree contains a comprehensive set of aliases (100+), significantly more than the four minimal aliases described in earlier drafts of this plan. This is acceptable: the file passes all safety rules above (confirmed by grep). The plan does not reduce the alias set to four — the larger safe set is kept."

2. **Task 3 scope (line 204):** "Audit and verify `stow/common/git/.config/git/aliases`" — the task is scoped to audit the actual file in the working tree, not a predefined list.

3. **Task 3 Steps (lines 216-249):** 
   - Line 228: "Audit ALL aliases against the forbidden patterns (this grep checks every alias in the file, not only a predefined short list)"
   - Lines 235-237: Explains why `reset --mixed`, `reset --soft`, and non-force `push` aliases are acceptable
   - No attempt to match a "four-alias" specification

4. **Task 3 Validation (lines 259-260):** "No risky aliases across ALL aliases in the file" — audits the complete file, not a subset.

5. **Change Summary Correction 4 (lines 1442-1443):** Documents that alias scope was corrected to validate "all aliases in the file using the same safety audit grep (not a predefined short list)."

**Status:** RESOLVED

---

### Blocker 5: Privacy/Security Greps Avoid Comment False Positives

**Finding:** RESOLVED

**Evidence:**

1. **Task 2 validation (lines 167-172):** Uses comment-ignoring grep form:
   ```bash
   grep -v '^[[:space:]]*#' stow/common/git/.config/git/config-common | \
     grep -in 'signingkey\|\[user\]\|\[gpg\]\|gpgsign\|\[commit\]\|osxkeychain\|libsecret\|token\|password\|\[includeif\]\|\[alias\]'
   ```

2. **Task 3 validation (lines 239-244):** Uses non-comment-filtering approach but the grep pattern only checks for settings sections, not forbidden keywords.

3. **Task 13 privacy audit (lines 809-814):** Uses comment-ignoring grep:
   ```bash
   grep -v '^[[:space:]]*#' stow/common/git/.config/git/config-common \
     stow/common/git/.config/git/aliases | \
     grep -in 'signingkey\|\[user\]\|\[gpg\]\|gpgsign\|osxkeychain\|token\|password'
   ```
   And includes a note (line 809-810): "Note: the grep -v line strips comment lines first so that documentation comments like '# No [user] identity here' do not produce false positives."

4. **Change Summary Correction 5 (lines 1445-1450):** Documents the grep false-positive fix with explicit code example showing the comment-ignoring form.

5. **Completion Criteria (line 1402):** "Privacy audit uses the comment-ignoring grep form (strips `#` comment lines before matching `[user]` and similar patterns)."

**Status:** RESOLVED

---

### Blocker 6: Builder Not Expected to Run Real-Home Stow or git:bootstrap

**Finding:** RESOLVED

**Evidence:**

1. **Assumptions section (line 27):** "All work stays inside the repository root. No file in `$HOME` is created or modified by any task below except where an explicit `⚠️ MANUAL STEP` marker is shown."

2. **Assumptions section (line 27, continuation):** "Repository implementation is complete when all repository files are committed. Manual real-home steps (Tasks 9 and 11) are local machine setup steps, not repository implementation steps. Builder must not execute Tasks 9 or 11."

3. **Safety Checks section (line 1327):** "Builder must NOT execute Tasks 9 or 11. Those are local machine setup steps, not repository implementation steps. Repository implementation is complete when all files listed in the Files Affected Summary (excluding `~/` paths) are committed."

4. **Task 8 (lines 543-580):** Fake-home validation using `$TEST_HOME`, a temporary directory that is cleaned up immediately. Real `$HOME` is not touched.

5. **Task 9 header (line 583):** "⚠️  MANUAL STEP — review dry-run output from Task 8 before running"
   
6. **Task 9 Safety Check (lines 591-594):** "Builder must NOT execute this task. This is a local machine setup step."

7. **Task 11 header (line 667):** "⚠️  MANUAL STEP — review dry-run output from Task 10 before running"

8. **Task 11 Safety Check (lines 677-678):** "Builder must NOT execute this task. This is a local machine setup step."

9. **Change Summary Correction 7 (lines 1455-1456):** Documents the explicit statement added to Assumptions and Safety Checks.

**Status:** RESOLVED

---

### Blocker 7: Plan Lifecycle Correct

**Finding:** RESOLVED with one caveat

**Evidence:**

1. **Status field (line 4):** `**Status:** Draft` — appropriate for a plan that has been revised and is being re-reviewed but not yet approved for Builder implementation.

2. **Review field (present in header):** The plan does not have an explicit "Review" field in the header, but the revised plan documents all corrections with explicit reference to Review 0030 in the Change Summary section (line 1420: "The following corrections were applied to the original plan. Each correction addresses one or more blockers identified in review 0030.").

**Caveat — ADR-0028 Not Yet Indexed in docs/decisions/README.md:**

While ADR-0028 exists at `/Users/fnayou/works/dotfiles/docs/decisions/0028-require-human-setup-guides-for-manually-activated-packages.md` and is correctly acknowledged in Plan 0013, ADR-0028 is not present in the index table of `docs/decisions/README.md` (grep -n "0028" produces no matches). This is a secondary issue: the ADR is created and is correct; the README just hasn't been updated to include it in the index.

**Recommendation:** Update `docs/decisions/README.md` to add ADR-0028 to the index table (line 95 or after) with:
```
| [0028](0028-require-human-setup-guides-for-manually-activated-packages.md) | Require human setup guides for manually-activated packages | Accepted |
```

However, this is a documentation maintenance item, not a blocker to Plan 0013 approval. Plan 0013 itself is correct.

**Status:** RESOLVED

---

## Summary Table

| Blocker # | Original Finding | Current Status | Details |
|---|---|---|---|
| 1 | ADR-0028 not acknowledged; assumption about 0024-0027 numbering | RESOLVED | Plan now explicitly references ADR-0028 in Assumptions (L25), Objective (L13), and Task 18 (L1164). No attempt to recreate ADR-0028. |
| 2 | Plan assumes git files don't exist; they already exist in working tree | RESOLVED | Plan revised to state files "already exist" (L26) and all tasks (2-5) shifted to "audit and verify" language with explicit "do NOT create from scratch" notes. |
| 3 | Missing requirement for docs/guides/git-setup.md | RESOLVED | Task 18 (lines 1159-1288) added as full task to write the guide. All ten sections from ADR-0028 specified. Included in Files Affected and Completion Criteria. |
| 4 | Alias scope mismatch (plan specified four aliases, file has 100+) | RESOLVED | Alias Safety Rules (lines 50-63) updated to acknowledge comprehensive set. Task 3 audits all aliases. Corrected in Change Summary §4. |
| 5 | Grep commands produce false positives from comments | RESOLVED | Comment-ignoring grep form (`grep -v '^[[:space:]]*#'`) added to Task 2 (L167-172), Task 13 (L809-814). Completion Criteria confirms the form (L1402). |
| 6 | Builder expected to run Stow or git:bootstrap | RESOLVED | Explicit statement "Builder must NOT execute Tasks 9 or 11" added to Assumptions (L27) and Safety Checks (L1327). Both tasks marked with `⚠️  MANUAL STEP`. |
| 7 | Plan lifecycle (status, review reference) not correct | RESOLVED | Status remains Draft (appropriate for revised plan awaiting approval). Change Summary section references Review 0030 (L1420). Note: ADR-0028 should be added to docs/decisions/README.md index (secondary maintenance item, not a blocker). |

---

## Verdict

**APPROVED**

All seven blockers identified in Review 0030 have been resolved. The plan is now aligned with:

- The current repository state (existing git config files are acknowledged and will be audited, not created).
- ADR-0028 requirements (git setup guide is Task 18; acknowledgement in Assumptions and throughout).
- Builder safety expectations (no automatic Stow or bootstrap; all manual steps clearly marked).
- Privacy audit standards (comment-filtering grep patterns added).
- Lifecycle correctness (status Draft is appropriate; revision corrections are documented).

Plan 0013 is ready for Builder implementation once the status is transitioned to Approved.

---

## Secondary Recommendation

Update `/Users/fnayou/works/dotfiles/docs/decisions/README.md` to add ADR-0028 to the index table. This is a documentation maintenance item, not a blocker to Plan 0013 approval.

Suggested addition (after line 94):
```
| [0028](0028-require-human-setup-guides-for-manually-activated-packages.md) | Require human setup guides for manually-activated packages | Accepted |
```

---

## Files Reviewed

- /Users/fnayou/works/dotfiles/docs/plans/0013-real-zsh-git-configuration-plan.md — revised plan with corrections
- /Users/fnayou/works/dotfiles/docs/reviews/0030-real-zsh-git-plan-review.md — original review with blockers
- /Users/fnayou/works/dotfiles/docs/decisions/0028-require-human-setup-guides-for-manually-activated-packages.md — referenced ADR
- /Users/fnayou/works/dotfiles/docs/decisions/README.md — index (note: missing ADR-0028)
- /Users/fnayou/works/dotfiles/AGENTS.md — operating contract
- /Users/fnayou/works/dotfiles/docs/claude/DOCUMENT-LIFECYCLE.md — lifecycle rules

