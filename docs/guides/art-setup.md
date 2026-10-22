# Generated Art Setup Guide

This guide explains how the repository's images are generated, how to rebuild them, and how the
reminder works. It is written for a human user, not for implementation agents.

The README banner, the GitHub social preview, the logo, the favicon and the architecture diagram are
generated from the repository by a small Python program (`scripts/art/`, entry point `scripts/art.sh`).
They use the Catppuccin Macchiato palette with the blue accent `#8aadf4`, and their numbers (packages,
tasks, decision records, guides, the release) are read from the repository. See ADR 0082 and PRD 0032.

Run every command in this guide from the root of your dotfiles repository (`/path/to/dotfiles`).

---

## 1. What is generated

| Image | Files in `website/assets/images/` | Committed | Used by |
|---|---|---|---|
| README banner | `dotfiles-readme-banner.svg` + `.png` | yes | `README.md` (the SVG) |
| Social preview | `dotfiles-social-preview.svg` + `.png` | yes | GitHub repository settings (the PNG, uploaded by you) |
| Logo | `dotfiles-logo.svg` + `.png` | yes | `mkdocs.yml` (the PNG) |
| Favicon | `favicon.png` (64 px, from the logo) | yes | `mkdocs.yml` |
| Architecture diagram | `dotfiles-architecture.svg` + `.png` | **no**, git-ignored | the website page [Architecture](../../website/reference/architecture.md) |

Every SVG has a PNG with the same base name beside it, rendered from it right after. The pair is written
together, so they cannot disagree.

Python 3.11 or later is the only requirement for the SVGs. The PNGs need `rsvg-convert` (see §2).

## 2. Prerequisites

`rsvg-convert` comes from librsvg and is optional: without it the SVG is written and the PNG step is
skipped with the message `PNG skipped: rsvg-convert not found`.

⚠️  MANUAL STEP — review before running
```bash
# macOS
brew install librsvg
```

⚠️  MANUAL STEP — review before running
```bash
# Arch / EndeavourOS
sudo pacman -S librsvg
```

⚠️  MANUAL STEP — review before running
```bash
# Debian
sudo apt install librsvg2-bin
```

`task doctor` reports whether `rsvg-convert` is installed. The PNGs use the JetBrains Mono font, which
the repository already asks you to install, so build them on the machine that has it.

## 3. Build, check and rebuild

```bash
task art:check          # read-only: are the committed SVGs and the palette current?
```

If it reports stale files, regenerate. This writes inside `website/assets/images/` only:

⚠️  MANUAL STEP — review the diff afterwards
```bash
task art:build                       # every image
task art:build ARGS='--only banner'  # one of: banner, social, logo, architecture
task art:build ARGS='--no-png'       # SVGs only
task art:logo                        # the logo, its PNG and the favicon only
```

Then review `git diff --stat website/assets/images/` and commit the result. A change to a counted
input (a package, a task, an ADR, a guide, a CI step, the release heading in `CHANGELOG.md`) makes the
banner and the social preview stale until you rebuild, so rebuild after the last change that affects
them.

## 4. What CI does

The `Art freshness` step of `ci.yml` runs `art.sh check` on every push and pull request. It regenerates
the committed SVGs in memory, compares them byte for byte with the files, and checks the palette against
the Alacritty theme. It needs no `rsvg-convert`, no `task` binary and no git tags. It never compares
PNGs, because PNG output depends on fonts and the renderer.

CI never commits images. Every commit in this repository is authored by you alone, so a stale SVG fails
the check and you rebuild and commit it yourself.

The `docs.yml` workflow generates the architecture diagram (SVG only) just before `mkdocs build
--strict`, so the website page is always current.

## 5. The reminder

Before you commit, push or open a pull request, a short message tells you to run the build, but only when
both of these are true: the change touches something the images are built from, and a committed SVG is
stale. Otherwise nothing is printed. The reminder never regenerates, stages or blocks anything; the
command always goes on.

```
⚠️  MANUAL STEP — the generated art is out of date (banner, social preview)
    task art:build
    git add website/assets/images
```

It reaches you in two ways, both calling the same read-only command, `task art:remind`.

**In a Claude Code session.** `.claude/settings.json` registers a hook that runs before
`git commit`, `git push` and `gh pr create`. After the first session on this repository, open `/hooks`
in Claude Code to review it. The hook shows the message and lets the command continue.

**In a plain terminal.** Opt in to the repository's Git hooks (`.githooks/pre-commit`, `pre-push`). The
task shows what it will do first and sets `core.hooksPath` in this repository's local Git config only:

```bash
task hooks:status     # read-only
task hooks:install    # dry run: prints the command it would run
```

⚠️  MANUAL STEP — review the dry-run output first
```bash
task hooks:install ARGS='--apply'
```

It refuses to run when `core.hooksPath` is already set to something else.

## 6. Turning the reminder off

⚠️  MANUAL STEP — review before running
```bash
# the Git hooks: removes core.hooksPath, only if it is still .githooks
task hooks:uninstall ARGS='--apply'
```

For the Claude Code hook, delete `.claude/settings.json` (or its `hooks` block) and restart the session.

## 7. Uploading the social preview

GitHub does not read the social preview from the repository. Upload the PNG yourself under the
repository's Settings → General → Social preview, using
`website/assets/images/dotfiles-social-preview.png`.

## 8. Troubleshooting

### `art.sh check` fails with `stale: ...`

The SVG no longer matches what the repository would generate. Rebuild the art as described in §3, review
the diff and commit the images.

### `palette: normal.blue is ..., palette blue is ...`

A value in `scripts/art/palette.py` disagrees with
`stow/common/alacritty/.config/alacritty/catppuccin-macchiato.toml`, the palette source of truth. Fix the
palette module or the theme, whichever one is wrong.

### `PNG skipped: rsvg-convert not found`

Install librsvg (§2). The SVG was still written.

### The README banner looks different from the PNG

GitHub renders an SVG image with the viewer's fonts, so the lettering can differ slightly from the PNG,
which is rendered with JetBrains Mono. The layout and colors are the same.

### The reminder never appears in Claude Code

Open `/hooks` and check that the `PreToolUse` hook for `Bash` is listed and trusted. A session that was
already running when `.claude/settings.json` appeared needs a restart.
