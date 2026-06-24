# PRD: OS Maintenance Helper

**Number:** 0018
**Status:** Approved
**Date:** 2026-06-24

## Context

System maintenance (package update/upgrade plus routine hygiene — orphan removal, package-cache
pruning, journal vacuum) is currently done by hand, command by command, per OS. The steps are
easy to forget, easy to get wrong, and one of them (`pacdiff` overwriting `mirrorlist`) has
already broken a machine. This PRD proposes tracking those steps as a reproducible, OS-aware
helper so the same maintenance runs identically on any machine, while staying inside the
repository's safety posture (§3, §8): destructive actions are surfaced, not silently executed.

## Goals

- Provide a single, reproducible entry point for routine OS maintenance that detects the OS and
  runs the correct package-manager path: **Arch / EndeavourOS** (`pacman` / `yay`) and **macOS**
  (`brew`).
- Cover two clearly separated concerns:
  - **update** — sync + upgrade installed packages.
  - **clean** — routine hygiene (orphan removal, package-cache pruning, journal/log vacuum).
- Default the destructive `clean` concern to a **dry-run / report** mode; real deletion happens
  only behind an explicit opt-in flag.
- Expose the helper through the project's existing interface (the `task` runner), consistent with
  `detect`, `check`, and the dependency-check scripts.
- Keep per-OS logic separated and CI-lintable (`bash -n`, secret scan), reusing the documented
  OS-detection pattern (§10).
- Document the manual, hazardous steps (notably `pacdiff` / mirrorlist handling) as a human
  runbook with `⚠️ MANUAL STEP` markers — never automated.

## Non-Goals

- Bootstrapping or installing the OS, the package managers, or the AUR helper.
- Running maintenance automatically (no shell-startup hook, no cron, no scheduled task).
- Running `pacdiff`, overwriting `mirrorlist`, or re-ranking mirrors from inside the helper.
- Modifying `$HOME`, running `stow`, or creating symlinks.
- Replacing the existing thin per-OS aliases (`pacu`, `pacs`, `paci`, `aur`) — they stay.
- Full system backup/restore, kernel pinning, or snapshot management.

## User Stories

- As a user, I want one command that updates and (optionally) cleans my system correctly on
  whichever OS I'm on, so I stop re-deriving the steps from memory.
- As a user, I want the cleanup to **show me what it would remove first**, so I never lose
  packages or caches I meant to keep.
- As a user, I want the dangerous mirrorlist/`pacdiff` step kept as a documented manual runbook,
  so an automated run can never empty my mirrorlist again.
- As a user, I want the helper to live where the other helper scripts live and run through `task`,
  so it fits the muscle memory I already have.

## Constraints

- **Platform:** Logic must branch on OS using the §10 detection pattern (`$OSTYPE` darwin /
  `/etc/arch-release`). Arch and macOS paths are written and reasoned about separately; no
  package-manager command leaks across OSes.
- **Safety posture:** `update` may run interactive privileged upgrades (`sudo pacman -Syu` /
  `brew upgrade`). `clean` must be **non-destructive by default** — it reports what it *would*
  remove; actual removal requires an explicit flag (e.g. `--apply` / `--yes`).
- **No destructive automation (§3.9, §8):** orphan removal, cache pruning, and journal vacuum are
  destructive and must therefore be opt-in and shown before they run.
- **Taskfile mutation ban lifted for this feature:** the `update` and `clean:apply` tasks execute
  privileged, mutating commands. This PRD explicitly lifts the ADR-0009 non-mutation ban for those
  two tasks only (per ADR-0019's requirement), recorded in ADR-0052; both are MANUAL USE ONLY.
- **Discoverability:** exposed as `task` targets; any zsh alias is a thin wrapper that calls the
  script only if present (guarded), and must not collide with existing aliases (`pacu`).
- **CI:** new scripts must pass the existing CI hygiene checks (`bash -n`, secret scan, expected
  files present).

## Safety Requirements

- `clean` must default to dry-run; destructive deletion only with an explicit, documented flag.
- Must not run `pacdiff`, edit `mirrorlist`, or re-rank mirrors automatically.
- Must not run on shell startup or on any schedule.
- Must not run `rm`, `mv`, or `ln -s` against `$HOME`, and must not modify files outside the repo.
- Must not run `stow` or create symlinks.
- Privileged commands must be explicit and visible in the script, never hidden behind indirection.
- Scripts use `set -euo pipefail` and exit non-zero on unsupported OS, consistent with
  `detect-os.sh` and `check.sh`.

## Acceptance Criteria

- [ ] A maintenance script (OS-detected) exists under `scripts/`, covering `update` and `clean`
      concerns, with `clean` defaulting to dry-run.
- [ ] Arch path covers: `yay -Syu` (or `pacman -Syu`), orphan listing/removal, `paccache`
      pruning, journal vacuum — destructive steps gated behind the explicit flag.
- [ ] macOS path covers the symmetric `brew` equivalents (`update`/`upgrade`, `cleanup`,
      `autoremove`, `doctor`) — destructive steps gated behind the explicit flag.
- [ ] Helper is exposed via `Taskfile.yml` targets consistent with existing tasks.
- [ ] Any zsh integration is a guarded, per-OS thin wrapper that does not collide with existing
      aliases and is a no-op when the script is absent.
- [ ] The hazardous mirrorlist / `pacdiff` procedure is documented as a `⚠️ MANUAL STEP` runbook
      under `docs/guides/`, explicitly outside the automated helper.
- [ ] New scripts pass CI (`bash -n`, secret scan); no secrets or machine-specific absolute paths.
- [ ] Architecture record and plan approved before any build is committed (§6).

## Out of Scope

- Mirror ranking, `pacdiff` automation, kernel/bootloader maintenance.
- Scheduling or unattended execution.
- Stowing anything or touching `$HOME`.
- AUR helper or package-manager installation/bootstrap.

## Open Questions (for Architecture)

1. One cross-platform script with an OS branch, or one script per OS plus a thin dispatcher?
2. Subcommand surface and flag naming (`update` / `clean`, dry-run default vs `--apply`).
3. Whether to ship a zsh alias at all, or rely solely on `task` (avoids `$HOME`→repo path coupling).
4. Whether `clean`'s journal-vacuum target size and `paccache` keep-count are fixed defaults or
   flags.
