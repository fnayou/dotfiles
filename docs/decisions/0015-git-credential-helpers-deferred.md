# Decision: Git Credential Helpers Deferred to Platform-Specific Packages

**Number:** 0015
**Date:** 2026-06-17
**Status:** Accepted
**PRD:** 0003-git-package
**Architecture:** 0003-git-package-architecture

## Context

Git credential helpers are platform-specific:

- macOS uses `osxkeychain` (Xcode Command Line Tools) or `store`.
- Arch / EndeavourOS uses `libsecret`, `gnome-keyring`, or `store`.

Including any credential helper in `stow/common/git/` would violate ADR-0001's third criterion: "No platform-specific tool or behavior is referenced."

## Decision

Git credential helpers are **not included in the common package**. No `[credential]` section appears in `stow/common/git/`.

When credential helper configuration is needed, it will be added in:
- `stow/macos/git/` — for macOS-specific credential helpers.
- `stow/arch/git/` — for Arch-specific credential helpers.

Each platform package will require its own PRD and architecture document.

## Consequences

- The common Git package satisfies all three ADR-0001 common-package criteria without exception.
- Users who need credential helpers must configure them manually in their local `~/.gitconfig` until platform packages exist.
- Future platform-layer Git packages are isolated; the common package is unaffected.
- Trade-off accepted: reduced out-of-the-box convenience in exchange for correct platform separation.
