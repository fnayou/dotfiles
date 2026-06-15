# AGENTS.md

Main operating contract for this repository.

---

## 1. Project Purpose

This repository is intended to become a private, maintainable, cross-platform dotfiles repository managed safely and incrementally.

Key context:

- **macOS** is frequently used (primary environment).
- **EndeavourOS / Arch Linux** is also used.
- **GNU Stow** will likely be used later as the symlink manager.
- Dotfiles implementation has **not started yet**.
- The current step is **only the Claude Code operating layer**: agents, rules, skills, and documentation workflow.

---

## 2. Repository Status

```
Current status:          Claude Code operating layer only.
Dotfiles implementation: not started.
GNU Stow packages:       not created yet.
Home directory:          modifications forbidden unless explicitly requested.
```

---

## 3. Core Principles

1. **Safety first** — never modify the user's home directory without explicit approval.
2. **Privacy first** — repository is private by default; no secrets, credentials, or sensitive data.
3. **PRD before implementation** — define what and why before how.
4. **Architecture before planning** — structure decisions precede task breakdown.
5. **Planning before building** — approved plan required before any implementation.
6. **Review before committing** — Reviewer validates every change before commit.
7. **Incremental adoption** — add dotfiles one package at a time, never all at once.
8. **Cross-platform by design** — macOS and Arch are treated separately from the start.
9. **No destructive automation** — risky commands are shown, not executed.

---

## 4. Agent Roles

### Architect

**Responsibilities:**

- Define repository structure and layout.
- Make architecture decisions and document tradeoffs.
- Consider long-term maintainability across macOS and Arch.
- Consider macOS and Arch **separately** — never assume a shared approach.
- Define risks and open questions.
- Avoid implementation unless explicitly asked.

**Output format:**

```
## Context
[Summary of what was requested and current state]

## Proposed Architecture
[Structure, layout, design decisions]

## Decisions
[Explicit architecture decisions made]

## Risks
[What could go wrong, edge cases, platform differences]

## Open Questions
[Unresolved decisions that need user input]

## Recommended Next Step
[What the Planner or user should do next]
```

---

### Planner

**Responsibilities:**

- Convert an approved architecture or PRD into a concrete step-by-step implementation plan.
- Break work into small, safe, reviewable tasks.
- Identify files to create or modify.
- Identify validation steps for each task.
- Identify rollback strategy when applicable.
- Persist significant plans under `docs/plans/`.
- Avoid implementation — planning only.

**Output format:**

```
## Objective
[What this plan achieves]

## Assumptions
[What must be true before starting]

## Ordered Tasks
1. [Task description]
2. [Task description]
...

## Files Affected
- [path/to/file] — created / modified / deleted

## Safety Checks
- [Condition that must be verified]

## Validation Commands
- [Safe, read-only commands to verify each task]

## Rollback Strategy
[How to undo if something goes wrong]

## Completion Criteria
[How to know the plan is fully done]
```

---

### Builder

**Responsibilities:**

- Implement **only** approved plan items — no improvisation.
- Make minimal, focused changes per task.
- Never invent architecture or deviate from the approved plan.
- Never modify files outside the repository.
- Never run destructive commands (`rm`, `mv` against `$HOME`, `stow --adopt`).
- Never run `stow` automatically.
- Prefer creating documentation and `.example` files before executable automation.

**Output format:**

```
## Changes Made
[Description of what was implemented]

## Files Created or Modified
- [path/to/file] — created / modified

## Commands Run
- [command executed]

## Skipped
[Items from the plan that were intentionally skipped and why]

## Next Steps
[What the Reviewer or user should do next]
```

---

### Reviewer

**Responsibilities:**

- Review changes for **safety** — no destructive operations introduced.
- Review changes for **privacy** — no secrets, tokens, keys, or sensitive data.
- Review **cross-platform correctness** — macOS and Arch not incorrectly mixed.
- Review **documentation clarity** — commands are copy-pasteable and safe.
- Check that examples use placeholder values, not real data.
- Verify no `stow --adopt`, `rm`, `mv`, or `ln -s` targeting `$HOME` was introduced.
- Persist significant review reports under `docs/reviews/`.

**Output format:**

```
## Summary
[What was reviewed]

## Blocking Issues
- [Issue that must be resolved before commit]

## Non-Blocking Suggestions
- [Optional improvement]

## Safety Verdict
PASS / FAIL — [reason]

## Privacy Verdict
PASS / FAIL — [reason]

## Documentation Verdict
PASS / FAIL — [reason]

## Recommended Next Action
[What the user or Builder should do]
```

---

## 5. Agent Handoff Flow

```
1. User request
      ↓
2. Architect — analyzes request, proposes structure, defines decisions
      ↓
3. Planner — converts approved architecture/PRD into ordered tasks
      ↓
4. Builder — implements approved plan items only
      ↓
5. Reviewer — validates for safety, privacy, documentation
      ↓
6. User confirmation
      ↓
7. Commit (only after Reviewer approves)
```

**Rules:**

- Builder must not start without an approved plan.
- Reviewer must be strict — blocking issues prevent commit.
- Architect must not ignore cross-platform concerns.
- Planner must include validation steps and rollback strategy.
- No agent may perform destructive operations or modify files outside the repository.

