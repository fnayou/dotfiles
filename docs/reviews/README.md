# Reviews

This directory stores review reports for this dotfiles repository.

## Purpose

Review reports document the **findings, verdicts, and recommendations** produced by the Reviewer agent after each significant change.

A review report must include:

- **Summary** — what was reviewed.
- **Blocking issues** — issues that must be resolved before commit.
- **Non-blocking suggestions** — optional improvements.
- **Safety verdict** — PASS or FAIL with reason.
- **Privacy verdict** — PASS or FAIL with reason.
- **Documentation verdict** — PASS or FAIL with reason.
- **Recommended next action** — what to do after the review.

## Naming convention

Use numbered filenames in sequence:

```
0001-claude-operating-layer-review.md
0002-zsh-package-review.md
0003-nvim-package-review.md
```

## Workflow

1. Builder completes implementation and reports changes.
2. Use the Reviewer agent or `review-change` skill to produce a review report.
3. All three verdicts must be PASS before committing.
4. If FAIL: Builder fixes blocking issues, then re-review.

## Verdicts

- **PASS** — no issues found in this category.
- **FAIL** — at least one blocking issue. Must be resolved before commit.

**All three verdicts (safety, privacy, documentation) must be PASS before any commit.**
