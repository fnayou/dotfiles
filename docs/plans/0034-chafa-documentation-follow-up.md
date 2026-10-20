# Plan: chafa Documentation Follow-up and Release v2026.10

**Number:** 0034
**Status:** Approved
**Date:** 2026-10-20
**PRD:** [0030-chafa-image-preview](../prd/0030-chafa-image-preview.md) (Approved)
**Architecture:** none — documentation and one report line only
**Follows:** [Plan 0033](0033-implement-chafa-image-preview.md), [review 0093](../reviews/0093-chafa-image-preview-implementation-review.md)
**Plan review:** [0094](../reviews/0094-chafa-documentation-follow-up-plan-review.md)
**Implementation review:** [0095](../reviews/0095-chafa-documentation-follow-up-implementation-review.md)

## Objective

List chafa everywhere the repository names the optional shell tools or prints their install
commands, add a screenshot of the image preview to the website, then cut the CalVer release
`v2026.10` with a git-cliff changelog.

## Assumptions

- Plan 0033 is Complete and merged (PR #85, `main` at `dce782d`). Its Scope covered the zsh
  README, `docs/shell-dependencies.md`'s table, two guides, two website pages and two `Taskfile.yml`
  install lines. A repository-wide search after the merge found the places below, which also list
  the shell tools by name or print their install lines, but without chafa.
- No change is needed in:
  - `README.md`, `website/index.md`, `website/features/index.md`: they list Stow packages, and
    chafa is a tool, not a package.
  - The GitHub repository description and topics: they name packages and platforms only.
  - `docs/guides/doctor.md`: it describes the "Optional tooling" section without naming tools.
  - `website/features/packages.md`: per Plan 0033 Task 8, its bat sentence stays true.
- The last release tag is `v2026.08.1` (PR #66). Releases follow that pattern: a
  `chore/release-<tag>` branch with one `chore(release): <tag>` commit that regenerates
  `CHANGELOG.md`, merged by PR, then a lightweight tag on the merged commit (ADR-0055).
- `git-cliff` is installed on the macOS machine.
- The operator took the screenshot in Ghostty: `cat image.png notes.md` in `/tmp/chafa-test`, the
  image in pixels above the bat-highlighted Markdown. It shows no username, hostname or private
  path (prompt path `/tmp/chafa-test`). It was converted from JPEG to PNG with `sips`, 1600 px
  wide (about 2 MB; the artwork compresses poorly), and saved as
  `website/assets/images/chafa-preview.png`.
- Work happens on branch `docs/chafa-docs-followup`.

## Ordered Tasks

### Task 1 — `website/installation.md`

- Line 34: `` | `fzf`, `zoxide`, `eza`, `bat`, `oh-my-posh`, `zinit`, `herdr` | shell/tooling enhancements | Optional | ``
  → `` | `fzf`, `zoxide`, `eza`, `bat`, `chafa`, `oh-my-posh`, `zinit`, `herdr` | shell/tooling enhancements | Optional | ``
- Line 53: `sudo pacman -S git stow go-task fzf zoxide eza bat` → `… eza bat chafa`
- Line 63: `sudo apt install git stow fzf zoxide eza bat` → `… eza bat chafa`

### Task 2 — `website/reference/shell-dependencies.md`

- After line 27 (the `bat` row), add:
  `` | `chafa` | shell | Optional | `packages/Brewfile` | `pacman` | `apt` (trixie ships 1.14.5) | ``
- Line 87: `sudo pacman -S git stow go-task fzf zoxide eza bat` → `… eza bat chafa`
- Line 116: `sudo apt install git stow fzf zoxide eza bat` → `… eza bat chafa`

### Task 3 — `docs/shell-dependencies.md`

- Line 106: `sudo pacman -S git stow go-task fzf zoxide eza bat` → `… eza bat chafa`
- Line 161: `` (`fzf`, `zoxide`, `eza`, `bat`, `oh-my-posh`, `zinit`) ``
  → `` (`fzf`, `zoxide`, `eza`, `bat`, `oh-my-posh`, `zinit`; `chafa` optional) ``

### Task 4 — `deps:check:zsh` descriptions

- `Taskfile.yml:133`: `(fzf, zoxide, eza, bat, oh-my-posh, zinit)` → `(fzf, zoxide, eza, bat, oh-my-posh, zinit; chafa optional)`
- `website/usage/taskfile.md:31`: `(fzf, zoxide, eza, bat, oh-my-posh, zinit)` → same replacement.
- `website/reference/supported-systems.md:45`: `fzf, zoxide, eza, bat, oh-my-posh, zinit` →
  `fzf, zoxide, eza, bat, oh-my-posh, zinit; chafa optional`

### Task 5 — `scripts/doctor.sh` optional tooling

Line 366: add `chafa` after `bat` in
`for tool in fzf zoxide eza bat oh-my-posh nvim jq herdr task git-cliff cloudflare-speed-cli; do`.
A missing chafa is then reported as `INFO`, like the other optional tools.

### Task 6 — Screenshot on the website

- `website/features/shell.md` — after the "Aliases and tool integrations" bullet list, add:

  ```markdown
  ![cat showing an image with chafa, then a Markdown file with bat, in Ghostty](../assets/images/chafa-preview.png)
  *`cat image.png notes.md` in Ghostty: the image through chafa, the Markdown through bat.*
  ```

- `website/screenshots.md` — after the bat image, add:

  ```markdown
  ![cat showing an image with chafa, then a Markdown file with bat, in Ghostty](assets/images/chafa-preview.png)
  *Image preview in the terminal: chafa for images, bat for text, from one `cat`.*
  ```

### Task 7 — Validate

```bash
bash -n scripts/doctor.sh
bash scripts/doctor.sh | grep -E 'chafa'          # PASS line on this machine
task --list | grep 'deps:check:zsh'               # description shows "chafa optional"
bash scripts/check-decisions.sh
git diff --stat                                   # only the files in Files Affected
```

Repeat the post-merge search and confirm that every remaining hit is one of the exclusions in
Assumptions:

```bash
grep -rIl --exclude-dir=.git -wE 'bat' . | grep -vE '^./docs/(reviews|plans|prd|architecture|decisions)/|CHANGELOG' | xargs grep -L chafa
```

The website build (`mkdocs`) is checked by CI on the PR.

### Task 8 — Commit, PR, review

1. Commits, Conventional Commits, no AI attribution, staged diff audited:
   - `docs(plans): add plan 0034 for chafa documentation follow-up` — this plan, `docs/plans/README.md`.
   - `docs: list chafa with the optional shell tools` — Tasks 1–4.
   - `feat(doctor): report chafa as optional tooling` — Task 5.
   - `docs(website): add a chafa image preview screenshot` — Task 6 and the image.
2. Implementation review in `docs/reviews/`, which marks this plan Complete.
3. Push `docs/chafa-docs-followup`, open the PR; the operator merges it.

### Task 9 — Release `v2026.10`

After the Task 8 PR is merged, on an up-to-date `main`:

```bash
git switch -c chore/release-v2026.10
git-cliff --config cliff.toml --tag v2026.10 --output CHANGELOG.md
git diff --stat                    # only CHANGELOG.md
head -30 CHANGELOG.md              # new "## [2026.10] - <date>" section at the top
```

Commit `chore(release): v2026.10` (CHANGELOG.md only), push, open the PR. After the operator merges
it, tag the merged commit on `main` (a rebase merge changes the SHA, so never tag the branch commit):

⚠️  MANUAL STEP — publishes the tag on GitHub (undo: `git push origin :refs/tags/v2026.10 && git tag -d v2026.10`)
```bash
git switch main && git pull --ff-only
git log -1 --format='%h %s'        # expect: chore(release): v2026.10
git tag v2026.10
git push origin v2026.10
```

## Files Affected

- `website/installation.md` — modified
- `website/reference/shell-dependencies.md` — modified
- `docs/shell-dependencies.md` — modified
- `Taskfile.yml` — modified (`deps:check:zsh` description)
- `website/usage/taskfile.md` — modified
- `website/reference/supported-systems.md` — modified
- `scripts/doctor.sh` — modified
- `website/features/shell.md` — modified (screenshot)
- `website/screenshots.md` — modified
- `website/assets/images/chafa-preview.png` — created
- `docs/plans/0034-chafa-documentation-follow-up.md` — created
- `docs/plans/README.md` — modified (index row)
- `docs/reviews/<next>-chafa-documentation-follow-up-implementation-review.md` — created
- `CHANGELOG.md` — regenerated (Task 9, separate PR)

No file is deleted.

## Safety Checks

- No stow run, no `$HOME` change, no `rm`/`mv`/`ln -s` outside the repository.
- Install commands in documentation stay inside blocks that already carry `⚠️  MANUAL STEP`.
- `CHANGELOG.md` is generated by git-cliff, never edited by hand (ADR-0055).
- The tag push is a marked manual step, made only after the release PR is merged.
- No status-block change: no package is added, removed or first stowed.

## Rollback Strategy

1. Before commit: `git checkout -- <file>`.
2. After merge: `git revert <sha>` of the docs or doctor commit.
3. Tag: `git push origin :refs/tags/v2026.10 && git tag -d v2026.10`, then revert the
   `chore(release)` commit.

## Completion Criteria

- [ ] Every file in Files Affected names chafa as described; no other file changed.
- [ ] The repeated search returns only the files listed as exclusions.
- [ ] `bash scripts/doctor.sh` reports chafa under Optional tooling.
- [ ] The screenshot shows on the Shell features page and in the gallery.
- [ ] CI passes on the PR.
- [ ] Implementation review passes with no blocking issue.
- [ ] `v2026.10` exists on GitHub, on the `chore(release): v2026.10` commit, and `CHANGELOG.md` has
      its section.
