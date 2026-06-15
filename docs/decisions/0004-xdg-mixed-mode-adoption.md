# Decision: XDG Base Directory Mixed-Mode Adoption

**Number:** 0004
**Date:** 2026-06-15
**Status:** Accepted

## Context

The XDG Base Directory specification defines standard locations for config (`$XDG_CONFIG_HOME`), data (`$XDG_DATA_HOME`), and cache (`$XDG_CACHE_HOME`) files. Two approaches were evaluated:

- **Strict XDG** — all configuration under `$XDG_CONFIG_HOME`. Clean home directory, but many macOS tools do not respect XDG and require workarounds per tool.
- **Mixed mode** — use XDG where the tool supports it; fall back to `$HOME/.*` where it does not.

The repository targets both macOS (primary) and Arch Linux. macOS tools frequently ignore XDG. Arch tools generally respect it more consistently.

## Decision

Adopt **XDG mixed-mode**: use XDG base directories where the tool supports them; fall back to `$HOME/.*` for tools that do not.

Implementation:
- Define `XDG_CONFIG_HOME`, `XDG_DATA_HOME`, `XDG_CACHE_HOME` in `.zshenv` (the `common/zsh` package).
- For each new package, verify whether the tool respects XDG before deciding the config file path.
- Document the XDG status of each tool when its package is created.

## Consequences

- Home directory is cleaner for tools that respect XDG (Neovim, many CLI tools).
- Some tools still write to `$HOME` directly — accepted on a per-tool basis.
- Each new package requires a one-time check of XDG support for that tool.
- Trade-off accepted: imperfect XDG coverage in exchange for broad tool compatibility on macOS.
