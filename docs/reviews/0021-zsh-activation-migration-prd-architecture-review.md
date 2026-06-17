# Review: Zsh Activation & Migration — PRD 0007 + Architecture 0007

**Number:** 0021
**Status:** Complete
**Date:** 2026-06-17
**Documents reviewed:** Design review (PRD + Architecture) — not an implementation review
**Files reviewed:**
- `docs/prd/0007-zsh-activation-migration.md`
- `docs/architecture/0007-zsh-activation-migration-architecture.md`

---

## Summary

Design review of PRD 0007 and Architecture 0007, which define a safe migration from the user's existing hand-tuned `~/.zshrc` to a managed zsh layer. Reviewed against the eight requested focus areas plus the standard safety/privacy/documentation/cross-platform checks.

Both documents are design-only. `git status` confirms the working tree contains **only** the two new docs untracked — no `$HOME` change, no symlink, no Stow run, no dependency install. The referenced example files (`shared/macos/arch/omp.zsh.example`) exist, and every cited ADR (0001, 0003, 0004, 0013, 0016, 0017, 0020) and PRD (0006) is present and accurately referenced.

Verdict: **all three verdicts PASS. No blocking issues.** The design is sound and safe. Recommend approving both documents (Draft → Approved) and proceeding to the plan.

This is a PRD/Architecture review, so no plan is marked Complete (skill step 7a applies to implementation reviews only).

---

## Focus-Area Findings

### 1. Is Model 4 → Model 3 safe? — YES

- **Model 4 (start):** `.zshrc.example` reference only; nothing wired into any startup file. Zero risk to the working shell by construction.
- **Model 3 (target):** unmanaged `~/.zshrc` + one guarded include line sourcing `~/.config/zsh/index.zsh`. The existing config keeps loading; the block only *adds* a managed layer.
- Model 2 (stowed/replaced `~/.zshrc`) is explicitly rejected for migration and deferred to a fresh-machine-only future PRD — the exact abrupt cutover the user forbade is excluded.
- The path is staged and incremental (PRD migration phases 0–5; Architecture Decisions 1–5). Safe.

### 2. Does the real `~/.zshrc` remain unmanaged? — YES

- `~/.zshrc` is never stowed (ADR-0016 upheld), never auto-edited, never re-read. The include block is added **by hand** by the user (`⚠️ MANUAL STEP`).
- Architecture states this in three places (Context, Constraints, Decision 1) and the risk table guards against `zshrc.example` ever being mistaken for a stowable `~/.zshrc` (Decision 4 → file can only stow to `~/.config/zsh/zshrc.example`).
- Confirmed no tool/script in the design writes to `~/.zshrc`.

### 3. Is the include block guarded? — YES

- Block: `[[ -r "$HOME/.config/zsh/index.zsh" ]] && source "$HOME/.config/zsh/index.zsh"` — absent entry point is a clean no-op, not an error.
- `index.zsh` guards every layer source (`[[ -r ... ]]`), so a partially-adopted machine still starts a clean shell.
- Delimiter markers (`>>> dotfiles managed (zsh) >>>` / `<<<`) make the managed region unambiguous and give one revert point.

### 4. Is rollback easy? — YES

- Primary revert: delete/comment the one delimited block → managed layer inert → new shell. One step, no data loss.
- Backup-first step shipped (`cp "$HOME/.zshrc" "$HOME/.zshrc.bak.$(date +%Y%m%d)"`, marked `⚠️ MANUAL STEP`).
- Staged rollback covers per-capability revert, single-layer disable, and full abort (unstow + restore backup), plus a verify step (`zsh --no-rcs -c 'echo ok'`). No rollback step touches `$HOME` automatically.

### 5. Is automatic dependency installation introduced? — NO

- Inherits Architecture 0006's Check / Install / Activate split. Startup only **activates**; Install stays manual/out-of-band, shown not run.
- "Why shell startup must not install dependencies" restated (latency, network, silent mutation, non-determinism, blast radius).
- The include block and `index.zsh` source only declarative, guarded files. No `brew`, no `pacman`, no `git clone` at startup.

### 6. Are OMP / Zinit / fzf / zoxide / eza handled safely? — YES

- **Oh My Posh:** opt-in via separate `omp.zsh`; `index.zsh` sources it only if present; inner `eval` double-guarded on binary **and** `omp.toml` (Architecture 0005). Never auto-activates.
- **Zinit:** guarded `source` only; manual one-time `git clone` (ADR-0020); never auto-cloned at startup; detected by directory, not `$PATH`.
- **fzf / zoxide / eza:** guarded `command -v` activation in `shared.zsh` (Architecture 0006, Decision 5). Absent tool → no-op.
- All five: activate-if-present, never install-if-absent.

