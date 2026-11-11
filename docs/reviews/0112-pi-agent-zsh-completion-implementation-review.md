# Review: pi Agent zsh Completion Implementation

**Number:** 0112
**Status:** Complete
**Date:** 2026-11-11
**Plan reviewed:** 0040 — zsh Completion for the pi Coding Agent CLI
**Files reviewed:**
`stow/common/zsh/.config/zsh/pi.zsh`, `stow/common/zsh/.config/zsh/index.zsh`,
`scripts/test-pi-completion.sh`, `docs/guides/zsh-setup.md`, `website/guides/zsh-setup.md`,
`website/features/shell.md`, `docs/decisions/0088-pi-agent-zsh-completion.md`,
`docs/decisions/README.md`, PRD 0036, Architecture 0032, Plan 0040.

## Summary

Reviewed the implementation of Plan 0040 — zsh Completion for the pi Coding Agent CLI. The unrelated
`stow/common/herdr/.config/herdr/config.toml` change is in the working tree and must not be staged.

Checks run:

- `bash scripts/test-pi-completion.sh` passes: syntax, loads with a stub `pi`, defines nothing without
  `pi` and returns 0, model/provider/package candidates from the stub, MCP server names only (a fake
  secret, URL and command in the test `mcp.json` never appear), a missing `mcp.json` gives no
  candidates and no error, no mutating or secret-reading call in the code, and the `index.zsh` slot.
- A pseudo-terminal run (zsh `zpty`, stub `pi`, fake home) showed real Tab results for: `--thinking`
  values, `pi mcp remove` server names, `pi remove` package sources, the `auth` subcommands and the
  `update` flags. The pty output lagged one query behind and is noisy, so `pi --model` values,
  `pi auth login` providers and the `mcp add` flags are checked only by the unit tests and are left to
  the user's validation task.
- `zsh -n` passes on `pi.zsh` and `index.zsh`. A new interactive shell starts in 0.3 s.
- Stow dry run against the real home lists exactly one new link, `pi.zsh`, and no conflict.
  Nothing was stowed by this work.
- `task check:decisions` passes (77 ADRs). `task brand:check` reports the art current. The existing
  `test-fzf-history-delete.sh` still passes.
- No real `~/.pi` content was read by any test; the only secret-pattern hits are option names
  (`--no-refresh` help text mentions "tokens").

One fix during build: `pi.zsh` returned status 1 when `pi` is missing (`|| return` keeps the failed
status); it now returns 0.

## Blocking Issues

- None.

## Non-Blocking Suggestions

- `docs/guides/zsh-setup.md` and `website/guides/zsh-setup.md` were already different (the docs copy
  has no completion section at all). The pi section was added to each separately.
- The tree is static: new pi commands and extension flags are not completed until the file is updated.
- Arch and Debian are untested. The file uses `compdef`, `_arguments`, `compadd`, `awk` and optional
  `jq`.
- `pi list` output is parsed by shape (two-space-indented lines). If pi changes that format the package
  list becomes empty; it does not break completion.
- Consider running `scripts/test-pi-completion.sh` in CI (needs `zsh`).

## Safety Verdict

PASS — The file runs only `pi --list-models`, `pi list` and a `jq` read of key names. No `stow`, `rm`,
`mv` or `ln -s` against `$HOME` is run or shipped as automated behavior; the re-stow is a `MANUAL STEP`
with a dry run first. The preview is limited to a fixed list of subcommand names.

## Privacy Verdict

PASS — `mcp.json` is read for key names only and a test asserts no value leaks. `auth.json`, sessions
and credentials are never read. Test data is made up; no `$HOME` content is in the repository.

## Documentation Verdict

PASS — Both guides, the site feature page, ADR 0088 and the index row are updated, with the live
sources, what is never run, the re-stow with dry run and `MANUAL STEP`, rollback, and the platform
note. PRD, architecture, plan and ADR references are accurate. No status block change is needed: no
package was added.

## Recommended Next Action

Approve and commit with `ship-change` on `feat/pi-completion`, staging only the paths above plus the
PRD, architecture, plan and this review (not the `herdr` change). Then re-stow `zsh` (dry run first),
open a new terminal, and check Tab on `pi `, `pi --model `, `pi auth login ` and `pi mcp add --`.
