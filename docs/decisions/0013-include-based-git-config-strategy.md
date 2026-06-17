# Decision: Include-Based Git Config Strategy — .gitconfig.common as Managed Layer

**Number:** 0013
**Date:** 2026-06-17
**Status:** Accepted
**PRD:** 0003-git-package
**Architecture:** 0003-git-package-architecture

## Context

The dotfiles repository needs a managed Git configuration package. Two options were evaluated:

- **Option A:** Stow `.gitconfig` directly to `~/.gitconfig`, replacing the user's existing file.
- **Option B:** Stow `.gitconfig.common` as a separate file; the user adds a `[include]` directive to their existing `~/.gitconfig` to pull in the managed settings.

The user has an existing `~/.gitconfig` with Git identity, signing configuration, and machine-specific settings. Option A would overwrite these irreversibly without a backup. ADR-0006 and PRD-0003 both prohibit modifying the user's existing `~/.gitconfig`.

## Decision

Use **Option B: include-based strategy**.

The managed file is named `.gitconfig.common`. When stowed, it appears at `~/.gitconfig.common`. The user manually adds:

```
[include]
    path = ~/.gitconfig.common
```

to their real `~/.gitconfig`. Identity, signing, credential helpers, and machine-specific settings remain in the user's local `~/.gitconfig` — never tracked by this repository.

The `[include]` directive has been supported since Git 1.7.10 (2012) and is present on all current macOS and Arch installations.

## Consequences

- The user's existing `~/.gitconfig` is never overwritten, replaced, or read by the repository.
- Adopting the managed config requires one manual step — accepted trade-off.
- Disabling is reversible by removing the `[include]` line.
- New settings in `.gitconfig.common` are picked up automatically once the include is active.
- Clean separation: portable settings are managed; identity and private settings are local.
