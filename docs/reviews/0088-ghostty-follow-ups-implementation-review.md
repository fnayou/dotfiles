# Review: Ghostty Follow-ups Implementation

**Number:** 0088
**Status:** Complete
**Date:** 2026-10-17
**Plan reviewed:** [0032-ghostty-follow-ups](../plans/0032-ghostty-follow-ups.md)
**PRD:** [0028-ghostty-configuration](../prd/0028-ghostty-configuration.md)
**Architecture:** [0026-ghostty-configuration-architecture](../architecture/0026-ghostty-configuration-architecture.md)
**Commits reviewed:** `af8730a` (plan), `4450a67`, `69563b4`, `e662326` (branch `feat/ghostty-package`, since `e9547f7`)

## Summary

Reviewed the implementation of Plan 0032 — Ghostty Follow-ups — Doctor, Task Dry-Run, Palette
Wording (Task 7.1). The branch makes `scripts/doctor.sh` check the platform area `stow/<os>/` in
addition to `stow/common/`, updates `docs/guides/doctor.md` for platform areas, fixes the stale
`task dry-run` description in `Taskfile.yml`, and names Ghostty next to Alacritty in four
terminal-colour lines.

Every diff in the three implementation commits was compared with the plan's Tasks 1–4. The full
`scripts/doctor.sh` at `4450a67` was read for the "Stow linkage" and "Directory folding" sections
and for where `OS` is set. The range `e9547f7..e662326` touches exactly the 11 files the plan lists
under "Files Affected" (excluding review 0088, added by this review).

The Builder results below come from the foreman's results file for this plan. It was read in full.
It holds a summary, not raw output; it is recorded faithfully.

Plan 0032 — Ghostty Follow-ups is complete.

## Blocking Issues

None.

## Non-Blocking Suggestions

1. **Two rewrapped lines exceed the paragraph width.** `docs/guides/codex-setup.md:23` and
   `stow/common/codex/README.md:65` grew past the surrounding ~100-column wrap after "Alacritty and
   Ghostty". Rendering is unaffected. Rewrap them in a later docs change if line width matters.
2. **Architecture 0026 still quotes the old wording.** `docs/architecture/0026-ghostty-configuration-architecture.md:530`
   quotes "Alacritty owns terminal colors" as the finding that motivated the change. It is a
   historical record, not a user-facing statement, so no edit is needed.
3. **Results file is a summary.** The foreman's results file records outcomes (`PASS:` lines, exit
   codes), not the raw `diff` and `grep` output of Tasks 1–4. The recorded lines match the plan's
   expectations exactly; raw output would make the next review independently checkable.
4. **Out-of-scope items stay open.** `website/reference/troubleshooting.md:58-63` still hardcodes
   `--dir=stow/common` (review 0086 suggestion 14), and the primary-checkout restow after merge
   (review 0085 suggestion 3) is still pending. Both are recorded in Plan 0032 "Out of Scope".

## Builder Results

From the foreman's results file:

- Baseline: `before.txt` `exit=0` (128 lines).
- After edit: `exit=0`; `PASS: non-ghostty output unchanged`; `PASS: syntax`; `DONE: area glob`.
- Ghostty and count lines: `INFO: repo: /path/to/dotfiles.feat-ghostty-package`;
  `PASS: ghostty (2/2 linked)`; `PASS: macos/ghostty (1/1 linked)`;
  `INFO: 2 of 13 package(s) stowed`; `PASS: ~/.config/ghostty is a real directory`.
- `task --list` shows the new dry-run description; `task dry-run AREA=macos PACKAGE=ghostty`
  `exit=0`; `nvim` `luafile colorscheme.lua` `exit=0`.
- `docs/guides/doctor.md` markers directly above fences (lines 102, 122); 2 `stow/<area>`
  commands.
- Commits: `af8730a` plan and reviews, `4450a67` doctor, `69563b4` task, `e662326` wording.
  Pre-commit checks PASS for each; the commit 1 privacy matches are the plan's own pattern line and
  review prose (accepted per Task 5).

The `INFO: repo:` line shows the lane path because doctor ran from the lane (Plan 0032
"Assumptions"). It is local output and is not committed anywhere.

## Checks

### `scripts/doctor.sh` (`4450a67`)

| Check | Result | Evidence |
|---|---|---|
| Stays read-only | Met | Only loop structure, labels, the hint `--dir`, and the folding test change; no new command touches `$HOME`; header "READ-ONLY" unchanged |
| Common output unchanged (labels, order, messages) | Met | `label=$pkg` for `common`; `common` iterates first, as before; every message string is the same except `$pkg` → `$label`; Builder `PASS: non-ghostty output unchanged` |
| Platform label only in PASS/FAIL/SKIP text | Met | `$label` used only in `skip`, `pass`, `fail`; `note` lines use `~/$rel` and `$pkg` |
| Bare `$pkg` in the stow hint | Met | `stow --dir=stow/$area … --simulate $pkg` |
| Folding check counts once | Met | One `[[ common || $OS ]]` test, one `folding_checked` increment per directory; Builder shows `~/.config/ghostty is a real directory` once |
| Area glob safe for `.gitkeep`-only areas | Met | `stow/<area>/*/` matches no directory there; an unmatched glob stays literal and fails `[[ -d ]]`, so it is skipped; Builder `DONE: area glob` with no `FAIL:` |
| Safe for `OS=unknown` | Met | `OS` is always set (lines 67–74) before "Stow linkage"; `case` adds no area for `unknown`; folding tests `stow/unknown/…`, which does not exist |

