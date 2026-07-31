# Review: Documentation Numbering Deduplication

**Number:** 0066
**Status:** Complete
**Date:** 2026-07-31
**Plan reviewed:** none — direct user request, no PRD/plan cycle (see Summary)
**Files reviewed:** 12 files under `docs/` (6 renames, 6 reference updates)

## Summary

Reviewed the deduplication of colliding document numbers under `docs/plans/` and
`docs/reviews/`. Six filenames shared a number with another document in the same
directory, violating the numbering convention in `.claude/rules/documentation.md`
("avoids name conflicts as the project grows").

Collisions resolved:

| Directory | Collision | Moved file | New number |
|---|---|---|---|
| `docs/plans/` | `0013` | `real-zsh-git-configuration-plan` | `0025` |
| `docs/plans/` | `0016` | `implement-neovim-configuration` | `0026` |
| `docs/reviews/` | `0005` | `dotfiles-foundation-implementation-review` | `0062` |
| `docs/reviews/` | `0006` | `git-package-prd-architecture-review` | `0063` |
| `docs/reviews/` | `0033` | `git-local-setup-validation` | `0064` |
| `docs/reviews/` | `0034` | `git-setup-guide-fix-review` | `0065` |

Strategy: **trailing renumber** — the colliding file moves to the next free number
at the end of its sequence; the other keeps its number. Chosen by the user over
letter-suffix disambiguation and a full cascade renumber. Rationale: document
numbers function as stable identifiers cited by other documents, so preserving
existing identifiers outweighs perfect chronological sort order.

Which file kept each number was decided by **chain integrity**, not creation order.
For the `0033`/`0034` collision this meant moving the *earlier* git pair, because the
*later* real-zsh pair heads an unbroken `0033 → 0034 → 0035 → 0036` sequence; moving
the git pair kept it contiguous at `0064`/`0065` and left the real-zsh chain intact.

No PRD, architecture, or plan document was produced. This was a mechanical,
docs-only correction of an existing convention violation — it introduces no new
structure, no new package, and no executable behaviour. Recording the rationale
here is the appropriate level of documentation; step 7a (marking a plan Complete)
does not apply as no plan governs this change.

## Scope of change

- 12 files changed, 40 insertions, 40 deletions — exactly symmetric.
- Every changed line is a filename-token substitution; each added line is identical
  to the line it replaces except for the four-digit prefix. Verified by diffing
  added against removed lines.
- Internal `**Number:**` header fields updated in 5 of the 6 renamed files
  (`0064-git-local-setup-validation.md` carries no such field).
- `0062-dotfiles-foundation-implementation-review.md` previously carried the ad-hoc
  value `**Number:** 0005-impl` — the original author's workaround for this very
  collision. It now carries a real number.
- The number column of the audit table in `0011-document-status-audit.md` was
  updated alongside the filenames so the two agree again.

## Blocking Issues

None.

## Non-Blocking Suggestions

- `docs/reviews/` has no `0001` — the sequence starts at `0002`. Pre-existing gap,
  deliberately not closed, as closing it would require the cascade renumber the user
  declined.
- `docs/plans/` numbers no longer align 1:1 with `docs/prd/` numbers; the drift
  begins at the former `0013` collision and continues through the end of the
  sequence. Pre-existing and unchanged by this review — noted so it is not
  rediscovered as new.
- Historical review bodies (`0030`, `0031`, `0032`) contain absolute paths of the
  form `/Users/fnayou/works/dotfiles/...`, which are machine-specific and inconsistent
  with the repository's own path-safety rule. Pre-existing; this change only altered
  the filename component of four such lines and introduced none. Cleaning them up is
  a separate concern.

## Deliberate exception

`docs/reviews/0006-dotfiles-foundation-implementation-review.md:9` still references
the old name `0005-dotfiles-foundation-implementation-review.md`. This is
intentional and must not be "fixed":

> **Filename note:** User requested `0005-dotfiles-foundation-implementation-review.md`.
> Slot 0005 is taken by `0005-dotfiles-foundation-plan-revision-review.md`. Used 0006.

The line records what number the user originally *asked for*. Rewriting it to `0062`
would misstate the history it exists to preserve. It is the only surviving mention of
a pre-rename name.

## Safety Verdict

PASS — documentation-only change. No `stow`, `stow --adopt`, `rm`, `mv`, or `ln -s`
introduced anywhere in the diff. No file outside the repository root touched; no file
outside `docs/` touched. `$HOME` untouched — all renames were performed with `git mv`
inside the repository. No stow package added, removed, or first-stowed, so the
status-sync rule does not apply and the `AGENTS.md` §2 / `CLAUDE.md` status blocks
correctly remain unchanged.

## Privacy Verdict

PASS — no credentials, tokens, keys, passwords, or private hostnames added. The sole
match for the secret-pattern scan is prose inside a historical review quoting a grep
pattern (`signingkey\|[user]\|token\|password`), not a value. Absolute home paths
appear 4 times in added lines and 4 times in removed lines — balanced, confirming
these are pre-existing lines whose basename changed rather than new disclosures. No
`.DS_Store` staged.

## Documentation Verdict

PASS — verified after the change:

- No duplicate numbers remain in `docs/prd/`, `docs/architecture/`, `docs/plans/`,
  `docs/reviews/`, or `docs/decisions/`.
- No references to the six old filenames remain anywhere in `*.md`, `*.yml`, `*.sh`,
  or `*.json`, except the deliberate historical note documented above.
- Both markdown links targeting renamed files resolve
  (`../plans/0025-real-zsh-git-configuration-plan.md`,
  `../reviews/0063-git-package-prd-architecture-review.md`).
- The `Prior implementation review` link in `0062` targets a file that was not
  renamed and remains valid.

Not verified: a full broken-link audit across all of `docs/`. Both interpreter-based
scans (`python3`, `perl`) stalled without output in the working environment. The links
this change touched were verified individually and are correct by construction
(old token → new token, with all six new files confirmed present). Pre-existing broken
links elsewhere in `docs/`, if any, remain unaudited.

## Recommended Next Action

Approve and commit.
