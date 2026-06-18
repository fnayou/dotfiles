# Review: Plan 0013 — Implement Zsh Managed-Layer Activation (--no-folding)

**Number:** 0026
**Status:** Complete
**Date:** 2026-06-18
**Plan reviewed:** 0013 — Implement Zsh Managed-Layer Activation (--no-folding)
**Related documents:**
- PRD: `docs/prd/0008-zsh-managed-layer-activation.md`
- Architecture: `docs/architecture/0008-zsh-managed-layer-activation-architecture.md`
- Review: `docs/reviews/0025-zsh-managed-layer-activation-prd-architecture-review.md` (Final Verdict: APPROVED)
- ADR: `docs/decisions/0024-use-no-folding-for-zsh-package.md` (Status: Accepted)

> **Filename note:** The user requested review of `docs/plans/0011-implement-zsh-managed-layer-activation.md`. That file does not exist — `0011` is reserved for shell dependencies. The actual plan is `0013`. This review covers Plan **0013**, the correct document.

---

## Summary

Review of Plan 0013 — Implement Zsh Managed-Layer Activation (--no-folding) against 10 focus areas covering migration safety, home-directory boundaries, file promotion, privacy, dependencies, and validation. All 10 focus areas PASS. Plan is complete, safe, dry-run-gated, and includes all required ADRs inline. No blocking issues.

| # | Focus Area | Verdict |
|---|---|---|
| 1 | Migration safe for folded → --no-folding (dry-run-gated, STOP on conflict, correct commands) | PASS |
| 2 | All real $HOME commands marked ⚠️ MANUAL STEP | PASS |
| 3 | No `--adopt` appears anywhere | PASS |
| 4 | No `rm -rf ~/.config/zsh` appears as instruction | PASS |
| 5 | `local.zsh` remains private/untracked (outside repo boundary + .gitignore) | PASS |
| 6 | Example-to-real promotion clear (copy commands, .example → real, git-ignore check) | PASS |
| 7 | Optional tools remain guarded (no auto-install, no unconditional eval) | PASS |
| 8 | Rollback realistic (named-file rm only, no broad deletion, all manual) | PASS |
| 9 | ADRs 0025–0027 included with full inline content | PASS |
| 10 | Validation proves ~/.config/zsh is NOT a directory symlink (real-dir check present) | PASS |

---

## Focus-Point Findings

### 1 — Migration safe for folded → --no-folding

**PASS.** Phase 3 (Tasks 3a–3e) structures the migration as: read-only pre-migration validation (3a) → fake-home layout validation (3b, agent-run on ephemeral `$TEST_HOME`) → `⚠️` unstow fold (3c, `--simulate` before live delete) → `⚠️` restow with `--no-folding` (3d, `--simulate` before live stow) → read-only post-migration form check (3e). Conflict handling explicitly stated in Task 3d: "Any conflict → STOP. Resolve manually. Never use `--adopt`." Stow command syntax is correct: `stow --dir=stow/common --target="$HOME" --no-folding zsh`. Matches Architecture 0008 §3 exactly.

### 2 — All real $HOME commands marked ⚠️ MANUAL STEP

**PASS.** All stow commands touching `$HOME` (Tasks 3c, 3d) and all Phase 6 rollback commands carry the marker on both the dry-run and live lines. Phase 0/1/2 (status updates, ADR creation, repo-internal copies) have no marker — correct, as they do not touch `$HOME`. Marker is consistently placed on the line directly before the code fence.

### 3 — No `--adopt` appears anywhere

**PASS.** `--adopt` does not appear in the plan. Conflict handling (Task 3d) states only "STOP. Resolve manually. Never use `--adopt`." No implicit adoption path.

### 4 — No `rm -rf ~/.config/zsh` appears as instruction

**PASS.** Phase 6 rollback explicitly forbids `rm -rf ~/.config/zsh`. Cleanup commands use named-file `rm -f` only, listing each file individually. Task 5.2 validation (documentation update) includes a grep check that `rm -rf.*config/zsh` produces no output from the updated `docs/zsh-migration.md`.

### 5 — `local.zsh` remains private/untracked (outside repo boundary + .gitignore)

**PASS.** ADR-0026 (Task 1.3) establishes `local.zsh` as a real, unversioned file created directly under `~/.config/zsh/` by the user — physically outside the repo working tree under `--no-folding`, with `.gitignore` as belt-and-suspenders. Never copied from the repo; never a symlink; never created by the agent. Task 4e validates `local.zsh` not tracked (`git check-ignore` + `git ls-files --error-unmatch`). ADR-0026 states it cannot be `git add`-ed by accident because it resides outside the repo.

### 6 — Example-to-real promotion clear

**PASS.** Phase 2 (Tasks 2.1–2.2) copies `index.zsh.example` → `index.zsh` and `shared.zsh.example` → `shared.zsh` with copy-pasteable commands. Each includes a `git check-ignore` validation confirming the file is ignored. Task 2.3 (git safety re-check) confirms no non-`.example`, non-`.gitignore` file appears in `git ls-files`. Task 2.1 note explicitly defers `omp.zsh`, `macos.zsh`, `arch.zsh` as `.example`-only for now. Phase 2 copies are agent-run (no `⚠️` marker) — correct, as they are repo-internal.

