# Decisions

This directory stores ADR-style (Architecture Decision Record) documents for this dotfiles repository.

## Purpose

Decision records capture **important technical choices** made during the evolution of the repository — with context, rationale, and consequences.

Every significant decision that is not obvious from the code or structure should have a record here.

## Structure of a decision record

Each decision record must include:

- **Context** — what situation led to this decision.
- **Decision** — what was decided.
- **Consequences** — what changes as a result; what tradeoffs were accepted.
- **Status** — current state of the decision.

## Naming convention

Use numbered filenames in sequence:

```
0001-use-agents-md-as-operating-contract.md
0002-use-stow-package-based-layout.md
0003-separate-macos-arch-stow-packages.md
```

## When to write a decision record

- A structural choice was made that future contributors (or future sessions) need to understand.
- A non-obvious tradeoff was accepted.
- A convention was established that must be followed consistently.
- An earlier decision was revisited and changed.

## Status values

- **Proposed** — decision is under discussion.
- **Accepted** — decision is in effect.
- **Deprecated** — decision is no longer in effect but not yet replaced.
- **Superseded by [number]** — replaced by a newer decision record.

## Template

```markdown
# Decision: [Title]

**Number:** 0001
**Date:** YYYY-MM-DD
**Status:** Accepted

## Context

[What situation, constraint, or question led to this decision]

## Decision

[What was decided — be explicit]

## Consequences

[What changes as a result; tradeoffs accepted]
```
