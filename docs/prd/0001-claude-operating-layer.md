# PRD: Claude Code Operating Layer

**Number:** 0001
**Status:** Approved
**Date:** 2026-06-15

---

## Context

Before implementing any dotfiles, a Claude Code operating layer was established to define how AI agents govern this repository safely and consistently. This layer sets the rules, roles, skills, and documentation structure that all future work builds on.

This is a retrospective PRD — the work described here is already complete. It is written to satisfy the PRD-first workflow and to document scope and intent for future reference.

---

## Problem Statement

Without a defined operating contract, Claude agents would have no consistent rules for safety, privacy, cross-platform behavior, or documentation. Ad-hoc agent behavior risks:

- Accidental home directory modification.
- Secret or credential leakage via committed files.
- Inconsistent decisions between sessions.
- No audit trail for architectural choices.
- No clear separation of agent responsibilities.

A structured operating layer prevents these risks before dotfiles implementation begins.

---

## Goals

1. Establish `AGENTS.md` as the single, authoritative operating contract for all agents and sessions.
2. Define four agent roles with explicit responsibilities and output formats: Architect, Planner, Builder, Reviewer.
3. Create a five-step agent handoff flow: Architect → Planner → Builder → Reviewer → Commit.
4. Create rule files covering safety, privacy, GNU Stow usage, documentation, and cross-platform behavior.
5. Create skill files for recurring structured tasks: `create-prd`, `create-architecture`, `create-plan`, `add-dotfile-package`.
6. Create persistent documentation directories for PRDs, architecture proposals, plans, reviews, and decision records.
7. Add root project hygiene files: `README.md`, `.gitignore`, `.editorconfig`, `LICENSE`.
8. Ensure the repository is ready for safe, incremental dotfiles implementation to begin.

---

## Non-Goals

- Implement any dotfiles.
- Create GNU Stow packages.
- Modify or inspect the real home directory.
- Configure real shell, editor, terminal, or tool settings.
- Replace or symlink any existing user configuration.
- Set up package managers (Homebrew, pacman).
- Set up Docker or test harnesses.
- Set up secrets management.

---

## Scope

### Files created

| File / Directory | Purpose |
|---|---|
| `AGENTS.md` | Main operating contract — agent roles, handoff flow, all rules |
| `CLAUDE.md` | Short Claude Code entry point — reads AGENTS.md |
| `.claude/agents/architect.md` | Architect agent definition |
| `.claude/agents/planner.md` | Planner agent definition |
| `.claude/agents/builder.md` | Builder agent definition |
| `.claude/agents/reviewer.md` | Reviewer agent definition |
| `.claude/rules/safety.md` | Forbidden actions and required approach |
| `.claude/rules/privacy.md` | Secret and credential handling rules |
| `.claude/rules/stow.md` | GNU Stow usage rules |
| `.claude/rules/documentation.md` | Document format, naming, and directory rules |
| `.claude/rules/cross-platform.md` | macOS vs. Arch separation rules |
| `.claude/skills/create-prd.md` | Skill: produce a PRD document |
| `.claude/skills/create-architecture.md` | Skill: produce an architecture document |
| `.claude/skills/create-plan.md` | Skill: produce an implementation plan |
| `.claude/skills/add-dotfile-package.md` | Skill: add a new Stow package safely |
| `docs/prd/` | PRD directory |
| `docs/architecture/` | Architecture proposals directory |
| `docs/plans/` | Implementation plans directory |
| `docs/reviews/` | Review reports directory |
| `docs/decisions/` | ADR-style decision records directory |
| `docs/claude/` | Agent guides and workflow documentation |
| `README.md` | User-oriented project overview |
| `.gitignore` | Excludes secrets, OS files, editor files, temp files |
| `.editorconfig` | Consistent editor settings across tools |
| `LICENSE` | All-rights-reserved personal notice |

### Not in scope

- `stow/` directory and all Stow packages.
- `packages/` directory and Brewfiles.
- `scripts/` directory and helper scripts.
- `Taskfile.yml`.
- `test/` directory and Docker harnesses.
- Any file outside the repository root.

