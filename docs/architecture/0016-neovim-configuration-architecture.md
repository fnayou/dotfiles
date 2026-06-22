# Architecture: Neovim Configuration Package

**Number:** 0016
**Status:** Approved
**Date:** 2026-06-22
**PRD:** 0016 (`docs/prd/0016-neovim-configuration.md`)

## Context

PRD 0016 (Approved) adds a managed Neovim configuration as a new common Stow
package, replacing the user's `vim` usage (local quick edits + server
maintenance/debug) with a full, learnable kickstart-based setup themed Catppuccin
Macchiato blue. This document defines structure, file layout, and the decisions
the Planner will turn into ordered tasks. Existing relevant decisions:
0024 (no-folding zsh package), 0004 (zsh layout), 0007 (split brewfiles),
0019 (non-mutating deps tasks), 0048 (status blocks in sync).

Notable existing-state finding: `stow/common/zsh/.config/zsh/shared.zsh` already
sets `EDITOR="${EDITOR:-nvim}"` and `VISUAL="${VISUAL:-zed}"`. The zsh change is
therefore small: flip `VISUAL` default to `nvim`, and add the `edit-command-line`
widget to `keybindings.zsh`.

## Proposed Structure

```
stow/common/nvim/
├── README.md                     # usage, plugins, keybinds, deps, vimtutor
├── .stow-local-ignore            # ignore README/.git/.gitignore/bak/orig/.DS_Store
└── .config/
    └── nvim/
        ├── init.lua              # stock kickstart.nvim, kept near-upstream
        ├── lazy-lock.json        # committed AFTER first :Lazy sync (see Decision 4)
        ├── stylua.toml           # lua formatter config (from kickstart)
        ├── .gitignore            # ignore nvim runtime dirs if any land here
        └── lua/
            └── custom/
                └── plugins/
                    ├── colorscheme.lua          # catppuccin macchiato, blue #8aadf4
                    ├── which-key.lua
                    ├── mini.lua                 # statusline, surround, comment, textobjects
                    ├── treesitter.lua           # (or rely on kickstart's; override langs)
                    ├── gitsigns.lua
                    ├── picker.lua               # snacks picker
                    ├── filetree.lua             # neo-tree
                    ├── flash.lua
                    ├── indent-blankline.lua
                    ├── lsp.lua                  # mason + mason-lspconfig + lspconfig
                    └── conform.lua              # formatters, lsp_format = fallback
```

Dependency manifests (outside the package, repo-level):

```
packages/Brewfile              # add: neovim ripgrep fd node python pipx
packages/arch/packages.txt     # add commented pacman/yay lines (matches file style)
Taskfile.yml                   # deps:brew / deps:arch print-only text updated
```

zsh package edits (existing files, additive):

```
stow/common/zsh/.config/zsh/shared.zsh       # VISUAL default zed -> nvim
stow/common/zsh/.config/zsh/keybindings.zsh  # edit-command-line widget + Ctrl-x Ctrl-e
```

Status blocks (same commit as package add): `AGENTS.md` §2, `CLAUDE.md`.

## Design Decisions

### Decision 1: Common, no-folding, XDG-native package

The config is identical on macOS and Arch and targets `~/.config/nvim`.
Place under `stow/common/nvim` mirroring the XDG layout, with a
`.stow-local-ignore` like the other packages (per 0024 no-folding precedent).

Option A: `common/`, XDG `.config/nvim`, no-folding.
  Pro: matches every existing package; one source of truth; portable.
  Con: none material — nvim config is genuinely platform-agnostic.

Option B: split per-platform.
  Pro: would isolate OS differences.
  Con: there are none in the config itself (only deps differ); pure overhead.

**Decision: Option A.** Differences live only in dependency manifests, not config.

### Decision 2: Stock kickstart.nvim base + custom plugins

Keep upstream `init.lua` near-vanilla; add features as files under
`lua/custom/plugins/` (lazy.nvim auto-imports the directory).

Option A: stock kickstart + `lua/custom/plugins/`.
  Pro: heavily commented upstream = best for a newcomer; easy upstream diffing;
       incremental one-file-per-feature growth.
  Con: carries a little kickstart scaffolding the user must read.

Option B: hand-rolled minimal lazy.nvim.
  Pro: leaner, fully bespoke.
  Con: more boilerplate to author + maintain; worse learning scaffold.

**Decision: Option A** — matches PRD learnability goal.

### Decision 3: Theme as a single override file sharing the global blue

`colorscheme.lua` installs `catppuccin/nvim`, flavour `macchiato`, accent blue
`#8aadf4` (the same hex used by alacritty/zsh/omp/bat/eza), `priority = 1000`,
loaded at startup. No other theme plugins.

**Decision:** one colorscheme file; reuse the existing macchiato-blue hex so the
whole terminal identity stays consistent.

### Decision 4: lazy-lock.json committed, stowed, write-through

`lazy-lock.json` pins plugin commits for reproducibility across machines. It
lives in `~/.config/nvim/` and lazy.nvim rewrites it on `:Lazy sync`. Because the
package is stowed (symlinked), nvim writes through the symlink back into the repo
— desired (lock changes become tracked diffs).

Sequencing: the file does not exist until plugins are first installed, and agents
do not run nvim. Therefore the package is authored without it; the user runs
`nvim`/`:Lazy sync` once (manual step), which generates `lazy-lock.json`, then it
is committed in a follow-up. Until then the package is fully valid without it.

