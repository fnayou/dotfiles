# Architecture: Herdr Configuration Stow Package

**Number:** 0012
**Status:** Approved
**Date:** 2026-06-20
**PRD:** [0012-herdr-configuration](../prd/0012-herdr-configuration.md)

---

## Context

PRD 0012 scopes the adoption of the current personal Herdr configuration into the
dotfiles repository as a managed Stow package under `stow/common/`.

Herdr is a cross-platform terminal multiplexer available via `brew install herdr` on
both macOS and Arch/Linux. The config path (`~/.config/herdr/config.toml`) follows the
XDG base directory convention and is identical on both platforms.

The configuration contains:

- Catppuccin Macchiato theme overrides (consistent with the Alacritty package).
- Terminal shell preference (`zsh`), new pane `cwd` behavior (`follow`).
- Deep scrollback buffer (`20000`) tuned for AI generation output.
- UI settings: agent labels on pane borders, sidebar width, Herdr-internal toast delivery.

No secrets, credentials, or platform-specific values are present. All values are safe
personal preferences suitable for direct version control.

One correction applied relative to the original live config:
`delivery = "herdr"` replaces `delivery = "system"` (the live config had a stale value
that tied notifications to macOS Alerts rather than Herdr's own toast UI).

Out of scope for this architecture (per PRD 0012):

- Installing Herdr on any machine.
- Creating symlinks in `$HOME`.
- Herdr keybinding or plugin configuration.
- Platform-split packages (`stow/macos/herdr/`, `stow/arch/herdr/`).
- Activating the Stow package.

---

## Proposed Structure

### Directory layout

```
stow/
└── common/
    └── herdr/
        ├── .stow-local-ignore
        └── .config/
            └── herdr/
                └── config.toml
```

No `stow/macos/herdr/` or `stow/arch/herdr/` packages are created. See Decision 2.

### File inventory

| File | Type | Stowed directly? | Maps to |
|------|------|-----------------|---------|
| `stow/common/herdr/.stow-local-ignore` | Stow metadata | No (consumed by Stow) | — |
| `stow/common/herdr/.config/herdr/config.toml` | Real managed config | Yes | `~/.config/herdr/config.toml` |

### Activation sequence (manual, future)

```bash
# Step 1: Dry run — verify what would be linked
stow --dir=stow --target="$HOME" --simulate herdr

# Step 2: Install — only after reviewing dry-run output
⚠️  MANUAL STEP — run only after approving dry-run output
stow --dir=stow --target="$HOME" herdr
```

After stowing:
`stow/common/herdr/.config/herdr/config.toml` → `~/.config/herdr/config.toml`

---

## Design Decisions

### Decision 1: Real managed file vs. `.example` file

**Option A: Real managed `config.toml` (stow directly)**
- Pro: Simpler activation — no rename step required.
- Pro: Consistent with Alacritty package (PRD 0011), which set the precedent for
  committing real config files when no secrets are present.
- Pro: File is immediately stowable after dry-run approval.
- Con: None identified — config contains only UI preferences and color values.

**Option B: `.example` file (rename before stowing)**
- Pro: Explicit user action required before symlink creation.
- Con: Extra rename step adds friction with no security benefit for a secret-free config.
- Con: Inconsistent with the Alacritty precedent.

**Decision: Option A (real managed file).**
Config contains only UI preferences and Catppuccin color values — no secrets,
credentials, or machine-specific values. The Alacritty package (PRD 0011) established
the convention of committing real files for secret-free configs. A `.stow-local-ignore`
is added at the package root following the same pattern.

---

### Decision 2: `stow/common/` vs. platform-specific placement

**Option A: `stow/common/herdr/`**
- Pro: Herdr is cross-platform — same binary, same XDG config path, same behavior on
  macOS and Arch.
- Pro: No platform-specific values remain after correcting `delivery = "herdr"`.
- Con: None identified.

**Option B: `stow/macos/herdr/` only**
- Pro: Safer if Arch usage is uncertain.
- Con: Requires a copy or migration later when Arch adoption happens.
- Con: Contradicts confirmed cross-platform availability.

**Decision: Option A (`stow/common/herdr/`).**
Herdr runs on both macOS and Arch via Homebrew. All config values are portable.
`delivery = "herdr"` is not OS-specific — it selects Herdr's own toast UI, not a system
notification backend. No rationale for platform separation.

---

### Decision 3: Single file vs. split config

**Option A: Single `config.toml.example`**
- Pro: Matches Herdr's own layout (single config file, no include mechanism needed).
- Pro: Simple to manage and review.
- Con: None identified.

**Option B: Base config + theme file (like Alacritty's two-file layout)**
- Pro: Would separate theme concerns from terminal/ui concerns.
- Con: Herdr does not use a separate theme file — theme overrides live in `config.toml`
  under `[theme.custom]`. Splitting would require a custom include mechanism not
  supported by Herdr.

**Decision: Option A (single file).**
Herdr's config format does not support file includes. Single `config.toml.example` is
the only viable approach.

---

## Risks

- **Stow conflict at activation:** If `~/.config/herdr/config.toml` already exists as a
  real file (not a symlink) when the user runs `stow`, Stow will refuse to create the
  symlink. The dry-run step in the activation sequence surfaces this before it becomes
  a problem. The user must back up or remove the existing file manually.
- **`delivery` value:** The live config had `delivery = "system"`. The managed
  `config.toml` corrects this to `delivery = "herdr"`. If the user has a diverged live
  config, the repository version is authoritative after activation.

---

## Extensibility

- **Future Herdr settings:** New settings (keybindings, plugins) append to the existing
  `config.toml` without changing package structure.
- **Arch-specific override:** If a future Herdr setting proves platform-specific, a
  `stow/arch/herdr/` or `stow/macos/herdr/` override package can be added alongside
  `stow/common/herdr/` without restructuring.

---

## Open Questions

None. All design questions resolved.

---

## Recommended Next Step

Planner: produce an implementation plan for PRD 0012 / Architecture 0012. The plan
should cover:

1. Create `stow/common/herdr/.config/herdr/` directory scaffold.
2. Write `.stow-local-ignore` at `stow/common/herdr/`.
3. Write `config.toml` with corrected `delivery = "herdr"` and all inline comments preserved.
4. Document the activation sequence (dry-run + install) in the plan.
5. Verify no secrets or machine-specific values in the committed file.
