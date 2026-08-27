# Plan: Implement Codex Customization Package

**Number:** 0028
**Status:** Complete
**Date:** 2026-08-27
**PRD:** 0025 — Codex Customization Package
**Architecture:** 0023 — Codex Customization Package

## Objective

Add a safe `codex` Stow package that tracks portable Codex CLI customization, document the current
status line feasibility for `rtk` and caveman savings, and correct known documentation drift.

## Assumptions

- Codex `0.149.1` is the local implementation inspected.
- The package is added to the repository but is not stowed during this implementation.
- `[projects]` trust entries in the live config are local state and must not be committed.

## Ordered Tasks

1. Create `stow/common/codex/.codex/config.toml` from the portable parts of the live config.
2. Create `stow/common/codex/README.md` with scope, exclusions, manual dry-run/stow commands, and
   `rtk`/caveman feasibility notes.
3. Update root/package docs to list `codex` and to state that it is added but not stowed.
4. Correct documentation drift in plan status documentation and Stow platform guidance.
5. Add ADR 0067 for the Codex config boundary and status line savings deferral.
6. Validate with read-only commands and write an implementation review.

## Files Affected

- `stow/common/codex/.codex/config.toml` — created
- `stow/common/codex/README.md` — created
- `README.md` — modified
- `AGENTS.md` — modified
- `CLAUDE.md` — modified
- `Taskfile.yml` — modified
- `docs/stow-usage.md` — modified
- `docs/plans/README.md` — modified
- `docs/decisions/0067-codex-config-boundary-and-statusline-savings.md` — created
- `docs/decisions/README.md` — modified
- `docs/prd/0025-codex-customization.md` — created
- `docs/architecture/0023-codex-customization-architecture.md` — created
- `docs/plans/0028-implement-codex-customization.md` — created
- `docs/reviews/0075-codex-customization-implementation-review.md` — created

## Safety Checks

- No command modifies `$HOME`.
- No `stow` command is run.
- No `~/.codex/auth.json`, SQLite database, cache, plugin, transcript, or project trust path is
  copied into the package.
- Documented install commands use `--no-folding` and dry-run first.

## Validation Commands

```bash
git status --short
grep -rnE "auth.json|BEGIN.*PRIVATE|password|token|api[_-]?key|secret|\\.sqlite|models_cache|version\\.json|projects" stow/common/codex/.codex
grep -rn "/Users/fnayou" stow/common/codex
mkdir -p /private/tmp/codex-dotfiles-validate
cp stow/common/codex/.codex/config.toml /private/tmp/codex-dotfiles-validate/config.toml
env CODEX_HOME=/private/tmp/codex-dotfiles-validate codex doctor --json
task check:decisions
```

The `codex doctor` command is expected to fail in the temporary home because it has no credentials
and the network may be unavailable. The relevant result is that `config.load` reports the managed
config as loaded and parsed.

## Rollback Strategy

Nothing is stowed and nothing outside the repository is touched. Rollback is a normal Git revert of
the branch or the listed files.

## Completion Criteria

- [x] Codex package exists and contains only portable config.
- [x] `.stow-local-ignore` keeps package documentation out of `$HOME`.
- [x] README documents scope, manual install, and local project trust preservation.
- [x] `rtk` and caveman status line feasibility is documented.
- [x] Documentation drift corrections are made.
- [x] Review report passes safety, privacy, and documentation checks.
