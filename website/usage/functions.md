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
