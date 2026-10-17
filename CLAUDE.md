# CLAUDE.md

Read `AGENTS.md` first.

`AGENTS.md` is the main operating contract for this repository.

Current repository status:

- Claude Code operating layer complete.
- GNU Stow packages live under `stow/common/` and `stow/macos/` (source of truth; `arch/`, `debian/` empty). Real config, plus some `.example` templates for local-only files.
- All `stow/common/` packages except `ghostty` are stowed to `$HOME` (live symlinks into the repo), including `codex`, whose `.stow-local-ignore` keeps `config.toml` unlinked; that template is propagated with `task codex:sync` instead. `ghostty` is added but not yet stowed, and so is the macOS-only `stow/macos/ghostty` (manual step: `docs/guides/ghostty-setup.md`). Home directory is modified by the existing symlinks. `stow/common/` and `stow/macos/` remain the source of truth for which packages exist.
- Home directory modifications are forbidden unless explicitly requested.

Keep this status block and the matching block in `AGENTS.md` in sync, in the same commit, whenever a package is added, removed, or first stowed.

Follow the agent workflow, safety rules, privacy rules, cross-platform rules, and persistent documentation workflow defined in `AGENTS.md`.
