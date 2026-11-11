# Decision: Author a Read-Only zsh Completion for the pi CLI

**Number:** 0088
**Date:** 2026-11-11
**Status:** Accepted
**PRD:** 0036 — zsh Completion for the pi Coding Agent CLI
**Architecture:** 0032 — zsh Completion for the pi Coding Agent CLI

## Context

The pi coding agent CLI (1.5.2) ships no zsh completion: `pi completion zsh` prints no script and no
`_pi` is on `fpath`. The `zsh` stow package already authors completions for tools in that position
(`herdr.zsh`, `lms.zsh`, ADR-0049: `compinit` runs once in `plugins.zsh`; tool files call `compdef`).
pi also keeps credentials and session content under `~/.pi/agent/`, and `pi mcp list` starts servers,
so a completion must be careful about what it runs.

## Decision

- Add `stow/common/zsh/.config/zsh/pi.zsh`: a hand-written `_pi` built on `_arguments`, registered with
  `compdef`, guarded so it does nothing without `pi`. `index.zsh` sources it in slot 6h.
- Complete subcommands and flags from `pi --help` and `pi <command> --help`. The tree is static and the
  header records the pi version it was validated against.
- Live candidates come only from read-only sources: `pi --list-models` (models as `provider/id`, and
  providers), `pi list` (package sources), and `jq` reading the key names of `~/.pi/agent/mcp.json`.
- Never run at completion time: `pi mcp list`, `pi auth ...`, `install`, `update`, `remove`. Never read
  `auth.json`, sessions or MCP server values.
- `scripts/test-pi-completion.sh` checks the file loads with a stub `pi`, is a no-op without it, uses no
  mutating or secret-reading call, and never prints an `mcp.json` value.
- fzf-tab preview runs only at the subcommand position, against a fixed list of subcommand names.

## Consequences

- New pi commands are not completed until `pi.zsh` is updated. Flags added by extensions fall back to
  file completion.
- `pi.zsh` is a new file in the stowed package, so each machine re-stows (dry run first).
- Without `jq` the MCP server list is empty.
- Tested on macOS with pi 1.5.2. Arch and Debian are untested.
- If pi later ships its own completion, delete `pi.zsh` and its `index.zsh` slot.
