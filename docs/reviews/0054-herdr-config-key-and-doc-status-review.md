# Review: Herdr Config Key Fix, Document Status Sync, Social Preview Size

**Number:** 0054
**Status:** Complete
**Date:** 2026-07-30
**Plan reviewed:** None — corrective maintenance, no PRD/Plan chain (see Process Note)
**Branch:** `fix/herdr-config-key-and-doc-status`

**Files reviewed:**

- `stow/common/herdr/.config/herdr/config.toml`
- `docs/guides/herdr-setup.md`
- `docs/prd/0007-zsh-activation-migration.md`
- `docs/prd/0010-real-zsh-configuration.md`
- `docs/architecture/0007-zsh-activation-migration-architecture.md`
- `docs/architecture/0010-real-zsh-configuration-architecture.md`
- `docs/plans/0017-implement-bat-configuration.md`
- `docs/plans/0018-implement-eza-configuration.md`
- `docs/plans/0023-implement-btop-configuration.md`
- `website/assets/images/dotfiles-social-preview.png`

---

## Summary

Three corrective changes found while auditing repository state against reality. No new Stow
package, no new feature, no change to how anything is stowed.

1. **`fix(herdr)`** — `herdr config check` reported
   `unknown config key ui.sidebar.initial_split_width; ignoring key`. Herdr 0.7.5 has no such key:
   sidebar width is a flat `[ui]` key measured in columns, not a percentage under an `[ui.sidebar]`
   table. Present since the package was added in `94917c6`, so the setting had never taken effect.
   Replaced with `sidebar_width = 25`; `agent_panel_sort` moved beside it instead of sitting
   orphaned above the removed table header. Guide updated with the corrected key, a
   `herdr config check` validation step, and a troubleshooting entry.

2. **`docs`** — status fields had drifted from what the reviews recorded. PRD/Architecture 0007 and
   0010 were still `Draft` despite passing reviews 0021 and 0033 and being implemented by Complete
   plans. Plans 0017 and 0018 were still `Approved` despite passing implementation reviews 0042 and
   0044 with no blocking issues. Plan 0023 used `Done`, which is not in the vocabulary defined in
   `docs/claude/DOCUMENT-LIFECYCLE.md`.

3. **`docs(assets)`** — `8346da1` had resized the social preview under GitHub's 1MB limit;
   `e29a1d4` ("refresh website screenshots") then replaced it with a 1,536,036-byte export,
   silently reverting the fix. Resized to 1280x720 at 217,309 bytes.

---

## Blocking Issues

None.

---

## Non-Blocking Suggestions

- **Plans 0016 (herdr) and 0020 (claude statusline) have no implementation review** under
  `docs/reviews/`. Both shipped; both remain `Approved`. They were deliberately left alone in this
  change — only a Reviewer may mark a plan Complete, and inventing a retroactive verdict would
  defeat the purpose of the status field. Worth closing out properly.

- **`docs/guides/herdr-setup.md` §3 still says "shared across macOS and Arch."** Debian became a
  supported platform in ADR-0053. Pre-existing, out of scope here, but the guide is now stale.

- **`herdr config check` is not a complete validator.** It reports unknown keys only for the tables
  it validates — a bogus key injected under `[theme.custom]` during testing still returned
  `config: ok`. The troubleshooting entry states this caveat so the check is not over-trusted.

- **Two stale symlinks remain in `$HOME`:** `~/.config/zsh/local.zsh.example` and
  `~/.config/zsh/zshrc.example`. ADR-0054 excluded these templates from stow, but stow does not
  reclaim links it no longer manages, so a restow is a no-op here. They are inert — `index.zsh`
  sources explicit filenames and never globs. Removing them requires `rm` against `$HOME`, which is
  the user's action to take, not an agent's.

- **`git-cliff` is not installed on this machine,** so `task changelog` fails its precondition and
  `CHANGELOG.md` was not regenerated. See Changelog Note.

---

## Safety Verdict

**PASS** — No `stow --adopt`, `rm`, `mv`, or `ln -s` against `$HOME` was executed. No file outside
the repository root was modified. The only `$HOME`-touching operation considered (removing the two
stale `.example` symlinks) was **shown to the user with a `⚠️  MANUAL STEP` marker and not run**.
Stow was invoked only as `--simulate` (read-only) while diagnosing drift. The herdr config edit took
effect through the existing symlink — no new link was created and no restow was performed.

## Privacy Verdict

**PASS** — No credentials, tokens, keys, private hostnames, or internal URLs in any changed file.
The herdr config carries only styling and behaviour values. The social preview image contains only
the public repository name and a generic `~/works/dotfiles` prompt. Staged diffs were audited before
each commit.

## Documentation Verdict

**PASS** — All added commands (`herdr config check`, the `magick` resize invocation recorded in the
commit message) are copy-pasteable and non-destructive; none needed a danger marker. The corrected
guide table now states the unit (columns, not percent) that the previous entry got wrong. Status
lines each name the review that justifies them, so the claim is checkable rather than asserted.

---

## Process Note

The commits were made **before** this report, inverting the documented
Build → Review → Commit order in `AGENTS.md` §5. Recording it plainly rather than backdating the
report. The changes are corrective maintenance to existing packages and documents — no PRD,
Architecture, or Plan was raised, and none of the three would have been meaningfully served by one.
Nothing has been pushed or merged, so the review still precedes anything leaving this machine.

## Changelog Note

Per ADR-0055 `CHANGELOG.md` is a rendered artifact, regenerated with `task changelog` and never
hand-edited. `git-cliff` is not installed here, so it could not be regenerated in this change. This
is not a gap in the change: the committed file has no `## [Unreleased]` section, and the repository
regenerates it at release time alongside a `chore(release)` commit. All three commit subjects are
Conventional Commits and map onto configured `cliff.toml` groups — `fix` → Bug Fixes,
`docs` → Documentation — so they will render correctly at the next release without further action.
`chore(release)` commits are themselves skipped by the parser.

---

## Recommended Next Action

Approve and open the PR. Confirm CI is green before merging.
