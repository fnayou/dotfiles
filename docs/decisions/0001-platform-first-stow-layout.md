# Decision: Platform-First Stow Directory Layout

**Number:** 0001
**Date:** 2026-06-15
**Status:** Accepted

## Context

The dotfiles repository uses GNU Stow for symlink management. Packages must be organised under a `stow/` directory. Two layouts were evaluated:

- **Platform-first**: `stow/<platform>/<package>/` — e.g., `stow/common/git/`, `stow/macos/zsh/`
- **Package-first**: `stow/<package>/<platform>/` — e.g., `stow/zsh/macos/`, `stow/zsh/arch/`

The repository must support macOS (primary) and EndeavourOS / Arch Linux (secondary). Stow commands must be explicit and unambiguous per platform.

## Decision

Use a **platform-first layout**: `stow/<platform>/<package>/`

```
stow/
├── common/     # Config that works on both platforms without modification
│   └── git/
├── macos/      # macOS-specific config only
│   └── zsh/
└── arch/       # EndeavourOS / Arch-specific config only
    └── zsh/
```

Stow commands target a platform directory:

```bash
stow --dir=stow --target="$HOME" common/git
stow --dir=stow --target="$HOME" macos/zsh
```

A package belongs in `common/` only if:
1. The config file path is identical on macOS and Arch.
2. The config values work without modification on both platforms.
3. No platform-specific tool or behavior is referenced.

## Consequences

- Stow invocation is unambiguous — the platform is explicit in the command.
- Everything under `arch/` is Arch-only by definition; no cross-contamination risk.
- The same logical config (e.g., zsh) may appear in multiple directories (`common/zsh/` and `macos/zsh/`) — this is intentional and expected.
- New packages are placed in the correct platform directory without wrapper scripts.
- Trade-off accepted: related config for one tool may be split across platform directories.
