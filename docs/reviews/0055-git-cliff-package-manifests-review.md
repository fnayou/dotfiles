# Review: Add git-cliff to the Package Manifests

**Number:** 0055
**Status:** Complete
**Date:** 2026-07-30
**Plan reviewed:** None — corrective maintenance, no PRD/Plan chain (see Process Note)
**Branch:** `chore/add-git-cliff-to-package-manifests`

**Files reviewed:**

- `packages/Brewfile`
- `packages/arch/packages.txt`
- `packages/debian/packages.txt`
- `docs/guides/packages-setup.md`
- `Taskfile.yml`

---

## Summary

`git-cliff` has been required by `task changelog` since ADR-0055, but appeared in no package
manifest — only as a printed hint inside `task changelog:install`. A fresh machine set up by
following the repository's own documentation would not get it, and `task changelog` would fail its
precondition. Review 0054 recorded this gap; this change closes it.

Added to all three manifests, each marked as optional tooling and pointing at ADR-0055 for the
rationale:

| Manifest | Entry |
|---|---|
| `packages/Brewfile` | `brew "git-cliff"` under a new "Changelog tooling" section |
| `packages/arch/packages.txt` | `sudo pacman -S git-cliff` (extra repo) under a new section |
| `packages/debian/packages.txt` | under "Out-of-band" — `cargo install` or a release binary |

The same tool list is duplicated in `docs/guides/packages-setup.md` (requirements table, per-OS
install steps, selective-install snippets) and in the `deps:arch` / `deps:debian` Taskfile tasks.
Updating only the manifests would have left those stale and recreated the gap in a different file,
so all copies were updated together.

---

## Blocking Issues

None.

---

## Non-Blocking Suggestions

- **`git-cliff` is deliberately not added to `task check`.** That task verifies the core
  prerequisites (`stow`, `git`, `task`) and should keep passing on a machine that never generates a
  changelog. `task changelog` already fails with a clear, actionable message
  (`git-cliff not installed — run: task changelog:install`).

- **The Debian entry is inherited, not verified.** `git-cliff` is recorded as absent from the Debian
  archive because `task changelog:install` and this repository already assert it. That claim could
  not be checked from this Arch machine — no `apt` available. Worth confirming on an actual Debian
  trixie box before relying on it.

- **`git-cliff` is now installed on this machine via Homebrew, not pacman**, because `sudo pacman`
  needs an interactive password. The Arch manifest correctly documents the native `pacman` route
  regardless — the manifest describes the intended install path, not what happens to be on one
  machine.

---

## Safety Verdict

**PASS** — No `stow`, `rm`, `mv`, or `ln -s` against `$HOME`. No file outside the repository root
was modified. Every install command added is commented out in the manifests or printed by a
`deps:*` task that explicitly "prints only, does not install". The new Debian instructions carry the
`⚠️  MANUAL STEP` marker already present on that block. No automation was added that installs
anything.

## Privacy Verdict

**PASS** — No credentials, tokens, hostnames, or personal data. The only URLs added are the public
git-cliff project and its GitHub releases page.

## Documentation Verdict

**PASS** — Commands are copy-pasteable and platform-labelled per the cross-platform rule: `pacman`
appears only in Arch context, `apt`/`cargo` only in Debian context, `brew` only in the Brewfile and
the macOS section. Verified by execution rather than inspection: `task deps:arch` and
`task deps:debian` render the new lines correctly, and `brew bundle list --file=packages/Brewfile`
parses the Brewfile and lists `git-cliff` in position.

---

## Process Note

As with review 0054, this is corrective maintenance to existing files — no PRD, Architecture, or
Plan was raised, and none would have added value. Unlike 0054, this report was written **before**
the commit, restoring the documented Build → Review → Commit order.

---

## Recommended Next Action

Approve and open the PR. Confirm CI is green before merging.

---

## Post-Completion Note — CHANGELOG regenerated

**Date:** 2026-07-30. Appended after the review was written; **Status: Complete** unchanged.

`task changelog` was run on this branch once `git-cliff` was available, adding an `## [Unreleased]`
section covering the five commits since `v2026.07`. The regeneration was folded into this branch
rather than a separate PR: PR #55 was still open, so regenerating from `main` would have produced a
`CHANGELOG.md` that was stale the moment #55 merged.

The section was first rendered as `[Unreleased]`, then cut as a real release on the user's
instruction: `git-cliff --tag v2026.08` rewrites the heading to `## [2026.08] - 2026-07-30` and
picks up the regeneration commit that could not list itself. This reproduces the `v2026.07`
convention exactly — the `chore(release)` commit *carries* the CHANGELOG rewrite, and the tag is
placed on that commit afterwards.

**The tag itself is not created in this change.** `main` is protected (PR required, strict
up-to-date), so the release commit reaches `main` only through this PR, and the merge rewrites its
SHA — as it did for #54. Tagging before the merge would leave `v2026.08` pointing at an orphaned
commit. The tag must be created on `main` after merge, then pushed.

The run emits `6 commit(s) were skipped due to parse error(s)`. This is expected, not a defect:
`cliff.toml` sets `filter_unconventional = true`, and every skipped commit is either a merge commit
or one of the two pre-convention initial commits (`Initial commit`,
`Initialize Claude Code operating layer`). `chore(release): v2026.07` is skipped separately and
deliberately by the `^chore\(release\)` parser rule. Verdicts are unaffected: the diff is purely
additive to a generated artifact, with no commands, paths, or secrets involved.
