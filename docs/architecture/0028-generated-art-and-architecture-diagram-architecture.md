# Architecture: Generated Brand Art and Architecture Diagram

**Number:** 0028
**Status:** Approved
**Date:** 2026-10-23
**PRD:** 0032 (Approved)

## Context

PRD 0032 asks for four generated images (README banner, GitHub social preview, logo with favicon,
architecture diagram) in the Macchiato palette, an SVG with a PNG sidecar for every one, tasks to build
and check them, a CI freshness check, and a reminder to the operator before they commit, push or open a
pull request. The reminder shows the message and lets the command continue.

State of the repository, verified on 2026-10-23:

- `scripts/` holds bash entry points, several with embedded Python, and `Taskfile.yml` holds 31 tasks.
  `scripts/codex-sync.sh` and `scripts/terminal-sync.sh` are the precedent for a task-backed script.
- `.claude/` has `agents/`, `rules/` and `skills/`. It has **no** `settings.json`, there is no tracked
  hooks folder, and `core.hooksPath` is unset. Both reminder mechanisms are new.
- `ci.yml` runs one job, Repository Hygiene, on every push and pull request. `docs.yml` runs only on
  `main` and on manual dispatch, installs `mkdocs-material` and runs `mkdocs build --strict`. Neither
  checks out tags or history beyond the default.
- `chafa` is the precedent for an optional tool: Brewfile, the Arch and Debian lists, and the tool loop
  in `scripts/doctor.sh`.
- `rsvg-convert` and Python 3.15 are present on the primary machine. `tomllib` needs Python 3.11 or
  later; `ubuntu-latest` provides it.
- The `Taskfile` is read by the experiments through the `task` binary, which CI does not have, and the
  banner showed a commit count and a branch, which change on every commit. Both break determinism.
- Claude Code hook facts, from the official hooks reference (fetched 2026-10-23): project hooks live in
  `.claude/settings.json`; a `PreToolUse` hook with matcher `Bash` receives JSON on stdin with
  `tool_input.command`; a handler-level `if` field (for example `Bash(git commit *)`) filters on the
  command text; exit 0 lets the call proceed; `{"systemMessage": "..."}` is documented as a warning
  shown to the user; `hookSpecificOutput.additionalContext` goes to Claude, not the user; exit 2 blocks
  and must not be used; the `timeout` field is in seconds. Unconfirmed: that `systemMessage` shows for
  `PreToolUse` specifically, that `if` matches compound commands, and the first-run approval flow.

## Proposed Structure

```
scripts/
├── art.sh                         # bash entry: python3 scripts/art/art.py "$@"
└── art/
    ├── art.py                     # CLI: build | check | logo | remind
    ├── palette.py                 # the Macchiato values, and the check against the Alacritty theme
    ├── facts.py                   # reads the repository, deterministically (no git, no task binary)
    ├── svg.py                     # drawing helpers shared by the generators
    ├── banner.py  social.py  logo.py  architecture.py     # each returns an SVG string
    └── render.py                  # writes SVG, then the PNG sidecar with rsvg-convert

website/assets/images/             # committed outputs, each SVG with its PNG beside it
├── dotfiles-readme-banner.svg  .png
├── dotfiles-social-preview.svg .png
├── dotfiles-logo.svg           .png
├── favicon.png                    # 64 px, rendered from the logo SVG
└── dotfiles-architecture.svg  .png   # NOT committed: git-ignored, generated

website/reference/architecture.md  # the page that embeds the diagram; added to the nav

.claude/settings.json              # new: one PreToolUse hook (Bash), with `if` filters
.claude/hooks/art-reminder.sh      # reads the hook JSON, calls `art.sh remind`, prints systemMessage
.githooks/pre-commit  pre-push     # opt-in Git hooks, call `art.sh remind`, always exit 0
```

Task group in `Taskfile.yml`:

