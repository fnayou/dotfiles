# Plan: Implement OS Maintenance Helper

**Number:** 0021
**Status:** Complete
**Date:** 2026-06-24
**PRD:** 0018 (OS Maintenance Helper)
**Architecture:** 0018 (OS Maintenance Helper)
**Review:** 0049 (PRD + Architecture review — incorporates Suggestions 1–4)

## Objective

Implement a single OS-detecting maintenance helper (`scripts/os-maintenance.sh`) with `update`
and `clean` (dry-run default, `--apply` to delete) concerns, expose it via `Taskfile.yml`,
document the hazardous manual steps as a runbook, and record the two load-bearing choices as
ADRs — all within the repo's safety, privacy, and cross-platform rules. No destructive command
is executed during the build.

## Assumptions

- Branch `feat/os-maintenance` is checked out.
- PRD 0018 and Architecture 0018 are Approved; Review 0049 has no blocking issues.
- No `$HOME` modification, no `stow`, no symlink creation occurs in this plan.
- Defaults `PACCACHE_KEEP=3`, `JOURNAL_VACUUM_SIZE=200M` (per Architecture Decision 3).
- Existing aliases (`pacu`, `pacs`, `paci`, `aur`) are left untouched; no zsh wrapper this
  milestone (Architecture Decision 4).

## Ordered Tasks

1. **Create `scripts/os-maintenance.sh` skeleton.** Shebang `#!/usr/bin/env bash`,
   `set -euo pipefail`, usage/help text, arg parse for `<command> [--apply]`, OS detection via the
   §10 pattern (`$OSTYPE` darwin / `/etc/arch-release`), unsupported-OS → stderr + exit 1. Named
   readonly defaults at top. Dispatch to `arch_<cmd>` / `macos_<cmd>` functions (stubs first).
2. **Implement Arch `update`.** `arch_update`: prefer `yay -Syu`, fall back to
   `sudo pacman -Syu` when `yay` absent (guarded by `command -v`). Interactive; no `--apply`
   gate (upgrading is the intent).
3. **Implement Arch `clean` (report + apply).** `arch_clean`: compute and print orphans
   (`pacman -Qtdq`), cached-version reclaim (`paccache -dvk$PACCACHE_KEEP` dry-run) and
   journal reclaim (`journalctl --disk-usage`). Default = report only. With `--apply`:
   re-print the report first (Review 0049 Suggestion 1), then `sudo pacman -Rns` the orphans
   (only if non-empty), `sudo paccache -rk$PACCACHE_KEEP`, `sudo paccache -ruk0`,
   `sudo journalctl --vacuum-size=$JOURNAL_VACUUM_SIZE`. Never touches `mirrorlist`/`pacdiff`.
4. **Implement macOS `update` + `clean`.** `macos_update`: `brew update && brew upgrade`
   (guarded by `command -v brew`). `macos_clean`: report = `brew cleanup --dry-run` +
   `brew autoremove --dry-run` + `brew doctor`; `--apply` re-prints then runs `brew cleanup` and
   `brew autoremove`. Symmetric to Arch; no pacman/yay leakage.
5. **Wire `Taskfile.yml` targets.** Add `update` (→ `bash scripts/os-maintenance.sh update`),
   `clean` (→ `... clean`, dry-run), and a distinctly named `clean:apply`
   (→ `... clean --apply`) so the safe task can never delete (Review 0049 Suggestion 2). Match
   existing task `desc`/`silent` style.
6. **Write `docs/guides/os-maintenance.md` runbook.** Document `task update` / `task clean` /
   `task clean:apply`; then a separate **manual** section for `pacdiff` and mirrorlist recovery
   (`reflector --save …`, keep-old-not-overwrite rule), each dangerous block preceded by the
   `⚠️  MANUAL STEP` marker (Review 0049 Suggestion 4). State the zsh wrapper is intentionally
   deferred (Review 0049 Suggestion 3).
7. **Add ADR `docs/decisions/0050-os-maintenance-single-script.md`** (Architecture Decision 1)
   and **`docs/decisions/0051-os-maintenance-task-only-interface.md`** (Architecture Decision 4),
   ADR-style (context / decision / consequences / status), matching existing decision files.
8. **Mark documents Complete/Approved as applicable and prepare commit** — Reviewer step (Task 9
   below) gates the commit; this task only stages after review passes.

## Files Affected

- `scripts/os-maintenance.sh` — created (executable, `chmod +x`).
- `Taskfile.yml` — modified (add `update`, `clean`, `clean:apply`).
- `docs/guides/os-maintenance.md` — created.
- `docs/decisions/0050-os-maintenance-single-script.md` — created.
- `docs/decisions/0051-os-maintenance-task-only-interface.md` — created.
- `docs/plans/0021-implement-os-maintenance.md` — this plan (status updates only).

No status-block change: no Stow package added/removed/first-stowed, so `AGENTS.md` §2 and
`CLAUDE.md` blocks stay as-is (status-sync rule self-check passes).

## Safety Checks

- [ ] Build runs **no** destructive command — no `pacman -Rns`, `paccache -r`, `journalctl
      --vacuum`, `brew cleanup`, `sudo`, `rm`, `mv`, `ln -s`, `stow`. Only file creation/edit.
- [ ] `clean` with no flag deletes nothing (dry-run verified by reading code + `bash -n`).
- [ ] No `mirrorlist`/`pacdiff` command anywhere in the script.
- [ ] No secrets or machine-specific absolute paths in any new file.
- [ ] `⚠️  MANUAL STEP` marker precedes every dangerous fenced block in the guide.

## Validation Commands

- `bash -n scripts/os-maintenance.sh` — syntax check (also run by CI).
- `shellcheck scripts/os-maintenance.sh` — if available; advisory.
- `bash scripts/os-maintenance.sh` — no args → prints usage, exits non-zero.
- `bash scripts/os-maintenance.sh bogus` — unknown command → usage to stderr, exit non-zero.
- `bash scripts/os-maintenance.sh clean` — Arch host: prints the report, **deletes nothing**
  (confirm by re-running `pacman -Qtdq | wc -l` and `du -sh /var/cache/pacman/pkg` before/after
  — unchanged).
- `task --list` — shows `update`, `clean`, `clean:apply` with descriptions.
- `grep -n 'pacdiff\|mirrorlist' scripts/os-maintenance.sh` — returns nothing.

## Rollback Strategy

All changes are new files plus an additive `Taskfile.yml` edit on an isolated branch. Rollback =
`git restore`/`git checkout` the affected paths, or delete the branch. Nothing outside the repo
is touched, so there is no system-state to revert. If `clean --apply` is ever run by the user
later, recovery for each destructive step is documented in the runbook (caches/orphans are
re-fetchable; journal reclaim is non-recoverable but bounded).

## Completion Criteria

- [ ] `scripts/os-maintenance.sh` implements `update` and `clean` (dry-run default + `--apply`
      that re-prints the report first) for both Arch and macOS, OS-detected, `set -euo pipefail`.
- [ ] `Taskfile.yml` exposes `update`, `clean`, `clean:apply`; `task clean` never deletes.
- [ ] `docs/guides/os-maintenance.md` exists with manual-step markers and the deferred-wrapper
      note.
- [ ] ADRs 0050 and 0051 exist.
- [ ] All validation commands pass; `bash -n` clean; no destructive command run during build.
- [ ] Reviewer approves (implementation review) before commit; Reviewer marks this plan Complete.
