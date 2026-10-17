# Review: Ghostty Configuration PRD and Architecture

**Number:** 0080
**Status:** Complete
**Date:** 2026-10-17
**Documents reviewed:**
- `docs/prd/0028-ghostty-configuration.md`
- `docs/architecture/0026-ghostty-configuration-architecture.md`

## Summary

Reviewed PRD 0028 (Approved, amended with Decision 11) and Architecture 0026 (Approved) for the
Ghostty configuration change: a common package `stow/common/ghostty/` and a macOS-only icon package
`stow/macos/ghostty/`. Ghostty was not run during this review.

The architecture carries PRD Decisions 1–11 over without re-opening them. File names, option
values, and the Stow commands agree between the two documents. All 18 hex values in the planned
`themes/catppuccin-macchiato` match
`stow/common/alacritty/.config/alacritty/catppuccin-macchiato.toml`, key for key, as listed in the
PRD theme mapping. The planned `.stow-local-ignore` matches `stow/common/alacritty/.stow-local-ignore`
exactly. The status-block wording points to `stow/common/` and `stow/macos/` and names one
not-yet-stowed exception, which is consistent with `.claude/rules/status-sync.md` and ADR 0048.

Two documentation defects block the Build: dangerous commands without the `⚠️  MANUAL STEP` marker on
the line directly before the fence, and an incomplete list of `README.md` statements that the Build
makes false.

## Blocking Issues

1. **Dangerous commands not fenced per `.claude/rules/documentation.md`.** The rule requires the
   marker on the line directly preceding the code block fence. The repository precedent
   (`docs/guides/alacritty-setup.md:37-48`) marks package installs as `⚠️  MANUAL STEP`.
   - Marker missing:
     - `docs/prd/0028-ghostty-configuration.md:128-131`: `brew install --cask ghostty`
     - `docs/prd/0028-ghostty-configuration.md:135-138`: `sudo pacman -S ghostty`
     - `docs/prd/0028-ghostty-configuration.md:201-207`: both font installs
     - `docs/architecture/0026-ghostty-configuration-architecture.md:396-405`: the guide's
       prerequisite fences. The prose says the guide will carry the marker, but the architecture
       shows the fences without it.
   - Marker separated from the fence by a blank line:
     - `docs/prd/0028-ghostty-configuration.md:320-322` and `:338-340`
     - `docs/architecture/0026-ghostty-configuration-architecture.md:764-766`, `:779-781`, and
       `:791-793`

   Fix: put `⚠️  MANUAL STEP — review before running` on the line immediately above each fence.
2. **The `README.md` change list is incomplete.** Architecture 0026 lists the README edits as the
   package-table row, the guide link, and the status lines (`:117`, `:475-476`). After the Build
   adds `stow/macos/ghostty/`, three more README statements become false:
   - `README.md:33-34`: "`stow/macos/`, `stow/arch/`, and `stow/debian/` … are currently empty"
   - `README.md:105`: `macos/          macOS-specific packages (empty)`
   - `README.md:24`: `Managed packages: see stow/common/`. Per ADR 0048, this pointer should name
     `stow/macos/` once that directory is populated.

   The "Documentation and Website Mentions" table (`:487-505`) selects pages that mention
   Alacritty. It only covers pages that say `stow/macos/` is empty when those pages also mention
   Alacritty. Fix: add these README lines to the inventory, and extend the page sweep to every page
   that says `stow/macos/` is empty.

## Non-Blocking Suggestions

1. The PRD Target Structure (`docs/prd/0028-ghostty-configuration.md:83-98`) does not show the
   common package's `.stow-local-ignore` and `README.md`. Decision 11 and the architecture both
   assume these files exist. Align the PRD tree with architecture `:65-83`.
2. `macos-option-as-alt` and `macos-icon` in the common `config.ghostty` depart from
   `.claude/rules/cross-platform.md`: "Do not mix OS-specific settings into common/shared config
   files". The departure is documented and follows the Alacritty `option_as_alt` precedent (PRD
   Decision 1). `stow/macos/ghostty/` now exists, so an optional include such as
   `config-file = ?macos.ghostty`, shipped by the macOS package, would satisfy the rule exactly. It
   would also remove the "`macos-icon = custom` with no icon present" risk. This is the operator's
   decision; it does not block.
