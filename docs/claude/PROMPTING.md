# Prompting Guide

Example prompts and anti-prompts for working with this repository.

## Agent prompts

Use agent-specific prompts to activate the right agent:

```
Use the architect agent to propose the repository architecture.
```

```
Use the planner agent to create a plan for the initial dotfiles structure.
```

```
Use the builder agent to implement the approved plan.
```

```
Use the reviewer agent to review the latest changes.
```

## Skill prompts

```
Use the create-prd skill for the first dotfiles PRD.
```

```
Use the create-architecture skill based on the approved PRD 0001.
```

```
Use the create-plan skill to plan the zsh package addition.
```

```
Use the review-change skill to review what was just implemented.
```

```
Use the add-dotfile-package skill to add a future nvim package.
```

## Workflow prompts

```
I want to add my zsh configuration. Start with the PRD.
```

```
Review the architecture proposal and tell me what's missing.
```

```
The plan is approved. Use the builder to implement tasks 1 through 3.
```

```
Review everything the builder just created before I commit.
```

## Documentation prompts

```
Write an ADR for the decision to separate macOS and Arch stow packages.
```

```
Update the architecture document to reflect the new package layout.
```

## Anti-prompts

Do **not** use these — they skip safety steps:

```
❌ Just setup everything.
❌ Copy all my current dotfiles into the repository.
❌ Run Stow on my home directory now.
❌ Commit everything you just created.
❌ Skip the dry-run and just stow it.
❌ Import my existing configs automatically.
```

These prompts bypass the PRD, architecture, planning, and review steps and may cause data loss or expose sensitive information.

## Context prompts

When starting a new session, orient Claude with:

```
Read AGENTS.md and CLAUDE.md. Current status: Claude Code operating layer only.
Dotfiles implementation has not started. I want to [describe goal].
```
