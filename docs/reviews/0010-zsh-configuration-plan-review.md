# Review: Zsh Configuration Implementation Plan

**Number:** 0010
**Status:** Complete
**Date:** 2026-06-17
**Reviewer:** Claude Code
**File reviewed:** docs/plans/0007-implement-zsh-configuration-foundation.md

---

## Verdict

**APPROVED** — Plan is conservative, safety-focused, and correctly implements all fixes from Review 0009. No blockers identified.

The plan correctly defers all modifications to `~/.zshrc`, restricts work to repository-scoped files, uses only `.example` files, and enforces directory-level `.gitignore` protection. All 8 tasks are low-risk, validation steps are read-only, and rollback strategy is complete. Cross-platform separation (macOS/Arch) is maintained. No Stow install is executed — only `--simulate` optional.

---

## Findings

**Task 1 (ADR-0016):** docs/decisions/0016-zsh-common-package-runtime-os-detection.md — NEW

**L105 — 🔵 NOTE:** Plan correctly specifies `$ZDOTDIR` deferral. ARCH-L25 fix from Review 0009 is carried forward in the language: "OS detection via `$OSTYPE`, `/etc/arch-release` in the user's `~/.zshrc` source block. `~/.zshrc` is never stowed."

---

**Task 3 (shared.zsh.example):** stow/common/zsh/.config/zsh/shared.zsh.example — NEW

**L148–181 — 🔵 NOTE:** Content scaffold is correct. Only portable items included:
- XDG variables (safe on both platforms)
- History, completion, options (portable zsh)
- Comment explicitly forbids brew, pacman, systemctl, plugin managers

Forbidden tokens explicitly checked in validation (L189–191).

---

**Task 4 (macos.zsh.example):** stow/common/zsh/.config/zsh/macos.zsh.example — NEW

**L206–222 — ✓ PASS:** Homebrew placeholder fix from Review 0009 (ARCH-L223) correctly applied.

**L212:** Literal placeholder marker present: `# YOUR_HOMEBREW_PREFIX is a LITERAL placeholder, NOT a shell variable.`

**L214:** Uses safe syntax: `eval "$(YOUR_HOMEBREW_PREFIX/bin/brew shellenv)"` — when user replaces `YOUR_HOMEBREW_PREFIX` with an actual path (`/opt/homebrew` or `/usr/local`), the result is valid shell.

Cross-platform separation verified: validation (L227–229) confirms no Arch tokens (pacman, yay, systemctl, /etc/arch-release).

---

**Task 5 (arch.zsh.example):** stow/common/zsh/.config/zsh/arch.zsh.example — NEW

**L249–260 — ✓ PASS:** Arch-specific only. Validation (L265–267) confirms no macOS/Homebrew tokens.

---

**Task 6 (.gitignore):** stow/common/zsh/.config/zsh/.gitignore — NEW

**L272–302 — ✓ PASS:** Directory-level `.gitignore` implementation (Review 0009 ARCH-L334–340 fix).

**L296–300:** Validation command correctly tests git-ignore behavior. Critical: **all three commands in this task stay within repository scope** — the test `cp`, test `git check-ignore`, and test `rm` all operate on `stow/common/zsh/.config/zsh/` (repo-scoped), not `$HOME`.

---

**Task 7 (stow-usage.md update):** docs/stow-usage.md — MODIFIED (append section)

**L306–373 — ✓ PASS:** Mandatory update per Review 0009 (ARCH-L232). Content is complete:

1. **Files table (L314–119):** Maps `.example` → real name and Stow symlink target.
2. **Copy step (L317–323):** Uses repo-root-relative paths (`stow/common/zsh/.config/zsh/...`), all in-repo. Matches Review 0009 ARCH-L330 fix.
3. **Review step (L325):** User confirms placeholders and no secrets.
4. **Dry-run step (L326–336):** Shows both `task` and direct `stow` commands with `--simulate` only.
5. **Stow install step (L338–343):** Marked `⚠️ MANUAL STEP`. **Critical:** Real stow command shown but NOT run by the plan.
6. **~/.zshrc source block (L345–356):** Manual user step. OS detection uses documented pattern (`$OSTYPE`, `/etc/arch-release`). **Critical:** No modification to `~/.zshrc` by the plan itself.
7. **Verify step (L358–363):** Read-only `ls -l` and `zsh -ic` checks (local-only, reversible).

