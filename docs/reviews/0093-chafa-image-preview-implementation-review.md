# Review: chafa Image Preview Implementation

**Number:** 0093
**Status:** Complete
**Date:** 2026-10-20
**Plan reviewed:** [0033-implement-chafa-image-preview](../plans/0033-implement-chafa-image-preview.md)
**PRD:** [0030-chafa-image-preview](../prd/0030-chafa-image-preview.md) (Approved)
**Plan review:** [0092](0092-chafa-image-preview-plan-review.md)
**Commits reviewed:** `5a94596` (plan approval), `7f9e10c`, `deff09d`, `2db1d9c`, `be76c50`
**Files reviewed:** `stow/common/zsh/.config/zsh/aliases.zsh`, `packages/Brewfile`,
`packages/arch/packages.txt`, `packages/debian/packages.txt`, `scripts/check-zsh-deps.sh`,
`stow/common/zsh/README.md`, `docs/shell-dependencies.md`, `docs/guides/zsh-setup.md`,
`docs/guides/packages-setup.md`, `website/usage/aliases.md`, `website/features/shell.md`,
`Taskfile.yml`

## Summary

Implementation review of Plan 0033 — Implement chafa Image Preview. Tasks 1–11 were carried out on
branch `docs/chafa-image-preview-prd` (draft PR #85). The `aliases.zsh` block is byte-identical to
the plan's Task 2 text. The operator confirmed all eight Task 10 visual checks on 2026-10-20.

Plan 0033 — Implement chafa Image Preview is complete.

## Blocking Issues

None.

## Deviations From the Plan

1. **Task 1 expected output was wrong.** The plan expected the kitty output to start with
   `033 _ G`. Debian's chafa 1.14.5 and Homebrew's 1.18.3 both start with `\e[?25l` (hide cursor),
   followed immediately by the kitty graphics sequence `\e_Ga=T`. A second container run confirmed
   one kitty APC sequence in the `-f kitty` output and none in the symbols output. The flags
   `-f kitty`, `-s x10` and `--animate off` are all accepted by 1.14.5; the check passes.
2. **Task 1 `exit=` line.** Run from a zsh tool shell, `${PIPESTATUS[0]}` printed nothing. The
   second run, with no pipe after `docker run`, printed `exit=0`.
3. **Task 9 harness order.** The harness runs `cd $D/w` after `source $A`, so the repo's `chpwd`
   hook (`aliases.zsh`) prints a directory listing before each result. With `cd` moved before
   `source`, all 12 cases print exactly the expected outputs. The block itself is unaffected.
4. **Task 10 file names.** macOS file systems are case-insensitive by default, so `p.png` and
   `P.PNG` cannot share a directory. Check 7 used `p.png` and `Q.PNG`, which tests the same
   lowercase and uppercase suffix aliases.

## Checks

| Check | Result | Evidence |
|---|---|---|
| Debian chafa 1.14.5 accepts the flags (Task 1) | Met | `Chafa version 1.14.5`; kitty output `033 [ ? 2 5 l 033 _ G a = T`; symbols `10` lines; `missing-file: rejected`; `exit=0` |
| `zsh -n aliases.zsh` | Met | no output, exit 0 |
| Fresh `zsh -ic ''` exits 0 | Met | `exit=0`. It prints `can't change option: zle` twice; the same warning appears with the change stashed, so it predates this work |
| `whence -w cat imgview`; suffix alias count | Met | `cat: function`, `imgview: function`, `14` |
| `check-zsh-deps.sh` | Met | `PASS: chafa`; with chafa off `PATH`: `INFO: chafa (optional, …)` and exit 0 |
| Pipe and redirect byte-exact | Met | `pipe-ok`, `redirect-ok` on `dotfiles-readme-banner.png` |
| Stub routing harness (12 cases) | Met | all outputs match the plan table, after deviation 3 |
| No bat: `cat notes.txt` | Met | prints the file via the real `cat`; pipe `cmp` OK |
| `check-decisions.sh` | Met | `PASS: decision record is self-consistent (69 ADRs)` |
| Operator visual checks 1–8 (Task 10) | Met | Ghostty, herdr, remote herdr show pixels; Alacritty shows symbol art; tall image fits with prompt visible; GIF shows a still frame and returns; `./p.png`, `./Q.PNG` show the image; `cat -n notes.md`, `cat -l md notes.txt` unchanged |
| Commits | Met | Conventional Commits, author Aymen Fnayou, no AI attribution |

Every PRD 0030 acceptance criterion is met by one of the rows above.

## Non-Blocking Suggestions

1. If the Task 9 harness is reused, move `cd $D/w` before `source $A` (deviation 3).

## Safety Verdict

PASS — no stow run, no `$HOME` change beyond the already-stowed `aliases.zsh` link, no `rm`
outside the repository. Task 1 ran in a throwaway container; the `debian:trixie` image stays in
Docker for the operator to remove (`docker image rm debian:trixie`). The operator test directory
`/tmp/chafa-test` is left for the operator to remove.

## Privacy Verdict

PASS — the staged diffs contain no hostnames, user paths, IPs or secrets.

## Cross-Platform Verdict

PASS — chafa is listed per platform in each manifest's style; Debian's apt version is verified; the
zsh block has no OS branch and is guarded by `command -v chafa`.

## Documentation Verdict

PASS — every document in PRD 0030's Scope, plus the `Taskfile.yml` install lines, describes the new
behaviour.

## Recommended Next Action

1. Mark PR #85 ready for review and merge it.
