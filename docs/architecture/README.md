# Architecture

This directory stores architecture proposals and architecture notes for this dotfiles repository.

## Purpose

Architecture documents define the **structure and design decisions** that guide implementation.

An architecture document should include:

- **Structure** — directory layout, package organization, naming conventions.
- **Tradeoffs** — analysis of design options with chosen decision and reason.
- **Risks** — what could go wrong, platform differences, reversibility concerns.
- **Decisions** — explicit choices made, with rationale.
- **Extensibility** — how the design supports future growth.

## Naming convention

Use numbered filenames in sequence:

```
0001-stow-layout.md
0002-macos-arch-separation.md
0003-package-naming-conventions.md
```

## Workflow

1. Read the related PRD first.
2. Use the Architect agent or `create-architecture` skill to produce an architecture document.
3. Reference the PRD number in the architecture document.
4. Review and approve the architecture before planning begins.
5. Reference the architecture number in implementation plans.

## Relationship to PRDs

Every significant architecture document must reference the PRD that motivated it.

Example frontmatter:

```
PRD: 0001-dotfiles-foundation.md
```

## Status values

- **Draft** — in progress, not yet approved.
- **Approved** — approved by the user, ready for planning.
- **Superseded** — replaced by a newer architecture document.
