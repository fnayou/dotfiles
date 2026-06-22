# Review: Neovim Configuration Implementation

**Number:** 0048
**Status:** Complete
**Date:** 2026-06-22
**Plan reviewed:** 0016 — Implement Neovim Configuration Package
**Files reviewed:**

- `stow/common/nvim/.config/nvim/init.lua` (vendored kickstart @ `cd7adee` + edits)
- `stow/common/nvim/.config/nvim/lua/custom/plugins/{colorscheme,filetree,flash,indent-blankline,filetypes}.lua`
- `stow/common/nvim/.config/nvim/{stylua.toml,.gitignore}`
- `stow/common/nvim/{README.md,.stow-local-ignore}`
- `stow/common/zsh/.config/zsh/shared.zsh` (VISUAL → nvim)
- `stow/common/zsh/.config/zsh/keybindings.zsh` (edit-command-line `^x^e`)
- `packages/Brewfile`, `packages/arch/packages.txt`, `Taskfile.yml`

## Summary

Reviewed the implementation of **Plan 0016 — Implement Neovim Configuration
Package** against PRD 0016, Architecture 0016, and the AGENTS.md workflow/rules
(safety, privacy, cross-platform, stow, status-sync, documentation).

The package is correctly structured, themed, and documented. Lua syntax validated
via Neovim `loadfile`; fake-home `stow --simulate` is clean; no secrets or
hardcoded home paths. Nothing was stowed or installed by an agent. All three core
verdicts (Safety, Privacy, Documentation) **PASS**.

The initial review raised one blocking-for-completion item — the build had kept
kickstart's bundled **Telescope** instead of the **snacks picker** named in PRD
0016. **Resolved:** the user chose snacks; `lua/custom/plugins/picker.lua` now
disables Telescope and wires the snacks picker (search maps + LSP-attach
navigation), and the README was updated. PRD/Architecture/Plan (which all
specified snacks) now match the implementation. Re-validated: all Lua syntax OK,
fake-home `stow --simulate` clean, no secrets. **Plan 0016 is marked Complete.**

## Blocking Issues

- **None.** (The original picker mismatch was resolved — snacks picker
  implemented in `picker.lua`, Telescope disabled, README updated. PRD/Arch/Plan
  now match the implementation.)

## Non-Blocking Suggestions

- **Telescope block still present (disabled) in `init.lua`.** It is neutralized
  via `enabled = false` in `picker.lua`, so it is never loaded — correct and
  low-risk, and keeps `init.lua` near-upstream. Kickstart's own comment suggests
  fully removing the block for a clean config; optional future tidy-up.
- **`stylua` remains in the LSP `servers` table** (inherited verbatim from
  kickstart). The `for name, server in pairs(servers)` loop therefore calls
  `vim.lsp.enable('stylua')` on a non-LSP tool. Harmless (no `cmd`, never
  attaches) and it is upstream behavior — leave as-is, or move `stylua` into the
  `ensure_installed` extend list for tidiness.
- **README keymap cheatsheet** lists `grd` for definition; Neovim 0.11+/kickstart
  defaults provide `grn`/`gra`/`grr`/`gri` and `gO`/`K` — verify the exact set on
  first run and adjust the table if needed (cosmetic).
- **Ansible LSP** only attaches when the filetype is `yaml.ansible`; this is
  documented in the README and `filetypes.lua`, but there is no automatic
  detection for playbook directories. Acceptable for now; a future enhancement
  could add path-based detection.
- **`lazy-lock.json`** is absent until the first `:Lazy sync`. Expected per
  Architecture 0016 Decision 4; commit it in the documented follow-up so plugin
  versions become pinned/reproducible.

## Deviations Assessed (from review brief)

1. **Telescope vs snacks** — resolved: snacks implemented, Telescope disabled.
2. **which-key/gitsigns/mini/treesitter/mason/conform bundled in `init.lua`** (not
   separate custom files) — **acceptable.** They ship with kickstart and are
   configured at kickstart's intended edit points; all functionality is present.
   Architecture allowed "inspire, not copy"; this matches the kickstart model.
3. **Status blocks not edited (AGENTS.md §2 / CLAUDE.md)** — **compliant.** Per
   decision 0048 and the status-sync rule, the blocks intentionally point to
   `stow/common/` as the source of truth and carry prose state only ("none stowed
   yet"). Adding `nvim` to `stow/common/` does not change the phase or the
   stowed-vs-not state, so both blocks remain accurate without edit. (The `M
   AGENTS.md` in git status is the pre-existing, unrelated public-repo wording
   edit — out of scope for this review.)
4. **`lazy-lock.json` absent** — expected, see Non-Blocking.

## Safety Verdict

**PASS** — No `stow`, `stow --adopt`, `ln -s`, `rm`, or `mv` against `$HOME` is
executed anywhere. `Taskfile.yml` deps tasks remain print-only (decision 0019).
README and Taskfile mark install/stow steps with `⚠️  MANUAL STEP`. Stow steps
show `--simulate` before install. Nothing outside the repository was modified.

## Privacy Verdict

**PASS** — Grep for keys/tokens/passwords/SSH material/internal hosts and absolute
`/Users|/home` paths returned nothing. Config uses `$HOME`/XDG only. No real
hostnames or secrets.

## Documentation Verdict

**PASS** — README is copy-pasteable, platform-labeled (macOS vs Arch), and marks
dangerous steps. PRD/Architecture/Plan numbers are consistent (all 0016).
Cross-platform deps correctly separated (Brewfile vs pacman; Xcode CLT vs
base-devel). The one doc gap is the picker name, captured as the Blocking item.

## Recommended Next Action

1. Commit the package + manifests + zsh edits + the four 0016 docs
   (PRD/Arch/Plan/this review) in a single `feat(nvim): ...` commit. Keep the
   unrelated `AGENTS.md` wording edit in its own separate commit.
2. Then the user performs the manual steps: install deps, first `:Lazy sync` +
   `:checkhealth`, commit generated `lazy-lock.json`, and stow (dry-run first).

All three verdicts PASS and no blocking issues remain — **Plan 0016 marked
Complete**. Ready to commit.
