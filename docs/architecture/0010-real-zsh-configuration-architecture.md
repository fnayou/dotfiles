# Architecture: Real Zsh Configuration Adoption

**Number:** 0010
**Status:** Draft
**Date:** 2026-06-19
**PRD:** [0010-real-zsh-configuration.md](../prd/0010-real-zsh-configuration.md)
**Related:** Architecture 0004, 0005, 0006, 0007, 0008, 0009; ADR-0016, ADR-0020, ADR-0021, ADR-0023, ADR-0024, ADR-0025, ADR-0026, ADR-0027, ADR-0028, ADR-0029

---

## Context

The managed zsh layer is structurally complete. ADR-0021 established the single guarded include block in `~/.zshrc`. ADR-0024 established `--no-folding` as the Stow strategy. ADR-0025 established that git-ignored real files are linked by presence. ADR-0026 established `local.zsh` as a real, unversioned file outside the repo. ADR-0027 confirmed `~/.zshrc` stays unmanaged. ADR-0029 confirmed `shared.zsh` and `index.zsh` are tracked with real safe content.

The current state entering this architecture:

- `stow/common/zsh/.config/zsh/index.zsh` — tracked, valid source-order logic, content is final.
- `stow/common/zsh/.config/zsh/shared.zsh` — tracked, contains `EDITOR="nvim"` and `PAGER="less"` (placeholders replaced per ADR-0029). Structural patterns are present; content is safe to commit.
- `stow/common/zsh/.config/zsh/shared.zsh.example` — tracked template for new machines.
- `stow/common/zsh/.config/zsh/index.zsh.example` — tracked template for new machines.
- `stow/common/zsh/.config/zsh/macos.zsh.example` — tracked; only a minimal placeholder file with `YOUR_HOMEBREW_PREFIX` and `YOUR_MACOS_TOOL_PATH`.
- `stow/common/zsh/.config/zsh/arch.zsh.example` — tracked; only a minimal placeholder file with `YOUR_ARCH_TOOL_PATH`.
- `stow/common/zsh/.config/zsh/omp.zsh.example` — tracked; contains the activation block commented out.
- `stow/common/zsh/.config/zsh/zshrc.example` — tracked; reference template for `~/.zshrc`.
- `stow/common/zsh/.config/zsh/.gitignore` — tracked; ignores `shared.zsh`, `index.zsh`, `macos.zsh`, `arch.zsh`, `omp.zsh`, `local.zsh`.

PRD-0010 covers filling in real, safe, portable configuration content into the `.example` templates. This is the design document for that content: what goes where, why it is ordered the way it is, and what decisions govern each layer's scope.

### Established decisions entering this architecture

- **ADR-0016** — All zsh-sourced files live in `stow/common/zsh/`; runtime OS detection governs what loads.
- **ADR-0020** — Zinit installed via documented one-time manual clone; never auto-cloned at startup.
- **ADR-0021** — Single guarded include block + `index.zsh` entry point; `~/.zshrc` never stowed.
- **ADR-0022** — Zsh migration: Model 4 start, Model 3 target.
- **ADR-0023** — `local.zsh` is the git-ignored, last-sourced override slot.
- **ADR-0024** — `--no-folding` is the intended Stow strategy for the zsh package.
- **ADR-0025** — Real managed files linked by physical presence, not git-tracking; `.example` templates are the only versioned source of truth.
- **ADR-0026** — `local.zsh` is a real, unversioned file physically outside the repo.
- **ADR-0027** — `~/.zshrc` stays unmanaged; the `--no-folding` migration does not touch it.
- **ADR-0028** — Manually-activated packages require a human setup guide under `docs/guides/`.
- **ADR-0029** — `shared.zsh` and `index.zsh` tracked with real safe content.

---

## §1 — Managed zsh file layout

All files live under `stow/common/zsh/.config/zsh/`.

```
stow/common/zsh/
└── .config/
    └── zsh/
        ├── .gitignore              # ignores real files; keeps .example tracked (ADR-0025)
        ├── index.zsh               # tracked — entry point; source order only; no logic
        ├── index.zsh.example       # tracked — new-machine template for index.zsh
        ├── shared.zsh              # tracked — portable env, history, options, Zinit guard, tool guards
        ├── shared.zsh.example      # tracked — new-machine template for shared.zsh
        ├── macos.zsh.example       # tracked — macOS platform layer template
        ├── arch.zsh.example        # tracked — Arch platform layer template
        ├── omp.zsh.example         # tracked — Oh My Posh activation template
        └── zshrc.example           # tracked — reference template for ~/.zshrc (never stowed to ~/.zshrc)
```

Real (local, git-ignored) files created by the user at setup time — not committed:

```
stow/common/zsh/.config/zsh/   (on disk, not in repo)
├── macos.zsh                   # git-ignored — real macOS config, symlinked by Stow
├── arch.zsh                    # git-ignored — real Arch config, symlinked by Stow
└── omp.zsh                     # git-ignored — real OMP activation, symlinked by Stow
```

And one file that lives outside the repo entirely:

```
~/.config/zsh/
└── local.zsh                   # real file, outside repo, never symlinked, never committed (ADR-0026)
```

### File roles

| File | Committed | Role |
|---|---|---|
| `index.zsh` | Yes (ADR-0029) | Entry point. Source order only. Four guarded source lines. No logic, no env, no aliases. |
| `index.zsh.example` | Yes | New-machine template. Content identical to `index.zsh`. |
| `shared.zsh` | Yes (ADR-0029) | Portable layer. XDG, env, history, options, Zinit guard, compinit fallback, fzf/zoxide/eza guards, grep alias. |
| `shared.zsh.example` | Yes | New-machine template. Same structure; `YOUR_EDITOR`/`YOUR_PAGER` placeholders instead of real values. |
| `macos.zsh.example` | Yes | macOS platform layer template. Homebrew guard, macOS PATH additions, macOS-only aliases. |
| `macos.zsh` | No (git-ignored) | Real macOS config copied from `.example`; user fills in values. |
| `arch.zsh.example` | Yes | Arch platform layer template. Arch PATH additions, pacman/yay/paru guards, systemctl aliases. |
| `arch.zsh` | No (git-ignored) | Real Arch config copied from `.example`; user fills in values. |
| `omp.zsh.example` | Yes | Oh My Posh activation template. Double-guarded eval; shipped commented out. |
| `omp.zsh` | No (git-ignored) | Real OMP activation; user copies and uncomments. |
| `zshrc.example` | Yes | Reference `~/.zshrc` template. Never stowed to `~/.zshrc` (ADR-0021). Stows only to `~/.config/zsh/zshrc.example`. |
| `local.zsh` | No — physically outside repo (ADR-0026) | Machine-specific overrides; private values; sourced last. No `.example` exists (ADR-0023). |
| `.gitignore` | Yes | Guards `shared.zsh`, `index.zsh`, `macos.zsh`, `arch.zsh`, `omp.zsh`, `local.zsh` (ADR-0025). |

