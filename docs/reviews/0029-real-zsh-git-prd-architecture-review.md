# Review: Real Zsh and Git Configuration PRD and Architecture

**Number:** 0029
**Date:** 2026-06-18
**Scope:** docs/prd/0009-real-zsh-git-configuration.md, docs/architecture/0009-real-zsh-git-configuration-architecture.md
**Verdict:** APPROVED WITH NOTES

---

## Summary

PRD-0009 and Architecture-0009 define the transition from placeholder-only managed zsh and Git configuration to real, safe, portable configuration. The PRD correctly identifies the current state (managed layers exist but are unfilled), clearly scopes the adoption strategy (replacing placeholder values in tracked files, creating `.gitconfig.local.example` for documentation), and establishes comprehensive safety and privacy boundaries. Architecture-0009 is thorough, internally consistent, grounded in established ADRs, and provides explicit content boundaries, file tracking decisions, validation steps, and rollback mechanisms. Both documents reflect the project's core principles: safety first, privacy first, and non-destructive adoption.

---

## Findings

### PRD-0009

**Section: Problem Statement**
- 🟢 PASS: Accurately reflects current state — managed layer activation exists (ADR-0021, PRD-0007), managed files are stowed and active, but placeholder tokens remain in `shared.zsh` and real Git common config does not yet exist.
- 🟢 PASS: Correctly identifies the scope boundary — this is about populating existing placeholders, not about file layout or activation wiring (both already decided).

**Section: Goals and Non-Goals**
- 🟢 PASS: Goals are specific and verifiable (replace `YOUR_EDITOR`/`YOUR_PAGER`, create managed `.gitconfig.common` and `.gitignore_global`, define tracking strategy).
- 🟢 PASS: Non-goals explicitly exclude SSH config, GitHub CLI auth, GPG management, stow execution, dependency installation, and home directory modification — all appropriate deferrals or safety constraints.

**Section: Zsh Adoption Strategy — Managed files table**
- 🟢 PASS: `shared.zsh` and `index.zsh` are correctly listed as "Yes — real values" (committed, not `.example`-only). This departs from Architecture-0004's original `.example`-only intent but is justified in Architecture-0009 Section 3 and makes the tracking decision explicit and auditable.
- 🟢 PASS: `local.zsh` correctly marked as "No — git-ignored, no `.example` template." Consistent with ADR-0023.
- 🟢 PASS: `macos.zsh` and `arch.zsh` correctly marked as "Yes (`.example` only)" — platform scope deferred, matching PRD language.

**Section: Zsh Adoption Strategy — Invariants**
- 🟢 PASS: All seven invariants are correct and comprehensive: no install/clone/network, `command -v` guards, Zinit existence-only check, `compinit` conditional, no platform-specific calls in `shared.zsh`, no Homebrew/pacman/platform tools.
- 🟢 PASS: Invariants align with ADR-0020 (Zinit manual clone only) and Architecture-0009 content boundaries.

**Section: Git Adoption Strategy — Local-only files**
- 🟢 PASS: `.gitconfig.local` correctly marked as "No (git-ignored)" and described as "Identity, signing key, work includes."
- 🟡 NOTE: The table lists `.gitconfig.local` but does not mention `.gitconfig.local.example` — a template file that will document the structure. Architecture-0009 Section 4 and the ADR list (Section 11) clarify this is a future addition, but the PRD would benefit from a note that a `.gitconfig.local.example` template (with placeholder values only) will be created separately.

**Section: Git Adoption Strategy — `.gitconfig.common` scope**
- 🟢 PASS: Content boundaries are precise and correct: `[core]` editor/autocrlf/whitespace/excludesfile, `[pull]` rebase, `[merge]` conflictstyle, `[diff]` colorMoved, `[color]` ui, `[alias]`, `[init]` defaultBranch.
- 🟢 PASS: Exclusions are correct: no `[user]`, `[gpg]`, `[commit] gpgsign`, no `[includeIf]`, no work includes, no credentials.

