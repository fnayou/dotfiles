# Architecture: Zsh Configuration Management

**Number:** 0004
**Status:** Approved
**Date:** 2026-06-17
**PRD:** [0004-zsh-configuration.md](../prd/0004-zsh-configuration.md)

---

## Context

The user currently relies on the default macOS zsh configuration. No zsh dotfiles are version-controlled. As the dotfiles repository matures past the foundation phase (Architecture 0002) and the first real package (Architecture 0003 — Git), zsh is the next logical package to bring under management.

This architecture defines the structure for managing zsh configuration across macOS (primary) and EndeavourOS/Arch Linux (secondary) using GNU Stow. It does not implement any zsh configuration files — that is deferred to the implementation phase.

Key established context entering this architecture:

- ADR-0001: Platform-first Stow layout (`stow/<area>/<package>/`) is the authoritative layout.
- ADR-0003: `.example` files are required for any config that may contain sensitive or identity-specific values.
- ADR-0004: XDG mixed-mode adoption is accepted — use `$XDG_CONFIG_HOME` where the tool supports it, fall back to `$HOME/.*` where it does not.
- ADR-0012: Stow task interface uses `AREA` and `PACKAGE` as separate variables.
- ADR-0013: The Git package established the include-based adoption model — managed files are sourced/included rather than replacing user-owned files.
- Architecture 0002: `stow/macos/` and `stow/arch/` exist as reserved platform areas; `stow/common/` holds cross-platform packages.

Zsh natively supports XDG-style config paths via `$ZDOTDIR`. When `$ZDOTDIR` is set, zsh reads `$ZDOTDIR/.zshrc` instead of `~/.zshrc`. This makes zsh a strong candidate for XDG placement under `$HOME/.config/zsh/`.

---

## Constraints

From PRD 0004:

- Must support macOS and EndeavourOS/Arch Linux.
- Must target zsh only — no other shells.
- Must not modify any existing file outside the repository until explicit user approval.
- Must follow established Stow safety rules: dry-run before install, no `--adopt`.
- No real personal values in committed files — `.example` files with placeholders only.
- Real zsh adoption is a later phase — this architecture covers design only.
- Must not delete, move, or overwrite `~/.zshrc` or any existing zsh file.
- Must not create symlinks in `$HOME` without explicit per-session user approval.
- Must not run `stow --adopt` at any point.

From AGENTS.md and established ADRs:

- macOS and Arch configurations must be kept separate (AGENTS.md §10, ADR-0001).
- Homebrew references must never appear in shared config (AGENTS.md §10).
- pacman/yay references must never appear in shared config (AGENTS.md §10).
- Do not choose a zsh plugin manager or prompt theme (PRD 0004 out-of-scope).

---

## Layout Decision

### Options evaluated

PRD 0004 presents two layout options:

**Option A — Stow Package Layout**

Shared logic and `~/.zshrc` are managed in `stow/common/zsh/`. Platform-specific files are in `stow/macos/zsh/` and `stow/arch/zsh/`. Stow symlinks `~/.zshrc` directly.

- Pro: `~/.zshrc` is fully version-controlled and reproducible.
- Con: `~/.zshrc` is in Stow's control — any existing `~/.zshrc` causes a conflict on first stow.
- Con: Every platform must stow both `common/zsh` and their platform package — two Stow invocations required.
- Con: Replacing `~/.zshrc` directly is a higher-risk first step; contradicts the incremental adoption principle.

**Option B — XDG-Style Layout**

All managed files live under `stow/common/zsh/.config/zsh/` (symlinked to `~/.config/zsh/`). `~/.zshrc` remains a user-owned minimal bootstrap file that sources the managed files. Stow never touches `~/.zshrc`.

- Pro: Stow only manages `~/.config/zsh/` — the existing `~/.zshrc` is never touched.
- Pro: Safer incremental adoption — the user adds a source line to their existing `~/.zshrc` at their own pace.
- Pro: Directly aligns with ADR-0004 (XDG mixed-mode) and the `$ZDOTDIR` convention.
- Pro: All platform-specific files (`macos.zsh`, `arch.zsh`) live in the same `common/zsh` Stow package — one stow invocation on any platform.
- Con: `~/.zshrc` bootstrap is not version-controlled — not fully reproducible on a new machine via stow alone. Mitigated by providing a documented example bootstrap snippet.
- Con: Requires explicit `source` calls in `~/.zshrc` — one manual user step.