The `.gitignore` guards `shared.zsh` and `index.zsh` even though both are currently tracked. The guard prevents a future `git rm --cached` from making them accidentally re-stageable in a modified state. Stow does not require git-tracking to create a symlink — it links any file physically present (ADR-0025).

---

## §2 — Source order and startup sequence

### Full startup chain

```
~/.zshrc (user-owned, never stowed)
  │
  └── [[ -r "$HOME/.config/zsh/index.zsh" ]] && source "$HOME/.config/zsh/index.zsh"
        │                              (guarded — ADR-0021)
        │
        ├── 1. [[ -r "…/shared.zsh" ]] && source "…/shared.zsh"
        │       XDG exports, env, history, shell options, Zinit guard, compinit,
        │       fzf/zoxide/eza guards, grep alias
        │
        ├── 2. OS detection:
        │       if [[ "$OSTYPE" == "darwin"* ]]
        │         [[ -r "…/macos.zsh" ]] && source "…/macos.zsh"
        │       elif [[ -f /etc/arch-release ]]
        │         [[ -r "…/arch.zsh" ]] && source "…/arch.zsh"
        │
        ├── 3. [[ -r "…/omp.zsh" ]] && source "…/omp.zsh"
        │       (opt-in; double-guarded inside the file itself)
        │
        └── 4. [[ -r "…/local.zsh" ]] && source "…/local.zsh"
                (last — wins over all layers; ADR-0023)
```

### Why this order matters

**Step 1 — `shared.zsh` first:** XDG variables must be set before any tool that uses them (Zinit path, fzf, zoxide). `$EDITOR`, `$PAGER`, and history must be set before the platform layer runs, so the platform layer can safely override them if needed without re-declaring defaults.

**Step 2 — Platform layer second:** Homebrew `shellenv` on macOS exports `PATH`, `MANPATH`, `INFOPATH`. These must be set before the prompt layer reads them. Platform aliases may override portable defaults from `shared.zsh` (override direction: last write wins in zsh). OS detection uses `$OSTYPE` (set by zsh at startup, always reliable) with `/etc/arch-release` as the Arch guard.

**Step 3 — `omp.zsh` third:** The prompt must come after `PATH` is fully composed (Homebrew, Arch-specific bins, `~/.local/bin`). Oh My Posh reads `$PATH` to locate its binary and reads `$XDG_CONFIG_HOME` to locate `omp.toml`. Both must be set before the prompt initializes.

**Step 4 — `local.zsh` last:** Private overrides win over everything. A user may override `$EDITOR`, add private `PATH` entries, set tokens, or override aliases from any earlier layer. Sourcing last guarantees this without any special ordering logic inside the layers themselves.

### `~/.zshrc` is never modified (ADR-0027)

The managed layer's activation trigger is the single guarded include block already present in the user's `~/.zshrc`:

```zsh
# >>> dotfiles managed (zsh) — added manually; delete this block to disable >>>
[[ -r "$HOME/.config/zsh/index.zsh" ]] && source "$HOME/.config/zsh/index.zsh"
# <<< dotfiles managed (zsh) <<<
```

No step in this PRD's implementation touches `~/.zshrc`. The zsh package path is `stow/common/zsh/.config/zsh/` — Stow targets `~/.config/zsh/`, which is outside `~/.zshrc`'s reach. The `~/.zshrc` block becomes active the moment `index.zsh` exists as a real symlinked file; no edit to `~/.zshrc` is required.

---

## §3 — `shared.zsh` content design

`shared.zsh` is the portable layer. Everything in it must work on macOS and Arch without modification. The sections below define both what belongs and what is forbidden.

### XDG base directory exports

```zsh
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
```

These use the `${VAR:-default}` pattern so a machine that already sets them (e.g. via `/etc/environment` on Arch) keeps its values; this file does not overwrite an existing configuration. They come first because Zinit's `ZINIT_HOME`, fzf's data path, and other tool paths all depend on `$XDG_DATA_HOME`.

`XDG_STATE_HOME` is not exported — `$HISTFILE` is placed at `$HOME/.zsh_history` instead (see §10 for rationale).

### EDITOR and PAGER exports

```zsh
export EDITOR="nvim"
export PAGER="less"
```

These are portable tool names, not paths. They satisfy the "safe to commit" definition from ADR-0029: both work on macOS and Arch, neither reveals private information, neither is machine-specific. A user who prefers a different editor overrides in `local.zsh`.

### History

Covered in detail in §10.

### Shell options

```zsh
setopt AUTO_CD
```

`AUTO_CD` lets the user type a directory name and enter it without typing `cd`. It is portable across zsh versions on both macOS (system zsh + Homebrew zsh) and Arch. Additional options (`HIST_IGNORE_DUPS`, `SHARE_HISTORY`) are set alongside the history variables.

### Zinit source guard (ADR-0020)

```zsh
ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
[[ -f "${ZINIT_HOME}/zinit.zsh" ]] && source "${ZINIT_HOME}/zinit.zsh"
```

The upstream Zinit auto-clone pattern is explicitly rejected (ADR-0020). The guard uses a file-existence check (`[[ -f … ]]`) rather than `command -v` because Zinit is not a `$PATH` binary — it is a shell script in a directory. The `:-` fallback on `$XDG_DATA_HOME` guarantees the path resolves even if `shared.zsh` is sourced before the XDG exports reach their line (though in practice they precede Zinit in the same file).

### Completion strategy (Zinit-aware)

```zsh
if ! typeset -f zinit >/dev/null 2>&1; then
  autoload -Uz compinit && compinit
fi
```

When Zinit is loaded, it manages `compinit` internally. Running a second `compinit` wastes startup time and can trigger security warnings about insecure completion directories. The guard `typeset -f zinit` tests whether the `zinit` function was defined by the source above. If Zinit is absent, the standalone `compinit` runs.

### Tool guards

```zsh
command -v fzf    >/dev/null 2>&1 && eval "$(fzf --zsh)"
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"
command -v eza    >/dev/null 2>&1 && alias ls='eza'
alias grep='grep --color=auto'
```

`command -v <tool> >/dev/null 2>&1` is the standard portable guard. It returns 0 only when the binary is in `$PATH`; the `>/dev/null 2>&1` suppresses any output from shells that print to stdout or stderr on failure. The `grep` alias has no guard because `grep` is always present on both macOS and Arch.

### What must NOT appear in `shared.zsh`

| Forbidden content | Reason |
|---|---|
| `brew`, `/opt/homebrew`, `/usr/local/Cellar`, `brew install` | macOS-only — belongs in `macos.zsh` |
| `pacman`, `yay`, `paru`, `systemctl` | Arch-only — belongs in `arch.zsh` |
| `pbcopy`, `pbpaste`, `open` | macOS-only builtins — belongs in `macos.zsh` |
| Hardcoded absolute paths with OS differences | Not portable |
| Plugin loading (`zinit light`, `zinit snippet`) | Plugin adoption is a separate initiative (PRD-0010 non-goal) |
| `oh-my-posh` `eval` | Belongs in `omp.zsh` |
| Private values, tokens, hostnames | Belongs in `local.zsh` (ADR-0023) |
| `git clone`, `brew install`, `apt install` | Network/mutating operations are forbidden at shell startup |

