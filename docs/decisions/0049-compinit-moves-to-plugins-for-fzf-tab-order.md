# Decision: `compinit` Moves into `plugins.zsh` for Correct fzf-tab Load Order

**Number:** 0049
**Date:** 2026-06-22
**Status:** Accepted
**Supersedes:** 0046

## Context

ADR-0046 documented that `compinit` runs unconditionally in `completions.zsh` (step 6 in
`index.zsh`), after `plugins.zsh` (step 5). This was correct and safe for `zinit light`
usage — `zinit light` never calls `compinit` internally, so there was no double-init risk.

However, `plugins.zsh` loaded `Aloxaf/fzf-tab` in a sequence that violated the upstream
fzf-tab contract in two ways simultaneously:

1. **fzf-tab loaded before `compinit`** — fzf-tab wraps the zsh completion widget and must
   be initialized after `compinit` has set up that widget. Loading it before risks fzf-tab
   hooking into an incomplete or default completion system.

2. **fzf-tab loaded after `zsh-syntax-highlighting` and `zsh-autosuggestions`** — both of
   those plugins wrap zsh line-editor widgets. fzf-tab must wrap the same widgets first;
   loading after them means the widget chain is wrong.

The root cause: the only way to satisfy both rules simultaneously is to interleave `compinit`
*within* `plugins.zsh`, between the fpath-populating plugins and fzf-tab. Since `compinit`
was owned by `completions.zsh` (one step later in `index.zsh`), this interleaving was
impossible without moving `compinit`.

Additionally, `zsh-users/zsh-completions` (loaded via `zinit blockf`) must populate `fpath`
**before** `compinit` runs so its completion functions are autoloaded. That constraint also
lives entirely within `plugins.zsh`.

## Decision

Move `compinit` into `plugins.zsh`, interleaved in the correct position:

```zsh
zinit blockf for zsh-users/zsh-completions   # 1. fpath before compinit
autoload -Uz compinit && compinit             # 2. exactly once, after fpath
zinit light Aloxaf/fzf-tab                    # 3. after compinit
zinit light zsh-users/zsh-syntax-highlighting # 4. widget-wrap after fzf-tab
zinit light zsh-users/zsh-autosuggestions    # 5. widget-wrap after fzf-tab
```

The no-zinit `else` branch keeps a fallback `compinit` so native completion works on a
machine without zinit:

```zsh
autoload -Uz compinit && compinit   # fallback: native completion without zinit
```

`completions.zsh` is reduced to completion styles and fzf-tab preview `zstyle`s only — it
no longer calls `compinit`.

## Why this supersedes ADR-0046

ADR-0046 established that the zinit guard (`typeset -f zinit`) around `compinit` was
unnecessary because `zinit light` never calls `compinit` internally. That reasoning remains
valid and is unchanged. What changes here is the *location* of `compinit`: it moves from
`completions.zsh` to `plugins.zsh`. The one-compinit-per-path invariant ADR-0046 described
is preserved — each execution path (zinit present or absent) still calls `compinit` exactly
once.

## Consequences

- `plugins.zsh` now owns the full plugin + completion initialization sequence.
- `completions.zsh` is styles-only; it may safely set `:fzf-tab:*` `zstyle`s because those
  are read at completion time, not at compinit time.
- If the plugin configuration ever adds a `zinit load + cdreplay` pattern, revisit whether
  additional compinit calls are introduced (the same caveat as ADR-0046).
- The corrected order is the durable base for future per-tool completion files (e.g.,
  `taskfile.zsh`) that only need to source after `compinit`.
