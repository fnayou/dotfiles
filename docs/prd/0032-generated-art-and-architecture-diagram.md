# PRD: Generated Brand Art and Architecture Diagram

**Number:** 0032
**Status:** Approved
**Date:** 2026-10-23

## Goals

- Generate the repository's images from code, in the Catppuccin Macchiato palette with the blue
  accent `#8aadf4`: the README banner, the GitHub social preview, the logo with its favicon, and a
  technical one-page architecture diagram ("big picture").
- Let the banner, the social preview and the diagram read facts from the repository (package, task,
  decision-record and guide counts, the release tag, package destinations, zsh layers, CI steps), so
  they follow the repository instead of going stale.
- Save a **PNG next to every generated SVG**, with the same base name, in the same folder. The PNG is
  rendered from the SVG right after the SVG is written, by the same command.
- Use the **SVG as the README banner**, with its PNG sidecar kept beside it.
- Define the palette once, in one shared module, and check it against the Alacritty Macchiato theme so
  the images cannot drift from the rest of the repository.
- Remove the glow from the title and align the title, logo and social preview with the banner (same
  type, same colors, "fnayou/" in lavender and "dotfiles" in blue).
- Provide a dedicated task group: build everything, check that the committed SVGs are current, and
  rebuild the logo on its own.
- Keep the committed SVGs honest with a CI freshness check that regenerates them and fails when they
  differ. This is how "auto-generated with each pull request" is met without a bot.
- Remind the operator to regenerate the art **when it is relevant**, before they commit, push or open a
  pull request: a visible message that names the exact commands to run. It fires only when a committed
  SVG is stale, as judged by the read-only check, so it stays quiet the rest of the time. It reminds and
  never regenerates anything by itself.
- Show the reminder at the moments the operator works in: when an agent session is about to run
  `git commit`, `git push` or `gh pr create`, and when the operator runs those commands themselves in a
  terminal. The CI freshness check remains the last line of defense.
- Publish the architecture diagram as a page of the website, generated during the docs build, so it is
  current on every release of the site.
- Document the workflow in a guide and record the decision in an ADR.

## Non-Goals

- A CI job that commits images back to a pull request branch. The authorship rule says every commit is
  authored by the user alone, and a bot commit needs a write token and can loop.
- Comparing PNG bytes in CI. PNG output depends on the installed fonts and the renderer version, so
  only the SVGs are compared.
- A reminder that blocks a commit, a push or a pull request for good, or that regenerates files by
  itself. The operator can always proceed, and only the CI check can fail a pull request.
- A reminder on every commit. It stays silent when the art is current or when the change cannot affect
  it.
- Changing the operator's global Git configuration. Any hook setup touches this repository's local
  configuration only.
- Uploading the social preview to GitHub. That is a repository setting, set by the user.
- Replacing or regenerating the documentation screenshots (`bat-output.png`, `eza-listing.png`, and
  the other screenshots under `website/assets/images/`).
- Light variants, other flavors of Catppuccin, or a theme switcher.
- An interactive or zoomable diagram, or any animation beyond the blinking cursor of the banner.
- New runtime dependencies on a machine: the generators need no package beyond Python 3 and, for PNG
  output only, `rsvg-convert`.
- Changing `mkdocs.yml` theme settings other than the logo and favicon paths, if they change at all.

## User Stories

- As the maintainer, I want the README banner to show the current package, task and decision counts so
  that it never contradicts the repository.
- As the maintainer, I want one command that rebuilds every image so that a change to the palette or
  the structure reaches all of them.
- As a reviewer, I want CI to fail when a committed SVG is out of date so that stale images cannot be
  merged by accident.
- As a reader of the website, I want a current architecture diagram so that I can see how the
  repository, deployment and the machine fit together.
- As the operator, I want a message that tells me to run the art build before I commit, push or open a
  pull request, only when it is needed, so that I do not find out from a red CI run.
- As the maintainer, I want a PNG saved beside each SVG so that GitHub's social preview, the mkdocs
  logo and any tool that cannot render SVG have a ready file.

## Constraints

- **Platforms:** the generators are portable Python 3 using only the standard library (`tomllib`
  needs Python 3.11 or later). Rendering a PNG needs `rsvg-convert` from librsvg: `brew install
  librsvg` [macOS], `sudo pacman -S librsvg` [Arch], `sudo apt install librsvg2-bin` [Debian]. The
  package lists and `scripts/doctor.sh` must say so, as optional tooling.
- **Determinism:** an SVG contains nothing that changes between runs on the same repository state: no
  timestamp, commit count, commit hash, branch name or machine path. Facts are read from files, not
  from the `task` binary, so CI needs no extra tool. Output order is sorted.
- **Fonts:** the SVG font stack is `JetBrains Mono`, `JetBrainsMono Nerd Font`, `SF Mono`, `Menlo`,
  `Consolas`, `DejaVu Sans Mono`, then `monospace`, because GitHub renders an SVG image with the
  viewer's fonts. A PNG sidecar uses whichever of those fonts the rendering machine has, so it is
  rendered on the primary machine, where the font is installed.
- **Paths:** images stay in `website/assets/images/`, which the README and `mkdocs.yml` already use. A
  new image takes the `dotfiles-` prefix of the existing ones.
- **Existing files:** the current PNGs are replaced by the regenerated ones. Git history is the
  rollback.
