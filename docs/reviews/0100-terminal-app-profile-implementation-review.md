# Review: macOS Terminal.app Profile Implementation

**Number:** 0100
**Status:** Complete
**Plan reviewed:** [0035-terminal-app-profile](../plans/0035-terminal-app-profile.md) (Approved)
**Review type:** Implementation review
**PRD:** [0031-terminal-app-profile](../prd/0031-terminal-app-profile.md) (Approved)
**Architecture:** [0027-terminal-app-profile-architecture](../architecture/0027-terminal-app-profile-architecture.md) (Approved)
**Files reviewed:** All 18 staged files, required rules, plan, PRD, architecture, and review 0099.

## Summary

Strict implementation review of Plan 0035 — macOS Terminal.app Profile. Most implementation checks pass. One documentation defect blocks approval: the guide's Homebrew font-install command changes the live system but lacks the required `⚠️  MANUAL STEP` marker (`docs/guides/terminal-app-setup.md:44-46`).

Plan 0035 stays **Approved** until the user completes the manual deployment and confirms the glyph and colors, its final completion criterion (`docs/plans/0035-terminal-app-profile.md:234-235`). This review does not change plan status.

## Blocking Issues

1. **Unmarked live-system install command:** `docs/guides/terminal-app-setup.md:44-46` gives `brew install --cask font-jetbrains-mono-nerd-font` without the immediately preceding `⚠️  MANUAL STEP — review before running` marker. Add the marker before this command block.

## Checks

