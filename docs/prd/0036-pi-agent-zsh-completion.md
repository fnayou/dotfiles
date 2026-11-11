# PRD: zsh Completion for the pi Coding Agent CLI

**Number:** 0036
**Status:** Approved
**Date:** 2026-11-11

## Goals

- Tab completion for the `pi` CLI in zsh, written the same way as `lms.zsh` (ADR-0049 pattern): a
  guarded file in the `zsh` stow package that authors the completion and registers it with `compdef`.
- Complete the subcommands (`install`, `remove`, `uninstall`, `update`, `list`, `config`, `auth`, `mcp`)
  and their own subcommands and flags, as listed by `pi <command> --help`.
- Complete the top-level options (for example `--model`, `--provider`, `--thinking`, `--mode`,
  `--tools`, `--tui-mode`) with fixed value lists where pi documents them.
- Complete live values from read-only sources:
  - `--model` and `--provider`: from `pi --list-models` (a local table, about 0.2 s).
  - `pi mcp remove|login|logout <server>`: server names from `~/.pi/agent/mcp.json` keys.
  - `pi remove|uninstall <source>`: installed package sources from `pi list`.
- No-op when `pi` is not installed.

## Non-Goals

- Running anything that changes state, signs in, installs, updates, or contacts the network at
  completion time.
- Completing `--session`, `--resume` or `--fork` ids (they would read session content).
- A shell alias or wrapper function for `pi`.
- Reading or printing `~/.pi/agent/auth.json` or any server's command, URL or environment values.
- Completions for other shells.

## User Stories

- As a pi user, I want Tab after `pi ` to list subcommands and options so that I do not need `--help`.
- As a pi user, I want `pi --model <Tab>` to list the models my pi knows so that I can pick one fast.
- As a pi user, I want `pi mcp remove <Tab>` to list my configured MCP servers so that I do not
  mistype a name.

## Constraints

- Common package (`stow/common/zsh`); `pi` runs the same on macOS, Arch and Debian. Candidates must not
  depend on a platform tool beyond `jq` (optional; without it the live MCP list is empty).
- pi ships no zsh completion (`pi completion zsh` prints no script), so the file authors it.
- Subcommand trees are validated against pi 1.5.2 and recorded in the file header, as `lms.zsh` does.
- Sourced after `compinit` through `index.zsh`, as a new slot after the `lms` one.
- The file `zsh/.config/zsh/pi.zsh` is new in an already stowed package: the user re-stows (dry run first).

## Safety Requirements

- Completion code only reads: `pi --list-models`, `pi list`, `pi <command> --help`, and a `jq` read of
  key names from `mcp.json`. Never `pi mcp list` (it starts servers), `pi auth`, `install`, `update`.
- Must not print, log or store credentials, tokens, session text or MCP server values.
- Must not delete, overwrite or move any file; must not run stow automatically.
- Must provide a dry run before the re-stow step in the docs.

## Acceptance Criteria

- [ ] `pi.zsh` returns without error and defines nothing when `pi` is missing.
- [ ] `zsh -n` passes and a new interactive shell starts without warnings.
- [ ] Tab on `pi ` offers all eight subcommands; each subcommand offers its own subcommands and flags.
- [ ] `pi --model <Tab>` and `--provider <Tab>` list values from `pi --list-models`.
- [ ] `pi mcp remove <Tab>` lists the configured server names and nothing else from `mcp.json`.
- [ ] A test script checks the completion function registers and that no mutating pi command appears
  in the file.
- [ ] Guide (`docs/guides/zsh-setup.md` and the site copy), `website/features/shell.md`, ADR and index
  are updated; `task check:decisions` and `task brand:check` pass.

## Out of Scope

- Session id completion, extension-registered flags (for example `--plan`), and `@file` prompts beyond
  zsh's default file completion.
- Completing a `pi` installed under a different name.
- Arch and Debian testing beyond a documented "untested" note.