- **Workflow:** follows PRD → Architecture → Plan → Build → Review. Whether the generators and tasks
  live in `scripts/` or in a new folder, and the exact task names, are decided in architecture.
- **Privacy:** images contain no user name, host name, absolute path or secret. The illustrative
  prompt path stays `~/works/dotfiles`, as in the current banner.
- **Reminder triggers (decided in architecture):** two mechanisms are expected. A Claude Code hook,
  committed under `.claude/`, for sessions where an agent runs the Git or `gh` command, and
  repository-owned Git hooks under a tracked folder, enabled by an opt-in task, for commands the
  operator runs themselves. The `ship-change` skill also lists the check as a step. Both mechanisms
  call the same read-only check, so the rule for "relevant" lives in one place.
- **Relevant means:** the staged or pushed change touches an input of the art (the generators, the
  palette, `stow/`, `Taskfile.yml`, `docs/decisions/`, `docs/guides/`, `.github/workflows/`, `README.md`
  or the committed images) **and** the read-only check finds a stale SVG.
- **Palette source:** the Macchiato values are those of
  `stow/common/alacritty/.config/alacritty/catppuccin-macchiato.toml` and ADR 0068.

## Safety Requirements

- Generators write only inside the repository, only to the declared image paths, and never to `$HOME`
  or any path outside the repository.
- Generators never run from a bootstrap, install or shell-init script, and no other task calls them.
- The check task is read-only: it regenerates into memory or a temporary directory and compares, and
  changes no tracked file.
- No generator uses the network, installs a package, or runs `pip`.
- A missing `rsvg-convert` is not an error for the SVG step: the SVG is still written and the PNG step
  reports that it was skipped and why, so CI and machines without librsvg can still check and build
  SVGs.
- The build writes the SVG first and renders the PNG from that file, so the pair cannot disagree, and
  it leaves the previous pair untouched when a step fails.
- The reminder is read-only and fast. It never edits, stages or deletes a file, never regenerates art,
  and never runs the build; it only prints the commands for the operator to run, marked as manual steps.
- A reminder hook never fails a commit, a push or a command because of a bug in itself: on any error it
  stays silent and lets the command continue.
- Git hooks are opt-in. Enabling them is a manual task that sets this repository's local
  `core.hooksPath` only, is shown before it runs, and has a documented way to turn it off. Nothing sets
  the global Git configuration or runs automatically from a bootstrap or install script.
- The docs workflow keeps its existing permissions. Any added step only generates files inside the
  runner's checkout before `mkdocs build --strict`.

## Acceptance Criteria

- [ ] A shared palette module holds the Macchiato values, and a check fails when any value differs
      from the Alacritty theme.
- [ ] Generators exist for the banner, the social preview, the logo with its favicon, and the
      architecture diagram, and use only the Python standard library.
- [ ] Each generator writes an SVG and, right after, a PNG with the same base name in the same
      folder, for every generated SVG including the logo and the diagram.
- [ ] The README uses the SVG banner, and the PNG banner sits beside it.
- [ ] The title has no glow in the banner, the social preview or the logo, and all three use the same
      lavender and blue treatment.
- [ ] The social preview names macOS, Debian and Arch, and its numbers come from the repository.
- [ ] Two runs on the same commit produce byte-identical SVGs.
- [ ] A task builds everything, a read-only task checks the committed SVGs against regenerated ones,
      and a task rebuilds the logo and favicon only; all appear in `task --list`.
- [ ] CI runs the freshness check on pull requests and fails on a stale SVG, without needing
      `rsvg-convert` or the `task` binary.
- [ ] When a committed SVG is stale and the change touches an art input, an agent session about to run
      `git commit`, `git push` or `gh pr create` shows the operator a reminder that names the commands
      to run, and the operator can still proceed.
- [ ] With the opt-in Git hooks enabled, the same reminder appears on `git commit` and `git push` in a
      plain terminal; with the art current, or the change unrelated, neither mechanism prints anything.
- [ ] Both mechanisms call one read-only check, change no file, and stay silent and harmless when the
      check itself errors.
- [ ] The opt-in task for the Git hooks shows what it will change before it changes it, touches only
      this repository's local configuration, and the guide explains how to disable it.
- [ ] The `ship-change` skill lists the art check as a step before commit, push and pull request.
- [ ] The architecture diagram is generated during the docs build and shown on a website page, and
      `mkdocs build --strict` passes.
- [ ] `librsvg` is listed as optional tooling in the Homebrew, Arch and Debian package lists and is
      reported by `scripts/doctor.sh`.
- [ ] A guide and an ADR document the workflow, the SVG and PNG pairing, and why CI does not commit
      images; every command that writes files is marked as a manual step.
- [ ] `mkdocs.yml` logo and favicon still resolve, and every image the README and the site reference
      exists.
- [ ] No secrets, user names or machine-specific paths appear in the diff or in any generated file.

## Out of Scope

- Screenshots of tools, and any image not listed in the goals.
- Automating the GitHub social preview upload.
- A hook that regenerates images, stages them, or commits them for the operator.
- Reminders for anything other than art (a general pre-commit linter, formatting, tests).
- Generating the images from a template language or a diagram tool such as Mermaid or D2.
- Text-to-path conversion of the SVG lettering to freeze the font in the SVG (a possible later
  improvement).
- Per-pull-request previews of the images.