**Decision: Option B — XDG-Style Layout.**

Evidence:

1. ADR-0004 explicitly establishes XDG mixed-mode as the repository's path preference. Zsh supports `$ZDOTDIR` natively, making it a first-class XDG candidate.
2. The Git package (Architecture 0003, ADR-0013) established the include-based adoption model — managed files are sourced/included rather than replacing user-owned files. Option B applies the same pattern to zsh: `~/.zshrc` is never replaced; it gains a `source` call pointing to the managed layer.
3. ADR-0001's platform-first layout is fully preserved — `stow/common/zsh/` satisfies all three common-package criteria (same path on both platforms, values portable, no platform-specific references).
4. The incremental adoption principle (AGENTS.md §3, PRD 0004) weighs against touching `~/.zshrc` as the first step.

---

## Directory Structure

```
stow/
└── common/
    └── zsh/
        └── .config/
            └── zsh/
                ├── shared.zsh.example      # Shared/portable zsh config — placeholder only
                ├── macos.zsh.example       # macOS-specific zsh config — placeholder only
                └── arch.zsh.example        # Arch-specific zsh config — placeholder only
```

When the user adopts and stows the package, Stow creates:

```
~/.config/zsh/shared.zsh   →  stow/common/zsh/.config/zsh/shared.zsh
~/.config/zsh/macos.zsh    →  stow/common/zsh/.config/zsh/macos.zsh
~/.config/zsh/arch.zsh     →  stow/common/zsh/.config/zsh/arch.zsh
```

`~/.zshrc` is NOT managed by Stow. It remains user-owned and is not version-controlled. The user adds source calls to their existing `~/.zshrc` manually — see Adoption Phases below.

No `stow/macos/zsh/` or `stow/arch/zsh/` packages are created. All three files live in `stow/common/zsh/` because `~/.config/zsh/` is the same path on both platforms, and OS detection is handled at runtime inside the `~/.zshrc` bootstrap.

---

## File Responsibilities

### `shared.zsh` (committed as `shared.zsh.example`)

The portable, cross-platform zsh configuration layer. Sourced first on every platform.

Must contain only:

- `$XDG_CONFIG_HOME`, `$XDG_DATA_HOME`, `$XDG_CACHE_HOME` exports (authoritative place to define XDG variables for interactive shells — see ADR-0004).
- `$EDITOR`, `$PAGER`, and other portable environment exports.
- Zsh options: `setopt`, `unsetopt` — portable options only.
- History configuration: `HISTFILE`, `HISTSIZE`, `SAVEHIST`.
- Completion initialization: `autoload -Uz compinit && compinit`.
- Aliases that are portable across macOS and Arch (safe flags available on both BSD and GNU).

Must NOT contain:

- Any Homebrew reference or path.
- Any pacman/yay reference or path.
- Any path that differs between macOS and Arch.
- Any macOS-only tool reference (`pbcopy`, `open`, `brew`).
- Any Arch-only tool reference (`pacman`, `yay`, `systemctl`).
- Plugin manager initialization.
- Prompt theme initialization.

### `macos.zsh` (committed as `macos.zsh.example`)

macOS-specific zsh configuration. Sourced after `shared.zsh` on macOS only.

Candidates for this file:

- Homebrew path initialization: `eval "$(YOUR_HOMEBREW_PREFIX/bin/brew shellenv)"`.
- macOS-specific `$PATH` entries.
- macOS tool aliases: `open`, `pbcopy`, `pbpaste`.
- macOS-specific tool integrations (e.g., iTerm2 shell integration, if applicable).
- Credential helper configuration specific to macOS.

Must NOT contain:

- Anything that belongs in `shared.zsh`.
- Any pacman/yay/systemctl reference.
- Hardcoded machine-specific paths — use `$HOME` and `$XDG_CONFIG_HOME` placeholders.

### `arch.zsh` (committed as `arch.zsh.example`)

