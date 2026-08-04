# Review: Architecture 0022 — Agent-Facing Install and Update Documents

**Number:** 0074
**Status:** Complete
**Date:** 2026-08-04
**Reviewed:** `docs/architecture/0022-agent-facing-install-and-update-architecture.md` against
PRD 0023, ADR-0062, ADR-0063, ADR-0064, and `AGENTS.md` §8–§11

**Files reviewed:**

- `docs/architecture/0022-agent-facing-install-and-update-architecture.md`
- `docs/prd/0023-agent-facing-install-and-update-documents.md`

---

## Summary

Architecture review preceding the `AGENTS.md` §8 ADR and the documents themselves. Four defects were
found, two of them blocking, and all four were fixed in this pass; the architecture moves to Approved.

**Reviewer independence is weak here and should be stated rather than glossed.** The same session
authored the architecture, grilled it, and reviewed it. The findings below are real — one of them a
silent-data-loss path — but a reviewer who did not write the document would plausibly find more. The
sandbox validation required by PRD 0023 is the compensating control, and it has not run yet.

## Blocking Issues (both fixed in this pass)

### B1 — `git switch -C deployed <tag>` can silently destroy operator commits

Decision 7 moves the deploy pointer with `git switch -C`, which **force-resets the branch**. If the
operator has committed anything on `deployed` — an experiment, a local tweak — the ref moves off
those commits and they survive only in the reflog. This is silent data loss, in the command this
design runs most often, on a branch the design itself invites the operator to sit on.

Nothing in the document guarded it. Grilling question 4 established the branch pointer specifically to
avoid a detached HEAD, and the destructive property of `-C` went unexamined.

**Fixed:** decision 7 now requires `git rev-list deployed --not --tags` to be empty before the ref
moves. Non-empty means the operator has work there; the run aborts, lists the commits, and changes
nothing. Added to the risk register as Low likelihood / High impact.

### B2 — PRD 0023 contradicted ADR-0064 in its own Safety Requirements

The approved PRD carried:

> **`.example` templates are copied, never filled.** […] It copies the template where the repo
> prescribes and lists what needs human completion.

ADR-0064 and Architecture 0022 decision 3 settled the opposite: the agent copies nothing and creates
no `local.zsh`. An approved PRD and an accepted ADR directly disagreed on a permitted agent action.

This is the **same defect class as ADR-0036 vs ADR-0054**, fixed hours earlier in this session — and
it was introduced *after* that lesson, which is worth recording. `scripts/check-decisions.sh` cannot
catch it: that checker validates ADRs against ADRs, and nothing validates PRDs against the ADRs that
supersede parts of them.

**Fixed:** the PRD requirement now states that no private file is created by the agent at all, and
names ADR-0064 as having settled it the other way.

## Non-Blocking Findings (both fixed in this pass)

### N1 — Design decisions were numbered out of order

Headings ran `1, 2, 3, 4, 3a, 3b, 4b, 5, 6, 6b, 7`. Sections 3a and 3b appeared *after* 4, and the
`a`/`b` suffixes were themselves evidence of a document patched during grilling rather than composed.
Renumbered 1–11 in file order, with the Open Questions cross-reference updated from "3a" to "5".

### N2 — The risk register predated half the design

Written before grilling, it covered none of decisions 5–7 or 10. Its Debian row was actively wrong:
it predicted `complete-with-caveats`, but decision 5 makes a fresh Debian server **abort**, since
`go-task` is not in the archive. Four rows added and the Debian row corrected.

## Conformance checks

| Check | Result |
|---|---|
| Every PRD 0023 goal has a design decision | Pass |
| PRD safety requirements reflected | Pass, after B2 |
| `--no-folding` mandated (ADR-0024) | Pass — decisions 2, 3 |
| `--adopt` forbidden absolutely | Pass — decision 3, risk register |
| `~/.zshrc` unmanaged (ADR-0027) | Pass — hand-editing forbidden; `task zsh:bootstrap` only |
| `chsh` never run (ADR-0027 / PRD-0007) | Pass — decision 10 |
| Zinit never cloned (ADR-0020) | Pass — no fetch of third-party code |
| `doctor` is the single definition of health (ADR-0063) | Pass — decision 11 |
| macOS / Arch / Debian treated separately | Pass — decisions 5, 3 (`batcat`) |
| No secrets, no `sudo`, no writes outside `$HOME` + checkout | Pass |

## Safety Verdict

PASS, after B1. The design's safety now rests on three structural properties rather than on agent
good behaviour: Assess is read-only so an abort is provably harmless; stow preflights every package
before installing any, so there is no partial-stow state; and every mutating command is idempotent
and reversible by a documented command. B1 was the one place a single command could destroy work
that nothing else could recover, and it is now guarded.

## Privacy Verdict

PASS. The agent creates no private file, requests no secret, and writes no report artifact. `git`
identity and `local.zsh` — the two private surfaces — are both report-only. `local.zsh` is never read
for content; `doctor` reports `PATH` assignments in it by line number only.

## Documentation Verdict

PASS, after N1 and N2. Decisions state their rejected alternatives, which is what makes the document
reviewable rather than merely declarative.

## Non-Blocking, Deferred

1. **Nothing validates PRDs against ADRs.** B2 existed because the consistency checker covers ADRs
   only. A PRD whose safety requirements are overtaken by a later ADR is undetectable mechanically.
   Worth considering after the documents ship.
2. **`Superseded in part` is still absent from `DOCUMENT-LIFECYCLE.md`** (carried from review 0073),
   whose ADR table is `Draft → Approved` and describes no supersession vocabulary at all.
3. **Decision 7's refusal rule is untested.** The tag-comparison logic is prose; the sandbox run
   required by PRD 0023 should exercise refusal explicitly, not only the success path.

## Recommended Next Action

Mark Architecture 0022 Approved. Write the `AGENTS.md` §8 ADR next — the documents must cite it —
then plan `install.md`, `update.md`, and the sandbox validation.