**Section: Git Adoption Strategy — Wiring**
- 🟢 PASS: Include order is correct: `.gitconfig.common` first, `.gitconfig.local` second. Rationale (last definition wins) is sound.

**Section: Validation Strategy — Zsh**
- 🟢 PASS: Five validation steps are clear, ordered, and verifiable: shell starts without errors, environment variables correct, tool guards activate/no-op appropriately, Zinit loads when installed, no brew/pacman/git clone appears in startup.
- 🟢 PASS: `set -x` trace recommendation is practical for verifying no network calls.

**Section: Validation Strategy — Git**
- 🟢 PASS: Five validation steps are concrete and correct: no identity in `.gitconfig.common`, common values active after stow, identity resolves from `.gitconfig.local` not `.gitconfig.common`, global gitignore active, privacy audit passes.
- 🟢 PASS: Privacy audit command pattern (grep for identity-revealing strings) is correct.

**Section: Acceptance Criteria**
- 🟢 PASS: All 11 zsh criteria are verifiable and complete: no `YOUR_*` tokens, no install commands, tool guards present, Zinit guarded, `index.zsh` source order correct, `local.zsh` git-ignored, shell starts on machines with/without tools, `~/.zshrc` unmodified, no platform-specific commands.
- 🟢 PASS: All 8 git criteria are verifiable: `.gitconfig.common` exists and committed, no identity/includeIf in it, `.gitignore_global` committed, `.gitconfig.local` git-ignored, config resolution correct, privacy audit passes.
- 🟢 PASS: General criteria (no home modification, manual stow steps, dry-run first) reinforce safety guardrails.

### Architecture-0009

**Section 1: Zsh File Layout**
- 🟢 PASS: Table is complete and accurate. All 12 files listed with correct committed status, purpose, and owner.
- 🟢 PASS: Row for `shared.zsh` correctly notes "Yes — see Section 4" (tracking decision explained later) and "real values to be added."
- 🟢 PASS: Row for `index.zsh` correctly notes "Yes — see Section 4" and "Currently valid content (no placeholders)."
- 🟢 PASS: `.gitignore` content is correct: guards `shared.zsh`, `index.zsh`, `macos.zsh`, `arch.zsh`, `omp.zsh`, `local.zsh`.

**Section: No-folding rationale**
- 🟢 PASS: Explanation is clear and sound: Stow's folding would create a directory symlink if every entry in `~/.config/zsh/` were managed, but `~/.zshrc` is not in the package so folding does not apply. The XDG layout (`~/.config/zsh/`) avoids the conflict entirely.
- 🟢 PASS: Correctly references ADR-0021, ADR-0022, and ADR-0013 as established principles.

**Section 2: Zsh Content Boundaries — `shared.zsh`**
- 🟢 PASS: "What belongs here" section is comprehensive: XDG exports (with `:-` default pattern respected), `$EDITOR`/`$PAGER` (real portable values), history config, completion init (with Zinit conditional), Zinit guard only, tool guards, portable aliases.
- 🟢 PASS: "Forbidden" section is precise and complete: no install/clone/network, no platform-specific tool calls, no hardcoded paths, no plugin manager init beyond Zinit guard, no prompt init.
- 🟡 NOTE: The decision to replace `YOUR_EDITOR` with `nvim` and `YOUR_PAGER` with `less` is stated in Section 3 but not in this content-boundary section. For clarity, a note here saying "The two placeholder tokens `YOUR_EDITOR` and `YOUR_PAGER` will be replaced with real portable values (`nvim`, `less`) per Section 3" would strengthen the content boundary.

**Section 2: Zsh Content Boundaries — `index.zsh`**
- 🟢 PASS: Correctly specifies source order only, four guarded lines (shared, platform, omp, local), OS-detection conditional. No logic, no environment setting, no aliases, no functions.

