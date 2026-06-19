# Decision: `shared.zsh` Content Scope

**Number:** 0033
**Date:** 2026-06-19
**Status:** Accepted
**Related:** PRD-0010, Architecture-0010 §3, ADR-0016, ADR-0029

## Context

The managed zsh layer places all sourced files in `stow/common/zsh/`. `shared.zsh` is the portable layer — sourced on every platform, every machine. Without an explicit content boundary, future contributors may add platform-specific configuration, tool installation commands, or private values to `shared.zsh`, breaking portability and violating privacy requirements.

PRD-0010 and Architecture-0010 §3 define what belongs in the portable layer and what is forbidden. This ADR records that boundary as a standing decision.

## Decision

`shared.zsh` (and its `.example` template) is restricted to content that is:

- Portable across macOS and Arch without modification.
- Free of platform-specific tool references.
- Free of network access or tool installation.
- Free of private values, tokens, hostnames, or credentials.

Permitted content: XDG base directory exports, `$EDITOR`/`$PAGER` exports, `$HISTFILE`/`$HISTSIZE`/`$SAVEHIST` and history options, `setopt AUTO_CD`, Zinit source guard, compinit fallback guard, `command -v` guards for fzf/zoxide/eza, `alias grep='grep --color=auto'`.

Forbidden content (must not appear):

| Content | Correct location |
|---|---|
| `brew`, `/opt/homebrew`, `brew install` | `macos.zsh` |
| `pacman`, `yay`, `paru`, `systemctl` | `arch.zsh` |
| `pbcopy`, `pbpaste`, `open` | `macos.zsh` |
| Oh My Posh `eval` block | `omp.zsh` |
| Zinit plugin declarations (`zinit light`, `zinit snippet`) | deferred to a future PRD |
| Private tokens, API keys, hostnames | `local.zsh` |
| `git clone`, `curl … | sh`, package manager install | forbidden everywhere at shell startup |
| Hardcoded absolute paths with OS differences | `macos.zsh` or `arch.zsh` |

## Consequences

- `shared.zsh` remains safe to commit and safe to source on both platforms without any runtime branching.
- Content boundary is enforced at review time: the pre-commit `grep` check in Architecture-0010 §15 flags violations automatically.
- Future contributors adding a portable tool integration add a guarded `command -v` line to `shared.zsh`; platform-specific additions go to the correct platform layer.
- Extended personal aliases (`ll`, `la`, `lt`) go in `local.zsh` or the user's real `shared.zsh` — not in the committed template (see ADR-0037).
