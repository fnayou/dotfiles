# Review: Zsh Activation & Migration — Plan Review

**Number:** 0022
**Status:** Complete
**Date:** 2026-06-17
**Plan reviewed:** 0012 — Implement Zsh Activation & Migration (Model 4 → Model 3)
**Files reviewed:** `docs/plans/0012-implement-zsh-activation-migration.md`

> **Filename note:** The review request named `docs/plans/0010-implement-zsh-activation-migration.md`. That file does not exist — `0010` and `0011` were already taken, so the plan was correctly written as `0012` (the plan documents this in its own numbering note). This review covers `0012`, the actual plan. Verified via `ls docs/plans/`.

---

## Summary

Plan-stage review of Plan 0012 against the 15 requested focus points plus standard safety/privacy/documentation/cross-platform checks. This is a **plan review**, not an implementation review — the plan is unimplemented, so no plan is marked Complete (skill step 7a does not apply) and Plan 0012 remains Draft pending user approval.

The plan is sound, safe, and faithfully implements the approved PRD 0007 / Architecture 0007 direction and folds in all three non-blocking notes from Review 0021. **All three verdicts PASS. No blocking issues.** Two non-blocking findings (one worth fixing before the Builder runs: a validation-grep false positive).

---

## Focus-Point Findings (all 15)

| # | Focus | Result | Evidence in Plan 0012 |
|---|---|---|---|
| 1 | Model 4 kept as current state | PASS | Objective + Template Strategy: `.example`-first; nothing turned active; real files git-ignored until user copies. |
| 2 | Model 3 only documented as target | PASS | Include block ships only in `zshrc.example` (template) + docs; user adds by hand. No active wiring. |
| 3 | Real `~/.zshrc` stays unmanaged | PASS | Safety Checks: never modified/read/stowed; Assumptions reaffirm it is never referenced. |
| 4 | Include block guarded + example-only | PASS | Task 5: `[[ -r "$HOME/.config/zsh/index.zsh" ]] && source …`, delimited, in `zshrc.example` (tracked template). |
| 5 | Block documented to go LAST in `~/.zshrc` | PASS | Task 5 comment "placing it LAST"; Task 9 step 5 "add … last"; ADR-0023 records the rationale. |
| 6 | `local.zsh` is final override point | PASS | Task 4 `index.zsh` sources `local.zsh` last; ADR-0023; git-ignored, no `.example`. |
| 7 | compinit / Zinit ordering explicitly handled | PASS | Task 7 requires resolving double-`compinit` when Zinit manages completions; chosen approach commented. |
| 8 | Oh My Posh optional + guarded | PASS | `index.zsh` sources `omp.zsh` only if present; inner `eval` double-guarded (binary + `omp.toml`); never auto. |
| 9 | Zinit not auto-cloned | PASS | Task 7 guarded `source` only on `${ZINIT_HOME}/zinit.zsh`; manual clone documented `⚠️ MANUAL STEP` (ADR-0020). |
| 10 | fzf / zoxide / eza checked & guarded | PASS | Task 7 `command -v … && (eval|alias)`; no-op when absent. |
| 11 | No dependency installation introduced | PASS | No install step anywhere; validation greps for `brew install|pacman -S|git clone`; installs stay out-of-band. |
| 12 | No `$HOME` changes | PASS | Safety Checks explicit; only fake-home `--simulate`; rollback is git-only. |
| 13 | No broad destructive cleanup command | PASS | Task 9 + Safety Checks: "never a bare `rm -rf ~/.config/zsh`"; full-abort scoped to named files. |
| 14 | Cleanup commands scoped & safe | PASS | Rollback is `git checkout`/`git restore`/`git reset`; runbook cleanup scoped + `⚠️ MANUAL STEP`. |
| 15 | Validation uses fake-home where needed | PASS | ADR-0017 block: `mktemp -d` → `stow --simulate` → `rm -rf "$TEST_HOME"`, never real `$HOME`. |

All 15 focus points PASS.

---

## Blocking Issues

