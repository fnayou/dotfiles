# Review: Ghostty Configuration Implementation

**Number:** 0085
**Status:** Complete
**Date:** 2026-10-17
**Plan reviewed:** [0031-implement-ghostty-configuration](../plans/0031-implement-ghostty-configuration.md)
**PRD:** [0028-ghostty-configuration](../prd/0028-ghostty-configuration.md) (as amended: Decision 11 withdrawn, Decision 12)
**Architecture:** [0026-ghostty-configuration-architecture](../architecture/0026-ghostty-configuration-architecture.md)
**Commits reviewed:** `a6a6225`, `e1b007e`, `51057af`, `e57f932`, `023a5fa` (branch `feat/ghostty-package`, since `69a4fc4`)

## Summary

Reviewed the implementation of Plan 0031 — Implement Ghostty Configuration (Task 24). The branch
adds the common Stow package `stow/common/ghostty/` (`config.ghostty`,
`themes/catppuccin-macchiato`, `.stow-local-ignore`, `README.md`) and the macOS-only Stow package
`stow/macos/ghostty/` (`macos.ghostty`, `.stow-local-ignore`, `README.md`), updates the status
blocks, adds `docs/guides/ghostty-setup.md`, updates `docs/stow-usage.md` and eleven website pages,
records the withdrawal of the custom Dock icon (PRD 0028 Decision 11) in the PRD, the architecture,
and the plan, and marks both packages as stowed after the operator's real install.

Every committed file was compared with the PRD as amended and with Architecture 0026 "File
Content". `config.ghostty`, `themes/catppuccin-macchiato`, `macos.ghostty`, both
`.stow-local-ignore` files, and both package READMEs match the architecture content exactly. The
custom icon is absent from the branch history: `a6a6225` has 10 files and no `Ghostty.icns`, and
the earlier commits `a3b14b1` and `26fb0be` are not on the branch.

The Builder and operator results below come from the foreman's results file for this plan. It was
read in full. Raw outputs are summarized faithfully where the file holds a summary, not the raw
text.

Plan 0031 — Implement Ghostty Configuration is complete.

## Blocking Issues

None.

## Non-Blocking Suggestions

1. **Check 1 expectation is wrong in the plan and architecture.** Plan 0031 "Checks 1 and 2" expects
   `exit=0` with at most a theme-not-found message. Ghostty 1.3.1 `+validate-config` exits `1` on a
   missing theme. The Builder stopped and reported it; the foreman accepted the deviation because
   `themes/` does not exist next to the default config before stow, and check 3 steps 2 and 3 prove
   theme loading in a fake home. A future plan that reuses this check should expect `exit=1` with
   only the theme-not-found message, or run it only in a fake home.
2. **Follow-up: stale `Taskfile.yml:67`.** It describes `task dry-run` as "AREA=<common> …
   (macos/arch/debian are future areas)", which is false now that `stow/macos/ghostty` exists
   (review 0083 suggestion 10). Plan 0031 did not change `Taskfile.yml`. Fix it in a separate
   change.
3. **Follow-up: restow from the primary checkout.** The live `~/.config/ghostty/` links point into
   the `feat/ghostty-package` worktree lane. After merge, and before the lane is removed, unstow both
   `ghostty` packages from the lane and restow them from the primary checkout (dry-run first, under
   the usual manual-step approval). Otherwise the links break when the lane is removed.
4. **Plan role deviation, recorded.** Plan 0031 Tasks 22 and 23 name the operator as the runner. The
   real dry-run and install were operator-approved and run by a worker from the lane, and the later
   unstow and restow of the macOS package (run 23) also ran that way. Approval was explicit, so this
   is not a safety failure. Future plans should name the worker-with-approval mode if it is the
   intended mode.
5. **Plan completion criteria still list icon items.** The Completion Criteria checkboxes for
   `Ghostty.icns` and the 11-file commit 1 stay as written; the Amendment at the top of the plan
   explains they were withdrawn. No edit is needed, but readers must read the Amendment first.
6. **Guide `mkdir -p` without a marker.** `docs/guides/ghostty-setup.md:324` (Troubleshooting,
   folded-directory recovery) runs `mkdir -p ~/.config/ghostty/themes` with no `⚠️  MANUAL STEP`
   marker. It writes to `$HOME` but is not destructive. Consider adding the marker for consistency.
7. **Raw Task 8 output not in the results file.** Task 8 (icon copy) was executed and then
   withdrawn. Its raw output is not in the results file, so this review records only the outcome.
8. **Incidental marker fixes.** `e57f932` also removes the blank line between the marker and the
   fence in the alacritty and herdr sections of `docs/stow-usage.md` and `website/features/terminal.md`.
   This is outside the Ghostty scope but brings those fences in line with
   `.claude/rules/documentation.md`. Accepted.