Arch/EndeavourOS-specific zsh configuration. Sourced after `shared.zsh` on Arch only.

Candidates for this file:

- Arch-specific `$PATH` entries.
- pacman/yay aliases, if desired.
- Arch-specific tool integrations (e.g., `systemctl` helpers).
- AUR helper configuration, if applicable.

Must NOT contain:

- Anything that belongs in `shared.zsh`.
- Any Homebrew/macOS reference.
- Hardcoded machine-specific paths.

### `~/.zshrc` bootstrap (user-owned, NOT version-controlled)

The user's existing `~/.zshrc` is never touched. After stowing, the user manually adds the following source block at the end of their existing `~/.zshrc`:

```zsh
# Managed zsh config — sourced from dotfiles
source "$HOME/.config/zsh/shared.zsh"

if [[ "$OSTYPE" == "darwin"* ]]; then
  source "$HOME/.config/zsh/macos.zsh"
elif [[ -f /etc/arch-release ]]; then
  source "$HOME/.config/zsh/arch.zsh"
fi
```

This is consistent with the Git package's include-based model (ADR-0013): the user's own file gains a pointer to the managed layer; the managed layer never replaces the user's file.

---

## Shared Zsh Logic

What belongs in `shared.zsh`:

| Category | Examples |
|---|---|
| XDG variable exports | `export XDG_CONFIG_HOME="$HOME/.config"` |
| Portable env exports | `export EDITOR=YOUR_VALUE`, `export PAGER=YOUR_VALUE` |
| History config | `HISTFILE`, `HISTSIZE`, `SAVEHIST` |
| Zsh options | `setopt HIST_IGNORE_DUPS`, `setopt AUTO_CD` |
| Completion init | `autoload -Uz compinit && compinit` |
| Portable aliases | `alias grep='grep --color=auto'` |

What must not appear in `shared.zsh`:

- `brew`, `homebrew`, `/opt/homebrew`, `/usr/local/Cellar`
- `pacman`, `yay`, `systemctl`, `/etc/arch-release`
- `pbcopy`, `pbpaste`, `open` (macOS-only builtins)
- Any hardcoded absolute path that differs between platforms

---

## macOS-Specific Zsh Logic

Belongs exclusively in `macos.zsh`:

```zsh
# Homebrew — path depends on chip architecture.
# YOUR_HOMEBREW_PREFIX is a literal placeholder token, NOT a shell variable.
# User replaces it with /opt/homebrew (Apple Silicon) or /usr/local (Intel).
eval "$(YOUR_HOMEBREW_PREFIX/bin/brew shellenv)"

# macOS-specific PATH additions
export PATH="YOUR_MACOS_TOOL_PATH:$PATH"

# macOS tool aliases
alias lock='/System/Library/CoreServices/Menu\ Extras/User.menu/Contents/Resources/CGSession -suspend'
```

Placeholder conventions in the `.example` file:

- `YOUR_HOMEBREW_PREFIX` — user replaces with `/opt/homebrew` (Apple Silicon) or `/usr/local` (Intel).
- `YOUR_MACOS_TOOL_PATH` — user replaces with any custom macOS-specific path.
- `YOUR_VALUE` — for any tool-specific configuration value.

---

## Arch-Specific Zsh Logic

Belongs exclusively in `arch.zsh`:

```zsh
# Arch-specific PATH additions
export PATH="YOUR_ARCH_TOOL_PATH:$PATH"

# AUR helper alias — if applicable
# alias aur='YOUR_AUR_HELPER'
```

Placeholder conventions in the `.example` file:

- `YOUR_ARCH_TOOL_PATH` — user replaces with any Arch-specific path.
- `YOUR_AUR_HELPER` — user replaces with `yay`, `paru`, etc. if applicable.

---

## Stow Compatibility

### Package location

`stow/common/zsh/` satisfies all three ADR-0001 common-package criteria:

1. Config path `$HOME/.config/zsh/` is identical on macOS and Arch.
2. The package directory structure is identical on both platforms.
3. Platform-specific logic is segregated into separate sourced files — no platform tool is referenced at the package level.

No `stow/macos/zsh/` or `stow/arch/zsh/` packages are created.

### Stow commands

Dry-run (always first):

