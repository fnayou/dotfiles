# Decision: GitHub Community Standards Files

**Number:** 0083
**Date:** 2026-10-23
**Status:** Accepted

## Context

The GitHub community profile (Insights, Community Standards) scored the repository at 42%. Only
the README and the license were detected. The code of conduct, contributing guide, issue
templates and pull request template were missing, as was a security policy.

## Decision

Add the standard files, each written from the repository's own rules instead of generic text:

- `CODE_OF_CONDUCT.md` — Contributor Covenant 2.1, reports routed through the maintainer's GitHub
  profile, so no email address is committed.
- `CONTRIBUTING.md` — points to `AGENTS.md` and `.claude/rules/`, states the Conventional Commits,
  Stow dry-run, privacy and status-sync rules, and the checks to run.
- `SECURITY.md` — private reporting through GitHub private vulnerability reporting.
- `.github/pull_request_template.md` — the privacy, Stow and status-sync checklists.
- `.github/ISSUE_TEMPLATE/` — bug report and feature request, with blank issues disabled and a
  link that sends security reports to the private advisory form.

## Consequences

- The community profile can reach 100% once GitHub detects the files.
- Private vulnerability reporting must be enabled in the repository settings for `SECURITY.md`
  and the issue chooser link to work.
- The pull request checklist duplicates rules from `.claude/rules/`. A rule change should update
  the template in the same commit.
