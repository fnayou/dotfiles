# Review: Oh My Posh PRD and Architecture

**Number:** 0013
**Status:** Complete
**Date:** 2026-06-17
**Files reviewed:**
- `docs/prd/0005-oh-my-posh.md`
- `docs/architecture/0005-oh-my-posh-architecture.md`

---

## Summary

Re-review of PRD 0005 and Architecture 0005 for Oh My Posh configuration support, after
Builder applied fixes for findings 1–3 from the first review pass. This is a pre-planning
review, not an implementation review — no plan is being marked complete. Both documents
are design-only; no implementation has taken place.

Three of four prior non-blocking findings are now resolved (verified below). The fourth
is deferred to the implementation phase by design.

---

## Checklist

### Safety

- [x] No `stow --adopt` as automated behavior — both documents forbid it explicitly.
- [x] No `rm` targeting `$HOME` — neither document introduces any destructive command.
- [x] No `mv` targeting `$HOME` — not present in either document.
- [x] No `ln -s` creating symlinks in `$HOME` automatically — all stow commands carry
  `⚠️  MANUAL STEP` markers.
- [x] No modification of files outside the repository root — Phase 2 states "No Stow
  invoked. No symlinks. No `$HOME` changes." explicitly.
- [x] Risky commands marked with `⚠️  MANUAL STEP` — dry-run and stow install commands
  both carry the marker in the architecture.
- [x] No `~/.zshrc` modification — both documents list this as a hard constraint and
  a non-goal.
- [x] No `~/.config/omp/omp.toml` inspected or copied — architecture Decision 4 states
  this explicitly; PRD lists it as a safety requirement.
- [x] No automatic OMP installation — Installation Reference section labels all commands
  as reference documentation only.
- [x] No automatic font installation — PRD non-goals and safety requirements both cover
  this; architecture repeats it.

### Privacy

- [x] No API keys, tokens, or credentials — not present in either document.
- [x] No passwords or passphrases — not present.
- [x] No SSH private key content — not present.
- [x] No private hostnames or internal IPs — `omp.toml.example` is described as using
  no personal identifiers; architecture Decision 4 is explicit.
- [x] All examples use placeholder values — `omp.toml.example` is a minimal functional
  starter with no personal data; `omp.zsh.example` contains only a commented eval line.
- [x] `.gitignore` in `stow/common/omp/.config/omp/` ignores `omp.toml` — real config
  cannot be accidentally committed.

### Oh My Posh vs Oh My Zsh separation

- [x] Both documents consistently identify Oh My Posh as a **prompt engine**.
- [x] PRD non-goals explicitly list "Do not add Oh My Zsh" and "Do not add any plugin
  manager (zinit, zplug, antigen, etc.)".
- [x] No Oh My Zsh, Zinit, Antigen, or other framework mentioned outside the out-of-scope
  section.
- [x] Architecture out-of-scope section lists "Any zsh plugin manager" and "Any zsh prompt
  theme" other than OMP.
- [x] The distinction is unambiguous throughout both documents.

### No ~/.zshrc modification

- [x] PRD non-goals: "Modifying `~/.zshrc` or any other shell startup file."
- [x] Architecture constraints: "Must not modify `~/.zshrc` or any shell startup file."
- [x] Architecture cross-reference to Architecture 0004: "`~/.zshrc` is never managed
  by Stow; the zsh package manages `~/.config/zsh/` only."
- [x] Adoption phase 2 states "No `$HOME` changes" with no exceptions.

### Template/sample first

- [x] Both files committed are `.example` only (`omp.toml.example`, `omp.zsh.example`).
- [x] `omp.zsh.example` has the activation line **fully commented out** — it cannot
  activate OMP even if accidentally sourced.
- [x] User must explicitly copy, fill, and uncomment before anything is active.
- [x] PRD Sample/Template Strategy section is explicit and complete.

### Zsh activation is optional and manual

- [x] PRD non-goals: "Activating the prompt in any shell session."
- [x] Architecture: eval line fully commented in `.example` — no auto-activation path.
- [x] Architecture Decision 3: guard-wrapped source call prevents shell startup failures
  on machines without OMP.
- [x] Adoption phase clearly lists activation as a user-controlled final step.

### macOS and Arch installation notes separated

- [x] PRD Cross-Platform Requirements: macOS and Arch sections clearly labeled and use
  correct package managers (Homebrew for macOS, yay for Arch).
