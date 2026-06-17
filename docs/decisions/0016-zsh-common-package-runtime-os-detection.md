# Decision: Zsh Files in `stow/common/zsh/` with Runtime OS Detection

**Number:** 0016
**Date:** 2026-06-17
**Status:** Accepted
**PRD:** 0004-zsh-configuration
**Architecture:** 0004-zsh-configuration-architecture

## Context

The zsh configuration spans three layers of logic: portable cross-platform config (`shared.zsh`), macOS-only config (`macos.zsh`), and Arch/EndeavourOS-only config (`arch.zsh`). The target path `~/.config/zsh/` is identical on both macOS and Arch — there is no structural difference between the two platforms at the package level.

ADR-0001 defines the criteria for placing a package under `stow/common/`:

1. The config file path is identical on macOS and Arch.
2. The config values work unmodified on both platforms.
3. No platform-specific tool or behavior is referenced at the package level.

All three criteria are satisfied:

1. `~/.config/zsh/` is the same path on both platforms.
2. The package directory structure is identical — all three files are symlinked on every platform.
3. Platform selection is handled at runtime inside the user's `~/.zshrc` source block, not at the Stow package level.

Two layout options were evaluated:

- **Option A:** Split into `stow/common/zsh/` (for `shared.zsh`) + `stow/macos/zsh/` (for `macos.zsh`) + `stow/arch/zsh/` (for `arch.zsh`). Platform files stowed only on their target platform.
- **Option B:** All three files in a single `stow/common/zsh/` package. Runtime OS detection in `~/.zshrc` selects which platform file is sourced.

Option A requires two Stow invocations on every machine (once for `common/zsh`, once for the platform area). Option B requires one. The unused platform file (`arch.zsh` on macOS, or `macos.zsh` on Arch) is symlinked but never sourced — it is harmless.

This decision is consistent with Architecture 0004 (Layout Decision, Design Decision 1) and the include-based adoption model established by ADR-0013 for the Git package.

## Decision

Place all three zsh files (`shared.zsh`, `macos.zsh`, `arch.zsh`) in a single `stow/common/zsh/` package at the path `stow/common/zsh/.config/zsh/`.

Platform selection happens at runtime via OS detection in the user's `~/.zshrc` source block:

```zsh
# Managed zsh config — sourced from dotfiles
source "$HOME/.config/zsh/shared.zsh"

if [[ "$OSTYPE" == "darwin"* ]]; then
  source "$HOME/.config/zsh/macos.zsh"
elif [[ -f /etc/arch-release ]]; then
  source "$HOME/.config/zsh/arch.zsh"
fi
```

`~/.zshrc` is never stowed. It remains a user-owned file. The user manually appends the source block above to their existing `~/.zshrc` after stowing the package — following the same include-based adoption model as ADR-0013.

`$ZDOTDIR` is not set by this architecture. Setting it would require modifying `~/.zshenv` (read first in zsh's startup sequence), which carries equal or higher risk than touching `~/.zshrc`. Explicit `source` calls achieve the same result with lower risk and no change to zsh's initialization order. `$ZDOTDIR` adoption is deferred to a future phase (Architecture 0004, Decision 4).

All three files are committed as `.example` variants only. The real files (`shared.zsh`, `macos.zsh`, `arch.zsh`) are git-ignored via a directory-level `.gitignore` at `stow/common/zsh/.config/zsh/.gitignore`.

## Consequences

- One Stow invocation is sufficient on every platform: `stow --dir=stow/common --target="$HOME" zsh`.
- `arch.zsh` is symlinked on macOS (and `macos.zsh` on Arch). These files are unused — not sourced at runtime due to OS detection guard. This is harmless.
- Adding a third platform requires adding one new file (e.g., `platform.zsh.example`) to the same package and one `elif` branch to the `~/.zshrc` source block. No Stow package change needed.
- `~/.zshrc` bootstrap is not version-controlled — not fully reproducible on a new machine via stow alone. Mitigated by the documented source-block snippet in `docs/stow-usage.md`.
- Adopting the managed config requires one manual user step — adding the source block to `~/.zshrc`. Accepted trade-off, consistent with ADR-0013.
