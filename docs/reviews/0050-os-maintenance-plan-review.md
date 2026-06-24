# Review: OS Maintenance Helper — Plan 0021

**Number:** 0050
**Status:** Complete
**Date:** 2026-06-24
**Reviews:** `docs/plans/0021-implement-os-maintenance.md` (Draft)

## Summary

Reviewed implementation Plan 0021 against PRD 0018, Architecture 0018, Review 0049, and the
Safety (§8), Privacy (§9), Cross-Platform (§10), and Documentation (§12) rules. The plan
sequences eight build tasks (script skeleton → Arch update/clean → macOS update/clean → Taskfile
→ runbook → ADRs → stage) with explicit Safety Checks, read-only Validation Commands, a Rollback
Strategy, and Completion Criteria. It correctly folds in all four non-blocking suggestions from
Review 0049.

## Blocking Issues

None.

## Non-Blocking Suggestions

1. **Validation should assert no deletion empirically, not just by reading code.** The plan
   already pairs `clean` dry-run with before/after `pacman -Qtdq | wc -l` and cache `du -sh`;
   keep that as a hard gate in the implementation review, not just a suggested check.
2. **`paccache` availability.** `paccache` ships with `pacman-contrib`, which may be absent. The
   build should guard the Arch `clean` path with `command -v paccache` and degrade gracefully
   (report that it is unavailable) rather than erroring under `set -euo pipefail`.
3. **`yay` vs `sudo pacman` interactivity.** `yay -Syu` must not be run as root; `pacman -Syu`
   needs `sudo`. Plan Task 2 already branches on `command -v yay`; the build must keep `yay`
   un-sudoed and only `sudo` the `pacman` fallback.

## Safety Verdict

PASS — Safety Checks explicitly forbid running any destructive command during the build; the only
build actions are file creation and an additive Taskfile edit. `clean` dry-run default and the
`pacdiff`/mirrorlist exclusion are carried through. Rollback is `git restore`/branch delete;
nothing outside the repo is touched.

## Privacy Verdict

PASS — no secrets or machine-specific absolute paths introduced; zsh wrapper (the only thing that
would need a hardcoded path) stays deferred. CI secret-scan will cover the new script.

## Cross-Platform Verdict

PASS — Tasks 2–4 keep Arch and macOS logic in separate `arch_*`/`macos_*` functions behind OS
detection; no package-manager command crosses OSes; macOS path guarded by `command -v brew`.

## Documentation Verdict

PASS — runbook task (6) requires `⚠️  MANUAL STEP` markers and the deferred-wrapper note; ADRs
0050/0051 scheduled (decisions namespace, distinct from this review's number). Numbering and
house format consistent.

## Recommended Next Action

User: confirm Plan 0021 → **Approved** (the Draft → Approved transition is the user's). On
approval, Builder implements Tasks 1–7 only, runs the read-only Validation Commands, and stops at
"Next Steps" without changing the plan status or committing. Builder must honour Suggestions 2–3
(guard `paccache`; never `sudo yay`).