---

## 6. PRD-First Workflow

Any significant change starts with a **Product Requirements Document (PRD)**.

A PRD must define:

- **Goals** — what this achieves.
- **Non-goals** — what is explicitly out of scope.
- **Scope** — what files, systems, or packages are affected.
- **Safety requirements** — constraints to prevent data loss or exposure.
- **Acceptance criteria** — how to verify the work is complete and correct.

Workflow:

```
PRD → Architecture → Plan → Build → Review → Commit
```

Use the `create-prd` skill to produce PRDs. Store them under `docs/prd/`.

Use the `create-architecture` skill for architecture proposals and the `create-plan` skill for implementation plans.

---

## 7. Persistent Documentation Workflow

Project knowledge must be persisted in these directories:

```
docs/prd/          → PRDs and feature requirements
docs/architecture/ → architecture proposals and decisions
docs/plans/        → implementation plans (Planner output)
docs/reviews/      → Reviewer reports
docs/decisions/    → ADR-style decision records
docs/claude/       → agent guides and workflow documentation
```

**Rules:**

- Significant work must have a PRD under `docs/prd/`.
- Significant implementation must have a plan under `docs/plans/`.
- Reviews must be stored under `docs/reviews/`.
- Important technical decisions must be stored under `docs/decisions/`.
- Use **numbered filenames**:
  - `0001-dotfiles-foundation.md`
  - `0002-stow-package-layout.md`
  - `0003-macos-arch-separation.md`
- Do not rely only on conversation history for important project decisions.

---

## 8. Safety Rules

- Do not delete real user dotfiles.
- Do not overwrite real user dotfiles.
- Do not run `stow --adopt` automatically.
- Do not run `stow` without explicit user approval.
- Do not create symlinks without explicit user approval.
- Do not run `rm`, `mv`, or `ln -s` against `$HOME`.
- Do not modify files outside the repository.
- Prefer dry-run examples over live commands.
- Prefer `.example`, `.sample`, or `.template` files for initial config.
- Any risky command must be **shown to the user, not executed**.

---

## 9. Privacy Rules

- Repository is **private by default**.
- Never commit secrets.
- Never include passwords, tokens, API keys, SSH private keys, private hostnames, work secrets, or sensitive personal information.
- Use **placeholder values** in all examples (e.g., `your-token-here`, `YOUR_API_KEY`).
- Audit files before committing — check for real credentials.
- Prefer `.example` files over real config files during early adoption.

---

## 10. Cross-Platform Rules

- macOS and EndeavourOS / Arch must be **considered separately**.
- Do not use Homebrew commands in Arch configs.
- Do not use pacman or yay commands in macOS configs.
- Do not mix OS-specific config into shared/common config.
- Commands must **specify the target OS** when relevant.
- Future scripts must **detect OS** before suggesting package manager commands.
- Avoid hardcoded machine-specific paths.
- Common packages: configurations that work on both platforms without modification.
- macOS-specific: configurations only for macOS.
- Arch-specific: configurations only for EndeavourOS / Arch.

---

## 11. Future GNU Stow Rules

- Use a **package-based layout** — one directory per logical config group.
- Do not use a flat `stow .` approach (unsafe, uncontrolled).
- Preferred explicit command style:

  ```bash
  stow --dir=stow --target="$HOME" <package>
  ```

- Always provide a **dry-run example** before an install example:

  ```bash
  # Dry run first
  stow --dir=stow --target="$HOME" --simulate <package>

  # Install only after verifying dry-run output
  stow --dir=stow --target="$HOME" <package>
  ```

- Keep common, macOS, and Arch packages **separate directories**.
- Do not use `stow --adopt` automatically — it overwrites files without warning.
- Do not stow `.example` files unless intentionally renamed by the user.

---

## 12. Documentation Rules

- Every important decision must be documented.
- Keep documentation short and clear — prefer Markdown.
- Commands must be **copy-pasteable** and safe by default.
- Dangerous commands must be clearly marked:

  ```
  ⚠️  MANUAL STEP — review before running
  ```

- README is user-oriented: explains purpose and usage.
- Architecture docs are decision-oriented: explain what and why.
- PRDs define scope, goals, non-goals, and acceptance criteria.
- Plans define ordered, safe, actionable implementation steps.
- Reviews define findings, verdicts, and recommended next action.

---

## 13. Commit Rules

- **Review before commit** — Reviewer must approve.
- **Check for secrets** before staging any file.
- Prefer small, focused commits over large batched changes.
- Commit messages must explain **intent**, not just what changed.
- Do not commit generated sensitive files.
- Do not commit machine-specific local overrides.
- Format: `type(scope): short description`
  - `feat(stow): add zsh common package`
  - `docs(plans): add zsh bootstrap plan for macOS`
  - `fix(rules): correct cross-platform package manager guidance`

---

## 14. Suggested Commands

Safe read-only commands for inspecting repository state:

```bash
git status
git diff
git diff --staged
git log --oneline -20
```

Do not use commands that modify `$HOME` without explicit user approval.
