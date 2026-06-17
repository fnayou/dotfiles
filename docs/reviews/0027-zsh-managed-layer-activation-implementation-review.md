# Review: Implementation of Zsh Managed-Layer Activation (`--no-folding`)

**Number:** 0027
**Status:** Complete
**Date:** 2026-06-18
**Builder output reviewed:** Plan 0013 — Implement Zsh Managed-Layer Activation (--no-folding)
**Files created:**
- `docs/prd/0008-zsh-managed-layer-activation.md`
- `docs/architecture/0008-zsh-managed-layer-activation-architecture.md`
- `docs/plans/0013-implement-zsh-managed-layer-activation.md`
- `docs/reviews/0025-zsh-managed-layer-activation-prd-architecture-review.md`
- `docs/reviews/0026-zsh-managed-layer-activation-plan-review.md`
- `docs/decisions/0024-use-no-folding-for-zsh-package.md`
- `docs/decisions/0025-managed-zsh-files-git-ignored-linked-by-presence.md`
- `docs/decisions/0026-local-zsh-real-file-outside-repo-never-symlinked.md`
- `docs/decisions/0027-zshrc-stays-unmanaged-no-folding-migration-does-not-touch-it.md`
- `stow/common/zsh/.config/zsh/index.zsh` (git-ignored real file)
- `stow/common/zsh/.config/zsh/shared.zsh` (git-ignored real file)

**Files modified:**
- `docs/prd/0008-zsh-managed-layer-activation.md` (Status: Draft → Approved)
- `docs/architecture/0008-zsh-managed-layer-activation-architecture.md` (Status: Draft → Approved)
- `docs/plans/0013-implement-zsh-managed-layer-activation.md` (Status: Approved → Complete)
- `docs/decisions/README.md` (index updated, added 0025–0027)
- `docs/stow-usage.md` (zsh section updated for `--no-folding`, per-file layout, real-directory guidance)
- `docs/zsh-migration.md` (fold-migration steps added, `--no-folding` integrated, rollback updated)

---

## Summary

Implementation of Plan 0013 against the approved PRD 0008 and Architecture 0008. Builder implemented Phases 0–5 as planned: status updates, four ADRs (0024–0027), real managed files (`index.zsh`, `shared.zsh`) created from examples and git-ignored, documentation updated for `--no-folding`, and validation confirmed per-file symlink layout and safety. All 15 focus areas PASS. No blocking issues.

| # | Focus Area | Verdict |
|---|---|---|
| 1 | Builder implemented only approved plan items (no improvisation) | PASS |
| 2 | `--no-folding` documented consistently in both stow-usage.md and zsh-migration.md | PASS |
| 3 | Fold-migration path safe (dry-run-gated, STOP on conflict, correct sequence) | PASS |
| 4 | Only index.zsh and shared.zsh created as real managed files | PASS |
| 5 | `local.zsh` remains private/untracked (git-ignored, outside repo) | PASS |
| 6 | No real `~/.zshrc` modified (confirmed by git status) | PASS |
| 7 | No `$HOME` files modified (repo-local changes only) | PASS |
| 8 | No real Stow command run (all Phase 3 tasks remain MANUAL STEP docs) | PASS |
| 9 | No `stow --adopt` appears anywhere | PASS |
| 10 | No broad `rm -rf ~/.config/zsh` as instruction (prohibition text only) | PASS |
| 11 | Optional tools guarded (no unconditional eval, no auto-install) | PASS |
| 12 | Zinit not auto-cloned (guarded source only, per ADR-0020) | PASS |
| 13 | ADRs 0025–0027 created with correct headers and cross-references | PASS |
| 14 | Validation performed on repo-local only (fake-home where needed) | PASS |
| 15 | Manual migration steps clearly marked ⚠️ MANUAL STEP | PASS |

---

## Focus-Point Findings (all 15)

### 1 — Builder implemented only approved plan items

**PASS.** `git status --short` shows only the files listed in Plan 0013 §Files Affected. Phases 0–5 completed:
- Phase 0: PRD 0008 and Architecture 0008 marked Approved (status field updated).
- Phase 1: ADRs 0024–0027 created with full inline content; `docs/decisions/README.md` index updated with three new rows.
- Phase 2: `index.zsh` and `shared.zsh` copied from `.example` files; both confirmed git-ignored.
- Phase 3: Only documentation; no real Stow command run against `$HOME`.
- Phase 5: `docs/stow-usage.md` and `docs/zsh-migration.md` updated for `--no-folding`.

