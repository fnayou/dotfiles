# PRD: Real Zsh Configuration Adoption

**Number:** 0010
**Status:** Draft
**Date:** 2026-06-19
**Branch:** feat/real-zsh-configuration

## Background

The managed zsh layer is active (ADR-0021 through ADR-0027). `~/.zshrc` sources `~/.config/zsh/index.zsh` via a guarded include block. `index.zsh` and `shared.zsh` exist as committed `.example` templates only — no real filled-in files have been created yet. The managed layer is structurally complete but carries only safe defaults. No real personal zsh configuration has been adopted into it.

This PRD covers adopting real zsh configuration content into the managed layer safely, without modifying `~/.zshrc`, without touching `$HOME`, and without committing private or sensitive values.

## Goals

- Populate `shared.zsh` with real, portable zsh configuration (env, history, aliases, Zinit, tool integrations).
- Populate `macos.zsh` with macOS-specific configuration.
- Populate `arch.zsh` with Arch/EndeavourOS-specific configuration.
- Populate `omp.zsh` with Oh My Posh prompt integration (guarded).
- Define what belongs in `local.zsh` (private, outside repo, never committed).
- Ensure every optional tool integration is guarded with `command -v` or equivalent.
- Ensure shell startup performs zero network access or package installation.
- Produce a human setup guide update for `docs/guides/zsh-setup.md` (ADR-0028).

## Non-Goals

- Do not modify `~/.zshrc`.
- Do not run Stow against `$HOME`.
- Do not install any dependency (Zinit, fzf, zoxide, eza, oh-my-posh).
- Do not auto-clone Zinit at shell startup.
- Do not commit `local.zsh`, `shared.zsh`, `macos.zsh`, `arch.zsh`, or `omp.zsh` — only their `.example` templates are committed (ADR-0025).
- Do not commit secrets, private hostnames, real email addresses, credentials, or machine-specific values.
- Do not create platform-specific Stow packages. The `common/zsh` package serves both platforms; OS detection is runtime (`$OSTYPE`, `/etc/arch-release`).
- Do not configure Zinit plugins in this PRD — Zinit plugin adoption is a separate initiative.

## User Stories

- As a user setting up a new machine, I copy `.example` files to real filenames, fill in my values, and run Stow — the managed layer activates with my real configuration.
- As a user with tools missing on a fresh machine, I start a shell and it loads cleanly without errors or hanging, because every optional tool is guarded.
- As a user with sensitive machine-specific values, I put them in `local.zsh` outside the repo — they are never committed and never visible to agents.
- As a user reading the setup guide, I can follow ordered steps to activate the real configuration without reading PRDs or architecture documents.

## Constraints

- Platform: macOS (primary), Arch/EndeavourOS. Both must work.
- All `.example` files use placeholder values only — no real values.
- Shell startup must be synchronous, offline, and free of side effects.
- `local.zsh` lives at `~/.config/zsh/local.zsh` outside the repo (ADR-0026). It cannot be staged by git.
- Stow uses `--no-folding` (ADR-0024). Each new file requires `--restow` to create its symlink.
- Home directory must not be modified by any automated step.

## Managed File Layout

```
stow/common/zsh/.config/zsh/
├── .gitignore              # ignores real files; keeps .example files tracked
├── index.zsh.example       # entry point: source order, platform branch, local slot
├── shared.zsh.example      # portable config: env, XDG, history, Zinit guard, tool guards
├── macos.zsh.example       # macOS-specific: PATH, brew env, pbcopy/open aliases
├── arch.zsh.example        # Arch-specific: PATH, pacman/yay aliases, systemctl aliases
└── omp.zsh.example         # Oh My Posh: guarded eval, config path
```

Real files (`shared.zsh`, `macos.zsh`, `arch.zsh`, `omp.zsh`) are git-ignored and created locally by copying the corresponding `.example` template. They are symlinked by Stow but never committed.

`local.zsh` has no `.example` template. The user creates it directly at `~/.config/zsh/local.zsh` using their editor. It is sourced last by `index.zsh` and wins over all other layers.

## Local/Private Override Strategy

`local.zsh` is the sole location for:
- Private `PATH` additions (internal tools, work-specific binaries).
- Private API tokens or credential exports (e.g., `GITHUB_TOKEN`).
- Private hostnames or internal service URLs.
- Machine-specific environment overrides that differ between machines.
- Work-specific configuration not appropriate for a shared repository.

Rules:
- Never committed. Never symlinked by Stow. Lives outside the repo working tree.
- Sourced last by `index.zsh`, so it wins over `shared.zsh`, `macos.zsh`/`arch.zsh`, and `omp.zsh`.
- Its absence is safe: `index.zsh` guards the source with `[[ -r … ]]`.
- No `.example` template exists for it — its content is machine-specific and sensitive by design (ADR-0023, ADR-0026).

## Optional Tool Guard Strategy

