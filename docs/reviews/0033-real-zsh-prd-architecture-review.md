# Review: Real Zsh Configuration Adoption — PRD and Architecture

**Number:** 0033
**Date:** 2026-06-19
**Documents reviewed:**
- docs/prd/0010-real-zsh-configuration.md
- docs/architecture/0010-real-zsh-configuration-architecture.md
**Verdict:** Approved with non-blocking notes

---

## Summary

This review validates a PRD and architecture proposal for adopting real zsh configuration content into `.example` templates. The documents define file layout, source order, optional tool guards, platform-specific content, and ADRs to record design decisions. Both documents are well-structured, internally consistent, reference established ADRs correctly, and reflect safety and privacy rules. Two issues require attention before implementation: (1) `zshrc.example` contains a personal alias that must be removed before commit, and (2) `macos.zsh.example` uses an outdated hardcoded Homebrew prefix pattern superseded by the `command -v brew` guard pattern documented in the architecture. These are straightforward fixes with no blocking impact on design.

---

## Findings

stow/common/zsh/.config/zsh/zshrc.example:25: 🔴 BLOCKING: Line contains `alias meteo='curl -4 http://wttr.in/Paris'` — a personal alias for the user's specific context (city: Paris). This is not a generic template and must be removed before any commit. Violates privacy rule against personal values in committed templates.

stow/common/zsh/.config/zsh/macos.zsh.example:8: 🟡 NOTE: Line `eval "$(YOUR_HOMEBREW_PREFIX/bin/brew shellenv)"` uses the outdated hardcoded-prefix pattern. Architecture §4 and PRD line 185 specify this should be `command -v brew >/dev/null 2>&1 && eval "$(brew shellenv)"` — portable across Apple Silicon and Intel without user input. Template must be updated to match architecture.

docs/prd/0010-real-zsh-configuration.md:182: 🟡 NOTE: `macos.zsh` strategy shows `YOUR_HOMEBREW_PREFIX/bin/brew shellenv` pattern, but architecture §4 defines this as superseded by `command -v brew` guard. Pattern mismatch; architecture is correct.

docs/prd/0010-real-zsh-configuration.md:194: 🟡 NOTE: macOS-specific aliases documented as "not guarded (always available on macOS)" with example `alias pbcopy`. But pbcopy/pbpaste are builtins, not binaries in $PATH, and may not be in user's shell environment in all contexts. Not blocking; minor documentation clarity issue.

docs/architecture/0010-real-zsh-configuration-architecture.md:25: 🟡 NOTE: States `macos.zsh.example` "only a minimal placeholder file with `YOUR_HOMEBREW_PREFIX` and `YOUR_MACOS_TOOL_PATH`" but does not flag that the hardcoded-prefix pattern should be replaced by `command -v brew`. Implies pattern in §4 is not yet reflected in current `.example`.

docs/prd/0010-real-zsh-configuration.md:269: 🟡 NOTE: Acceptance criterion "Shell starts cleanly with all optional tools present (macOS)" and "(Arch)" — but validation commands in §Validation Strategy (lines 229–237) do not include actual validation on macOS and Arch machines with tools present. Validation is dry-run only; real-machine validation is deferred to plan/build phase (acceptable, but worth noting).

docs/architecture/0010-real-zsh-configuration-architecture.md:899–910: ❓ QUESTION: ADR-0033 through ADR-0042 (10 new records) are listed as "to create" but no placeholder ADR files exist yet. This is expected (architecture proposes; planner/builder execute), but PRD acceptance criteria and architecture "Recommended Next Step" do not call out whether Architect or Planner is responsible for creating ADRs. Clarification: per DOCUMENT-LIFECYCLE.md, ADRs are created by agents as part of implementation (typically Planner or Builder before commit). Non-blocking.

docs/architecture/0010-real-zsh-configuration-architecture.md:771–773: 🟡 NOTE: Validation command `zsh -n stow/common/zsh/.config/zsh/shared.zsh` — the `-n` flag parses syntax only (no execution). This is correct but will not catch runtime errors such as a syntax error in a `$(…)` substitution that are only visible at eval time. Acceptable for committed files; additional runtime validation recommended in setup guide.

docs/prd/0010-real-zsh-configuration.md:251–249: 🟡 NOTE: Rollback strategy describes `stow --delete` but does not explicitly mention reverting `~/.zshrc` — though ADR-0027 reaffirms `~/.zshrc` is untouched and requires no revert. Minor clarity issue; not blocking.

---

## Checklist

### PRD checks

- [x] PRD has status, date, number — PASS
- [x] Problem statement / background is present and accurate — PASS
- [x] Goals are specific and verifiable — PASS
- [x] Non-goals are explicit — PASS
- [x] User stories are present — PASS
- [x] Constraints reference existing ADRs correctly — PASS
- [x] Safety requirements are complete and consistent with AGENTS.md safety rules — PASS
- [x] Privacy requirements are complete and consistent with AGENTS.md privacy rules — PASS
- [x] Managed file layout matches the actual repo package structure — PASS
- [x] local/private override strategy consistent with ADR-0023, ADR-0026 — PASS
- [x] Optional tool guard strategy covers all tools mentioned — PASS
- [x] Zinit strategy consistent with ADR-0020 — PASS
- [x] OMP strategy consistent with PRD-0005 and existing omp.zsh.example — PASS
- [x] fzf, zoxide, eza strategies are guarded — PASS
- [x] Validation strategy is actionable and copy-pasteable — PASS
- [x] Rollback strategy is actionable — PASS
- [x] Acceptance criteria are verifiable — PASS
- [x] Out of scope is explicit — PASS
- [x] Human setup guide requirement referenced (ADR-0028) — PASS
- [x] No secrets, private values, real paths, or credentials in the PRD text — PASS

