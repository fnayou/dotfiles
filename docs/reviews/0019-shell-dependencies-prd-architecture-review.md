# Review: Shell Dependency Management — PRD and Architecture

**Number:** 0019
**Status:** Complete
**Date:** 2026-06-17
**Documents reviewed:**
- `docs/prd/0006-shell-dependencies.md`
- `docs/architecture/0006-shell-dependencies-architecture.md`

---

## Summary

Pre-implementation review of PRD 0006 and Architecture 0006 for shell dependency management. No code or scripts were built — this review validates whether the design is sound, safe, and ready for planning.

---

## Safety Checks

### Shell startup is free of installs

- PRD §Safety Requirements explicitly forbids install, `brew bundle`, `git clone`, and network commands in shell startup.
- Architecture §"Why Shell Startup Must Not Install Tools" records five independent reasons and states the rule load-bearingly.
- Decision 5 mandates guarded activation for every tool: `command -v fzf >/dev/null 2>&1 && eval "$(fzf --zsh)"`.
- Decision 6 explicitly rejects the upstream zinit auto-clone-on-startup pattern and forbids it in the zsh config.

**PASS**

### Package install / dotfile activation separation

- Architecture formalises three verbs in a table: Check (read-only), Install (manual), Activate (guarded). These are distinct owners, triggers, and side-effect levels.
- Decision 4 keeps `deps:macos:shell` as a print-only task — it shows the `brew bundle` command with a `⚠️  MANUAL STEP` marker and exits without executing it.
- ADR-0009 no-mutation constraint is explicitly acknowledged and not lifted.

**PASS**

### No $HOME modification

- PRD Non-Goals list: "Do not modify `$HOME` or any path outside the repository."
- Architecture Constraints (carried verbatim): "Do not modify `~/.zshrc`, `$HOME`, or any path outside the repository."
- Proposed structure creates only `packages/macos/`, `scripts/check-zsh-deps.sh`, and `Taskfile.yml` entries — all inside the repo.
- Rollback section explicitly states no rollback step touches `$HOME` automatically.

**PASS**

### Zinit not auto-cloned

- PRD §Safety Requirements: "Must not auto-clone `zinit` from `~/.zshrc` or any sourced file."
- Architecture Decision 6: upstream auto-clone option is documented and **rejected outright**. The manual clone command is shown with `⚠️  MANUAL STEP`, not executed. The zsh config only sources zinit behind a directory-existence guard — never clones.

**PASS**

### Risky commands marked correctly

- PRD shows the only install example with `⚠️  MANUAL STEP — review before running` directly preceding the code block. Format matches documentation rules.
- Architecture Decision 6 zinit clone example carries the same marker.
- Rollback `rm -rf "${ZINIT_HOME}"` is explicitly labelled a `⚠️  MANUAL STEP, user-run only`.

**PASS**

### No stow --adopt, no rm/mv against $HOME

- Neither document introduces any stow, rm, mv, or ln -s command targeting $HOME.
- All stow references in the architecture are qualified with existing Stow safety rules (ADR-0017, fake-home --simulate only).

**PASS**

---

## Privacy Checks

- Brewfiles are planned to contain only public formula/cask/tap names (e.g. `jandedobbeleer/oh-my-posh/oh-my-posh`). No private taps, no tokens.
- Architecture Safety and Privacy section explicitly states scripts use `$HOME`/`$XDG_DATA_HOME` — no hardcoded paths revealing username or machine layout.
- Zinit clone URL in Decision 6 is a public GitHub URL — no credentials, no private registry.
- Both documents contain no API keys, tokens, passwords, SSH content, or internal hostnames.
- Architecture correctly notes Brewfiles do not need `.example` treatment because they are public package manifests (consistent with ADR-0003 intent for credential-bearing files only).

**PASS**

---

## macOS / Arch Separation Checks

- PRD §Arch Package Strategy: "Planned, not implemented. No Arch files are created." Future illustrative layout shown as comment-only prose.
- Architecture Decision 3 explicitly rejects scaffolding `packages/arch/` and records that no Arch directory is created by this architecture.
- Tool-by-Tool table separates macOS source and Arch source (future) columns — no mixing.
- `check-zsh-deps.sh` design: tool detection via `command -v` (platform-neutral), install hints via OS detection (`detect-os.sh` logic) — Homebrew hints only on macOS, pacman/paru hints only on Arch.
- ADR-0007 tension (illustrative category list vs. `core/shell/optional`) is explicitly handled by proposing ADR-0018 — not silently ignored.

**PASS**

---

## Documentation Checks

- PRD §Dependency Tiers table: all eight required tools appear with correct tier assignment. `zinit` special-case (not a Homebrew formula) is noted.
- PRD §Bootstrap Strategy: four-step flow is clear and copy-pasteable. Manual `brew bundle` step is shown, not implicit.
- Architecture §Tool-by-Tool Handling: comprehensive table covering all eight tools with tier, macOS source, Arch source, activation method, and checker detection method.
- Architecture §Proposed Structure: ASCII tree clearly shows what is new vs. existing.
- Architecture §ADRs to Create: three ADRs (0018, 0019, 0020) are correctly identified with rationale. These must be written as part of the implementation plan.
- `⚠️  MANUAL STEP` markers appear on the line directly preceding fenced code blocks for dangerous commands — consistent with documentation rules.

**PASS**

---

## Scope Check