### 7 — Optional tools remain guarded

**PASS.** Task 4f validates `shared.zsh` uses `command -v` guards for fzf, zoxide, eza — expects three matching guard lines and no unconditional `eval`. The full validation suite checks for active install/clone lines (`brew install`, `pacman -S`, `git clone`) and expects no output. OMP is opt-in (sourced only if present). Zinit is guarded by ADR-0020. No auto-install or auto-clone path introduced.

### 8 — Rollback realistic

**PASS.** Phase 6 defines five ordered steps: disable layer (comment include block in `~/.zshrc`) → unstow (`--simulate` before live) → named-file `rm -f` for copied managed files + optional `local.zsh` → re-fold fallback (optional, `--simulate` before live) → verify. No `rm -rf`; every `$HOME`-touching step is `⚠️ MANUAL STEP`. Restore step provides the re-fold stow command to return to prior folded state. Ordered, safe, reversible.

### 9 — ADRs 0025–0027 included with full inline content

**PASS.** Tasks 1.2–1.4 include the complete markdown content for ADRs 0025, 0026, and 0027 inline as copy-pasteable blocks. Each contains header (Number, Date, Status, cross-references), Context, Decision, and Consequences sections. ADR-0025: files linked by physical presence, not git-tracking; templates versioned; real files git-ignored. ADR-0026: `local.zsh` is real, outside repo, never symlinked; refines ADR-0023. ADR-0027: `~/.zshrc` stays unmanaged throughout migration; reaffirms ADR-0021. Task 1.5 appends all three to the `docs/decisions/README.md` index.

### 10 — Validation proves ~/.config/zsh is NOT a directory symlink

**PASS.** Task 3e (post-migration form check) includes: `[[ -d "$HOME/.config/zsh" && ! -L "$HOME/.config/zsh" ]] && echo "real-dir-ok" || echo "NOT-real-dir — investigate"`. This verifies a real directory AND not a symlink. Task 4c confirms `index.zsh` and `shared.zsh` are per-file symlinks resolving into the repo. The full validation suite repeats the real-directory check. Expected output is explicit: `real-dir-ok`.

---

## Additional Observations

**Assumptions verified:** Assumptions section correctly restates Review 0024 confirmed state (directory-fold, `~/.zshrc` with guard, `$ZDOTDIR` unset, `.example`-only). Consistent with Review 0024 Issue 3 findings. No conflict.

**PRD/Architecture status transition:** Plan marks PRD 0008 and Architecture 0008 as Approved in Phase 0 before implementation phases begin. Correct per DOCUMENT-LIFECYCLE: status transition precedes implementation.

**Fake-home validation (Task 3b):** Uses `mktemp -d`, `--simulate`, immediate cleanup. Per ADR-0017. Correctly confirms package layout without touching real `$HOME`. Separated from migration steps.

**Completion criteria:** 23 explicit, observable, machine-checkable criteria covering all phases.

---

## Blocking Issues

None.

---

## Non-Blocking Observations

- **Task 1.1:** "Log: ADR-0024 already Accepted — no action" — no commit artifact expected; verbal or log confirmation sufficient. Plan is clear.
- **Phase 6 scope:** Explicitly labeled "reference section, not a task to execute" and excluded from completion criteria. Correct framing.

---

## Verdicts

- **Safety: PASS** — All `$HOME` stow commands marked `⚠️ MANUAL STEP` with preceding dry-runs. No `--adopt`. No `rm -rf ~/.config/zsh`. `~/.zshrc` never modified. Rollback uses named-file cleanup only. No dependency installation; no Zinit auto-clone; no OMP auto-activation.
- **Privacy: PASS** — No credentials, tokens, private hostnames, or personal values in plan or ADR content. Placeholder values only. `local.zsh` designated secret slot (git-ignored, never created by agent, physically outside repo). Only `.example` templates are versioned.
- **Documentation: PASS** — Commands are copy-pasteable; risky ones marked `⚠️`. Cross-references to PRD 0008, Architecture 0008, ADRs 0024–0027 are accurate. Three new ADRs are complete and self-contained inline.

---

## Final Verdict

**APPROVED**

All 10 focus points pass. Plan 0013 is a safe, complete, dry-run-gated implementation plan for the zsh managed-layer activation under `--no-folding`. Migration is correctly ordered. ADRs 0025–0027 are fully defined inline. `local.zsh` boundary is clear and strong. Validation proves the post-migration state. Rollback is explicit and safe.

Per DOCUMENT-LIFECYCLE (Reviewer marks a Plan Complete after a passing review): **Plan 0013 is marked Complete** and this review is **Complete**.

**Recommended next action:** Builder implements Plan 0013 Phases 0–5 in order, running per-task validation after each phase, committing per logical group. Phase 3 tasks 3c–3d are `⚠️ MANUAL STEP` — Builder presents dry-run output; user reviews and runs the live command. Follow-up implementation review verifies all 23 completion criteria.