**Section 2: Zsh Content Boundaries — `local.zsh`**
- 🟢 PASS: Correctly identifies as machine-specific overrides, work-specific config, private values. Git-ignored, never committed, no `.example` template (ADR-0023). Sourced last so it wins.

**Section 2: Zsh Content Boundaries — `macos.zsh` / `arch.zsh`**
- 🟢 PASS: Correctly states scope is deferred — these remain `.example`-only in this adoption. Platform scope covered by a future PRD.

**Section 2: Zsh Content Boundaries — `omp.zsh`**
- 🟢 PASS: Correctly states scope is deferred — committed only as `.omp.zsh.example`. User may create local copy for personal use.

**Section 3: Zsh Tracking Decision**
- 🟢 PASS: Current state is correctly described: `shared.zsh` and `index.zsh` already tracked (not `.example`-only as Architecture-0004 originally specified). `shared.zsh` has placeholder tokens; `index.zsh` has correct content.
- 🟢 PASS: Option A (replace placeholders in tracked files) and Option B (permanent templates, use ignored local copy) are both presented with pro/con analysis.
- 🟡 NOTE: Option B's structural conflict explanation is correct but could be slightly clearer. Current state: `.gitignore` lists `shared.zsh`, but git respects the tracked file. On a new clone, the tracked `shared.zsh` exists and is used; the `.gitignore` entry prevents accidentally staging a locally-modified copy. This is accurate but the explanation spans three sentences and could be more concise. However, the ultimate conclusion (Option A chosen) is sound.
- 🟢 PASS: Decision (Option A) is justified: `shared.zsh` is already tracked, pattern established by `index.zsh`, content boundaries ensure safety, `.example` remains as template.
- 🟢 PASS: "Safe to commit" definition is precise: portable (both platforms), no identity/secret/path, no install/clone/network, publishable.
- 🟢 PASS: Specific value replacements justified: `nvim` (Homebrew + pacman available, no identity risk), `less` (standard on both platforms, no identity risk).

**Section 4: Git File Layout**
- 🟢 PASS: Table is complete. Seven files listed with correct committed status, purpose, and symlink target.
- 🟡 NOTE: Filename column says `.gitconfig.local.example` "does not yet exist — to be created" but the table row says it's "Yes (does not yet exist — to be created)." This is accurate but the phrasing could be clearer. The intent is that this is a new addition, committed for reference only, not stowed. Architecture-0009 Section 11 (ADR list) clarifies this is ADR-0025, so the cross-reference is present.
- 🟢 PASS: Row for `.gitconfig.local` correctly notes git-ignored via `*.local` pattern and never placed in stow package — lives only in user's `$HOME`, wired via `[include]` in `~/.gitconfig`.
- 🟢 PASS: Note about `.gitconfig.common` creation (copy from `.gitconfig.example`, remove `[user]` block, edit to add real safe settings) is present and correct.

**Section 5: Git Include Architecture — Wiring diagram**
- 🟢 PASS: Diagram clearly shows `~/.gitconfig` including `.gitconfig.common` (symlink) then `.gitconfig.local` (user-owned).
- 🟢 PASS: Include order rationale is sound and repeated: last definition wins, so `.gitconfig.local` overrides `.gitconfig.common`.

**Section 5: Git Include Architecture — Example structures**
- 🟢 PASS: Three example blocks (`.gitconfig` user-owned, `.gitconfig.common` stowed, `.gitconfig.local` user-owned, `.gitconfig.local.example` template) use placeholder values only throughout: `YOUR_NAME`, `YOUR_EMAIL@example.com`, `~/work/` example with comment delimiters.
- 🟢 PASS: No real name, email, hostname, token, or key appears in the example blocks.