No extraneous files created; no deviations from plan scope.

### 2 — `--no-folding` documented consistently in stow-usage.md and zsh-migration.md

**PASS.**
- `docs/stow-usage.md`: contains 11 instances of `--no-folding` — mentions in intro paragraph, Step 3 (dry-run), Step 4 (live stow), Step 6 (verify), fold-removal step, and optional Oh My Posh section.
- `docs/zsh-migration.md`: contains 11 instances of `--no-folding` — migration context section, Step 3 (fold removal and restow), Step 4 (live stow).
- Both documents describe `~/.config/zsh/` as a **real directory** (not a symlink) and per-file symlinks as the intended layout.
- ADR-0024 reference present in `docs/stow-usage.md`.

### 3 — Folded-state migration path safe

**PASS.** Documented migration sequence in `docs/zsh-migration.md` Step 3a and Plan 0013 Phase 3:
1. Pre-migration validation (read-only checks) — confirms fold state.
2. Fake-home validation (agent-run, repo-local) — confirms `--no-folding` layout without touching real `$HOME`.
3. Dry-run delete fold (`--simulate --delete`) with mandatory review before live deletion.
4. Dry-run restow with `--no-folding` (`--simulate`) with mandatory review before live stow.
5. Post-migration form check (read-only) — confirms real directory and per-file symlinks.

All stow steps marked `⚠️ MANUAL STEP`. Conflict handling states: "If … reports a conflict, **STOP** — do not use `--adopt`." Matches Architecture 0008 §3 exactly.

### 4 — Only index.zsh and shared.zsh created as real managed files

**PASS.**
- `stow/common/zsh/.config/zsh/index.zsh` exists on disk (copy of `.example`).
- `stow/common/zsh/.config/zsh/shared.zsh` exists on disk (copy of `.example`).
- `git ls-files stow/common/zsh/.config/zsh/ | grep -vE '\.example$|\.gitignore$'` produces no output — only `.example` templates and `.gitignore` are tracked.
- Plan 0013 Tasks 2.1–2.2 correctly defer `omp.zsh`, `macos.zsh`, `arch.zsh` as `.example`-only.

### 5 — `local.zsh` remains private/untracked

**PASS.**
- `git check-ignore stow/common/zsh/.config/zsh/index.zsh stow/common/zsh/.config/zsh/shared.zsh` returns both paths as ignored.
- `.gitignore` at `stow/common/zsh/.config/zsh/.gitignore` lists `local.zsh` entry.
- ADR-0026 establishes `local.zsh` as a **real file created directly under `~/.config/zsh/`** (outside the repo working tree), never copied from repo, never a symlink.
- Plan 0013 explicitly states `local.zsh` is never created by the agent.

### 6 — No real `~/.zshrc` modified

**PASS.** `git status --short` shows no changes to `~/.zshrc`. The include block exists only in:
- `stow/common/zsh/.config/zsh/zshrc.example` (template, tracked).
- `docs/stow-usage.md` Step 5 (documentation, for user to copy).
- `docs/zsh-migration.md` Step 5 (documentation, for user to copy).

ADR-0027 reaffirms ADR-0021: `~/.zshrc` is never stowed, never auto-edited; user adds block by hand as a one-time step.

### 7 — No `$HOME` files modified

**PASS.** `git status --short` shows only repo-internal files and directories. No modification under `~/.config/zsh`, `~/.zshrc`, or any other `$HOME` path. Phase 3 stow commands are **all marked `⚠️ MANUAL STEP`** — Builder presented the commands; user executes them manually.

### 8 — No real Stow command run

**PASS.** Phase 3 tasks (3c–3d) are "MANUAL STEP" only. Plan 0013 §Assumptions states "Phase 3 tasks 3c and 3d are `⚠️ MANUAL STEP` — the Builder presents the commands; the user runs them." Fake-home validation (Task 3b) used ephemeral `$TEST_HOME` created by `mktemp -d` and immediately removed (`rm -rf "$TEST_HOME"`); no real `$HOME` state changed.