- PRD scope is documentation-only — no files outside `docs/prd/` are created by this PRD. Correct.
- Architecture scope is design-only — no Brewfiles, scripts, or Taskfile changes are made by the architecture document. Correct.
- Both documents are appropriately narrow: they define and decide, they do not build.
- The "recommended next step" in Architecture correctly delegates implementation to the Planner (docs/plans/0006-shell-dependencies-plan.md). Correct sequencing.

**PASS**

---

## Blocking Issues

None.

---

## Non-Blocking Suggestions

1. **PRD §Last acceptance criterion** (`PRD is reviewed and approved before architecture work begins`) is already superseded in practice — architecture was written before this review. The criterion is technically unfulfillable as written. Consider replacing it with `Architecture 0006 reviewed and approved before planning begins` in the final PRD update.

2. **Architecture Open Question 3** (where to document the zinit clone command and `brew bundle` steps) should be decided at plan time before writing the plan, not left open during the plan phase. Recommend: a dedicated `docs/shell-dependencies.md` (separate from `docs/stow-usage.md`) since the content is about dependency setup, not Stow symlink management.

3. **Architecture §Rollback**: `brew bundle cleanup` is listed as listing what "would be removed." In practice `brew bundle cleanup` without `--dry-run` removes packages. Consider clarifying the safe form is `brew bundle cleanup --dry-run --file=...` in the architecture prose, so the plan documents it correctly.

4. **Tool table, `go-task` Arch source**: listed as `pacman`/AUR. `go-task` is not in the official Arch repos and is typically AUR-only (`go-task` or `task-bin`). Minor — this is future/illustrative, but accuracy matters when Arch is implemented.

5. **PRD §Bootstrap Strategy** mentions `task packages:macos:shell` but Architecture Decision 4 names the task `deps:macos:shell`. Naming diverges between the two documents. The architecture name (`deps:macos:shell`) is better-structured and should be the canonical one. PRD reference is illustrative only, but the inconsistency could confuse the Planner. Flag for PRD status update when approved.

---

## Safety Verdict

**PASS** — No automatic installation, no `$HOME` modification, no startup side effects, all risky commands marked. Guarded activation and manual-only install path are enforced at the design level.

## Privacy Verdict

**PASS** — No credentials, tokens, private hostnames, or sensitive values in either document. Brewfiles correctly treated as public package manifests.

## Documentation Verdict

**PASS** — All required sections present, dangerous commands marked, platform separation clean, tool coverage complete, ADR gaps identified. One naming inconsistency (non-blocking, noted above).

---

## Recommended Next Action

Approve both documents (flip `**Status:** Draft` → `**Status:** Approved` in PRD 0006 and Architecture 0006). Then invoke the `create-plan` skill to produce `docs/plans/0006-shell-dependencies-plan.md`.

Plan must address:
- Resolve Open Question 3 (docs location for zinit and brew bundle instructions) before writing steps.
- Use `deps:macos:shell` as the canonical task name (not `packages:macos:shell`).
- Use `brew bundle cleanup --dry-run` in rollback documentation (Non-Blocking Suggestion 3).
- Write ADR-0018, ADR-0019, ADR-0020 as explicit plan steps.

---

## Corrections Review — 2026-06-17

Follow-up review of non-blocking documentation corrections applied to PRD 0006 and Architecture 0006 after the initial review above.

### Correction 1 — Task naming consistency (`task deps:macos:shell`)

**PRD §Bootstrap Strategy**: `task packages:macos:shell` → `task deps:macos:shell`. Correct.
**PRD §Out of Scope**: `task packages:macos:shell` → `task deps:macos:shell`. Correct.
**PRD §Acceptance Criteria**: `task packages:macos:shell` → `task deps:macos:shell`. Correct.
Architecture task naming was already correct — unchanged.
All three PRD occurrences updated. No stale references to `packages:macos:shell` remain in either document.

**PASS**

### Correction 2 — `brew bundle cleanup` safety

**Architecture §Rollback Strategy**: original prose said `brew bundle cleanup --file=...` "lists what would be removed" — factually wrong; that form removes immediately.
Updated text now:
- prescribes `brew bundle cleanup --dry-run --file=...` as the safe preview form,
- states explicitly that omitting `--dry-run` removes packages immediately,
- directs actual removal to a deliberate manual `brew uninstall`.
Wording is accurate and matches the documentation rules for dangerous commands.

**PASS**

### Correction 3 — PRD acceptance criterion sequencing

**PRD §Acceptance Criteria** last item: was `PRD is reviewed and approved before architecture work begins` — unfulfillable because architecture was already written.
Updated to: `PRD and Architecture 0006 are reviewed together before planning begins`.
New wording is accurate, achievable, and aligns with the actual review sequence (PRD + Architecture reviewed together in this report).

**PASS**

### Correction 4 — Arch `go-task` accuracy

**Architecture §Tool-by-Tool Handling** table, `go-task` Arch column: was `pacman`/AUR — misleading because `go-task` is not in official Arch repos.
Updated to: `AUR (go-task or task-bin — not in official repos; resolve when Arch is implemented)`.
Accurate, clearly deferred, no pacman claim made.

**PASS**

### Scope confirmation

No Brewfiles, scripts, Taskfile changes, symlinks, or `$HOME` modifications were introduced by the corrections. Both files remain documentation-only. No implementation was added.

**PASS**

### Corrections verdict

All four non-blocking suggestions from the initial review are now resolved. No new issues introduced.

**Corrected documents are ready for approval. Planning can proceed.**