**Section 6: Git Content Boundaries — `.gitconfig.common`**
- 🟢 PASS: "What belongs here" is precise: core editor/autocrlf/whitespace/excludesfile, pull rebase, merge conflictstyle, diff colorMoved, color ui, aliases (portable, non-identity), init defaultBranch.
- 🟢 PASS: "Forbidden" section is complete and correct: no `[user]`, no commit/gpgsign, no `[gpg]`, no `[includeIf]`, no credentials, no platform-specific credential helpers.

**Section 6: Git Content Boundaries — `.gitconfig.local`**
- 🟢 PASS: Correctly identifies as user identity, signing key, work includes, machine-specific overrides. Never placed in stow package.

**Section 6: Git Content Boundaries — `.gitignore_global`**
- 🟢 PASS: Content categories are correct and well-organized: macOS artifacts, Linux desktop, editor, build, thumbnail caches, environment files. Rationale states these are well-known tool artifacts, not machine-specific — sound.

**Section 7: Stow Strategy — Zsh**
- 🟢 PASS: Dry-run and fake-home validation commands are correct and copy-pasteable. Uses `stow --dir=stow/common --target="$HOME" --simulate zsh`.
- 🟢 PASS: Manual step marker (`⚠️  MANUAL STEP`) present.
- 🟢 PASS: Motivation for not stowing `~/.zshrc` is restated clearly: file already exists, Stow would refuse without `--adopt` (forbidden), include-based activation achieves same result safely.

**Section 7: Stow Strategy — Git**
- 🟢 PASS: Correctly specifies what stows: `.gitconfig.common`, `.gitignore_global`, `.gitconfig.example`, `.gitignore_global.example`, `.gitconfig.local.example` (all reference/template files).
- 🟢 PASS: Correctly specifies what does NOT stow: `~/.gitconfig` (user-owned), `~/.gitconfig.local` (user-owned, lives at home, never in package).
- 🟢 PASS: Dry-run command is correct. Manual step marker present.

**Section 8: Privacy Boundary**
- 🟢 PASS: Table is comprehensive and correct. Shows what's forbidden (name, email, signing key, SSH, work identity, work paths, tokens, hostname) vs. allowed (editor/pager names, history counts, shell options, ignore patterns, Git settings, portable aliases). All entries are justified.
- 🟢 PASS: `.gitignore` guard descriptions are accurate: Zsh package guards six real files; Git package guards via root `.gitignore` patterns for `.gitconfig.common`, `.gitignore_global`, and `*.local`.
- 🟢 PASS: Pre-commit audit commands are correct and will catch the right patterns: grep for `YOUR_*` in `shared.zsh`, grep for identity-revealing strings in git config examples, confirm git-ignored files are not staged.

**Section 9: Rollback Strategy — Zsh**
- 🟢 PASS: Rollback is fast (under 60 seconds claimed), requires only editing `~/.zshrc` to remove the three-line guarded include block. No stow unstow, no file deletion, no repository changes needed.
- 🟢 PASS: Consistent with ADR-0021 (single guarded include block provides one revert point).

**Section 9: Rollback Strategy — Git**
- 🟢 PASS: Rollback is similarly fast: remove or comment out `[include] path = ~/.gitconfig.common` from `~/.gitconfig`. Managed files remain as symlinks but are not applied.

**Section 10: Validation Steps — Zsh**
- 🟢 PASS: Seven validation steps are ordered, complete, and verifiable:
  1. Syntax check (zsh -n) — correct command.
  2. No placeholder tokens (grep 'YOUR_') — correct pattern.
  3. No forbidden content (grep for install commands, network ops, platform-specific calls) — correct patterns including brew, pacman, yay, pbcopy/paste, apt, systemctl, git clone, curl, wget.
  4. Package layout validation (fake-home, stow --simulate) — correct.
  5. Shell startup check (zsh -ic 'echo zsh-ok') — correct.
  6. Tool guard verification — practical approach (rename binary or test on machine without tool).
  7. `~/.zshrc` unchanged check (stat) — correct.

