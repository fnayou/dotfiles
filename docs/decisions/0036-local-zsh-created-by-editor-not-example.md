# Decision: `local.zsh` Created Directly by User with Editor, Not Copied from `.example`

**Number:** 0036
**Date:** 2026-06-19
**Status:** Accepted
**Related:** PRD-0010, Architecture-0010 §6, ADR-0023, ADR-0026

## Context

ADR-0023 established `local.zsh` as the git-ignored, last-sourced override slot. ADR-0026 established that `local.zsh` lives physically outside the repo working tree (at `~/.config/zsh/local.zsh`, a real directory under `--no-folding`). Neither ADR specified the creation workflow.

A `.example` template for `local.zsh` would imply a canonical structure for private content, which conflicts with the purpose of `local.zsh`: it is machine-specific, sensitive, and has no predictable shape across machines.

## Decision

`local.zsh` has no `.example` template and no documented default content. The user creates it directly at `~/.config/zsh/local.zsh` using their editor:

```
⚠️  MANUAL STEP — review before running
$EDITOR "$HOME/.config/zsh/local.zsh"
```

This workflow is preferred over copying from an `.example` for three reasons:

1. An `.example` would suggest a canonical structure, which is false — `local.zsh` content is machine-specific and arbitrary.
2. An `.example` could be accidentally committed if a user copies it into the repo directory and adds it with `git add .`. Physical location outside the repo is the primary safety boundary (ADR-0026); not providing a template removes one path to accidental commit.
3. The setup guide (`docs/guides/zsh-setup.md`) documents what `local.zsh` is for and gives example content categories (private PATH, tokens, machine-specific overrides) without providing a template that implies those are the only valid contents.

The absence of `local.zsh` is always safe. `index.zsh` guards the source:

```zsh
[[ -r "$HOME/.config/zsh/local.zsh" ]] && source "$HOME/.config/zsh/local.zsh"
```

## Consequences

- No `.example` file exists for `local.zsh` in the repo. This is intentional.
- `docs/guides/zsh-setup.md` documents the creation command and content categories.
- Users who need identical private config across machines must copy or sync `local.zsh` out-of-band — this repository does not manage that.
- The `.gitignore` entry for `local.zsh` (at `stow/common/zsh/.config/zsh/.gitignore`) provides a belt-and-suspenders second line of defence, but the primary boundary is physical location.