Also updates layout tree (L365) to show `zsh/` under `common/` — correct.

---

**Task 8 (status updates):** Multiple files — Status/index updates

**L376–395 — 🟡 MINOR:** Task 8 references but plan does not list exact files. Reading L378–382 shows:

- `docs/prd/0004-zsh-configuration.md` — Status → Approved
- `docs/architecture/0004-zsh-configuration-architecture.md` — Status → Accepted; ADR-0016 row Status → Accepted
- `docs/plans/README.md` — add 0007 entry
- `docs/decisions/README.md` — add 0016 entry

This is correct. Validation (L388–395) is sufficient. Not a blocker — minor clarity issue only.

---

## Cross-Check: Safety, Privacy, Stow, Cross-Platform Rules

### Safety Rules (from .claude/rules/safety.md)

✓ **Never modify `~/.zshrc`** — Confirmed. Plan explicitly defers bootstrap source-block to Phase 4 user action (Task 7 L345–356, L375–376).

✓ **No `rm`, `mv` against `$HOME`** — Confirmed. Task 6 validation (L296–300) uses `rm` only on repo-scoped `stow/common/zsh/.config/zsh/shared.zsh` (test copy, immediately deleted).

✓ **No symlinks created in `$HOME`** — Confirmed. Task 7 notes "no symlink was created in `$HOME`" as part of Safety Checks (L438). Real stow invocation is user-manual (marked `⚠️`), not executed by the plan.

✓ **No `stow --adopt`** — Confirmed. No `--adopt` anywhere. Only `--simulate` used; real stow is marked manual.

✓ **No modifications outside repository root** — Confirmed. All files created under `stow/common/zsh/` and `docs/`.

✓ **Dry-run before install** — Confirmed. Task 7 (L326–336) shows `--simulate` step.

✓ **Dangerous commands marked** — Confirmed. Stow install (L338–343) and `~/.zshrc` edit (L345–356) both marked `⚠️ MANUAL STEP`.

### Privacy Rules (from .claude/rules/privacy.md)

✓ **No real secrets, tokens, keys** — Confirmed. All `.example` files. Task 3 validation (L189–191) rejects brew/pacman/systemctl. Task 4 uses `YOUR_HOMEBREW_PREFIX` literal placeholder (L212). Task 5 uses `YOUR_ARCH_TOOL_PATH`, `YOUR_AUR_HELPER` placeholders.

✓ **Placeholder values** — Confirmed. All examples use `YOUR_*`, `$HOME`, `$XDG_*` conventions. Documented in comments (Task 3 L148–150, Task 4 L208–209, Task 5 L251–252).

✓ **Audit before staging** — Covered by full-suite validation (L399–428). All files checked for forbidden tokens. Safety Checks (L432–446) confirm no real values in committed files.

✓ **No real hostnames, paths, or personal data** — Confirmed. Validation explicitly forbids "token", "password", "secret", "ssh-rsa", "BEGIN OPENSSH" (L418–419).

### Stow Rules (from .claude/rules/stow.md)

✓ **Package-based layout** — Confirmed. `stow/common/zsh/` is the only package created, satisfying ADR-0001 criteria.

✓ **Explicit `--dir` and `--target`** — Confirmed. Task 7 uses `stow --dir=stow/common --target="$HOME" zsh` format (L335, L342). (Note: plan says `--dir=stow/common` not bare `--dir=stow`, which is correct per AGENTS.md §11 and architecture.)

✓ **`--simulate` before install** — Confirmed. Task 7 L326–336 shows dry-run first. Install marked manual (L338–343).

✓ **No `.example` files stowed directly** — Confirmed. Task 6 .gitignore ignores real filenames (L285–287). Task 7 copy step (L317–323) is user-manual. Validation (L422–423) confirms only `.example` files in git status.

✓ **No `--adopt`** — Confirmed. No `--adopt` in the entire plan.

✓ **No flat `stow .`** — Confirmed. Only `stow --dir=stow/common --target="$HOME" zsh` used.

