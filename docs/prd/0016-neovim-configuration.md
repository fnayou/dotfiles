# PRD: Neovim Configuration Package

**Number:** 0016
**Status:** Approved
**Date:** 2026-06-22

## Context

The repository has no editor package yet. The user currently uses Zed (primary,
everything: this repo, Python, Ansible, SOPS) and PHPStorm (heavy PHP/Symfony),
and plain `vim` for quick local edits and heavy maintenance/debug sessions on
servers. This package introduces a managed Neovim configuration that **replaces
the user's `vim` usage** — light local editing and heavy server work — while
being a full, learnable setup that may grow into a Zed replacement over time.

Inspiration (not wholesale copy): `josephschmitt/dotfiles` nvim config, built on
`kickstart.nvim`. We adopt its structure and a curated subset of plugins.

## Goals

- Add a new common Stow package `stow/common/nvim` providing `~/.config/nvim`
  (XDG-native, identical on macOS and Arch).
- Base the config on **stock `kickstart.nvim`** with custom plugins under
  `lua/custom/plugins/` — chosen for learnability (heavily commented upstream).
- Theme with **Catppuccin Macchiato, blue accent (`#8aadf4`)**, matching the
  existing alacritty / zsh / oh-my-posh / bat / eza identity.
- Provide a curated, full local plugin set (see Scope) including an LSP stack.
- Wire LSP servers for the languages the user actually edits: PHP, Lua, Bash,
  YAML, JSON, Python, Ansible, Docker (Dockerfile + Compose).
- Make Neovim the terminal `$EDITOR`/`$VISUAL` and enable the zsh
  `edit-command-line` widget (`Ctrl-x Ctrl-e`) — a related change to the
  existing `zsh` package.
- Document dependencies per-platform (not auto-installed) and provide a usage +
  per-plugin + keybind-cheatsheet guide, including `vimtutor` as the entry point.

## Non-Goals

- Not a primary IDE replacement on day one (Zed/PHPStorm remain for their roles).
- No framework-specific tooling (no `laravel.nvim`, no Symfony plugin) — PHP
  language server only.
- No lean/server-only profile or profile-splitting in this iteration (single
  full config; a server trim may be a later PRD).
- No tmux/Herdr pane-navigation integration (explicitly dropped).
- No automatic stowing, no symlink creation, no dependency auto-install.

## User Stories

- As the user, I want a themed, capable Neovim so that I can replace `vim` for
  local quick edits and server maintenance/debug with a consistent experience.
- As a Neovim newcomer, I want a documented, commented config and a pointer to
  `vimtutor` so that I can learn incrementally without drowning in plugins.
- As a cross-platform user, I want one config that works identically on macOS
  and Arch so that my editor feels the same everywhere.
- As someone who edits long shell commands, I want `Ctrl-x Ctrl-e` to open the
  command in Neovim so that I can edit complex commands comfortably.
- As a maintainer of this repo, I want the package to follow the existing Stow /
  privacy / cross-platform conventions so that it stays safe and consistent.

## Constraints

- **Platform:** Common — must work on both macOS and Arch without modification.
  Dependency install commands must be given separately per platform.
- **Safety:** Must not stow automatically, must not create or overwrite symlinks
  in `$HOME`, must not modify files outside the repository.
- **Privacy:** Config is non-secret, but must contain no real hostnames, tokens,
  or machine-specific paths; use `$HOME`/XDG, not hardcoded user paths.
- **Dependencies (documented, not auto-run):** `neovim`, `git`, `ripgrep`,
  `fd`, `node` (node-based LSP servers), `python` + `pipx` (ruff, ansible-lint),
  a C compiler (treesitter parsers). LSP servers themselves are Mason-managed.
- **Existing package:** the `$EDITOR`/`$VISUAL`/`edit-command-line` change
  modifies the already-real `zsh` package and must respect its file layout.

## Safety Requirements

- Must not delete or overwrite any existing user dotfiles.
- Must not run `stow`, `stow --adopt`, `ln -s`, `rm`, or `mv` against `$HOME`.
- Stow install steps must show a `--simulate` dry-run first, marked as a manual
  step, and be executed by the user only.
- Dependency installation must be documented per-platform and never executed by
  an agent or script.
- The zsh change must be additive and guarded so it degrades gracefully if
  `nvim` is not yet installed (fallback editor preserved).

## Acceptance Criteria

- [ ] `stow/common/nvim/.config/nvim/` exists with a kickstart-based `init.lua`
      and `lua/custom/plugins/` containing the curated plugin files.
- [ ] `lazy-lock.json` is committed (pinned, reproducible across machines).
- [ ] Catppuccin Macchiato with blue accent (`#8aadf4`) is the active colorscheme.
- [ ] Curated plugin set present: which-key, mini.nvim, treesitter, gitsigns,
      snacks picker, neo-tree, flash, indent-blankline, LSP stack (mason +
      lspconfig + conform).
- [ ] LSP servers configured: intelephense (PHP), lua_ls, bashls, yamlls,
      jsonls, pyright + ruff (Python), ansiblels + ansible-lint (Ansible),
      dockerls (Dockerfile), docker_compose_language_service (Compose),
      hadolint (Dockerfile lint).
- [ ] Dropped items absent: tmux/Herdr nav, multicursor, pj, sortjson,
      bufferline, persistence, ai, dashboard.
- [ ] zsh package sets `EDITOR=nvim` and `VISUAL=nvim` and enables
      `edit-command-line` bound to `Ctrl-x Ctrl-e`, guarded for nvim absence.
- [ ] Package `README.md` documents purpose, usage, per-plugin description,
      keybind cheatsheet, per-platform dependencies, and the `vimtutor`/`:Tutor`
      starting point.
- [ ] Stow dry-run (`--simulate`) instructions are documented; nothing is stowed.
- [ ] Both status blocks (`AGENTS.md` §2 and `CLAUDE.md`) updated in the same
      commit that adds the package.
- [ ] No secrets, real hostnames, or hardcoded machine-specific paths committed.

## Out of Scope

- Server-specific lean profile or runtime profile switching.
- Framework-specific PHP/Symfony/Laravel tooling.
- tmux/Herdr or any pane-navigation bridge.
- Heavy IDE features beyond the curated plugin set (DAP/debugging UI, test
  runners, AI plugins) — may be future PRDs.
- Automatic stowing or automatic dependency installation.
