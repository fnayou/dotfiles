# Review: OS Maintenance Helper — PRD 0018 + Architecture 0018

**Number:** 0049
**Status:** Complete
**Date:** 2026-06-24
**Reviews:** `docs/prd/0018-os-maintenance.md` (Approved), `docs/architecture/0018-os-maintenance-architecture.md` (Draft)

## Summary

Reviewed PRD 0018 and Architecture 0018 for the OS maintenance helper against the Core
Principles (§3), Safety (§8), Privacy (§9), Cross-Platform (§10), and Documentation (§12) rules.
The design proposes one OS-detecting `scripts/os-maintenance.sh` with `update` and `clean`
(dry-run default, `--apply` to delete), surfaced via `task`, with `pacdiff`/mirrorlist kept as a
manual runbook. The proposal is coherent, fits existing repo patterns, and honours the
no-destructive-automation posture.

## Blocking Issues

None.

## Non-Blocking Suggestions

1. **`clean --apply` should re-print the report immediately before deleting.** Architecture
   Decision 2 gives dry-run then `--apply` as separate invocations; between them state can drift.
   Suggest `--apply` run the same report first, then act — cheap belt-and-braces. Resolves the
   architecture's own Open Question without a `y/N` prompt.
2. **`Taskfile.yml` destructive target naming.** Keep the deleting path visibly distinct
   (`clean:apply`) from the safe `clean`; do not let `task clean` ever delete. (Architecture
   already intends this — call it out explicitly in the plan's validation.)
3. **PRD/Architecture consistency on zsh integration.** PRD acceptance lists a guarded zsh
   wrapper; Architecture Decision 4 defers it (task-only) pending a `$DOTFILES` anchor. Consistent
   because the PRD phrases it as conditional ("Any zsh integration…"), but the plan should state
   the wrapper is explicitly deferred so the deferral is intentional, not an omission.
4. **Runbook safety markers.** The `docs/guides/os-maintenance.md` `pacdiff`/`reflector` steps
   must carry the `⚠️ MANUAL STEP` marker on the line directly preceding each fenced block
   (Documentation rule). Verify at build/review time.

## Safety Verdict

PASS — `clean` is non-destructive by default; deletion is opt-in and report-preceded.
`pacdiff`/mirrorlist excluded from automation (Decision 5). No `$HOME`, stow, symlink, `rm`/`mv`
against `$HOME`. Privileged commands are explicit and interactive. `set -euo pipefail` retained.

## Privacy Verdict

PASS — no secrets, tokens, or machine-specific absolute paths introduced; the deferred zsh
wrapper is what would have needed a hardcoded path, and it is correctly deferred. Scripts will be
secret-scanned by CI.

## Cross-Platform Verdict

PASS — single file, but per-OS logic separated into `arch_*`/`macos_*` functions behind the §10
detection pattern; no package-manager command leaks across OSes; macOS path guarded by
`command -v brew` and flagged as needing a manual smoke-test.

## Documentation Verdict

PASS (conditional on Suggestion 4 at build time) — PRD and Architecture follow house format and
numbering; runbook planned with manual-step markers. Decisions captured in ADRs 0050/0051.

## Recommended Next Action

User: confirm Architecture 0018 → **Approved** (PRD already Approved). Then Planner produces
`docs/plans/0021-implement-os-maintenance.md` incorporating Suggestions 1–4. Build must not run
the destructive paths.
