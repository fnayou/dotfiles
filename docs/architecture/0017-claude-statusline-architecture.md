# Architecture: Claude Code Statusline Package

**Number:** 0017
**Status:** Approved
**Date:** 2026-06-24
**PRD:** 0017 (Claude Code Statusline Package)

## Context

PRD 0017 (Approved) asks to track the portable Claude Code status line script
(`~/.claude/statusline-command.sh`) as a Stow package under `stow/common/`, while
excluding every sensitive part of `~/.claude` and reusing the existing `omp` package as
the theme source of truth. A working copy already exists on branch
`feat/claude-statusline-package` (uncommitted); this document gates and may revise it.

`~/.claude/` on the host is a real directory holding credentials (`.credentials.json`),
machine-local settings (`settings.local.json`), session transcripts (`projects/`),
installed plugins (`plugins/`), logs, and caveman runtime files. The package must reach
into this directory and manage exactly one file without exposing the rest.

## Proposed Structure

```
stow/common/claude/
├── .claude/
│   └── statusline-command.sh      # → $HOME/.claude/statusline-command.sh (executable)
├── .stow-local-ignore             # excludes README, VCS, *.bak/*.orig from stowing
└── README.md                      # scope, exclusions, --no-folding install workflow
```

Target after stow:

```
stow/common/claude/.claude/statusline-command.sh
  → $HOME/.claude/statusline-command.sh
```

The package mirrors the layout of existing `stow/common/` packages (`omp`, `eza`, `bat`):
real managed file, package-root `.stow-local-ignore`, package-root `README.md`.

## Design Decisions

### Decision 1: Package category — `common`

```
Option A: stow/common/claude
  Pro: Script is OS-portable (runtime detection of macOS/Arch/EndeavourOS/Linux,
       $HOME-relative). Path ~/.claude/statusline-command.sh identical on both OSes.
  Con: None material — the only per-OS difference (the OS glyph) is resolved at runtime
       inside the one file, not by separate packages.

Option B: split per-OS overlays (common + macos/arch)
  Pro: Could hard-code per-OS icons.
  Con: Pointless duplication; the script already branches on OS at runtime.

Decision: Option A — stow/common/claude. Matches PRD platform analysis.
```

### Decision 2: Single-file scope; never manage the `~/.claude` directory

```
Option A: Package contains only .claude/statusline-command.sh
  Pro: Physically impossible to sweep in credentials/sessions — only the one tracked file
       is ever a stow source. Smallest blast radius.
  Con: settings.json (which wires the status line) stays unmanaged; the wiring is a manual
       one-time step per machine.

Option B: Also manage .claude/settings.json
  Pro: Wires the status line automatically on stow.
  Con: settings.json is rewritten by Claude Code at runtime (model, plugin toggles) and sits
       next to credentials; managing it raises churn and privacy risk. PRD lists it as a
       non-goal.

Decision: Option A — single file. settings.json remains local (PRD non-goal).
```

### Decision 3: `--no-folding` is mandatory for install

```
Context: GNU Stow "folds" a package directory into a single symlink when the target
directory does not already exist — i.e. it would create $HOME/.claude as a symlink to the
repo's .claude/ if ~/.claude were absent. That would shadow the user's real credentials and
session data behind a repo symlink.

Option A: Document install with --no-folding
  Pro: Forces per-file symlinks; stow links only statusline-command.sh and never the
       ~/.claude directory itself. Safe even on a machine where ~/.claude does not yet exist.
  Con: Slightly longer command; must be remembered (so it is encoded in the README).

Option B: Rely on ~/.claude already existing so stow descends instead of folding
  Pro: Works today on the current host.
  Con: Fragile — breaks the safety guarantee on a fresh machine. Unacceptable for a dir
       holding secrets.

Decision: Option A — always --no-folding. Matches the alacritty/zsh precedent in the repo.
```

### Decision 4: Existing-file conflict resolved manually, never with `--adopt`

```
Context: A real ~/.claude/statusline-command.sh already exists on the host, so stow reports
a conflict (confirmed by dry-run). The repo's managed copy is the intended source of truth.

Option A: User manually backs up/removes the real file, then stows
  Pro: Deliberate, reviewable, reversible (user keeps a backup). No silent overwrite.
  Con: Manual step.

Option B: stow --adopt
  Pro: One command.
  Con: Forbidden by repo safety rules — silently overwrites and pulls host content into the
       repo, defeating review. Also risks adopting a drifted host copy over the curated one.

Decision: Option A — manual resolution, documented in the README. --adopt never used.
```

### Decision 5: Theme ownership stays with `omp`; runtime dependencies are expectations, not install steps

The script's colors are chosen to mirror `stow/common/omp/` (Catppuccin Macchiato). `omp`
remains the single theme source of truth; this package only consumes those color values as
literals. Runtime needs (`jq`, `git`) are documented expectations; the optional caveman badge
segment is a guarded no-op when the plugin is absent. This package installs none of them.

## Risks

- **Folding hazard (high if mishandled):** Without `--no-folding`, stow could symlink the whole
  `~/.claude`. Mitigated by Decision 3 and an explicit README warning.
- **Conflict/overwrite (medium):** The existing real file must not be clobbered. Mitigated by
  Decision 4 (manual, backup-first, no `--adopt`).
- **Privacy (low):** Only the status line script is ever a stow source; credentials/sessions are
  never tracked. `.stow-local-ignore` keeps README/backups out of links.
- **Platform drift (low):** OS glyph selection is runtime-detected; a new distro id falls back to
  the generic Linux icon — cosmetic only.
- **Reversibility (low):** Uninstall is `stow --delete`; the user's pre-stow backup restores the
  original file.
- **Status-block drift (low):** Adding the package without stowing it makes the "all packages
  stowed" invariant false; mitigated by recording `claude` as added-but-not-stowed in both blocks.

## Extensibility

- If `settings.json` management is wanted later, it is an additive decision (new file in the same
  package or a separate `claude-settings` package), not a redesign — likely paired with a
  `dark-ansi` theme decision (deferred per the separate theme discussion).
- A future macOS/Arch divergence would still be handled in-script; no package split anticipated.
- The package is a template for managing other single, non-secret files inside otherwise-sensitive
  directories via `--no-folding`.

## Open Questions

- Should the README also point to the Catppuccin browser userstyle / `dark-ansi` option for the
  Claude Code UI theme? Deferred — tracked as a separate follow-up, out of this package's scope.

## Recommended Next Step

Planner: produce `docs/plans/00NN-claude-statusline-plan.md` with ordered, safe steps —
create the three package files, set the executable bit, run the `--no-folding` dry-run, update
both status blocks, and stage for the user-approved commit. Build must not stow to `$HOME`.
