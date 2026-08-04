# Zsh PATH-Timing Guidance Review

**Number:** 0069
**Date:** 2026-08-04
**Status:** Complete
**Type:** Documentation fix review (bug-driven)
**Related Documents:** ADR-0062, ADR-0023, ADR-0026, ADR-0027, ADR-0049, `docs/guides/zsh-setup.md`, `stow/common/zsh/`

---

## Review Scope

Validates the documentation correction prompted by a reproducible completion failure on the Arch
workstation: in a new Alacritty window, `herdr <Tab>` and `task <Tab>` completed filenames instead of
arguments; `exec zsh` fixed both until the next new window.

No PRD or plan was produced. This follows the lightweight documentation-fix path already used by
reviews 0056, 0065, and 0066: the change corrects wrong guidance in existing documents, adds no Stow
package, and alters no shell logic. Every `.zsh` file that runs at shell startup is untouched.

## Root Cause

`local.zsh` is sourced last (step 11 of `index.zsh`) so that it overrides the managed layers
(ADR-0023). `local.zsh.example` also taught it as the home for machine `PATH` setup — specifically
`brew shellenv` plus hand re-init of `zoxide` and `fzf`.

Those two roles conflict. By step 11:

- every optional layer has already run its `command -v <tool> || return` guard, and a failed guard
  registers nothing and never retries;
- `compinit` has already read `fpath` (step 5, ADR-0049), so a completion directory added later is
  never scanned.

So `herdr.zsh` (step 6c) returned early and never called `compdef _herdr herdr`, and `_task` was never
autoloaded from brew's `share/zsh/site-functions`. `exec zsh` masked the bug because `brew shellenv`
exports both `PATH` and `FPATH` and the replacement shell inherits them.

## Verification

Clean-environment interactive shell, before and after moving `brew shellenv` into `~/.zshrc` above the
managed block:

```bash
env -i HOME="$HOME" TERM=xterm PATH=/usr/local/sbin:/usr/local/bin:/usr/bin zsh -ic \
  'print -r -- "herdr=${+_comps[herdr]} task=${+_comps[task]}"'
```

| | `_comps[herdr]` | `_comps[task]` | `_comps[ssh]` | `speed` fn |
|---|---|---|---|---|
| before | 0 | 0 | 1 | 1 |
| after | 1 | 1 | 1 | 1 |

`ssh` and `speed` were never affected — `ssh` and `cloudflare-speed-cli` are in `/usr/bin`.

zoxide re-checked after removing the `local.zsh` re-init line: `chpwd_functions` holds exactly one
`__zoxide_hook`, `cd` resolves to the zoxide function, and `_omp_precmd` is present in
`precmd_functions` — confirming zoxide still initialises after Oh My Posh, as `index.zsh` step 10
requires, with no duplicate registration.

## Changes Reviewed

| File | Change |
|---|---|
| `docs/decisions/0062-…-above-the-managed-block.md` | New ADR — records the discovery/precedence split |
| `docs/decisions/README.md` | Index row for 0062 |
| `stow/common/zsh/.config/zsh/local.zsh.example` | Removed the brew + re-init recipe; states what does **not** belong here and why |
| `stow/common/zsh/.config/zsh/zshrc.example` | Starter-lines section now shows `PATH`/`brew shellenv` placement above the block |
| `stow/common/zsh/README.md` | New two-row table splitting `~/.zshrc` (discovery) from `local.zsh` (precedence) |
| `docs/guides/zsh-setup.md` | New step 3b-bis; scope note in step 5; Troubleshooting entry with the clean-env check |
| `docs/zsh-migration.md` | Note at step 5 clarifying item 7 means values that must *win*, not be *found* |
| `website/features/shell.md` | Warning admonition alongside the existing `local.zsh` info box |
| `website/reference/troubleshooting.md` | Public "A completion only works after `exec zsh`" entry |

Machine-local changes, applied with user approval and outside the repository: `~/.zshrc` (brew block
added above the managed block) and `~/.config/zsh/local.zsh` (brew block and both re-init lines
removed). Neither is tracked.

## Blocking Issues

None.

## Non-Blocking Findings

1. **`docs/decisions/README.md` is stale by 11 entries** — ADRs 0049–0053 and 0056–0061 exist on disk
   but have no index row. Pre-existing drift, unrelated to this change; 0062 was added on top. Worth a
   separate backfill commit so the index is trustworthy again.
2. **The re-init pattern may exist on other machines.** Any machine whose `local.zsh` was written from
   the old example carries the same latent bug. The Troubleshooting entry gives the check command; no
   automated detection was added.
3. **`docs/zsh-migration.md` remains historically inaccurate** in other respects (it references
   `macos.zsh.example` and describes completions as living in `shared.zsh`). Left as-is — it is a
   historical migration record, and only the actively misleading `PATH` guidance was corrected.

## Safety Verdict

PASS — no shell logic changed; no startup file in the repository executes anything new. The two
`$HOME` edits were explicitly approved by the user in-session, are additive/subtractive comments and
one `eval` relocation, and were verified by a clean-environment shell. No `rm`, `mv`, `ln -s`, or
`stow --adopt` was run. No Stow operation was performed.

## Privacy Verdict

PASS — no secrets, tokens, or credentials introduced. The one concrete path committed,
`/home/linuxbrew/.linuxbrew/bin/brew`, is a fixed, documented linuxbrew location, not a
machine-identifying or private path; it already appeared in the previous example text. No username
appears in any committed file — the guide's clean-env command uses `"$HOME"`. `local.zsh` itself
remains git-ignored and physically outside the working tree (ADR-0026).

## Documentation Verdict

PASS — the corrected rule appears in all five places a reader could hit it: the template that caused
the bug (`local.zsh.example`), the template that shows the fix (`zshrc.example`), the package README,
the setup guide (placement + troubleshooting), and the public site. The ADR records the mechanism and
the rejected alternatives. All commands are copy-pasteable; the clean-env check is read-only and needs
no danger marker.

## Status-Sync Check

No Stow package added, removed, or first stowed. The `AGENTS.md` §2 and `CLAUDE.md` status blocks
require no change (`status-sync` rule).

## Recommended Next Action

Commit as a single focused `docs(zsh)` change. Handle the ADR index backfill (finding 1) as a separate
commit.