Every tool integration must be guarded. No tool may run unconditionally at shell startup.

Required pattern:

```zsh
# Guard: activates only when the tool is installed; no-op otherwise.
command -v <tool> >/dev/null 2>&1 && eval "$(<tool> <init-flags>)"
```

Tools requiring guards in `shared.zsh`:
- `fzf` — `eval "$(fzf --zsh)"`
- `zoxide` — `eval "$(zoxide init zsh)"`
- `eza` — `alias ls='eza'`
- `zinit` — sourced from `${ZINIT_HOME}/zinit.zsh` only if the file exists (ADR-0020)

Tools requiring guards in `omp.zsh`:
- `oh-my-posh` — `command -v oh-my-posh` plus config file presence check

Tools requiring guards in `macos.zsh`:
- `brew` — Homebrew environment setup (`eval "$(brew shellenv)"`) guarded by binary presence
- Any macOS-only tool (e.g., `mise`, `direnv`) guarded with `command -v`

Tools requiring guards in `arch.zsh`:
- Any Arch-only tool guarded with `command -v`

## Zinit Strategy

Zinit is a plugin manager. Its source-only guard is already in `shared.zsh.example`:

```zsh
ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
[[ -f "${ZINIT_HOME}/zinit.zsh" ]] && source "${ZINIT_HOME}/zinit.zsh"
```

Rules:
- Never auto-clone Zinit at shell startup (ADR-0020).
- The guard is a no-op when Zinit is absent.
- Manual install command is documented in comments and in the setup guide, never executed automatically.
- Plugin declarations (`zinit light`, `zinit snippet`) belong inside `shared.zsh` after the source guard. They load only if Zinit was successfully sourced.
- Zinit plugin selection is outside the scope of this PRD. The `.example` template shows the pattern; the user fills in their actual plugins in their local `shared.zsh`.

## Oh My Posh Strategy

Oh My Posh is activated via `omp.zsh`, sourced by `index.zsh` (step 3):

```zsh
# omp.zsh.example
if command -v oh-my-posh >/dev/null 2>&1 && [[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/omp/omp.toml" ]]; then
  eval "$(oh-my-posh init zsh --config "${XDG_CONFIG_HOME:-$HOME/.config}/omp/omp.toml")"
fi
```

Rules:
- Double-guarded: binary presence AND config file presence.
- Config path uses `$XDG_CONFIG_HOME` with `$HOME/.config` fallback.
- The `omp/omp.toml` config is managed by the `common/omp` Stow package (separate from this PRD).
- No fallback theme is set — if the guard fails, no prompt theme loads. The default zsh prompt remains.
- `omp.zsh` is git-ignored; only `omp.zsh.example` is committed.

## fzf Strategy

fzf integration in `shared.zsh`:

```zsh
command -v fzf >/dev/null 2>&1 && eval "$(fzf --zsh)"
```

- `fzf --zsh` provides key bindings (`Ctrl-R`, `Ctrl-T`, `Alt-C`) and completion.
- Guard ensures no error when fzf is absent.
- No `FZF_DEFAULT_OPTS` or `FZF_DEFAULT_COMMAND` defaults are set in the committed template — machine-specific options belong in `local.zsh`.
- fzf install path does not need to be hardcoded; `command -v fzf` resolves via `PATH`.

## zoxide Strategy

zoxide integration in `shared.zsh`:

```zsh
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"
```

- Replaces `cd` with `z` (and optionally `zi` for interactive selection).
- Guard ensures no error when zoxide is absent.
- No `--cmd` override is set in the template — if the user wants `cd` aliased to `z`, they add it in `local.zsh`.

## eza Alias Strategy

eza integration in `shared.zsh`:

```zsh
command -v eza >/dev/null 2>&1 && alias ls='eza'
```

- Minimal alias: `ls` → `eza` only.
- Extended aliases (`ll`, `la`, `lt`, `tree`) are user-specific and belong in `local.zsh` or in the real `shared.zsh` — not in the committed `.example`.
- `--color=auto` is not added to the alias since eza enables color by default. The `.example` comment notes this.
- Guard ensures `ls` works normally when eza is absent.

## macOS-Specific Strategy (`macos.zsh`)

`macos.zsh.example` covers:
- Homebrew environment: `command -v brew >/dev/null 2>&1 && eval "$(brew shellenv)"` — portable guard, no-op when Homebrew is absent.
- macOS clipboard aliases: `alias pbcopy` / `alias pbpaste` — not guarded (always available on macOS).
- macOS `PATH` additions for tools not on the default path.
- Any macOS-specific `MANPATH` or `INFOPATH` setup.

What does NOT belong here:
- Anything portable (belongs in `shared.zsh`).
- Secrets or private paths (belongs in `local.zsh`).
- Zinit or OMP (belongs in `shared.zsh` / `omp.zsh`).

## Arch-Specific Strategy (`arch.zsh`)

