# Review: btop Configuration Implementation

**Number:** 0053
**Date:** 2026-07-03
**Reviews:** Plan [0023-implement-btop-configuration.md](../plans/0023-implement-btop-configuration.md)
(PRD [0020](../prd/0020-btop-configuration.md))

## Summary

Reviewed the implementation of Plan 0023 — the `stow/common/btop/` package (Catppuccin Macchiato,
blue) plus package-list, website, guide, and status-block updates. The package mirrors the existing
bat/eza/alacritty pattern: vendored theme file, small managed `btop.conf`, `.stow-local-ignore`,
README, and a human setup guide.

Verified:
- Four package files present under `stow/common/btop/`.
- Shipped theme byte-identical to upstream catppuccin/btop `catppuccin_macchiato.theme` apart from
  a single added trailing newline (benign; POSIX text-file convention).
- `stow --dir=stow/common --target="$HOME" --no-folding --simulate -v btop` → two `LINK:` lines,
  expected `MKDIR:` lines, no conflicts, exit 0. `~/.config/btop` does not yet exist on host.
- btop added to `packages/Brewfile`, `packages/arch/packages.txt`, `packages/debian/packages.txt`.
- Website `features/packages.md` (new section) and `features/index.md` (row + shared-thread list)
  updated.
- Both status blocks (`AGENTS.md` §2, `CLAUDE.md`) updated in this same change, softened to record
  btop as added-but-not-yet-stowed.

## Blocking Issues

- None.

## Non-Blocking Suggestions

- The catppuccin/btop port has no accent selector; if the user ever wants a non-blue accent it
  requires hand-editing the `.theme` file. Documented in the PRD, guide, README, and website.
- `stow/common/btop/` is intentionally left unstowed (safety rule). The user runs the documented
  dry-run → apply to activate; the status blocks must return to "all stowed" wording once they do.

## Safety Verdict

PASS — No `stow`, `ln -s`, `rm`, or `mv` against `$HOME` was run. Only `stow --simulate` (read-only)
was executed. `--no-folding` and the `--adopt` prohibition are documented. All host changes are
deferred to the user.

## Privacy Verdict

PASS — Config and theme contain only styling/behaviour values. Secret scan of the new files found
no credentials, tokens, keys, or machine-specific paths.

## Documentation Verdict

PASS — Setup guide, README, PRD, and plan are consistent and copy-pasteable. Dangerous/manual
commands carry the `⚠️  MANUAL STEP` marker. Cross-platform install commands are labelled per OS.

## Recommended Next Action

Commit the change (single commit; status blocks move with the package). Then, on each machine, the
user runs the dry-run → apply from `docs/guides/btop-setup.md` and — once stowed — the status blocks
can be restored to the plain "all stow/common/ packages stowed" wording.
