# Plan: Rex Catppuccin Macchiato Theme with Blue Accent

**Number:** 0038
**Status:** Complete
**Date:** 2026-11-04
**PRD:** [0034](../prd/0034-rex-catppuccin-macchiato-theme.md)
**Architecture:** [0030](../architecture/0030-rex-catppuccin-macchiato-theme-architecture.md)

## Objective

Add the `stow/common/rex` package with a Catppuccin Macchiato theme file in Ghostty format (blue
`#8aadf4` cursor, selection and blue ANSI slots), plus a setup guide and decision record, without
stowing it or changing any Rex setting.

## Assumptions

- PRD 0034 and Architecture 0030 are Approved.
- The owner confirmed that Rex's accent follows the cursor and the blue ANSI slot, so the theme file
  carries the accent. The Active Pane highlight and shell icon settings stay manual.
- The package is **not** stowed by this plan. Activation (import into Rex, Settings changes, optional
  stow) is a user-run step documented in the guide.
- The next free numbers are ADR `0086` and review `0NNN` (the Reviewer takes the next review number).
- Rex Beta 0.1.0 is the tested build.
- The uncommitted change to `stow/common/herdr/.config/herdr/config.toml` is unrelated and is not part
  of this work.

## Ordered Tasks

1. **Create the theme file** `stow/common/rex/.config/rex/themes/catppuccin-macchiato-blue`, in Ghostty
   format. Copy the palette, `background`, `foreground` and search colors from
   `stow/common/ghostty/.config/ghostty/themes/catppuccin-macchiato`. Differences from that file:
   `cursor-color = #8aadf4`, `selection-background = #8aadf4`, `cursor-text` and `selection-foreground`
   stay `#24273a`. Header comment names the shared source (ADR 0068), the two differing keys and the
   Rex version tested.
2. **Create `stow/common/rex/.stow-local-ignore`** with the same patterns as the Alacritty package, so
   `README.md` is never linked.
3. **Create `stow/common/rex/README.md`**: purpose, file-to-target table, a pointer to the guide, and
   the note that activation is manual.
4. **Write the setup guide** `docs/guides/rex-setup.md`, with `[macOS]` labels and `MANUAL STEP`
   markers, covering:
   1. Check the build (`rex version`, Settings > Developer > App Version).
   2. Import the theme, in either of two ways, both run by the user: Settings > Themes > Import Theme,
      or `client.theme.import` with the absolute path of the repository file.
   3. Select it under Settings > Themes > Dark Mode.
   4. Set the accent controls by hand: Interface > Active Pane > Highlight color to the blue palette
      swatch, and Interface > Tabs > Shell icon theme to "Use theme accent". State that neither can be
      tracked in the repository.
   5. Optional stow of the file to `~/.config/rex/themes/`: dry run first (`stow --simulate`), then
      the `MANUAL STEP` install, no `--adopt`.
   6. Visual check list, and a note that Rex may keep the old entry when a theme is imported twice.
   7. Rollback: select the previously migrated `catppuccin-macchiato` theme; delete the imported entry
      in Settings > Themes; unstow with a dry run first.
   8. Beta caveat and what to re-check after a Rex update.
5. **Write ADR `docs/decisions/0086-rex-theme-imported-manually.md`** (Accepted): the theme is a
   tracked import source; activation is manual because Rex stores themes in its app preferences and
   exposes no `init.lua` theme key. Add its row to `docs/decisions/README.md`.
6. **Update the docs index**: add a `rex` row to the package table in `README.md`, add `rex` to the
   per-package setup guide list, add the guide to `zensical.toml` navigation, and add the matching
   website feature entry as the btop commit did (`website/features/terminal.md`, `website/features/index.md`
   if it carries a package count).
7. **Update the status blocks** in `AGENTS.md` §2 and `CLAUDE.md` in the same change set. State that
   `stow/common/rex` is present but not stowed until the user stows it, as for `codex`. Keep the
   prose-only form and no per-package list (status-sync rule).
8. **Validate** (all read-only, see Validation Commands): palette lines match the Ghostty theme except
   the two blue keys; dry run against a fake home; `task check:decisions`; `task brand:check`; privacy
   audit of the diff.
9. **Review.** The Reviewer runs the `review-change` skill, writes the report under `docs/reviews/`,
   and marks this plan Complete only after a PASS with no blocking issues.
10. **User validation (manual).** The user imports the theme, sets the two accent settings, confirms
    the result visually, and reports back. The result is added to the guide's "tested" note.
11. **Ship** with the `ship-change` skill on branch `feat/rex-theme`, staging only the paths in Files
    Affected (not the herdr change), as one Conventional Commit and a PR.

## Files Affected

