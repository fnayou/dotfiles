# zsh

Managed [Zsh](https://www.zsh.org/) configuration. Stows into `~/.config/zsh/`.

Layered design: `index.zsh` is the entry point and sources each layer in order. After Stow,
`~/.config/zsh/` is a **real directory** of per-file symlinks — not a single directory symlink.

## What it configures

- Layered init: path, history, completions, plugins, tools, prompt, aliases, keybindings.
- Per-OS layers (`macos.zsh`, `arch.zsh`) loaded conditionally.
- Local, unstowed override hook (`local.zsh`, from `local.zsh.example`) for machine-specific values.

## Files (selected)

| File | Purpose |
|---|---|
| `.config/zsh/index.zsh` | Entry point — sources all layers in order |
| `.config/zsh/path.zsh`, `history.zsh`, `completions.zsh` | Core shell setup |
| `.config/zsh/plugins.zsh`, `tools.zsh`, `prompt.zsh` | Plugins, CLI tools, Oh My Posh prompt |
| `.config/zsh/aliases.zsh`, `keybindings.zsh` | Aliases and key bindings |
| `.config/zsh/taskfile.zsh` | go-task completion tuning — guarded, no-op without `task` |
| `.config/zsh/herdr.zsh` | Herdr session completion — guarded, no-op without `herdr` |
| `.config/zsh/macos.zsh`, `arch.zsh` | Per-platform layers |
| `.config/zsh/local.zsh.example` | Template for local-only overrides |

## Plugin load order

`plugins.zsh` satisfies the fzf-tab upstream contract (ADR-0049):

1. `zsh-users/zsh-completions` — populates `fpath` before `compinit`
2. `compinit` — runs exactly once, after `fpath` is ready
3. `Aloxaf/fzf-tab` — after `compinit`, before widget-wrapping plugins
4. `zsh-syntax-highlighting`, `zsh-autosuggestions` — widget-wrap, after `fzf-tab`

## go-task (Taskfile) completion

`task <Tab>` shows available Taskfile tasks via fzf-tab, with descriptions. Selecting a task
inserts it into the command line; pressing `Enter` runs it. Preview shows the task summary
(read-only — never executes a task).

Requires `task` installed via Homebrew (`brew install go-task`) or pacman (`pacman -S go-task`).
Both ship a native `_task` completion file into the default zsh `fpath`. Non-package installs
(`go install`, raw `install.sh`) do not include `_task` — native completion will be unavailable
without manually placing the file.

## Herdr session completion

`herdr session attach <Tab>` (also `stop`/`delete`, and the global `herdr --session <Tab>`)
shows the host's real Herdr sessions via fzf-tab. Selecting a session inserts it into the
command line; pressing `Enter` runs it. The preview shows the highlighted session's
metadata (status, directory, socket) — read-only, never starts/stops/attaches a session.

Unlike go-task, Herdr ships **no** native zsh completion, so `herdr.zsh` **authors** the
`_herdr` function itself. `jq` is recommended for parsing `herdr session list --json`; when
absent, a plain-text fallback still completes session names. Guarded by `command -v herdr`,
so it is a no-op when Herdr is not installed.

## Setup

See [Zsh Package Setup Guide](../../../docs/guides/zsh-setup.md) for the full dry-run → install workflow, `.zshenv` wiring, and local override setup.
