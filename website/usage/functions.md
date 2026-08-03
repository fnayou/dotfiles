# Functions

The shell config defines only a few functions. They're small and live in `stow/common/zsh/`. This page
covers the ones useful in daily work — the rest are internal plumbing and are intentionally not
highlighted.

## `sizeof`

From `aliases.zsh`. Prints the size of each entry in the current directory:

```bash
sizeof
```

Implementation is `du -sh ./*` — a quick "what's taking space here?" for the current folder.

## `chpwd` (automatic listing on `cd`)

Also in `aliases.zsh`. `chpwd` is a Zsh hook that runs whenever the working directory changes; here it
runs `ll`, so every `cd` immediately lists the new directory. You don't call it directly — it fires on
navigation.

## `speed`, `speed-json`, `speed-log`

From `speedtest.zsh`. Wrappers around
[`cloudflare-speed-cli`](https://github.com/kavehtehrani/cloudflare-speed-cli), which ships **no
config file** — so this layer holds the defaults and the shortcuts:

```bash
speed                     # interactive TUI run
speed -4                  # extra flags pass straight through
speed-json | jq '.'       # headless, machine-readable
speed-log                 # silent run appended to a monthly CSV under XDG state
```

Defaults are `SPEEDTEST_DOWNLOAD_DURATION=10s`, `SPEEDTEST_UPLOAD_DURATION=10s`, and
`SPEEDTEST_CONCURRENCY=6`, all set with `: "${VAR:=…}"` so `~/.config/zsh/local.zsh` or a one-shot
environment variable overrides them:

```bash
SPEEDTEST_CONCURRENCY=12 speed
```

`speed-log` is the one worth scheduling; it writes to
`${XDG_STATE_HOME:-$HOME/.local/state}/cloudflare-speed-cli/history-YYYYMM.csv`. The whole layer is
guarded by `command -v cloudflare-speed-cli`, so the functions simply do not exist on a machine
without the tool.

!!! note "Measures the path to Cloudflare"
    Results describe your connection to the Cloudflare anycast edge and are not directly comparable to
    Ookla Speedtest figures. The tool also has no theme options, so it is the one integration that
    does not follow the Catppuccin Macchiato palette.

## Internal helpers (not for direct use)

These exist for the config's own wiring and aren't meant to be called by hand:

| Function | File | Role |
|---|---|---|
| `path_prepend` / `path_append` | `path.zsh` | Add directories to `PATH` safely during shell init |
| `_herdr` / `_herdr_sessions` | `herdr.zsh` | Zsh completion plumbing for Herdr session names |

!!! note "Deliberately minimal"
    The setup leans on aliases and tool integrations rather than a large library of custom functions.
    Anything more personal or machine-specific belongs in your own untracked `~/.config/zsh/local.zsh`
    (see [Shell](../features/shell.md)).
