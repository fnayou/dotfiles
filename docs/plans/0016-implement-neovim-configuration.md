# Plan: Implement Neovim Configuration Package

**Number:** 0016
**Status:** Complete
**Date:** 2026-06-22
**PRD:** 0016
**Architecture:** 0016

## Objective

Create the `stow/common/nvim` package (kickstart-based, Catppuccin Macchiato blue,
curated plugins + 12-server LSP stack), wire the related zsh editor change, add
dependency manifests, document everything — all without stowing, installing, or
touching `$HOME`.

## Assumptions

- Branch `feat/neovim-config` is checked out.
- PRD 0016 and Architecture 0016 are Approved.
- Neovim is **not yet installed**; the user will install deps and run the first
  `:Lazy sync` manually (agents cannot run nvim).
- `shared.zsh` already defaults `EDITOR=nvim` and `VISUAL=zed` (only VISUAL flips).
- No `~/.config/nvim` ownership assumption — real-home stow conflict is possible
  and handled by dry-run + fake-home validation (decision 0017).

## Ordered Tasks

> Tag legend: **[agent]** = Builder does it. **[manual]** = user-only step
> (install / run nvim / stow), shown but never executed by an agent.

1. **[agent] Package skeleton.** Create `stow/common/nvim/.config/nvim/lua/custom/plugins/`
   directory tree. Add `stow/common/nvim/.stow-local-ignore` (bat/zsh template +
   `^.*\.DS_Store$`; do **not** ignore `lazy-lock.json`). Add
   `stow/common/nvim/.config/nvim/.gitignore` for nvim runtime artifacts
   (e.g. `lazy-lock.json` stays tracked; ignore stray `*.bak`, swap, undo dirs).
2. **[agent] kickstart init.lua.** Add stock `kickstart.nvim` `init.lua` kept
   near-upstream, with `{ import = 'custom.plugins' }` enabled and leader=space.
   Add `stylua.toml` (kickstart default).
3. **[agent] colorscheme.lua.** `catppuccin/nvim`, `flavour = "macchiato"`,
   blue accent `#8aadf4`, `priority = 1000`, set at startup. No other theme.
4. **[agent] which-key.lua.** which-key on `VeryLazy`; register `g`/leader groups.
5. **[agent] mini.lua.** mini.nvim modules: statusline, surround, comment,
   ai/textobjects. Pure-lua, no compiler.
6. **[agent] treesitter.lua.** Override kickstart treesitter `ensure_installed`
   to the user's langs (lua, bash, yaml, json, php, python, dockerfile, etc.);
   highlight + indent on. Note: needs C compiler (risk documented).
7. **[agent] gitsigns.lua.** gitsigns on file read; signs + blame keymaps.
8. **[agent] picker.lua.** snacks.nvim picker (files/grep/buffers) with keymaps.
9. **[agent] filetree.lua.** neo-tree on `cmd`/`keys` (lazy), toggle keymap.
10. **[agent] flash.lua.** flash jump motions on `VeryLazy`/keys.
11. **[agent] indent-blankline.lua.** indent guides on file read.
12. **[agent] lsp.lua.** `mason` + `mason-lspconfig` + `lspconfig` +
    `mason-tool-installer`. `ensure_installed` = the 12 servers (intelephense,
    lua_ls, bashls, yamlls, jsonls, pyright, ruff, ansiblels, ansible-lint,
    dockerls, docker_compose_language_service, hadolint). Filename scoping:
    compose server → `docker-compose*.yml`/`compose*.yml`, yamlls → other YAML,
    ansiblels → ansible YAML. LSP keymaps via `LspAttach` autocmd.
13. **[agent] conform.lua.** conform.nvim, `lsp_format = 'fallback'`; map
    formatters (ruff → python, stylua → lua) and a format keymap.
14. **[agent] zsh: VISUAL default.** In `stow/common/zsh/.config/zsh/shared.zsh`
    change `VISUAL="${VISUAL:-zed}"` → `VISUAL="${VISUAL:-nvim}"`.
15. **[agent] zsh: edit-command-line widget.** In
    `stow/common/zsh/.config/zsh/keybindings.zsh` add autoload + `zle -N` +
    `bindkey '^x^e' edit-command-line` (guarded/builtin).
16. **[agent] Brewfile.** Add `# --- Neovim ---` section to `packages/Brewfile`:
    `neovim`, `ripgrep`, `fd`, `node`, `python`, `pipx`.
17. **[agent] arch packages.txt.** Add commented Neovim section to
    `packages/arch/packages.txt` matching its commented style:
    `# sudo pacman -S neovim ripgrep fd nodejs npm python python-pipx base-devel`.
18. **[agent] Taskfile deps text.** Update `deps:brew` / `deps:arch` echoed text
    to mention the Neovim install step. Tasks stay **print-only** (0019).
19. **[agent] README.md.** `stow/common/nvim/README.md`: purpose, usage, per-plugin
    description, keybind cheatsheet, per-platform deps, `vimtutor`/`:Tutor` start,
    C-compiler note, and `stow --simulate` dry-run + fake-home instructions.
20. **[agent] Status blocks.** Update `AGENTS.md` §2 and `CLAUDE.md` status blocks
    to record the new (not-yet-stowed) `nvim` package — **same commit** as the
    package add (decision 0048).
21. **[manual] Install deps.** User runs `task deps:brew` / `deps:arch` to read
    commands, then installs (incl. `xcode-select --install` / `base-devel`).
22. **[manual] First nvim run.** User launches `nvim`, lets lazy.nvim install
    plugins + Mason install servers, runs `:Lazy sync` and `:checkhealth`.
23. **[manual] Commit lazy-lock.json.** After first sync generates
    `lazy-lock.json`, user commits it (write-through via stow once stowed; before
    stow, copy the generated file into the package — documented in README).
