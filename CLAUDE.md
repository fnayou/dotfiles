# CLAUDE.md

Read `AGENTS.md` first.

`AGENTS.md` is the main operating contract for this repository.

Current repository status:

- Claude Code operating layer complete.
- GNU Stow packages live under `stow/common/` (source of truth; `macos/` and `arch/` empty). Real config, plus some `.example` templates for local-only files.
- No package stowed yet. No symlinks created. Home directory unmodified.
- Home directory modifications are forbidden unless explicitly requested.

Keep this status block and the matching block in `AGENTS.md` in sync, in the same commit, whenever a package is added, removed, or first stowed.

Follow the agent workflow, safety rules, privacy rules, cross-platform rules, and persistent documentation workflow defined in `AGENTS.md`.