`arch.zsh.example` covers:
- `PATH` additions for Arch-specific tool locations.
- `pacman` / `yay` aliases.
- Systemd / `systemctl` convenience aliases.
- AUR helper detection (guarded with `command -v yay` or `command -v paru`).

What does NOT belong here:
- Anything portable (belongs in `shared.zsh`).
- Secrets or private paths (belongs in `local.zsh`).

## Privacy Requirements

- All `.example` files use placeholder values only.
- No real names, email addresses, hostnames, tokens, or credentials in any committed file.
- Placeholder convention: `YOUR_TOKEN`, `your-email@example.com`, `hostname.example.com`.
- The `.gitignore` at `stow/common/zsh/.config/zsh/.gitignore` already excludes real filenames (ADR-0025). No change needed.
- Pre-commit: run `git diff --staged` and inspect for real values before every commit.

## Safety Requirements

- Must not modify `~/.zshrc`.
- Must not create or modify any file in `$HOME` via automated step.
- Must not run `stow` against `$HOME` automatically.
- Must not install Zinit, fzf, zoxide, eza, or oh-my-posh.
- Must not perform network access at shell startup.
- Every optional tool integration must be guarded.
- Shell startup must succeed on a machine with no optional tools installed.
- `local.zsh` must never be committed. Its location outside the repo working tree (under `--no-folding`) is the primary boundary; the `.gitignore` entry is secondary.
- Stow dry-run (`--simulate`) must be shown to the user before any install step.

## Validation Strategy

After setup, the following must pass:

1. `zsh --no-rcs -c 'source ~/.config/zsh/index.zsh; echo OK'` — managed layer loads cleanly.
2. `echo $EDITOR $PAGER` — expected: `nvim less` (or user's values from `shared.zsh`).
3. `echo $XDG_CONFIG_HOME` — expected: `~/.config` (or user override).
4. `echo $HISTFILE` — expected: `~/.zsh_history`.
5. `type z` — expected: zoxide function (if zoxide installed); else `not found` without error.
6. `type ls` — expected: eza alias (if eza installed); else system `ls`.
7. New shell starts without error on a machine with no optional tools (Zinit, fzf, zoxide, eza, oh-my-posh all absent).
8. `ls -la ~/.config/zsh/` — shows symlinks for each managed file, real dir (not a symlink to repo).

## Rollback Strategy

1. Remove Stow symlinks:
   ```
   ⚠️  MANUAL STEP — review before running
   stow --dir=stow --target="$HOME" --delete common/zsh
   ```
2. Confirm `~/.config/zsh/` is empty or removed.
3. `~/.zshrc` is unchanged throughout (it was never modified).
4. Shell restores to pre-managed behavior on next login.

## Human Setup Guide

Per ADR-0028, an updated `docs/guides/zsh-setup.md` must be produced as part of this initiative. It must cover:

1. What the zsh package manages (files stowed, symlink targets).
2. What it does NOT manage (`~/.zshrc` stays unmanaged).
3. Prerequisites (optional tools: Zinit, fzf, zoxide, eza, oh-my-posh).
4. How to copy `.example` files to real filenames and fill in values.
5. Dry-run step (`stow --simulate`).
6. Apply step (`stow --no-folding`).
7. How to create `local.zsh` for private overrides.
8. Validation steps (copy-pasteable).
9. Rollback steps.
10. Troubleshooting.
11. Expected final file layout.

## Acceptance Criteria

- [ ] `shared.zsh.example` contains real, complete portable configuration: XDG, env, history, shell options, Zinit guard, completion fallback, fzf/zoxide/eza guards, grep alias.
- [ ] `macos.zsh.example` contains macOS-specific configuration: Homebrew env guard, macOS-only aliases.
- [ ] `arch.zsh.example` contains Arch-specific configuration: PATH additions, pacman/yay/paru guards, systemctl aliases.
- [ ] `omp.zsh.example` contains a double-guarded Oh My Posh init block.
- [ ] Every optional tool integration is guarded with `command -v` or file-existence check.
- [ ] No `.example` file contains real names, emails, tokens, hostnames, or credentials.
- [ ] Shell starts cleanly with all optional tools absent.
- [ ] Shell starts cleanly with all optional tools present (macOS).
- [ ] Shell starts cleanly with all optional tools present (Arch).
- [ ] `local.zsh` is not committed and has no `.example` template.
- [ ] `docs/guides/zsh-setup.md` updated with sections required by ADR-0028.
- [ ] `git diff --staged` shows no secrets before merge.

## Out of Scope

- Zinit plugin declarations (separate initiative).
- Oh My Posh theme content — `omp/omp.toml` is managed by the `common/omp` package (PRD-0005).
- Neovim, Alacritty, tmux, or any other tool not listed above.
- Modifying `~/.zshrc` or any file in `$HOME`.
- Automated bootstrap scripts or Taskfile tasks for zsh setup.
- Cross-machine dotfile synchronization.
- SSH, GPG, or credentials management.
