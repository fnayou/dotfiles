# Architecture: bat Configuration Stow Package

**Number:** 0013
**Status:** Approved
**Date:** 2026-06-21
**PRD:** [0013-bat-configuration](../prd/0013-bat-configuration.md)

> **Backfill note:** Authored retroactively after implementation. See PRD 0013 and
> review 0042 for the sequencing explanation.

---

## Context

PRD 0013 scopes adopting a managed bat configuration into the dotfiles repository as a
Stow package under `stow/common/`, with the Catppuccin Macchiato theme active.

bat is cross-platform — `brew install bat` (macOS), `pacman -S bat` (Arch). The config
directory (`~/.config/bat/`) follows XDG and is identical on both platforms; it resolves
via `bat --config-dir`.

The inspiration was the public `josephschmitt/dotfiles` repo, whose `bat` package ships a
`config` file plus a `themes/` directory of Tokyo Night `.tmTheme` files and instructs the
user to run `bat cache --build` after stowing. This package follows the same shape but
substitutes the Catppuccin Macchiato theme to match the repository color scheme and
activates the theme in `config` (joseph's leaves it commented, driven by `BAT_THEME`).

The key behavioral fact that distinguishes bat from Alacritty and Herdr: **bat does not read
`.tmTheme` files at runtime.** It reads a compiled binary cache built by `bat cache --build`
from the files in `$(bat --config-dir)/themes/`. Stowing the theme file is necessary but not
sufficient — the cache build is a required, separate, manual activation step.

No secrets or machine-specific values are present in either the config or the theme file.

Out of scope (per PRD 0013): installing bat, creating symlinks in `$HOME`, running
`bat cache --build` against the host, fzf/git/`MANPAGER` integration, platform-split packages.

---

## Proposed Structure

### Directory layout

```
stow/
└── common/
    └── bat/
        ├── README.md
        ├── .stow-local-ignore
        └── .config/
            └── bat/
                ├── config
                └── themes/
                    └── Catppuccin Macchiato.tmTheme
```

No `stow/macos/bat/` or `stow/arch/bat/` packages are created.

### File inventory

| File | Type | Stowed? | Maps to |
|------|------|---------|---------|
| `stow/common/bat/README.md` | Package doc | No (ignored) | — |
| `stow/common/bat/.stow-local-ignore` | Stow metadata | No (consumed by Stow) | — |
| `stow/common/bat/.config/bat/config` | Real managed config | Yes | `~/.config/bat/config` |
| `stow/common/bat/.config/bat/themes/Catppuccin Macchiato.tmTheme` | Theme | Yes | `~/.config/bat/themes/Catppuccin Macchiato.tmTheme` |

### Activation sequence (manual, future)

```bash
# Step 1: Dry run
stow --dir=stow/common --target="$HOME" --no-folding --simulate bat

# Step 2: Install (after reviewing dry-run output)
⚠️  MANUAL STEP — run only after approving dry-run output
stow --dir=stow/common --target="$HOME" --no-folding bat

# Step 3: Build theme cache (bat-specific — required for the theme to apply)
bat cache --build
```

---

## Design Decisions

### Decision 1: Theme file committed in-repo vs. fetched at activation

**Option A: Commit the `.tmTheme` into the package.**
- Pro: Activation is offline and reproducible; not dependent on upstream availability.
- Pro: Matches the inspiration repo's layout (themes vendored in `themes/`).
- Pro: The theme is a single static file with a clear upstream provenance.
- Con: A vendored copy can drift from upstream — accepted; bat themes are stable.

**Option B: Document a `wget` into `$(bat --config-dir)/themes` at activation.**
- Pro: Always current with upstream.
- Con: Requires network at activation; not reproducible offline.
- Con: Writes into `$HOME` outside the Stow mechanism, splitting ownership of the config dir.

**Decision: Option A (vendor the theme).** Reproducibility and a single Stow-owned config
dir outweigh staying bleeding-edge. The theme was fetched once from
`catppuccin/bat` and committed.

---

### Decision 2: `--no-folding` required (nested directory)

The package has a nested `themes/` directory. Without `--no-folding`, Stow may fold
`~/.config/bat` into a single symlink pointing at the package directory, rather than
creating `~/.config/bat` and `~/.config/bat/themes` as real directories with per-file
symlinks. A folded config dir breaks the moment any non-managed file (or a future
`bat cache --build` output, were it directed there) needs to coexist.

**Decision:** All stow commands for this package use `--no-folding`, consistent with the
Alacritty and Herdr packages.

---

### Decision 3: Activate theme in `config` vs. via `BAT_THEME` env var

**Option A: `--theme="Catppuccin Macchiato"` in the `config` file.**
- Pro: Self-contained in the package; no dependency on shell exports.
- Pro: Works for any invocation of bat regardless of shell.
- Con: Overridable only by `BAT_THEME` or `--theme` at call time (acceptable).

**Option B: Leave theme commented, set `BAT_THEME` in zsh.**
- Pro: Matches the inspiration repo; centralizes theme choice in shell env.
- Con: Couples the bat package to the zsh package; theme breaks if used outside that shell.

**Decision: Option A.** Keeps the package self-contained and theme-active on stow + cache
build, with no cross-package coupling.

---

### Decision 4: `stow/common/` vs. platform-specific placement

bat, its config path, and every option used are identical on macOS and Arch. No
platform-specific values exist. **Decision: `stow/common/bat/`.**

---

## Risks

- **Theme not applied after stow:** The most likely user-facing failure. bat needs
  `bat cache --build` after the theme file is linked; stow alone is insufficient. Mitigated
  by making the cache build an explicit, prominent step in the setup guide (§6) and a
  troubleshooting entry.
- **Stow conflict at activation:** If `~/.config/bat/config` already exists as a real file,
  Stow refuses. The dry-run step surfaces this; the user resolves manually (no `--adopt`).
- **Directory folding:** Mitigated by mandatory `--no-folding` (Decision 2).
- **Vendored theme drift:** The committed `.tmTheme` can age relative to upstream. Low
  impact; re-fetch and rebuild cache if desired.

---

## Extensibility

- **More themes:** Additional `.tmTheme` files drop into `themes/`; one `bat cache --build`
  picks them all up. No package restructure.
- **More bat options:** Append flags to `config`.
- **Platform override:** A future `stow/arch/bat/` or `stow/macos/bat/` overlay can be added
  alongside `stow/common/bat/` if a platform-specific need ever arises.

---

## Open Questions

None.

---

## Recommended Next Step

Planner: produce an implementation plan for PRD 0013 / Architecture 0013 covering the
package skeleton, config, vendored theme, README + setup guide, README package-table update,
and fake-home validation — without running Stow or `bat cache --build` against `$HOME`.
