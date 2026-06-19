# Review: Real Zsh Configuration Adoption Plan

**Document:** docs/reviews/0034-real-zsh-plan-review.md
**Reviewed:** docs/plans/0014-real-zsh-configuration-plan.md
**Against:** docs/prd/0010-real-zsh-configuration.md, docs/architecture/0010-real-zsh-configuration-architecture.md
**Reviewer:** Claude Code
**Date:** 2026-06-19
**Status:** Complete

---

## Verdict

**Approved with non-blocking notes**

The plan is thorough, well-structured, and faithful to the approved PRD and architecture. Safety constraints are upheld throughout: no `$HOME` files are touched during implementation, Stow is not run against the real home in any Builder step, and every command that touches `$HOME` in the guide is correctly marked `⚠️  MANUAL STEP`. Two non-blocking notes require attention: (1) the A5 validation command `grep -c 'source'` produces 8, not 4, because comments containing the word "source" are counted; and (2) `task dry-run AREA=common PACKAGE=zsh` is presented as equivalent to `stow --no-folding --simulate zsh` but the Taskfile's `dry-run` task does not pass `--no-folding`. Neither is a blocker, but both should be corrected before or during implementation.

---

## Blockers

None.

---

## Non-Blocking Notes

### Note 1 — A5 validation: `grep -c 'source'` produces 8, not 4

**Location:** Plan task A5, Validation block, line:
```bash
grep -c 'source' stow/common/zsh/.config/zsh/index.zsh
# Expected: 4 (one per source step)
```

**Problem:** `index.zsh` currently has 8 occurrences of the string `source`: four in active `source` calls and four in comments (header comment "source is guarded", and section comments "OS-detected, sourced only if present", "sourced LAST so it wins"). `grep -c 'source'` counts all lines containing the word, including comments. The validation would fail on a correct file.

**Correction:** Replace with a grep that matches only the active source calls:
```bash
grep -c '^\[\[.*\]\] && source ' stow/common/zsh/.config/zsh/index.zsh
# Expected: 4 (one per guarded source step)
```

Or count by checking each specific source step exists individually, as the other validation commands do.

---

### Note 2 — Guide section: `task dry-run AREA=common PACKAGE=zsh` omits `--no-folding`

**Location:** Plan task C1 (Guide section 5, Dry-run step):
```bash
task dry-run AREA=common PACKAGE=zsh
```

**Problem:** The Taskfile `dry-run` task (Taskfile.yml line 27) runs:
```bash
stow --dir=stow/{{.AREA}} --target="$HOME" --simulate {{.PACKAGE}}
```
It does not pass `--no-folding`. The guide presents this command as equivalent to:
```bash
stow --dir=stow/common --target="$HOME" --no-folding --simulate zsh
```
They are not equivalent. Running `task dry-run AREA=common PACKAGE=zsh` would simulate a folding stow — producing a single directory-symlink result, not per-file symlinks. The user would see a different dry-run output and potentially proceed with incorrect expectations. The same issue exists in `docs/stow-usage.md` (line 316), but that document is outside this plan's scope.

**Note:** The direct stow command shown immediately before the `task dry-run` line is correct:
```bash
stow --dir=stow/common --target="$HOME" --no-folding --simulate zsh
```

**Correction options (either is acceptable):**

Option A — Remove the `task dry-run` shortcut entirely from the zsh setup guide, leaving only the direct command that includes `--no-folding`.

Option B — Note inline that `task dry-run` does not include `--no-folding` and the direct command must be used for the zsh package:
```bash
# Use the direct command for the zsh package — task dry-run does not include --no-folding (ADR-0024):
stow --dir=stow/common --target="$HOME" --no-folding --simulate zsh
```

Option C — Update the Taskfile `dry-run` task to accept an optional `NO_FOLDING` variable. This is outside this plan's scope; if desired, it should be a separate task.

---

### Note 3 — `alias o='open'` remains commented out in current `macos.zsh.example`

**Location:** Plan task A1, step 3.

The plan instructs the Builder to "confirm or uncomment the `alias o='open'` line. It must be active (not commented out)." The current file has `# alias o='open'` (confirmed by reading `stow/common/zsh/.config/zsh/macos.zsh.example`). The plan correctly identifies this as a step the Builder must take. This note is a reminder that the current file state does require the edit — no risk of the Builder skipping it.

---

### Note 4 — `docs/stow-usage.md` contains an outdated OMP activation instruction

**Location:** `docs/stow-usage.md`, Step 7 under "Oh My Posh package adoption" (line ~582):
```zsh
[[ -f "$HOME/.config/zsh/omp.zsh" ]] && source "$HOME/.config/zsh/omp.zsh"
```
This instruction tells the user to add the OMP source guard to `shared.zsh` or `~/.zshrc`. But Architecture-0010 §5 and Plan task A3 establish that `index.zsh` already handles sourcing `omp.zsh` (step 3 of the source order). This is the same outdated instruction the plan removes from `omp.zsh.example`. The `stow-usage.md` file is not in this plan's scope (no file under Group A lists it), so this note is informational only — the Builder should be aware that `stow-usage.md` will need a follow-up update.

---

## Checklist Results