---

## Safety Requirements

- No command that modifies `$HOME` may be run as part of this scope.
- No `stow`, `stow --adopt`, `rm`, `mv`, or `ln -s` against `$HOME` may be run.
- No real user dotfiles may be inspected, copied, or referenced.
- All agent rules must enforce dry-run-first behavior for any future Stow operation.
- All dangerous commands in documentation must be marked with `⚠️  MANUAL STEP`.

---

## Privacy Requirements

- No real credentials, API keys, tokens, passwords, or SSH private keys may be committed.
- No private hostnames, internal IP addresses, or work-specific secrets may be committed.
- No real email addresses used as identity or credentials may be committed.
- No machine-specific paths (e.g., `/Users/fnayou/`) may appear in committed files.
- All example configuration must use placeholder values only.

---

## Cross-Platform Considerations

The operating layer itself is platform-neutral — it is Markdown and YAML that runs in Claude Code on any OS.

However, the rules and agents it defines must enforce cross-platform discipline for all future work:

- macOS (primary) and EndeavourOS / Arch Linux (secondary) are always treated separately.
- Agent rules must never assume Homebrew on Arch or pacman on macOS.
- Future Stow packages must be separated into `common/`, `macos/`, and `arch/`.
- Future scripts must detect OS before suggesting package manager commands.

---

## Acceptance Criteria

- [x] `AGENTS.md` exists and defines Architect, Planner, Builder, and Reviewer roles with output formats.
- [x] `CLAUDE.md` exists and points to `AGENTS.md`.
- [x] All four agent files exist under `.claude/agents/`.
- [x] All five rule files exist under `.claude/rules/`.
- [x] Skill files exist under `.claude/skills/`.
- [x] All documentation directories exist under `docs/`.
- [x] `README.md` exists with project purpose, status, safety rules, and planned direction.
- [x] `.gitignore` exists and covers secrets, OS files, editor files, and local overrides.
- [x] `.editorconfig` exists with UTF-8, LF, final newline, and 2-space indent.
- [x] `LICENSE` exists with all-rights-reserved personal notice.
- [x] No dotfiles have been implemented.
- [x] No GNU Stow packages have been created.
- [x] No home directory has been modified.
- [x] No secrets or credentials are present in any committed file.

---

## Out-of-Scope Items

| Item | Status |
|---|---|
| Dotfiles implementation | Not started — future scope |
| GNU Stow packages | Not created — future scope |
| Home directory modifications | Forbidden until explicitly requested |
| Shell configuration (zsh) | Deferred |
| Editor configuration (Neovim) | Deferred |
| Terminal configuration | Deferred |
| Homebrew Brewfiles | Deferred |
| SSH configuration | Explicit non-goal — managed manually per host |
| Secrets management (`pass`) | Deferred — future evaluation |
| Docker test harness | Deferred — future optional |
| macOS system preferences | Deferred |
| Arch system configuration | Deferred |

---

## Related Documents

| Document | Path |
|---|---|
| Architecture proposal | `docs/architecture/0001-dotfiles-repository-architecture.md` |
| Initial scaffold plan | `docs/plans/0001-initial-repository-scaffold.md` |
| Root hygiene plan | `docs/plans/0002-root-project-hygiene-files.md` |
| ADR: Platform-first Stow layout | `docs/decisions/0001-platform-first-stow-layout.md` |
| ADR: go-task as task runner | `docs/decisions/0002-go-task-as-task-runner.md` |
| ADR: .example files for sensitive config | `docs/decisions/0003-example-files-for-sensitive-config.md` |
| ADR: XDG mixed-mode adoption | `docs/decisions/0004-xdg-mixed-mode-adoption.md` |
| ADR: SSH config out of scope | `docs/decisions/0005-ssh-config-out-of-scope.md` |
| ADR: Git config templates only | `docs/decisions/0006-git-config-templates-only.md` |
| ADR: Homebrew split Brewfiles | `docs/decisions/0007-homebrew-split-brewfiles.md` |
