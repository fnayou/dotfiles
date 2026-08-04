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
| `.config/zsh/ssh.zsh` | SSH host completion from `~/.ssh/config` — guarded, no-op without `ssh`/config |
| `.config/zsh/speedtest.zsh` | `speed` / `speed-json` / `speed-log` / `speed-history` helpers — guarded, no-op without `cloudflare-speed-cli` |
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

## SSH host completion

`ssh <Tab>` (also `scp`/`sftp`/`rsync`/`ssh-copy-id`) shows the `Host` aliases defined in
`~/.ssh/config` via fzf-tab. Only your configured hosts appear — the shipped `_ssh` mix of
`known_hosts` entries (often hashed and unusable) is swapped out for config aliases only.
Wildcard/negation patterns (`*`, `?`, `!`) are dropped. The preview shows the effective
config the alias resolves to (`ssh -G` — read-only, never connects).

`ssh.zsh` **tunes** the shipped `_ssh` rather than replacing it, so option and remote-path
completion stay intact. The `Host` list is re-read on every completion, so config edits show
up without a new shell. Guarded by `command -v ssh` and a readable `~/.ssh/config`, so it is
a no-op otherwise. The config itself is local/unstowed (private hostnames) — this layer reads
it at runtime and commits no host data.

## Speed test helpers

`speedtest.zsh` wraps [`cloudflare-speed-cli`](https://github.com/kavehtehrani/cloudflare-speed-cli):
`speed` runs the interactive TUI, `speed-json` prints JSON for `jq`, `speed-log` is the silent
cron/timer form, and `speed-history` exports every saved run to one CSV.

History belongs to the tool, not to this layer: with `--auto-save` (default true) each run is written
as a JSON file under `${XDG_DATA_HOME:-$HOME/.local/share}/cloudflare-speed-cli/runs/`, and
`speed-history` calls `--export-all-csv` over that set. `--export-csv` is **not** an append log — it
truncates its target and holds only the current run.

The tool ships **no config file** — every knob is a flag — so this layer holds the defaults
(`SPEEDTEST_DOWNLOAD_DURATION`, `SPEEDTEST_UPLOAD_DURATION`, `SPEEDTEST_CONCURRENCY`), set with
`: "${VAR:=…}"` so `local.zsh` or the environment overrides them. Extra flags pass through
(`speed -4`, `speed --traceroute`). Guarded by `command -v cloudflare-speed-cli`; nothing runs at
shell startup, and only `speed-log` writes anything.

See [Speed Test Setup Guide](../../../docs/guides/speedtest-setup.md).

## Where machine-specific setup goes

Two different files, split by role (ADR-0062):

| Need | File | Why |
|---|---|---|
| `PATH`, `FPATH`, `brew shellenv` — making a tool **findable** | `~/.zshrc`, above the managed block | Layers are guarded on `command -v <tool>` and `compinit` reads `fpath` once (step 5). Both run before `local.zsh`. |
| Aliases, tokens, editor — values that must **win** | `~/.config/zsh/local.zsh` | Sourced last, so it overrides every managed layer. |

Putting `PATH` in `local.zsh` produces a completion that works only after `exec zsh` — the second
shell inherits the exported `PATH` the first one set too late. See the setup guide's Troubleshooting.

## Setup

See [Zsh Package Setup Guide](../../../docs/guides/zsh-setup.md) for the full dry-run → install workflow, `.zshenv` wiring, and local override setup.
