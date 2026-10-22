# Decision: Generated Art with SVG and PNG Sidecars, Checked in CI, Reminded Locally

**Number:** 0082
**Date:** 2026-10-23
**Status:** Accepted
**PRD:** 0032 — Generated Brand Art and Architecture Diagram
**Architecture:** 0028 — Generated Brand Art and Architecture Diagram

## Context

The README banner, the GitHub social preview, the logo and the favicon were static PNGs with their own
navy and periwinkle colors, a title that differed from image to image, and numbers that could not follow
the repository ("macOS and Arch" while Debian runs on every server). A one-page technical picture of how
the repository, deployment and the machine fit together did not exist.

Four ways to keep generated images current were weighed:

- **A CI job that commits the images to the pull request.** Every commit here is authored by the user
  alone, so a bot commit breaks the authorship rule, needs a write token and can loop with the user's
  pushes.
- **Comparing PNG files in CI.** PNG output depends on the installed fonts and the renderer version, so
  the same repository state would render differently on a runner and on the primary machine.
- **Counting commits, hashes or the branch in the images.** They change on every commit, so a committed
  image would be stale as soon as it was written.
- **Doing nothing automatic.** The images would drift and nobody would notice.

## Decision

Generate the images from code, with the Python standard library only (`scripts/art/`, entry point
`scripts/art.sh`, tasks `art:build`, `art:check`, `art:logo`), in the Catppuccin Macchiato palette with
the blue accent. The palette is defined once and checked against the Alacritty theme, the palette source
of truth of ADR 0068.

- **SVG plus PNG, side by side.** Every generated SVG gets a PNG with the same base name in the same
  folder, rendered from it right after by `rsvg-convert` (librsvg, optional tooling). The SVG is written
  first, the PNG is rendered from a temporary copy, and both are moved into place together, so the pair
  cannot disagree. Without `rsvg-convert` the SVG is still written and the PNG is skipped with a message.
- **Deterministic.** An SVG holds no timestamp, commit count, hash or branch; facts are read from files
  (not from git or the `task` binary), lists are sorted and numbers are rounded. Two runs on one checkout
  are byte-identical, so a comparison means something.
- **Committed outputs and the diagram.** The README banner (the SVG is the README image), the social
  preview, the logo and the favicon are committed. The architecture diagram is git-ignored and generated
  during the docs build, SVG only (the runner has no `rsvg-convert` or fonts), and shown on a website page.
- **CI checks the SVGs only.** The `Art freshness` step of `ci.yml` regenerates the committed SVGs in
  memory, compares them byte for byte, and checks the palette. It needs no `rsvg-convert`, no `task`
  binary and no tags. This is how "auto-generated with each pull request" is met without a bot.
- **A reminder, not an enforcer.** A read-only `art.sh remind` prints the commands to run when the change
  touches an art input and an SVG is stale. A Claude Code `PreToolUse` hook shows it before `git commit`,
  `git push` and `gh pr create`; opt-in Git hooks (`.githooks/`, enabled by `task hooks:install`) show it
  in a plain terminal. Both show the message and let the command continue; neither blocks, edits, stages
  or regenerates anything, and on any error they stay silent.

## Consequences

- A change to a counted input (a package, a task, an ADR, a guide, a CI step, the release heading)
  makes the committed SVGs stale and fails CI until `task art:build` runs and its output is committed.
  That is the intended behavior and the reminder exists to make it painless; the images are regenerated
  after the last change that affects them.
- The PNG sidecars are rendered on the primary machine, where JetBrains Mono is installed. They are not
  compared in CI.
- The SVG font stack lists JetBrains Mono first, but GitHub renders SVG images with the viewer's fonts, so
  the lettering of the README banner can differ slightly from the PNG.
- Enabling the Git hooks sets `core.hooksPath` in this repository's local Git config only, after a dry
  run, and `task hooks:uninstall` removes it. Nothing touches the global Git configuration.
- The Claude Code hook is project-level (`.claude/settings.json`) and runs with the user's permissions;
  Claude Code shows it under `/hooks`, where the operator can review it.