## Builder and Operator Results

### Task 1 — Preflight

- First preflight: `codesign --verify --deep --strict /Applications/Ghostty.app` gave `exit=1`, "a
  sealed resource is missing or invalid", file modified: `Contents/Resources/Ghostty.icns`. The
  bundle icon had been replaced at 02:51 on 2026-10-17, before this work, with the custom icon
  (SHA-256 `6796c0f4…32ac`).
- The operator ran `brew reinstall --cask ghostty`. `codesign` then gave `exit=0`.
- Re-run preflight: 7 `PASS:` lines; Application Support `config.ghostty` `wc -c` = `0`;
  `codesign` `exit=0`.

### Task 8 — Icon copy

Executed, then withdrawn with the icon feature (see "Icon investigation and withdrawal"). Raw
output not in the results file.

### Task 10 — Checks 1, 2, 4, 5, 6

- Check 1: printed `theme "catppuccin-macchiato" not found` for `~/.config/ghostty/themes` and the
  bundle themes directory, and `exit=1`. Deviation from the plan (expected `exit=0`); accepted by
  the foreman. See Non-Blocking Suggestion 1.
- Check 2: `exit=0`, no message.
- Checks 4, 5, 6: 15/15 `PASS:`.

### Task 11 — Check 3

Steps 1, 2, 3: all `PASS:`. Step 1 showed 2 `LINK:` lines (`-v`), no conflict.

### Task 12 — Fake-home launch (operator)

| # | Question | Answer |
|---|---|---|
| 0 | New Ghostty window opened | Yes |
| 1 | Dock and app switcher icon | Official, not custom. The foreman compared renders: custom is a white ghost on black; the Dock showed the official blue icon. So the `macos-custom-icon` default did not follow `XDG_CONFIG_HOME`, or the icon did not load. Task 23 was to settle it. |
| 2 | Login shell | `echo $SHELL $0` printed `/bin/zsh -/bin/zsh` (leading `-` = login shell) |
| 3 | Theme and `TERM` | Catppuccin Macchiato colors; `$TERM` = `xterm-256color` |
| 4 | Keys | Option+N types `~`: yes. Option+Shift+L types `|`: yes. Shift+Enter sends a newline: yes. |
| 5 | Finder icon of `/Applications/Ghostty.app` | Official, unchanged |

### Task 13 — Numpad (operator)

All numpad keys (`0`–`9`, `+`, `-`, `*`, `/`, `.`, `Enter`) printed their literal character in
plain `cat -v` and after `tput smkx`. Misbehaving keys: none.

### Task 14 — Numpad result applied

No change (empty list). `config.ghostty` has no numpad `keybind` line.

### Task 17 — Commit 1

- Commit `a3b14b1` `feat(ghostty): add common and macOS Ghostty stow packages`, 11 files, operator
  approved. Later amended twice (see below); final commit-1 SHA is `a6a6225`.
- Pre-commit: `diff --check` and `diff --staged --check` PASS; `task check:decisions` `exit=0`;
  the privacy grep matched only context lines.
- The Builder fixed a double "and" at `README.md:15-16` with a comma (wording only, same meaning).

### Tasks 22 and 23 — Real dry-run and install

Operator-approved, run by a worker from the lane.

- Dry-run, common package: `MKDIR` `.config/ghostty`, `LINK` `config.ghostty`, `MKDIR` `themes`,
  `LINK` `catppuccin-macchiato`. macOS package (with the icon, before withdrawal): `LINK`
  `Ghostty.icns`, `LINK` `macos.ghostty`. Both `exit=0`, no conflict.
- Install: both `exit=0`. The links point into the worktree lane checkout.
- Verified: `~/.config/ghostty` and `themes/` are real directories; the 4 links resolve;
  `ghostty +validate-config` (default files) `exit=0`; `+show-config` shows the theme, palette 0,
  opacity, command, `macos-option-as-alt = true`, `macos-icon = custom`, and `term`.

### Task 23 — Check 7b (operator)

- Dock icon after a full quit and relaunch: official (blue). Custom icon not shown.
- Ghostty user defaults key `CustomGhosttyIcon2` held the custom icon (decoded 152344 bytes,
  SHA-256 `6796c0f4…32ac`): Ghostty read `macos-icon = custom` and the icon file; the Dock did not
  render it.
- Environment: macOS 27.0.1 (26A434), Ghostty 1.3.1, app named `Ghostty.app`, Dock pinned item,
  `dock.external.extra` at 0% CPU.
- Option+N types `~`: confirmed in Task 12 and after the restow (`macos-option-as-alt = true`
  loaded).
- Finder icon: official, unchanged (expected).

### Icon investigation and withdrawal

