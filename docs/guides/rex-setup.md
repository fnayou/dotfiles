# Rex Package Setup Guide

This guide explains how to give [Rex](https://www.superlogical.com/rex/) the Catppuccin Macchiato theme with a blue accent. It is written for a human user, not for implementation agents.

Rex is a beta. Setting names, action names and where Rex stores themes can change between builds. This guide was written against **Rex Beta 0.1.0** on macOS.

---

## 1. What this package manages

The `stow/common/rex/` package holds one file:

| Repository file | Optional symlink at | Purpose |
|---|---|---|
| `stow/common/rex/.config/rex/themes/catppuccin-macchiato-blue` | `~/.config/rex/themes/catppuccin-macchiato-blue` | Ghostty-format theme: Catppuccin Macchiato palette, blue `#8aadf4` cursor and selection |

Rex does **not** read that path by itself. Rex keeps imported themes in its own app preferences and has no `init.lua` setting for a theme, so the file is an **import source**. Stowing it is optional: you can import straight from the repository checkout.

The theme file is the same palette as `stow/common/ghostty/.config/ghostty/themes/catppuccin-macchiato` (ADR 0068). Only `cursor-color` and `selection-background` differ: blue instead of rosewater.

---

## 2. Platform notes

- [macOS] Rex Beta runs on macOS here. The Settings paths below and Rex's preferences under `~/Library/` are macOS-only.
- [Arch] [Debian] Rex ships Linux packages, but this repository does not use Rex there. The theme file itself is platform-neutral.
- Installing Rex is out of scope for this guide.

---

## 3. Before you start

- Rex ships a migrated copy of the Ghostty `catppuccin-macchiato` theme on first launch if you use Ghostty. Keep it: it is your rollback target.
- Check the Rex build in **Settings > Developer > App Version**. This guide assumes 0.1.0.

---

## 4. Import the theme

Pick one way. Both are run by you inside Rex. Nothing in this repository imports the theme for you.

### Option A: Settings

1. Open **Settings > Themes > Import Theme**.
2. Choose `stow/common/rex/.config/rex/themes/catppuccin-macchiato-blue` from your checkout of this repository, or `~/.config/rex/themes/catppuccin-macchiato-blue` if you stowed it (section 7).

### Option B: Command palette

1. Open the command palette and run **Import Theme File** (action `client.theme.import`).
2. Pick the same file when Rex asks for it (the action takes the file's absolute path).

Rex selects the theme right after the import. If you import the same file twice, Rex may keep both entries; delete the old one in **Settings > Themes** first.

---

## 5. Select the theme

Open **Settings > Themes > Dark Mode** and choose `catppuccin-macchiato-blue` as the dark theme. Leave the light theme alone: this package has no light variant.

---

## 6. Set the accent controls by hand

The theme file carries the accent in the cursor, the selection and the blue ANSI slots. Two Rex settings sit outside the theme and **cannot be tracked in this repository**:

| Setting | Menu path | Value |
|---|---|---|
| Highlight color | Settings > Interface > Active Pane | The blue palette swatch |
| Shell icon theme | Settings > Interface > Tabs | Use theme accent |

Optional: **Settings > Interface > Appearance > Tint with theme** applies the theme's colors to interface surfaces.

---

## 7. Optional: stow the theme file

Only do this if you want the file at `~/.config/rex/themes/`. It does not change Rex.

`~/.config/rex/` may already contain a real `init.lua`. Stow with `--no-folding` so it links the file and leaves `init.lua` alone.

1. Dry run, from the repository root:

```bash
stow --dir=stow/common --target="$HOME" --no-folding --simulate rex
```

2. If the output lists only `.config/rex/themes/catppuccin-macchiato-blue` and no conflict, install:

⚠️  MANUAL STEP — run only after reviewing the dry-run output
```bash
stow --dir=stow/common --target="$HOME" --no-folding rex
```

If the dry run reports a conflict, stop and resolve it by hand. Never use `stow --adopt`.

---

## 8. Check the result

- Background is the dark Macchiato base (`#24273a`), text is `#cad3f5`.
- The cursor and selection are blue, not rosewater.
- Blue in `ls`, git and prompt output matches your other terminals.
- The active pane edge is blue, and tab shell icons use the accent.

---

## 9. Rollback

1. Select the migrated `catppuccin-macchiato` theme (or any other) in **Settings > Themes > Dark Mode**.
2. Delete the `catppuccin-macchiato-blue` entry in **Settings > Themes**.
3. Put the two accent settings in section 6 back to your previous values.
4. If you stowed the file, dry-run the removal first:

```bash
stow --dir=stow/common --target="$HOME" --no-folding --simulate -D rex
```

⚠️  MANUAL STEP — run only after reviewing the dry-run output
```bash
stow --dir=stow/common --target="$HOME" --no-folding -D rex
```

---

## 10. After a Rex update

Re-check the menu paths in section 6 and the import step. If Rex adds a theme folder or an `init.lua` theme key, the setup can become automatic; see ADR 0086 for why it is manual today.
