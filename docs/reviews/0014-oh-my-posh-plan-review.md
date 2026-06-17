# Review: Oh My Posh Implementation Plan

**Number:** 0014
**Status:** Complete
**Date:** 2026-06-17
**Plan reviewed:** 0008 — Implement Oh My Posh Support
**Files reviewed:**
- `docs/plans/0008-implement-oh-my-posh-support.md`

---

## Summary

Pre-build review of Plan 0008 for Oh My Posh support. This is a plan review — no
implementation has taken place. The plan is in Draft status, correctly pending user
approval before Builder may act.

---

## Checklist

### Conservative scope

- [x] 5 files total: 3 created, 2 modified. No scripts, no hooks, no CI, no
  bootstrap logic.
- [x] All created files are `.example`, `.gitignore`, or documentation — no
  executable files.
- [x] No plugin managers, no Oh My Zsh, no shell frameworks introduced or referenced
  in task steps.
- [x] Objective explicitly states "template files and documentation only, no
  installation, no activation, no `$HOME` changes."
- [x] Scope matches Architecture 0005 Phase 2 exactly.

### Templates/examples only

- [x] `omp.toml.example` — `.example` suffix, never stowed directly.
- [x] `omp.zsh.example` — `.example` suffix, never stowed directly.
- [x] Both `.gitignore` files exclude the real (user-local) filenames so they can
  never be accidentally committed.
- [x] No real config values appear in task content.

### No copy or inspection of `~/.config/omp/omp.toml`

- [x] Assumptions section: "No real `~/.config/omp/omp.toml` is read, copied, or
  referenced at any point."
- [x] Safety checks section: "Confirm `~/.config/omp/omp.toml` is not read, opened,
  or `cat`-ted at any point."
- [x] `omp.toml.example` content is authored from scratch — no read of the real file
  required.
- [x] No `cat`, `cp`, or read command targeting `~/.config/omp/` in any task step.

### No `~/.zshrc` modification

- [x] No task step modifies `~/.zshrc` or any path under `~/.`.
- [x] The stow-usage.md section documents adding a source guard to `~/.zshrc` as a
  future user action, explicitly framed as a manual step — not executed by the plan.
- [x] `~/.zshrc` not listed in Files Affected.

### No `$HOME` modification

- [x] Files Affected table: "No files outside the repository root are modified."
- [x] Every task targets `stow/common/...` or `docs/...` — all repository-internal paths.
- [x] No `mv`, `rm`, or `ln -s` targeting `$HOME` anywhere in the plan.

### No symlinks created

- [x] Files Affected table: "No symlinks are created."
- [x] Stow install commands (`stow --dir=stow/common --target="$HOME" omp`) appear
  only inside the stow-usage.md draft content (future user documentation), not in any
  task step that the Builder executes.
- [x] Safety checks section: "Confirm no stow install command is run."
- [x] `$HOME` check in validation commands is read-only (`ls -la`) — does not create
  anything.

### No Stow run except `--simulate` in documentation

- [x] Assumptions: "No stow install commands are run — only `--simulate` is
  permissible, and only as reference documentation in `docs/stow-usage.md`."
- [x] Task 5 correctly places all stow commands (including `--simulate`) inside the
  documentation section being added to `docs/stow-usage.md` — they are content to be
  written, not commands to be executed.
- [x] No Builder-executed stow command anywhere in Tasks 1–5.

### No automatic Oh My Posh or font installation

- [x] Install commands (`brew install`, `yay -S`, `curl ... | bash`) appear only
  inside the stow-usage.md draft content for Task 5 — future user reference, not
  Builder-executed.
- [x] No install command in Tasks 1–4.
- [x] Task 5 install documentation correctly labeled as manual prerequisites.

### No Oh My Zsh or plugin managers

- [x] Not mentioned in any task step.
- [x] Not present in `omp.toml.example` content.
- [x] Not present in `omp.zsh.example` content.

### Sample config paths valid

- [x] `stow/common/omp/.config/omp/omp.toml.example` — mirrors XDG target
  `~/.config/omp/omp.toml`. Consistent with ADR-0004 (XDG mixed-mode) and ADR-0001
  (common-package criteria satisfied).
- [x] `stow/common/zsh/.config/zsh/omp.zsh.example` — mirrors target
  `~/.config/zsh/omp.zsh`. Consistent with ADR-0016 (all zsh-sourced files in the
  zsh package).
- [x] Stow commands in documentation use correct form:
  `--dir=stow/common --target="$HOME"` — matches established stow-usage.md pattern.
- [x] `task dry-run AREA=common PACKAGE=omp` — valid per ADR-0012 Stow task
  interface; `omp` will be discoverable once `stow/common/omp/` exists.

### Validation commands safe

All validation commands in the plan are read-only:

