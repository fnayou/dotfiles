# PRD: Claude Code Statusline Package

**Number:** 0017
**Status:** Approved
**Date:** 2026-06-24

> **Process note:** A working copy of the package was built ahead of this PRD during
> an exploratory session (branch `feat/claude-statusline-package`, uncommitted). Per
> `AGENTS.md` §6 the documents lead: this PRD, the architecture record, and the plan
> must be approved before that build is committed, and the build is subject to revision
> if the documents require it.

## Goals

- Track the portable Claude Code status line script as a Stow package under `stow/common/`
  named `claude`, so the status line is reproducible on any machine.
- Manage exactly one file: `~/.claude/statusline-command.sh`.
- Keep the script consistent with the repository color scheme — it mirrors the Oh My Posh
  Catppuccin Macchiato theme shipped by the `omp` package.
- Include a `.stow-local-ignore` and a package `README.md`, consistent with existing packages.
- Document a safe, manual dry-run → install workflow that resolves the known conflict with the
  existing real file.

## Non-Goals

- Installing, upgrading, or configuring Claude Code itself.
- Managing `~/.claude/settings.json` (the file that wires the status line) — kept local for now.
- Tracking any other `~/.claude` content.
- Running `stow` or creating symlinks in `$HOME`.
- Modifying the existing live `~/.claude/statusline-command.sh` on the host.
- Re-implementing the prompt theme — that lives in the `omp` package.

## User Stories

- As a user, I want my Claude Code status line script tracked in the dotfiles repository so I
  can reproduce the same status line on any machine (macOS or Arch).
- As a user, I want the status line to match my terminal prompt, so I keep one Catppuccin
  Macchiato look across the shell prompt and Claude Code.
- As a user, I want the package to exclude every sensitive part of `~/.claude`, so version
  control can never capture credentials or session data.
- As a user, I want the package under `stow/common/` because the script and its path are
  identical on macOS and Arch.

## Constraints

- **Platform:** The script is OS-portable — it detects macOS / Arch / EndeavourOS / generic
  Linux at runtime and uses `$HOME`. The path `~/.claude/statusline-command.sh` is identical on
  both platforms. Package goes in `stow/common/`.
- **Dependencies:** The script requires `jq` and `git` at runtime; the caveman badge segment is
  optional and a no-op when the plugin is absent. These are runtime expectations, not install
  steps owned by this package.
- **Stow layout rule:** Package must live under `stow/common/`, `stow/macos/`, or `stow/arch/`.
  Decision: `stow/common/`.
- **Folding hazard:** `~/.claude` is a real directory holding credentials and session data.
  Stow must link only the single file, never fold/symlink the whole directory. Install must use
  `--no-folding`.
- **Conflict:** A real `~/.claude/statusline-command.sh` already exists, so a plain stow reports
  a conflict (confirmed by dry-run). Resolution is manual; `--adopt` is forbidden.
- **Privacy:** The script contains only colors, layout logic, and `$HOME`-relative paths. No
  secrets, tokens, or machine-specific absolute paths.

## Safety Requirements

- Must not delete or overwrite the existing `~/.claude/statusline-command.sh` on the host.
- Must not run `stow` automatically during build.
- Must not create or overwrite symlinks in `$HOME` without explicit per-session user approval.
- Must not use `stow --adopt` at any point.
- Must document `--no-folding` so stow links only the file, never the `~/.claude` directory.
- Must provide a dry-run command for the user to verify before any activation.
- Must not run `rm`, `mv`, or `ln -s` targeting `$HOME`.

## Acceptance Criteria

- [ ] `stow/common/claude/.claude/statusline-command.sh` created as a real managed file (executable).
- [ ] `stow/common/claude/.stow-local-ignore` created.
- [ ] `stow/common/claude/README.md` created, documenting scope, exclusions, and the
      `--no-folding` dry-run → install workflow.
- [ ] `docs/guides/claude-setup.md` created (human-facing dry-run → `--no-folding` install,
      manual conflict resolution, the sensitive-content exclusion list, and the `settings.json`
      wiring snippet), consistent with the other package setup guides.
- [ ] The committed script contains no secrets, tokens, or machine-specific absolute paths.
- [ ] Stow dry-run command documented for the user (`--dir=stow/common --no-folding --simulate`).
- [ ] Both status blocks (`AGENTS.md` §2 and `CLAUDE.md`) updated in the same commit to record
      `claude` as added-but-not-yet-stowed.
- [ ] PRD and Architecture approved before the plan; plan approved before the build is committed.

## Out of Scope

- Automating Claude Code installation or configuration.
- Managing `~/.claude/settings.json` or any other `~/.claude` file.
- Stowing the package to `$HOME` in this milestone (manual, user-run, post-merge).
- Splitting the script into per-platform overlays (runtime detection handles this).