3. Dry-run expectations (architecture `:410-414`): a plain `stow --simulate` may print only the
   simulation warning, not `LINK:` lines, unless it runs with `-v`. The Alacritty guide makes the
   same assumption. Verify in Build, and add `-v` to the dry-run if needed.
4. Validation check 7 (architecture `:746-751`) does not define its "fake-home launch". Launching
   `Ghostty.app` writes app state under `~/Library` even when `XDG_CONFIG_HOME` is set, so "without
   touching `$HOME`" may not hold. It is also unconfirmed whether the default for
   `macos-custom-icon` follows `XDG_CONFIG_HOME` or the literal `~`. The plan must give the exact
   invocation, or make check 7 an operator-run step.
5. Validation check 3 (architecture `:660-692`) cleans up only its `mktemp -d` directory, which is
   correct. Harden it anyway: use `FAKE_HOME="$(mktemp -d)" || exit 1` and
   `rm -rf "${FAKE_HOME:?}"`, so that an empty variable never reaches `stow --target` or `rm`.
6. Verify in Build. The options and behaviors below could not be confirmed from the documents
   because Ghostty was not run during review. The PRD states that they were checked against
   `ghostty +show-config --default --docs` (1.3.1).
   - Option names: `macos-icon = custom`, and the `macos-custom-icon` default
     `~/.config/ghostty/Ghostty.icns`.
   - Search colors: `search-background`, `search-foreground`, `search-selected-background`,
     `search-selected-foreground`.
   - Other options: `window-padding-balance`, `adjust-cell-height`, `cursor-text`,
     `selection-foreground`, `faint-opacity`, `background-opacity-cells`, and `config-default-files`
     (PRD Decision 2).
   - Key names `arrow_left`, `enter`, and `numpad_<key>`, and the `text:\n` escape.
   - Whether `command = /bin/zsh -l` runs through `/bin/sh -c`.
   - The `+validate-config --config-file=` form, and whether it also loads the default config
     files.
   - Whether theme lookup honours `XDG_CONFIG_HOME` on macOS.
7. Icon licence: AGENTS.md §1 says the repository is public. An icon with an unknown licence stays
   in git history even after deletion. This is recorded and accepted by the operator (PRD Decision
   11). Before the Build commit, consider confirming the licence on macosicons.com, or keeping the
   icon local and ignored by git if no licence is found.
8. The proposed `CLAUDE.md` bullet (architecture `:472`) nests two em-dash clauses ("including
   `codex` — … — except `ghostty`"). That is hard to parse. Split it into two sentences; keep the
   meaning.

## Safety Verdict

PASS — neither document has an agent write to `$HOME`, use `--adopt`, or run a Stow install.
Every Stow install is preceded by a `--simulate` dry run. The macOS Application Support file and
the signed app bundle are explicitly left untouched. The icon source is copied read-only. The
fake-home validation removes only its own `mktemp -d` directory.

## Privacy Verdict

PASS — the planned files contain display and key preferences only. They contain no secrets,
hostnames, or user-specific paths: `~` and `$HOME` are used, plus placeholders in the guide. The
icon's unknown licence is recorded with its source and SHA-256, and the operator accepted it.

## Cross-Platform Verdict

PASS — macOS, Arch, and Debian are treated separately. The macOS-only icon lives in
`stow/macos/ghostty/`. Arch stows only the common package. Debian stows neither. The `macos-*`
options in the common file are a documented, precedent-backed exception (see suggestion 2).

## Documentation Verdict

FAIL — dangerous commands lack the `⚠️  MANUAL STEP` marker on the line directly before the fence
(Blocking Issue 1). The architecture's `README.md` change list leaves three statements that the
Build makes false (Blocking Issue 2).

## Recommended Next Action

Architect: amend PRD 0028 and Architecture 0026 to fix both blocking issues, then return them to
the Reviewer for re-review. The operator re-approves the amended architecture before the Planner
writes the implementation plan. The operator should also decide on suggestion 2 (an optional
macOS include) before planning.
