# 0053 — Debian added as a third supported platform

- Status: Accepted
- Date: 2026-06-29

## Context

Until now the repository supported exactly two platforms, treated separately
per the cross-platform rule: **macOS** (primary) and **EndeavourOS / Arch
Linux**. All servers the maintainer runs are **Debian** (stable, currently
trixie / Debian 13), and Neovim is used on them directly.

A concrete failure surfaced this gap. `nvim-treesitter` is pinned to its
`main` branch (`stow/common/nvim/.config/nvim/init.lua`), which builds parsers
by shelling out to a `tree-sitter` CLI binary. A Debian server had no
`tree-sitter` CLI, so parser builds failed with:

```
ENOENT ... (cmd): 'tree-sitter'
```

The repository's documented remedy was node-specific
(`npm install -g tree-sitter-cli`). On that server there was no `node` at all,
so the documented path did not apply. The fix used a prebuilt static
`tree-sitter` binary instead.

This exposed two things:

1. Debian is a real, recurring target, not an incidental "unknown" OS.
2. The tree-sitter CLI install advice assumed node was present.

## Decision

1. **Debian becomes a first-class supported platform**, alongside macOS and
   Arch. The cross-platform rule, agent contract (`AGENTS.md`), status blocks,
   dependency scripts, package manifests, task runner, and human setup guides
   all treat Debian explicitly and separately — never folded into Arch or
   assumed to share an approach.

2. **Package manager on Debian is `apt`.** Debian uses `sudo apt install`.
   Arch's `pacman`/`yay` and macOS's `brew` are never mixed into Debian docs,
   and vice versa.

3. **tree-sitter CLI on Debian is installed from the prebuilt GitHub release
   binary**, not via npm:

   ```bash
   curl -fsSL https://github.com/tree-sitter/tree-sitter/releases/latest/download/tree-sitter-linux-x64.gz \
     | gunzip > ~/.local/bin/tree-sitter && chmod +x ~/.local/bin/tree-sitter
   ```

   Rationale: it is node-free, version-pinnable, and avoids ABI drift between
   a node wrapper and Neovim's runtime. `apt`'s `tree-sitter-cli` exists but
   trails upstream (0.22.x on trixie) and needs sudo.

4. **node is still installed on Debian hosts** (`nodejs`, `npm`) so that
   Mason-installed LSP servers work, even though tree-sitter itself no longer
   depends on it.

## Consequences

- New file `packages/debian/packages.txt` lists apt packages, mirroring
  `packages/arch/packages.txt`.
- New `deps:debian` task prints (never runs) the Debian install commands.
- `scripts/check-nvim-deps.sh` and `scripts/check-zsh-deps.sh` detect Debian
  (`/etc/debian_version`) and print apt-flavoured hints.
- An empty `stow/debian/` package directory exists for parity with
  `stow/macos/` and `stow/arch/`; no Debian-only packages exist yet.
- Status blocks in `AGENTS.md` and `CLAUDE.md` now name macOS, Arch, and
  Debian, and report `macos/`, `arch/`, `debian/` as empty.
- Debian quirks are documented where relevant: `bat` ships as `batcat`,
  `fd` as `fdfind` (package `fd-find`); `go-task` and `oh-my-posh` are not in
  the Debian archive and are installed out-of-band.
- **Neovim version risk:** nvim-treesitter's `main` branch needs Neovim
  >= 0.11. Debian stable's apt `neovim` may be older. The package list, task,
  and guides document a node-free prebuilt-tarball fallback into `~/.local`
  for when apt's neovim is too old. (`eza` is likewise apt-available only on
  trixie/13+, not bookworm/12 — hence the trixie/13+ scope.)
- Homebrew/linuxbrew was considered for Debian (one shared Brewfile with
  macOS, always-latest versions) but rejected to keep servers apt-native and
  minimal — no `/home/linuxbrew` layer. apt is the Debian package manager;
  curl-prebuilt covers the two tools apt can't serve well (tree-sitter CLI
  always, neovim when too old).

## Related

- `.claude/rules/cross-platform.md` — platform separation contract.
- `0048-status-blocks-kept-in-sync-with-repo-state.md` — status-block sync.
