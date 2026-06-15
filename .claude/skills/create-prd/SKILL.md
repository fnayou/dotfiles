# Skill: create-prd

Produces a numbered PRD document under `docs/prd/`.

## When to use

- User wants to start a significant new feature or package.
- User wants to formalize a request before architecture or planning begins.
- Any change that affects dotfiles, home directory structure, or repository layout.

## Process

### Step 1 — Clarify objective

Ask the user:

- What is the goal of this change?
- What problem does it solve?
- Is this macOS-specific, Arch-specific, or common?
- What is explicitly out of scope?

Do not proceed until the objective is clear.

### Step 2 — Define goals

List what success looks like. Be specific and verifiable.

### Step 3 — Define non-goals

List what this PRD explicitly does not cover. This prevents scope creep.

### Step 4 — Define user stories

Write 1–5 user stories in format:

```
As a [user], I want [action] so that [outcome].
```

### Step 5 — Define constraints

List known constraints:

- Platform constraints (macOS only? Arch only? Both?)
- Safety constraints (home directory? existing files?)
- Privacy constraints (any sensitive config involved?)
- Dependency constraints (tools required?)

### Step 6 — Define safety requirements

Explicitly state what must not happen:

- Must not delete existing files.
- Must not overwrite existing dotfiles.
- Must provide dry-run before install.
- (add more as applicable)

### Step 7 — Define acceptance criteria

List explicit, verifiable conditions that define "done":

```
- [ ] Criterion one
- [ ] Criterion two
```

### Step 8 — Define out-of-scope items

Repeat and expand the non-goals list with any additional exclusions that came up during steps 2–7.

### Step 9 — Produce the PRD

Write the PRD to a numbered file:

```
docs/prd/0001-dotfiles-foundation.md
docs/prd/0002-zsh-package.md
```

Use the next available number in the sequence.

## PRD template

```markdown
# PRD: [Title]

**Number:** 0001
**Status:** Draft | Approved | Superseded
**Date:** YYYY-MM-DD

## Goals

- [goal]

## Non-Goals

- [non-goal]

## User Stories

- As a user, I want [X] so that [Y].

## Constraints

- [constraint]

## Safety Requirements

- [safety requirement]

## Acceptance Criteria

- [ ] [criterion]

## Out of Scope

- [exclusion]
```
