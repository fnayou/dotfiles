# Plan: zsh Completion for the pi Coding Agent CLI

**Number:** 0040
**Status:** Complete
**Date:** 2026-11-11
**PRD:** [0036](../prd/0036-pi-agent-zsh-completion.md)
**Architecture:** [0032](../architecture/0032-pi-agent-zsh-completion-architecture.md)

## Objective

Add a guarded, read-only zsh completion for the `pi` CLI (`pi.zsh`, slot 6h in `index.zsh`) with a
test script, documentation, ADR 0088 and a review.

## Assumptions

- PRD 0036 and Architecture 0032 are Approved.
- `pi` 1.5.2 is installed on this machine; macOS only. Arch and Debian are untested and the guide says so.
- The `zsh` package is already stowed with `--no-folding`. `pi.zsh` is a new file, so the user re-stows
  (dry run first). This plan does not run `stow`, and no `$HOME` file is edited by the agent.
- The test uses made-up `mcp.json` content in a temporary directory. The real `~/.pi/agent/mcp.json`
  and `auth.json` are never read by tests or printed by an agent.
- No package is added or removed, so the status blocks in `AGENTS.md` and `CLAUDE.md` do not change.
- Work is on branch `feat/pi-completion`. The unrelated `herdr` change stays unstaged.

## Ordered Tasks

1. **Spike, read-only.** Run `pi --list-models`, `pi list` and each `pi <command> --help` and record:
   the column layout of `--list-models` and the line shape of `pi list` (including the empty case when
   `pi list` shows no packages), and every flag per subcommand. Note findings in Architecture 0032's
   Open Questions as a short "Spike results" section. Stop and report if a list shape is not parseable.
2. **Write `scripts/test-pi-completion.sh`** first, covering the checks in Decision 5 (load with a stub
   `pi`, no-op without `pi`, no mutating call in `pi.zsh`, `mcp.json` helper returns keys only).
   Run it: it fails because `pi.zsh` does not exist.
3. **Write `stow/common/zsh/.config/zsh/pi.zsh`**: guard, header (validated against pi 1.5.2),
   live-candidate helpers, `_pi` with the subcommand and option trees, `compdef _pi pi`, fzf-tab preview
   zstyles using read-only `--help`. Run the test script until it passes; run `zsh -n`.
4. **Wire the slot**: add 6h to `index.zsh`. Check a fresh `zsh -i -c 'whence -w _pi'` in a fake home that
   holds the new file, and that a shell without `pi` on `PATH` loads with no output.
5. **Check completion behaviour** with zsh's `zpty` or `compadd` capture where possible (subcommands
   offered, `--thinking` values, `mcp remove` names from a made-up file). Record what could not be tested
   non-interactively; those go to the user task.
6. **Docs**: new section in `docs/guides/zsh-setup.md` and `website/guides/zsh-setup.md` (what is
   completed, live sources, what is never run, re-stow with dry run and `MANUAL STEP`, rollback, platform
   note); table and layout rows; the `website/features/shell.md` row. Apply to each guide separately (the
   two copies already differ).
7. **ADR 0088** and the row in `docs/decisions/README.md`. Run `task check:decisions` and
   `task brand:check`; regenerate art only if reported stale.
8. **Review**: run `review-change`, write review 0112, mark this plan Complete if all verdicts PASS.
9. **User validation**: the user re-stows `zsh` (dry run first), opens a new terminal, and checks Tab on
   `pi `, `pi --model `, `pi --thinking `, `pi mcp remove ` and `pi remove `. The user reports the result.
10. **Ship** with `ship-change` on `feat/pi-completion`, staging only the feature paths (not the `herdr`
    change). Merge only when the user says so, with `gh pr merge --rebase`.

## Files Affected

- `stow/common/zsh/.config/zsh/pi.zsh` — created
- `stow/common/zsh/.config/zsh/index.zsh` — modified (slot 6h)
- `scripts/test-pi-completion.sh` — created
- `docs/guides/zsh-setup.md`, `website/guides/zsh-setup.md`, `website/features/shell.md` — modified
- `docs/decisions/0088-pi-agent-zsh-completion.md`, `docs/decisions/README.md` — created, modified
- `docs/prd/0036-…`, `docs/architecture/0032-…`, this plan, `docs/reviews/0112-…` — created
- Nothing is deleted.

## Safety Checks

- `pi.zsh` calls only `pi --list-models`, `pi list`, `pi <command> --help` and a `jq` key read.
- No test or command reads real `mcp.json` values, `auth.json`, sessions or history.
- No `stow`, `rm`, `mv` or `ln -s` against `$HOME` is run by an agent after this plan starts.
- Staged diff is audited for secrets and `.DS_Store` before commit.

## Validation Commands

```bash
bash scripts/test-pi-completion.sh
zsh -n stow/common/zsh/.config/zsh/pi.zsh
task check:decisions
task brand:check
git status --short
```

## Rollback Strategy

Before merge: `git switch main` and delete the branch. After the user re-stows: remove the link with
`stow --dir=stow/common --target="$HOME" --no-folding --delete zsh` (⚠️ MANUAL STEP, dry run with
`--simulate` first) or delete the slot line in `index.zsh` and revert the commit. A completion file has
no other state.

## Completion Criteria

- [ ] `bash scripts/test-pi-completion.sh` passes.
- [ ] `pi.zsh` is a no-op without `pi`; `zsh -n` passes; a new shell starts without output.
- [ ] Tab behaviour confirmed by the user in a new terminal.
- [ ] Guides, site page, ADR 0088 and index updated; `task check:decisions` and `task brand:check` pass.
- [ ] Review 0112 has Safety, Privacy and Documentation PASS.