- `stow/common/rex/.config/rex/themes/catppuccin-macchiato-blue` — created
- `stow/common/rex/.stow-local-ignore` — created
- `stow/common/rex/README.md` — created
- `docs/guides/rex-setup.md` — created
- `website/guides/rex-setup.md` — created (identical copy; the site navigation reads `website/guides/`)
- `docs/decisions/0086-rex-theme-imported-manually.md` — created
- `docs/decisions/README.md` — modified (index row)
- `README.md` — modified (package row, guide list)
- `zensical.toml` — modified (navigation)
- `website/features/terminal.md` — modified (Rex section)
- `website/features/index.md`, `website/index.md`, `website/reference/stow.md` — modified (terminal lists, package tree)
- `AGENTS.md` — modified (status block)
- `CLAUDE.md` — modified (status block)
- `docs/prd/0034-rex-catppuccin-macchiato-theme.md` — already created; ships in the same PR
- `docs/architecture/0030-rex-catppuccin-macchiato-theme-architecture.md` — already created; ships in the same PR
- `docs/plans/0038-rex-catppuccin-macchiato-theme.md` — this file
- `docs/reviews/` — one review report created by the Reviewer
- `brand/generated/` — regenerated only if `task brand:check` reports stale art
- Nothing is deleted.

## Safety Checks

- Before starting: `git status` shows only the three approved documents and the unrelated herdr change.
- No `stow` install, `ln -s`, `rm` or `mv` runs anywhere in this plan. Only `stow --simulate` against a
  fake home (ADR-0017).
- No `rex` command that changes state runs (no `config reload`, `client.theme.import`, `set_theme`,
  `client.action`). Read-only `rex` inspection is allowed.
- `~/.config/rex/init.lua`, `~/Library/Application Support/rex/` and
  `~/Library/Preferences/com.superlogical.rex.plist` are not edited. Their contents (account, host,
  server, session and theme IDs) are not copied into the repository.
- Guide examples use placeholders and a repo-relative path, not `/Users/<name>/`.
- Staged diff audited for secrets and `.DS_Store` before commit.

## Validation Commands

```bash
git status --short                                   # only expected paths
# Task 1: same palette as the Ghostty theme, apart from the intended differences
diff <(grep -E '^(background|foreground|palette|search-)' stow/common/ghostty/.config/ghostty/themes/catppuccin-macchiato) \
     <(grep -E '^(background|foreground|palette|search-)' stow/common/rex/.config/rex/themes/catppuccin-macchiato-blue)
grep -E '^(cursor|selection)-' stow/common/rex/.config/rex/themes/catppuccin-macchiato-blue
# Tasks 2-3: package shape
ls -a stow/common/rex stow/common/rex/.config/rex/themes
# Stow dry run in a fake home, no real $HOME touched
FAKE=$(mktemp -d) && stow --dir=stow/common --target="$FAKE" --simulate rex && find "$FAKE" -maxdepth 4
# Tasks 5-7
task check:decisions
task brand:check
grep -n "rex" README.md zensical.toml AGENTS.md CLAUDE.md
# Privacy audit of the staged diff
git diff --staged | grep -iE "password|token|api[_-]?key|secret|BEGIN.*PRIVATE|/Users/|/home/"
git diff --staged --name-only | grep -i ds_store
```

The `diff` is expected to print nothing for the palette lines; the `grep` shows the four cursor and
selection lines. The privacy audit must return nothing real.

## Rollback Strategy

Nothing outside the repository changes before Task 10, so rollback is git only:

- Before commit: `git restore --staged --worktree -- <path>` for modified files; delete the new
  files created by this plan (all are untracked and inside the repository).
- After commit, before push: `git reset HEAD~1`.
- After push: close the PR, or `git revert` the commit.
- If the user already imported the theme in Rex: select the migrated `catppuccin-macchiato` under
  Settings > Themes > Dark Mode and delete the imported entry. If the file was stowed, run
  `stow --dir=stow/common --target="$HOME" --simulate -D rex` first, then the `MANUAL STEP` delete.

## Completion Criteria

- [ ] The theme file exists; its palette lines match the Ghostty Macchiato theme; the cursor and
      selection backgrounds are `#8aadf4`.
- [ ] `stow/common/rex` has `.stow-local-ignore` and `README.md`; the fake-home dry run lists only
      `.config/rex/themes/catppuccin-macchiato-blue`, with no conflicts.
- [ ] `docs/guides/rex-setup.md` covers import, selection, the manual accent settings, optional stow
      with a dry run, rollback and the beta caveat.
- [ ] ADR 0086 is added and indexed; `task check:decisions` passes.
- [ ] `README.md`, `zensical.toml`, website pages, `AGENTS.md` and `CLAUDE.md` are updated and agree.
- [ ] `task brand:check` passes, or the generated art is regenerated and staged.
- [ ] No Rex account, host, server, session or theme identifiers appear in the repository.
- [ ] The Reviewer returns PASS for safety, privacy and documentation, and marks this plan Complete.
- [ ] The user confirms the theme looks right in Rex.
