# Plan: Generated Brand Art and Architecture Diagram

**Number:** 0036
**Status:** Approved
**Date:** 2026-10-23
**PRD:** [0032-generated-art-and-architecture-diagram](../prd/0032-generated-art-and-architecture-diagram.md) (Approved)
**Architecture:** [0028-generated-art-and-architecture-diagram-architecture](../architecture/0028-generated-art-and-architecture-diagram-architecture.md) (Approved)
**Plan review:** [0102](../reviews/0102-generated-art-plan-review.md), [0103](../reviews/0103-generated-art-plan-re-review.md), [0104](../reviews/0104-generated-art-plan-third-review.md) — blocking issues addressed in this revision

## Objective

Build the stdlib Python generators for the banner, social preview, logo, favicon and architecture diagram
with SVG and PNG sidecars, the `art:*` and `hooks:*` tasks, the CI freshness check, and the operator
reminder (Claude Code hook and opt-in Git hooks), and document and publish them.

## Assumptions

- Work happens on branch `docs/generated-art-prd`, cut from `main` at `e86f647`. PRD 0032, architecture
  0028 and this plan are on it, uncommitted. Task 0 commits them on their own, so every later rollback
  concerns only the build.
- Plan 0036 is Approved by the user before Task 0 starts. The Builder does not change plan status.
- The experiments in `experiments/` (`banner.py`, `social.py`, `logo.py`, `bigpicture.py`) are local,
  untracked and excluded through `.git/info/exclude`. They are the starting point for the tasks that
  port them; the build does not import from `experiments/` and it is not committed.
- The user approved the banner, social preview, logo and diagram designs as shown in the experiments.
  Porting changes only what the architecture requires: deterministic facts, no commit count or branch,
  no glow, "macOS, Debian and Arch" in the social preview.
- Python 3.11 or later is available on the primary machine and on `ubuntu-latest`. `rsvg-convert` is
  installed on the primary machine only; CI has neither it nor the `task` binary nor the JetBrains Mono
  font.
