# Skill: create-architecture

Produces a numbered architecture document under `docs/architecture/`.

## When to use

- A PRD has been approved and needs to be translated into a structural design.
- The user requests an architecture proposal for a new package category or layout change.
- An existing architecture decision needs revisiting.

## Process

### Step 1 — Read the PRD

Locate and read the relevant PRD under `docs/prd/`. Do not proceed without it.

Confirm:

- What is the goal?
- What is in scope and out of scope?
- What platform(s) are targeted?
- What safety requirements must the architecture respect?

### Step 2 — Propose structure

Define:

- Directory layout (use ASCII tree when helpful).
- Package organization (common / macOS / Arch).
- File naming conventions.
- Stow package strategy when relevant.

### Step 3 — Identify tradeoffs

For each significant design choice, state the tradeoff:

```
Option A: [description]
  Pro: [benefit]
  Con: [cost or risk]

Option B: [description]
  Pro: [benefit]
  Con: [cost or risk]

Decision: [chosen option and reason]
```

### Step 4 — Define decisions

List explicit architecture decisions made. These become the basis for ADRs in `docs/decisions/`.

### Step 5 — Define risks

List what could go wrong:

- Platform-specific risks (behavior differs on macOS vs. Arch).
- Stow conflict risks.
- Privacy risks.
- Reversibility risks.

### Step 6 — Define future extensibility

Briefly note how the architecture supports future growth without requiring a redesign.

### Step 7 — Produce the document

Write the architecture document to a numbered file:

```
docs/architecture/0001-stow-layout.md
docs/architecture/0002-macos-arch-separation.md
```

Use the next available number in the sequence. Reference the related PRD by number.

## Architecture document template

```markdown
# Architecture: [Title]

**Number:** 0001
**Status:** Draft | Approved | Superseded
**Date:** YYYY-MM-DD
**PRD:** [link or number]

## Context

[What was requested and what state the repository is in]

## Proposed Structure

[Directory tree or layout description]

## Design Decisions

### Decision 1: [title]
[Tradeoff analysis and chosen option with reason]

### Decision 2: [title]
[Tradeoff analysis and chosen option with reason]

## Risks

- [risk]

## Extensibility

[How this design supports future growth]

## Open Questions

- [unresolved item]

## Recommended Next Step

[What the Planner should do with this]
```
