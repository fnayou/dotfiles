# Review: chafa Image Preview Plan

**Number:** 0092
**Status:** Complete
**Date:** 2026-10-19
**Plan reviewed:** [0033-implement-chafa-image-preview](../plans/0033-implement-chafa-image-preview.md) (Draft, at `52f0c67`)
**PRD:** [0030-chafa-image-preview](../prd/0030-chafa-image-preview.md) (Approved)
**Files reviewed:** `docs/plans/0033-implement-chafa-image-preview.md`, and the files it cites

## Summary

Plan review of Plan 0033 — Implement chafa Image Preview, before approval. Two independent reviewers
ran as herdr workers, read-only, and each finding was checked against the files by the foreman:

- **codex** (open review brief, read-only sandbox): 3 blocking, 1 non-blocking.
- **pi** (14-step checklist, local model, read-only tools): 3 findings, of which 1 was valid.

The foreman found one more gap neither reviewer reported (`Taskfile.yml`). All valid findings are
fixed in the plan; the fixed Task 9 harness was rerun against the prototype and gave the expected
output for every case. Plan 0033 is ready for operator approval.

## Blocking Issues (all fixed)

1. **`rm` outside the repository** (codex B2). Task 9 ended with `rm -f "$t"` and `rm -r "$D"` in
   `$TMPDIR`; `.claude/rules/safety.md` forbids `rm` outside the repository. **Fixed:** both removed;
   temporary files are left to the OS, and Safety Checks says so.
2. **Task 1 changed the host without a marker** (codex B1, adjusted). The container install itself
   was already scoped to the container, but `docker run` pulls `debian:trixie` onto the host.
   **Fixed:** Task 1 is a `⚠️  MANUAL STEP` with the undo command (`docker image rm debian:trixie`),
   marker on the line directly above the fence.
3. **No-chafa behaviour was not tested** (pi). The PRD criterion "With chafa removed from `PATH`,
   `cat` and the suffix aliases behave exactly as before" had no check; the prototype had one but
   the plan dropped it. **Fixed:** Task 9 harness adds a no-chafa case, expected
   `cat: alias;BAT a.png;0`.

## Non-Blocking Suggestions (fixed)

1. **Task 1 exit status** (codex B3). `…; echo "exit=$?"` always returned 0. **Fixed:** the script
   runs under `bash` with `set -euo pipefail`, writes chafa output to files instead of piping into
   `head` (which would raise `SIGPIPE` under `pipefail`), and the missing-file check fails the run
   only if chafa accepts it. `exit=0` is now meaningful.
2. **Packages guide lists** (codex N1). `docs/guides/packages-setup.md` names tools in line 67, the
   pacman line 99, the apt line 157 and three "individual tools" lists. **Fixed:** Task 7 adds
   `chafa` to each.
3. **`Taskfile.yml` install lines** (found by the foreman). `task deps:arch` (line 191) and
   `task deps:debian` (line 230) print hard-coded install lines without chafa. **Fixed:** Task 7
   edits both; `Taskfile.yml` added to Files Affected.
4. **`cat Photo.Png` not automated** (pi reported NOT COVERED). It was covered by Task 10 step 1;
   the harness now also checks it.

## Findings Not Accepted

- **pi CHECK 14** flagged `sudo` lines in Task 3. They are the commented `# sudo pacman -S chafa`
  and `# sudo apt install chafa` lines that the manifests carry by design. The checklist's
  expectation was too narrow; no change.
- **PRD 0030 acceptance criterion** for redirects still ends in `rm -f "$t"`. The plan's Task 9 no
  longer runs it. Changing the approved PRD would need re-approval; the criterion is met by Task 9's
  `cmp` check without the cleanup.

## Checks

| Check | Result | Evidence |
|---|---|---|
| Plan anchors exist | Met | pi checks 4–12 OK; `aliases.zsh:17` and `:25`, `Brewfile:43`, `arch/packages.txt:29`, `check-zsh-deps.sh:47`, zsh README `:125`, `zsh-setup.md:82`, `website/features/shell.md:66`, `website/usage/aliases.md:29` |
| Every PRD acceptance criterion mapped to a task | Met after fix | pi step 3; no-chafa case added |
| zsh block correctness | Met | codex read-through; prototype harness 12/12 expected outputs |
| Commit messages | Met | pi check 13; codex |
| Safety: no stow, no `$HOME` change, no `rm` outside repo | Met after fix | Blocking 1 and 2 |

## Safety Verdict

PASS — after fixes: no `rm` outside the repository, the only host change (Docker image pull) is a
marked manual step with its undo, and no stow command or `$HOME` change is planned.

## Privacy Verdict

PASS — no hostnames, user paths or secrets in the plan.

## Cross-Platform Verdict

PASS — manifests and guide edits are per platform; Debian's apt chafa is checked in Task 1; the zsh
block has no OS branch.

## Documentation Verdict

PASS — after fixes: every document and printed install line that lists tools gets chafa; the
marker sits directly above its fence.

## Recommended Next Action

1. Operator: approve Plan 0033 explicitly (e.g. "Approve plan 0033"). The Builder then starts with
   Task 1.