### 7. Are macOS and Arch separated? — YES

- Layer files segregated: `shared.zsh` (portable only), `macos.zsh` (Homebrew/macOS), `arch.zsh` (PATH/AUR). OS detection (`$OSTYPE` / `/etc/arch-release`) lives in `index.zsh` (ADR-0016).
- No Homebrew in Arch material, no pacman/AUR in macOS material. macOS/Arch considerations sectioned separately in both docs (AGENTS §10 upheld).

### 8. Is fake-home validation used where appropriate? — YES

- Architecture includes the ADR-0017 fake-home (`mktemp -d`) `--simulate` block for the implementation phase, and notes the real-home `--simulate` conflict on a pre-existing `~/.config/zsh/` is expected (layout-valid), not a bug. Rules carried correctly (always `mktemp -d`, remove immediately, never `--adopt`, conflict is a stop signal).

---

## Blocking Issues

None.

---

## Non-Blocking Suggestions

1. **`compinit` vs Zinit ordering (flag for the plan).** `shared.zsh.example` runs `autoload -Uz compinit && compinit`, and the design also places the Zinit guard in `shared.zsh`. Zinit commonly manages its own `compinit`; running both can double-initialize completions or conflict for the user's existing Zinit-based setup. The plan/implementation phase should define the order (e.g. Zinit-managed completions vs. a plain `compinit`) and avoid double init. Design-level note only — does not block approval.

2. **`local.zsh` "wins" scope is relative to managed layers, not the user's own `~/.zshrc` lines.** `index.zsh` sources `local.zsh` last so it wins **among managed layers**. If the user places the include block at the top of `~/.zshrc`, their own later lines still override `local.zsh`. Architecture already says "typically at the end" — recommend the migration runbook state explicitly that the block should be the last managed entry for the "local wins" guarantee to hold end-to-end.

3. **Full-abort `rm` of git-ignored real files is prose, not a marked command.** Rollback step 5 says "remove the git-ignored real files under `~/.config/zsh/`" without a literal command — good that no unmarked `rm` against `$HOME` is shown. When the runbook later spells this out, mark it `⚠️ MANUAL STEP` and scope it to the specific files (never a bare `rm -rf ~/.config/zsh`).

4. **Number-space clarity.** This review is `0021` in `docs/reviews/`; the architecture proposes ADR-`0021` in `docs/decisions/`. Different directories, no collision — noted here only to avoid confusion when the ADRs are written.

5. **`zshrc.example` scope (already an open question).** Recommend Open Question 2's option (b): full fresh-machine starter with the include block delimited at the top — serves both "I already have a `~/.zshrc`" and "fresh machine" cases. Confirm during planning.

---

## Safety Verdict

**PASS** — No `$HOME` modification, no symlink, no Stow against real home, no auto-install, no Zinit auto-clone, no OMP auto-activation. `~/.zshrc` never managed or re-read. All risky commands marked `⚠️ MANUAL STEP` and user-run. Fake-home validation (ADR-0017) used for layout checks. Rollback is one-step and reversible. `git status` confirms only the two design docs are present in the tree.

## Privacy Verdict

**PASS** — No credentials, tokens, passwords, private hostnames, or work-specific values in either document. Placeholders used throughout. `local.zsh` is correctly defined as git-ignored, never-tracked, no `.example` — the designated home for machine-specific/sensitive overrides (AGENTS §9). `.gitignore` extension for `index.zsh`/`local.zsh` specified.

## Documentation Verdict

**PASS** — Commands copy-pasteable; dangerous ones carry `⚠️ MANUAL STEP`; platform-specific content labeled and separated. Cross-references accurate (PRD 0006; ADR-0001/0003/0004/0013/0016/0017/0020; Architecture 0004/0005/0006 all exist and are cited correctly). Status fields correct (both Draft). Relationship to Architecture 0004 (refinement, not contradiction) is stated explicitly.

---

## Recommended Next Action

**Approve and proceed.** No blocking issues. Recommend the user/reviewer transition both documents Draft → Approved (per `docs/claude/DOCUMENT-LIFECYCLE.md`), then hand off to the Planner for `docs/plans/0007-zsh-activation-migration-plan.md`. The plan should carry the three proposed ADRs (0021–0023) and address non-blocking suggestions 1–3 (compinit/Zinit ordering, `local.zsh` placement guidance, marked full-abort cleanup). Do not implement before the plan is approved.
