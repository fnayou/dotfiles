# Decision: Minimal GitHub Actions for Repository Hygiene

**Number:** 0008
**Date:** 2026-06-15
**Status:** Accepted

## Context

The repository follows a PRD-first, review-before-commit workflow. Before the first commit, a question arose: should CI be added, and if so, what scope?

The repository is a private dotfiles repository with no application code to build or test. However, CI can still provide value as a non-destructive hygiene check — verifying structure, shell script syntax, and absence of obvious secrets.

## Decision

Add a minimal GitHub Actions workflow (`.github/workflows/ci.yml`) that performs hygiene-only checks:

- Verify required files and directories exist.
- Verify Markdown files are present.
- Run `bash -n` syntax check on any shell scripts found (skips if none exist).
- Scan for obvious secret patterns and fail if found.

Constraints that must always hold for this workflow:

- Must not run GNU Stow.
- Must not create symlinks or modify `$HOME`.
- Must not use `secrets.*` or require privileged access.
- Must not deploy, publish, or send data anywhere.
- Must not install system packages beyond what `ubuntu-latest` provides.
- Must not require Docker.
- Must remain safe to run on every push without side effects.

## Consequences

- Every push and pull request triggers a fast, non-destructive hygiene check.
- Secret pattern scanning provides an automated safety net against accidental credential commits.
- Shell scripts added in future will be syntax-checked automatically.
- The workflow is intentionally minimal — it will grow only as the repository grows.
- CI scope must be reviewed before adding any step that runs Stow, modifies $HOME, or uses secrets.
