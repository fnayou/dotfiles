# Review: Oh My Posh Implementation

**Number:** 0015
**Status:** Complete
**Date:** 2026-06-17 (updated after Plan 0009 corrective pass)
**Plans reviewed:**
- 0008 — Implement Oh My Posh Support (marked Complete)
- 0009 — Corrective: Stow Directory Conflict and Fake-Home Validation (marked Complete)
**Files reviewed (Plans 0008 + 0009):**
- `stow/common/omp/.config/omp/.gitignore` — created (Plan 0008)
- `stow/common/omp/.config/omp/omp.toml.example` — created (Plan 0008)
- `stow/common/zsh/.config/zsh/omp.zsh.example` — created (Plan 0008)
- `stow/common/zsh/.config/zsh/.gitignore` — modified (Plan 0008)
- `docs/stow-usage.md` — modified (Plans 0008 + 0009)
- `docs/plans/0008-implement-oh-my-posh-support.md` — modified (Plan 0009 post-note)
- `docs/decisions/0017-use-fake-home-for-stow-validation.md` — created (Plan 0009)
- `docs/plans/0009-corrective-stow-conflict-and-fake-home-validation.md` — created (Plan 0009)

---

## Summary

Combined review of Plan 0008 (Oh My Posh scaffold) and Plan 0009 (corrective: Stow
directory-ownership conflict documentation and fake-home validation). Plan 0008 was
marked Complete in the initial review pass. Plan 0009 addresses a post-implementation
finding where `task dry-run AREA=common PACKAGE=omp` against a real `$HOME` containing
`~/.config/omp/` produced a directory-ownership conflict — expected and correct Stow
behaviour, not a defect. Both plans are Complete. No blocking issues found.

---

## Checklist

### Builder implemented only the approved plan

- [x] Exactly 5 files changed: 3 created, 2 modified — matches the Files Affected table
  in Plan 0008.
- [x] No files outside the plan scope were created or modified (Taskfile.yml unchanged,
  no CI changes, no hook changes, no other docs touched).
- [x] `docs/plans/0008-implement-oh-my-posh-support.md` status was set to Approved by
  the user's explicit instruction before implementation began — correct per
  DOCUMENT-LIFECYCLE.md.
- [x] No task was skipped. All 5 tasks (scaffold, toml.example, zsh.example, gitignore
  update, stow-usage.md update) are present in the diff.

### No real `~/.config/omp/omp.toml` copied or inspected

- [x] `~/.config/omp/omp.toml` exists on disk (1.4K, permissions 644, regular file —
  not a symlink). This is the user's pre-existing real config. It is unchanged.
- [x] `omp.toml.example` content is authored from scratch — path segment, text segment,
  plain style, no personal identifiers. No content matches what a real personal OMP
  config would contain.
- [x] No `cat`, `cp`, or read command targeting `~/.config/omp/` appears in the Builder
  session output.

### Only example/template files added

- [x] `omp.toml.example` — `.example` suffix, never stowed directly.
- [x] `omp.zsh.example` — `.example` suffix, never stowed directly.
- [x] `.gitignore` and `docs/stow-usage.md` are the only other changes — both are
  repository metadata and documentation, not executable or personal config.
- [x] No real `omp.toml` or `omp.zsh` committed anywhere.

### No `~/.zshrc` modification

- [x] `git diff` shows no changes to any path under `~/`.
- [x] `~/.zshrc` not present in diff, not in Files Affected, not referenced in any
  task command.
- [x] stow-usage.md Step 7 documents adding the source guard to `~/.zshrc` as a future
  user manual step — not executed by the Builder.

### No `$HOME` modification

- [x] `git status` shows only repository-internal changes.
- [x] `~/.config/omp/omp.toml` — pre-existing regular file, unchanged (644, 1.4K).
- [x] `~/.config/zsh/omp.zsh` — does not exist. No symlink created.
- [x] No path under `$HOME` appears in the git diff as created or modified.

### No symlinks created

- [x] `~/.config/zsh/omp.zsh` — confirmed absent.
- [x] `~/.config/omp/omp.toml` — confirmed regular file (not a symlink; no `->` in
  `ls -la` output, permissions 644 not `lrwxr-xr-x`).
- [x] No `ln -s` command in Builder session output.
- [x] No stow install command run — stow commands appear only in documentation text.

### No Stow install/adopt operation run

- [x] git diff contains no evidence of stow execution.
- [x] stow-usage.md changes are documentation content — stow commands in the OMP
  section are text to be written, not commands executed.
- [x] `--adopt` flag absent from all files.
- [x] `stow --simulate` appears only in `docs/stow-usage.md` as reference documentation
  (Step 3 dry-run), not executed.

### No automatic package or font installation

- [x] No `brew install`, `yay -S`, `curl | bash`, or `oh-my-posh font install` in the
  git diff as executed commands.