---

## §4 — Platform layer design (`macos.zsh`, `arch.zsh`)

Both files follow the same principle: contain only what cannot be placed in `shared.zsh` or `local.zsh` because it is specific to this operating system.

### `macos.zsh` design

**Homebrew environment:**

```zsh
# Guard: activates only if brew is present. Handles Apple Silicon (/opt/homebrew) and Intel (/usr/local).
command -v brew >/dev/null 2>&1 && eval "$(brew shellenv)"
```

`brew shellenv` exports `HOMEBREW_PREFIX`, `HOMEBREW_CELLAR`, `HOMEBREW_REPOSITORY`, and adds Homebrew's `bin`, `sbin`, and `lib` to the appropriate path variables. Guarding with `command -v brew` handles the case where Homebrew is not yet installed on a fresh machine — the guard is a no-op and the shell still starts cleanly.

The earlier `.example` template used the literal `YOUR_HOMEBREW_PREFIX/bin/brew shellenv` pattern. That is superseded by the `command -v brew` guard, which does not require the user to know or hardcode the prefix. Homebrew installs itself into the right path on each chip architecture; `brew shellenv` handles the path exports correctly regardless.

**macOS-only aliases:**

```zsh
alias o='open'
```

`open` is a macOS-specific command that opens files and URLs with their associated application. No guard is needed because `macos.zsh` is only sourced on macOS.

**macOS PATH additions:**

