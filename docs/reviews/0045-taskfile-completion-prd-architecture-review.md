# Review: Taskfile/fzf-tab Completion — PRD/Architecture/ADR (Design Review)

**Number:** 0045
**Status:** Complete
**Date:** 2026-06-22
**Plan reviewed:** Design review (pre-implementation) — PRD 0015, Architecture 0015, Plan 0019 (Draft)
**Files reviewed:**
- `docs/prd/0015-taskfile-completion.md`
- `docs/architecture/0015-taskfile-completion-architecture.md`
- `docs/plans/0019-implement-taskfile-completion.md`
- `docs/decisions/0046-compinit-unconditional-zinit-light-mode.md` (supersession target)

## Summary

Strict design review of the full Taskfile/fzf-tab zsh completion milestone (fzf-tab
load-order fix + native Task completion + conservative preview, all in scope; fzf-make out
of scope). The **technical design is correct** against every item in the review checklist.
However, the architecture document was edited in place when scope flipped from "defer" to
"full," and **several sections still carry the old framing that now contradicts the approved
Decisions**. Because the doc is marked `Approved` and drives the Builder, those contradictions
are blocking until reconciled. ADR-0049 (supersedes 0046) is correctly specified but not yet
written — that is a build task, not a design gap.

This is a design review; no Builder output exists, so no plan is marked Complete.

## Blocking Issues

All blockers are internal contradictions in `docs/architecture/0015-taskfile-completion-architecture.md`
left over from the scope flip. They would misdirect the Builder.

- **B1 — Proposed Structure contradicts Decision 4 (architecture:51–52).** Tree comments say
  `plugins.zsh` "(unchanged by this feature; see Decision 4 for optional reorder)" and
  `completions.zsh` "compinit + ... styles (unchanged here)". Approved Option C changes both
  files (compinit moves into `plugins.zsh`; `completions.zsh` becomes styles-only). Fix the
  two comments to reflect the reorder.
- **B2 — index source-order block is stale (architecture:60–64).** Says "6) completions.zsh
  # compinit runs here today". Under Option C, compinit runs in `plugins.zsh` (step 5).
  Update so the order shows compinit at the plugins step, not completions.
- **B3 — Decision 4 heading contradicts its own body (architecture:144).** Heading still reads
  "decouple from this feature; recommend a separate corrective ADR"; the body says Option C is
  folded INTO this milestone. Rename the heading to match the approved decision.
- **B4 — Recommended Next Step is wrong on two counts (architecture:237–241).** It names the
  plan as `docs/plans/0015-taskfile-completion.md` (actual: `docs/plans/0019-implement-taskfile-completion.md`)
  and instructs "Track the fzf-tab reorder ... as a separate plan + ADR if the user approves"
  — directly contradicting the approved full scope. Correct the plan filename and state that
  the reorder + ADR-0049 are in this milestone (Plan 0019).

## Non-Blocking Suggestions

- **N1 — `verbose yes` vs `verbose true` (architecture:106).** Decision 2's sample uses
  `verbose yes`; the user-approved form and Plan 0019 use `verbose true`. Both are valid zsh
  booleans, but align the sample to `true` for consistency.
- **N2 — Stale conditional language in Risks/Extensibility (architecture:215, 226–228).**
  "Ordering change (if Option C taken)" and "If Option C is adopted" / "A future fzf-tab task
  preview drops in" read as not-yet-decided; both are now decided/included. Reword to past/active.
- **N3 — Pre-existing zinit auto-clone caveat (not introduced here).** `zinit light <plugin>`
  auto-clones a missing plugin on first startup, which is network access. This predates this
  milestone and is unchanged by it, but since the checklist asks about network-at-startup it
  should be stated honestly: the *new* code (taskfile.zsh, the reorder) adds no network; the
  pre-existing zinit bootstrap may clone on a fresh machine. No action required for this milestone.
- **N4 — ADR-0046 scope wording.** ADR-0046 documents compinit *location/unconditionality*, not
  fzf-tab ordering per se. ADR-0049's supersession is about compinit moving to `plugins.zsh`.
  Keep that framing precise in 0049 so the supersession reason is accurate.

## Checklist Findings (technical design — all PASS)

- Fixes the fzf-tab ordering contract? **Yes.** Option C: `zsh-completions` (fpath) →
  `compinit` → `fzf-tab` → `zsh-syntax-highlighting`/`zsh-autosuggestions`.
- `compinit` runs exactly once? **Yes.** One call in the zinit branch, one fallback in the
  no-zinit `else` branch, and it is removed from `completions.zsh`. `zinit light` does not call
  compinit (ADR-0046 basis). Plan 0019 Task 8 greps `compinit` to verify.
- fzf-tab after compinit? **Yes.**
- autosuggestions/syntax-highlighting after fzf-tab? **Yes.**
- Native Task completion loaded safely and guarded? **Yes.** Native `_task` on `fpath`
  autoloaded by compinit (`#compdef task`); `taskfile.zsh` guarded by `command -v task`.
- Avoids executing tasks during completion? **Yes.** Native `_task` candidates; selection
  inserts only — zsh does not execute on completion.
- Preview conservative and non-executing? **Yes.** `task --summary "$word" 2>/dev/null ||
  task --list-all 2>/dev/null` — both read-only; explicitly never `--dry`/`-n`.
- Startup safe if `task`/`fzf`/Zinit/fzf-tab missing? **Yes.** task missing → `return`; fzf
  missing → preview zstyle unused, fzf-tab degrades to default menu; Zinit missing → error
  print + fallback compinit + `return 1`, shell continues; fzf-tab missing under Zinit → see N3.
- No dependency install / no network in new code? **Yes** for new code (see N3 for the
  pre-existing zinit caveat).
- Updates/supersedes ADR-0046? **Yes** — ADR-0049 specified (Plan 0019 Task 6), 0046 to be
  marked Superseded. (ADR-0049 written at build time.)
- Avoids fzf-make entirely? **Yes** — not referenced anywhere; native + fzf-tab only.
- Safety rules preserved? **Yes** — no `stow --adopt`, no `$HOME` modification, no real-home
  stow, only documented `stow --simulate` dry-run; reversible via git.
- Privacy preserved? **Yes** — files hold only completion `zstyle`s; no secrets/private/work values.

## Safety Verdict

PASS — no `stow --adopt`, no `$HOME` writes, no real-home stow, no `rm`/`mv`/`ln -s` against
`$HOME`; only a documented dry-run. All new runtime paths guarded.

## Privacy Verdict

PASS — no credentials, hostnames, or work-specific values; design is completion styling only.

## Documentation Verdict

FAIL — blocking internal contradictions B1–B4 in `architecture/0015` (stale pre-flip text vs
approved Decisions; wrong plan filename in Recommended Next Step). PRD 0015 and Plan 0019 are
consistent with the approved scope.

## Recommended Next Action

Architect: fix B1–B4 (and ideally N1–N2) in `docs/architecture/0015-taskfile-completion-architecture.md`
so the whole document agrees with its approved Decisions and points to Plan 0019. After that,
the design is **approved for planning/build** — the technical design already passes every
checklist item, and Plan 0019 is aligned. No code or ADR-0049 implementation until Plan 0019
is approved by the user.
