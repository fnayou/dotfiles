# Decision: `fzf --zsh` as the fzf Integration Method

**Number:** 0040
**Date:** 2026-06-19
**Status:** Accepted
**Related:** PRD-0010, Architecture-0010 §7

## Context

fzf provides multiple integration methods depending on version. Older approaches required the user to manually source shell scripts from fzf's installation directory (`~/.fzf.zsh`, `/usr/share/fzf/key-bindings.zsh`, etc.) and to manually configure `FPATH` and `bindkey` calls. These approaches are version-specific, install-path-specific, and require the user to know their exact fzf installation method.

Since fzf 0.48 (2024), fzf provides `fzf --zsh`, which outputs a self-contained shell script enabling key bindings (`Ctrl-R` for history search, `Ctrl-T` for file search, `Alt-C` for directory navigation) and completion in a single call.

## Decision

The committed `shared.zsh.example` template uses `fzf --zsh` as the integration method:

```zsh
command -v fzf >/dev/null 2>&1 && eval "$(fzf --zsh)"
```

Reasons:

1. **Single call.** No separate `FPATH`, `bindkey`, or script-sourcing steps.
2. **Install-path agnostic.** Works regardless of whether fzf was installed via Homebrew, pacman, AUR, `~/.fzf/`, or direct binary.
3. **Forward-compatible.** The upstream fzf project maintains `fzf --zsh`; it will stay correct as fzf evolves.

Minimum required fzf version: 0.48. Users on older versions must use the manual integration path (sourcing `~/.fzf.zsh` or the system scripts); this is documented in `docs/guides/zsh-setup.md` in the troubleshooting section.

`FZF_DEFAULT_OPTS` and `FZF_DEFAULT_COMMAND` are not set in the committed template — they are machine-specific preferences and belong in `local.zsh`.

## Consequences

- Machines with fzf >= 0.48 get key bindings and completion with no user action beyond copying the template.
- Machines with fzf < 0.48 or no fzf are unaffected (the `command -v fzf` guard is a no-op).
- Users who want custom fzf options add `FZF_DEFAULT_OPTS` in `local.zsh` — no committed template change needed.
- A version check (`fzf --version`) is recommended before relying on `fzf --zsh`; the setup guide documents this.
