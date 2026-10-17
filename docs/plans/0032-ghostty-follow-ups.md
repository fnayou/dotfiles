# Plan: Ghostty Follow-ups — Doctor, Task Dry-Run, Palette Wording

**Number:** 0032
**Status:** Complete
**Date:** 2026-10-17
**PRD:** [0028-ghostty-configuration](../prd/0028-ghostty-configuration.md)
**Architecture:** [0026-ghostty-configuration-architecture](../architecture/0026-ghostty-configuration-architecture.md)
**Follows:** [Plan 0031](0031-implement-ghostty-configuration.md) (Complete) and review 0085
**Reviews:** [0086](../reviews/0086-ghostty-follow-ups-plan-review.md) (B1 and suggestions 1–13 applied),
[0087](../reviews/0087-ghostty-follow-ups-plan-re-review.md) (suggestions 1–4 and the optional note applied)

## Objective

Close the gaps found after plan 0031, in the same pull request (#83):

1. `task doctor` checks only `stow/common/*`, so the macOS-only package `stow/macos/ghostty` is never
   checked on macOS.
2. `Taskfile.yml` describes `task dry-run` as `AREA=<common>` with "macos/arch/debian are future
   areas", which is stale now that `stow/macos/ghostty` exists (review 0083 suggestion 10).
3. Four places say only Alacritty owns terminal colors or shares the Macchiato palette; Ghostty does
   too.

## Assumptions

- Work happens in the worktree lane `feat/ghostty-package`, on top of `e9547f7`. Every block sets
  `REPO="$(git rev-parse --show-toplevel)"` at its top and runs from the lane root.
- `scripts/doctor.sh` is read-only for `$HOME` and stays read-only (ADR-0063). It already sets
  `OS` to `macos`, `arch`, `debian`, or `unknown`. `REPO_ROOT` comes from `BASH_SOURCE`, so the
  script must run from the lane path to check the lane.
- Lane caveat: the Ghostty links point into this lane; other packages are stowed from the
  primary checkout. Run from the lane, doctor reports those other packages as
  `SKIP: <pkg> (not stowed — …)` (observed on 2026-10-17, exit 0), both before and after the
  change. That is expected here and is not a regression; the before/after comparison decides.
- `task dry-run` behaviour (no `--no-folding`) is not changed; only its description.
- `stow/arch/` and `stow/debian/` hold only `.gitkeep`; the area glob must match no package there.
- Plan approval is separate from the operator's earlier request to push PR #83; Task 7 asks again
  before pushing.

## Ordered Tasks

### Task 1 — `scripts/doctor.sh`: check platform-area packages (Builder)

Files: `scripts/doctor.sh` — modified.

Step 0 — baseline, **before any edit** (read-only for `$HOME`; writes only a `mktemp -d` dir):

```bash
REPO="$(git rev-parse --show-toplevel)"
BASE="$(mktemp -d)"; echo "BASE=$BASE"
bash "$REPO/scripts/doctor.sh" --verbose > "$BASE/before.txt" 2>&1; echo "exit=$?"
```

Edits:

1. In "Stow linkage", iterate over the areas `common` and, when `$OS` is `macos`, `arch`, or
   `debian`, also `$OS`. For each area, iterate `stow/<area>/*/` as today; skip non-directories.
2. Label packages outside `common` as `<area>/<pkg>` (for example `macos/ghostty`) **in the
   PASS/FAIL/SKIP text only**; keep the bare name for `common` so existing output does not change.
3. In the re-stow hint, use `--dir=stow/<area>` and keep the **bare** `$pkg` as the Stow package
   argument (`--dir=stow/macos … --simulate ghostty`, never `macos/ghostty`).
4. In "Directory folding (ADR-0024)", accept a `~/.config/<name>` directory as managed when either
   `stow/common/<name>/.config/<name>` or `stow/$OS/<name>/.config/<name>` exists; count it once.
5. Change nothing else; no new writes, no new commands that touch `$HOME`.

Validation (after the edit):

```bash
REPO="$(git rev-parse --show-toplevel)"
bash -n "$REPO/scripts/doctor.sh" && echo "PASS: syntax"
for d in "$REPO"/stow/arch/*/ "$REPO"/stow/debian/*/; do [[ -d "$d" ]] && echo "FAIL: unexpected $d"; done; echo "DONE: area glob"
```

```bash
REPO="$(git rev-parse --show-toplevel)"
BASE="<value printed in step 0>"
bash "$REPO/scripts/doctor.sh" --verbose > "$BASE/after.txt" 2>&1; echo "exit=$?"
strip() { sed '/^── Version/,/^── Summary/d' "$1" | grep -vE 'ghostty|package\(s\) stowed|uncommitted changes'; }
if diff <(strip "$BASE/before.txt") <(strip "$BASE/after.txt"); then
  echo "PASS: non-ghostty output unchanged"
else
  echo "FAIL: non-ghostty output changed"
fi
```

```bash
# macOS — both ghostty packages stowed from this lane
BASE="<value printed in step 0>"
grep -E 'ghostty|package\(s\) stowed' "$BASE/after.txt"
```

Expected: `PASS: syntax`; `DONE: area glob` with no `FAIL:`; `PASS: non-ghostty output unchanged`
(the same exit code before and after); on macOS a `PASS` line for
`ghostty (2/2 linked)`, a `PASS` line for `macos/ghostty (1/1 linked)`, the stowed count includes
both, and `~/.config/ghostty is a real directory` appears once.

Then remove the baseline dir (a `mktemp -d` dir outside the repository and `$HOME`):

⚠️  MANUAL STEP — review before running
```bash
BASE="<value printed in step 0>"
rm -rf "${BASE:?}"
```

Rollback before commit (discards uncommitted edits with no recovery):

⚠️  MANUAL STEP — review before running
```bash
REPO="$(git rev-parse --show-toplevel)"
git -C "$REPO" restore -- scripts/doctor.sh
```

After commit (with `<sha>` of commit 2 in Task 6):

```bash
REPO="$(git rev-parse --show-toplevel)"
git -C "$REPO" revert --no-commit <sha>
git -C "$REPO" commit -m "revert(doctor): check common stow packages only" -m "Refs: <sha>"
```

### Task 2 — `docs/guides/doctor.md` (Builder)

Files: `docs/guides/doctor.md` — modified.

1. In "Common findings" → `N of M file(s) not linked into $HOME`, say that platform-area packages
   (`stow/<os>/`) are checked on their own OS and reported as `<area>/<package>`.
2. In both re-stow commands, use `stow/<area>` as the placeholder instead of `stow/common`.
3. Put the existing marker lines directly above their fences (remove the blank line) at the
   re-stow install and at the `chsh` block, per `.claude/rules/documentation.md`.
4. Under `link(s) point outside this repo`, add one sentence: a package whose links all point into
   another checkout shows `SKIP: <pkg> (not stowed — …)`, not this finding (review 0087).

Validation:

```bash
REPO="$(git rev-parse --show-toplevel)"
grep -B1 -n '^```bash' "$REPO/docs/guides/doctor.md"
grep -n 'stow/<area>' "$REPO/docs/guides/doctor.md"
```

Expected: each dangerous fence is preceded by its marker line; two `stow/<area>` matches.

Rollback before commit (discards uncommitted edits with no recovery):

⚠️  MANUAL STEP — review before running
```bash
REPO="$(git rev-parse --show-toplevel)"
git -C "$REPO" restore -- docs/guides/doctor.md
```

After commit, the Task 1 `revert(doctor)` commit covers it, since both share commit 2.

### Task 3 — `Taskfile.yml`: dry-run description (Builder)

Files: `Taskfile.yml` — modified (one `desc:` line).

Old: `desc: "Dry-run a Stow package — usage: task dry-run AREA=<common> PACKAGE=<name> (macos/arch/debian are future areas)"`

New: `desc: "Dry-run a Stow package — usage: task dry-run AREA=<common|macos|arch|debian> PACKAGE=<name> (packages: task list)"`

Validation:

```bash
# macOS
REPO="$(git rev-parse --show-toplevel)"
cd "$REPO" && task --list 2>/dev/null | grep 'dry-run'
cd "$REPO" && task dry-run AREA=macos PACKAGE=ghostty; echo "exit=$?"
```

Expected: the new description; the macOS dry-run prints no conflict and `exit=0` (`--simulate`,
read-only). On Arch, do not dry-run the macOS package.

Rollback before commit:

⚠️  MANUAL STEP — review before running
```bash
REPO="$(git rev-parse --show-toplevel)"
git -C "$REPO" restore -- Taskfile.yml
```

After commit (with `<sha>` of commit 3):

```bash
REPO="$(git rev-parse --show-toplevel)"
git -C "$REPO" revert --no-commit <sha>
git -C "$REPO" commit -m "revert(task): restore previous dry-run description" -m "Refs: <sha>"
```

### Task 4 — Palette and terminal-colour wording (Builder)

Files — modified, one phrase each:

- `docs/guides/codex-setup.md:23` — "Alacritty owns terminal colors" → "Alacritty and Ghostty own
  terminal colors".
- `stow/common/codex/README.md:65` — "Alacritty still owns terminal ANSI colors" → "Alacritty and
  Ghostty still own terminal ANSI colors".
- `stow/common/nvim/README.md:5` — "(alacritty / zsh / oh-my-posh / bat / eza)" → "(alacritty /
  ghostty / zsh / oh-my-posh / bat / eza)".
- `stow/common/nvim/.config/nvim/lua/custom/plugins/colorscheme.lua:2` — same list change in the
  comment only.

Not changed (checked): the Alacritty comparisons in `docs/guides/bat-setup.md` and
`docs/guides/btop-setup.md`, `website/philosophy.md`, the skill example list, `doctor.sh:220`
(Alacritty-specific shell behaviour), `docs/guides/alacritty-setup.md`, `CHANGELOG.md` (generated).

Validation:

```bash
REPO="$(git rev-parse --show-toplevel)"
git -C "$REPO" diff --stat -- docs/guides/codex-setup.md stow/common/codex/README.md stow/common/nvim
nvim --headless -u NONE -c "luafile $REPO/stow/common/nvim/.config/nvim/lua/custom/plugins/colorscheme.lua" -c qa; echo "exit=$?"
```

Expected: four files, one changed line each; `exit=0` (skip the nvim line if nvim is not installed).

Rollback before commit:

⚠️  MANUAL STEP — review before running
```bash
REPO="$(git rev-parse --show-toplevel)"
git -C "$REPO" restore -- docs/guides/codex-setup.md stow/common/codex/README.md \
  stow/common/nvim/README.md stow/common/nvim/.config/nvim/lua/custom/plugins/colorscheme.lua
```

After commit (with `<sha>` of commit 4):

```bash
REPO="$(git rev-parse --show-toplevel)"
git -C "$REPO" revert --no-commit <sha>
git -C "$REPO" commit -m "revert(docs): name Alacritty only for terminal colors" -m "Refs: <sha>"
```

### Task 5 — Pre-commit checks (Builder, before every commit in Task 6)

```bash
REPO="$(git rev-parse --show-toplevel)"
git -C "$REPO" diff --staged --check && echo "PASS: no whitespace errors"
cd "$REPO" && task check:decisions; echo "exit=$?"
git -C "$REPO" diff --staged | grep -n -iE '^\+.*(password|token|api[_-]?key|secret|BEGIN.*PRIVATE|/Users/|/home/)' || echo "PASS: privacy"
```

Expected: `PASS: no whitespace errors`; `exit=0`; `PASS: privacy`. For commit 1 only, the grep
matches its own pattern line in this plan and review prose about secrets; inspect each match and
continue only if every match is one of those (review 0087 suggestion 1).

### Task 6 — Commits (Builder, each after operator approval of the staged diff)

1. `docs(plans): add Ghostty follow-ups plan` — this plan, `docs/plans/README.md`, review 0086
   and its re-review.
2. `fix(doctor): check platform-area stow packages` — `scripts/doctor.sh`, `docs/guides/doctor.md`.
3. `docs(task): describe all dry-run areas` — `Taskfile.yml`.
4. `docs: name Ghostty alongside Alacritty for terminal colors` — the four Task 4 files.

### Task 7 — Review and push (Reviewer, then operator)

1. Implementation review `docs/reviews/0088-ghostty-follow-ups-implementation-review.md` (0086 is
   the plan review, 0087 its re-review). It marks this plan Complete (plan file and
   `docs/plans/README.md` row) only with no blocking issue; commit
   `docs(reviews): add Ghostty follow-ups implementation review` after operator approval.
2. Ask the operator before pushing the branch to update PR #83. Push only; no merge, no force push.

## Files Affected

- `scripts/doctor.sh`, `docs/guides/doctor.md`, `Taskfile.yml`, `docs/guides/codex-setup.md`,
  `stow/common/codex/README.md`, `stow/common/nvim/README.md`,
  `stow/common/nvim/.config/nvim/lua/custom/plugins/colorscheme.lua` — modified.
- `docs/plans/0032-ghostty-follow-ups.md`, `docs/plans/README.md`,
  `docs/reviews/0086-…`, `docs/reviews/0087-…`, `docs/reviews/0088-…` — created/modified.

## Safety Checks

- `doctor.sh` stays read-only; `task dry-run` stays `--simulate`.
- No `stow` install, no `$HOME` write, no status-block change (no package added, removed, or first
  stowed).
- No force push, no merge; push only after the operator confirms (Task 7).

## Rollback Strategy

Per task as above; all on the lane branch, Conventional Commits `revert(...)` messages, no
`reset --hard`, no force push.

## Out of Scope (recorded)

- `website/reference/troubleshooting.md:58-63` hardcodes `--dir=stow/common` in the folded-directory
  fix, which does not reach `stow/macos/ghostty` (review 0086 suggestion 14). Later change.
- After merge, doctor run from the primary checkout reports the Ghostty links as foreign until they
  are re-stowed from there (review 0085 suggestion 3).

## Completion Criteria

- `task doctor` reports `macos/ghostty` on macOS; non-ghostty output unchanged (Task 1 diff PASS).
- `docs/guides/doctor.md` describes platform areas; markers sit directly above fences.
- `task dry-run` description lists all areas.
- No user-facing doc says only Alacritty owns terminal colors.
- Implementation review passes with no blocking issue; PR #83 updated after operator confirmation.