- [x] Installation commands appear only inside the `docs/stow-usage.md` Prerequisites
  section — labeled as manual user steps.

### Oh My Posh clearly separated from Oh My Zsh

- [x] `omp.toml.example` header: "Oh My Posh configuration template".
- [x] `omp.zsh.example` header: "Oh My Posh — prompt engine activation snippet".
- [x] stow-usage.md section heading: "Oh My Posh package adoption".
- [x] No reference to "Oh My Zsh", zinit, antigen, or any plugin manager in any new
  file.
- [x] Prompt engine terminology consistent throughout.

### Zsh activation remains optional and manual

- [x] `omp.zsh.example`: all 22 lines are comments. No uncommented `eval` line present.
  Verified: `grep -v '^#' omp.zsh.example | grep -v '^$'` produces no output.
- [x] The guarded eval block is presented as a comment block the user must explicitly
  uncomment — it cannot activate OMP if accidentally sourced.
- [x] stow-usage.md Step 7 (source guard in `shared.zsh`/`~/.zshrc`) is user-executed,
  not Builder-executed.
- [x] stow-usage.md Steps 4 and 6 carry `⚠️  MANUAL STEP` markers.

### macOS and Arch notes separated

- [x] stow-usage.md Prerequisites section: **macOS:** and **Arch / EndeavourOS:**
  subsections clearly separated for both OMP installation and Nerd Font installation.
- [x] No Homebrew command in Arch section; no pacman/yay command in macOS section.
- [x] `curl | bash` binary fallback present in both sections — correct, it is
  cross-platform.

### Nerd Font requirement documented

- [x] stow-usage.md Prerequisites section: Nerd Font installation covered for both
  macOS (Homebrew Cask + OMP installer) and Arch (AUR + OMP installer).
- [x] stow-usage.md: "configure your terminal emulator to use it before activating Oh
  My Posh" — post-install step documented.
- [x] `omp.zsh.example` lists "A Nerd Font installed and selected in your terminal
  emulator" as a named prerequisite.

### Sample config free of secrets and personal values

- [x] `omp.toml.example` contains: TOML schema reference, `version = 2`,
  `final_space = true`, one `path` segment, one `text` segment with `❯`. No
  username, hostname, API key, token, absolute path, or personally identifying value.
- [x] Automated privacy grep over `stow/common/omp/` for `username|hostname|password|
  token|api.key|secret` — returned `privacy-ok`.
- [x] `foreground` values are generic color names (`cyan`, `white`) — not personal.
- [x] Template path (`{{ .Path }}`) is an OMP template variable, not a hardcoded path.

### Taskfile safe

- [x] `Taskfile.yml` — unchanged (verified via `git diff Taskfile.yml`).
- [x] No new tasks, no modified dry-run logic, no new install targets.

---

## Blocking Issues

None.

---

## Non-Blocking Observations

1. **`omp.zsh.example` inner eval quoting improved vs plan.**
   The plan (Open Question section) used `"$HOME/..."` inside the outer `"..."`. The
   Builder used `"${HOME}/..."` — the safer form recommended in Plan Review 0014
   finding 4. Improvement accepted; no action needed.

2. **Pre-existing `~/.config/omp/omp.toml` will conflict at future stow dry-run.**
   This is expected and documented (Architecture 0005 Risk table row 1, stow-usage.md
   Step 3 conflict note). The user will need to back up and remove the real file before
   stowing the omp package in Phase 3. No action needed now.

3. **`omp.toml.example` TOML schema URL is a raw GitHub URL.**
   `"$schema" = "https://raw.githubusercontent.com/..."` — this URL may drift if the
   OMP project moves the schema file. Non-critical for a template; the user will
   customize the file before stowing. Noted for awareness; no action required.

4. **Expected directory-ownership conflict on real-home dry-run (post-review finding,
   resolved by Plan 0009).**
   Running `task dry-run AREA=common PACKAGE=omp` against a machine where
   `~/.config/omp` already exists produces:
   ```
   WARNING! stowing omp would cause conflicts:
     * existing target is not owned by stow: .config/omp
   All operations aborted.
   ```
   Correct Stow behaviour — not a defect. Package layout confirmed valid by fake-home
   validation. Fully documented in Plan 0009. No `$HOME` files modified. No `--adopt`
   used. Resolved: `docs/stow-usage.md` now covers directory-ownership conflicts and
   fake-home validation. ADR-0017 records the decision.

---

## Plan 0009 Corrective Review

### Fake-home validation documented correctly

- [x] `docs/stow-usage.md` "Conflict handling" section gains two new subsections:
  "Directory-ownership conflicts" and "Fake-home validation" — both present and
  correctly placed after the existing `--adopt` prohibition paragraph.
- [x] Fake-home command uses `mktemp -d` (not a hardcoded path), `--simulate`, and
  immediate `rm -rf "$TEST_HOME"` — safe form throughout.
