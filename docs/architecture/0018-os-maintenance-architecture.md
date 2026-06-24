# Architecture: OS Maintenance Helper

**Number:** 0018
**Status:** Approved
**Date:** 2026-06-24
**PRD:** 0018 (OS Maintenance Helper)

## Context

PRD 0018 (Approved) asks for a reproducible, OS-aware maintenance helper with two separated
concerns — `update` (sync + upgrade) and `clean` (orphans, package-cache pruning, journal
vacuum) — where `clean` is non-destructive by default and the hazardous `pacdiff` / mirrorlist
procedure stays a manual runbook. The repo already has the shape this should follow: small
`bash` helpers under `scripts/` (`detect-os.sh`, `check.sh`, `check-*-deps.sh`), all
`set -euo pipefail`, OS-detecting, report-only, each surfaced as a `task` in `Taskfile.yml` and
linted by CI (`bash -n` + secret scan). Per-OS shell aliases already exist in `arch.zsh`
(`pacu`, `pacs`, `paci`, `aur`) and `macos.zsh`.

## Proposed Structure

```
scripts/
└── os-maintenance.sh        # new: OS-detect → arch_* / macos_* functions; update|clean
docs/guides/
└── os-maintenance.md        # new: human runbook incl. the ⚠️ MANUAL pacdiff/mirrorlist steps
Taskfile.yml                 # new tasks: update, clean (dry-run), clean:apply
docs/decisions/
└── 0050-*.md, 0051-*.md     # ADRs for the two load-bearing choices (see Decisions 1 & 4)
```

No new stow package, no `$HOME` changes, no symlinks. `stow/arch/` stays empty (reserved for
config packages, not scripts).

## Design Decisions

### Decision 1: One OS-detecting script, not per-OS files

```
Option A: single scripts/os-maintenance.sh, OS detected once, dispatch to arch_*/macos_* funcs
  Pro: Matches detect-os.sh / check.sh single-file precedent. One file for CI to bash -n and
       secret-scan. Cross-platform rule (§10) requires separating per-OS *logic*, which named
       arch_update/macos_update functions satisfy — separation does not require separate files.
  Con: Both OS code paths live in one file (only one is exercised per host).

Option B: scripts/os-maintenance-arch.sh + -macos.sh + a dispatcher
  Pro: Physical separation per OS.
  Con: Three files and a dispatcher for a small helper; duplicated arg-parsing/usage; more
       surface to keep in sync. Over-built for the current scope.

Decision: Option A. Single script; clear arch_*/macos_* functions keep logic separate.
Documented in ADR 0050.
```

### Decision 2: Subcommand surface — `update`, `clean`; `clean` dry-run by default

```
Interface: scripts/os-maintenance.sh <command> [--apply]

  update            sync + upgrade. Interactive privileged step (sudo pacman -Syu / yay; or
                    brew update && brew upgrade). No --apply needed; upgrading is the point.
  clean             DRY-RUN by default: print exactly what would be removed (orphans, cached
                    package versions, journal reclaim) and exit without deleting.
  clean --apply     actually perform the destructive cleanup.

  Unknown command / unsupported OS → usage to stderr, exit non-zero (matches check.sh).

Rationale: maps 1:1 onto the PRD's two concerns and its safety posture — destructive deletion
is opt-in and is always preceded by a report. No combined `all` target: keeping update and
clean distinct keeps each invocation's blast radius explicit.
```

### Decision 3: Fixed, named defaults for cleanup thresholds (flags deferred)

```
At the top of the script, as named readonly vars:
  PACCACHE_KEEP=3            # keep last 3 cached versions per package
  JOURNAL_VACUUM_SIZE=200M   # cap persistent journal

Option A: fixed defaults now, env/flag overrides deferred (YAGNI)
  Pro: Simple, readable, matches the values used in the manual hygiene already run. Easy to
       change in one place.
  Con: Not tunable per-invocation yet.

Option B: expose --keep / --vacuum-size flags now
  Pro: Tunable.
  Con: More arg-parsing for a need that has not arisen.

Decision: Option A. Values are obvious, centralised, and documented; promote to flags only when
a real need appears.
```

