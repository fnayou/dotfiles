# Review: OS Maintenance Helper — Implementation (Plan 0021)

**Number:** 0051
**Status:** Complete
**Date:** 2026-06-24
**Reviews:** implementation of `docs/plans/0021-implement-os-maintenance.md` (Approved)

## Summary

Reviewed the build of Plan 0021: `scripts/os-maintenance.sh` (OS-detected `update` / `clean`
with dry-run default and report-first `--apply`), three new `Taskfile.yml` targets (`update`,
`clean`, `clean:apply`), the `docs/guides/os-maintenance.md` runbook, and ADRs 0050 / 0051.
Read-only validation passed: `bash -n` clean; no-arg and bogus-command exit non-zero with usage;
`clean` dry-run produced a report and deleted nothing (orphans 0→0, cache 3.3G→3.3G unchanged);
`task --list` shows all three targets; the script contains no `pacdiff`/`mirrorlist` command
(only documentation comments). The build matches the plan and folds in Review 0049/0050
suggestions (report-first apply, `paccache` guarded, `yay` un-sudoed, manual-step markers).

## Blocking Issues

1. **Mutating Taskfile tasks conflict with ADR-0009 / ADR-0019 without an explicit lift.**
   ADR-0009 establishes the Taskfile holds only read-only / `--simulate` tasks, and ADR-0019
   restates that a mutating task requires *a separate PRD that explicitly lifts the restriction
   and a separate ADR*. The mutating bootstrap tasks set the precedent of lifting it per feature
   (ADR-0032 for `git:bootstrap`, ADR-0043 for `zsh:bootstrap`). The new `update` and
   `clean:apply` tasks **execute** privileged, destructive commands (`sudo pacman -Syu`,
   `sudo pacman -Rns`, `paccache -r`, `journalctl --vacuum`, `brew cleanup`) — clearly mutating —
   but Plan 0021 scheduled only ADRs 0050/0051 and did not lift the ban. This must be resolved
   before commit.

   **Resolution options:**
   - (a) Add **ADR 0052** explicitly lifting the ADR-0009 mutation ban for the os-maintenance
     tasks (following the 0032/0043 precedent), mark the tasks `MANUAL USE ONLY` like the
     bootstrap tasks (`clean:apply` already says this; add it to `update`), and add one sentence
     to PRD 0018 recording the lift. Recommended — keeps the executing helper, consistent with
     existing mutating-task precedent.
   - (b) Make `update` / `clean:apply` **print** their commands (like `deps:arch` / `deps:brew`)
     instead of executing, keeping the Taskfile fully non-mutating. More conservative but removes
     the feature's main convenience.

## Non-Blocking Suggestions

1. `update` task description/echo could also carry `MANUAL USE ONLY` for symmetry with the
   bootstrap tasks, regardless of which resolution is chosen.
2. Consider a short comment in `Taskfile.yml` above the maintenance block pointing at ADR 0052
   (once it exists) so the mutation-lift is discoverable from the Taskfile.

## Safety Verdict

PASS (script) — `clean` is non-destructive by default and empirically deleted nothing; `--apply`
re-prints the report first; `paccache` guarded; `yay` never sudo'd; `pacdiff`/mirrorlist excluded
and documented as manual. No `$HOME`/stow/symlink/`rm`/`mv`. `set -euo pipefail` with safe
`|| true` around non-zero-but-expected reads.
CONDITIONAL (process) — see Blocking Issue 1: the mutation-ban lift must be documented before
these mutating tasks are committed.

## Privacy Verdict

PASS — no secrets, tokens, or machine-specific absolute paths in any new file. Zsh wrapper (the
only thing needing a hardcoded path) correctly deferred (ADR 0051).

## Cross-Platform Verdict

PASS — Arch and macOS logic separated into `arch_*` / `macos_*` functions behind OS detection;
no package-manager command crosses OSes; macOS path guarded by `command -v brew`. macOS path is
unexercised on this host and must be smoke-tested on macOS before relying on it (documented risk).

## Documentation Verdict

PASS — runbook present with `⚠️  MANUAL STEP` markers preceding every dangerous block, the
mirrorlist/pacdiff manual procedure, and the deferred-wrapper note; ADRs 0050/0051 in house
format. (Will need the PRD note + ADR 0052 from Blocking Issue 1.)

## Recommended Next Action

User decides Blocking Issue 1 (option a or b). On (a): I add ADR 0052, the `update`
`MANUAL USE ONLY` marker, and the one-line PRD 0018 note, then this plan can be marked Complete
and the change staged for the user-approved commit. No commit until the blocking issue is
resolved.

## Resolution (2026-06-24)

User chose option (a). Applied: ADR-0052 added (lifts the ADR-0009 mutation ban for the two
os-maintenance tasks), `update` task marked `MANUAL USE ONLY` (matching `clean:apply`), Taskfile
comment pointing at ADR-0052, and PRD 0018 amended to record the lift. Blocking Issue 1 closed;
Plan 0021 marked Complete.