| Task | Effect | Writes |
|---|---|---|
| `art:build` | Regenerate every image: SVG first, then its PNG sidecar. `ARGS='--only banner'`, `--no-png` | `website/assets/images/` |
| `art:check` | Regenerate the committed SVGs in memory, compare with the files, check the palette | nothing |
| `art:logo` | Regenerate the logo, its PNG and the favicon only | `website/assets/images/` |
| `art:remind` | Print the reminder for `ARGS='--staged'` or `--range A..B`; silent when nothing applies | nothing |
| `hooks:install` | Dry run by default; `ARGS='--apply'` sets this repository's `core.hooksPath` to `.githooks` | local Git config |
| `hooks:uninstall` | Dry run by default; `ARGS='--apply'` removes it, only if it still equals `.githooks` | local Git config |

`hooks:status` is the dry run of either, plus a report of the current value.

## Design Decisions

### Decision 1: Generators are a Python package under `scripts/art/`, not one bash script

```
Option A: bash wrapper with embedded Python, like codex-sync.sh
  Pro: matches the existing pattern
  Con: the diagram generator is about 600 lines; a heredoc cannot be imported, tested or reused

Option B: a Python package with one thin bash entry point
  Pro: modules share the palette and facts; each generator is testable alone; the entry point still
       looks like every other script and task
  Con: first Python package in scripts/

Decision: B. `scripts/art.sh` is the entry point the Taskfile calls. It runs `python3 scripts/art/art.py`
(not `-I`, because the package imports its sibling modules).
```

### Decision 2: Deterministic facts, no git and no `task` binary

`facts.py` reads only files: package directories under `stow/`, tasks from the top-level keys under
`tasks:` in `Taskfile.yml`, ADR and guide counts by glob, zsh layers from `index.zsh`, CI steps from
`ci.yml`, install-list counts from `packages/`, and the release from the first `## [x]` heading of
`CHANGELOG.md` that is not `Unreleased`, written as `vx`. The experiment's commit count, hash and branch
are dropped: the prompt in the banner always shows `main`. Every list is sorted. Two runs on one commit
give identical SVGs, and CI needs no tag or history.

### Decision 3: Which outputs are committed

```
Option A: commit every image, including the diagram, and let CI check them all
  Pro: one rule
  Con: the diagram is large, changes whenever anything changes, and the site would build from a
       committed copy that someone must regenerate

Option B: commit the banner, social preview, logo and favicon; generate the diagram at docs build
  Pro: the README, GitHub and mkdocs need committed files; the diagram is only read by the site, which
       can build it fresh every time
  Con: the diagram has no committed copy to browse on GitHub

Decision: B. The diagram's SVG and PNG are git-ignored. `art:build` still writes both locally, for
preview and export. `docs.yml` runs `art.sh build --only architecture --no-png` before
`mkdocs build --strict`: the runner has no `rsvg-convert` and none of the fonts, so it publishes the SVG
only, as the PRD allows.
```

### Decision 4: PNG sidecars

`render.py` writes the SVG to a temporary file, validates it as XML, then renames it into place, and only
then runs `rsvg-convert` on that file, writing the PNG to a temporary file and renaming it. If a step
fails, the previous pair is untouched. The PNG width is the SVG's own width (banner 1670, social preview
1280, logo 1254, diagram 2400); the favicon is the logo at 64 px. A missing `rsvg-convert` prints
`PNG skipped: rsvg-convert not found` and exits 0, so SVG generation and the check work on any machine.
PNGs are rendered on the primary machine, where the JetBrains Mono font is installed.

### Decision 5: CI runs a freshness check on the SVGs only

`ci.yml` gets one step, `Art freshness`, after the existing checks: `bash scripts/art.sh check`. It
regenerates the banner, social preview and logo in memory, compares them with the committed files
byte for byte, and checks the palette against the Alacritty theme. On failure it prints which files are
stale and the command to fix them, `task art:build`. It never compares PNGs and never calls
`rsvg-convert`. The step satisfies "auto-generated with each pull request" without a bot commit
(PRD Non-Goals).

### Decision 6: One palette module, verified against the Alacritty theme

