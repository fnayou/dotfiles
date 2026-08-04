# Decision: PATH-Affecting Setup Belongs in `~/.zshrc` Above the Managed Block

**Number:** 0062
**Date:** 2026-08-04
**Status:** Accepted

## Context

The managed zsh layer is built on two mechanisms that both read the environment **at source time**:

1. **Presence guards.** Every optional layer opens with `command -v <tool> >/dev/null 2>&1 || return`
   (`herdr.zsh`, `taskfile.zsh`, `speedtest.zsh`, `fzf.zsh`, `tools.zsh`, and the `eza`/`bat` branches
   in `aliases.zsh` and `completions.zsh`). A guard that fails does not defer — the file returns and
   nothing it defines is ever registered.
2. **`compinit` reads `fpath` once.** `plugins.zsh` (step 5) runs `compinit` exactly once (ADR-0049).
   A completion directory added to `fpath` after that point is never scanned.

`local.zsh` is sourced **last**, at step 11, so that machine-specific values win over the managed
layers (ADR-0023, ADR-0026). That ordering is correct for overrides and wrong for discovery: by step
11, every guard has already run and `compinit` has already read `fpath`.

`local.zsh.example` nevertheless taught the machine-PATH case as a `local.zsh` job — wire Homebrew
there, then hand re-init the affected tools:

```zsh
# [former guidance, now removed]
[[ -x /home/linuxbrew/.linuxbrew/bin/brew ]] && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init --cmd cd zsh)"
command -v fzf    >/dev/null 2>&1 && eval "$(fzf --zsh)"
```

That advice only repairs the two tools it names. Everything else guarded stays silently unconfigured.

### Observed failure

An Arch machine installs `herdr`, `task`, `fzf`, `zoxide`, and `jq` via linuxbrew, and wired
`brew shellenv` in `local.zsh` exactly as the example instructed. Symptom: in a **new terminal
window**, `herdr <Tab>` and `task <Tab>` complete filenames instead of arguments. Running
`exec zsh` in that same window fixes both.

The mechanism:

- Fresh shell — PATH has no linuxbrew. Step 6b/6c guards fail, `compdef _herdr herdr` never runs, and
  brew's `share/zsh/site-functions` is not on `fpath` when `compinit` runs, so `_task` is never
  autoloaded. Zsh falls back to default file completion.
- Step 11 — `local.zsh` runs `brew shellenv`, which exports **both** `PATH` and `FPATH`. Too late for
  this shell.
- `exec zsh` — replaces the process image but **inherits the exported environment**. The second pass
  finds linuxbrew already on `PATH` and its site-functions already on `FPATH`, so every guard passes
  and `compinit` sees `_task`. Hence "works after `exec zsh`".

Measured, clean-environment interactive shell (`env -i … zsh -ic`):

| | `_comps[herdr]` | `_comps[task]` |
|---|---|---|
| brew wired in `local.zsh` | 0 | 0 |
| brew wired in `~/.zshrc`, above the managed block | 1 | 1 |

## Decision

**Environment setup that makes tools discoverable — `PATH`, `FPATH`, and anything sourced to produce
them, such as `brew shellenv` — belongs in `~/.zshrc` above the managed block.**

`local.zsh` keeps its documented purpose and no other: values that must **beat** the managed layers.
It is not a place to make a tool findable.

`~/.zshrc` is the right home because it is the only file that is both unmanaged by Stow (ADR-0027)
and guaranteed to run before `index.zsh`. It is already the user's own file, so machine-specific
content there breaks no privacy or portability rule.

Placement inside `~/.zshrc`:

```zsh
# machine-specific PATH / FPATH setup goes here, above the block

# >>> dotfiles managed zsh layer >>>
if [[ -r "$HOME/.config/zsh/index.zsh" ]]; then
  source "$HOME/.config/zsh/index.zsh"
fi
# <<< dotfiles managed zsh layer <<<
```

## Consequences

- Every guarded layer sees the same PATH, so a tool works on the first shell of a session — no
  `exec zsh`, no second window.
- `compinit` sees the full `fpath`, so package-shipped completions (`_task`) autoload normally.
- The hand re-init lines disappear. `tools.zsh` initialises zoxide once, in its correct
  after-Oh-My-Posh position (see `index.zsh` step 10); the former `local.zsh` re-init registered a
  second `__zoxide_hook`.
- `local.zsh` shrinks to genuine overrides, matching ADR-0023's stated intent.
- The split is now two-sided and must stay documented: **`~/.zshrc` for discovery, `local.zsh` for
  precedence.** `local.zsh.example` and `docs/guides/zsh-setup.md` carry that rule.
- `task zsh:bootstrap` appends the managed block to the end of `~/.zshrc`, which is still correct —
  content the user adds above it keeps working. The task is unchanged by this decision.

## Alternatives rejected

- **Keep the re-init pattern in `local.zsh`.** Whack-a-mole: it must name every affected tool, and it
  cannot fix `compinit`/`fpath` at all, because `compinit` has already run by step 11. It was also the
  guidance that produced the observed bug.
- **Add an early local slot** (e.g. `local.path.zsh` sourced at step 1b of `index.zsh`). Structurally
  clean and keeps machine config under `~/.config/zsh/`, but it introduces a second private file and a
  second ordering rule for one machine's needs, and `~/.zshrc` already solves it with no new concept.
  Revisit if a machine ever needs early setup that cannot live in `~/.zshrc`.
- **Put `brew shellenv` in `arch.zsh`.** Rejected: Homebrew on Arch is a per-machine choice, not an
  Arch property. Committing it would put a package-manager assumption in a platform layer, against
  the cross-platform rule and `arch.zsh`'s existing stance.