### Architecture checks

- [x] Architecture has status, date, number, PRD reference — PASS
- [x] §1 file layout matches actual package on disk — PASS
- [x] §2 startup sequence is correct and consistent with index.zsh.example / index.zsh — PASS
- [x] §3 shared.zsh content matches actual shared.zsh and shared.zsh.example — PASS
- [x] §4 platform layers (macos.zsh, arch.zsh) are consistent with .example files — PARTIAL PASS (content correct; Homebrew pattern in .example is outdated)
- [x] §5 omp.zsh double guard is correct — PASS
- [x] §6 local.zsh boundary is consistent with ADR-0023, ADR-0026 — PASS
- [x] §7 tool guard patterns are all present and correct — PASS
- [x] §8 Zinit strategy is consistent with ADR-0020 — PASS
- [x] §9 PATH strategy is consistent with shared.zsh (no PATH in shared.zsh) — PASS
- [x] §10 history strategy: HISTFILE at $HOME/.zsh_history, correct setopt choices — PASS
- [x] §11 completion strategy: Zinit compinit guard is correct — PASS
- [x] §12 aliases: guarded where required; no unguarded optional-tool aliases — PASS
- [x] §13 no-folding strategy consistent with ADR-0024 — PASS
- [x] §14 setup guide requirement references ADR-0028 correctly — PASS
- [x] §15 validation commands are correct zsh syntax and safe to run — PASS
- [x] §16 rollback is complete and safe — PASS
- [x] §17 ADR numbers start from 0033 (after ADR-0032); titles match decisions; no duplicates — PASS
- [x] No net-access, no stow runs against real $HOME, no dependency installs described as automatic — PASS
- [x] No secrets or private values in the architecture text — PASS

### Consistency checks (PRD vs architecture)

- [x] File layout in PRD §Managed File Layout matches architecture §1 — PASS
- [x] Validation in PRD §Validation Strategy matches architecture §15 — PASS
- [x] Rollback in PRD §Rollback Strategy matches architecture §16 — PASS
- [x] Safety requirements in PRD match safety rules in architecture — PASS
- [x] ADR references in both documents are consistent — PASS

### Scope check

- [x] Scope is strictly "real zsh configuration adoption into .example templates" — PASS
- [x] No scope creep into Zinit plugin selection — PASS
- [x] No scope creep into OMP theme content (managed by common/omp package) — PASS
- [x] No scope creep into Neovim, Alacritty, tmux, SSH, or other packages — PASS
- [x] ~/.zshrc is confirmed unmanaged — PASS
- [x] $HOME is not touched during design/planning — PASS

---

## Verdict

**Approved with non-blocking notes**

The PRD and architecture are comprehensive, well-organized, and aligned with established ADRs and safety rules. Design decisions are sound; all constraints are satisfied. Two items must be resolved before implementation begins:

1. **Remove the personal alias from zshrc.example.** Line 25 of `stow/common/zsh/.config/zsh/zshrc.example` contains `alias meteo='curl -4 http://wttr.in/Paris'` — a personal alias for the user's specific context. This must be removed before any commit.

2. **Update macos.zsh.example to use `command -v brew` guard.** The current line 8 pattern is outdated. Replace with the correct, portable guard pattern documented in architecture §4: `command -v brew >/dev/null 2>&1 && eval "$(brew shellenv)"`.

After these two fixes, both documents are ready for planner review and implementation.

---

## Follow-up Review: Pre-Plan Consistency Fix

**Date:** 2026-06-19
**Scope:** Homebrew pattern fix + personal alias removal

### Findings

None.

### Checklist

- [x] `YOUR_HOMEBREW_PREFIX` does not appear in `stow/common/zsh/.config/zsh/macos.zsh.example` — PASS
- [x] `YOUR_HOMEBREW_PREFIX` does not appear in `docs/prd/0010-real-zsh-configuration.md` — PASS
- [x] Architecture-0010 §4 references to `YOUR_HOMEBREW_PREFIX` are historical/descriptive only — PASS
- [x] `macos.zsh.example` contains `command -v brew >/dev/null 2>&1 && eval "$(brew shellenv)"` — PASS
- [x] PRD macOS-Specific Strategy describes the `command -v brew` guard — PASS
- [x] PRD and architecture §4 are now consistent on the Homebrew pattern — PASS
- [x] `alias meteo` does not appear in `zshrc.example` — PASS
- [x] No other personal aliases, real names, emails, or private values introduced — PASS
- [x] No $HOME modifications introduced — PASS
- [x] No Stow commands introduced — PASS
- [x] No dependency install introduced — PASS
- [x] No network access at shell startup introduced — PASS

### Verdict

**Approved.**

Both reviewer findings from review-0033 have been addressed. Homebrew pattern is now portable and consistent across all documents; personal alias removed. Ready for planning.
