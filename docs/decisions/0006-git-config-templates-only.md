# Decision: Git Configuration Starts as Templates Only

**Number:** 0006
**Date:** 2026-06-15
**Status:** Accepted

## Context

The user has an existing Git configuration including SSH signing and GitHub CLI integration. Replacing or symlinking `~/.gitconfig` automatically would break the existing setup.

Git config contains identity-specific values (name, email, signing key) that must never be hardcoded in a shared repository. It may also contain work-specific settings that must remain private.

## Decision

Git configuration starts as **template files only** — no symlinks, no automatic replacement.

Initial scope:
- `stow/common/git/.gitconfig.example` — placeholder values for name, email, signing key
- `stow/common/git/.gitignore_global.example` — safe global gitignore patterns (no sensitive values)

Rules:
- The existing `~/.gitconfig` is not inspected, copied, or replaced.
- The existing `~/.gitignore_global` is not inspected, copied, or replaced.
- Git signing strategy is **not changed** — existing SSH signing setup is preserved as-is.
- Machine-specific identity (name, email, signing key, work settings) must never be hardcoded in committed files.

Future direction (not scoped now):
- Git `[include]` or `[includeIf]` directives for machine-specific identity overrides.
- Local include files (e.g., `~/.gitconfig.local`) remain outside the repository.
- Signing strategy review deferred until the user decides to consolidate Git config.

## Consequences

- Existing Git setup is fully protected — no risk of breaking SSH signing or GitHub CLI.
- The repository provides a documented starting point for Git config without imposing one.
- New machines require manual identity setup — the `.example` file documents what is needed.
- Trade-off accepted: Git config is not immediately functional after stowing — user must populate identity values.