**Section 10: Validation Steps — Git**
- 🟢 PASS: Six validation steps are ordered and concrete:
  1. No identity in common config (grep for signingkey, user, gpg, gpgsign) — correct patterns.
  2. Package layout dry-run — correct.
  3. Config origin check (git config --list --show-origin) — verifies active values.
  4. Identity resolution check (git config --show-origin user.name/email) — confirms resolution from local file.
  5. Excludesfile active check (git config --global core.excludesfile) — correct.
  6. Privacy audit (git diff --staged) — correct pattern search for identity-revealing strings.

**Section 11: ADRs to Create**
- 🟢 PASS: Three ADRs proposed (0024, 0025, 0026) with correct titles and justifications:
  - ADR-0024: `shared.zsh` and `index.zsh` tracked with real safe content.
  - ADR-0025: `.gitconfig.local.example` committed as identity structure reference.
  - ADR-0026: `[init] defaultBranch = main` belongs in `.gitconfig.common`.
- 🟢 PASS: Each ADR entry states why it matters.

**Section 12: Open Questions**
- 🟢 PASS: Four open questions are realistic and labeled correctly as non-blocking:
  1. `$EDITOR` value (`nvim` proposed) — non-blocking if acceptable.
  2. Additional aliases beyond `grep` — non-blocking.
  3. `.gitconfig.local.example` placement (in stow package vs. docs only) — recommends stow-to-home approach, consistent with `zshrc.example`. Non-blocking.
  4. `diff.algorithm` in `.gitconfig.common` — nice-to-have, not in original scope. Non-blocking.

**Section: Risks**
- 🟢 PASS: Seven risks identified with likelihood, severity, and mitigation:
  1. `shared.zsh` committed with real editor/pager path containing username — Low/Medium, mitigated by pre-commit grep.
  2. `.gitconfig.common` committed with `[user]` block forgotten — Low/High, mitigated by validation step.
  3. `.gitconfig.local.example` confused with real `.gitconfig.local` and committed with real values — Low/High, mitigated by suffix signal and `.gitignore` guard.
  4. `shared.zsh` edited to add platform-specific call — Low/Medium, mitigated by content boundary and pre-commit grep.
  5. User fills `.gitconfig.common` with identity, stows it, then commits — Low/High, mitigated by root `.gitignore` guard and force-add requirement.
  6. `index.zsh` gains logic beyond source order — Low/Low, mitigated by content boundary.
  7. Zinit auto-clone reintroduced — Low/High, mitigated by ADR-0020 and validation step.
- 🟢 PASS: Risk assessment is realistic and mitigations are sound.

---

### Cross-Document Consistency

- 🟢 PASS: PRD-0009 non-goals match Architecture-0009 out-of-scope: SSH config, GitHub CLI, GPG, Zinit plugin list, Oh My Posh theme, platform-specific zsh (deferred), Stow execution, home modification.
- 🟢 PASS: PRD acceptance criteria align with Architecture validation steps: syntax checks, no placeholders, no forbidden content, shell startup test, identity resolution test, privacy audit.
- 🟢 PASS: Architecture references correct ADRs: 0001 (platform-first layout), 0003 (example files), 0013 (include-based Git strategy), 0014 (gitconfig.common filename), 0016 (zsh in common package with runtime OS detection), 0020 (Zinit manual clone), 0021 (guarded include block), 0022 (migration model), 0023 (local.zsh override slot).
- 🟢 PASS: Architecture references correct PRD numbers: 0003, 0004, 0006, 0007 in PRD-0009 "Related" section. Architecture-0009 references PRD-0009 correctly.

---

### Safety and Privacy