- [x] `ls stow/common/omp/.config/omp/` — read-only.
- [x] `cat stow/common/omp/.config/omp/.gitignore` — read-only.
- [x] `grep -v '^#' stow/common/zsh/.config/zsh/omp.zsh.example | grep -v '^$'`
  — read-only; correctly verifies no uncommented lines exist.
- [x] `grep 'omp.zsh' stow/common/zsh/.config/zsh/.gitignore` — read-only.
- [x] `grep -n 'Oh My Posh package adoption' docs/stow-usage.md` — read-only.
- [x] `grep 'harmless' docs/stow-usage.md` — read-only.
- [x] `ls -la ~/.config/omp/ 2>/dev/null || echo "..."` — read-only access to
  `$HOME`; suppresses error when directory absent; does not create anything.
- [x] `git status` — read-only.
- [x] `git diff --staged` — read-only.

### Rollback realistic

- [x] Modified files rolled back with `git checkout -- <file>` — standard, reversible.
- [x] New files rolled back with `git rm --cached <file> && rm <file>` — correct
  two-step for tracked new files.
- [x] Post-commit rollback with `git reset HEAD~1` — correct for pre-push scenario.
- [x] "No `$HOME` rollback is needed" — accurate; nothing in `$HOME` is changed.
- [x] Rollback scope matches the plan scope: 5 files, all repository-internal.

---

## Blocking Issues

None.

---

## Non-Blocking Suggestions

1. **`rm` in rollback leaves empty directories.**
   The rollback command `rm stow/common/omp/.config/omp/omp.toml.example` followed by
   the equivalent for `.gitignore` would leave empty directories
   (`stow/common/omp/.config/omp/`, `stow/common/omp/.config/`, `stow/common/omp/`)
   behind in the working tree. These are repository-internal and harmless, but the
   Builder should follow with `rmdir` calls or `rm -r stow/common/omp/` to keep the
   tree clean. Not a safety concern — nothing outside the repo.

2. **`omp.zsh.example` grep path in Safety Checks is incomplete.**
   Safety Checks section, "During execution" bullet:
   `grep -v '^#' omp.zsh.example | grep -v '^$'`
   The path is relative without a directory prefix. In practice the Builder will likely
   run this from the repo root with the full path
   `stow/common/zsh/.config/zsh/omp.zsh.example`, which matches the Validation Commands
   section. Minor inconsistency; the full-path version in Validation Commands is
   authoritative and correct.

3. **`omp.toml.example` `❯` glyph note.**
   The prompt character `❯` in the sample theme is a Unicode character (U+276F RIGHT-
   POINTING ANGLE QUOTATION MARK), not a Nerd Font glyph. Task 2 correctly states "Plain
   style — no nerd font glyphs in the starter". The `❯` character renders in any terminal
   without a Nerd Font, so this is fine. The Builder should confirm the file is saved as
   UTF-8 and that the character is the plain Unicode `❯`, not a Nerd Font power-line
   codepoint. Low-risk; noted for Builder awareness.

4. **`omp.zsh.example` inner guard quoting.**
   The guarded eval line in the plan's Open Question section:
   ```zsh
   eval "$(oh-my-posh init zsh --config "$HOME/.config/omp/omp.toml")"
   ```
   The inner `"$HOME/..."` is inside the outer `"..."`. In zsh this works correctly
   because `$(...)` creates its own quoting context, but it can confuse linters and
   some syntax highlighters. The Builder may optionally use `${HOME}` (no change in
   behavior) or wrap the path in single quotes for clarity:
   ```zsh
   eval "$(oh-my-posh init zsh --config '${HOME}/.config/omp/omp.toml')"
   ```
   Wait — single quotes would prevent `$HOME` expansion. The correct alternative is:
   ```zsh
   eval "$(oh-my-posh init zsh --config "${HOME}/.config/omp/omp.toml")"
   ```
   Either form works in zsh. The plan's form also works. Builder choice; no impact on
   safety or correctness.

---

## Safety Verdict

**PASS** — No `$HOME` modifications, no stow install commands, no destructive operations.
All validation steps are read-only. Safety checks are explicit and per-task. No real
`~/.config/omp/omp.toml` is accessed at any point.

## Privacy Verdict

**PASS** — All created files use `.example` suffix or `.gitignore`/docs only. Both
`.gitignore` files protect against accidental commit of real user-local copies. Privacy
audit checklist is embedded in Task 2. Pre-commit `git diff --staged` review is listed
as a completion criterion.

## Documentation Verdict

**PASS** — Task 5 produces a complete OMP adoption section in `docs/stow-usage.md` with
macOS and Arch steps strictly separated, Nerd Font requirements documented, guarded eval
pattern documented, and review finding 4 (`.example` symlink note) addressed. Validation
commands verify all key content is present after writing.

---

## Recommended Next Action

No blocking issues. Plan 0008 is ready for user approval (status change Draft → Approved).

Once approved, Builder may implement Tasks 1–5 in order. Each task is independently
stoppable. Reviewer validates implementation before any commit is made.