### Decision 4: `task` is the canonical interface; zsh wrapper deferred

```
Option A: expose via Taskfile only (task update / task clean / task clean:apply); no zsh alias
  Pro: No coupling between an interactive shell and the repo's on-disk location. Consistent with
       how detect/check/deps are surfaced. Works from a repo checkout on any machine.
  Con: Must be run from the repo dir (as the other tasks already are).

Option B: also add a zsh function in arch.zsh/macos.zsh calling the script by absolute path
  Pro: Run from anywhere.
  Con: Requires a stable $DOTFILES anchor that does not exist in the zsh layers yet; hardcoding
       ~/work/dotfiles violates the "no machine-specific paths" rule (§10). Premature.

Decision: Option A for this milestone. Canonical interface = task targets. A guarded per-OS zsh
wrapper is deferred until a $DOTFILES anchor is introduced (separate change). Recorded in ADR
0051. Existing aliases (pacu etc.) are untouched.
```

### Decision 5: `pacdiff` / mirrorlist explicitly excluded from automation

The helper never runs `pacdiff`, edits `mirrorlist`, or re-ranks mirrors. These are documented
as a `⚠️ MANUAL STEP` runbook in `docs/guides/os-maintenance.md`, including the
`reflector --save /etc/pacman.d/mirrorlist` recovery and the rule to keep the old mirrorlist
rather than blind-overwrite a `.pacnew`. This directly encodes the failure already hit on this
host and keeps destructive, interactive, host-specific config merging out of any scripted path.

## Risks

- **Privileged commands (medium):** `update` and `clean --apply` invoke `sudo` package
  operations. Mitigated: commands are explicit and visible in-script (no hidden indirection),
  `clean` shows a report before `--apply`, and privileged steps are interactive.
- **Orphan-removal false positives (medium):** `pacman -Qtdq` can list packages the user wants.
  Mitigated: dry-run default prints the full list for review before any `-Rns`.
- **Partial failure mid-update (low/medium):** an interrupted `-Syu` leaves a partial state.
  Mitigated: documented recovery in the runbook; script uses `set -euo pipefail` and stops on
  first error rather than continuing.
- **macOS path unexercised here (low):** authored on an Arch host. Mitigated: `bash -n` in CI
  plus a documented manual smoke-test on macOS before relying on it; the brew path is guarded by
  `command -v brew`.
- **Reversibility (low):** `update` is forward-only by nature (package upgrades); `clean`
  removes caches/orphans that pacman/brew can re-fetch. No `$HOME` or repo data is touched.
- **Scope creep (low):** temptation to fold `pacdiff`/mirrorlist in later. Guarded by Decision 5
  and the PRD non-goals.

## Extensibility

- Adding a third OS is a new `wsl_*`/`debian_*` branch plus a detection arm — no redesign.
- Tunable thresholds become flags (Decision 3) without touching the command surface.
- A zsh wrapper drops in once a `$DOTFILES` anchor exists (Decision 4) — additive.
- A future `task maintain` meta-target (update + clean dry-run) is additive if wanted.

## Open Questions

- Should `clean --apply` require a second interactive confirmation (`y/N`) in addition to the
  flag, or is the explicit flag + preceding dry-run report sufficient? Leaning: flag + report is
  enough for a user-invoked tool; defer prompt unless the Planner/Reviewer wants belt-and-braces.

## Recommended Next Step

Reviewer: review this architecture against PRD 0018 and the safety/cross-platform/documentation
rules. On pass, Planner produces `docs/plans/0021-implement-os-maintenance.md` with ordered, safe
steps (create script with `update`/`clean` + dry-run default, add Taskfile targets, write the
runbook guide, add ADRs 0050/0051), each with validation (`bash -n`, `task --list`, a dry-run
`clean` showing no deletion) and a rollback note. Build must not run the destructive paths.
