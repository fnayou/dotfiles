# Review: Zsh Managed-Layer Activation — PRD & Architecture Review

**Number:** 0025
**Status:** Complete
**Date:** 2026-06-18
**Documents reviewed:**
- PRD: `docs/prd/0008-zsh-managed-layer-activation.md`
- Architecture: `docs/architecture/0008-zsh-managed-layer-activation-architecture.md`
- Validation: `docs/reviews/0024-zsh-manual-migration-validation.md`
- ADR: `docs/decisions/0024-use-no-folding-for-zsh-package.md`

---

## Summary

Review of PRD 0008, Architecture 0008, and ADR-0024 against a 10-point safety and strategy
checklist. **All 10 points PASS.** The `--no-folding` strategy is sound, clearly justified,
and migration safeguards are comprehensive. No blocking issues found.

| # | Focus Area | Verdict |
|---|---|---|
| 1 | `--no-folding` strategy justified | PASS |
| 2 | Folded state acknowledged | PASS |
| 3 | Migration safety (dry-run, conflict-stop, no `--adopt`) | PASS |
| 4 | `~/.zshrc` remains unmanaged | PASS |
| 5 | No `$HOME` modification in docs/architecture phase | PASS |
| 6 | Example-to-real promotion explicit | PASS |
| 7 | `local.zsh` boundary (outside repo, never symlinked) | PASS |
| 8 | Dependencies guarded (no auto-install, no auto-clone) | PASS |
| 9 | Rollback clear and safe | PASS |
| 10 | ADR for `--no-folding` exists | PASS |

---

## Findings

### 1 — `--no-folding` strategy justified

**PASS.** PRD 0008 §`--no-folding` Strategy selects it as intended behavior with explicit
trade-off (re-stow per new file, accepted). Architecture 0008 §2 provides a five-row
drawbacks table for folding: repo boundary leak, no managed/private separation,
non-managed file pollution, doc divergence, coarse revert granularity. ADR-0024 records
the rationale. All three documents agree.

### 2 — Folded state acknowledged

**PASS.** PRD 0008 §Problem Statement (line 12) states `~/.config/zsh` is stowed as a
directory fold, referencing Review 0024 Issue 3. Architecture 0008 §Context restates the
confirmed state and references the same issue. Migration runbook is structured around
converting FROM the folded state. No gaps.

### 3 — Migration safety (dry-run-gated, conflict-stops, never `--adopt`)

**PASS.** Architecture 0008 §3 orders five steps: read-only pre-check → `--simulate
--delete` → `--delete` → `--simulate --no-folding` → `--no-folding`. Every executable
command carries `⚠️  MANUAL STEP`. Conflict handling (§3, last paragraph): "STOP and
resolve manually … **Never use `--adopt`**." PRD 0008 §Safety Requirements (line 73)
requires `--simulate` before any real stow. No shortcuts observed.

### 4 — `~/.zshrc` remains unmanaged

**PASS.** PRD 0008 Non-Goals and Safety Requirements both forbid modifying `~/.zshrc`.
Architecture 0008 §6 ("How `~/.zshrc` Remains UNMANAGED") states it is never stowed,
never symlinked, never auto-edited, and confirms Review 0024 left it unchanged. ADR-0024
Decision 4 reaffirms. `zshrc.example` in the package (stow/common/zsh/.config/zsh/) is
annotated "NEVER applied automatically and is NEVER stowed to `~/.zshrc`."

### 5 — No `$HOME` modification in docs/architecture phase

**PASS.** PRD 0008 §Safety Requirements (line 67) and Closing Note (acceptance criterion,
last bullet) confirm no `$HOME` file touched. Architecture 0008 Closing Note: "Nothing in
this document was executed." All validation commands in §12 are read-only (`ls`, `grep`,
`readlink`). The fake-home validation uses `mktemp -d` and cleans it immediately — real
`$HOME` untouched (ADR-0017).

### 6 — Example-to-real promotion explicit

