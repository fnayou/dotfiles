# Review: Zsh PRD and Architecture

**Number:** 0009
**Status:** Complete
**Date:** 2026-06-17
**Reviewer:** Claude Code
**Files reviewed:**
- docs/prd/0004-zsh-configuration.md
- docs/architecture/0004-zsh-configuration-architecture.md

---

## Verdict

**APPROVED** — all minors and notes resolved 2026-06-17.

Both documents are well-structured, safety-conscious, and aligned with established ADRs and repository rules. The XDG-style layout decision (Option B) is justified and defensible. All 6 minor findings and 3 notes from the original review have been applied to the PRD and architecture documents (see Resolution Log below).

---

## Findings

### docs/prd/0004-zsh-configuration.md

**PRD-L109: 🟡 MINOR — Homebrew path initialization example uses unquoted path.**

PRD line 191 (in architecture, mirrored from PRD reasoning):
```zsh
eval "$(YOUR_HOMEBREW_PREFIX/bin/brew shellenv)"
```

The `YOUR_HOMEBREW_PREFIX` placeholder must be quoted or the shell will interpret it as a variable reference. Fix: wrap in `"$(...)"` and clarify in comment that the user replaces `YOUR_HOMEBREW_PREFIX` as a literal string token, not a shell variable.

Scope: Documentation clarity only, not a blocker for implementation.

---

**PRD-L163: 🔵 NOTE — Git package context link.**

PRD L163 notes that the Git package established XDG preference. This context is valuable. Consider linking to `docs/decisions/0013-include-based-git-config-strategy.md` for implementers who need to understand the precedent.

Scope: Optional improvement, no action required if intentional.

---

### docs/architecture/0004-zsh-configuration-architecture.md

**ARCH-L25: 🟡 MINOR — `$ZDOTDIR` deferral rationale could be more explicit.**

Architecture L477–479 (Decision 4) correctly defers `$ZDOTDIR`. The rationale is sound but could note that `$ZDOTDIR` affects zsh startup sequence (it changes where zsh looks for `~/.zshrc` entirely). Recommend clarifying: "Setting `$ZDOTDIR` requires modifying `$HOME/.zshenv` or shell startup configuration — equivalent or higher risk to touching `~/.zshrc`. Explicit `source` calls achieve the same result with **lower risk and no change to zsh's initialization order**." This strengthens the safety argument.

Scope: Documentation clarity, no impact on implementation.

---

**ARCH-L223: 🟡 MINOR — Homebrew path example uses unquoted variable placeholder.**

Architecture L223:
```zsh
eval "$(YOUR_HOMEBREW_PREFIX/bin/brew shellenv)"
```

Same issue as PRD-L109. The placeholder `YOUR_HOMEBREW_PREFIX` is not a valid shell variable name and will cause syntax error if left as-is. Recommend: update to use a shell-safe token like `YOUR_HOMEBREW_PATH` or quote the example to make replacement more obvious. Add a comment: `# User replaces YOUR_HOMEBREW_PREFIX with /opt/homebrew (Apple Silicon) or /usr/local (Intel)`.

Scope: Critical for implementer clarity; not a blocker but must be fixed in the `.example` file itself during implementation phase.

---

**ARCH-L232: 🟡 MINOR — Missing documentation of `~/.zshrc` bootstrap in stow-usage.md.**

Architecture recommends updating `docs/stow-usage.md` to include a zsh package section (L362). The current `stow-usage.md` (reviewed separately) documents git package adoption in detail but does not yet reference zsh. Architecture should be explicit that the `.md` update is mandatory before Phase 2 completion, and should show exactly what snippet to add to `stow-usage.md` for the zsh package.

Scope: Implementation planning only; architecture document is correct to note the dependency.

---

**ARCH-L303–308: 🔵 NOTE — Symlink asymmetry on non-matching platform.**

Architecture notes that `arch.zsh` is symlinked on macOS (and vice versa). The note is correct: unused symlinks are harmless. Confirmation: this design is intentional and aligns with "simplicity over perfect separation" principle. No issue.

---

