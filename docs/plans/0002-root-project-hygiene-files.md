# Plan: Root Project Hygiene Files

**Number:** 0002
**Status:** Approved
**Date:** 2026-06-15
**PRD:** none — direct user requirement
**Architecture:** docs/architecture/0001-dotfiles-repository-architecture.md

## Objective

Add four root-level project hygiene files (`.editorconfig`, `.gitignore`, `README.md`, `LICENSE`) without touching dotfiles, Stow packages, or the home directory.

## Assumptions

- Repository root contains no `.editorconfig`, `.gitignore`, or `LICENSE` yet.
- `README.md` exists but is minimal — it will be replaced with a fuller version.
- No Stow packages, no `$HOME` modifications, no symlinks are part of this plan.
- Builder does not run `stow`, `rm`, `mv`, or `ln -s` against `$HOME`.

## Ordered Tasks

1. Create `.editorconfig` at repository root with UTF-8, LF, final newline, trim trailing whitespace, 2-space indent globally, trailing whitespace disabled for Markdown.
2. Create `.gitignore` at repository root covering OS files, editor files, local Claude overrides, environment/secrets, temp files, logs, and local machine files — without ignoring `.claude/`, `docs/`, or `.editorconfig`.
3. Replace `README.md` at repository root with a detailed version covering project purpose, current status, safety rules, operating model, and planned future direction.
4. Create `LICENSE` at repository root with an all-rights-reserved personal notice.

## Files Affected

- `.editorconfig` — created
- `.gitignore` — created
- `README.md` — modified (existing minimal version replaced)
- `LICENSE` — created

## Safety Checks

- Verify `.gitignore` does not include `.claude/` — agents, rules, and skills must be committed.
- Verify `.gitignore` does not include `docs/` — documentation must be committed.
- Verify `.gitignore` does not include `.editorconfig`.
- Verify `README.md` contains no real credentials, hostnames, or identity data.
- Verify `LICENSE` contains no personal identifying information beyond what the user specified.
- Verify no file is created outside the repository root.
- Verify no `stow`, `rm`, `mv`, or `ln -s` command is run.

## Validation Commands

```bash
# Verify all four files exist
ls -la .editorconfig .gitignore README.md LICENSE

# Verify .gitignore does not accidentally ignore .claude/ or docs/
grep -E '(\.claude|docs/)' .gitignore && echo "PROBLEM: .claude or docs/ is ignored" || echo "OK: .claude and docs/ not ignored"

# Verify no secrets in any created file
git diff --staged

# Verify overall repository state
git status
```

## Rollback Strategy

All changes are new or modified files within the repository. No home directory changes — no $HOME rollback needed.

```bash
# Undo a specific file
git checkout -- README.md

# Remove newly created files (if not yet committed)
git clean -n          # dry run — review first
git clean -f          # remove untracked files only
```

⚠️  MANUAL STEP — run `git clean -n` first and review output before `git clean -f`.

## Completion Criteria

- [ ] `.editorconfig` exists with root = true, UTF-8, LF, final newline, 2-space indent.
- [ ] `.gitignore` exists and covers all specified patterns.
- [ ] `.gitignore` does not ignore `.claude/`, `docs/`, or `.editorconfig`.
- [ ] `README.md` exists with project purpose, status, safety rules, and planned direction.
- [ ] `LICENSE` exists with the all-rights-reserved personal notice.
- [ ] `git status` shows only the four expected files changed.
- [ ] No home directory was modified.
- [ ] Reviewer approves before commit.