**PASS.** PRD 0008 §Example-to-Real-File Strategy names two file classes (versioned/
symlinked vs. unversioned/private), the minimum to activate (`index.zsh`), recommended
source order, and one-way copy direction. Architecture 0008 §4 provides a named table
(each `.example` → real file, role, whether to promote), explicit copy commands with
platform labels, and the `--no-folding --restow` step to create per-file links. No
ambiguity on which files, what order, or who performs the copy (user only).

### 7 — `local.zsh` outside repo, never symlinked

**PASS.** PRD 0008 §Example-to-Real-File Strategy explicitly places `local.zsh` in the
unversioned/private class. Architecture 0008 §5 states it is created directly under
`~/.config/zsh/` with `$EDITOR`, not from the repo. The git-ignore (verified:
`stow/common/zsh/.config/zsh/.gitignore` line 8) is described as "belt-and-suspenders"
— the primary boundary is physical (outside the repo working tree). Architecture 0008 §5:
"it can never be `git add`-ed by accident."

### 8 — Oh My Posh, fzf, zoxide, eza, Zinit remain guarded

**PASS.**
- **OMP:** `omp.zsh` is opt-in (only `[[ -r … ]]` sourced by `index.zsh`), double-guarded
  internally (binary + config), and ships commented out in `omp.zsh.example`. Architecture
  0008 §9 confirms.
- **fzf / zoxide / eza:** each is a `command -v <tool> >/dev/null 2>&1 && …` guard in
  `shared.zsh.example`; no install at startup. Architecture 0008 §10 confirms.
- **Zinit:** ADR-0020 forbids the upstream auto-clone snippet. Guard: `[[ -f
  "${ZINIT_HOME}/zinit.zsh" ]]`. Manual one-time clone documented, never at startup.
  Architecture 0008 §11 confirms.

No auto-install or auto-clone path found in any template or documentation command.

### 9 — Rollback clear and safe

**PASS.** PRD 0008 §Rollback Strategy provides five ordered steps. Architecture 0008 §13
expands them with copy-pasteable commands under `⚠️  MANUAL STEP` markers. Step 3 (both
documents) names files explicitly: `rm -f "$HOME/.config/zsh/index.zsh" … local.zsh`.
`rm -rf ~/.config/zsh` prohibition stated in both documents. `~/.zshrc` untouched in all
steps. Optional re-fold fallback (Step 4) allows return to prior state. Verify step closes
the runbook.

### 10 — ADR for `--no-folding` exists

**PASS.** ADR-0024 (`docs/decisions/0024-use-no-folding-for-zsh-package.md`) exists,
status Accepted, references PRD 0008 and Architecture 0008. Architecture 0008 §14
proposes three additional ADRs (0025–0027) for managed-file git-ignore strategy,
`local.zsh` boundary, and `~/.zshrc` unmanaged status — all still to be created.

---

## Cross-Reference Consistency

PRD 0008, Architecture 0008, ADR-0024, and Review 0024 are mutually referential and
internally consistent. Architecture 0008 adds concrete commands and decisions not present
in PRD 0008 without contradicting it. Review 0024 Issue 3 (folding vs. per-file) is
resolved by PRD 0008 and Architecture 0008. No contradictions found.

---

## Verdicts

- **Strategy (--no-folding):** PASS — justified, consistent, trade-off explicit.
- **Safety:** PASS — no `$HOME` touch, dry-run-gated migration, no `--adopt`, no auto-install.
- **Privacy:** PASS — `local.zsh` physically outside repo, git-ignored; no `$HOME` content in docs.

---

## Final Verdict

**APPROVED**

All 10 focus points pass. PRD 0008 and Architecture 0008 form a coherent, complete
specification for zsh managed-layer activation under `--no-folding`. Migration is safe.
`~/.zshrc` remains unmanaged. Dependency guards hold. Rollback is explicit. ADR-0024 is
recorded. No blocking issues. Ready for planning.

**Recommended next step:** plan `docs/plans/0008-zsh-managed-layer-activation-plan.md`
covering the ADRs 0025–0027 from Architecture 0008 §14, `--no-folding` migration runbook
(Architecture 0008 §3), example-to-real copy steps (§4), `local.zsh` creation (§5),
doc updates (`docs/stow-usage.md` / `docs/zsh-migration.md`), per-task validation (§12),
and rollback note (§13).
