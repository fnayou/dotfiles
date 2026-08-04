# Review: `task doctor` Implementation

**Number:** 0071
**Status:** Complete
**Date:** 2026-08-04
**Plan reviewed:** None — standalone read-only tooling, built ahead of the agent install/update PRD
**Branch:** `feat/doctor`

**Files reviewed:**

- `scripts/doctor.sh` (new)
- `Taskfile.yml` — `doctor`, `doctor:verbose`
- `docs/decisions/0063-machine-health-check-is-a-read-only-offline-task.md` (new)
- `docs/guides/doctor.md` (new)
- `docs/decisions/README.md`, `README.md`, `website/reference/troubleshooting.md`

---

## Summary

Adds a read-only machine health check. Built first, ahead of the agent-facing install and update
documents, so those documents have a trustworthy terminal step instead of each re-deriving what
"correctly installed" means.

## The detector was tested against its own failure mode

A check that never fires is worse than no check, so the failure path was exercised rather than
assumed. A sandbox `$HOME` was built with `.config/zsh` and `.local/share/zinit` symlinked to the real
ones, so **`PATH` placement was the only variable**, and three `~/.zshrc` variants were probed:

| `~/.zshrc` variant | `_comps[herdr]` | `_comps[task]` |
|---|---|---|
| A. no brew line | 0 | 0 |
| B. brew line **above** the managed block | 1 | 1 |
| C. brew line **below** the managed block (the ADR-0062 bug) | 0 | 0 |

Variant C reproduces the original bug exactly and the probe reports it. An earlier attempt at this
test omitted the Zinit symlink, which introduced a second variable; it was redone rather than
reasoned around.

Nothing outside the sandbox was written, and the sandbox was removed on exit.

## A defect found and fixed during verification

The first run reported `zoxide registered 13 chpwd hooks — initialised more than once`. False.
`${#${(M)chpwd_functions:#*zoxide*}}` measures the **string length** of the joined match, not the
element count, and `__zoxide_hook` is exactly 13 characters. There was one hook.

Fixed by assigning to a real array first (`zhooks=(${(M)chpwd_functions:#*zoxide*})`, then
`${#zhooks}`), with a comment recording the trap. Worth stating plainly: had this shipped, the first
thing every user saw would have been a confident, wrong warning.

## Portability

- No `readlink -f` and no `realpath` — neither is portable to stock macOS. Symlink resolution uses a
  `cd -P` helper.
- No `stat`, whose flags differ between BSD and GNU.
- OS detection tests `/etc/arch-release` before `/etc/debian_version`, per the cross-platform rule.
- Verified on Arch only. macOS and Debian are unexercised; the constructs avoided are the known
  divergences, but this is stated rather than claimed as tested.

## Blocking Issues

None.

## Non-Blocking Findings

1. **`scripts/detect-os.sh` does not know about Debian.** It prints `unsupported: $OSTYPE` and exits 1
   on Debian, even though ADR-0053 made Debian a first-class platform and `check-zsh-deps.sh` already
   detects all three. `task detect`'s description also says "macos or arch". Pre-existing, unrelated
   to this change, and deliberately **not** folded in to keep the commit focused. `doctor.sh` does its
   own three-platform detection. Worth a separate fix.
2. **Only Arch was exercised.** See Portability above.
3. **The probe costs about a second** — it starts a real interactive zsh, loading Zinit and plugins.
   Acceptable for an on-demand check; it would not be acceptable in a shell hot path.
4. **The negative test is not committed.** It lives in scratch. If the probe logic grows, it should
   become a real `scripts/check-doctor.sh` so the detector stays honest.

## Safety Verdict

PASS — read-only by construction. No `rm`, `mv`, `ln -s`, `stow`, or any write inside `$HOME`. The
only mutation anywhere is `mktemp -d`, removed by an `EXIT` trap. The probe subprocess gets
`HISTFILE` redirected into that temp dir, so real shell history cannot be appended to. Remediation is
printed as dry-run commands, never executed — a repairing doctor was explicitly rejected in ADR-0063.

## Privacy Verdict

PASS — `local.zsh` is inspected for `PATH` assignments but reported by **line number only**; its
contents are never printed, which matters because it is the designated home for private values. No
secrets, tokens, or credentials introduced. `$HOME` is referenced via the variable throughout; the one
absolute path in the new files, `/home/linuxbrew/.linuxbrew/bin/brew`, appears only in guide prose and
was already present in the repository.

## Documentation Verdict

PASS — ADR-0063 records the four defining properties and four rejected alternatives. The guide
explains the legend, every check, the probe, the common findings with copy-pasteable dry-run commands
(destructive one carries the manual-step marker), and an explicit "what it deliberately does not do".
Indexed in `docs/decisions/README.md`, linked from `README.md`, and made the first stop in the public
troubleshooting page.

## Status-Sync Check

No Stow package added, removed, or first stowed. Status blocks unaffected.

## Recommended Next Action

Commit as `feat(doctor)`. Then begin the PRD for the agent-facing install and update documents, whose
final step is `task doctor`.
