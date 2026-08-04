# Review: `detect-os.sh` Debian Support

**Number:** 0072
**Status:** Complete
**Date:** 2026-08-04
**Plan reviewed:** None — corrective fix, finding 1 of review 0071
**Branch:** `fix/detect-os-debian`

**Files reviewed:**

- `scripts/detect-os.sh`
- `Taskfile.yml` — `detect`

---

## Summary

`scripts/detect-os.sh` printed `unsupported: linux-gnu` and exited 1 on Debian, despite ADR-0053
having made Debian a first-class supported platform. The script was written before that ADR and was
never revisited. `scripts/check-zsh-deps.sh` and `scripts/doctor.sh` already detected all three
platforms, so the repository disagreed with itself about what OS a Debian machine is.

This implements an existing decision rather than making a new one, so no ADR accompanies it.

## Change

A `debian` branch keyed on `/etc/debian_version`, placed **after** the Arch test, and a header
comment recording why the order is load-bearing: the Debian marker exists on Debian and on every
derivative, so testing it first would misreport any system carrying both markers. This is the
ordering `AGENTS.md` §10 mandates and the one the two other detecting scripts already use.

`task detect`'s description updated from "macos or arch" to "macos, arch, or debian".

## Verification

The script hardcodes `/etc` paths, so a copy was generated with the marker paths rewritten into a
sandbox — **branch order preserved verbatim**, since that is the property under test. All five
branches were exercised, including the two this machine cannot otherwise reach:

| Case | Result | Exit |
|---|---|---|
| `darwin*` | `macos` | 0 |
| arch marker only | `arch` | 0 |
| debian marker only | `debian` | 0 |
| **both markers** | `arch` | 0 |
| neither marker | `unsupported: linux-gnu` | 1 |

Real machine: `task detect` → `arch`, exit 0. `bash -n` clean.

The both-markers case is the one that matters — it is the assertion that the ordering fix is real and
not incidental.

## Blocking Issues

None.

## Non-Blocking Findings

1. **`scripts/os-maintenance.sh` has the same gap, independently.** Its private `detect_os()` returns
   `unsupported` on Debian. Deliberately not fixed here: unlike this one-line branch, making
   `os-maintenance` work on Debian requires real `apt` update/upgrade/autoremove/clean logic and a
   decision about which of those may run. That is a feature with its own PRD, not a detection fix.
   Until then, `task update` and `task clean` are unavailable on Debian.
2. **Historical documents still describe two platforms.** Plans 0001/0005, architectures 0001/0002/
   0006, and several reviews say `detect-os.sh` prints "macos or arch". Left untouched — they are
   records of what was decided and built at the time, and rewriting them would falsify the history.
   Plan 0005 even scoped Debian out explicitly and asked for an ADR when the time came; ADR-0053 is
   that ADR.
3. **Debian remains unexercised by a real machine.** The sandbox proves branch selection, not that
   the rest of the toolchain behaves on Debian.

## Safety Verdict

PASS — read-only script; prints and exits, no side effects. The change adds one branch and cannot
reach any mutating code. No `$HOME` interaction.

## Privacy Verdict

PASS — no secrets, credentials, or machine-identifying values. `/etc/debian_version` is a standard
distribution marker.

## Documentation Verdict

PASS — the usage comment names all three outputs, the header records why the branch order matters and
points at the sibling scripts using the same order, and the Taskfile description matches actual
behaviour.

## Status-Sync Check

No Stow package added, removed, or first stowed. Status blocks unaffected.

## Recommended Next Action

Commit as `fix(scripts)`. Consider a PRD for Debian `os-maintenance` support (finding 1) if servers
need `task update`.