**Decision:** commit `lazy-lock.json` after first user sync; do **not** stow-ignore
it (it must be symlinked so writes land in the repo).

### Decision 5: LSP via Mason; servers are runtime-managed, not OS packages

`lsp.lua` wires `mason` + `mason-lspconfig` + `lspconfig`; `mason-tool-installer`
(or `ensure_installed`) declares the 12 servers. Mason downloads servers into
nvim's data dir — they are **not** added to Brewfile/pacman. node + python (OS
deps) make node-/python-based servers runnable.

Server file-scoping to avoid overlap:
- `docker_compose_language_service` → `docker-compose*.yml`, `compose*.yml`.
- `yamlls` → all other YAML.
- `ansiblels` → ansible-flavored YAML (playbooks/roles); avoid double-attaching
  with yamlls where possible.
- `hadolint` → Dockerfile diagnostics (standalone binary, no runtime).

Formatting via `conform.nvim` with `lsp_format = 'fallback'` (conform formatters
first, LSP as fallback) — e.g. `ruff` for Python, `stylua` for Lua.

**Decision:** servers Mason-managed and Mason-installed; only runtimes
(node/python) and CLI tools (ripgrep/fd) + compiler are OS-level.

### Decision 6: zsh integration is additive and guarded

- `shared.zsh`: change `VISUAL="${VISUAL:-zed}"` → `VISUAL="${VISUAL:-nvim}"`.
  `EDITOR` already defaults to `nvim`. The `:-` form preserves any user override.
- `keybindings.zsh`: add
  ```zsh
  autoload -Uz edit-command-line
  zle -N edit-command-line
  bindkey '^x^e' edit-command-line
  ```
  This is a zsh builtin widget; it needs no external tool. If `nvim` is absent,
  `$EDITOR`/`$VISUAL` `:-` fallbacks still resolve and the widget opens whatever
  editor is set — graceful degradation.

**Decision:** keep editor env in `shared.zsh`, keybinding in `keybindings.zsh`;
both additive, no new files, consistent with the zsh package's structure.

### Decision 7: Dependency manifests follow each file's existing style

- `packages/Brewfile`: real `brew "..."` lines — add `neovim`, `ripgrep`, `fd`,
  `node`, `python`, `pipx` under a new `# --- Neovim ---` section.
- `packages/arch/packages.txt`: that file uses **commented** example commands,
  not raw package lines — add commented `# sudo pacman -S neovim ripgrep fd
  nodejs npm python python-pipx base-devel` under a Neovim section, matching style.
- C compiler is **not** a package line: documented as `xcode-select --install`
  (macOS) / `base-devel` (Arch, already in the pacman line).
- `Taskfile.yml` `deps:brew` / `deps:arch` remain print-only (0019); update their
  echoed text to mention the Neovim step. No task installs anything.

**Decision:** match per-file conventions; never make a deps task mutate the system.

### Decision 8: .stow-local-ignore mirrors existing packages

Ignore `README.md`, `.git`, `.gitignore`, `.stow-local-ignore`, `*.bak`,
`*.orig`, and add `.DS_Store` (macOS noise). Do **not** ignore `lazy-lock.json`
(must symlink) or `lua/` (the config).

**Decision:** reuse the bat/zsh ignore template plus a `.DS_Store` rule.

## Risks

- **Treesitter needs a C compiler.** No compiler → parser builds fail. Mitigation:
  document Xcode CLT / `base-devel` as required; treesitter degrades to no
  highlighting for unbuilt langs rather than breaking nvim.
- **node-based servers need node.** 9 of 12 servers are node-based; without node
  they silently won't start. Mitigation: node is in the manifests + README; choice
  A accepted this cost.
- **First-run network.** First `nvim` launch clones plugins + Mason downloads
  servers — needs network. Mitigation: documented as a manual first-run step;
  `lazy-lock.json` pins versions afterward.
- **lazy-lock write-through.** Because stowed, `:Lazy sync` edits the repo file.
  Intended, but means plugin updates show as repo diffs to commit deliberately.
- **Truecolor.** Macchiato needs a truecolor terminal; alacritty already provides
  it. On a server without truecolor the theme degrades (acceptable).
- **Stow conflict.** If `~/.config/nvim` already exists, stow will conflict.
  Mitigation: `--simulate` dry-run first (safety rules); user resolves manually,
  never `--adopt`.
- **ansiblels vs yamlls overlap.** Both may attach to YAML. Mitigation: scope by
  filename/filetype as in Decision 5.

## Extensibility

- New language: add one server to `lsp.lua` `ensure_installed` (+ runtime if
  needed) — no structural change.
- New feature: drop a new file in `lua/custom/plugins/` (auto-imported).
- Deferred plugins from PRD (multicursor, persistence, dashboard, etc.) slot in
  the same way later without redesign.
- A future server-lean profile (out of scope here) could branch on an env var in
  `init.lua` without moving files.

## Open Questions

- None blocking. (lazy-lock sequencing resolved in Decision 4.)

## Recommended Next Step

Planner: convert this into an ordered, safe plan under `docs/plans/0016-…`,
splitting work into reviewable tasks (package skeleton → colorscheme → core
plugins → LSP/conform → zsh edits → deps manifests → README/docs → status blocks
→ dry-run validation), each with validation commands and a rollback note. Use the
`add-dotfile-package` skill where it fits.