Any macOS-specific `PATH` entries (e.g., tools installed outside Homebrew's standard bin) go here. The `.example` retains the `YOUR_MACOS_TOOL_PATH` placeholder for documentation — in the user's real `macos.zsh`, they replace or delete it.

**What does NOT belong in `macos.zsh`:**

- Anything portable (belongs in `shared.zsh`).
- Zinit, fzf, zoxide, eza guards (already in `shared.zsh` and work on both platforms).
- Oh My Posh activation (belongs in `omp.zsh`).
- Private PATH, tokens, hostnames (belongs in `local.zsh`).

### `arch.zsh` design

**Arch PATH additions:**

The `.example` retains the `YOUR_ARCH_TOOL_PATH` placeholder. In the real `arch.zsh`, the user fills in any Arch-specific tool locations (e.g., `/usr/local/bin` not already on the default Arch PATH, AUR-installed binaries in non-standard locations).

**pacman / yay / paru guards:**

```zsh
command -v yay  >/dev/null 2>&1 && alias aur='yay'
command -v paru >/dev/null 2>&1 && alias aur='paru'
```

AUR helpers are optional on Arch. Guards prevent errors on machines where neither is installed. The alias chooses the first available helper. Users who prefer a specific helper override in `local.zsh`.

**systemctl aliases:**

```zsh
alias sc='systemctl'
alias scu='systemctl --user'
```

`systemctl` is always present on Arch (systemd is the init system). No guard needed.

**What belongs in each vs. shared.zsh:**

| Configuration | `shared.zsh` | `macos.zsh` | `arch.zsh` | `local.zsh` |
|---|---|---|---|---|
| XDG exports | Yes | — | — | Override only |
| `$EDITOR`, `$PAGER` | Yes | — | — | Override only |
| `fzf`, `zoxide`, `eza` guards | Yes | — | — | Extended aliases |
| Homebrew `shellenv` | — | Yes | — | — |
| `open`, `pbcopy` aliases | — | Yes | — | — |
| macOS-only PATH additions | — | Yes | — | Private additions |
| `pacman`/`yay`/`paru` aliases | — | — | Yes | — |
| `systemctl` aliases | — | — | Yes | — |
| Arch-specific PATH additions | — | — | Yes | Private additions |
| Private tokens, hostnames | — | — | — | Yes |
| Work-specific config | — | — | — | Yes |

### OS detection

`index.zsh` uses:

```zsh
if [[ "$OSTYPE" == "darwin"* ]]; then
  [[ -r "$HOME/.config/zsh/macos.zsh" ]] && source "$HOME/.config/zsh/macos.zsh"
elif [[ -f /etc/arch-release ]]; then
  [[ -r "$HOME/.config/zsh/arch.zsh" ]] && source "$HOME/.config/zsh/arch.zsh"
fi
```

`$OSTYPE` is set by zsh itself at startup — it does not require `uname` and is always available. `darwin*` covers all macOS versions. `/etc/arch-release` is the authoritative Arch detection file that EndeavourOS also ships. The unused platform file (e.g., `arch.zsh` on macOS) is symlinked but never sourced — harmless (ADR-0016).

---

## §5 — `omp.zsh` design (Oh My Posh)

### Double guard

```zsh
if command -v oh-my-posh >/dev/null 2>&1 && [[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/omp/omp.toml" ]]; then
  eval "$(oh-my-posh init zsh --config "${XDG_CONFIG_HOME:-$HOME/.config}/omp/omp.toml")"
fi
```

Two independent conditions must both be true:

1. `command -v oh-my-posh` — the binary is in `$PATH`. Uses `command -v` rather than a file-existence check because the binary install location differs between macOS (Homebrew bin) and Arch (AUR bin, or `~/.local/bin` for the direct-binary install).
2. `[[ -f … omp.toml ]]` — the config file exists. Oh My Posh will error if invoked without a config file, so this guard prevents a broken prompt on machines where the `common/omp` Stow package has not been applied yet.

The `${XDG_CONFIG_HOME:-$HOME/.config}` fallback mirrors the same pattern used in `shared.zsh` for XDG exports — it resolves correctly even if XDG variables were not exported before this file was sourced (which cannot happen in the normal startup chain, but is a safe defensive pattern).

### Config path

`$XDG_CONFIG_HOME/omp/omp.toml` — this is the standard path managed by the `common/omp` Stow package (PRD-0005). The `omp.zsh` activation guard must reference the same path the omp package stows to. Any mismatch results in the config-file guard failing silently and OMP not activating.

### Why a separate file

Oh My Posh activation is separated into `omp.zsh` for three reasons:

1. **Opt-in isolation.** A user who does not want Oh My Posh simply does not create `omp.zsh`. The managed layer works without a prompt engine; the default zsh prompt remains. No guard is needed in `shared.zsh` or `index.zsh` because the `[[ -r "…/omp.zsh" ]]` guard in `index.zsh` already handles the absent case.

2. **Deployment flexibility.** On machines where Oh My Posh is not installed (e.g., a minimal Arch server environment), not creating `omp.zsh` achieves the no-prompt-engine state without any code change. Machines where OMP is installed create `omp.zsh` from the template; the double guard protects against partial states.

3. **Separation of concerns.** Prompt initialization is the most latency-sensitive part of shell startup. Isolating it makes performance profiling and replacement straightforward.

### Relationship with `common/omp` Stow package

The `common/omp` package (PRD-0005) manages the OMP config:

```
stow/common/omp/.config/omp/omp.toml  →  ~/.config/omp/omp.toml
```

The `omp.zsh` activation file references this stowed path. Both packages must be stowed and the `omp.toml` must exist for the double guard to pass. The `.example` template in `omp.zsh.example` ships with the activation block commented out, preventing accidental activation on machines that have not stowed the omp package.

### Fallback

If either guard fails, the `if` block is skipped. No error is raised. The shell gets zsh's default right-prompt-less `%` prompt. This is the correct behavior for machines without OMP or without the omp config.

---

## §6 — `local.zsh` private boundary

### Physical location

`local.zsh` lives at `~/.config/zsh/local.zsh`. Under `--no-folding` (ADR-0024), `~/.config/zsh/` is a real directory owned by Stow — not a symlink into the repo. A file created directly in `~/.config/zsh/` resides physically outside the repository working tree. It cannot be staged by `git add` by accident because `git` operates on the working tree, and `~/.config/zsh/local.zsh` is not under the repo root (ADR-0026).

The `.gitignore` entry at `stow/common/zsh/.config/zsh/.gitignore` listing `local.zsh` is a belt-and-suspenders second line of defence. The primary privacy boundary is physical location.

### What belongs here

- Private `PATH` additions: internal tooling, work-specific binaries, machine-specific SDK paths.
- Private tokens and API keys: `export GITHUB_TOKEN=...`, `export ANTHROPIC_API_KEY=...`.
- Private hostnames and internal service URLs: `export WORK_REGISTRY=registry.internal.example.com`.
- Machine-specific environment overrides: different `$EDITOR` on a server, different `$PAGER`.
- Work-specific aliases and functions.
- Extended eza aliases (`ll`, `la`, `lt`, `tree`) — these are personal preferences not suitable for a committed template (see §12).
- FZF options (`FZF_DEFAULT_OPTS`, `FZF_DEFAULT_COMMAND`) — machine-specific.
- zoxide `--cmd` override if the user wants `cd` aliased to `z`.

### Source position: last

`index.zsh` sources `local.zsh` last (step 4). This guarantees `local.zsh` wins over all layers: `shared.zsh`, the platform layer, and `omp.zsh`. A user who needs a different `$EDITOR` on a specific machine sets it in `local.zsh` without modifying any committed file.

### No `.example` template (ADR-0023)

`local.zsh` has no `.example` template and no documented default content. Its content is machine-specific and sensitive by design. Providing a template would imply a canonical shape for private content, which is contrary to its purpose. The user creates it directly with their editor:

```
⚠️  MANUAL STEP — review before running
$EDITOR "$HOME/.config/zsh/local.zsh"
```

### Absence is safe

The source guard in `index.zsh`:

```zsh
[[ -r "$HOME/.config/zsh/local.zsh" ]] && source "$HOME/.config/zsh/local.zsh"
```

If `local.zsh` does not exist, the guard evaluates false and the `&&` short-circuits. No error. Shell starts cleanly. Machines without private overrides work identically to machines with `local.zsh`.

---

## §7 — Optional tool guard strategy

### Standard pattern

```zsh
command -v <tool> >/dev/null 2>&1 && <action>
```

`command -v` is a POSIX-standard builtin that returns 0 when a binary is found in `$PATH` and non-zero otherwise. `>/dev/null 2>&1` suppresses both stdout and stderr. The `&&` short-circuits on non-zero exit, so `<action>` runs only when the tool is present.

### When to use `command -v` vs. file-existence check

| Check | When to use | Examples |
|---|---|---|
| `command -v <tool>` | Tool is a `$PATH` binary installed in a standard location | `fzf`, `zoxide`, `eza`, `oh-my-posh`, `brew` |
| `[[ -f <path> ]]` | Tool is a shell script or a file sourced by path, not in `$PATH` | `zinit.zsh`, `omp.toml` |
| `[[ -r <path> ]]` | File must be readable before sourcing | All `source` calls in `index.zsh` |

### Tool-specific guards

**fzf:**

```zsh
command -v fzf >/dev/null 2>&1 && eval "$(fzf --zsh)"
```

Modern fzf (0.48+) provides `fzf --zsh` which outputs a self-contained shell script enabling key bindings (`Ctrl-R`, `Ctrl-T`, `Alt-C`) and completion. This is the recommended integration method — it does not require manual `FPATH` manipulation or `bindkey` calls. No `FZF_DEFAULT_OPTS` or `FZF_DEFAULT_COMMAND` defaults are set in the committed template; those are machine-specific and belong in `local.zsh`.

**zoxide:**

```zsh
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"
```

`zoxide init zsh` outputs the `z` and `zi` function definitions plus the hook that updates the zoxide database on each `cd`. No `--cmd` override is set in the template — if the user wants `cd` to invoke `z`, they add `--cmd cd` in `local.zsh` by overriding or re-running the init there.

**eza:**

```zsh
command -v eza >/dev/null 2>&1 && alias ls='eza'
```

Minimal alias only: `ls` → `eza`. Extended aliases (`ll`, `la`, `lt`) are personal preference and belong in `local.zsh`. See §12 for the aliases strategy.

**oh-my-posh:**

Double guard as documented in §5: `command -v oh-my-posh` plus `[[ -f … omp.toml ]]`. Both must be true.

**Zinit:**

```zsh
[[ -f "${ZINIT_HOME}/zinit.zsh" ]] && source "${ZINIT_HOME}/zinit.zsh"
```

File-existence check, not `command -v`, because Zinit is a shell script. See §8 for the full Zinit strategy.

**Homebrew:**

```zsh
command -v brew >/dev/null 2>&1 && eval "$(brew shellenv)"
```

`command -v brew` resolves correctly on both Apple Silicon (`/opt/homebrew/bin/brew`) and Intel (`/usr/local/bin/brew`) because Homebrew's installer places the binary in the correct location for the chip architecture and that location is on the default `$PATH` after installation.

### Shell must start cleanly with all optional tools absent

Every tool guard is independently a no-op when the tool is missing. A machine with none of fzf, zoxide, eza, zinit, oh-my-posh, and brew still starts a clean shell with portable aliases (`grep --color=auto`), history, XDG exports, and `$EDITOR`/`$PAGER` set.

---

## §8 — Zinit plugin strategy

### Source guard pattern (ADR-0020)

```zsh
ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
[[ -f "${ZINIT_HOME}/zinit.zsh" ]] && source "${ZINIT_HOME}/zinit.zsh"
```

The guard is a no-op when Zinit is absent. The shell starts cleanly. No bootstrap, no clone, no network access.

### Where plugin declarations live

Plugin declarations (`zinit light`, `zinit snippet`) belong inside `shared.zsh` **after** the Zinit source guard. The placement is conditional on Zinit loading:

```zsh
ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
[[ -f "${ZINIT_HOME}/zinit.zsh" ]] && source "${ZINIT_HOME}/zinit.zsh"

# Plugin declarations here — only reached if zinit.zsh was sourced above.
# Example pattern (not the actual plugin selection — deferred to a future PRD):
# zinit light some-author/some-plugin
# zinit snippet OMZ::plugins/git/git.plugin.zsh
```

When Zinit is absent, all lines after the guard are still read by the shell, but any `zinit` function calls in those lines would fail with "command not found". To prevent this, plugin declaration blocks must be wrapped in a `typeset -f zinit >/dev/null 2>&1` check:

```zsh
if typeset -f zinit >/dev/null 2>&1; then
  # zinit light author/plugin
  # zinit snippet URL
fi
```

This is the pattern the `.example` templates document. The user fills in their actual plugins.

### Completion integration

When Zinit is loaded, it calls `compinit` internally at the appropriate time. The `shared.zsh` completion guard:

```zsh
if ! typeset -f zinit >/dev/null 2>&1; then
  autoload -Uz compinit && compinit
fi
```

This avoids a double `compinit` — a second `compinit` call wastes startup time and can trigger security warnings. The guard's position in `shared.zsh` (after the Zinit source guard) is critical: `typeset -f zinit` is true only if Zinit was already sourced above.

### Plugin adoption is out of scope for PRD-0010

The `.example` templates show the declaration pattern (`zinit light`, `zinit snippet`) in comments only. Actual plugin selection is a separate initiative. The architecture record here documents the pattern, not the plugin list.

### `zinit light` vs. `zinit snippet`

- `zinit light <author>/<repo>` — loads a GitHub plugin without tracking (no report/ice). Suitable for most plugins.
- `zinit snippet <URL-or-OMZ-path>` — loads a single file (snippet). Suitable for individual plugin files from Oh My Zsh library or direct URLs.

Both patterns are safe in the committed template (they are in comments). The user decides which plugins to load in their real `shared.zsh`.

---

## §9 — PATH strategy

No `shared.zsh` content modifies `$PATH` directly. The portable layer assumes a working `$PATH` is already established at shell entry (from `/etc/profile`, `/etc/zprofile`, or the user's existing `~/.zshrc` lines). Modifying `$PATH` in `shared.zsh` would create ordering dependencies that differ by platform.

| Layer | PATH role |
|---|---|
| `shared.zsh` | No PATH modifications. Sets XDG, env, history, options, tool guards only. |
| `macos.zsh` | Homebrew `shellenv` (adds Homebrew bin, sbin, man); macOS-specific tool PATH additions via `YOUR_MACOS_TOOL_PATH` placeholder. |
| `arch.zsh` | Arch-specific tool PATH additions via `YOUR_ARCH_TOOL_PATH` placeholder. |
| `local.zsh` | Private PATH additions — internal tools, work-specific binaries. Always last; wins over platform layer. |

### XDG_BIN_HOME and `~/.local/bin`

`~/.local/bin` is the standard XDG user-local binary directory (it is the resolved value of `$XDG_BIN_HOME` as defined in the XDG Base Directory spec, though `XDG_BIN_HOME` is not exported by this managed layer). Tools installed without root (e.g., the direct-binary install of `oh-my-posh`) are typically placed in `~/.local/bin`. This directory is commonly pre-existing on Arch and may need adding on macOS. Adding `~/.local/bin` to `PATH` is a portable operation suitable for `shared.zsh`, but it is not added in the committed template because the value is a personal convention. Users who rely on `~/.local/bin` add it in `local.zsh` or in `macos.zsh`/`arch.zsh` as appropriate.

---

## §10 — History strategy

### HISTFILE at `$HOME/.zsh_history`

```zsh
export HISTFILE="$HOME/.zsh_history"
```

`HISTFILE` is deliberately placed at `$HOME/.zsh_history` rather than under `$XDG_STATE_HOME`. Reasons:

1. **zsh default.** `$HOME/.zsh_history` is zsh's built-in default. Keeping the default avoids surprising users who grep for their history file.
2. **XDG_STATE_HOME complexity.** `XDG_STATE_HOME` is `$HOME/.local/state` by convention, but it is not exported by this managed layer. Using `${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history` would require a directory that does not exist on a fresh machine. Creating directories at shell startup is a side effect; `$HOME/.zsh_history` requires no directory creation.
3. **Backward compatibility.** Existing `$HOME/.zsh_history` files carry full history from before this managed layer. Moving the file to XDG would silently lose history or require a migration step. Keeping the default path avoids this.

The `shared.zsh` template and the `.example` both carry a comment explaining this choice.

### HISTSIZE and SAVEHIST

```zsh
export HISTSIZE=10000
export SAVEHIST=10000
```

`HISTSIZE` is the in-memory limit (number of events held in the session). `SAVEHIST` is the on-disk limit (number of events saved to `$HISTFILE` at session end). Setting both to 10000 is a reasonable default for a developer workflow. Users who need more override in `local.zsh`.

### `HIST_IGNORE_DUPS` and `SHARE_HISTORY`

```zsh
setopt HIST_IGNORE_DUPS
setopt SHARE_HISTORY
```

`HIST_IGNORE_DUPS` prevents consecutive duplicate entries from being added to history. It does not deduplicate across non-consecutive entries.

`SHARE_HISTORY` shares history across all running zsh sessions by appending to `$HISTFILE` on every command and re-reading it when the history list is accessed. This means all terminal windows share a live history — desirable for developers with multiple terminals open simultaneously.

### `HIST_IGNORE_ALL_DUPS` tradeoff

`HIST_IGNORE_ALL_DUPS` is a stronger variant that deduplicates non-consecutive entries too. It removes the older entry when a duplicate is added, keeping history smaller. The tradeoff is that command chronology is lost for repeated commands. This choice is left to the user in their real `shared.zsh` or `local.zsh` — the committed `.example` shows only `HIST_IGNORE_DUPS` (the conservative default). The comment in the template notes the alternative.

---

## §11 — Completion strategy

### Zinit manages compinit when loaded

When Zinit sources successfully (the `[[ -f … zinit.zsh ]]` guard passes), Zinit initializes the completion system internally. No explicit `compinit` call is needed.

### Standalone compinit only when Zinit absent

```zsh
if ! typeset -f zinit >/dev/null 2>&1; then
  autoload -Uz compinit && compinit
fi
```

This runs only when Zinit is not loaded. On machines without Zinit, this is the completion bootstrap.

### Why the guard avoids double compinit

Calling `compinit` twice in the same shell session:

1. Wastes startup time — `compinit` scans completion function directories.
2. May print a warning about insecure completion directories if the second call is made with different options.
3. Resets completion state built up by Zinit plugins loaded before the second call.

The `typeset -f zinit` check is authoritative: if Zinit was successfully sourced, the `zinit` function exists in the shell; if the source guard failed (Zinit absent or corrupted), `zinit` is not defined and the standalone path runs.

### Platform-specific completions

Platform-specific completions (e.g., Homebrew's own completion system on macOS) belong in the respective platform layer:

- `macos.zsh`: Homebrew completions via `eval "$(brew shellenv)"` already includes completion additions. Additional Homebrew-specific `FPATH` additions go here.
- `arch.zsh`: AUR helper completions, pacman completions.

These must not appear in `shared.zsh`.

---

## §12 — Aliases strategy

### Committed in `.example`: minimal, guarded, portable

The committed `.example` files ship only aliases that are:

1. Guarded when they assume tool presence.
2. Portable across macOS and Arch.
3. Not personal preference (i.e., not opinionated about workflow).

| Alias | File | Guard | Notes |
|---|---|---|---|
| `alias grep='grep --color=auto'` | `shared.zsh` / `.example` | None (grep always present) | `--color=auto` is valid on both BSD grep (macOS) and GNU grep (Arch) |
| `alias ls='eza'` | `shared.zsh` / `.example` | `command -v eza` | Minimal alias only |
| `alias o='open'` | `macos.zsh.example` | None (open always present on macOS; file only sourced on macOS) | Example, commented out |
| `alias sc='systemctl'` | `arch.zsh.example` | None (systemctl always present on Arch) | Example, commented out |

### Extended aliases NOT in `.example`

`ll='ls -lh'`, `la='ls -lha'`, `lt='ls --sort=modified'`, and `tree` variants are personal preferences. The `.example` templates deliberately do not include them. These belong in:

- The user's real `shared.zsh` (if they want them on all machines), or
- `local.zsh` (if they are machine-specific or sensitive-context-dependent).

The design decision here is that the committed template represents the minimum safe default. Workflow-specific aliases are not defaults.

### macOS-only aliases in `macos.zsh.example`

`open`-based aliases belong only in `macos.zsh.example`. If added to `shared.zsh`, they would fail silently on Arch (no `open` binary) or require a guard.

### Arch-only aliases in `arch.zsh.example`

`pacman`, `yay`, `paru`, `systemctl` aliases belong only in `arch.zsh.example`.

### No aliases without guards that assume tool presence

Any alias that calls a tool not guaranteed to be present must be guarded. The `ls='eza'` alias is the canonical example: guarded with `command -v eza`, so `ls` falls back to the system default when eza is absent.

---

## §13 — No-folding Stow strategy

### `--no-folding` creates per-file symlinks (ADR-0024)

Under `--no-folding`, Stow creates `~/.config/zsh/` as a real directory and places one symlink per managed file inside it, rather than collapsing the whole directory into a single directory symlink into the repo.

The resulting layout after stowing:

```
~/.config/zsh/                           (REAL directory — created by Stow)
├── index.zsh         ->  …/stow/common/zsh/.config/zsh/index.zsh
├── shared.zsh        ->  …/stow/common/zsh/.config/zsh/shared.zsh
├── macos.zsh         ->  …/stow/common/zsh/.config/zsh/macos.zsh   (on macOS)
├── arch.zsh          ->  …/stow/common/zsh/.config/zsh/arch.zsh    (on Arch)
├── omp.zsh           ->  …/stow/common/zsh/.config/zsh/omp.zsh     (if real omp.zsh exists)
├── *.example         ->  …  (harmless reference copies)
└── local.zsh                   (REAL FILE — created by user directly; NOT a symlink)
```

### Adding a new managed file requires `--restow`

Stow does not automatically pick up new files added to the package after the initial stow. Each new `.example`-to-real file the user creates requires:

```
⚠️  MANUAL STEP — review dry-run output before running
stow --dir=stow/common --target="$HOME" --no-folding --simulate zsh
stow --dir=stow/common --target="$HOME" --no-folding --restow zsh
```

This is an accepted trade-off (ADR-0024). The alternative — automatic re-stow via a hook — would require automating a `$HOME`-touching operation, which violates the repository's safety rules.

### Dry-run mandatory before install (stow rules)

The repository requires `--simulate` before every real stow operation. This is enforced by documentation in `docs/stow-usage.md` and the `task dry-run AREA=common PACKAGE=zsh` convenience command. The Taskfile's `dry-run` task encapsulates the correct flags including `--no-folding`.

### New `.example` file added to the package

When a new `.example` file is added to `stow/common/zsh/.config/zsh/`, the following steps are required before the user's machine reflects the change:

1. Pull the updated repo.
2. Copy the `.example` to its real filename.
3. Fill in any placeholder values.
4. Re-stow with `--no-folding --restow` to create the new symlink.

The `.example` itself is symlinked immediately after any stow (it is a tracked file and always present in the package), but the real file's symlink only exists after the user copies and re-stows.

---

## §14 — Human setup guide requirement

### ADR-0028 requirement

ADR-0028 requires that any package with manual setup steps include a guide under `docs/guides/`. The zsh package has multiple manual steps (copying `.example` files, creating `local.zsh`, adding the include block). PRD-0010 explicitly calls for an updated `docs/guides/zsh-setup.md`.

### Current state

`docs/guides/zsh-setup.md` does not yet exist. The setup steps currently live in `docs/stow-usage.md` (the Zsh package adoption section). That section is an improvement over nothing, but it does not satisfy ADR-0028's requirement for a human-facing setup guide with all ten required sections.

### Required sections per ADR-0028

1. What this package manages.
2. What it does NOT manage.
3. Prerequisites (optional tools: Zinit, fzf, zoxide, eza, oh-my-posh).
4. How to copy `.example` files to real filenames and fill in values.
5. Dry-run step (`stow --simulate --no-folding`).
6. Apply step (`stow --no-folding`).
7. Manual activation steps (adding the guarded include block to `~/.zshrc`).
8. Validation steps (copy-pasteable).
9. Rollback steps.
10. Troubleshooting.
11. Expected final file layout.

### What is new in this PRD that the guide must cover

- The real content of `shared.zsh.example` and each tool guard.
- How to fill in `macos.zsh.example` (Homebrew guard, macOS PATH placeholder).
- How to fill in `arch.zsh.example` (Arch PATH placeholder, AUR helper guard).
- How to activate `omp.zsh.example` (copy, uncomment, re-stow).
- How to create `local.zsh` directly in `~/.config/zsh/` (not copied from repo).
- Validation commands matching PRD-0010's Validation Strategy section.
- The `--no-folding --restow` requirement when adding new files after initial stow.

The guide must not duplicate PRDs or architecture documents. It is the user-facing reference; this document is the implementer-facing reference.

---

## §15 — Validation

### Pre-commit validation (on managed files in the repo)

```bash
# No placeholder tokens remain in the tracked shared.zsh
grep 'YOUR_' stow/common/zsh/.config/zsh/shared.zsh
# Must produce no output

# No platform-specific content in shared.zsh
grep -E '(brew |pacman |yay |paru |pbcopy|pbpaste|systemctl|git clone|curl |wget )' \
  stow/common/zsh/.config/zsh/shared.zsh
# Must produce no output

# Syntax check on tracked files
zsh -n stow/common/zsh/.config/zsh/shared.zsh
zsh -n stow/common/zsh/.config/zsh/index.zsh
# Both must exit 0 with no output

# No real managed files accidentally tracked
git ls-files stow/common/zsh/.config/zsh/ | grep -vE '\.example$|\.gitignore$|index\.zsh$|shared\.zsh$'
# Must produce no output (only index.zsh and shared.zsh are intentionally tracked real files)
```

### Stow dry-run as pre-validation

```bash
TEST_HOME="$(mktemp -d)"
stow --dir=stow/common --target="$TEST_HOME" --no-folding --simulate zsh
rm -rf "$TEST_HOME"
# Must produce no output (no conflicts in clean fake home)
```

### Layer load verification (after setup, on the user's machine)

```bash
# 1. Managed layer loads cleanly
zsh --no-rcs -c 'source ~/.config/zsh/index.zsh; echo OK'
# Expected: OK (no errors)

# 2. EDITOR and PAGER set correctly
zsh --no-rcs -c 'source ~/.config/zsh/index.zsh; echo $EDITOR $PAGER'
# Expected: nvim less (or user's local.zsh override)

# 3. XDG_CONFIG_HOME set
zsh --no-rcs -c 'source ~/.config/zsh/index.zsh; echo $XDG_CONFIG_HOME'
# Expected: ~/.config (or user override)

# 4. HISTFILE set
zsh --no-rcs -c 'source ~/.config/zsh/index.zsh; echo $HISTFILE'
# Expected: ~/.zsh_history

# 5. zoxide function present (if zoxide installed)
zsh --no-rcs -c 'source ~/.config/zsh/index.zsh; type z'
# Expected: z is a shell function (if installed), or "z not found" without error

# 6. ls alias (if eza installed)
zsh --no-rcs -c 'source ~/.config/zsh/index.zsh; type ls'
# Expected: ls is an alias for eza (if installed), or ls is /bin/ls

# 7. Clean start with all optional tools absent
zsh --no-rcs -c 'source ~/.config/zsh/index.zsh; echo OK'
# Must print OK with no errors even if Zinit, fzf, zoxide, eza, oh-my-posh are absent
```

### Symlink verification

```bash
# ~/.config/zsh is a real directory (not a symlink)
[[ -d "$HOME/.config/zsh" && ! -L "$HOME/.config/zsh" ]] && echo "real-dir-ok" || echo "NOT-real-dir"

# Managed file symlinks resolve into the repo
ls -la ~/.config/zsh/
# Each managed file should show: <file> -> <absolute-path-into-repo>/stow/common/zsh/.config/zsh/<file>

# local.zsh is a real file, not a symlink (if present)
p="$HOME/.config/zsh/local.zsh"
if   [[ -L $p ]]; then echo "local.zsh (SYMLINK — WRONG)"
elif [[ -e $p ]]; then echo "local.zsh (real file — ok)"
else echo "local.zsh (absent — ok)"; fi
```

---

## §16 — Rollback

### Stow `--delete` removes symlinks; `~/.zshrc` stays untouched

```
⚠️  MANUAL STEP — review dry-run output before running
stow --dir=stow/common --target="$HOME" --simulate --delete zsh
stow --dir=stow/common --target="$HOME" --delete zsh
```

This removes the per-file symlinks from `~/.config/zsh/`. The real directory `~/.config/zsh/` remains (Stow does not remove directories it created under `--no-folding` if files still exist in them, such as `local.zsh`).

### No `$HOME` files are modified by this work

PRD-0010's implementation scope is strictly the `.example` files in the repo. No step:

- Modifies `~/.zshrc`.
- Runs Stow against `$HOME`.
- Creates symlinks in `$HOME`.
- Installs any tool.

The rollback scope is therefore narrow: the only thing to revert is the Stow symlinks — and only after the user has manually run Stow (which happens after this architecture document, plan, and implementation are complete).

### Disabling the layer

To disable the managed layer without unstowing:

```
⚠️  MANUAL STEP
```

1. Open `~/.zshrc`.
2. Delete or comment out the three-line managed block.
3. Open a new shell — managed layer is immediately inert.

This is the fastest rollback. No stow operation required.

---

## §17 — ADRs to create

The last existing ADR is **ADR-0032**. New records start at **ADR-0033**.

| Number | Title | Decision to capture | Why a dedicated ADR |
|---|---|---|---|
| **ADR-0033** | `shared.zsh` content scope: what is portable, what is not | Explicit list of what belongs in the portable layer and what is forbidden, with rationale for each boundary | No existing ADR defines content scope at this level of detail; Architecture-0004 defined the concept but not the specific content boundaries established by this PRD |
| **ADR-0034** | `macos.zsh` and `arch.zsh` as runtime-selected platform layers | The platform files are sourced only on their target OS; both are always symlinked; the unused file is harmless | ADR-0016 established the single-package layout but did not capture the specific content scope for each platform file; this PRD defines both |
| **ADR-0035** | `omp.zsh` as a standalone, double-guarded prompt file | Oh My Posh activation is isolated in its own file with two independent guards (binary + config file); absent `omp.zsh` falls back to default zsh prompt | No existing ADR captures the double-guard pattern or the isolation rationale; Architecture-0008 documented it as "opt-in" but did not formalize the design |
| **ADR-0036** | `local.zsh` created directly by the user with an editor, not copied from `.example` | The user creates `local.zsh` with `$EDITOR "$HOME/.config/zsh/local.zsh"` — there is no `.example` to copy from | ADR-0023 and ADR-0026 establish that `local.zsh` is unversioned and outside the repo; this ADR formalizes the creation workflow and explains why no template exists |
| **ADR-0037** | Extended aliases (`ll`, `la`, `lt`) excluded from committed `.example` files | Only minimal, guarded, uncontroversial aliases (`grep --color=auto`, `ls='eza'`) appear in committed templates; extended aliases are personal preference and belong in `local.zsh` | No existing ADR draws this line; without it, future contributors may add opinionated aliases to the templates |
| **ADR-0038** | HISTFILE at `$HOME/.zsh_history`, not XDG | `$HISTFILE` uses zsh's built-in default path to avoid directory-creation side effects, preserve existing history, and avoid `$XDG_STATE_HOME` complexity | No existing ADR addresses history file placement; the rationale is specific enough to warrant a record |
| **ADR-0039** | Completion guard: avoid double `compinit` when Zinit is present | `compinit` is only called standalone when `typeset -f zinit >/dev/null 2>&1` returns false | No existing ADR captures this guard pattern; it is a subtle startup-performance and correctness decision that future contributors must not accidentally remove |
| **ADR-0040** | `fzf --zsh` as the fzf integration method | Modern fzf provides `fzf --zsh` which handles key bindings and completion in one call; manual `FPATH`/`bindkey` setup is not used | No existing ADR specifies the fzf integration method; the choice has implications for fzf version requirements |
| **ADR-0041** | `zoxide init zsh` without `--cmd` override | The `--cmd` override (aliasing `cd` to `z`) is not set in the committed template; it is a personal preference left to `local.zsh` | No existing ADR covers zoxide initialization options; this decision is subtle but affects user muscle memory and should be documented |
| **ADR-0042** | Minimal `ls='eza'` alias only; extended eza aliases excluded from committed template | The committed template sets only `alias ls='eza'`; `ll`, `la`, `lt`, `tree` variants are personal and go in `local.zsh` | Follows directly from ADR-0037 but is specific to eza; eza's extensive alias ecosystem makes this a recurring decision point |

### ADR candidates evaluated but not recommended

- **HISTSIZE/SAVEHIST value choice:** the values (10000) are reasonable defaults, not architectural decisions. They can be changed without a new ADR.
- **`HIST_IGNORE_DUPS` vs. `HIST_IGNORE_ALL_DUPS`:** documented in the template comment; not significant enough for a standalone ADR.
- **`AUTO_CD` option:** a well-known portable option; the choice is minor and reversible via `local.zsh`.

---

## Design Decisions

**Decision 1 — `shared.zsh` content boundary is explicit and enforced by the `.example` template.** The committed template is the enforcement mechanism: it ships only portable, safe, guarded content. Content that exceeds that boundary has no place in the committed file and must go in platform layers or `local.zsh`. This is a change from Architecture-0004, which defined the boundary conceptually but did not provide a filled-in template to enforce it.

**Decision 2 — `macos.zsh` and `arch.zsh` use `command -v` for optional tool guards, not hardcoded paths.** The `command -v brew` pattern is preferred over `/opt/homebrew/bin/brew` because it is chip-architecture-agnostic. A user on Intel with Homebrew at `/usr/local` does not need to change the template.

**Decision 3 — The `omp.zsh` double guard uses both `command -v oh-my-posh` and `[[ -f … omp.toml ]]`.** Either guard alone is insufficient: the binary can be present without the config (after OMP install but before the omp Stow package is applied), and vice versa on a machine where the config was left but OMP was uninstalled. Both together are necessary and sufficient for a functional activation.

**Decision 4 — Extended aliases (`ll`, `la`, `lt`) are excluded from all committed `.example` templates.** This is the narrowest possible opinionated scope for committed configuration. The alternative (shipping a rich alias set) would turn the `.example` into a configuration template that imposes workflow choices. The minimal approach respects that different users have different workflows.

**Decision 5 — `HISTFILE` stays at `$HOME/.zsh_history`.** Covered in §10. The XDG alternative would require directory creation at shell startup — a side effect inconsistent with the "no startup side effects" constraint.

**Decision 6 — No `FZF_DEFAULT_OPTS` or `FZF_DEFAULT_COMMAND` in the committed template.** These are machine-specific (different terminals have different capabilities; different codebases call for different file finders). They belong in `local.zsh`.

---

## Risks

| Risk | Likelihood | Severity | Mitigation |
|---|---|---|---|
| `shared.zsh` committed with a platform-specific tool call | Low | High | Pre-commit `grep` check; content boundary in §3 explicit; Reviewer checklist |
| `macos.zsh.example` or `arch.zsh.example` missing a guard for an optional tool | Medium | Low | Tool guard strategy in §7 explicit; every optional tool must be guarded |
| `omp.zsh` double guard bypassed by a future contributor who only checks one condition | Low | Medium | ADR-0035 documents both conditions as mandatory; Reviewer checklist |
| Extended alias added to `.example` that assumes tool presence without guard | Medium | Low | ADR-0037 establishes the no-unguarded-aliases rule; Reviewer checks |
| `local.zsh` accidentally committed (e.g., by a new contributor unfamiliar with the gitignore) | Low | High | Physical location outside repo is the primary guard; `.gitignore` is secondary; validation §15 checks `git ls-files` |
| Shell startup fails when `$HISTFILE` directory does not exist | Low | Low | `$HOME` always exists; `$HOME/.zsh_history` parent is `$HOME` — no directory creation needed |
| `fzf --zsh` unavailable on older fzf versions | Low | Low | `fzf --zsh` was introduced in fzf 0.48 (2024). The guard `command -v fzf` succeeds even on old fzf, but `fzf --zsh` errors. Mitigation: the PRD requires a minimum fzf version note in the guide. Users on very old fzf use `local.zsh` for the manual binding approach |
| Double `compinit` introduced by a future platform layer | Medium | Low | ADR-0039 forbids standalone `compinit` outside the `shared.zsh` Zinit guard; Reviewer checks |
| Cross-platform alias leak (macOS alias in `shared.zsh`) | Low | Medium | Forbidden content list in §3 explicit; `grep` pre-commit check in §15 |

---

## Extensibility

- **New portable tool integration:** add a guarded `command -v <tool>` line to `shared.zsh` and `shared.zsh.example`. No structural change.
- **New macOS-only tool:** add a guarded or unguarded (macOS-only file) line to `macos.zsh.example`. No structural change.
- **New Arch-only tool:** add to `arch.zsh.example`. No structural change.
- **Third platform:** add a new `<platform>.zsh.example` to the package and an `elif` branch to `index.zsh`. The `.gitignore` needs one entry for the real file.
- **Zinit plugin adoption:** add `zinit light` / `zinit snippet` lines inside the Zinit-loaded block in `shared.zsh`. A separate PRD will govern plugin selection.
- **New private environment variable:** add to `local.zsh`. No repo change.
- **Alternative prompt engine:** replace or extend `omp.zsh` with a new `<engine>.zsh` file and a new source line in `index.zsh`. The double-guard pattern applies to any prompt engine.

---

## Open Questions

1. **`macos.zsh.example` `pbcopy`/`pbpaste` aliases:** The current `.example` only has `alias o='open'` (commented). Should `pbcopy`/`pbpaste` convenience aliases be added? Non-blocking; no architectural impact.

2. **`FZF_DEFAULT_OPTS` documentation in `shared.zsh.example` comment:** The committed template currently has no mention of `FZF_DEFAULT_OPTS`. Should the comment note this option exists and belongs in `local.zsh`? Non-blocking; documentation quality only.

3. **`~/.local/bin` in PATH:** Should `macos.zsh.example` add `~/.local/bin` to `$PATH` for macOS users who install tools via the direct binary method? Currently left to `local.zsh`. Non-blocking.

4. **`zshrc.example` content:** The current `zshrc.example` includes a `meteo` alias (`curl -4 http://wttr.in/Paris`). This is a personal alias that should be removed from the committed template before this PRD's implementation. Non-blocking but should be cleaned up.

---

## Recommended Next Step

Planner writes `docs/plans/0014-real-zsh-configuration-plan.md`. The plan must cover:

1. Update `macos.zsh.example` with real, guarded content: `command -v brew` guard, macOS aliases, PATH placeholder cleaned up.
2. Update `arch.zsh.example` with real, guarded content: AUR helper guards (`command -v yay`, `command -v paru`), `systemctl` aliases, PATH placeholder.
3. Update `omp.zsh.example`: uncomment the double-guarded eval block, remove the outdated comment referencing a manual source line in `shared.zsh` or `~/.zshrc` (activation is handled by `index.zsh` sourcing `omp.zsh`).
4. Clean up `zshrc.example`: remove the `meteo` alias. This is a personal alias that must not appear in a committed template.
5. Write ADR-0033 through ADR-0042 (§17).
6. Write `docs/guides/zsh-setup.md` per ADR-0028 requirements (§14).
7. Per-step validation from §15.
8. Safety check per step: `~/zshrc` not modified, `$HOME` not modified, no Stow run against real home, no dependency installed.
9. Rollback notes from §16.

Every command that touches `$HOME` must carry the `⚠️  MANUAL STEP — review before running` marker. Stow dry-run before every real stow.
