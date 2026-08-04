# Review: Decision Record Consistency Check

**Number:** 0073
**Status:** Complete
**Date:** 2026-08-04
**Plan reviewed:** None — corrective fix plus the tooling that prevents its recurrence
**Branch:** `fix/adr-record-consistency`

**Files reviewed:**

- `scripts/check-decisions.sh` (new)
- `Taskfile.yml` — `check:decisions`
- `.github/workflows/ci.yml` — "Decision record consistency" step
- `docs/decisions/0013-include-based-git-config-strategy.md`
- `docs/decisions/0014-gitconfig-common-filename.md`
- `docs/decisions/README.md`

---

## Summary

Closes the last known contradiction in the ADR record and makes the class of defect mechanically
detectable. ADR-0064 recorded that two audits had missed contradictions of this shape; this is the
tooling that answer implied.

## The contradiction fixed

ADR-0030 declares `**Supersedes:** ADR-0013 (include-based Git config strategy, in part), ADR-0014
(gitconfig-common filename)`, but both targets still read `Accepted`.

Resolved asymmetrically, because the two are not alike:

- **ADR-0014** decided *only* the filename `.gitconfig.common` at `~/.gitconfig.common`. ADR-0030's
  XDG layout replaced that outright, so nothing it decided is still in force → `Superseded by 0030`.
- **ADR-0013** decided both the include-based *strategy*, which is still current, and the file's
  location, which is not → `Superseded in part by 0030`, with a header note telling the reader which
  half to trust.

Collapsing 0013 to a plain `Superseded` would have discarded a decision still in force; leaving it
`Accepted` implied the `~/.gitconfig.common` paths in its body were live. Both were wrong, which is
why the status vocabulary needed a third form here.

## The checker

`scripts/check-decisions.sh` — read-only, no `$HOME`, no network, so it runs in CI. Six checks: every
ADR indexed exactly once; index status matches the file's; index links resolve; every `Supersedes: Y`
matched by a superseded status on Y; every ADR has a status; no duplicate numbers.

**Check 4 is the one that matters** — it compares ADRs against *each other*, which is precisely what
review 0069's audit structurally could not do, and is why ADR-0036 and ADR-0054 both passed as
`Accepted` while flatly contradicting one another.

### A false positive that had to be designed out

A naive implementation greps four-digit numbers from the `Supersedes:` line and reports ADR-0032,
whose line reads:

```
**Supersedes:** N/A (lifts the ADR-0009 restriction for this specific, bounded case)
```

That names 0009 without superseding it — the bounded-lift pattern ADR-0052 also uses. The checker
therefore strips parenthesised segments *before* extracting numbers, which also handles markdown link
targets, whose number is already present in the label.

This is verified continuously rather than by a test: ADR-0032 is in the live record, so any
regression turns the baseline run red.

## Verification

Baseline: `PASS: decision record is self-consistent (64 ADRs)`.

The failure paths were exercised, not assumed. A sandbox mirroring the repo layout was mutated one
defect at a time:

| Injected defect | Caught as |
|---|---|
| Index status disagrees with file | `0064 — file says 'Accepted', index says 'Superseded by 0099'` |
| ADR removed from the index | `0063 — not listed in README.md` |
| Supersession not mutual | `0036 — superseded by 0064, but its status reads 'Accepted'` |
| Index link to a missing file | `index links to 0063-nonexistent-file.md, which does not exist` |
| ADR with no Status field | `0061 — no Status field in 0061-...md` |

Row three is the exact defect that started this.

## Blocking Issues

None.

## Non-Blocking Findings

1. **Only mechanical contradictions are caught.** The checker verifies that supersession is *declared*
   mutually. It cannot detect two ADRs that contradict each other in prose without either citing the
   other — which is exactly how ADR-0036 and ADR-0054 diverged. That case was found by a human
   reading, and nothing here would have caught it. The tooling narrows the gap; it does not close it.
2. **`Superseded in part` is a new status not listed in `DOCUMENT-LIFECYCLE.md`**, whose ADR table is
   `Draft → Approved` only and does not describe ADR supersession at all. The document should be
   extended, or the vocabulary formalised. Left out to keep this change focused.
3. **The CI step needed an SSH push.** The `gh` token lacks `workflow` scope, so a push touching
   `.github/workflows/` fails over the HTTPS remote. Not a defect in this change, but it will recur
   for anyone editing CI.

## Safety Verdict

PASS — the script reads `docs/decisions/` and prints; it has no write, delete, or move operation and
touches nothing outside the repository. The Taskfile entry and CI step invoke it unmodified.

## Privacy Verdict

PASS — no secrets, credentials, or machine-identifying values. The script reads only committed
documentation.

## Documentation Verdict

PASS — the script's header states what it checks and *why the gap existed*, citing review 0069 and
ADR-0064, so a future reader understands the check is a response to a real miss rather than
speculative rigour. Both amended ADRs carry header notes distinguishing live from historical content.

## Status-Sync Check

No Stow package added, removed, or first stowed. Status blocks unaffected.

## Recommended Next Action

Commit as `fix(decisions)`. Consider extending `DOCUMENT-LIFECYCLE.md` with the supersession
vocabulary (finding 2).
