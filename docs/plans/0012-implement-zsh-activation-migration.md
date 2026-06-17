# Plan: Implement Zsh Activation & Migration (Model 4 → Model 3)

**Number:** 0012
**Status:** Complete
**Date:** 2026-06-17
**PRD:** 0007
**Architecture:** 0007
**Review:** 0021 (PRD + Architecture, all verdicts PASS)

> **Numbering note:** This plan was requested as `0010`, but `docs/plans/0010-zsh-omp-optional-integration.md` and `0011-implement-shell-dependencies.md` already exist. Per the numbered-filename convention (no collisions, chronological), the next available number `0012` is used.

---

## Objective

Add the template/documentation artifacts that make the managed zsh layer adoptable via Model 3 (unmanaged `~/.zshrc` + one guarded managed include block sourcing `~/.config/zsh/index.zsh`), starting from Model 4 (`.zshrc.example` reference). Template- and documentation-only: no `$HOME` change, no symlink, no Stow against real home, no dependency install, no OMP activation, no Zinit clone.

---

## Assumptions

- PRD 0007 and Architecture 0007 are approved (Draft → Approved) before Builder starts. If still Draft, the Builder must stop (DOCUMENT-LIFECYCLE rule 1 applies to plans; PRD/architecture approval is the user's gate here).
- The existing zsh package scaffold is present: `stow/common/zsh/.config/zsh/{shared,macos,arch,omp}.zsh.example` and `.gitignore`.
- All work stays in the repository. The user's real `~/.zshrc` is never read, modified, or referenced beyond the design context already captured.
- `.example` files are templates only. Adding guarded blocks to them is **not** "active config" — the real (git-ignored) files do not exist until the user copies them, and every added line is a guarded no-op when its tool is absent.

---

## Ordered Tasks

Each task is independently committable and safe to stop after.

### Task 1 — Write ADR-0021 (activation mechanism)

Create `docs/decisions/0021-zsh-activation-include-block-and-index-entrypoint.md`.

Record: zsh activation uses a **single guarded `~/.zshrc` include block** (delimited, user-added by hand, never auto-edited, never stowed) that sources one managed entry point `~/.config/zsh/index.zsh`; `index.zsh` owns source order only; this refines ADR-0016's inline source block. Include the `zshrc.example` placement decision (under `.config/zsh/`, never stowable to `~/.zshrc`). Status: Accepted. Cross-ref PRD 0007, Architecture 0007 (Decisions 1, 2, 4).

- **Create:** `docs/decisions/0021-zsh-activation-include-block-and-index-entrypoint.md`
- **Validate:** `git status` shows the new file; `grep -c "Status: Accepted" docs/decisions/0021-*.md`

### Task 2 — Write ADR-0022 (migration strategy)

Create `docs/decisions/0022-zsh-migration-model-4-start-model-3-target.md`.

Record: migration starts at Model 4 (`.zshrc.example`), targets Model 3 (include block); Model 2 (stowed/replaced `~/.zshrc`) rejected for migration and deferred to a possible fresh-machine-only PRD; Model 1 (scattered manual `source` lines) superseded by Model 3. Status: Accepted. Cross-ref PRD 0007, Architecture 0007 (Decision 5).

- **Create:** `docs/decisions/0022-zsh-migration-model-4-start-model-3-target.md`
- **Validate:** `git status`; file references Architecture 0007 and PRD 0007.

### Task 3 — Write ADR-0023 (local override slot)

Create `docs/decisions/0023-zsh-local-override-slot.md`.

Record: `local.zsh` is the git-ignored, never-tracked, last-sourced override slot; it is the migration home for the user's machine-specific/sensitive lines; it "wins" among managed layers; the migration runbook must instruct placing the include block last in `~/.zshrc` for the win to hold end-to-end (Review 0021, non-blocking #2). Status: Accepted. Resolves Architecture 0004 open question.

- **Create:** `docs/decisions/0023-zsh-local-override-slot.md`
- **Validate:** `git status`; `grep -n "local.zsh" docs/decisions/0023-*.md`

### Task 4 — Create the managed entry point `index.zsh.example`

Create `stow/common/zsh/.config/zsh/index.zsh.example`. Orchestration only — every source guarded; no env/tool logic of its own. Template content:

```zsh
# index.zsh — managed zsh entry point (template).
# Copy to index.zsh (git-ignored), review, then stow. Do NOT stow this .example directly.
# Sourced by the single guarded include block in your real ~/.zshrc (see zshrc.example).
# This file owns SOURCE ORDER only. Each layer file owns its own guarded logic.

# 1) Portable layer: env, history, completion, guarded fzf/zoxide/eza/zinit.
[[ -r "$HOME/.config/zsh/shared.zsh" ]] && source "$HOME/.config/zsh/shared.zsh"

# 2) Platform layer: OS-detected, sourced only if present.
if [[ "$OSTYPE" == "darwin"* ]]; then
  [[ -r "$HOME/.config/zsh/macos.zsh" ]] && source "$HOME/.config/zsh/macos.zsh"
elif [[ -f /etc/arch-release ]]; then
  [[ -r "$HOME/.config/zsh/arch.zsh" ]] && source "$HOME/.config/zsh/arch.zsh"
fi

# 3) Prompt: Oh My Posh — opt-in, guarded inside omp.zsh. Never auto-activated.
[[ -r "$HOME/.config/zsh/omp.zsh" ]] && source "$HOME/.config/zsh/omp.zsh"

# 4) Local overrides — machine-specific/sensitive, git-ignored, sourced LAST so it wins.
[[ -r "$HOME/.config/zsh/local.zsh" ]] && source "$HOME/.config/zsh/local.zsh"
```

- **Create:** `stow/common/zsh/.config/zsh/index.zsh.example`
- **Validate:** `zsh -n stow/common/zsh/.config/zsh/index.zsh.example` (syntax OK); confirm no install/clone/`eval` of a tool present.

### Task 5 — Create the reference `zshrc.example`

Create `stow/common/zsh/.config/zsh/zshrc.example` (placed here per ADR-0021/Architecture Decision 4 — can only ever stow to `~/.config/zsh/zshrc.example`, never `~/.zshrc`). Include the delimited guarded block at the top, plus a minimal fresh-machine starter body (Open Question 2 → option b). Template content:

```zsh
# zshrc.example — reference template for your real ~/.zshrc.
# This file is NEVER applied automatically and is never stowed to ~/.zshrc.
#
# If you ALREADY have a ~/.zshrc: copy ONLY the managed block below into it,
#   placing it LAST so managed defaults and local.zsh take effect after your own lines.
# If this is a FRESH machine with no ~/.zshrc: you may use this whole file as a starter.

# --- (fresh-machine starter lines may go here; keep minimal and portable) ---

# >>> dotfiles managed (zsh) — added manually; delete this block to disable >>>
[[ -r "$HOME/.config/zsh/index.zsh" ]] && source "$HOME/.config/zsh/index.zsh"
# <<< dotfiles managed (zsh) <<<
```

- **Create:** `stow/common/zsh/.config/zsh/zshrc.example`
- **Validate:** `zsh -n stow/common/zsh/.config/zsh/zshrc.example`; confirm the block is `[[ -r ... ]]`-guarded and delimited.

### Task 6 — Extend the package `.gitignore`

Modify `stow/common/zsh/.config/zsh/.gitignore` to ignore the two new real filenames. Append:

```gitignore
index.zsh
local.zsh
```

`zshrc.example` stays **tracked** (template). `local.zsh` never has an `.example` (privacy — never committed).

- **Modify:** `stow/common/zsh/.config/zsh/.gitignore`
- **Validate:** `git check-ignore stow/common/zsh/.config/zsh/index.zsh stow/common/zsh/.config/zsh/local.zsh` (both reported ignored); `git status` shows `.example` and `zshrc.example` still trackable.

### Task 7 — Add guarded tool activation to `shared.zsh.example`

Modify `stow/common/zsh/.config/zsh/shared.zsh.example` to add guarded, example-only activation for fzf, zoxide, eza, and Zinit, with completion ordering resolved (Review 0021, non-blocking #1). All lines are guarded no-ops when the tool is absent; none install or clone. Suggested block (ordering: Zinit guard, then tools, then a `compinit` that does not double-init when Zinit manages completions):

```zsh
# --- Zinit (plugin manager) — guarded SOURCE only; never cloned at startup (ADR-0020) ---
# Install once, manually:  see docs/shell-dependencies.md / docs/zsh-migration.md
ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
[[ -f "${ZINIT_HOME}/zinit.zsh" ]] && source "${ZINIT_HOME}/zinit.zsh"

# --- Tool integrations (guarded — no-op when the tool is absent; never installs) ---
command -v fzf    >/dev/null 2>&1 && eval "$(fzf --zsh)"
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"
command -v eza    >/dev/null 2>&1 && alias ls='eza'
```

Builder must resolve the existing `autoload -Uz compinit && compinit` line so it is not run twice when Zinit initializes completions (e.g. guard the standalone `compinit` to run only when Zinit is absent, or document the chosen order in a comment). Record the chosen approach in a code comment. Keep the existing OMP reference block unchanged (OMP activation stays in `omp.zsh`).

- **Modify:** `stow/common/zsh/.config/zsh/shared.zsh.example`
- **Validate:** `zsh -n stow/common/zsh/.config/zsh/shared.zsh.example`; `grep -nE "command -v (fzf|zoxide|eza)" shared.zsh.example` shows guards; confirm **no active** `brew install`, `pacman`, or `git clone` line exists using the comment-ignoring grep in Validation Commands.

> **Builder note (Task 7 — guarded live lines):**
> - Task 7 may convert the fzf, zoxide, and eza examples from commented references into **guarded live** `eval`/`alias` lines.
> - Builder must confirm each line is a **no-op when the related command is missing** — verify by running the line on a machine (or fake env) where the tool is absent and seeing no error and no effect.
> - Guarded live lines are acceptable **only** when protected by `command -v <tool>` (or an equivalent existence check such as a file-exists guard for the Zinit `source`).
> - **No dependency installation may happen from shell startup files.** A guard activates an already-installed tool; it must never `brew install`, `pacman -S`, `git clone`, or otherwise fetch/install the tool.

### Task 8 — Update `docs/stow-usage.md` zsh section

Modify `docs/stow-usage.md`:

- Replace the **Step 5** inline multi-line source block (lines ~319–334) with the single guarded include block from Task 5, and point to `index.zsh` as the entry point.
- Add `index.zsh.example → index.zsh`, `zshrc.example → (reference only, not stowed to ~/.zshrc)`, and `local.zsh (git-ignored, no .example)` to the "Files in this package" table.
- Add a one-line pointer to the new `docs/zsh-migration.md` for the full Model 4 → Model 3 path.
- Keep all `⚠️  MANUAL STEP` markers; do not introduce any command that writes to `~/.zshrc`.

- **Modify:** `docs/stow-usage.md`
- **Validate:** `grep -n "index.zsh" docs/stow-usage.md`; `grep -n ">>> dotfiles managed (zsh)" docs/stow-usage.md`; confirm old inline `if [[ "$OSTYPE"` Step-5 block is gone or moved into `index.zsh` context.

### Task 9 — Create the migration runbook `docs/zsh-migration.md`

Create `docs/zsh-migration.md` (Open Question 1 → dedicated doc). Contents:

1. The Model 4 → Model 3 path (start, target, why Model 2 rejected — summarize, link PRD 0007 / ADR-0022).
2. Pre-adoption: run `task deps:check:zsh` (read-only); install missing tools out-of-band (link `docs/shell-dependencies.md`); one-time manual Zinit clone (`⚠️  MANUAL STEP`, per ADR-0020) and Oh My Posh install (`⚠️  MANUAL STEP`, optional).
3. Backup step: `cp "$HOME/.zshrc" "$HOME/.zshrc.bak.$(date +%Y%m%d)"` marked `⚠️  MANUAL STEP`.
4. Copy `.example → real`, fake-home dry-run (Task 10 commands), stow (`⚠️  MANUAL STEP`).
5. Add the guarded include block to `~/.zshrc` **last** (`⚠️  MANUAL STEP`), open new shell to verify.
6. Incremental per-capability cutover (history → completions → aliases → tool integrations → prompt), verifying after each; move local overrides into `local.zsh`.
7. Rollback (staged, per Architecture 0007): delete the block; per-capability revert; full abort with a **scoped, marked** cleanup — never a bare `rm -rf ~/.config/zsh` (Review 0021, non-blocking #3).

Every risky line carries `⚠️  MANUAL STEP`. macOS and Arch steps labeled separately where they differ.

- **Create:** `docs/zsh-migration.md`
- **Validate:** `grep -c "⚠️  MANUAL STEP" docs/zsh-migration.md` (≥ the risky-step count); confirm no unmarked `rm`/`mv`/`ln -s` against `$HOME`.

### Task 10 — Final validation pass (read-only)

Run the full validation suite (see Validation Commands). No file changes in this task.

---

## Files Affected

**Created:**
- `docs/decisions/0021-zsh-activation-include-block-and-index-entrypoint.md`
- `docs/decisions/0022-zsh-migration-model-4-start-model-3-target.md`
- `docs/decisions/0023-zsh-local-override-slot.md`
- `stow/common/zsh/.config/zsh/index.zsh.example`
- `stow/common/zsh/.config/zsh/zshrc.example`
- `docs/zsh-migration.md`

**Modified:**
- `stow/common/zsh/.config/zsh/.gitignore`
- `stow/common/zsh/.config/zsh/shared.zsh.example`
- `docs/stow-usage.md`

**Deleted:** none.

---

## Template Strategy

- **`.example`-first, unchanged from the package convention.** New real files (`index.zsh`, `local.zsh`) are git-ignored; `index.zsh.example` is the only new tracked template that has a real counterpart. `local.zsh` has **no** `.example` (privacy slot).
- **`zshrc.example` is reference-only.** Tracked, never stowed to `~/.zshrc`, never auto-applied. Placed under `.config/zsh/` so Stow can only ever link it to `~/.config/zsh/zshrc.example`.
- **Guarded include block** is the single managed edit the user makes to `~/.zshrc`, by hand, delimited for a one-step revert.
- **Orchestration vs logic separation:** `index.zsh` sources; layer files (`shared`/`macos`/`arch`/`omp`) hold guarded logic. macOS/Arch never mixed.

---

## Oh My Posh Optional Integration

- No change to OMP activation design (Architecture 0005). `index.zsh` sources `omp.zsh` only if the real file exists; the `eval` inside `omp.zsh` stays double-guarded (binary + `omp.toml`). OMP is never activated automatically by this plan. Install remains a manual, optional step documented in `docs/zsh-migration.md` and the existing OMP adoption section.

## fzf / zoxide / eza Handling

- Guarded `command -v … && (eval|alias)` lines added to `shared.zsh.example` (Task 7). No-op when absent; never installed at startup. Install stays out-of-band via `Brewfile.shell` (macOS) / pacman (Arch), per Architecture 0006.

## Zinit Handling

- Guarded `source` only (Task 7), gated on `${ZINIT_HOME}/zinit.zsh` existing. **Never auto-cloned** (ADR-0020). The one-time manual `git clone` is documented as a `⚠️  MANUAL STEP` in `docs/zsh-migration.md`. No plugin manager is wired into active config by this plan.

## Documentation Updates

- `docs/stow-usage.md` Step 5 → single guarded include block + `index.zsh`; file table extended (Task 8).
- New `docs/zsh-migration.md` runbook (Task 9).
- Three ADRs (Tasks 1–3).
- Update `MEMORY.md`/index files are out of scope (no auto-memory change required by this plan).

---

## Validation Commands

```bash
# Syntax check every shipped zsh template (must all pass)
zsh -n stow/common/zsh/.config/zsh/index.zsh.example
zsh -n stow/common/zsh/.config/zsh/zshrc.example
zsh -n stow/common/zsh/.config/zsh/shared.zsh.example

# Confirm new real filenames are git-ignored; templates stay tracked
git check-ignore stow/common/zsh/.config/zsh/index.zsh stow/common/zsh/.config/zsh/local.zsh

# Fake-home Stow layout validation ONLY (ADR-0017) — never against real $HOME
TEST_HOME="$(mktemp -d)"
stow --dir=stow/common --target="$TEST_HOME" --simulate zsh
rm -rf "$TEST_HOME"

# No ACTIVE install/clone/auto-activation in shipped templates.
# Ignore commented reference lines (e.g. the existing OMP examples in
# omp.zsh.example / shared.zsh.example) before searching — match only
# active, non-commented lines. grep -Rn output is "file:line:content";
# the second grep drops lines whose content starts with "#".
grep -RnE "brew install|pacman -S|git clone|oh-my-posh init" \
  stow/common/zsh --include="*.example" \
  | grep -v '^[^:]*:[0-9]*:[[:space:]]*#' \
  || echo "OK: no active install/clone/oh-my-posh init lines in example files"

# Confirm only expected files changed; real ~/.zshrc untouched (not in repo, never staged)
git status
```

---

## Safety Checks

- [ ] No task modifies `~/.zshrc`, `$HOME`, or any path outside the repository.
- [ ] No task creates a symlink; no `ln -s` in any shipped command without a `⚠️  MANUAL STEP` marker (and none target `$HOME` automatically).
- [ ] No task runs Stow against real `$HOME`; only fake-home `--simulate` (ADR-0017), with `mktemp -d` and immediate `rm -rf "$TEST_HOME"`.
- [ ] No task installs a dependency, clones Zinit, or activates Oh My Posh.
- [ ] Every risky command in docs carries `⚠️  MANUAL STEP`; full-abort cleanup is scoped to named files, never a bare `rm -rf ~/.config/zsh`.
- [ ] `.example` files remain templates; no real (`index.zsh`/`local.zsh`/`shared.zsh`) file is created or committed.

## Privacy Checks

- [ ] No credentials, tokens, passwords, SSH key content, private hostnames, internal IPs, or work-specific values in any new/modified file.
- [ ] All placeholders use `YOUR_*` / `$HOME` / `$XDG_*` conventions.
- [ ] `local.zsh` defined as git-ignored, no `.example`, never tracked.
- [ ] `git check-ignore` confirms `index.zsh` and `local.zsh` are ignored before any local copy is made.

---

## Rollback Strategy

All artifacts are in-repo, so rollback is git-based — nothing touches `$HOME`.

```bash
# Undo a single file before commit
git checkout -- <path>

# Drop all uncommitted plan work
git restore --staged --worktree docs/decisions/0021-* docs/decisions/0022-* docs/decisions/0023-* \
  docs/zsh-migration.md stow/common/zsh/.config/zsh/index.zsh.example \
  stow/common/zsh/.config/zsh/zshrc.example

# Restore modified files to HEAD
git checkout -- stow/common/zsh/.config/zsh/.gitignore \
  stow/common/zsh/.config/zsh/shared.zsh.example docs/stow-usage.md

# Undo the last commit (only before push)
git reset HEAD~1
```

No symlink, no stow, no `$HOME` change is performed by this plan, so there is nothing to unstow or restore outside the repository.

---

## Completion Criteria

- [ ] ADR-0021, ADR-0022, ADR-0023 created, Status Accepted, cross-referencing PRD 0007 / Architecture 0007.
- [ ] `index.zsh.example` created — orchestration only, every source guarded, no install/clone/auto-eval.
- [ ] `zshrc.example` created under `.config/zsh/` — delimited guarded include block at top; never stowable to `~/.zshrc`.
- [ ] `.gitignore` ignores `index.zsh` and `local.zsh`; `zshrc.example` stays tracked.
- [ ] `shared.zsh.example` has guarded fzf/zoxide/eza/Zinit blocks; compinit/Zinit ordering resolved and commented; no install/clone line.
- [ ] `docs/stow-usage.md` Step 5 uses the single guarded include block + `index.zsh`; file table updated; migration doc linked.
- [ ] `docs/zsh-migration.md` created — full Model 4 → Model 3 runbook with backup, incremental cutover, scoped rollback, all risky steps marked `⚠️  MANUAL STEP`, macOS/Arch labeled.
- [ ] All `zsh -n` checks pass; fake-home `--simulate` clean; `git check-ignore` confirms ignores.
- [ ] `git status` shows only the listed files changed; real `~/.zshrc` and `$HOME` untouched.
- [ ] Plan remains Draft until the user approves it (Planner does not self-approve).

---

## Recommended Next Step

User reviews this plan. On approval (Draft → Approved), the Builder implements Tasks 1–10 in order, committing per task, running the per-task validation, and stopping at "Next Steps" without changing the plan status. A follow-up implementation review (next `docs/reviews/` number) verifies and, if all verdicts PASS, marks this plan Complete. Do not implement before approval.