- `killall Dock` and a relaunch (operator): official icon.
- Explicit `macos-custom-icon = ~/.config/ghostty/Ghostty.icns` (uncommitted experiment, runs 20–21,
  reverted; tree clean): official icon.
- Built-in `macos-icon = xray` (run 22, uncommitted): Ghostty stored `{"xray":{}}` in
  `CustomGhosttyIcon2`; the Dock still showed the official icon. So the Dock renders no
  `macos-icon` value on macOS 27.0.1 with Ghostty 1.3.1. The failure is not specific to custom
  icons or to the optional include.
- Upstream: ghostty-org/ghostty discussion #11029 (a renamed-bundle bug, fixed in PR #11049, merged
  2026-02-27; later reports on macOS 26.4 are unresolved).
- The operator chose to drop the feature. Run 23: unstowed the macOS package, `git rm`
  `Ghostty.icns`, rewrote `macos.ghostty` (Option-as-Alt only) and the macOS README, edited the
  README row and the common README line, and amended `a3b14b1`.
- Restowed the macOS package: dry-run clean, 1 `LINK:` line; only `~/.config/ghostty/macos.ghostty`
  linked; `+validate-config` `exit=0`; `macos-option-as-alt = true` loaded.
- `e1b007e` records the withdrawal in PRD 0028, Architecture 0026, and Plan 0031 (Amendment). Plan
  check 3 step 3 and check 6 were updated and re-run with `PASS` against `a6a6225`.

### Foreman script bug and repair

- The foreman's `apply.py` opened `README.md` and `stow/common/ghostty/README.md` for writing before
  reading them, which emptied both files. The amend `26fb0be` committed them empty.
- The foreman repaired both files from `a3b14b1` with `repair.py` and amended again, giving
  `a6a6225`. The final diff of `a6a6225` against `a3b14b1` is exactly the intended icon removal.
- Confirmed in this review: `git show a6a6225` shows both READMEs with full content, matching
  Architecture 0026. Neither `a3b14b1` nor `26fb0be` is on the branch, so the icon never reaches
  the pushed history.

### Commit SHAs

| Commit | SHA | Message |
|---|---|---|
| 1 (Task 17) | `a6a6225` | `feat(ghostty): add common and macOS Ghostty stow packages` |
| Withdrawal | `e1b007e` | `docs: withdraw the custom Ghostty Dock icon` |
| 2 (Task 19) | `51057af` | `docs(guides): add Ghostty setup guide` |
| 3 (Task 21) | `e57f932` | `docs: add Ghostty to stow usage and website pages` |
| Follow-up (Task 25) | `023a5fa` | `docs: mark Ghostty packages as stowed` |

All commits are authored by the repository owner, follow Conventional Commits, and carry no
`Co-Authored-By:` trailer or tool footer. All were operator-approved.

### Application Support file and app bundle

| Moment | `wc -c` of Application Support `config.ghostty` | `codesign --verify --deep --strict` |
|---|---|---|
| Task 1, first preflight | `0` | `exit=1` (bundle icon replaced before this work) |
| Task 1, after `brew reinstall --cask ghostty` | `0` | `exit=0` |
| Task 24, before this review (foreman, read-only) | `0` | `exit=0` |

The Reviewer had no shell access beyond git for this review; the Task 24 values were recorded by
the foreman.

### Process notes

- In run 9 the foreman added `git grep` to a worker allowlist without operator approval. The worker
  was restarted with the standing allowlist before it acted.
- A pasted brief once stayed unsubmitted; a later Enter key press answered a read-only `ls | grep`
  dialog. No write was approved that way.

## PRD 0028 Acceptance Criteria

