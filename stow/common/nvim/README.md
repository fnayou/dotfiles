# nvim — Neovim configuration (common)

A [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim)-based Neovim
configuration, themed **Catppuccin Macchiato** (blue accent `#8aadf4`) to match
the rest of the terminal (alacritty / zsh / oh-my-posh / bat / eza).

It is meant to replace plain `vim` for local quick edits and server
maintenance/debug, while being a full, learnable setup. Plugins are managed by
[lazy.nvim](https://github.com/folke/lazy.nvim); the stock kickstart `init.lua`
is kept close to upstream and feature files live under `lua/custom/plugins/`.

> Target: `~/.config/nvim` (XDG). Identical on macOS and Arch — only the system
> dependencies differ per platform.

## Layout

```
.config/nvim/
├── init.lua                 # stock kickstart (LSP servers + treesitter langs edited)
├── stylua.toml              # Lua formatter config
├── lazy-lock.json           # pinned plugin versions (committed after first sync)
└── lua/custom/plugins/
    ├── colorscheme.lua      # Catppuccin Macchiato (disables Tokyonight)
    ├── picker.lua           # snacks picker (disables Telescope)
    ├── filetree.lua         # neo-tree file explorer
    ├── flash.lua            # label jump motions
    ├── indent-blankline.lua # indent guides
    └── filetypes.lua        # compose/ansible filetype scoping (no plugin)
```

## Dependencies

LSP servers are installed **inside** Neovim by [Mason](https://github.com/mason-org/mason.nvim)
(`:Mason`), but they need runtimes and a few CLI tools on the system first.

```bash
# macOS — installed via the repo Brewfile
brew bundle --file=packages/Brewfile     # neovim ripgrep fd node python pipx
xcode-select --install                    # C compiler for treesitter parsers
npm install -g tree-sitter-cli           # tree-sitter CLI (see note below)
```

```bash
# Arch / EndeavourOS
sudo pacman -S neovim ripgrep fd nodejs npm python python-pipx base-devel
sudo pacman -S tree-sitter-cli           # (or: npm install -g tree-sitter-cli)
```

- **ripgrep / fd** — snacks picker live-grep and file finding.
- **node** — powers most LSP servers (intelephense, bashls, yamlls, jsonls,
  pyright, ansiblels, dockerls, docker_compose_language_service).
- **python + pipx** — ruff.
- **C compiler** — treesitter compiles parsers on install.
- **tree-sitter CLI** — nvim-treesitter's `main` branch builds parsers by
  shelling out to the `tree-sitter` binary. On macOS, Homebrew's `tree-sitter`
  formula ships the **library only** (no CLI), so install the CLI via
  `npm install -g tree-sitter-cli`. Without it parser builds fail with
  `ENOENT ... (cmd): 'tree-sitter'`.

Print the commands any time (nothing is installed automatically):

```bash
task deps:brew    # macOS
task deps:arch    # Arch
```

## Install (Stow)

⚠️  MANUAL STEP — review the dry-run before stowing.

```bash
# 1. Dry run — verify what would be linked
stow --dir=stow/common --target="$HOME" --simulate nvim
```

⚠️  MANUAL STEP — only after reviewing the dry-run output.

```bash
# 2. Link the package
stow --dir=stow/common --target="$HOME" nvim
```

If `~/.config/nvim` already exists, Stow reports a conflict — resolve it manually
(back up / remove your old config). Never use `--adopt`.

## First run

```bash
# Launch once: lazy.nvim installs plugins, Mason installs LSP servers.
nvim --headless "+Lazy! sync" +qa
nvim "+checkhealth" +qa   # review interactively
```

After the first sync, commit the generated `lazy-lock.json` (pinned versions).
Because the config is stowed, `:Lazy sync` writes through the symlink straight
into this repo.

## Learning Neovim

New to Neovim? Start with the built-in tutorial (~30 min):

```bash
vimtutor      # or, inside Neovim:  :Tutor
```

## Plugins

| Plugin | Purpose |
|---|---|
| **catppuccin/nvim** | Macchiato colorscheme, blue accent — matches the terminal. |
| **lazy.nvim** | Plugin manager (`:Lazy`). |
| **which-key.nvim** | Popup showing what each key/prefix does — your map while learning. |
| **snacks.nvim** | Fuzzy picker: files, live-grep, buffers, diagnostics, LSP nav (replaces Telescope). |
| **nvim-treesitter** | Syntax highlighting + indentation; parsers auto-install per language. |
| **mason + lspconfig** | Install and wire LSP servers (see below). |
| **conform.nvim** | Formatting (`<leader>f`); `lsp_format = 'fallback'`. |
| **gitsigns.nvim** | Git signs in the gutter + hunk keymaps. |
| **mini.nvim** | Statusline, surround (`gs` prefix), `ai` textobjects, and more. |
| **neo-tree.nvim** | File explorer sidebar (`\`). |
| **flash.nvim** | Jump anywhere with `s` + 2 chars + label. |
| **indent-blankline.nvim** | Vertical indent guides. |

### LSP servers (Mason-managed)

`intelephense` (PHP), `lua_ls`, `bashls`, `yamlls`, `jsonls`, `pyright` + `ruff`
(Python), `ansiblels` (Ansible), `dockerls` + `docker_compose_language_service`
(Docker), plus the `hadolint` Dockerfile linter.

- **YAML scoping:** `compose.yml` / `docker-compose*.yml` get the
  `yaml.docker-compose` filetype (compose server); all other YAML uses `yamlls`.
- **Ansible:** not auto-detected. To attach `ansiblels`, set the filetype, e.g.
  `:set filetype=yaml.ansible`, add a modeline, or configure detection for your
  playbook directories.

## Keybindings (cheatsheet)

Leader = `<Space>`. which-key shows the rest live.

| Key | Action |
|---|---|
| `<leader>sf` | Search files (snacks picker) |
| `<leader>sg` | Search by grep (live grep) |
| `<leader>sh` | Search help |
| `<leader><leader>` | Find buffers |
| `\` | Toggle neo-tree |
| `s` / `S` | Flash jump / Flash treesitter |
| `gsa` / `gsd` / `gsr` | Surround add / delete / replace (mini.surround) |
| `<leader>f` | Format buffer (conform) |
| `grn` / `gra` / `grd` / `grr` | LSP rename / code action / definition / references |
| `<leader>q` | Diagnostic quickfix list |
| `Ctrl-x Ctrl-e` | (zsh) edit the current shell command in Neovim |

See `:help` and `<leader>sk` (search keymaps) for the full set.