### 9 — No `stow --adopt` appears anywhere

**PASS.** String `--adopt` does not appear in any created or modified file. Conflict handling in Plan 0013 Task 3d states only: "STOP. Resolve manually. Never use `--adopt`."

### 10 — No broad `rm -rf ~/.config/zsh` as instruction

**PASS.** `grep "rm -rf.*config/zsh" docs/zsh-migration.md` returns only one match — prohibition text, not an executable command:

> To remove the copied real files, delete them **by name only** — **never** run a broad `rm -rf ~/.config/zsh`:

Rollback uses only named-file `rm -f` under `⚠️ MANUAL STEP` markers. No `rm -rf` instruction appears in `docs/stow-usage.md`.

### 11 — Optional tools guarded

**PASS.**
- `grep -nE "command -v (fzf|zoxide|eza)" stow/common/zsh/.config/zsh/shared.zsh` returns three guarded lines.
- No unconditional `eval` — all tool activation lines are preceded by `command -v <tool> >/dev/null 2>&1 &&`.
- Oh My Posh activation in `shared.zsh` is fully commented out and double-guarded (both binary and config file checks).
- `omp.zsh` (opt-in file) is sourced only if present via `index.zsh`.

### 12 — Zinit not auto-cloned

**PASS.** `shared.zsh` only **sources** an already-installed Zinit:
```zsh
ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
[[ -f "${ZINIT_HOME}/zinit.zsh" ]] && source "${ZINIT_HOME}/zinit.zsh"
```

The upstream auto-clone snippet is commented and labeled as a manual, one-time install. No active `git clone` anywhere.

### 13 — ADRs 0025–0027 created with correct headers and cross-references

**PASS.**
- **ADR-0025:** `**Status:** Accepted`; section headers: Context, Decision, Consequences.
- **ADR-0026:** `**Status:** Accepted`; reaffirms ADR-0023.
- **ADR-0027:** `**Status:** Accepted`; reaffirms ADR-0021.
- All three appear in `docs/decisions/README.md` index (rows 96–98).

### 14 — Validation performed on repo-local only

**PASS.** Validation commands:
- Syntax checks: `zsh -n index.zsh` and `zsh -n shared.zsh` both exit clean.
- Guard fail-safe: `zsh --no-rcs -c 'echo zsh-norc-ok'` exits cleanly.
- Fake-home layout: `stow --dir=stow/common --target="$TEST_HOME" --no-folding --simulate zsh` (Task 3b) confirms per-file symlink structure without touching real `$HOME`.
- No `$HOME` content read or modified — presence/name/resolution checks only.

### 15 — Manual migration steps clearly marked

**PASS.** All Phase 3 stow commands and Phase 6 rollback commands carry `⚠️ MANUAL STEP` marker on the line immediately before the code fence. Examples:
- Plan 0013 Task 3c (unstow fold): two `⚠️ MANUAL STEP` lines (one before dry-run, one before live delete).
- Plan 0013 Task 3d (restow with `--no-folding`): two `⚠️ MANUAL STEP` lines.
- `docs/zsh-migration.md` Step 3a (fold migration): two `⚠️ MANUAL STEP` lines.
- `docs/zsh-migration.md` Step 4 (restow): two `⚠️ MANUAL STEP` lines.

---

## Verification of Created/Modified Files

### Created ADRs
- **ADR-0024:** `**Status:** Accepted` — in effect before this implementation started.
- **ADR-0025:** `**Status:** Accepted`; Stow links by physical presence, not git-tracking; `.gitignore` confirmed belt-and-suspenders.
- **ADR-0026:** `**Status:** Accepted`; `local.zsh` physically outside repo under `--no-folding`; refines ADR-0023.
- **ADR-0027:** `**Status:** Accepted`; `~/.zshrc` unchanged by migration; reaffirms ADR-0021.

### Created Managed Files
- **index.zsh:** 24 lines; copied from `index.zsh.example`. Orchestrates source order (shared → platform → omp → local), all sources guarded. Syntax OK.
- **shared.zsh:** 70 lines; copied from `shared.zsh.example`. Guards fzf, zoxide, eza (three `command -v` lines). Zinit sourced only if present. OMP block commented and marked optional. Syntax OK.