| # | Check | Result | Notes |
|---|-------|--------|-------|
| 1 | Plan follows approved PRD and architecture — no scope expansion | Pass | Scope strictly matches PRD-0010 goals. No new files or tasks outside what Architecture-0010 prescribed (Groups A, B, C, D). |
| 2 | `~/.zshrc` remains unmanaged — not in stow package, not modified | Pass | Plan explicitly states this in Overview (line 14) and in the guide's "What this package does NOT manage" section. No Builder step touches `~/.zshrc`. The include block in Guide section 7 is marked `⚠️  MANUAL STEP`. |
| 3 | `local.zsh` remains private/untracked | Pass | D9 validation checks `git ls-files stow/common/zsh/.config/zsh/local.zsh` must return nothing. ADR-0026 boundary is enforced by physical location. `.gitignore` is secondary. Guide section 8 creates it outside repo. |
| 4 | No `$HOME` files modified by any Builder step | Pass | Every Group A, B, C task carries explicit "No `$HOME` file is touched. Repository file only." safety check. Group D tasks are read-only. |
| 5 | No real-home Stow command run by Builder — only fake-home Stow | Pass | No Builder task runs `stow` against `$HOME`. D7 is the only stow command in validation and uses `TEST_HOME=$(mktemp -d)`. All `$HOME`-targeting stow commands are in the guide (Group C) and marked `⚠️  MANUAL STEP`. |
| 6 | Fake-home Stow validation uses `--no-folding` flag | Pass | D7 uses `stow --dir=stow/common --target="$TEST_HOME" --no-folding --simulate zsh`. |
| 7 | No dependency installation step introduced | Pass | Prerequisites section (lines 20–36) lists only zsh, stow, and git — read-only version checks. Guide section 3 lists optional tools with "not required" label. No install commands in Builder steps. |
| 8 | No network access during shell startup | Pass | D6 checks `grep -rE '(git clone|brew install|pacman -S|yay -S|pip install|npm install|curl .* \| (ba)?sh)'`. No startup file contains install commands. |
| 9 | Zinit is not auto-cloned — requires user approval | Pass | A4 verifies the Zinit source guard `[[ -f "${ZINIT_HOME}/zinit.zsh" ]] && source ...`. No auto-clone. Manual install is documented in `deps:macos:shell` Taskfile task (outside this plan). ADR-0020 enforced. |
| 10 | Optional tools are guarded | Pass | D5 validates all guards. A4 verifies fzf, zoxide, eza guards in `shared.zsh.example`. A1 verifies brew guard. A3 verifies oh-my-posh guard. |
| 11 | Homebrew shellenv uses `command -v brew` guard pattern | Pass | Plan A1 specifies `command -v brew >/dev/null 2>&1 && eval "$(brew shellenv)"` and confirms `YOUR_HOMEBREW_PREFIX` must not appear. Current `macos.zsh.example` already has this correct pattern (per Review-0033 follow-up). |
| 12 | Oh My Posh integration is guarded with `command -v oh-my-posh` | Pass | Plan A3 requires the double-guarded `if command -v oh-my-posh >/dev/null 2>&1 && [[ -f … omp.toml ]]; then` block (active, not commented). D5 validates guard presence. |
| 13 | fzf integration is guarded | Pass | A4 verifies `command -v fzf >/dev/null 2>&1 && eval "$(fzf --zsh)"` in `shared.zsh.example`. D5 validates. |
| 14 | zoxide integration is guarded with `command -v zoxide` | Pass | A4 verifies `command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"`. D5 validates. |
| 15 | eza aliases are guarded with `command -v eza` | Pass | A4 verifies `command -v eza >/dev/null 2>&1 && alias ls='eza'`. D5 validates. |
| 16 | PATH logic contains no private/machine-specific paths | Pass | `shared.zsh` content design explicitly forbids PATH modifications (Architecture §9). Platform files use `YOUR_MACOS_TOOL_PATH` / `YOUR_ARCH_TOOL_PATH` placeholders only. D2 checks that `YOUR_HOMEBREW_PREFIX` and `YOUR_EDITOR`/`YOUR_PAGER` are absent from tracked real files. |
| 17 | No secrets, credentials, private hostnames, or identity values in any committed file | Pass | Privacy checklist at end of plan is comprehensive. D2, D3, D4 validation commands check for placeholders, platform leaks, and personal aliases. Guide example in section 8 uses `"your-token-here"` placeholder. |
| 18 | ADR-0028 human setup guide requirement — satisfied | Pass | Group C (task C1) creates `docs/guides/zsh-setup.md` with all twelve sections listed in the ADR-0028 requirement. All `$HOME`-touching commands are marked `⚠️  MANUAL STEP`. `stow --adopt` does not appear. |
| 19 | Validation commands are accurate and would not produce false positives | Warn | **One false positive:** A5 uses `grep -c 'source' stow/common/zsh/.config/zsh/index.zsh` with `# Expected: 4` but the current `index.zsh` has 8 occurrences of "source" (4 active + 4 in comments). All other validation commands are accurate. See Note 1. |
| 20 | Rollback steps are clear and sufficient | Pass | Each task group has explicit rollback via `git checkout --` (Group A), `rm` (Group B), `rm`/`git checkout --` (Group C). Group D requires no rollback. `$HOME` rollback is documented as N/A. Guide section 10 covers user-facing rollback. |
| 21 | Plan lifecycle status field is correct | Pass | Status is `Draft` — correct for a plan that has not yet been approved by the user per DOCUMENT-LIFECYCLE.md. This review's purpose is to allow the user to elevate status to `Approved`. |
| 22 | Plan references correct PRD and architecture doc numbers | Pass | Header references `PRD: 0010-real-zsh-configuration.md` and `Architecture: 0010-real-zsh-configuration-architecture.md`. Review field references `0033-real-zsh-prd-architecture-review.md`. All numbers are correct. |