24. **[manual] Stow.** User runs dry-run then stow (see Validation / Safety).

## Files Affected

- `stow/common/nvim/.stow-local-ignore` — created
- `stow/common/nvim/.config/nvim/.gitignore` — created
- `stow/common/nvim/.config/nvim/init.lua` — created
- `stow/common/nvim/.config/nvim/stylua.toml` — created
- `stow/common/nvim/.config/nvim/lua/custom/plugins/colorscheme.lua` — created
- `stow/common/nvim/.config/nvim/lua/custom/plugins/which-key.lua` — created
- `stow/common/nvim/.config/nvim/lua/custom/plugins/mini.lua` — created
- `stow/common/nvim/.config/nvim/lua/custom/plugins/treesitter.lua` — created
- `stow/common/nvim/.config/nvim/lua/custom/plugins/gitsigns.lua` — created
- `stow/common/nvim/.config/nvim/lua/custom/plugins/picker.lua` — created
- `stow/common/nvim/.config/nvim/lua/custom/plugins/filetree.lua` — created
- `stow/common/nvim/.config/nvim/lua/custom/plugins/flash.lua` — created
- `stow/common/nvim/.config/nvim/lua/custom/plugins/indent-blankline.lua` — created
- `stow/common/nvim/.config/nvim/lua/custom/plugins/lsp.lua` — created
- `stow/common/nvim/.config/nvim/lua/custom/plugins/conform.lua` — created
- `stow/common/nvim/README.md` — created
- `stow/common/zsh/.config/zsh/shared.zsh` — modified (VISUAL default)
- `stow/common/zsh/.config/zsh/keybindings.zsh` — modified (widget)
- `packages/Brewfile` — modified (Neovim section)
- `packages/arch/packages.txt` — modified (commented Neovim section)
- `Taskfile.yml` — modified (deps text only)
- `AGENTS.md` — modified (status block §2)
- `CLAUDE.md` — modified (status block)
- `stow/common/nvim/.config/nvim/lazy-lock.json` — created by user after first sync

No files deleted.

## Safety Checks

- Before starting: `git status` shows only the expected branch and the unrelated
  pre-existing `AGENTS.md` wording edit (do not bundle that into nvim commits).
- No task runs `stow`, `stow --adopt`, `ln -s`, `rm`, or `mv` against `$HOME`.
- No task installs packages; deps tasks remain print-only.
- `git diff --staged` audited for secrets before any commit (no tokens, real
  hostnames, or hardcoded user paths — use `$HOME`/XDG only).
- Status blocks updated in the same commit as the package add.

## Validation Commands

```bash
# Structure (agent / read-only)
git status
find stow/common/nvim -type f | sort
cat stow/common/nvim/.stow-local-ignore

# Lua sanity (optional, if luacheck/stylua present — read-only)
stylua --check stow/common/nvim/.config/nvim || true

# Stow layout via fake home (decision 0017) — non-mutating, agent-safe
TEST_HOME="$(mktemp -d)"
stow --dir=stow/common --target="$TEST_HOME" --simulate nvim
rm -rf "$TEST_HOME"

# Secret audit before commit
git diff --staged
```

⚠️  MANUAL STEP — review output before running (real-home dry-run; user only)
```bash
stow --dir=stow/common --target="$HOME" --simulate nvim
```

⚠️  MANUAL STEP — install only after approving dry-run (user only)
```bash
stow --dir=stow/common --target="$HOME" nvim
```

⚠️  MANUAL STEP — first nvim run / health check (user only)
```bash
nvim --headless "+Lazy! sync" +qa
nvim "+checkhealth" +qa   # review interactively
```

## Rollback Strategy

```bash
# Undo a single file before commit
git checkout -- <file>

# Discard all uncommitted package work
git restore --staged stow/common/nvim packages Taskfile.yml AGENTS.md CLAUDE.md
git checkout -- stow/common/zsh

# Undo the last commit (before push)
git reset HEAD~1
```

No symlinks are created by this plan, so there is nothing to unstow on rollback.
If the user already stowed, they unstow with
`stow --dir=stow/common --target="$HOME" -D nvim` (manual).

## Completion Criteria

(Maps to PRD 0016 acceptance criteria.)

- [ ] `stow/common/nvim/.config/nvim/` exists with kickstart `init.lua` +
      `lua/custom/plugins/` containing all curated plugin files.
- [ ] colorscheme = Catppuccin Macchiato, blue accent `#8aadf4`.
- [ ] Curated plugin set present (which-key, mini, treesitter, gitsigns, snacks
      picker, neo-tree, flash, indent-blankline, mason/lspconfig, conform).
- [ ] `lsp.lua` declares the 12 servers with compose/yaml/ansible scoping.
- [ ] Dropped items absent (no tmux/herdr, multicursor, pj, sortjson, bufferline,
      persistence, ai, dashboard).
- [ ] `shared.zsh` VISUAL defaults to nvim; `keybindings.zsh` binds
      `Ctrl-x Ctrl-e` to `edit-command-line`.
- [ ] `packages/Brewfile` + `packages/arch/packages.txt` carry Neovim deps;
      Taskfile deps text mentions Neovim; tasks remain non-mutating.
- [ ] `stow/common/nvim/README.md` covers purpose/usage/plugins/keybinds/deps/
      vimtutor/dry-run.
- [ ] Fake-home `stow --simulate` passes clean.
- [ ] Status blocks (`AGENTS.md` §2 + `CLAUDE.md`) updated in the package-add commit.
- [ ] `git diff --staged` shows no secrets / real hostnames / hardcoded paths.
- [ ] (manual, post-merge) `lazy-lock.json` committed after first `:Lazy sync`.