- [x] Architecture Installation Reference: same clear separation.
- [x] No Homebrew commands in Arch section; no pacman/yay commands in macOS section.
- [x] Both platforms also document the `curl`-based binary fallback.

### Nerd Font requirement documented

- [x] PRD Font Requirements section covers the need, recommended fonts, macOS and Arch
  installation options, and terminal emulator configuration note.
- [x] Architecture Installation Reference repeats font installation for both platforms.
- [x] `omp.zsh.example` content (as defined in the architecture) lists a Nerd Font as
  a named prerequisite.

### GNU Stow layout validity

- [x] `stow/common/omp/` satisfies all three ADR-0001 common-package criteria:
  (1) `~/.config/omp/` path is identical on macOS and Arch;
  (2) values work unmodified on both platforms (OMP is cross-platform);
  (3) no platform-specific tool referenced at package level.
- [x] `stow/common/zsh/` extended with one new `.example` file — no layout change,
  consistent with existing zsh package structure.
- [x] Architecture stow commands correctly use `--dir=stow/common --target="$HOME"`.
- [x] Directory-level `.gitignore` placement is consistent with zsh package precedent
  (ADR-0003 and Architecture 0004).
- [x] One package per tool — `omp` package is separate from `zsh` package (Decision 1).
- [x] ADR-0016 upheld — `omp.zsh.example` lives in the zsh package, not the omp package
  (Decision 2).

### Scope

- [x] Phase 2 scope is two new files plus two small `.gitignore` updates plus one doc
  update. Appropriately small.
- [x] No scripting, no hooks, no CI changes, no bootstrap logic.
- [x] All activation deferred to user-driven Phase 3.

---

## Blocking Issues

None.

---

## Non-Blocking Suggestions

1. **RESOLVED — PRD stow commands corrected to `--dir=stow/common`.**
   `docs/prd/0005-oh-my-posh.md:112,116`. Verified: both dry-run and install lines now
   use `--dir=stow/common`, matching the established layout (ADR-0012, stow-usage.md).

2. **RESOLVED — Architecture risk row 7 reworded.**
   `docs/architecture/0005-oh-my-posh-architecture.md:372`. Verified: the row now states
   the outer `[[ -f "$HOME/.config/zsh/omp.zsh" ]]` guard in `shared.zsh` prevents
   startup failure, and defers the optional inner guard to implementation (cross-referenced
   to Open Questions). No longer implies `omp.zsh.example` contains a binary check.

3. **RESOLVED — Architecture Phase 3 Step 8 reworded.**
   `docs/architecture/0005-oh-my-posh-architecture.md:188`. Verified: the misleading
   "appears automatically" language is gone. Now states Stow does not pick up newly added
   files automatically and the user must re-run `stow` for the zsh package.

4. **DEFERRED — `omp.toml.example` stowed as a symlink in `~/.config/omp/`.**
   The adoption symlink table shows `~/.config/omp/omp.toml.example` as a Stow-created
   link. Harmless (OMP ignores it) but may surprise users. Not actionable now — the
   `docs/stow-usage.md` OMP section does not exist yet. Carry to the Planner: note in
   that section that the `.example` symlink is expected and harmless.

---

## Safety Verdict

**PASS** — Both documents impose strict safety constraints: no `$HOME` modification,
no destructive commands, no automatic stow, no `--adopt`. All risky commands carry
`⚠️  MANUAL STEP` markers. Phase boundaries are clearly drawn.

## Privacy Verdict

**PASS** — Real `~/.config/omp/omp.toml` is never read, copied, or referenced. All
committed artifacts are `.example` files with no personal data. Directory-level
`.gitignore` prevents accidental commit of the real config file. Activation line
contains no sensitive information.

## Documentation Verdict

**PASS** — macOS and Arch installation steps are cleanly separated with correct package
managers. Nerd Font requirement is documented on both platforms. Manual steps are
marked. Guard-wrapped source pattern is documented and explained. Scope is appropriate
for a design-only phase.

---

## Recommended Next Action

No blocking issues. Findings 1–3 resolved and verified. Both documents are safe to commit.

Planner may proceed to create `docs/plans/0005-oh-my-posh-plan.md`. The plan should:
- Decide whether `omp.zsh.example` includes an inner binary guard or relies on the
  outer `[[ -f ... ]]` guard only (see Open Questions in architecture).
- Address finding 4: note in the `docs/stow-usage.md` OMP section that the
  `~/.config/omp/omp.toml.example` symlink is expected and harmless.