```bash
task dry-run AREA=common PACKAGE=zsh
```

Or directly:

```bash
stow --dir=stow/common --target="$HOME" --simulate zsh
```

Install (manual step only, after reviewing dry-run output):

```
⚠️  MANUAL STEP — review dry-run output before running
```

```bash
stow --dir=stow/common --target="$HOME" zsh
```

This creates symlinks:

- `~/.config/zsh/shared.zsh` → `stow/common/zsh/.config/zsh/shared.zsh`
- `~/.config/zsh/macos.zsh` → `stow/common/zsh/.config/zsh/macos.zsh`
- `~/.config/zsh/arch.zsh` → `stow/common/zsh/.config/zsh/arch.zsh`

### Platform stow summary

| Platform | Stow invocation | Files activated |
|---|---|---|
| macOS | `stow --dir=stow/common --target="$HOME" zsh` | `shared.zsh`, `macos.zsh`, `arch.zsh` (all symlinked; only macOS branch sourced at runtime) |
| Arch | `stow --dir=stow/common --target="$HOME" zsh` | same — only Arch branch sourced at runtime |

All three files are always symlinked on every platform. Runtime OS detection in `~/.zshrc` determines which platform file is sourced. This keeps Stow usage to a single package invocation on all platforms.

---

## Placeholder/Template-First Approach

All three files are committed as `.example` variants only:

- `stow/common/zsh/.config/zsh/shared.zsh.example`
- `stow/common/zsh/.config/zsh/macos.zsh.example`
- `stow/common/zsh/.config/zsh/arch.zsh.example`

The real files (`shared.zsh`, `macos.zsh`, `arch.zsh`) are git-ignored. The user copies each `.example` file to the real filename locally, fills in any placeholder values, and then stows.

Copy commands (manual step). Paths are relative to the repository root — run from the repository root, or substitute the repository root for the leading `stow/`:

```
⚠️  MANUAL STEP — review before running
```

```bash
cp stow/common/zsh/.config/zsh/shared.zsh.example stow/common/zsh/.config/zsh/shared.zsh
cp stow/common/zsh/.config/zsh/macos.zsh.example  stow/common/zsh/.config/zsh/macos.zsh
cp stow/common/zsh/.config/zsh/arch.zsh.example   stow/common/zsh/.config/zsh/arch.zsh
```

These copied files must be ignored by git so they are never committed. Prefer a directory-level `.gitignore` placed at `stow/common/zsh/.config/zsh/.gitignore` — this keeps the package's ignore rules next to the files and scales as more packages are added:

```gitignore
# stow/common/zsh/.config/zsh/.gitignore
# Ignore real (filled-in) zsh files; keep .example templates tracked.
shared.zsh
macos.zsh
arch.zsh
```

(Equivalent root-level entries also work, but the directory-level file is preferred for locality.)

Placeholder conventions used across all `.example` files:

- `$HOME` — never a hardcoded absolute home path.
- `YOUR_VALUE` — any value the user must supply.
- `YOUR_HOMEBREW_PREFIX` — macOS only.
- `YOUR_ARCH_TOOL_PATH` — Arch only.
- Comments explain each placeholder.

---

## Adoption Phases

This architecture covers Phases 1 and 2 of the PRD's adoption strategy. Phases 3–5 are implementation and user-facing.

### Phase 1 — Architecture (this document)

Output: this architecture document. No files created. No `$HOME` changes.

### Phase 2 — Scaffold `.example` files (implementation)

Create the three `.example` files with placeholder content only. Add the directory-level `.gitignore`. Updating `docs/stow-usage.md` with a zsh package section is **mandatory** before Phase 2 is considered complete — the section must document the dry-run command, the copy-and-fill step, and the `~/.zshrc` source-block snippet, mirroring the existing git package section.

No symlinks created. No stow invoked.

### Phase 3 — Populate `.example` files (implementation)

Fill in the `.example` files with documented patterns (options, history, portable aliases). Still no real values — only structure and safe defaults.

### Phase 4 — User local adoption (user action, not automated)

The user:

1. Copies each `.example` to the real filename.
2. Reviews and customizes placeholder values.
3. Runs the Stow dry-run and reviews output.
4. Stows the package after reviewing dry-run.
5. Adds the source block to their existing `~/.zshrc` manually.
6. Opens a new shell to verify.