- The highest ADR is 0081, the highest review is 0103 (this plan's second review), and the highest plan
  before this one is 0035. The Builder
  confirms the next free ADR and review numbers with `ls` before writing them.
- `docs.yml` runs only on pushes to `main`, so its new step is verified by running the same command
  locally and by the first run after the merge. `mkdocs` is not installed locally.
- No agent runs `hooks:install --apply` on the user's behalf outside the throwaway-branch test of
  Task 21, and no agent edits the GitHub repository settings.

## Ordered Tasks

Tasks run in this order. Dependencies are stated where a task needs an earlier one.

0. **Commit the planning documents.** Stage exactly `docs/prd/0032-generated-art-and-architecture-diagram.md`,
   `docs/architecture/0028-generated-art-and-architecture-diagram-architecture.md`,
   `docs/plans/0036-generated-art-and-architecture-diagram.md` (status Approved by the user's explicit
   approval) and any review reports written for it. Audit the staged diff, then one commit:
   `docs(plans): add generated art PRD, architecture and plan`. The working tree is then clean.
1. **Package skeleton and palette.** Create `scripts/art/` with `palette.py` (the 26 Macchiato values by
   name, and the mapping of each Alacritty theme slot to a palette name from Architecture Decision 6),
   `scripts/art.sh` (bash entry: `exec python3 "$(dirname "$0")/art/art.py" "$@"`), and an `art.py` that
   only parses `check` and exits. Validate: `python3 -c` imports `palette`, and the palette check passes
   against `stow/common/alacritty/.config/alacritty/catppuccin-macchiato.toml`; then change one palette
   value in memory and confirm the check reports it.
2. **Facts reader.** Create `facts.py`: packages by area, their `$HOME` destinations, the files Stow
   ignores, whether each package carries the palette (hex values or a README that names Macchiato),
   tasks parsed from the top-level keys under `tasks:` in `Taskfile.yml`, scripts, ADR, guide, plan,
   review and PRD counts, `.claude` agents, rules and skills, zsh layers from `index.zsh`, CI steps from
   `ci.yml`, install-list counts from `packages/`, and the release from the first non-`Unreleased`
   `## [x]` heading of `CHANGELOG.md`. It runs no subprocess. Validate: `grep -n "subprocess\|os.system"
   scripts/art/facts.py` finds nothing; the task count equals `task --list-all --json | length` once;
   two runs print identical JSON; the release prints `v2026.10`.
3. **Drawing helpers and renderer.** Create `svg.py` (palette access, text and chip helpers, monospace
   width, XML escaping) and `render.py`: write the SVG to a temporary file in the target folder, parse it
   as XML, rename it into place; then run `rsvg-convert` on that file at the SVG's own width into a
   temporary PNG and rename it. A missing `rsvg-convert` prints `PNG skipped: rsvg-convert not found`
   and returns success; a failing step leaves the previous pair untouched. Validate with a throwaway
   SVG under a temporary folder in the repository's ignored area: pair written; a malformed SVG is
   rejected and leaves no file; `PATH` without `rsvg-convert` skips the PNG with the message.
4. **Logo and favicon** (depends on Tasks 1 and 3). Create `logo.py` from the experiment, remove nothing
   from the design, write `dotfiles-logo.svg` and `.png` and a 64 px `favicon.png` rendered from the
   logo SVG. Validate: the PNG is 1254×1254, the favicon 64×64, the SVG has no `filter`, and the image is
   viewed once and judged against the approved experiment.
5. **Banner** (depends on Tasks 1–3). Create `banner.py` from the experiment: no glow filter, facts from
   `facts.py` (packages, tasks, ADRs, release), the prompt always showing `main`. Validate: two runs are
   byte-identical; the SVG contains no `glow`, no commit count and no branch other than `main`; the PNG
   is 1670×558; the image is viewed.
6. **Social preview** (depends on Tasks 1–3). Create `social.py` from the experiment: subtitle "for
   macOS, Debian and Arch", the version-control tile reads the release and Conventional Commits instead
   of a commit count, the other tiles read `facts.py`. Only the featured packages that exist in the repo
   are drawn. Validate as Task 5, with a 1280×720 PNG.
7. **Architecture diagram** (depends on Tasks 1–3). Create `architecture.py` from the experiment with
   `facts.py` as its only input, including the "Other" slot for a package outside the families. Validate:
   byte-identical runs; a 2400-wide PNG; the SVG has no commit count, hash or branch; add a temporary
   package directory under `stow/common/`, regenerate, confirm it appears and the package count rises
   by one, then remove that directory (inside the repository, created by the Builder).
8. **CLI: `build`, `logo`, `check`** (depends on Tasks 1–7). In `art.py`: `build` regenerates every image,
   SVG then PNG, with `--only NAME` and `--no-png`; `logo` regenerates the logo, its PNG and the favicon;
   `check` regenerates the banner, social preview and logo SVGs in memory, compares them byte for byte
   with the committed files, runs the palette check, prints the stale files and the fix command
   `task art:build`, and exits 1 on any difference. `build --only architecture` writes the diagram.
   Validate: `check` passes on a clean tree; append one space to a committed SVG, `check` exits 1 and
   names it, then restore it with `git restore`; `build --only banner --no-png` writes no PNG.
9. **`remind` command** (depends on Task 8). In `art.py`: `remind --staged` and `remind --range A..B`
   list the changed files, exit silently when none matches the input globs (Architecture Decision 7),
   exit silently when the check passes, else print the reminder with the stale files and the commands
   marked `⚠️  MANUAL STEP`. Every exception is caught and ends in silent exit 0. Validate with throwaway
   edits that `git restore` undoes: a staged change to a README outside the inputs prints nothing; a
   staged new task in `Taskfile.yml` with a stale banner prints the reminder; the same change with the
   art rebuilt prints nothing; a forced exception (a missing Taskfile) prints nothing and exits 0.
10. **Taskfile targets** (depends on Tasks 8 and 9). Add `art:build`, `art:check`, `art:logo`,
    `art:remind`, and `hooks:install`, `hooks:uninstall`, `hooks:status` beside the other task groups (the `hooks:` tasks call `scripts/hooks.sh`),
    with descriptions that say what they write. The `hooks:` tasks are a dry run by default and need
    `ARGS='--apply'`; `hooks:install` refuses when `core.hooksPath` is already set to something else;
    `hooks:uninstall` removes the key only when it still equals `.githooks`. Validate: `task --list`
    shows all seven; `task hooks:status`, `task hooks:install` and `task hooks:uninstall` without
    `--apply` change nothing (`git config --local --get core.hooksPath` stays empty).
11. **Git hooks files.** Create `.githooks/pre-commit` and `.githooks/pre-push` (bash, executable): the
    first runs `scripts/art.sh remind --staged`, the second reads the lines Git passes on stdin and runs
    `remind --range <remote_sha>..<local_sha>`, using `origin/main` as the base for a new branch; both
    write to stderr, end with `|| true` and `exit 0`. Validate: `bash -n` on both; run `pre-commit` and
    `pre-push` directly with simulated input in the stale and current cases.
12. **Claude Code hook** (depends on Task 9). Create `.claude/hooks/art-reminder.sh` and
    `.claude/settings.json`: a `PreToolUse` entry with matcher `Bash`, three handlers with `if` filters
    `Bash(git commit *)`, `Bash(git push *)`, `Bash(gh pr create *)`, `timeout` 10, command
    `"$CLAUDE_PROJECT_DIR"/.claude/hooks/art-reminder.sh`. The script reads the hook JSON from stdin,
    re-checks the command text, and picks the range: `git commit` uses `--staged`; `git push` uses
    `@{u}..HEAD` when the branch has an upstream and `origin/main..HEAD` when it has none; `gh pr create`
    uses `origin/main..HEAD`. It runs `remind` and, when there is a message, prints the JSON of
    Architecture Decision 8 (`systemMessage` and `additionalContext`) and exits 0; it never prints
    `permissionDecision` and never exits 2. Validate with synthetic stdin: a stale `git commit` prints
    valid JSON (`python3 -m json.tool`) and exits 0; `ls -la` prints nothing; malformed JSON input exits 0
    with no output; a push on a branch without upstream picks `origin/main..HEAD`.
13. **Optional tooling for the PNG step.** Add `brew "librsvg"` to `packages/Brewfile`, `# sudo pacman -S
    librsvg` to the Arch list, `# sudo apt install librsvg2-bin` to the Debian list, `rsvg-convert` to
    the optional tool loop of `scripts/doctor.sh`, and a row to `docs/guides/packages-setup.md`, following
    how `chafa` is listed. Validate: `bash scripts/doctor.sh` reports `rsvg-convert` and its exit status is
    unchanged from the clean baseline.
14. **ADR.** Write the next free ADR in `docs/decisions/` recording: generated art with SVG and PNG
    sidecars; only SVGs compared in CI; the diagram generated at docs build and git-ignored; no bot
    commits; the reminder shows and continues; and add its row to `docs/decisions/README.md`. This and the
    next two tasks change counted inputs, so they come before the images are regenerated.
15. **Guide.** Write `docs/guides/art-setup.md`: what is generated and where, `task art:build`,
    `art:check`, `art:logo`, the optional `librsvg`, how the reminder works, enabling and disabling the Git
    hooks, checking `/hooks` after the first session, and why CI never commits. Every command that writes
    files or changes configuration is preceded by `⚠️  MANUAL STEP — review before running`. Add the guide
    to the `README.md` guide list.
16. **Website page and scripts page.** Create `website/reference/architecture.md` embedding the diagram SVG
    and linking it for zoom, add it under Reference in `mkdocs.yml`, and mention the new tasks in
    `website/features/scripts.md`. Validate: the new nav entry resolves to an existing file.
17. **`ship-change` skill.** Add the `task art:check` step (and `task art:build` when it reports stale
    files) before staging, in `.claude/skills/ship-change/SKILL.md`.
18. **CI and docs workflow.** Add `Art freshness` (`bash scripts/art.sh check`) to `ci.yml` after the
    existing steps; add `Generate architecture diagram` (`python3 scripts/art/art.py build --only
    architecture --no-png`) to `docs.yml` before `Build site`; add the diagram SVG and PNG to
    `.gitignore`. The architecture diagram counts CI steps, which is why this comes before the images are
    regenerated. Validate: both workflow files parse as YAML; `git check-ignore` reports the two diagram
    files ignored; the `ci.yml` command runs clean locally; the `docs.yml` command writes the SVG and no
    PNG; and, if `mkdocs` is installed, `mkdocs build --strict` passes locally. Reproducibility: run
    `art.sh check` with `LC_ALL=C` and with the default locale, and under every other Python 3.11 or later
    interpreter on the primary machine (`python3.11`, `python3.12`, and so on, if present); the results
    must agree.
19. **Regenerate the committed images and point the README at the SVG** (depends on Tasks 4–8 and 10–18;
    nothing may change a counted input after it). Run `task art:build`, then change the README banner
    `src` to `dotfiles-readme-banner.svg`. The files replaced are the banner, social preview, logo and
    favicon PNGs and the new SVGs. Validate: `task art:check` passes; `git status` lists only the expected
    images; the banner, social preview and logo are viewed once more; every image path referenced from
    `README.md`, `mkdocs.yml` and `website/**/*.md` exists (a read-only script). If any later task edits an
    ADR, guide, task, package, workflow file, install list or `CHANGELOG.md`, run `task art:check` again and
    rebuild.
20. **Local checks** (no commit yet). `bash -n` on the new shell scripts, `shellcheck` if installed,
    `python3 -m py_compile` on every module, `task check:decisions`, `task --list`, `task art:check`,
    `git diff --check`, and the privacy audit of the working-tree changes (secrets, user names,
    `/Users/`, `/home/`).
21. **Live tests of the reminder** (the user's session, with the build still uncommitted). The user
    restarts the Claude Code session in this repository (or runs `/hooks`) so the new project hook loads
    and reviews it in `/hooks`. Then, on a throwaway branch `tmp/art-hook-test` created from the current
    working tree, the user stages only a throwaway file `docs/decisions/9999-hook-test.md` (a counted
    input, which makes the banner stale) and runs: a plain `git commit`; a compound
    `cd . && git commit`; a `git push` to an **isolated local bare repository**, never to `origin`, for
    example `git push "$TEST_REMOTE" HEAD:refs/heads/art-hook-test`, where `TEST_REMOTE` is a bare
    repository created in a system temporary directory with `git init --bare`; and
    `gh pr create --help`, which matches the `if` filter without creating a pull request. Record for each
    whether the message appeared in the UI. The same steps run with `hooks:install --apply` in a plain
    terminal for the Git hooks. Cleanup: delete the throwaway branch locally (`git switch` back, then
    `git branch -D tmp/art-hook-test`) and make sure the build files are still uncommitted and intact
    with `git status --short`; the project remote is never touched, so there is no remote branch to delete;
    the bare repository in the temporary directory is removed by the user as a manual step (below); run
    `hooks:uninstall --apply` if the user does not want the Git hooks on. If `systemMessage` is not shown
    for `PreToolUse`, or `if` misses the compound command, the Builder applies the architecture's
    fallback (rely on `additionalContext`; drop the `if` filters and filter in the script) and repeats
    the test, then Task 20 runs again.
22. **Review.** The Reviewer checks safety, privacy and documentation against the working tree and the
    recorded results of Task 21, stores the report under `docs/reviews/`, and marks this plan Complete only
    if there are no blocking issues and Task 21 has been done by the user.
23. **Commits** (only after Task 22 passes with no blocking issue). Stage exactly the files under Files
    Affected for each commit, audit each staged diff, and commit in this order, so the regenerated images
    land after every input they count:
    1. `feat(art): generate brand art and the architecture diagram` (Tasks 1–8, 10, 13);
    2. `feat(art): remind the operator to regenerate art` (Tasks 9, 11, 12, 17);
    3. `docs(art): add the art guide, website page and ADR` (Tasks 14, 15, 16);
    4. `feat(art): regenerate the brand images and check them in CI` (Tasks 18, 19);
    5. `docs(reviews): add the art implementation review` (the implementation review report from Task 22,
       and the plan's `Status` line if the Reviewer marked it Complete). It is last because the report
       exists only after the review passes, and it changes no counted input of the committed images.
    Run `task art:check` after the last commit and expect a pass.

## Files Affected

Created:
- `scripts/art.sh`, `scripts/hooks.sh` (the `hooks:*` tasks call it), `scripts/art/art.py`, `palette.py`, `facts.py`, `svg.py`, `render.py`, `banner.py`,
  `social.py`, `logo.py`, `architecture.py`
- `.githooks/pre-commit`, `.githooks/pre-push`
- `.claude/settings.json`, `.claude/hooks/art-reminder.sh`
- `website/assets/images/dotfiles-readme-banner.svg`, `dotfiles-social-preview.svg`, `dotfiles-logo.svg`
- `website/reference/architecture.md`
- `docs/guides/art-setup.md`
- `docs/decisions/<next free number>-generated-art-with-svg-png-sidecars.md`
- `docs/reviews/<next numbers>` — plan and implementation reviews

Modified (regenerated binaries are replaced in place, history is the rollback):
- `website/assets/images/dotfiles-readme-banner.png`, `dotfiles-social-preview.png`, `dotfiles-logo.png`,
  `favicon.png`
- `Taskfile.yml` — `art:*` and `hooks:*` targets
- `.github/workflows/ci.yml`, `.github/workflows/docs.yml`
- `.gitignore` — the generated diagram files
- `mkdocs.yml` — one nav entry
- `README.md` — banner `src` and the guide list
- `website/features/scripts.md`
- `packages/Brewfile`, `packages/arch/packages.txt`, `packages/debian/packages.txt`, `scripts/doctor.sh`,
  `docs/guides/packages-setup.md`
- `docs/decisions/README.md` — ADR index row
- `.claude/skills/ship-change/SKILL.md`

Committed in Task 0, before the build: PRD 0032, architecture 0028, this plan and the plan reviews.

Deleted: none.

## Safety Checks

Before starting:
- Plan 0036 is Approved, the branch is `docs/generated-art-prd`, and `git status` shows only the
  planning documents named in Task 0. After Task 0 the tree is clean.

During execution:
- Generators write only inside the repository, to the declared image paths and to temporary files beside
  them; nothing writes to `$HOME`. The only change outside tracked files is `core.hooksPath` in this
  repository's local Git config, made by `hooks:install --apply`, which the Builder runs only in the
  throwaway-branch test of Task 21 and removes afterward.
- The `remind` command, the Claude Code hook and the Git hooks are read-only, never regenerate, stage or
  commit, and exit 0 on any error.
- No hook uses exit code 2 or prints `permissionDecision`.
- No script installs a package, runs `pip`, uses the network, or calls `task`, `stow` or `defaults`.
- No task or script calls `hooks:install`, and no bootstrap or install script runs a generator.
- The push in Task 21 goes only to an isolated local bare repository in a system temporary directory,
  never to `origin`; `gh pr create` is run only with `--help`. No remote branch is created, so none is deleted.
- The staged diff is audited for secrets, user names and absolute home paths before each commit.
- Dangerous commands appear in docs only behind the `⚠️  MANUAL STEP` marker.
- Test edits to tracked files (Tasks 8, 9, 21; Task 21 also stages one throwaway ADR file on a throwaway branch) are restored with `git restore` and verified with
  `git status` before moving on.

## Validation Commands

```bash
git status --short
python3 -c "import sys; sys.path.insert(0, 'scripts/art'); import palette, facts, render"
bash scripts/art.sh check                         # read-only, exit 0 when current
task --list | grep -E 'art:|hooks:'
python3 -m py_compile scripts/art/*.py
bash -n scripts/art.sh .githooks/pre-commit .githooks/pre-push .claude/hooks/art-reminder.sh
git check-ignore website/assets/images/dotfiles-architecture.svg website/assets/images/dotfiles-architecture.png
task check:decisions
git diff --check
grep -rnE "/Users/|/home/" scripts/art scripts/art.sh .githooks .claude/hooks docs/guides/art-setup.md
```

The throwaway-branch run of Task 21 and the first `docs.yml` run after the merge complete the validation.

## Rollback Strategy

Repository work (nothing outside the repository has changed until Task 21):
- Uncommitted: after Task 0 the tree started clean, so `git status --short` lists exactly this plan's
  changes. Restore each modified file with `git restore <file>`. For each created file, confirm it in
  `git status --short` and delete that single path by hand. Do not use `git clean` over the tree. The
  planning documents are in the Task 0 commit and are not touched. The generated diagram files are
  git-ignored, so `git status --short` does not list them: check them with
  `git status --short --ignored website/assets/images/` and delete exactly
  `website/assets/images/dotfiles-architecture.svg` and `.png` by hand if present.
- Committed, not pushed: `git log --oneline main..HEAD` shows the commits; undo them with
  `git revert --no-edit <oldest>^..<newest>`, which keeps history and needs no reset.
- Merged: open a new branch and revert the merged commits the same way, then a pull request. This
  repository merges with rebase, so there is no single merge commit to revert.
- Replaced images: `git checkout <commit-before> -- website/assets/images` restores the previous PNGs.

Temporary test remote (only after Task 21): the user removes the bare repository they created in a
system temporary directory:

⚠️  MANUAL STEP — review before running
```bash
# remove only the temporary bare repository created for the test
rm -rf "$TEST_REMOTE"
```

Local configuration (only after Task 21 or after the user enables the hooks):

⚠️  MANUAL STEP — review before running
```bash
# removes the opt-in Git hooks; touches only this repository's local config
task hooks:uninstall ARGS='--apply'
```

To disable the Claude Code reminder alone, delete `.claude/settings.json` (or remove its `hooks` block)
and restart the session.

## Completion Criteria

- [ ] Every acceptance criterion in PRD 0032 is met and checked in the implementation review.
- [ ] The palette check passes against the Alacritty theme and fails on an altered value.
- [ ] Two runs of every SVG generator on one commit produce byte-identical files, and no SVG contains a
      commit count, hash, branch other than `main`, glow filter or absolute path.
- [ ] Every SVG written by `art:build` has a PNG with the same base name beside it, written after it;
      a missing `rsvg-convert` skips the PNG with a message and still succeeds.
- [ ] `task art:check` passes on the committed images and fails, naming the file, when one is stale.
- [ ] `remind` is silent when the change is unrelated or the art is current, prints the reminder when
      both an input changed and an SVG is stale, and exits 0 on any error.
- [ ] Synthetic-input tests show the Claude Code hook prints valid JSON or nothing and never exits 2.
- [ ] `hooks:install`, `hooks:uninstall` and `hooks:status` are dry runs by default, refuse a foreign
      `core.hooksPath`, and touch only this repository's local config under `--apply`.
- [ ] `ci.yml` and `docs.yml` parse, the diagram files are git-ignored, and CI needs no `rsvg-convert`,
      `task` binary or tags.
- [ ] `librsvg` is in the three package lists and reported by `doctor.sh`.
- [ ] The README banner is the SVG with its PNG beside it, and every image referenced by the README,
      `mkdocs.yml` and the website exists.
- [ ] ADR, guide, website page and `ship-change` step are in place, `task check:decisions` passes, and
      the first `docs.yml` run on `main` builds with `--strict`.
- [ ] No secrets, machine user names or machine-specific paths are in the diff or in any generated
      file; the public repository name `fnayou/dotfiles` is allowed.
- [ ] The user has run Task 21 and recorded whether `systemMessage` shows for `PreToolUse` and whether
      the `if` filters match a compound command, and the fallback was applied where it did not.