`palette.py` holds the 26 Macchiato values by name. `check` loads
`stow/common/alacritty/.config/alacritty/catppuccin-macchiato.toml` and asserts that each theme slot
equals the palette value of the matching name (background is `base`, foreground `text`, cursor
`rosewater`, `normal.black` `surface1`, `normal.magenta` `pink`, `normal.white` `subtext1`,
`bright.black` `surface2`, `bright.white` `subtext0`, and the other slots by name). A palette edit that
disagrees with the theme fails CI. This is the same source of truth as ADR 0068 and PRD 0031.

### Decision 7: One read-only `remind` command decides what is relevant

`art.sh remind --staged` (for `git commit`) and `art.sh remind --range A..B` (for `git push` and
`gh pr create`) do the following, in order:

1. List the changed files for that range or the staged set.
2. If none matches the **input globs** (defined once in `art.py`: `scripts/art/**`, `stow/**`,
   `Taskfile.yml`, `docs/decisions/**`, `docs/guides/**`, `.github/workflows/**`, `README.md`,
   `CHANGELOG.md`, `packages/**`, and the committed images), print nothing.
3. Otherwise run the same comparison as `check`. If every SVG is current, print nothing.
4. Otherwise print the message: the stale files and the commands to run, marked as manual steps:

```
⚠️  MANUAL STEP — the generated art is out of date (banner, social preview)
    task art:build
    git add website/assets/images
```

It never edits, stages or runs anything. It catches every exception and exits 0 with no output, so a
bug in it cannot stop a commit.

### Decision 8: Claude Code hook, show and continue

`.claude/settings.json` registers one `PreToolUse` hook for the `Bash` tool with three handlers, each
with an `if` filter (`Bash(git commit *)`, `Bash(git push *)`, `Bash(gh pr create *)`), a `timeout` of 10
seconds, and the command `"$CLAUDE_PROJECT_DIR"/.claude/hooks/art-reminder.sh`. The script reads the
JSON from stdin, re-checks the command text itself, picks `--staged` or `--range`, runs `art.sh remind`,
and, when there is a message, prints:

```json
{"systemMessage": "<the reminder>",
 "hookSpecificOutput": {"hookEventName": "PreToolUse",
   "additionalContext": "Tell the operator this art reminder before you run the command: <the reminder>"}}
```

It exits 0, prints no `permissionDecision`, and never exits 2, so the command proceeds. `systemMessage`
is the operator's message; `additionalContext` is a second path, so Claude relays the reminder if the
user-visible field does not show for this event. Neither rewrites the command, so the global `rtk` hook,
which rewrites `git` commands, is not affected. The `rtk` rewrite does not change what this hook sees as
its filter, which is why the script re-checks the command text rather than trusting the `if` alone.

```
Option A: matcher "Bash" with no `if`, filter in the script
  Pro: independent of how `if` treats compound commands
  Con: starts the script on every Bash call of every session

Option B: `if` filters plus a re-check in the script
  Pro: the script starts only for git commit, git push and gh pr create
  Con: if `if` misses a compound command such as `cd x && git commit`, no reminder fires

Decision: B, with a test in the plan. If `if` misses compound commands, fall back to A: the script
filters in bash with a `case` on the raw stdin before it starts Python, which costs a few milliseconds.
```

### Decision 9: Git hooks are tracked and opt-in

`.githooks/pre-commit` runs `scripts/art.sh remind --staged`; `.githooks/pre-push` reads the
`local_ref local_sha remote_ref remote_sha` lines Git passes on stdin and runs
`scripts/art.sh remind --range <remote_sha>..<local_sha>` (for a new branch, `origin/main..<local_sha>`).
Both write to stderr, end with `|| true` and `exit 0`, and use only `bash` and `python3`.
`hooks:install` is a dry run that prints the `git config --local core.hooksPath .githooks` it would run
and refuses if `core.hooksPath` is already set to something else; with `--apply` it runs that one
command. `hooks:uninstall` removes the key only when it still equals `.githooks`. Nothing touches the
global Git configuration, and no script runs these tasks.

### Decision 10: `ship-change` lists the check