### Cross-Platform Rules (from .claude/rules/cross-platform.md)

✓ **macOS and Arch separated** — Confirmed. Three files: `shared.zsh.example`, `macos.zsh.example`, `arch.zsh.example` (Tasks 3–5).

✓ **No Homebrew in shared** — Confirmed. Task 3 validation (L189–191) explicitly forbids brew. macOS-only items in Task 4.

✓ **No pacman/yay in shared** — Confirmed. Task 3 validation (L189–191) forbids pacman/yay. Arch-only items in Task 5.

✓ **OS detection explicit** — Confirmed. Task 7 L349–355 provides documented bootstrap snippet using `$OSTYPE` and `/etc/arch-release` pattern (matches cross-platform.md).

✓ **No hardcoded paths** — Confirmed. All placeholders use `$HOME`, `$XDG_CONFIG_HOME`, `YOUR_*` tokens (Task 3 L154–156, Task 4 L211–218, Task 5 L256).

✓ **Paths portable** — Confirmed. `~/.config/zsh/` is identical on both platforms. No `/opt/homebrew` or Arch-specific paths in shared config.

---

## Validation Commands & Execution Safety

**Pre-Implementation Checklist (L35–65)** — 7 commands, all read-only ✓

**Task 1 validation (L109–114)** — 2 commands:
- `ls docs/decisions/0016-*.md` — read-only ✓
- `grep -n "Status" docs/decisions/0016-*.md` — read-only ✓

**Task 2 validation (L130–132)** — 1 command:
- `test -d stow/common/zsh/.config/zsh && echo "OK: package dir exists"` — read-only ✓

**Task 3 validation (L185–191)** — 1 command:
- `grep` to forbid framework tokens — read-only ✓

**Task 4 validation (L224–234)** — 3 commands:
- 2x `grep` to forbid Arch/Homebrew tokens — read-only ✓
- 1x `grep` to confirm "literal placeholder" comment — read-only ✓

**Task 5 validation (L262–267)** — 1 command:
- `grep` to forbid macOS/Homebrew tokens — read-only ✓

**Task 6 validation (L290–301)** — 3 commands:
- `cat stow/common/zsh/.config/zsh/.gitignore` — read-only ✓
- `cp stow/common/zsh/.config/zsh/shared.zsh.example stow/common/zsh/.config/zsh/shared.zsh` — **repo-scoped, local test** ✓
- `git check-ignore stow/common/zsh/.config/zsh/shared.zsh` — read-only ✓
- `rm stow/common/zsh/.config/zsh/shared.zsh` — **cleanup of test file, repo-scoped** ✓

**Task 7 validation (L368–371)** — 2 commands:
- `grep` on `docs/stow-usage.md` — read-only ✓
- `grep` on source-block pattern — read-only ✓

**Full-suite validation (L399–428)** — 5 commands:
- Directory check ✓
- `ls` package contents ✓
- `grep -rn` forbidden frameworks — read-only ✓
- `grep -n` shared.zsh for forbidden tokens — read-only ✓
- `grep -rn` no secrets — read-only ✓
- `git status --porcelain` confirm only .example tracked — read-only ✓
- Optional stow `--simulate` commented out (user-manual Phase 4) ✓

**All validation commands are safe and stay within repository scope.**

---

## Rollback Strategy (L449–477)

✓ **If uncommitted:** Removes `stow/common/zsh/`, `docs/decisions/0016-*.md`, reverts doc edits. Complete and correct.

✓ **If committed (not pushed):** Uses `git revert` or `git reset --hard HEAD~1` on feature branch. Correct.

✓ **User-side rollback:** Notes not applicable to plan phase (Phase 4+ user action). References Architecture 0004 rollback strategy. Correct.

---

## Completion Criteria (L480–492)

All 12 criteria are measurable and aligned with the plan:

- [ ] ADR-0016 exists, Status: Accepted ✓
- [ ] `stow/common/zsh/.config/zsh/` contains exact files ✓
- [ ] `.gitignore` ignores real names, keeps `.example` ✓
- [ ] `shared.zsh.example` platform-clean ✓
- [ ] `macos.zsh.example` has Homebrew literal placeholder, no Arch tokens ✓
- [ ] `arch.zsh.example` has no macOS tokens ✓
- [ ] `docs/stow-usage.md` has zsh section ✓
- [ ] Status flips and README updates ✓
- [ ] All validation commands pass ✓
- [ ] All Safety Checks ticked ✓
- [ ] No `$HOME` change, no symlink, no stow install, no framework, no `~/.zshrc` access ✓