**ARCH-L330: 🟡 MINOR — `cp` command shown in architecture may be clearer with absolute source path.**

Architecture L329–331 shows:
```bash
cp stow/common/zsh/.config/zsh/shared.zsh.example stow/common/zsh/.config/zsh/shared.zsh
```

For absolute clarity, recommend prefixing with the repository root or using `$PWD`:
```bash
cp "$PWD/stow/common/zsh/.config/zsh/shared.zsh.example" stow/common/zsh/.config/zsh/shared.zsh
```

Or show both forms (relative and absolute). This prevents user error if they run from a different working directory.

Scope: Documentation clarity; low risk of actual problem in Phase 4 (user action) since user reads architecture from repository.

---

**ARCH-L334–340: 🟡 MINOR — `.gitignore` entries placement.**

Architecture recommends adding three entries to `.gitignore`:
```
stow/common/zsh/.config/zsh/shared.zsh
stow/common/zsh/.config/zsh/macos.zsh
stow/common/zsh/.config/zsh/arch.zsh
```

This is correct. Recommendation: during Phase 2 (scaffold), create a directory-level `.gitignore` in `stow/common/zsh/.config/zsh/` instead of global entries. This keeps platform/package-specific ignores close to the files and scales better as more packages are added.

Scope: Implementation choice; architecture is correct either way.

---

**ARCH-L402–406: 🟡 MINOR — Rollback verification commands assume `~/.config/zsh/` is empty post-rollback.**

Architecture L427–431 shows:
```bash
ls ~/.config/zsh/
```