```
⚠️  MANUAL STEP — each of these steps requires explicit user review
```

### Phase 5 — Active use

Stow is active. `~/.config/zsh/*.zsh` are symlinks. `~/.zshrc` sources the managed layer. Changes to `.example` files flow to the user after they re-copy and re-stow, or update in place.

---

## Rollback Strategy

Because `~/.zshrc` is never replaced or managed by Stow, rollback is low-risk.

### Rollback from Phase 4 (after stowing but before adding source block to `~/.zshrc`)

No zsh behavior has changed. Simply unstow:

```
⚠️  MANUAL STEP — review before running
```

```bash
stow --dir=stow/common --target="$HOME" --delete zsh
```

This removes the three symlinks from `~/.config/zsh/`. The user's `~/.zshrc` is unaffected.

### Rollback from Phase 5 (after adding source block to `~/.zshrc`)

1. Remove the source block from `~/.zshrc` (manual edit — delete the added lines).
2. Unstow the package:

```
⚠️  MANUAL STEP — review before running
```

```bash
stow --dir=stow/common --target="$HOME" --delete zsh
```

3. Open a new shell to confirm the original `~/.zshrc` behavior is restored.

### Verification after rollback

```bash
# Confirm no stow-managed symlinks remain (the directory may still hold
# the user's own files — verify no symlinks point into the dotfiles repo)
ls -l ~/.config/zsh/

# Confirm zsh starts cleanly
zsh --no-rcs -c 'echo ok'
```

A clean rollback shows no symlinks under `~/.config/zsh/` resolving to `stow/common/zsh/`. Any remaining entries should be the user's own non-managed files.

---

## Design Decisions

### Decision 1: All zsh files in `stow/common/zsh/`, not split across platform areas

**Option A:** Create `stow/macos/zsh/` and `stow/arch/zsh/` for platform-specific files.

- Pro: platform separation explicit in Stow layout.
- Con: two Stow invocations required on each machine.
- Con: shared path `$HOME/.config/zsh/` means the three files do not violate ADR-0001 criteria — splitting adds complexity with no structural benefit.

**Option B:** Keep all three files in `stow/common/zsh/`. Platform selection happens at runtime via OS detection in `~/.zshrc`.

- Pro: single Stow invocation on every platform.
- Pro: all three files satisfy ADR-0001 common-package criteria (same path, same structure, no platform tool at package level).
- Pro: consistent with Git package pattern — one `common` package, all config in one place.
- Con: `arch.zsh` is symlinked on macOS and vice versa (unused but harmless; not sourced).

**Decision: Option B.** Unused symlinks are harmless; simplicity benefit outweighs the minor asymmetry.

---

### Decision 2: XDG-style layout over Stow package layout

See Layout Decision section above. Decision is Option B from PRD 0004.

---

### Decision 3: `.example` files for all three zsh files

All three files are committed as `.example` variants.

- `shared.zsh` is low-sensitivity, but the pattern is applied uniformly to avoid confusion.
- `macos.zsh` may contain Homebrew paths — user-specific enough to warrant `.example`.
- `arch.zsh` may contain AUR helper or Arch-specific paths — same rationale.

Consistent with ADR-0003.

---

### Decision 4: `$ZDOTDIR` is not set by this architecture