---

## Alignment with Review 0009 Fixes

Plan correctly incorporates all findings from Review 0009:

| Review 0009 Finding | Plan Implementation | Status |
|---|---|---|
| **ARCH-L223** — Homebrew placeholder syntax | Task 4 L212–214: Comment marks `YOUR_HOMEBREW_PREFIX` as literal placeholder, safe shell syntax | ✓ APPLIED |
| **ARCH-L232** — `stow-usage.md` update mandatory | Task 7: Complete zsh package adoption section with copy, review, dry-run, stow, source-block, verify steps | ✓ APPLIED |
| **ARCH-L334–340** — Directory-level `.gitignore` | Task 6: `.gitignore` placed at `stow/common/zsh/.config/zsh/` with three entries | ✓ APPLIED |
| **ARCH-L330** — Path clarity | Task 7 L320–322: Paths are repo-root-relative, documented "relative to repository root" | ✓ APPLIED |
| **ARCH-L25** — `$ZDOTDIR` deferral clarity | Task 1 L105, Task 7 L345–356: Defers `$ZDOTDIR` to future; uses explicit `source` block; no `~/.zshrc` modification | ✓ APPLIED |

**All fixes from Review 0009 are correctly carried forward.**

---

## Scope & Conservatism Check

**8 tasks, 2 phases (ADR + Scaffold & Docs):**

1. ADR-0016 — 1 file (decision record) ✓
2. Package scaffold — 4 files (.example × 3, .gitignore) ✓
3. Documentation — 5 file updates (stow-usage.md, status fields, README entries) ✓

**Total: 9 files created/modified, all in-scope, all low-risk.**

No out-of-scope additions. No frameworks introduced. No zsh behavior tuning. No plugin manager. No prompt theme. No `$HOME` changes.

**Scope is tight and conservative.** ✓

---

## Notable Strengths

1. **Pre-implementation checklist (L35–65):** Seven safety gates before work begins. Catches missing ADRs, missing plans, conflicting directory state.

2. **Task 6 validation (L296–300):** Test copy/git-ignore in-repo before real adoption. Ensures `.gitignore` works as expected before user phase.

3. **Full-suite validation (L399–428):** Comprehensive post-implementation checks covering package structure, forbidden tokens, secrets, git tracking status.

4. **Explicit Phase 4 deferral (L375–376, L345–356):** Bootstrap source-block and stow install are user-manual, explicitly marked, never run by plan.

5. **Rollback clarity (L449–477):** Distinguishes uncommitted (file removal), committed (git revert), and user-side (architecture reference) rollback scenarios.

6. **Cross-platform validation embedded in each task:** Each `.example` file validation (Tasks 3–5) explicitly checks for forbidden platform tokens.

---

## Minor Observations

1. **Task 8 description (L376–395):** Could list exact files being modified for clarity, but validation commands are sufficient to verify.

2. **Stow directory path notation (L335, L342):** Uses `--dir=stow/common` not bare `--dir=stow`. This is correct per architecture and ADR-0001 (platform-first layout), but worth noting the plan deviates from the generic `stow.md` template which shows `--dir=stow`. Plan is correct; template is generic.

---

## Summary

| Severity | Count | Details |
|---|---|---|
| 🔴 BLOCKER | 0 | None. Plan is safe and ready. |
| 🟠 MAJOR | 0 | None. All safety, privacy, Stow, and cross-platform rules followed. |
| 🟡 MINOR | 1 | Task 8 file list could be more explicit (non-blocking). |
| 🔵 NOTE | 2 | Review 0009 fixes correctly applied; cross-platform separation well-maintained. |

---

## Recommended Next Step

**Builder implements Plan 0007 following all task descriptions and validation steps.** Pre-implementation checklist (L35–65) must pass before any file creation. All 8 tasks are low-risk and safe to execute in order.