If `~/.config/zsh/` contains other files (user's own scripts), this directory will be non-empty after rollback. Recommend clarifying: `ls ~/.config/zsh/` should show no symlinks pointing to stow packages — or show only user-created files. This avoids false-negative verification.

Scope: Implementation documentation only, not a blocker.

---

**ARCH-L508–526: 🔵 NOTE — ADR-0016 proposal.**

Architecture recommends creating ADR-0016 on "Zsh files in `stow/common/zsh/` with runtime OS detection". This is appropriate and aligns with the project's ADR workflow. No issues.

---

## Cross-Check: Safety, Privacy, Stow Rules

### Safety Rules Compliance

✓ **Never modify `~/.zshrc` before stowing** — Confirmed. PRD L63, Architecture L39, L177–189.

✓ **No symlinks without approval** — Confirmed. Both docs explicitly state dry-run + manual approval required. Architecture L285–292.

✓ **No `stow --adopt`** — Confirmed. PRD L65, Architecture forbids it implicitly (uses only `--simulate` and clean `stow`).

✓ **No `$HOME` modifications** — Confirmed. Architecture explicitly defers all user-facing adoption (Phase 4+) to manual user action.

✓ **Dry-run before install** — Confirmed. Architecture L275–293.

### Privacy Rules Compliance

✓ **No real API keys, tokens, credentials** — Confirmed. All three files are `.example` only; PRD L56, L74–78.

✓ **Placeholder values mandatory** — Confirmed. Architecture L232–236, L252–254. Both docs enforce `$HOME`, `YOUR_VALUE`, `YOUR_HOMEBREW_PREFIX` patterns.

⚠️ **Exception flagged above** — Homebrew path example (ARCH-L223, PRD-L191) uses unquoted placeholder. Recommend clarifying in implementation `.example` file comments.

### Stow Rules Compliance

✓ **Package-based layout** — Confirmed. `stow/common/zsh/` follows ADR-0001.

✓ **`--dir` and `--target` explicit** — Confirmed. Architecture L276, L282–283, L292.

✓ **`--simulate` always first** — Confirmed. Architecture L275–279.

✓ **No `.example` files stowed directly** — Confirmed. Architecture L314–320; user copies and fills before stowing.

✓ **No flat `stow .`** — Confirmed. Only `stow --dir=stow/common --target="$HOME" zsh` shown.

### Cross-Platform Rules Compliance

✓ **macOS and Arch separated** — Confirmed. Three separate files: `shared.zsh`, `macos.zsh`, `arch.zsh`.

✓ **No Homebrew in shared** — Confirmed. Architecture L136.

✓ **No pacman/yay in shared** — Confirmed. Architecture L137.

✓ **OS detection explicit** — Confirmed. Architecture L184–188; uses documented `$OSTYPE` and `/etc/arch-release` pattern from cross-platform rules.

✓ **No hardcoded paths** — Confirmed. Architecture L157, L174 forbid hardcoded absolute paths; recommends `$HOME`, `$XDG_CONFIG_HOME`.

---

## Summary

| Severity | Count | Details |
|---|---|---|
| 🔴 BLOCKER | 0 | None. Documents are safe to approve. |
| 🟠 MAJOR | 0 | None. All major design decisions are sound. |
| 🟡 MINOR | 6 | Documentation clarity, placeholder examples, `.gitignore` placement, rollback verification. |
| 🔵 NOTE | 3 | Context improvements, ADR proposal, intentional design choices. |

---

## Resolution Log

All findings resolved 2026-06-17:

| Finding | Resolution |
|---|---|
| PRD-L109 / ARCH-L223 (Homebrew placeholder) | Both files clarify `YOUR_HOMEBREW_PREFIX` is a literal placeholder, not a shell variable; architecture example gains an inline comment. |
| PRD-L163 (Git package link) | PRD note now links `docs/decisions/0013-include-based-git-config-strategy.md`. |
| ARCH-L25 (`$ZDOTDIR` rationale) | Decision 4 expanded: explains `$ZDOTDIR` changes zsh startup file lookup, requires `~/.zshenv` edit, and that source-block has lower risk / no init-order change. |
| ARCH-L232 (`stow-usage.md` update) | Phase 2 now marks the `stow-usage.md` zsh section as mandatory, listing required contents. |
| ARCH-L330 (`cp` paths) | Copy commands now state paths are relative to repository root. |
| ARCH-L334–340 (`.gitignore` placement) | Architecture now prefers a directory-level `.gitignore` at `stow/common/zsh/.config/zsh/.gitignore`. |
| ARCH-L402–406 (rollback verification) | Rollback uses `ls -l` and clarifies a clean rollback shows no symlinks resolving to `stow/common/zsh/`. |
| Notes (symlink asymmetry, ADR-0016) | Confirmed intentional; no change required. |

---

## Recommended Next Step

**Planner converts this architecture into `docs/plans/0004-zsh-configuration-plan.md`**, including:

1. Phase 2 scaffold task: create `stow/common/zsh/.config/zsh/` directory structure.
2. Create three `.example` files with placeholder content (fixing homebrew path example syntax per ARCH-L223 finding).
3. Create `.gitignore` entry or directory-level ignore file (per ARCH-L334–340 note).
4. Update `docs/stow-usage.md` with zsh package adoption section (per ARCH-L232 note).
5. Create ADR-0016 for zsh runtime OS detection pattern (per ARCH-L508–526 note).
6. All tasks validated with read-only checks — no stow invoked, no `$HOME` modified.

Before **Builder** starts implementation, ensure:

- [ ] All homebrew placeholder examples clarified in architecture (e.g., "replace `YOUR_HOMEBREW_PREFIX` with `/opt/homebrew` or `/usr/local`").
- [ ] Plan includes explicit note about `$ZDOTDIR` deferral rationale (per ARCH-L25 finding).
- [ ] Plan includes validation step: confirm no `.example` files have unescaped shell syntax before stowing Phase 4.

---

## Audit Checklist (Reviewer Input to Future Builder)

Before committing any `.example` files:

- [ ] Homebrew path examples use shell-safe syntax (quoted or explicitly marked as literal placeholders).
- [ ] All placeholder tokens (`YOUR_*`) are explained in file comments.
- [ ] No real API keys, tokens, paths, or personal values in any file.
- [ ] `.gitignore` entries added for the three real (non-example) filenames.
- [ ] `docs/stow-usage.md` updated with zsh section.
- [ ] ADR-0016 written and linked in architecture document.
- [ ] All `.example` files are valid zsh syntax (even with placeholders) or clearly marked as non-executable.