| Check | Result | Evidence |
|---|---|---|
| PRD 0031: valid committed `.terminal` profile | Met | `plutil -lint` reports `OK`; file is `stow/macos/terminal/Catppuccin Macchiato.terminal`. |
| PRD 0031: JetBrainsMono Nerd Font, verified PostScript name, size 13 | Met | Profile archive decodes to `JetBrainsMonoNF-Regular`, size `13.0` (`scripts/terminal-sync.sh:117-119,159-171`). |
| PRD 0031: background, foreground, cursor, selection and 16 ANSI colors | Met with documented exception | Read-only palette comparison: 21 checked profile slots all match Alacritty theme, including TextBoldColor; SelectionColor is documented Surface2 `#5b6078` (`scripts/terminal-sync.sh:120-122,180-198`; architecture Decision 6). The 20 requested slots are among these. |
| PRD 0031: Apple glyph and final live background/text after deployment | Partial — user action pending | Profile uses the requested font, background `#24273a`, and text `#cad3f5`; actual Terminal.app rendering awaits the user's manual deployment (`docs/guides/terminal-app-setup.md:101-105`). |
| PRD 0031: task target, script, task listing | Met | `task --list` lists `terminal:sync`, DRY RUN by default; `Taskfile.yml:433-441`. |
| PRD 0031: default report is read-only and reports profile/default | Met | `bash scripts/terminal-sync.sh` completed a live-domain report; it reported profile absent and current default/startup as `Clear Dark`. Report code reads state and prints status (`scripts/terminal-sync.sh:205-211,247-269`). |
| PRD 0031: apply only owned profile, idempotent, leaves other profiles/default alone | Met by implementation; scratch behavior not repeated | `defaults write ... -dict-add` targets only `Window Settings` / `Catppuccin Macchiato`; default keys are written only under `--set-default` (`scripts/terminal-sync.sh:303-314`). Builder evidence supplied: repeated scratch apply was idempotent and preserved seeded key/profile. I could not repeat write tests because the review fence forbids defaults writes. |
| PRD 0031: separate explicit default opt-in and documentation | Met | `--set-default` without `--apply` exits 2 (`scripts/terminal-sync.sh:56-59`); task and guide document the combined invocation. |
| PRD 0031: non-macOS refusal | Met by implementation; not repeated | OS detection exits 1 before preference reads (`scripts/terminal-sync.sh:76-81`). Builder evidence says fake non-macOS result exits as expected. I could not repeat the injected test under the read-only fence. |
| PRD 0031: guide covers deployment, rollback, color limit, manual markers | Partial | Guide covers the required subjects and marks apply/rollback/cache-reset commands. Font installation at `docs/guides/terminal-app-setup.md:44-46` is unmarked; see blocker. |
| PRD 0031: website pages and strict build | Partial | Terminal and script pages are updated, and `#terminalapp-macos` resolves to the explicit Terminal.app heading (`website/features/terminal.md:95`). `mkdocs build --strict` was not run; plan says it is CI-authoritative (`docs/plans/0035-terminal-app-profile.md:27-28,232`). |
| PRD 0031: Stow ignores package and documents behavior | Met | `stow --dir=stow/macos --target="$(mktemp -d)" --simulate -v terminal` produced no links; README documents ignored/not-stowed behavior (`stow/macos/terminal/README.md:6-10`). |
| PRD 0031: both status blocks updated in same change | Met | Aggregate clause appears in AGENTS.md §2 and CLAUDE.md and agrees; `.claude/rules/status-sync.md` prose-only requirement is satisfied. |
| PRD 0031: macOS-only scope, no Arch/Debian changes | Met | Script guards OS; all changed implementation/config paths are macOS-specific or shared docs. No Arch/Debian package files changed. |
| PRD 0031: privacy | Met | Read-only grep of staged diff found no `/Users/`, `/home/`, email-like address, secret/token/password key, or hostname indicators. Profile contains no user or machine path. |
| Architecture Decision 1: Task deployment, not Stow | Met | ADR 0081 and ignored package README; Stow simulation linked nothing. |
| Architecture Decision 2: defaults, not open/raw plist edit | Met | Script has no `open`, direct live plist edit, or network call; applies through `defaults write` (`scripts/terminal-sync.sh:274-305`). |
| Architecture Decision 3: refuse apply while Terminal runs | Met by code; scratch/live apply guard not repeated | Live apply checks `pgrep -x Terminal` before backup/write (`scripts/terminal-sync.sh:287-293`). Scratch tests were not repeatable under fence. |
| Architecture Decision 4: separate default flag | Met | Enforced in argument validation; only writes default/startup in `set_default` branch (`scripts/terminal-sync.sh:56-59,307-314`). |
| Architecture Decision 5: committed profile and repository-only build source | Met by inspection | `--build` reads the Alacritty TOML and writes only `profile_path`; branch exits before preference reads (`scripts/terminal-sync.sh:180-198,222-227`). Build itself was not run because it writes a repository file. |
| Architecture Decision 6: readable selection exception | Met | Surface2 `#5b6078` is in script and guide with rationale (`scripts/terminal-sync.sh:120-122`; guide `:28-29`). |
| Architecture Decision 7: timestamped export backup before writes | Met by inspection | Live-domain guard runs first, then export to `$HOME/Library/Preferences/com.apple.Terminal.plist.bak-<timestamp>`, then preference writes (`scripts/terminal-sync.sh:287-305`). No live apply was run. |
| Architecture Decision 8: OS/defaults/domain checks before preference reads | Met | OS guard at `:76-81`, `defaults` and live-domain existence checks at `:83-95`, before Python reads preference state at `:234`. |
| Script argument restrictions and allowlist | Met | `--set-default` without `--apply` and `--build` with apply/default are rejected; only live domain or `com.example.terminal-sync-test*` accepted, else exit 2 (`scripts/terminal-sync.sh:56-74`). |
| Backup and running guard cannot be bypassed for live domain | Met by inspection | `is_live` is based on exact domain equality (`:107-111`); both guard and backup are inside `if is_live` (`:287-300`). No flag or environment setting skips them for `com.apple.Terminal`. |
| Script write surface and error behavior | Met by inspection | Only writes are repository profile during `--build`, and live preferences plus live backup during live `--apply`; scratch writes target allowlisted test domain. No `stow`, `open`, `rm`, or network invocation. `set -euo pipefail` is present; Python `global` declarations precede state assignments (`:31,287-288`). Missing OS/defaults/domain exits 1; argument/domain validation exits 2. |
| XML argument, idempotency, absent keys, refreshed state | Met by inspection; scratch writes not repeated | XML is passed as one subprocess argument (`:303-304`); `-dict-add` replaces owned key. Absent previous defaults generate `defaults delete` restore instructions (`:281-284`); apply reloads domain and refreshes all state after writes (`:316-322`). Builder evidence confirms absent Startup key output. |
| Profile privacy and plist validity | Met | `plutil -lint` passed. Profile has 16 ANSI colors plus background/text/bold/cursor/selection; no personal paths or identifying data. Palette decoder matched every checked color. |
| Stow/status synchronization | Met | Simulation returned no links. README documents ignored package. AGENTS.md and CLAUDE.md status clauses agree; `status-sync.md` satisfied. |
| Guide commands, platform labels, font prerequisite, anchors | Partial | macOS labels and required font command are present; `#terminalapp-macos` resolves. Font install command misses manual marker (blocker). |
| ADR 0081 and index; local decision check | Met | ADR follows repository record format; index row exists (`docs/decisions/README.md`). `task check:decisions` passed: `PASS: decision record is self-consistent (70 ADRs)`. |
| Plan Files Affected scope | One extra relevant file | `website/reference/stow.md` is staged but absent from Plan 0035's Files Affected list (`docs/plans/0035-terminal-app-profile.md:137-159`). It updates the package tree consistently with the planned `docs/stow-usage.md` and the PRD website criterion; no blocking defect found. |
| Builder-reported scratch-domain evidence | Not independently repeated | Fence forbids preference writes and forbids setting `TERMINAL_SYNC_DOMAIN`; therefore apply idempotency, seeded-key/profile preservation, set-default restore output, absent Startup restore line, invalid-domain exit, non-macOS injection, and missing-defaults tests could not be repeated. Builder reports these passed. |
| Known scratch artifact | Not part of diff | Builder left an empty 42-byte `~/Library/Preferences/com.example.terminal-sync-test.plist`. It is outside the staged diff; review fence forbids cleanup. |
| Review-safe checks | Met | `bash -n scripts/terminal-sync.sh` passed; `plutil -lint` passed; Stow simulation linked nothing; `task --list` showed target; `task check:decisions` passed; live `bash scripts/terminal-sync.sh` was read-only; `git diff --staged --check` passed. |

## Non-Blocking Suggestions

- Add `website/reference/stow.md` to Plan 0035's Files Affected list if that documentation change is retained.
- Run CI's `mkdocs build --strict` before merge.

## Safety Verdict

PASS — review ran no preference writes, Stow installs, home-directory changes, or other prohibited commands. Script write paths and live-domain safeguards are constrained as designed.

## Privacy Verdict

PASS — staged diff contains no detected secrets, usernames, absolute home paths, hostnames, or personal data.

## Documentation Verdict

FAIL — font installation command at `docs/guides/terminal-app-setup.md:44-46` changes the macOS system without the required manual-step marker.

## Recommended Next Action

Builder: add `⚠️  MANUAL STEP — review before running` immediately before the font-install command block. Reviewer: re-review documentation and all verdicts. Keep Plan 0035 Approved until the user completes its manual deployment criterion.
