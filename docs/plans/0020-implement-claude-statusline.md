# Plan: Implement Claude Code Statusline Package

**Number:** 0020
**Status:** Approved
**Date:** 2026-06-24
**PRD:** 0017
**Architecture:** 0017

## Objective

Create the `stow/common/claude` package that tracks the portable Claude Code status line
script, update both status blocks to record it as added-but-not-stowed, and stage everything
for a user-approved commit — without stowing to `$HOME`.

## Assumptions

- PRD 0017 and Architecture 0017 are both **Approved**.
- Working branch `feat/claude-statusline-package` exists with draft files already present and
  staged (built during an earlier exploratory session). This plan governs and validates them;
  any deviation from the approved docs is corrected here.
- The host has a real `~/.claude/statusline-command.sh`; the package is **not** stowed in this
  plan (manual, user-run, post-merge).
- `jq`, `git`, and `stow` are available for validation.

## Ordered Tasks

1. **Verify branch + clean baseline.** Confirm `feat/claude-statusline-package` is checked out
   and only the intended paths differ from `main`.
2. **Confirm package file: script.** `stow/common/claude/.claude/statusline-command.sh` exists,
   is executable, and matches the approved single-file, OS-portable, no-secrets design (mirrors
   `omp` colors; segments OS · model · path · git · ctx · optional caveman badge).
3. **Confirm package file: `.stow-local-ignore`.** Excludes `README.md`, VCS metadata, and
   `*.bak`/`*.orig`, consistent with the `omp` package.
4. **Confirm package file: `README.md`.** Documents scope, the sensitive-content exclusion list,
   and the `--no-folding` dry-run → install workflow with the manual conflict-resolution note
   (no `--adopt`).
5. **Write the setup guide.** Create `docs/guides/claude-setup.md` (human-facing), mirroring the
   other guides: prerequisites, dry-run, `--no-folding` apply, validation, rollback,
   troubleshooting (expected conflict + folding hazard), exclusion list, and the `settings.json`
   wiring snippet.
6. **Validate package syntax + permissions.** `bash -n` the script; verify the executable bit.
7. **Run the stow dry-run (read-only).** `--dir=stow/common --no-folding --simulate claude`.
   Expect a reported conflict against the existing real file (this is the documented, expected
   outcome — not stowing here).
8. **Update status blocks.** Edit `AGENTS.md` §2 and `CLAUDE.md` so both record `claude` as a
   common package that is **added but not yet stowed**, consistent with each other.
9. **Privacy audit of the staged diff.** Inspect `git diff --staged` for any token, credential,
   or machine-specific absolute path. Must be clean.
10. **Stop for user-approved commit.** Present the staged diff and the proposed commit message.
   Do **not** commit, push, or open a PR without explicit user approval (no Claude trailer).

## Files Affected

- `stow/common/claude/.claude/statusline-command.sh` — created (executable)
- `stow/common/claude/.stow-local-ignore` — created
- `stow/common/claude/README.md` — created
- `docs/guides/claude-setup.md` — created
- `AGENTS.md` — modified (§2 status block)
- `CLAUDE.md` — modified (status block)
- `docs/prd/0017-claude-statusline-package.md` — created (Approved)
- `docs/architecture/0017-claude-statusline-architecture.md` — created (Approved)
- `docs/plans/0020-implement-claude-statusline.md` — created (this file)

No files deleted. No `$HOME` files created, modified, or deleted.

## Safety Checks

- Before starting: `git status` shows only the expected branch and paths.
- The build performs **no** `stow` install, no `ln -s`, no `rm`/`mv` against `$HOME`.
- Stow step is `--simulate` only; `--no-folding` is present so no whole-directory fold is ever
  proposed.
- `--adopt` appears nowhere.
- Staged diff passes the privacy checklist before any commit is proposed.

## Validation Commands

```bash
git branch --show-current                                   # feat/claude-statusline-package
git status --short                                          # only expected paths
bash -n stow/common/claude/.claude/statusline-command.sh    # script syntax
ls -l stow/common/claude/.claude/statusline-command.sh      # executable bit
find stow/common/claude -type f | sort                      # 3 package files
stow --dir=stow/common --target="$HOME" --no-folding --simulate claude   # expect conflict
git diff --staged                                           # privacy audit
```

## Rollback Strategy

Nothing is committed by this plan, so rollback is local and git-based:

```bash
git restore --staged stow/common/claude AGENTS.md CLAUDE.md docs   # unstage
git checkout -- AGENTS.md CLAUDE.md                                # revert tracked edits
rm -rf stow/common/claude                                         # remove new package (untracked)
```

To abandon entirely: `git checkout main && git branch -D feat/claude-statusline-package`.
No `$HOME` changes were made, so there is nothing to undo outside the repository.

## Completion Criteria

- [ ] `stow/common/claude/.claude/statusline-command.sh` present, executable, syntax-clean.
- [ ] `stow/common/claude/.stow-local-ignore` present.
- [ ] `stow/common/claude/README.md` present with `--no-folding` workflow and exclusion list.
- [ ] `docs/guides/claude-setup.md` present, mirroring the other guides (install, validation,
      rollback, troubleshooting, exclusions, `settings.json` wiring).
- [ ] `--no-folding` dry-run runs and reports the expected conflict (no stow performed).
- [ ] `AGENTS.md` §2 and `CLAUDE.md` status blocks updated, mutually consistent, recording
      `claude` as added-but-not-stowed.
- [ ] Staged diff contains no secrets or machine-specific absolute paths.
- [ ] Changes staged and presented; commit awaits explicit user approval.
