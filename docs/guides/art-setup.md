# Project Artwork

Brand artwork uses SVG templates in `brand/src/`, palette and project facts in `brand/data/`, and
committed outputs in `brand/generated/`. Catppuccin Macchiato Blue (`#8aadf4`) is the project accent.
The generator renders the social preview at 1280×640 and the standalone square website header icon
at 256×256 from SVG. The wordmark logo, favicon, and README banner remain SVG.

The repository-derived package count, task count, and release are added during generation. Alacritty's
Macchiato theme remains the palette consistency check. Architecture SVG is generated at docs build
time and remains ignored.

Run these commands from the repository root:

```bash
task brand:check
task brand:generate
task docs:build
task docs:check
```

`brand:check` is read-only. `brand:generate` updates only `brand/generated/`. Review those changes
before staging them. `docs:build` stages generated site assets, builds the architecture diagram, and
runs Zensical. Site staging and `site/` output are ignored.

The opt-in Git hook and Claude Code hook call `task art:remind`. The reminder checks for stale brand
outputs, prints `task brand:generate` and `git add brand/generated`, and never modifies or blocks.

GitHub Actions checks the generated assets and builds the site on pull requests. The default branch
build deploys to GitHub Pages. It does not commit generated files.