- 🟢 PASS: No real name, email, hostname, token, key, or path appears in either document. All examples use placeholder values: `YOUR_EDITOR`, `YOUR_PAGER`, `YOUR_NAME`, `YOUR_EMAIL@example.com`, hostname.example.com, `~/work/` (commented).
- 🟢 PASS: No `stow --adopt` usage anywhere.
- 🟢 PASS: No `rm`, `mv`, or `ln -s` against `$HOME` — all stow commands are shown, never executed, marked with manual step warning.
- 🟢 PASS: No install commands in managed shell files. `shared.zsh` explicitly forbids install commands, and the pre-commit audit checks for them.
- 🟢 PASS: No network calls in managed shell files. Zinit is guarded source-only (ADR-0020). Tool guards are no-op when absent.
- 🟢 PASS: Zsh activation is include-based (guarded single block in user-owned `~/.zshrc`), not destructive replacement.
- 🟢 PASS: Git adoption is include-based (user's `~/.gitconfig` includes the managed common layer), not destructive.

---

## Verdict

**APPROVED WITH NOTES**

The documents are well-structured, comprehensive, and aligned with the repository's core principles. The PRD correctly identifies the current state and scopes the work. The architecture is detailed, grounded in established ADRs, and includes explicit content boundaries, tracking decisions (with justification), and validation/rollback steps. Both documents reflect deep understanding of the safety and privacy constraints.

**Reasons for approval:**
1. Problem statement and goals are accurate and verifiable.
2. Non-goals and scope boundaries are explicit and appropriate.
3. Content boundaries for both zsh and Git are precise, complete, and enforced by validation steps.
4. File tracking decision (Option A: replace placeholders in tracked files) is justified and makes the trade-off auditable.
5. Validation steps are concrete, ordered, and catch the right patterns (no identities, no install commands, no network calls, shell starts correctly).
6. Rollback strategies for both zsh and Git are fast and non-destructive (edits only, no stow unstow).
7. Privacy audit commands are correct and will catch secrets before commit.
8. Cross-document consistency is maintained: PRD goals align with architecture validation, ADR references are correct.
9. Safety guardrails are comprehensive: no `stow --adopt`, no home modification, placeholder examples throughout, pre-commit audits, manual step warnings.

**Blocking issues:** None.

**Non-blocking notes:**
1. PRD Section 2 (Git Adoption Strategy) could note that `.gitconfig.local.example` (template) will be created as a separate addition — Architecture-0009 clarifies this (ADR-0025), but explicit mention in the PRD table would improve clarity.
2. Architecture-0009 Section 2 could note in the `shared.zsh` content boundaries that the two placeholder tokens will be replaced with specific portable values (nvim, less), for consistency with Section 3's tracking decision.
3. Architecture-0009 Section 3's explanation of Option B's structural conflict (tracked vs. ignored) is accurate but spans three sentences; slight condensing could improve readability. However, the ultimate conclusion (Option A) is sound and well-justified.

These notes do not block planning or implementation. Proceed to planning phase.

---

## Recommended Next Step

Planner converts this architecture into an ordered implementation plan under `docs/plans/0009-real-zsh-git-configuration-plan.md`. The plan should:

1. Task 1: Replace placeholder tokens in `stow/common/zsh/.config/zsh/shared.zsh` (YOUR_EDITOR → nvim, YOUR_PAGER → less).
2. Task 2: Create `stow/common/git/.gitconfig.local.example` with placeholder identity structure.
3. Task 3: Update `stow/common/git/.gitconfig.example` (move `[user]` block to comment, add `[init] defaultBranch = main`).
4. Task 4: Document user steps for creating `.gitconfig.common` and `.gitignore_global` locally (copy from `.example`, remove identity, edit with real values).
5. Task 5: Write ADRs 0024, 0025, 0026.
6. Task 6: Update `docs/stow-usage.md` Git section.
7. Per-task validation and rollback steps (from Architecture Section 10).

Plan must include explicit safety checks: `~/.zshrc` unmodified, `$HOME` unmodified, no Stow run against real home, no dependencies installed, all new/modified files audited for secrets before staging.
