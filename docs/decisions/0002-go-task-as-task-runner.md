# Decision: go-task as Task Runner

**Number:** 0002
**Date:** 2026-06-15
**Status:** Accepted

## Context

The repository needs a unified entry point for safe, discoverable operations — primarily stow dry-run and install commands. Three options were evaluated:

- **Makefile** — zero dependencies, but fragile quoting and no built-in task descriptions.
- **go-task (Taskfile.yml)** — YAML-based, readable, cross-platform, `task --list` discovery.
- **Shell scripts only** — no dependencies, but no unified entry point or discoverability.

The user already uses go-task in other projects. `just` was noted as an alternative but adds complexity without benefit at this stage.

## Decision

Use **go-task** (`Taskfile.yml`) as the task runner.

Installation:

```bash
# macOS
brew install go-task

# Arch / EndeavourOS
sudo pacman -S go-task
```

All stow operations are exposed through Taskfile tasks. No stow command is ever run directly by a script or hook.

`just` is noted as a possible future evaluation — not added now.

## Consequences

- All stow operations are discoverable via `task --list`.
- Tasks are readable and safe-by-default — the YAML format makes intent clear.
- go-task must be installed once per machine before tasks can be run — bootstrap script prints the install command.
- If go-task is not installed, `task` fails gracefully with a clear error rather than silently doing nothing.
- Trade-off accepted: one additional tool dependency per machine.
