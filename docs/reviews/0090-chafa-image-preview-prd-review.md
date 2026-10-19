# Review: chafa Image Preview PRD

**Number:** 0090
**Status:** Complete
**Date:** 2026-10-19
**PRD reviewed:** [0030-chafa-image-preview](../prd/0030-chafa-image-preview.md) (Draft, at `6da30b9`)
**Architecture:** none — the change adds no package, directory or structural decision
**Files reviewed:** `docs/prd/0030-chafa-image-preview.md`

## Summary

PRD review of PRD 0030 — Image Preview in the Terminal with chafa, before approval. The PRD's
claims were checked against `stow/common/zsh/.config/zsh/aliases.zsh`, the package manifests,
ADR-0045, and the documentation that describes `cat` and `bat` today. Its test results (chafa
1.18.3 and herdr 0.9.5 on Ghostty, 2026-10-19) were run in this session and match the PRD.

No architecture document is needed: the change edits one existing zsh file, three manifests and
docs, with no new package or layout decision. The approval gate goes straight from this PRD to the
plan.

Two blocking issues: the per-file routing rule is ambiguous for `bat` options that take a value, and
the Scope list misses five documents that describe today's `cat` behaviour.

## Blocking Issues

1. **Routing is undefined for options with values.** Goals route "each file" to chafa or `bat`, and
   Constraints say `bat` options keep working. `bat` options such as `-l md`, `-r 1:20`,
   `-H 3`, `--theme X` and `--style plain` take a value. Per-file routing that treats every
   non-option word as a file would send `md` or `1:20` to `bat` as a file name. The acceptance
   criterion `cat -n notes.md` does not cover this.
   **Fix:** state that when no argument is an image file, all arguments go to `bat` exactly as
   given, in one call (today's behaviour). Per-file routing applies only when at least one argument
   is an existing image file. Add an acceptance criterion for `cat -l md notes.txt`.
2. **Scope misses documents that describe `cat` today.** These would go stale:
   - `website/usage/aliases.md:35-36` (`cat` → `bat`, suffix alias table)
   - `docs/guides/zsh-setup.md:82` (bat suffix aliases row)
   - `docs/guides/packages-setup.md` (package install lists)
   - `website/features/shell.md` and `website/features/packages.md`
   **Fix:** add them to Scope, or state which of them stay unchanged and why.

## Non-Blocking Suggestions

1. **Text path when `bat` is absent.** On a Debian machine with apt chafa and no `bat`, the PRD does
   not say what `cat notes.md` does. Today it is the real `cat`. State that the text path falls back
   to the real `cat` when `bat` is not on `PATH`.
2. **Alias to function.** Replacing `alias cat='bat'` with a function needs the alias removed first;
   in zsh an alias expands while a `cat()` definition is parsed. A plan detail, worth one line in
   Constraints so the plan does not miss it.
3. **Acceptance criterion uses `/tmp/x`.** Prefer `mktemp` so the check is copy-pasteable without
   clobbering a file.
4. **`TERM_PROGRAM` across SSH and remote herdr.** SSH does not forward `TERM_PROGRAM` by default, so
   from a herdr pane over SSH chafa gets symbols (accepted, Resolved Question 5). On a remote herdr
   session (`herdr --remote`) the remote pane does see `TERM_PROGRAM=herdr`; whether its graphics
   reach the local Ghostty is untested. Worth a sentence so the plan does not claim it.
5. **Dependency check.** `task deps:check:zsh` (`scripts/check-zsh-deps.sh`) lists shell-tier tools.
   Decide whether chafa is reported there as optional.
6. **Edge cases.** Name what happens to a file whose name starts with `-` and to `--`. Keeping
   `bat`'s own handling for every non-image call (Blocking Issue 1 fix) covers most of it.

## Checks

| Check | Result | Evidence |
|---|---|---|
| Current alias and suffix aliases quoted correctly | Met | `aliases.zsh:17-23` |
| chafa versions per platform | Met | Homebrew 1.18.3 (installed), Arch `extra` 1.18.3-1, Debian trixie 1.14.5-1 |
| Debian servers on Homebrew on Linux run `bat` by its normal name | Met | Checked on a Debian server: `bat` 0.26.1 from Homebrew |
| herdr kitty graphics on by default | Met | herdr.dev/docs/configuration; `[terminal]` in `stow/common/herdr/.config/herdr/config.toml` does not set `kitty_graphics` |
| chafa detection fails inside herdr; forcing kitty shows pixels | Met | Tested in a herdr pane; operator confirmed the image |
| chafa writes symbol art, not bytes, to a pipe | Met | Tested; output starts with `\e[?25l` |
| BMP decodes only through CoreGraphics | Met | `chafa --version` loaders list has no BMP entry |
| zsh suffix aliases are case-sensitive | Met | Tested: `alias -s png` does not match `T.PNG` |
| Manifest layout matches ADR-0045 | Met | `packages/Brewfile`, `packages/arch/packages.txt`, `packages/debian/packages.txt` |
| No status-block change needed | Met | No stow package added, removed or first stowed |

## Safety Verdict

PASS — the PRD keeps package installation manual, forbids stow runs and `$HOME` changes, and
requires raw bytes in pipes so scripts and agents see unchanged output.

## Privacy Verdict

PASS — no hostnames, user paths, tokens or secrets. The Debian server check is described without
naming the host.

## Cross-Platform Verdict

PASS — macOS, Arch and Debian are treated separately for packaging and decoder support. BMP is
dropped because it decodes only on macOS. Detection inside herdr uses an environment variable, not
an OS branch.

## Documentation Verdict

FAIL — Blocking Issue 2: the Scope list misses five documents that would go stale.

## Recommended Next Action

1. Fix Blocking Issues 1 and 2 in PRD 0030, and consider the non-blocking suggestions.
2. Re-review the fixes.
3. Operator: approve PRD 0030 explicitly once the re-review passes. The plan follows.
