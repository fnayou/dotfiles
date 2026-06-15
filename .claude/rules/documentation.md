# Documentation Rules

These rules apply to all agents and all sessions.

## Principle

Every important decision must be documented. Conversation history is not a substitute for written documentation.

## Format

- Prefer short, clear Markdown.
- Use headers to structure documents.
- Use numbered lists for ordered steps.
- Use bullet lists for unordered items.
- Use code blocks for all commands.

## Command documentation

- Commands must be **copy-pasteable** and correct.
- Commands must be safe by default when copy-pasted.
- Dangerous commands must be clearly marked:

  ```
  ⚠️  MANUAL STEP — review before running
  ```

- Never put a dangerous command in a code block without this marker on the line directly preceding the code block fence.

## Document purposes

| Directory            | Purpose                                                |
|----------------------|--------------------------------------------------------|
| `docs/prd/`          | Goals, non-goals, scope, safety requirements, criteria |
| `docs/architecture/` | Structure decisions, tradeoffs, risks                  |
| `docs/plans/`        | Ordered implementation tasks, validation steps         |
| `docs/reviews/`      | Findings, verdicts, recommended actions                |
| `docs/decisions/`    | ADR-style records of important technical choices       |
| `docs/claude/`       | Agent guides and workflow documentation                |

## Document orientation

- **README** — user-oriented: explains purpose, usage, how to get started.
- **Architecture docs** — decision-oriented: explains what was decided and why.
- **PRDs** — scope-oriented: defines goals, non-goals, and acceptance criteria.
- **Plans** — action-oriented: defines ordered, safe steps and validation.
- **Reviews** — findings-oriented: strict, explicit, with verdicts.
- **Decision records** — rationale-oriented: context, decision, consequences, status.

## Naming convention

Use numbered filenames for all persistent documents:

```
0001-dotfiles-foundation.md
0002-stow-package-layout.md
0003-macos-arch-separation.md
```

This ensures chronological ordering and avoids name conflicts as the project grows.
