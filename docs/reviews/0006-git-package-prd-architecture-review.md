# Review: Git Package PRD and Architecture

**Number:** 0006
**Status:** Complete
**Date:** 2026-06-17
**Reviewer:** Architect Review Agent
**Documents reviewed:**
- docs/prd/0003-git-package.md
- docs/architecture/0003-git-package-architecture.md

---

## Verdict

**APPROVED WITH NOTES**

Both documents pass all safety, privacy, scope, and cross-platform checks. The PRD correctly defines the Git package scope, non-goals, and acceptance criteria. The architecture clearly maps to the PRD and provides a detailed implementation blueprint. One formatting issue requires correction before implementation begins.

---

## Findings

### Safety
- ✓ No command modifies `$HOME` or files outside the repo root without explicit user approval.
- ✓ All Stow install commands have dry-run steps preceding them.
- ✓ `stow --adopt` is never suggested.
- ✓ No `rm`, `mv`, or `ln -s` against `$HOME` is proposed.
- ✓ Dry-run output review is mandatory before any install.
- ⚠️ **MINOR:** Marker placement issue — `⚠️ MANUAL STEP` marker is separated from code fence by blank lines in three locations (architecture lines 83-87, 215-219, 256-260). Per documentation.md rule, the marker must be "on the line directly preceding the code block fence." Currently blank lines appear between marker and fence.

### Privacy
- ✓ No real identity (name, email) proposed or copied.
- ✓ No real `~/.gitconfig` or global gitignore is read, inspected, or copied.
- ✓ No signing keys, GPG config, SSH keys, or tokens appear.
- ✓ No private hostnames, internal URLs, or work-specific values.
- ✓ All example placeholder values follow approved conventions (`Your Name`, `your-email@example.com`).
- ✓ ADR-0003 (`.example` file strategy) is correctly applied.

### Scope Compliance
- ✓ Git signing configuration is fully out of scope per ADR-0006 (no signing lines in examples, explicitly deferred).
- ✓ SSH configuration is fully out of scope per ADR-0005 (permanent non-goal, not mentioned anywhere).
- ✓ GitHub CLI authentication is out of scope (not mentioned).
- ✓ Work-specific identities and `[includeIf]` are explicitly out of scope (PRD line 127-128).
- ✓ No automatic replacement of existing `~/.gitconfig` — include-based strategy is non-destructive.
- ✓ Scope is appropriately sized for a first real package (two example files plus adoption documentation).

### Stow Layout
- ✓ Package layout uses `stow/common/git/` correctly.
- ✓ `.example` files are never stowed directly — adoption requires user rename (ADR-0003 enforced).
- ✓ Architecture properly documents that `.gitconfig.common` and `.gitignore_global` must be added to `.gitignore` to prevent accidental commits (line 409-420).
- ✓ Commands use ADR-0012 form: `stow --dir=stow/common --target="$HOME" git` (explicit AREA/PACKAGE split).

### Include-Based Strategy
- ✓ Non-destructive — real `~/.gitconfig` is never overwritten.
- ✓ Reversible — removing `[include]` line disables the managed config.
- ✓ Identity (name, email) explicitly does NOT go in `.gitconfig.common` (architecture line 115).
- ✓ The `[include]` line is added manually by the user to their local `~/.gitconfig`, not automated.
- ✓ Model clearly illustrated with path mapping (architecture lines 57-63).

### Cross-Platform
- ✓ All settings in common config are valid on both macOS and EndeavourOS/Arch (architecture lines 269-289).
- ✓ No macOS-only tools (e.g., `osxkeychain`) in common package.
- ✓ No Arch-only tools in common package.
- ✓ File paths use `$HOME`-relative notation (`~/.gitconfig.common`, `~/.gitignore_global`), portable across both platforms.
- ✓ Per-setting compatibility analysis provided (architecture table, lines 272-283).