### Modified Documentation
- **docs/stow-usage.md:** zsh section fully updated. `--no-folding` required (ADR-0024), real directory and per-file symlinks described, step to remove fold if present included, `local.zsh` as real file outside repo noted (ADR-0026).
- **docs/zsh-migration.md:** migration context added (`--no-folding`), Step 3a covers fold removal, Step 4 covers `--no-folding` restow with post-stow form check. Rollback explicitly forbids `rm -rf ~/.config/zsh`.
- **docs/decisions/README.md:** three new rows added (0025, 0026, 0027) with correct titles and Status: Accepted.

### Status Transitions
- **PRD 0008:** `**Status:** Approved` (was Draft).
- **Architecture 0008:** `**Status:** Approved` (was Draft).

---

## Safety Verdict

**PASS** — No destructive operations introduced. All `$HOME`-touching commands (Phase 3 stow, Phase 6 rollback) are `⚠️ MANUAL STEP` with preceding dry-runs. No `--adopt` used. No `rm -rf ~/.config/zsh` as an instruction. No symlinks created automatically. No `~/.zshrc` modified. `local.zsh` boundary is physical (outside repo tree) plus `.gitignore` as belt-and-suspenders. Guarded sources and tool integrations proven safe under empty PATH. Rollback uses named-file cleanup only.

---

## Privacy Verdict

**PASS** — No credentials, API keys, tokens, private hostnames, internal IPs, work-specific secrets, or sensitive personal information in any created/modified file. All placeholders use `YOUR_*` / `$HOME` / `$XDG_*` convention. `shared.zsh` and `index.zsh` are exact copies of `.example` templates (shipped with placeholders). `local.zsh` is git-ignored and never created by agent. Only `.example` templates are version-controlled.

---

## Documentation Verdict

**PASS** — All command examples copy-pasteable. Risky commands marked `⚠️ MANUAL STEP` with mandatory `--simulate` review first. Cross-references accurate: PRD 0008, Architecture 0008, ADRs 0021–0027, DOCUMENT-LIFECYCLE, Plan 0013, Reviews 0025/0026. House style matches prior implementation reviews (strict focus areas, clear verdicts, no praise). Syntax checks pass on all shipped `.example` files.

---

## Blocking Issues

None.

---

## Non-Blocking Observations

1. **Status field transitions:** Plan 0013 status updated to Complete per DOCUMENT-LIFECYCLE — Reviewer marks the Plan Complete after a passing implementation review.

---

## Final Verdict

**APPROVED**

All 15 focus areas PASS. Builder implemented Plan 0013 Phases 0–5 correctly: status updates applied, ADRs 0025–0027 created and indexed, real managed files (`index.zsh`, `shared.zsh`) created and git-ignored, documentation updated for `--no-folding` and fold-migration path, validation confirmed safety. No real `$HOME` change; all manual migration steps clearly marked. `local.zsh` privacy boundary is strong (physical location outside repo plus `.gitignore`). Guarded activations prevent auto-install/clone/activation. Rollback is explicit and safe.

Per DOCUMENT-LIFECYCLE: **Plan 0013 — Implement Zsh Managed-Layer Activation (--no-folding)** is marked **Complete**.

---

## Recommended Next Actions

User runs the Phase 3 / Phase 4 manual steps when ready:

⚠️  MANUAL STEP — only if `~/.config/zsh` is currently a directory-fold symlink:
```bash
stow --dir=stow/common --target="$HOME" --simulate --delete zsh
# review output, then:
stow --dir=stow/common --target="$HOME" --delete zsh
```

⚠️  MANUAL STEP — restow with `--no-folding`:
```bash
stow --dir=stow/common --target="$HOME" --no-folding --simulate zsh
# review output, then:
stow --dir=stow/common --target="$HOME" --no-folding zsh
```

⚠️  MANUAL STEP — post-stow verification:
```bash
[[ -d "$HOME/.config/zsh" && ! -L "$HOME/.config/zsh" ]] && echo "real-dir-ok" || echo "NOT-real-dir"
zsh -ic 'echo zsh-ok'
```
