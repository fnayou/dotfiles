# Plan: Implement btop Configuration

**Number:** 0023
**Status:** Done
**PRD:** [0020-btop-configuration.md](../prd/0020-btop-configuration.md)
**Date:** 2026-07-03

## Objective

Add a `stow/common/btop/` package that vendors the Catppuccin Macchiato (blue) theme and a small
managed `btop.conf`, following the established bat/eza/alacritty package pattern. Update package
lists, docs, website, and both status blocks. Do not stow.

## Assumptions

- btop is (or will be) installed by the user via their platform package manager.
- `~/.config/btop/` may not yet exist on the host; stow will create it with `--no-folding`.

## Ordered Tasks

1. Create `stow/common/btop/.config/btop/themes/catppuccin_macchiato.theme` verbatim from
   [catppuccin/btop](https://github.com/catppuccin/btop).
2. Create `stow/common/btop/.config/btop/btop.conf` — active theme + commented tweakables.
3. Create `stow/common/btop/.stow-local-ignore` (copy of bat/eza ignore).
4. Create `stow/common/btop/README.md` (mirror bat/eza README).
5. Add btop to `packages/Brewfile`, `packages/arch/packages.txt`, `packages/debian/packages.txt`.
6. Add a btop section to `website/features/packages.md`; update `website/features/index.md`.
7. Create `docs/guides/btop-setup.md` (human setup guide, mirror eza-setup.md).
8. Update the status blocks in `AGENTS.md` §2 and `CLAUDE.md` in the same commit.

## Files Affected

- `stow/common/btop/**` — created (4 files).
- `packages/Brewfile`, `packages/arch/packages.txt`, `packages/debian/packages.txt` — modified.
- `website/features/packages.md`, `website/features/index.md` — modified.
- `docs/guides/btop-setup.md` — created.
- `docs/prd/0020-btop-configuration.md`, `docs/reviews/0053-btop-implementation-review.md` — created.
- `AGENTS.md`, `CLAUDE.md` — status blocks modified.

## Safety Checks

- No `stow`, `ln -s`, `rm`, or `mv` against `$HOME`.
- Theme/config contain no secrets or machine-specific values.
- `stow --simulate` reports no conflicts before any user apply.

## Validation Commands

```bash
# Package files present
find stow/common/btop -type f

# Shipped theme identical to upstream
diff <(curl -fsSL https://raw.githubusercontent.com/catppuccin/btop/main/themes/catppuccin_macchiato.theme) \
     stow/common/btop/.config/btop/themes/catppuccin_macchiato.theme

# Dry-run — expect two LINK lines, no conflicts, exit 0
stow --dir=stow/common --target="$HOME" --no-folding --simulate -v btop
```

## Rollback Strategy

The change is additive and unstowed. To undo before commit: delete `stow/common/btop/` and revert
the edits to package lists, website, guides, and status blocks. Nothing in `$HOME` is touched.

## Completion Criteria

All PRD 0020 acceptance criteria checked; dry-run clean; reviewer verdicts PASS.
