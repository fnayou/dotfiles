# Review: Herdr Full Macchiato Palette and Base Theme Correction

**Number:** 0060
**Status:** Complete
**Date:** 2026-07-31
**Plan reviewed:** None — configuration change (see Process Note)
**Branch:** `feat/herdr-full-macchiato-palette`

**Files reviewed:**

- `stow/common/herdr/.config/herdr/config.toml`
- `docs/guides/herdr-setup.md`

---

## Summary

The user observed that Herdr renders as Catppuccin Macchiato with a blue accent despite
`name = "tokyo-night"`. Investigation confirmed the observation and found two related issues.

**Why it looked Macchiato.** `[theme.custom]` paints over the named base. The config set the two
values that dominate the visible surface — `panel_bg = #24273a` (Macchiato Base, the whole
background) and `accent = #8aadf4` (Macchiato Blue, borders, highlights, navigation) — plus green,
red and yellow. The base theme was barely visible.

**What was still Tokyo Night.** Herdr 0.7.5 exposes eight overridable colour slots — the
`CustomThemeColors` struct in the binary (`accent`, `surface_dim`, `mauve`, `green`, `yellow`,
`red`, `peach`) plus `panel_bg`, documented in Herdr's own default config template. Five were set,
so **`mauve`, `peach` and `surface_dim` were inherited from Tokyo Night**.

**A stale comment.** `# Built-in base: catppuccin (closest to Macchiato palette)` sat directly above
`name = "tokyo-night"` — the comment described the value Plan 0016 specified, and did not follow
when the value changed. Review 0057 accepted the `tokyo-night` divergence without noticing the
comment contradicted it.

Resolved by setting the base to `catppuccin` and filling all eight slots with Macchiato values, on
the user's choice from three presented options.

---

## Change

```toml
[theme]
name = "catppuccin"        # was "tokyo-night"

[theme.custom]
panel_bg    = "#24273a"    # Base       (unchanged)
surface_dim = "#1e2030"    # Mantle     (new)
accent      = "#8aadf4"    # Blue       (unchanged)
mauve       = "#c6a0f6"    # Mauve      (new)
green       = "#a6da95"    # Green      (unchanged)
yellow      = "#eed49f"    # Yellow     (unchanged)
red         = "#ed8796"    # Red        (unchanged)
peach       = "#f5a97f"    # Peach      (new)
```

Every hex value is from the official Catppuccin Macchiato palette. Herdr has no `macchiato`
built-in — it ships `catppuccin`, `catppuccin-latte` and `catppuccin-mocha` — which is why Plan 0016
described `catppuccin` as "closest" and layered overrides on top. With all eight slots set, the base
choice now only affects colours Herdr does not expose, and those stay in the Catppuccin family
rather than falling back to Tokyo Night.

Validated: `herdr config check` → `config: ok` (rc=0); `tomllib` parses; 8/8 slots present.

---

## Blocking Issues

None.

---

## Non-Blocking Suggestions

- **`surface_dim = "#1e2030"` (Mantle) is a judgement call.** Herdr does not document what the slot
  paints, and the name only suggests a dimmed surface. Mantle is the conventional Macchiato choice
  one step darker than Base. If it reads too dark in practice, Surface0 (`#363a4f`) is the obvious
  alternative — a one-value edit, applied instantly through the existing symlink.

- **Not visually verified.** Correctness here is established from the palette values and Herdr's
  accepted config, not from looking at the rendered UI. The user should confirm the result looks
  right.

- **`config.toml` is stowed, so the change is already live**, but a running Herdr server holds the
  old values until `herdr server reload-config` or a restart.

---

## Safety Verdict

**PASS** — Two files changed, both configuration and documentation. No `stow`, `rm`, `mv`, or
`ln -s` against `$HOME`; no file outside the repository modified. No install commands added, so no
`⚠️  MANUAL STEP` markers were needed.

## Privacy Verdict

**PASS** — Colour hex codes and comments only. No credentials, tokens, hostnames, or personal data.

## Documentation Verdict

**PASS** — The guide's configuration table now lists the base theme accurately, names all eight
overridden slots, and explains why `catppuccin` rather than a macchiato variant. The misleading
comment in `config.toml` is replaced with one that matches the value beneath it and states what the
base still governs.

---

## Process Note

Configuration change driven by a user observation, not a defect report — no PRD, Architecture or
Plan, consistent with reviews 0054 through 0059. Written before the commit. The user chose the
approach from three options (correct the comment only; keep `tokyo-night` and fill all slots; switch
base and fill all slots) and selected the last.

---

## Recommended Next Action

Approve and merge, then reload Herdr and confirm the palette reads correctly.
