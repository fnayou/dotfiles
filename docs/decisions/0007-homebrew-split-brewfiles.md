# Decision: Homebrew Packages Split into Category Brewfiles

**Number:** 0007
**Date:** 2026-06-15
**Status:** Accepted

## Context

Homebrew is the primary package manager on macOS. Managing all packages in a single `Brewfile` becomes unwieldy as the number of tools grows, makes incremental installation harder, and obscures which tools are essential versus optional.

Options evaluated:
- **Single Brewfile** — simple, one file to manage, but difficult to install selectively.
- **Split Brewfiles by category** — multiple files, each covering a logical group of tools.

Homebrew management is out of scope for the initial implementation. This decision records the intended future structure.

## Decision

Use **split Brewfiles by category** under `packages/macos/`:

```
packages/macos/
├── Brewfile.core       # Essential tools required on every macOS machine
├── Brewfile.cli        # Developer CLI tools (ripgrep, fd, bat, fzf, jq, etc.)
├── Brewfile.dev        # Development environments (language toolchains, runtimes)
├── Brewfile.gui        # GUI applications installed as casks
└── Brewfile.optional   # Optional or personal tools not needed on every machine
```

Each Brewfile is installed independently:

```bash
# macOS
brew bundle --file=packages/macos/Brewfile.core
brew bundle --file=packages/macos/Brewfile.cli
```

No Brewfiles are created as part of the initial repository scaffold. This structure is the planned layout for when Homebrew management is added.

## Consequences

- Each category can be reviewed, installed, and updated independently.
- New machines can install only what they need (e.g., skip `Brewfile.optional`).
- Easier to audit: essential tools are clearly separated from optional ones.
- Brewfiles live under `packages/macos/` — not under `stow/` — because they are not symlinked into `$HOME`.
- Trade-off accepted: multiple files to maintain instead of one, but the added clarity is worth it at scale.
