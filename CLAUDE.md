# CLAUDE.md

Read `AGENTS.md` first.

`AGENTS.md` is the main operating contract for this repository.

Current repository status:

- Claude Code operating layer complete.
- GNU Stow packages live under `stow/common/` (source of truth; `macos/` and `arch/` empty). Real config, plus some `.example` templates for local-only files.
- All `stow/common/` packages are stowed to `$HOME` (live symlinks into the repo). Home directory is modified by these symlinks. `stow/common/` remains the source of truth for which packages exist.
- Home directory modifications are forbidden unless explicitly requested.

Keep this status block and the matching block in `AGENTS.md` in sync, in the same commit, whenever a package is added, removed, or first stowed.

Follow the agent workflow, safety rules, privacy rules, cross-platform rules, and persistent documentation workflow defined in `AGENTS.md`.
