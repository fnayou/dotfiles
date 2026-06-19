# Decision: `macos.zsh` and `arch.zsh` as Runtime-Selected Platform Layers

**Number:** 0034
**Date:** 2026-06-19
**Status:** Accepted
**Related:** PRD-0010, Architecture-0010 §4, ADR-0016

## Context

ADR-0016 established the single-package layout: all zsh config lives in `stow/common/zsh/`. Both macOS and Arch platform files (`macos.zsh`, `arch.zsh`) are part of this common package and are therefore symlinked on every machine, regardless of platform.

This creates a question: what happens when an Arch file is symlinked on macOS, or vice versa? And what is the explicit content scope for each platform layer?

## Decision

Both `macos.zsh` and `arch.zsh` are always symlinked by Stow on every machine. OS detection happens at runtime inside `index.zsh`:

```zsh
if [[ "$OSTYPE" == "darwin"* ]]; then
  [[ -r "$HOME/.config/zsh/macos.zsh" ]] && source "$HOME/.config/zsh/macos.zsh"
elif [[ -f /etc/arch-release ]]; then
  [[ -r "$HOME/.config/zsh/arch.zsh" ]] && source "$HOME/.config/zsh/arch.zsh"
fi
```

The unused platform file is symlinked but never sourced. It is harmless.

**`macos.zsh` scope:** Homebrew environment (`command -v brew` guard), macOS-only aliases (`alias o='open'`), macOS-specific PATH additions (`YOUR_MACOS_TOOL_PATH` placeholder).

**`arch.zsh` scope:** AUR helper aliases (guarded with `command -v yay`/`command -v paru`), systemctl aliases (`sc`, `scu`), Arch-specific PATH additions (`YOUR_ARCH_TOOL_PATH` placeholder).

Neither file may contain content from `shared.zsh`'s scope (portable config), `omp.zsh`'s scope (prompt), or `local.zsh`'s scope (private values).

## Consequences

- A single Stow operation (`stow common/zsh`) works on both macOS and Arch.
- No platform-specific Stow packages are needed for zsh config.
- Adding a new macOS-only or Arch-only tool is a one-line change in the correct platform file.
- The unused platform symlink (e.g., `arch.zsh` on macOS) has no runtime cost and no side effect.
- OS detection uses `$OSTYPE` (zsh built-in, always reliable) with `/etc/arch-release` as the Arch guard (authoritative on EndeavourOS too).
