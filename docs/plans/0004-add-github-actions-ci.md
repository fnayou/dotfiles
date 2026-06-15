# Plan: Add Minimal GitHub Actions CI

**Number:** 0004
**Status:** Approved
**Date:** 2026-06-15
**PRD:** docs/prd/0001-claude-operating-layer.md
**Architecture:** docs/architecture/0001-dotfiles-repository-architecture.md

## Objective

Add a minimal, safe GitHub Actions CI workflow that validates repository hygiene — structure checks, shell syntax, and secret-pattern scanning — without running Stow, modifying $HOME, using secrets, or deploying anything.

## Assumptions

- `.github/workflows/` directory does not exist yet.
- Repository has no secrets configured in GitHub.
- CI must be non-destructive and require zero privileged access.
- ADR numbers 0001–0007 are taken; this decision uses 0008.

## Ordered Tasks

1. Create `.github/workflows/ci.yml` — triggers on push and pull_request; checks out repo; verifies expected files and directories exist; runs bash syntax check on any `.sh` files found; scans for obvious secret patterns.
2. Create `docs/decisions/0008-minimal-github-actions-ci.md` — ADR recording the decision to use GitHub Actions for hygiene-only CI.
3. Modify `README.md` — add a short "CI" section after the Basic commands section describing what the workflow does and does not do.

## Files Affected

- `.github/workflows/ci.yml` — created
- `docs/decisions/0008-minimal-github-actions-ci.md` — created
- `README.md` — modified

## Safety Checks

- Verify `ci.yml` does not run `stow`, `rm`, `mv`, or `ln -s`.
- Verify `ci.yml` does not use `secrets.*` or require privileged access.
- Verify `ci.yml` does not deploy, publish, or modify $HOME.
- Verify secret-pattern scan excludes `.github/` itself to avoid false positives on the pattern strings in the workflow.
- Verify `README.md` update adds no sensitive data.
- Verify ADR contains no sensitive data.

## Validation Commands

```bash
ls -la .github/workflows/ci.yml
ls docs/decisions/0008-minimal-github-actions-ci.md
git diff README.md
git status
git diff --staged
```

## Rollback Strategy

All changes are new or modified files within the repository. No $HOME changes.

```bash
git checkout -- README.md
git clean -n                        # dry run
git clean -f .github/
git clean -f docs/decisions/0008-minimal-github-actions-ci.md
```

⚠️  MANUAL STEP — run `git clean -n` first and review before `git clean -f`.

## Completion Criteria

- [ ] `.github/workflows/ci.yml` exists and is valid YAML.
- [ ] Workflow triggers on push and pull_request.
- [ ] Workflow runs on ubuntu-latest.
- [ ] Workflow checks out the repository.
- [ ] Workflow verifies presence of expected files and directories.
- [ ] Workflow runs `bash -n` on any `.sh` files found (skips if none exist).
- [ ] Workflow scans for secret patterns and fails if found.
- [ ] Workflow does not use `secrets.*`, does not run Stow, does not modify $HOME.
- [ ] `docs/decisions/0008-minimal-github-actions-ci.md` exists with status Accepted.
- [ ] `README.md` has a CI section describing hygiene-only behavior.
- [ ] `git status` shows only the three expected files changed.
- [ ] No home directory was modified.
- [ ] Reviewer approves before commit.
