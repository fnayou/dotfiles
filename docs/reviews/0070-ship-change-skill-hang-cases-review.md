# Review: Add Two Measured Hang Cases to the ship-change Skill

**Number:** 0070
**Status:** Complete
**Date:** 2026-08-04
**Plan reviewed:** None — corrective documentation fix (same path as review 0056)
**Branch:** `docs/ship-change-hang-cases`

**Files reviewed:**

- `.claude/skills/ship-change/SKILL.md`

---

## Summary

Extends the skill's "Environment gotchas" section with two `git commit` stalls hit while shipping
PRs #64, #65, and #66. Review 0056 previously corrected this same section's hang guidance; this adds
the shapes that guidance did not cover.

## What was missing

The skill documented exactly one stalling shape — `git commit -F -`, the heredoc-on-stdin case — and
attributed it to the heredoc not surviving the hook's command rewrite. Two shapes outside that
description stalled for the full timeout during this session:

| Shape | Result |
|---|---|
| heredoc writing `$MSG_FILE`, then `git commit -F "$MSG_FILE"` in the same call | stalled at 2m, commit never ran |
| `git add -A` + `git commit -F …` + `git push` chained with `;` in one call | stalled at 3m, commit never ran |

The first widens the existing rule: the trigger is a heredoc **anywhere in the same command as the
commit**, not only one feeding stdin. The second contains no heredoc at all, so the documented
quoting explanation does not reach it.

Both left the change **staged but uncommitted** — the failure is inert, not partial, which is worth
stating because the natural reaction is to fear a half-finished commit and start cleaning up.

## Mechanism

Attributed to the permission-prompt signature the skill already describes, and grounded in the
repository's own configuration rather than left as speculation: `.claude/settings.local.json` allows
`Bash(rtk git *)`, a prefix matcher against the visible command string. A compound string retains
`;` and later commands after the rewritten prefix, so it fails to match the entry that auto-approves
plain git and queues a prompt instead. This predicts the observed detail that the stall lands on the
first git call and nothing after it runs.

## Contradiction resolved

The skill's existing measured table (rtk 0.44.1) contains the row
`plain git add && git commit, direct Bash call | completes normally`, which the second new case
directly contradicts.

The prior measurement was **not deleted**. It is annotated as having held when taken but not being
reliable, with a pointer to the split form. Removing another session's recorded observation to make
the document self-consistent would destroy evidence; flagging it preserves both readings and lets a
future session see the shape is intermittent.

## Blocking Issues

None.

## Non-Blocking Findings

1. **The mechanism is inferred, not proven.** It fits every observation and the allow-list is real,
   but no instrumented confirmation that a prompt was queued was captured. Read-only chains such as
   `git add …; git diff --staged --stat` succeeded in the same session, which the prefix-matcher
   account does not obviously explain. Stated as "consistent with" rather than "caused by".
2. **Guidance is session-specific.** The allow-list quoted lives in `.claude/settings.local.json`,
   which is per-machine. A differently configured machine may not see these stalls at all.

## Safety Verdict

PASS — a skill document only. No executable code, no Stow operation, no `$HOME` path. The advice is
strictly more conservative than what it replaces: split calls and inspect state before retrying.

## Privacy Verdict

PASS — no secrets, tokens, or credentials. The one configuration value quoted, `Bash(rtk git *)`, is
already committed in `.claude/settings.local.json`. No absolute machine paths or usernames added.

## Documentation Verdict

PASS — measurements presented as a table with outcomes, the working form given as explicit rules, and
the contradiction with the older table annotated in place rather than silently reconciled. The
following "Script files" section was adjusted so it now reads as the sanctioned multi-step escape
hatch rather than as a caution against an "imagined hang".

## Status-Sync Check

No Stow package added, removed, or first stowed. Status blocks unaffected.

## Recommended Next Action

Commit as a single `docs(claude)` change.