### Documentation Quality
- ✓ Commands are copy-pasteable and correct (ADR-0012 form validated).
- ✓ Adoption steps are clear and numbered.
- ✓ Validation commands provided both before and after stowing.
- ✓ Conflict resolution documented with explicit prohibition on `--adopt`.
- ⚠️ **MINOR:** Marker formatting (see Safety section above) requires correction.

### Cross-Reference Accuracy
- ✓ PRD correctly references ADRs (ADR-0003, ADR-0005, ADR-0006, ADR-0001).
- ✓ Architecture correctly cites PRD and parent architecture.
- ✓ Decision rationale aligns with existing project decisions.

---

## Recommended Actions

1. **Before implementation:** Fix marker placement in architecture document:
   - Lines 83-87: Remove blank line between marker and code fence.
   - Lines 215-219: Remove blank line between marker and code fence.
   - Lines 256-260: Remove blank line between marker and code fence.
   
   Correct format:
   ```
   ⚠️  MANUAL STEP — review dry-run output before running
   ```bash
   stow --dir=stow/common --target="$HOME" git
   ```
   ```

2. **Before implementation:** Planner should create `docs/plans/0003-git-package-plan.md` converting this architecture into ordered tasks, including:
   - Write ADRs-0013, 0014, 0015 (proposed in architecture line 434-440).
   - Populate `.gitconfig.example` with content from architecture lines 141-174.
   - Create `.gitignore_global.example` with patterns from architecture lines 188-197.
   - Update `.gitignore` with `.gitconfig.common` and `.gitignore_global` entries.
   - Create adoption documentation.
   - Define per-task validation commands.

3. **Reviewer stage:** Before commit, verify:
   - `.gitconfig.common` and `.gitignore_global` are added to `.gitignore`.
   - No real identity values appear in committed `.example` files.
   - No signing-related keys in examples (verify absence of `signingkey`, `gpgsign`, `gpg.`).
   - All commands are copy-pasteable and safe.

---

## Notes

### Alignment with Project Decisions
- **ADR-0001** (platform-first layout): Package correctly uses `stow/common/` and satisfies all three common-package criteria.
- **ADR-0003** (`.example` files): Strategy correctly applied — users rename locally before stowing.
- **ADR-0005** (SSH out of scope): Correctly respected — no SSH configuration mentioned.
- **ADR-0006** (Git templates only): Correctly applied — templates with placeholders, no identity hardcoding, no signing config.
- **ADR-0012** (AREA/PACKAGE split): Commands correctly use the two-variable form for Stow invocation.

### Include-Based Strategy Strengths
The `[include]` mechanism (Git 1.7.10+, 2012) is a strong choice:
- Fully compatible on both macOS and Arch.
- Clean separation of concerns (portable settings vs. identity/private settings).
- Non-destructive and reversible — can be disabled by removing one line.
- Additive — new settings in `.gitconfig.common` are picked up automatically.

### Global Gitignore Patterns
Patterns listed (macOS, Linux, editor, build, environment files) are appropriate for a common package and unlikely to conflict with user preferences.

### Platform Credential Helpers
Correctly deferred — these belong in platform-specific packages (`stow/macos/git/` or `stow/arch/git/`) under separate PRDs. Common package properly excludes them.

### Future Extensibility
Architecture clearly documents extensibility paths (lines 425-430): platform credential helpers, work identity, signing configuration, new aliases, and gitignore patterns. No blocker for future evolution.

---

## Safety Checklist (Pre-Implementation)

Before the Planner or Builder begins, confirm:

- [ ] `.gitconfig.common` and `.gitignore_global` will be added to `.gitignore` (documented in architecture but must be actioned).
- [ ] No real email, name, or credentials will be used in example files.
- [ ] No signing keys or signing configuration will appear in examples.
- [ ] All adoption documentation will use copy-pasteable, safe commands.
- [ ] Marker placement will be corrected (blank lines removed).
- [ ] Reviewer pre-commit checklist will be applied (see AGENTS.md section 4, Reviewer role).

