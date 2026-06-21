# Architecture: eza Configuration Stow Package

**Number:** 0014
**Status:** Approved
**Date:** 2026-06-21
**PRD:** [0014-eza-configuration](../prd/0014-eza-configuration.md)

---

## Context

PRD 0014 scopes adopting a managed eza theme into the dotfiles repository as a Stow package
under `stow/common/`, with the Catppuccin Macchiato (Blue) theme active.

eza is cross-platform — `brew install eza` (macOS), `pacman -S eza` (Arch). The config
directory (`~/.config/eza/`) follows XDG and is identical on both platforms. eza already in
use; only configuration is being adopted, not installation.

The inspiration was the public `josephschmitt/dotfiles` eza package, which ships a `theme.yml`
plus alternate variants (`catppuccin.yml`, `tokyonight.yml`) and points `theme.yml` at the
active one via symlink. This package follows the same shape but ships a **single** active
`theme.yml` (Catppuccin Macchiato Blue), consistent with how the bat package ships one active
theme rather than a switchable set.

Key behavioral fact distinguishing eza from bat: **eza reads `~/.config/eza/theme.yml`
directly at runtime.** There is no compiled cache and no `bat cache --build` analogue.
Stowing the file is sufficient for activation. eza honors `EZA_CONFIG_DIR` if set, but
defaults to `~/.config/eza`; this package relies on the default and adds no env-var
dependency.

No secrets or machine-specific values are present in the theme file (colors + styling keys).

Out of scope (per PRD 0014): installing eza, creating symlinks in `$HOME`, CLI flags/aliases
(owned by the zsh package), multiple switchable variants, platform-split packages.

---

## Proposed Structure

### Directory layout

```
stow/
└── common/
    └── eza/
        ├── README.md
        ├── .stow-local-ignore
        └── .config/
            └── eza/
                └── theme.yml
```

No `stow/macos/eza/` or `stow/arch/eza/` packages are created.

### File inventory

| File | Type | Stowed? | Maps to |
|------|------|---------|---------|
| `stow/common/eza/README.md` | Package doc | No (ignored) | — |
| `stow/common/eza/.stow-local-ignore` | Stow metadata | No (consumed by Stow) | — |
| `stow/common/eza/.config/eza/theme.yml` | Real managed theme | Yes | `~/.config/eza/theme.yml` |

### Activation sequence (manual, future)

```bash
# Step 1: Dry run
stow --dir=stow/common --target="$HOME" --no-folding --simulate eza

# Step 2: Install (after reviewing dry-run output)
⚠️  MANUAL STEP — run only after approving dry-run output
stow --dir=stow/common --target="$HOME" --no-folding eza
```

No step 3 — eza reads `theme.yml` directly; the theme is active immediately after stowing.

---

## Design Decisions

### Decision 1: Theme committed in-repo vs. fetched at activation

**Option A: Vendor the `theme.yml` into the package.**
- Pro: Activation is offline and reproducible; not dependent on upstream availability.
- Pro: Consistent with the bat package (Architecture 0013, Decision 1).
- Con: A vendored copy can drift from upstream — accepted; theme files are stable.

**Option B: Document a copy from `catppuccin/eza` at activation.**
- Con: Requires network at activation; not reproducible offline.
- Con: Writes into `$HOME` outside the Stow mechanism.

**Decision: Option A (vendor the theme).** Same rationale as bat — reproducibility and a
single Stow-owned config dir. The theme is fetched once from `catppuccin/eza` and committed.

---

### Decision 2: Single `theme.yml` vs. multiple switchable variants

**Option A: Single active `theme.yml` (Macchiato Blue).**
- Pro: Matches the repo's single-theme convention (bat ships one theme).
- Pro: eza reads `theme.yml` by name — no symlink indirection needed.
- Pro: Simplest to stow and reason about.
- Con: Switching themes means replacing the file (acceptable; theme is fixed by repo scheme).

**Option B: Ship variants + symlink `theme.yml` → active (inspiration repo's approach).**
- Pro: Easy runtime theme switching.
- Con: Adds a symlink-management step and files we do not use.
- Con: Inconsistent with the bat single-theme precedent.

**Decision: Option A (single file).** The repository has one fixed color scheme. A switchable
set adds complexity with no benefit here.

---

### Decision 3: Accent color — Blue

Catppuccin Macchiato has many accent variants. Alacritty and Herdr already use the **Blue**
accent (`#8aadf4`). **Decision: vendor `catppuccin-macchiato-blue.yml`** for visual
consistency. Swappable later by replacing the file with another accent variant — no structural
change.

---

### Decision 4: `--no-folding` required (nested directory)

The package nests `.config/eza/`. Without `--no-folding`, Stow may fold `~/.config/eza` into a
single symlink pointing at the package directory rather than creating a real directory with a
per-file symlink. **Decision:** all stow commands use `--no-folding`, consistent with the
Alacritty, Herdr, and bat packages.

---

### Decision 5: `stow/common/` placement

eza, its config path, and the theme format are identical on macOS and Arch. No
platform-specific values. **Decision: `stow/common/eza/`.**

---

## Risks

- **Stow conflict at activation:** If `~/.config/eza/theme.yml` already exists as a real file,
  Stow refuses. The dry-run step surfaces this; the user resolves manually (no `--adopt`).
- **Directory folding:** Mitigated by mandatory `--no-folding` (Decision 4).
- **Vendored theme drift:** The committed `theme.yml` can age relative to upstream. Low
  impact; re-fetch to refresh (no cache rebuild needed, unlike bat).
- **`EZA_CONFIG_DIR` override:** If the user has `EZA_CONFIG_DIR` pointing elsewhere, the
  stowed `~/.config/eza/theme.yml` will not be read. Documented in the setup guide.

---

## Extensibility

- **Accent/theme change:** Replace `theme.yml` with a different variant; active immediately on
  next eza run (no rebuild).
- **Platform override:** A future `stow/arch/eza/` or `stow/macos/eza/` overlay can be added
  alongside `stow/common/eza/` if a platform-specific need arises.

---

## Open Questions

None blocking. Accent defaulted to Blue (Decision 3); trivially swappable.

---

## Recommended Next Step

Planner: produce an implementation plan for PRD 0014 / Architecture 0014 covering the package
skeleton, vendored `theme.yml`, README + setup guide, root README package-table update, and
fake-home validation — without running Stow against `$HOME`.