The skill `.claude/skills/ship-change/SKILL.md` gets a step before staging: run `task art:check`, and if
it reports stale files run `task art:build`, review the diff and stage `website/assets/images`. The hook
and the Git hooks remind; the skill makes the step part of the normal flow.

### Decision 11: Website and README

`website/reference/architecture.md` embeds `../assets/images/dotfiles-architecture.svg` with a short
text and a link that opens the SVG on its own page for zooming; it is added under Reference in
`mkdocs.yml`. `README.md` changes its banner `src` to `dotfiles-readme-banner.svg`. `mkdocs.yml` keeps
the PNG logo and favicon paths, now produced by `art:logo`.

### Decision 12: `librsvg` is optional tooling

`brew "librsvg"` in the Brewfile; `# sudo pacman -S librsvg` in the Arch list; `# sudo apt install
librsvg2-bin` in the Debian list; `rsvg-convert` added to the optional tool loop in `scripts/doctor.sh`;
a row in `docs/guides/packages-setup.md`. It is needed only for the PNG sidecars.

## Risks

- **Hook visibility:** `systemMessage` for `PreToolUse` and `if` on compound commands are unconfirmed.
  Both are tested in the plan before the work is called done, and the `additionalContext` path and the
  no-`if` fallback exist for them.
- **First-run approval:** how Claude Code asks the operator to trust a new project hook is unconfirmed.
  The guide tells the operator to check `/hooks` after the first session on the branch.
- **Font widths:** chip and text widths are computed with a 0.6 em advance. A viewer whose fallback
  monospace font is wider can overflow a chip. The SVG stack lists fonts with that advance first; the
  PNG sidecar is unaffected.
- **Staleness noise:** any change to a counted file (a new ADR, a new task) makes the banner stale and
  fails CI until `task art:build` runs. That is the intended behavior, and the reminder exists to make
  it painless. A merge that touches counts on two branches needs a rebuild after the second merge.
- **Reproducibility across Python versions:** only text is generated, with sorted inputs and fixed
  number formatting; the check runs on CI's Python and on the primary machine's. Any difference there
  fails the check, which the plan tests by running it on both.
- **Cross-platform:** the generators are pure Python and work on macOS, Arch and Debian. Only the PNG
  step needs `librsvg`, and it is skipped when missing. No path is machine-specific.
- **Privacy:** images and scripts hold no machine user name, host name or absolute path. The public
  repository name `fnayou/dotfiles` is the brand and is allowed (clarified 2026-10-23). The illustrative prompt
  path stays `~/works/dotfiles`.
- **Reversibility:** every output is a file inside the repository, restorable from Git. The Git hooks
  are removed by `hooks:uninstall`; the Claude Code hook by deleting `.claude/settings.json`.
- **Hook cost:** with the `if` filters the script starts only for three command shapes, and a freshness
  comparison takes well under a second.

## Extensibility

A new image is a new module returning an SVG, one entry in the build list and, if committed, one in the
check list. The `remind` input globs and the palette check are shared, so a new generator is covered by
both without new wiring. The same `hooks:` tasks can later carry other opt-in Git hooks, though PRD 0032
limits this work to the art reminder.

## Open Questions

- Does `systemMessage` show for `PreToolUse` on the installed Claude Code build? Answered by a live test
  in the plan.
- Does the `if` filter match `cd <dir> && git commit ...`? Answered by the same test.
- Should the social preview keep the six-package card, or list every package by name? Kept at six, as in
  the experiment, unless the user prefers otherwise.

## Recommended Next Step

On approval, the Planner writes plan 0036 with ordered tasks: palette and facts, drawing helpers and the
four generators with byte-identical-run tests, the renderer and the PNG sidecars, the CLI and tasks, the
`check` and `remind` commands, the Claude Code hook and the live visibility test, the Git hooks and their
tasks, the CI and docs-workflow steps, the package lists and `doctor.sh`, the guide, the website page, the
README and the ADR, then review. Every command that writes outside generated files stays a
`⚠️  MANUAL STEP`.