Setting `$ZDOTDIR` changes where zsh looks for its startup files entirely — zsh would read `$ZDOTDIR/.zshrc` instead of `~/.zshrc`. To set it before zsh evaluates it, the user must modify `~/.zshenv` (read first in zsh's startup sequence), which is equivalent or higher risk than touching `~/.zshrc`. The explicit `source` block achieves the same result with **lower risk and no change to zsh's initialization order** — the user's existing `~/.zshrc` keeps loading exactly as before, gaining only the appended source calls. `$ZDOTDIR` can be adopted in a future phase once the managed layer is proven.

**Decision:** Do not set `$ZDOTDIR`. Use explicit `source` calls in the user's existing `~/.zshrc`.

---

## Risks and Mitigations

| Risk | Likelihood | Severity | Mitigation |
|---|---|---|---|
| Stow conflict — `~/.config/zsh/` already contains files with the same names | Medium | Medium | Dry-run step surfaces conflicts; user resolves manually before install; `--adopt` is forbidden |
| User adds source block to `~/.zshrc` before stowing, causing `source` errors on shell start | Medium | Low | Adoption phases are ordered — stow before adding source block; docs make this explicit |
| `.example` file committed with real values (credentials, hostname) | Low | High | ADR-0003 enforced by Reviewer checklist; pre-commit review |
| `macos.zsh` sourced on Arch (or vice versa) due to incorrect OS detection | Low | Medium | OS detection guard is explicit in bootstrap snippet; sourcing a no-op file is harmless |
| `$HOME/.config/zsh/` directory does not exist on a fresh machine | Low | Low | Stow creates parent directories as needed; dry-run output shows this |
| Placeholder values left in `.example` files render incorrect shell config | Low | Low | Comments in each `.example` file explain every placeholder |
| Plugin manager or prompt added to `shared.zsh` during implementation | Low | Medium | Explicitly out of scope per PRD 0004; Reviewer rejects any such addition |
| Cross-platform behavioral differences in zsh options | Low | Low | Only options documented as portable are added to `shared.zsh` |
| User accidentally stows `.example` files directly | Low | Low | `.example` files are not valid zsh; shell errors on `source`; easy to diagnose |

---

## Extensibility

This structure supports future growth without redesign:

- **Plugin manager:** Initialized in `shared.zsh` (if cross-platform) or a platform file (if not). No structural change needed.
- **Prompt theme:** Added to `shared.zsh` or a platform file. No structural change.
- **Additional platform:** New `platform.zsh.example` added to the same package. Bootstrap snippet gains an `elif` branch.
- **`$ZDOTDIR` migration:** If the user later wants `$ZDOTDIR`, `shared.zsh` can export it. No Stow package change required.
- **Per-machine overrides:** A `local.zsh` (git-ignored, sourced last) can be added without committing machine-specific values — same pattern as Git's `[include]` model.

---

## ADRs to Create

The following new ADR is proposed based on this architecture:

| Number | Title | Status |
|---|---|---|
| ADR-0016 | Zsh files in `stow/common/zsh/` with runtime OS detection | Accepted |

Existing ADRs that directly govern this architecture (no new records needed):

- ADR-0001: Platform-first layout
- ADR-0003: `.example` files
- ADR-0004: XDG mixed-mode
- ADR-0013: Include-based adoption

---

## Out of Scope

This architecture explicitly does not decide or implement:

- Any zsh plugin manager (Oh My Zsh, Zinit, Antigen, etc.).
- Any zsh prompt theme (Starship, Powerlevel10k, Pure, etc.).
- Specific aliases, functions, or environment variable values.
- Terminal emulator configuration.
- Fish, bash, or any other shell.
- SSH configuration (permanent non-goal per ADR-0005).
- Git credential helpers.
- `chsh` or any change to the user's default shell.
- The content of `~/.zshrc` — only the documented source-block pattern is provided as a guide.
- Zsh plugin installation or management.
- Whether to use `$ZDOTDIR` (deferred — see Decision 4).
- Actual zsh configuration file content beyond documented patterns.

---

## Open Questions

None blocking. The layout decision is made, the file structure is defined, and the adoption strategy aligns with established ADRs.

Optional future discussion:

- Should a `local.zsh` slot (git-ignored, sourced last) be scaffolded from the start to make machine-specific overrides explicit? Decide during implementation phase without changing this architecture.

---

## Recommended Next Step

Planner converts this architecture into an ordered implementation plan under `docs/plans/0004-zsh-configuration-plan.md`. The plan must include:

- Creation of the `stow/common/zsh/.config/zsh/` directory scaffold.
- Creation of `shared.zsh.example`, `macos.zsh.example`, `arch.zsh.example` with placeholder content.
- `.gitignore` additions for the three real (non-example) filenames.
- `docs/stow-usage.md` update with a zsh package section.
- ADR-0016 written before implementation files are committed.
- Per-task validation steps (all read-only).
- Explicit safety check: no stow invoked, no `$HOME` modified.