### `docs/guides/doctor.md` (`4450a67`)

| Check | Result | Evidence |
|---|---|---|
| Platform areas described | Met | "Platform-area packages (`stow/<os>/`) are checked only on their own OS and reported as `<area>/<package>`" |
| `stow/<area>` placeholders | Met | Both re-stow commands use `--dir=stow/<area>` (2 matches) |
| Markers directly above fences | Met | Re-stow install (marker line 102, fence 103) and `chsh` (marker line 122, fence 123); blank lines removed |
| Foreign-checkout sentence | Met | "A package whose links all point into another checkout shows `SKIP: <pkg> (not stowed — …)` instead of this finding." |

### `Taskfile.yml` (`69563b4`)

Met. The `dry-run` `desc:` is exactly the plan's new line:
`AREA=<common|macos|arch|debian> PACKAGE=<name> (packages: task list)`. Behaviour unchanged (no
`--no-folding` change).

### Wording (`e662326`)

| File | Result |
|---|---|
| `docs/guides/codex-setup.md:23` | Met — "Alacritty and Ghostty own terminal colors" |
| `stow/common/codex/README.md:65` | Met — "Alacritty and Ghostty still own terminal ANSI colors" |
| `stow/common/nvim/README.md:5` | Met — "(alacritty / ghostty / zsh / oh-my-posh / bat / eza)" |
| `stow/common/nvim/.config/nvim/lua/custom/plugins/colorscheme.lua:2` | Met — comment only |

Four files, one changed line each. `git grep` at `HEAD` finds no other "Alacritty owns",
"Alacritty still owns", or "(alacritty / zsh" outside plans, reviews, the changelog, and the
Architecture 0026 quote (Non-Blocking Suggestion 2).

### Commits

| Commit | SHA | Message |
|---|---|---|
| 1 | `af8730a` | `docs(plans): add Ghostty follow-ups plan` |
| 2 | `4450a67` | `fix(doctor): check platform-area stow packages` |
| 3 | `69563b4` | `docs(task): describe all dry-run areas` |
| 4 | `e662326` | `docs: name Ghostty alongside Alacritty for terminal colors` |

All four match the Task 6 messages exactly, follow Conventional Commits, are authored by the
repository owner, and carry no `Co-Authored-By:` trailer or tool footer. Each commit holds the files
Task 6 assigns to it.

## Plan 0032 Completion Criteria

| Criterion | Result | Evidence |
|---|---|---|
| `task doctor` reports `macos/ghostty` on macOS; non-ghostty output unchanged | Met | `PASS: macos/ghostty (1/1 linked)`; `PASS: non-ghostty output unchanged` |
| `docs/guides/doctor.md` describes platform areas; markers directly above fences | Met | See doctor.md checks |
| `task dry-run` description lists all areas | Met | `69563b4` |
| No user-facing doc says only Alacritty owns terminal colors | Met | `e662326`; `git grep` at `HEAD` |
| Implementation review passes with no blocking issue; PR #83 updated after operator confirmation | Met (review); push pending | This review: no blocking issue. Push awaits the operator (Recommended Next Action 2) |

## Status-Sync Check

No change needed. No package is added, removed, or first stowed: `e9547f7..e662326` touches no
`stow/<area>/<package>` directory structure, only one README and one Lua comment inside existing
packages. `AGENTS.md` and `CLAUDE.md` are unchanged, and their blocks already describe
`stow/macos/ghostty` as stowed on macOS.

## Safety Verdict

PASS — `doctor.sh` stays read-only and gains no command that writes or touches `$HOME`.
`task dry-run` stays `--simulate`. No `stow` install, `--adopt`, `rm`, `mv`, or `ln -s` was added.
In `docs/guides/doctor.md` both dangerous fences now have their marker on the line directly above.

## Privacy Verdict

PASS — no secrets, tokens, hostnames, or user paths in any committed file. The lane path from the
foreman's local results file is recorded in this review with the placeholder `/path/to/`.

## Cross-Platform Verdict

PASS — the platform area is chosen from the existing `OS` detection; `common` runs everywhere,
`stow/macos/` only on macOS, and `stow/arch/` and `stow/debian/` (`.gitkeep` only) contribute no
package. `OS=unknown` checks `common` only. The doctor guide labels the area generically as
`stow/<os>/`.

## Documentation Verdict

PASS — `docs/guides/doctor.md` explains `<area>/<package>` labels and uses `stow/<area>`
placeholders; markers follow `.claude/rules/documentation.md`. The `Taskfile.yml` description
matches the real areas. The four wording lines name Ghostty.

## Recommended Next Action

1. Operator: review and commit this review together with the Plan 0032 status change
   (`docs/plans/0032-ghostty-follow-ups.md`, `docs/plans/README.md`) as
   `docs(reviews): add Ghostty follow-ups implementation review`.
2. Push `feat/ghostty-package` to update PR #83 only after the operator confirms. Push only; no
   merge, no force push.
3. After merge, and before the lane is removed: restow both `ghostty` packages from the primary
   checkout, dry-run first (review 0085 suggestion 3).
4. Fix `website/reference/troubleshooting.md:58-63` in a later change (review 0086 suggestion 14).