| # | Criterion | Result | Evidence |
|---|---|---|---|
| 1 | `config.ghostty` exists, sets every Configuration Summary option, follows Decisions 8–10 | Met | `a6a6225`; matches Architecture 0026 exactly; no `scrollback-limit`, no `shell-integration*`, no numpad lines (Task 13: none needed) |
| 2 | `themes/catppuccin-macchiato` exists; every hex matches Alacritty | Met | Check 4 PASS; each key matches the PRD theme-mapping table |
| 3 | Theme loaded with `theme = catppuccin-macchiato`, not bundled, not absolute | Met | `config.ghostty:6` |
| 4 | `+validate-config` reports no errors for the new file | Met, with deviation | Check 1 `exit=1` (theme not found before stow; plan expectation wrong); check 3 steps 2 and 3 PASS in a fake home; real stow `+validate-config` `exit=0` |
| 5 | No secrets, credentials, or private data in any package file | Met | Check 5 PASS; reviewed every file in `a6a6225` |
| 6 | No symlinks created in `$HOME` during implementation | Met | Builder created none; the only `$HOME` links come from the operator-approved Tasks 22–23 |
| 7 | No `stow` install executed automatically | Met | Installs ran only with explicit operator approval |
| 8 | Application Support `config.ghostty` untouched | Met | `0` bytes at Task 1 and Task 24 |
| 9 | Settings with no Ghostty equivalent listed in the PRD, not invented | Met | PRD table; none of them in `config.ghostty` or the theme |
| 10 | Stow dry-run and install commands documented | Met | PRD, `docs/guides/ghostty-setup.md`, `docs/stow-usage.md`, `website/features/terminal.md` |
| 11 | `config.ghostty` has no `macos-*` line; last line `config-file = ?macos.ghostty` | Met | Check 6 PASS; `config.ghostty:49` |
| 12 | `macos.ghostty` sets `macos-option-as-alt = true`, own-line comments | Met | `a6a6225`; check 6 PASS |
| 13 | `+validate-config` clean with `macos.ghostty` absent and present | Met | Check 3 step 2 (absent) and step 3 (present) PASS |
| 14 | `stow/macos/ghostty/README.md` lists `macos.ghostty` | Met | Files table |
| 15 | macOS `.stow-local-ignore` has the same entries as the common one | Met | Check 6 PASS; identical in `a6a6225` |
| 16 | `/Applications/Ghostty.app` bundle not modified | Met | `codesign` `exit=0` at Task 1 (after reinstall) and Task 24; the earlier break predates this work |
| 17 | Both status blocks updated in the commit that adds the packages | Met | `a6a6225` changes `AGENTS.md` §1/§2 and `CLAUDE.md` with both packages |
| — | `macos.ghostty` sets `macos-icon = custom`, not `macos-custom-icon` | Withdrawn | PRD Decision 11 withdrawn (`e1b007e`) |
| — | `Ghostty.icns` exists with SHA-256 `6796c0f4…32ac` | Withdrawn | PRD Decision 11 withdrawn |
| — | macOS README records icon source, SHA-256, unknown licence | Withdrawn | PRD Decision 11 withdrawn |
| — | Dock shows the custom icon after a full restart | Withdrawn | Not rendered on macOS 27.0.1 with Ghostty 1.3.1; evidence above |

## Status-Sync Check

- `a6a6225` adds both packages and updates `AGENTS.md` (§1 bullet, §2 block), `CLAUDE.md`, and the
  `README.md` status lines in the same commit. The blocks agree: `ghostty` and
  `stow/macos/ghostty` added, not yet stowed.
- `023a5fa` is the first-stowed commit (Task 25). It updates both blocks and the `README.md` status
  lines in one commit. The blocks agree: all `stow/common/` packages stowed, plus
  `stow/macos/ghostty` on macOS.
- Neither block re-introduces a per-package list; both point to `stow/common/` and `stow/macos/`.

## Safety Verdict

PASS — no committed file adds automated `stow`, `stow --adopt`, or `rm`, `mv`, or `ln -s` against
`$HOME`. Every install, `stow --delete`, and `mv` fence in the guide, `docs/stow-usage.md`, and
`website/features/terminal.md` has the marker on the line directly above it. The real install ran
only with explicit operator approval. The Application Support file stayed empty, and the app
bundle verifies with `codesign`. The bundle icon replacement found at Task 1 predates this work and
was repaired by the operator's reinstall.

## Privacy Verdict

PASS — the package files hold display and key preferences only. No secrets, tokens, hostnames, or
work settings. No committed file contains a user path: the guide uses `/path/to/dotfiles`, and
other docs use `$HOME` or `~`. The third-party icon with an unknown licence never entered the
branch history.

## Cross-Platform Verdict

PASS — the common `config.ghostty` has no `macos-*` line; the macOS-only option lives in
`stow/macos/ghostty`, loaded by the optional `config-file = ?macos.ghostty`, which Arch skips.
Install commands are labelled per platform (`brew` for macOS, `pacman` for Arch), the macOS
binary path is used only in `# macOS` blocks, and Debian is documented as not using Ghostty.

## Documentation Verdict

PASS — the guide follows the ten sections of Architecture 0026, with 11 markers and no user path.
`docs/stow-usage.md` and the website pages no longer call `stow/macos/` empty, name `--no-folding`
for both packages, and mention no custom icon outside the guide's withdrawal note. The PRD,
architecture, and plan record the icon withdrawal and its evidence.

## Recommended Next Action

1. Operator: review and commit this review together with the Plan 0031 status change
   (`docs/plans/0031-implement-ghostty-configuration.md`, `docs/plans/README.md`).
2. Open the pull request for `feat/ghostty-package`.
3. After merge, and before the lane is removed: unstow both `ghostty` packages from the lane and
   restow them from the primary checkout, dry-run first (Non-Blocking Suggestion 3).
4. Fix `Taskfile.yml:67` in a separate change (Non-Blocking Suggestion 2).
