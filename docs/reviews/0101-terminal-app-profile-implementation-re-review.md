# Review: macOS Terminal.app Profile Implementation Re-review

**Number:** 0101
**Status:** Complete
**Plan reviewed:** [0035-terminal-app-profile](../plans/0035-terminal-app-profile.md) (Complete)
**Review type:** Implementation re-review
**Previous review:** [0100](0100-terminal-app-profile-implementation-review.md)
**Commits reviewed:** `e248c01` blocker fix and `3a3c30e` Mono font fix; implementation through `3a3c30e`

## Summary

Re-reviewed Plan 0035 — macOS Terminal.app Profile, including both commits since review 0100. The missing manual-step marker is fixed, the profile and documentation consistently use the Mono font, and all requested local checks pass. Plan 0035 is Complete. The CI `mkdocs build --strict` check remains pending for the PR.

The user confirmed in this session that Terminal.app shows the Apple glyph and Macchiato colors with the Mono profile. The current read-only script report says all five rows are `ok` and ends with `SYNCED`.

## Blocking Issues

None.

## Checks

| Check | Result | Evidence |
|---|---|---|
| Previous review 0100 blocker | Resolved | The font install at guide `:49-53`, apply at `:76-80`, set-default at `:91-95`, `killall cfprefsd` at `:115-119`, `defaults import` at `:125-129`, and example `defaults write` at `:134-139` each have the immediately preceding `⚠️  MANUAL STEP` marker. |
| Mono font consistency | Met | `scripts/terminal-sync.sh:120-121,254` uses PostScript name `JetBrainsMonoNFM-Regular`, Mono font file glob, and Mono report label. The committed profile's decoded Font archive contains `NSName = JetBrainsMonoNFM-Regular` and `NSSize = 13.0` (`python3 -I` with `plistlib`). README, guide, website, ADR 0081 amendment, PRD amendment, and architecture amendment agree. |
| Font search hits | Met | Remaining `JetBrainsMonoNF-Regular` hits describe the regular variant as a failed Terminal.app choice (guide and ADR 0081), or identify the regular font still used by Alacritty/Ghostty (architecture, ADR, guide). The script comment names that failed variant. Remaining generic “Nerd Font” hits describe the glyph/category, not the selected family. No claim in the touched files contradicts the Mono profile. |
| PRD font acceptance criterion | Met | PRD 0031 now requires `JetBrainsMono Nerd Font Mono`, size 13, with verified PostScript name. The committed profile decodes to the corresponding name and size. |
| Safe syntax, plist, and Stow checks | Met | `bash -n scripts/terminal-sync.sh` exited 0. `plutil -lint` reported `OK`. Stow simulation printed only its simulation warning and linked nothing. |
| Task target and ADR check | Met | `task --list` includes `terminal:sync` as DRY RUN by default. `task check:decisions` reported `PASS: decision record is self-consistent (70 ADRs)`. |
| Read-only live report | Met | `bash scripts/terminal-sync.sh` reported `ok` for installed Mono font, profile present, profile matches repository file, default profile, and startup profile; it ended with `SYNCED`. |
| Plan 0035 completion criteria | Met, with CI pending | PRD acceptance criteria are covered by review 0100 and this re-review, including the corrected font criterion. Stow links nothing; README documents ignored behavior. Plist lint and decoded palette were checked in review 0100; profile font archive was decoded here. Dry-run, scratch-domain idempotency/preservation, `--set-default` argument rejection, domain allowlist, live guard/backup, non-macOS refusal, and running-Terminal refusal are implemented and covered by builder evidence recorded in review 0100; this fence prohibits repeating write/injected tests. Task target, docs, ADR check, and status blocks were checked in review 0100 and task listing/ADR check repeated here. No secrets, user names, or machine paths were found in added diff content. The user confirmed the glyph and colors in this session. CI `mkdocs build --strict` is pending on the PR, as required by the plan; it does not block this re-review. |
| Privacy | Met | Read-only scan of added `git diff main...HEAD` lines for secret/token/password terms, `/Users/`, `/home/`, and hostname patterns found only review/plan instructions and prior-review text describing those checks. No secret, user path, or hostname value was found. |
| Diff hygiene and working tree | Met | `git diff main...HEAD --check` passed. `git status --short --branch` was clean before this review report and status update. |

## Non-Blocking Suggestions

- Run CI's `mkdocs build --strict` on the PR; result remains pending.

## Safety Verdict

PASS — only read-only checks ran. No prohibited preference writes, Stow install, home-directory changes, or other live-system commands ran.

## Privacy Verdict

PASS — no secrets, usernames, machine paths, or private hostnames were found in added diff content.

## Documentation Verdict

PASS — every live-system command in the guide has the required manual-step marker. Font naming and the PRD acceptance criterion agree with the committed Mono profile.

## Recommended Next Action

Merge only after CI's strict MkDocs build passes.