- [x] Fake-home validation was executed by the Builder and returned clean output:
  `WARNING: in simulation mode so not modifying filesystem.` — no conflicts, no errors.
- [x] `$TEST_HOME` was removed immediately after the run.

### Real `$HOME` dry-run conflict explained as expected and non-blocking

- [x] stow-usage.md "Directory-ownership conflicts" subsection states: "This is correct
  behaviour" — framed as expected, not as an error.
- [x] OMP Step 3 "If `~/.config/omp` already exists" states: "This is expected and
  correct — Stow refuses to claim a directory it does not own."
- [x] Conflict is presented as a stop signal, not as something to bypass.

### No instruction suggests using `--adopt`

- [x] All "adopt" occurrences in `docs/stow-usage.md` are prohibitions or the concept
  "adoption" (package adoption steps). Every context that mentions `--adopt` says
  "do not use" or "forbidden" or "Never use this."
- [x] OMP Step 3 conflict guidance: "**Do not use `--adopt`.**" explicit.
- [x] ADR-0017: "`--adopt` remains forbidden. A directory-ownership conflict is a stop
  signal, not a flag to bypass."

### No instruction suggests deleting or moving `~/.config/omp`

- [x] OMP Step 3 "Migrate" option says "back up your real `~/.config/omp/` contents,
  remove the directory" — this is a user-initiated option, not a Builder-executed
  command. Framed as one of three options including Defer (do nothing) and fake-home
  validation.
- [x] No `rm -rf ~/.config/omp` or `mv ~/.config/omp` command appears anywhere as an
  automatic or required step.
- [x] `~/.config/omp/omp.toml` confirmed unchanged on disk (1.4K regular file).

### No real `~/.config/omp/omp.toml` copied or inspected

- [x] Confirmed throughout Plan 0009 execution — no read, copy, or cat of the real file.
- [x] `~/.config/omp/omp.toml` remains a 1.4K regular file, permissions unchanged.

### No `~/.zshrc` modified

- [x] Git status clean — no home directory paths in any diff.
- [x] Plan 0009 files are all documentation/decisions — no shell config touched.

### OMP config remains template/example-only

- [x] `omp.toml.example` unchanged from Plan 0008 — minimal starter theme, no personal
  values.
- [x] No new config files committed. Plan 0009 adds only docs and an ADR.

### Zsh activation remains optional and manual

- [x] `omp.zsh.example` unchanged — all lines comments, eval block inert.
- [x] Plan 0009 adds no sourcing, no activation, no shell startup changes.

### Taskfile safe

- [x] `Taskfile.yml` unchanged across both plans.

### ADR-0017 correctly recorded

- [x] `docs/decisions/0017-use-fake-home-for-stow-validation.md` — Status: Accepted,
  number 0017 (0016 was last used; user suggested 0013 which is already taken).
- [x] ADR states `--adopt` remains forbidden, fake-home supplements (not replaces)
  real-home dry-run, `$TEST_HOME` must be removed immediately.
- [x] Clean fake-home result does not authorise skipping real-home conflict resolution
  before stowing for real — stated explicitly.

### Minor non-blocking observation (Plan 0009)

- "Fake-home validation" subsection in the general "Conflict handling" section
  hardcodes `omp` as the package name in the example command, rather than a generic
  `<package>` placeholder. ADR-0017 shows the generic form. The example is correct for
  the OMP context and harmless since it uses `--simulate`. Acceptable for now — can be
  generalised when another package hits this case.

---

## Safety Verdict

**PASS** — Plans 0008 and 0009 combined: no `$HOME` modifications, no stow installs,
no `--adopt`, no destructive commands. Pre-existing `~/.config/omp/omp.toml` untouched.
Fake-home validation run cleanly against a temporary directory, removed immediately.
All risky adoption commands in documentation carry `⚠️  MANUAL STEP` markers.

## Privacy Verdict

**PASS** — No personal config read or committed across either plan. `omp.toml.example`
contains no personal identifiers. `omp.zsh.example` activation line fully commented.
ADR-0017 contains no sensitive data. Both `.gitignore` files prevent accidental commit
of user-local real files.

## Documentation Verdict

**PASS** — `docs/stow-usage.md` now covers the full conflict surface: file-level
conflicts (existing), directory-ownership conflicts (Plan 0009), and fake-home
validation (Plan 0009). OMP Step 3 gives clear, safe guidance for users with existing
`~/.config/omp/`. ADR-0017 records the decision formally. macOS/Arch separation,
Nerd Font requirement, and guard patterns are all intact from Plan 0008.

---

## Recommended Next Action

All verdicts PASS. Plans 0008 and 0009 both marked Complete. Ready to commit.

Suggested commit scope: all untracked and modified files on `feature/omp` branch —
PRD, architecture, reviews, plans, ADRs, stow package, zsh snippet, and
`docs/stow-usage.md`. Pre-commit checklist per AGENTS.md §13 applies.
