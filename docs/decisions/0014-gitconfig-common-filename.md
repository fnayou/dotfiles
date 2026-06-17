# Decision: .gitconfig.common Filename Chosen Over .gitconfig to Avoid Home Directory Conflict

**Number:** 0014
**Date:** 2026-06-17
**Status:** Accepted
**PRD:** 0003-git-package
**Architecture:** 0003-git-package-architecture

## Context

Two filenames were evaluated for the managed Git config file:

- **Option A:** `.gitconfig` — stows to `~/.gitconfig`.
- **Option B:** `.gitconfig.common` — stows to `~/.gitconfig.common`.

The user has an existing `~/.gitconfig`. With Option A, Stow refuses to create the symlink because `~/.gitconfig` already exists. The only workarounds are `stow --adopt` (forbidden by safety rules) or manually deleting `~/.gitconfig` first (irreversible data loss risk).

## Decision

Name the managed file **`.gitconfig.common`** — stows to `~/.gitconfig.common`.

Combined with ADR-0013 (include-based strategy), the user's existing `~/.gitconfig` is left entirely untouched. The managed config is layered in via `[include]`.

## Consequences

- Zero conflict risk with any existing `~/.gitconfig` at stow time.
- The stowed path is non-standard but valid — Git follows include paths regardless of filename.
- The `.example` file in the repository is named `.gitconfig.example` — the user renames to `.gitconfig.common` locally.
- Repository `.gitignore` must include `stow/common/git/.gitconfig.common` to prevent accidental commit.
