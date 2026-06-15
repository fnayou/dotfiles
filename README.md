# dotfiles

Private personal dotfiles repository for macOS and EndeavourOS / Arch Linux.

## Status

```
Claude Code operating layer: complete
Dotfiles implementation:     not started
GNU Stow packages:           not created
Home directory:              unmodified
```

## What this is

A safe, maintainable, cross-platform dotfiles repository being built incrementally.

- **macOS** is the primary environment.
- **EndeavourOS / Arch Linux** is the secondary environment, planned from the start.
- **GNU Stow** will manage dotfile symlinks when implementation begins.
- **No dotfiles have been stowed yet. No home directory has been modified.**

## For Claude Code

Read `AGENTS.md` first. It is the main operating contract for this repository.

`AGENTS.md` defines:
- Agent roles (Architect, Planner, Builder, Reviewer).
- The PRD-first workflow.
- Safety rules, privacy rules, and cross-platform rules.
- Persistent documentation workflow.
- Commit rules.

Do not implement dotfiles, run Stow, create symlinks, or modify `$HOME` without explicit user approval and an approved plan.

## Safety rules

- No Stow has been run. No symlinks exist.
- Stow operations and symlinks will only happen with explicit per-session user approval and a reviewed, approved plan.
- No files in `$HOME` have been modified or replaced.
- No secrets, credentials, or private hostnames are committed.
- All sensitive configuration uses `.example` files with placeholder values.
- Every significant change requires: PRD → Architecture → Plan → Build → Review → Commit.

## Repository structure

```
.claude/          Claude Code agents, rules, and skills
docs/             Project documentation
  architecture/   Structure decisions and tradeoffs
  decisions/      ADR-style decision records
  plans/          Ordered implementation plans
  prd/            Product requirements documents
  reviews/        Review reports
  claude/         Agent guides and workflow documentation
AGENTS.md         Main operating contract — read this first
CLAUDE.md         Claude Code entry point
```

## Planned future direction

- PRD-first workflow for every significant change.
- Architecture documents before planning.
- Implementation plans before building.
- Reviews before committing.
- GNU Stow with a package-based layout:
  - `stow/common/` — config that works on both platforms unchanged.
  - `stow/macos/` — macOS-specific config.
  - `stow/arch/` — EndeavourOS / Arch-specific config.
- Common, macOS, and Arch packages always treated separately.
- Optional Docker test harness for safe Linux validation.

## Basic commands

```bash
git status
git diff
git log --oneline -10
```

Do not run commands that modify `$HOME` without an approved plan and explicit user confirmation.

## CI

GitHub Actions runs on every push and pull request. The workflow performs non-destructive repository hygiene checks only:

- Verifies expected files and directories exist.
- Verifies Markdown files are present.
- Runs `bash -n` syntax check on shell scripts (skips if none exist).
- Scans for obvious secret patterns and fails if found.

The CI workflow does not run Stow, create symlinks, modify `$HOME`, use secrets, deploy, or publish anything.

## License

See `LICENSE`.