None.

---

## Non-Blocking Suggestions

1. **Validation grep false-positives on existing commented OMP lines (worth fixing before Builder runs).** The Task 10 / Validation Commands check:

   ```bash
   grep -RnE "brew install|pacman -S|git clone|oh-my-posh init" \
     stow/common/zsh/.config/zsh/*.example || echo "clean: ..."
   ```

   matches the already-present **commented** reference lines, so it never prints "clean" and could mislead the Builder into seeing a phantom auto-activation. Verified:

   ```
   omp.zsh.example:22:#   eval "$(oh-my-posh init zsh --config ...)"
   shared.zsh.example:39:#   eval "$(oh-my-posh init zsh --config ...)"
   ```

   Recommend anchoring the pattern to non-comment lines, e.g. `grep -RnE "^[[:space:]]*[^#].*?(brew install|pacman -S|git clone|oh-my-posh init)"` (or pipe through `grep -v '^[[:space:]]*#'` first). The intent — "no *active* install/clone/auto-eval in templates" — is correct; only the matcher needs to ignore comments. Not blocking: it is a validation-command refinement, not a defect in the shipped templates.

2. **Task 7 adds uncommented (guarded) `eval` lines to `shared.zsh.example`.** Today `shared.zsh.example` carries only a *commented* OMP block; Task 7 introduces live-but-guarded `command -v … && eval` lines for fzf/zoxide/eza and a guarded Zinit `source`. This is consistent with Architecture 0006 Decision 5 (guards are no-ops when the tool is absent) and does not violate "do not turn examples into active config" (the real `shared.zsh` does not exist until the user copies it, and every line is presence-gated). Flagged only so the Builder/Reviewer treats the shift from commented→guarded-live as intentional and confirms each line is a genuine no-op when its tool is missing.

3. **Number-space clarity (informational).** This review is `0022` in `docs/reviews/`; the plan proposes ADR-`0021`/`0022`/`0023` in `docs/decisions/`. Different directories — no collision. Noted to avoid confusion when the ADRs are written.

---

## Safety Verdict

**PASS** — No `$HOME` modification, no symlink creation, no Stow against real home (fake-home `--simulate` only, ADR-0017), no dependency install, no Zinit auto-clone, no OMP auto-activation. Real `~/.zshrc` never read/modified/stowed. No `stow --adopt`. No broad `rm`; cleanup scoped to named files and `⚠️ MANUAL STEP`-marked. Rollback is git-based and in-repo. The plan modifies/creates only repository files.

## Privacy Verdict

**PASS** — No credentials, tokens, SSH key content, private hostnames, internal IPs, or work-specific values in the plan or its template specs. Placeholders use `YOUR_*` / `$HOME` / `$XDG_*`. `local.zsh` correctly defined as git-ignored, no `.example`, never tracked; plan adds a `git check-ignore` gate before any local copy. `.gitignore` extension for `index.zsh`/`local.zsh` specified.

## Documentation Verdict

**PASS** — Tasks are ordered, individually verifiable, with per-task validation. Commands copy-pasteable; risky ones carry `⚠️ MANUAL STEP`. macOS/Arch separation preserved (layer files + OS detection in `index.zsh`; runbook labels platform-specific steps). Cross-references accurate (PRD 0007, Architecture 0007, Review 0021, ADR-0016/0017/0020, DOCUMENT-LIFECYCLE). Status correctly Draft. The renumbering from the requested `0010` to `0012` is documented in-plan and confirmed correct.

---

## Recommended Next Action

**Approve the plan.** No blocking issues. Recommend the user transition Plan 0012 Draft → Approved (per DOCUMENT-LIFECYCLE), optionally asking the Builder to apply non-blocking suggestion #1 (comment-anchored validation grep) when implementing Task 10. The Builder then implements Tasks 1–10 in order with per-task validation, stopping at "Next Steps" without changing plan status; a follow-up implementation review verifies and, if all verdicts PASS, marks Plan 0012 Complete. Do not implement before approval.
