# Skill: review-change

Produces a numbered review report under `docs/reviews/`.

## When to use

- Builder has completed a set of changes.
- User wants validation before committing.
- Any significant change to the repository that touches dotfiles, scripts, or config.

## Process

### Step 1 — Inspect changed files

Run:

```bash
git status
git diff
git diff --staged
```

List every file that was created or modified.

### Step 2 — Check safety

For each file, verify:

- [ ] No `stow --adopt` command present as automated behavior.
- [ ] No `rm` targeting `$HOME` or paths outside the repository.
- [ ] No `mv` targeting `$HOME` or paths outside the repository.
- [ ] No `ln -s` creating symlinks in `$HOME` without clear manual-step markers.
- [ ] No modification of files outside the repository root.
- [ ] Risky commands are shown with `⚠️  MANUAL STEP` markers, not executed automatically.

### Step 3 — Check privacy

For each file, verify:

- [ ] No API keys, tokens, or access credentials.
- [ ] No passwords or passphrases.
- [ ] No SSH private key content.
- [ ] No private hostnames or internal IP addresses.
- [ ] No work-specific secrets or environment variables.
- [ ] All examples use placeholder values (`YOUR_API_KEY`, `your-token-here`).

### Step 4 — Check documentation

For each documentation file, verify:

- [ ] Commands are copy-pasteable and correct.
- [ ] Dangerous commands have `⚠️  MANUAL STEP` markers.
- [ ] Platform-specific commands clearly specify the target OS.
- [ ] PRD, architecture, and plan references are accurate.

### Step 5 — Check macOS / Arch separation

Verify:

- [ ] macOS-specific content is not placed in Arch directories or docs.
- [ ] Arch-specific content is not placed in macOS directories or docs.
- [ ] Common packages genuinely work on both platforms.
- [ ] Platform detection is used in any multi-platform scripts.

### Step 6 — Produce findings

Categorize each finding as:

- **Blocking** — must be fixed before commit.
- **Non-blocking** — improvement, does not block commit.

### Step 7 — Produce verdicts

Issue explicit verdicts:

- **Safety**: PASS or FAIL
- **Privacy**: PASS or FAIL
- **Documentation**: PASS or FAIL

All three must be PASS before recommending commit.

### Step 7a — Mark the Plan Complete (implementation reviews only)

If this is an **implementation review** (reviewing Builder output) and all three verdicts are PASS:

1. Open the plan file referenced in the review (under `docs/plans/`).
2. Change `**Status:** Approved` to `**Status:** Complete`.
3. Record the plan number and title in the Summary of the review report.

If any verdict is FAIL, leave the plan status as Approved.

See `docs/claude/DOCUMENT-LIFECYCLE.md` for the full lifecycle rules.

### Step 8 — Produce the review report

Write the report to a numbered file:

```
docs/reviews/0001-claude-operating-layer-review.md
docs/reviews/0002-zsh-package-review.md
```

Use the next available number in the sequence.

## Review report template

```markdown
# Review: [Title]

**Number:** 0001
**Status:** Complete
**Date:** YYYY-MM-DD
**Plan reviewed:** [number] — [title]
**Files reviewed:** [list]

## Summary

[What was reviewed — name the Plan completed, e.g. "Plan 0007 — Implement Zsh Configuration Foundation"]

## Blocking Issues

- [issue — file:line if applicable]

## Non-Blocking Suggestions

- [suggestion]

## Safety Verdict

PASS / FAIL — [reason]

## Privacy Verdict

PASS / FAIL — [reason]

## Documentation Verdict

PASS / FAIL — [reason]

## Recommended Next Action

[Fix blocking issues and re-review / Approve and commit]
```
