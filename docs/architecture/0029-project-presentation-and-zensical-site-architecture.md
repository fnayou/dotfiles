# Architecture: Project Presentation and Zensical Website

**Number:** 0029
**Status:** Approved
**Date:** 2026-10-28
**PRD:** [0033 — Project Presentation and Zensical Website](../prd/0033-project-presentation-and-zensical-site.md) (Approved)

## Context

PRD 0033 replaces the current MkDocs site with a rebuilt Zensical site, reproduces visitor-facing
documentation, refreshes four brand assets, and updates the generated architecture diagram. The
repository already has an established identity: Catppuccin Macchiato with Blue (`#8aadf4`), a terminal
prompt and Git branch logo mark, generated banner/social/logo SVGs, and a repository-derived
architecture diagram. ADR 0068 defines the palette source; ADR 0082 records the existing art pipeline.

The `project-presentation` skill's documentation and brand tracks define the target conventions. The
other public projects use the same Zensical structure with their own accent colors. Dotfiles keeps its
Blue identity.

## Proposed Structure

```text
zensical.toml                    # Native Zensical config; docs_dir = "website"
requirements-docs.txt            # Exact Zensical pin
website/                          # Curated public documentation only
├── index.md
├── getting-started.md
├── features/                     # Existing feature content, reorganized as needed
├── usage/                        # Existing usage content
├── reference/                    # Including the generated architecture page
├── stylesheets/macchiato.css     # Skill stylesheet; project accent remains Blue
└── assets/generated-brand/       # Ignored, copied from brand/generated at build time
overrides/main.html               # Open Graph and Twitter card metadata
brand/
├── data/brand.json              # Macchiato palette and Blue project accent
├── data/facts.json              # Verified tagline and descriptive facts
├── src/                          # Canonical SVG templates for banner, social, logo, favicon
└── generated/                    # Committed SVGs and required raster derivatives
scripts/brand_generate.py        # Deterministic generator from the shared skill
scripts/check_docs.py             # Offline accessibility, link, base-path, and contrast checker
scripts/art/architecture.py       # Repository-derived diagram, updated for Zensical delivery
Taskfile.yml                      # brand:generate/check; docs:build/check task entry points
.github/workflows/ci.yml          # Brand freshness check
.github/workflows/docs.yml        # PR validation; default-branch Pages deployment
```

`docs/` remains internal. Public content is curated in `website/`; internal records are never included
by broad directory copying, navigation discovery, or generated search indexes. Human setup guidance
that visitors need is represented in the site and mapped to its current source during planning.

The diagram remains generated from repository facts at documentation build time and is not committed.
The build creates it under the website content tree before Zensical runs. It describes the Zensical
build and GitHub Pages delivery and contains no MkDocs workflow labels or commands.

## Design Decisions

### Decision 1: Rebuild directly on native Zensical configuration

**Option A: Keep `mkdocs.yml` as a compatibility layer for Zensical.**

- Pro: Less initial configuration work.
- Con: Does not align with the native `zensical.toml` configuration used by the other projects and
  leaves the old generator's name and assumptions in the repository.

**Option B: Author the replacement in `zensical.toml`.**

- Pro: Matches the requested Zensical setup and the native configuration used by agent-skills and
  ffmpegfyMe.
- Con: Requires rebuilding configuration and checking each feature against the pinned Zensical release.

**Decision: B.** Treat the work as a site rebuild, not a compatibility migration. The implementation
removes obsolete MkDocs configuration and commands only after the replacement site passes checks.

### Decision 2: Use the skill's canonical brand structure and preserve the existing mark

**Option A: Extend the existing `scripts/art/` drawing code and keep generated assets under
`website/assets/images/`.**

- Pro: Preserves the current generator and paths.
- Con: Diverges from the shared `project-presentation` brand data/source/generated layout and keeps
  website assets as the brand source of truth.

**Option B: Adopt `brand/data`, `brand/src`, and `brand/generated` with the skill's deterministic
generator.**

- Pro: Aligns all public repositories, makes palette and project facts explicit, and separates source
  templates from generated output.
- Con: Requires replacing the current banner/social/logo generator and updating README and CI paths.

**Decision: B.** Preserve the recognized terminal prompt/Git branch mark while redesigning its geometry,
wordmark, and supporting artwork around Blue. `brand.json` holds the shared Macchiato palette and Blue
accent. `facts.json` holds verified descriptive claims. Repository-derived counts and architecture
facts continue to come from repository files, not timestamps, Git history, or manual artwork edits.

Use SVG for the README banner, logo, and favicon. Generate the social-preview PNG at the platform's
required dimensions from its canonical SVG. This revises ADR 0082's PNG-sidecar-for-every-SVG rule;
implementation must update the decision record after this architecture is approved.

Generated SVG assets and required PNG derivatives live only under `brand/generated/`. The README points
to the generated banner there. A build preparation step copies the logo, SVG favicon, and social-preview
image into the ignored `website/assets/generated-brand/` directory for Zensical and page metadata. These
copies are temporary build inputs, not a second committed source of truth. The architecture SVG remains
a build-only output because it changes with repository structure.

### Decision 3: Make the new website the visitor-facing documentation surface

**Option A: Publish the existing site pages only.**

- Pro: Smallest content move.
- Con: Leaves useful human setup guidance outside the replacement website despite the PRD's complete
  documentation goal.

**Option B: Reproduce current public pages and curate visitor-relevant setup guidance into the site.**

- Pro: Gives visitors one organized source for overview, setup, features, usage, and reference.
- Con: Requires a source-to-destination inventory to avoid omissions and duplicated guidance.

**Decision: B.** The plan must map every current `website/` page and each relevant `docs/guides/` page to
its destination or an explicit exclusion. Internal decisions, plans, reviews, PRDs, and agent runbooks
remain unpublished. Any retained guide copy must have a clear maintenance owner and source mapping.

### Decision 4: Validate and deploy with the shared documentation track

The site uses the project's exact pinned Zensical release, Macchiato dark palette, Blue accent, shared
override for social metadata, and skill-provided offline docs checker. `docs:build` and `docs:check`
expose local workflows. Pull requests build and check the site; only the default branch deploys it to
GitHub Pages at `https://fnayou.github.io/dotfiles/`. The workflow uses GitHub's built-in token, narrow
job permissions, and full-SHA action pins. The checker receives `/dotfiles/` as the Pages base path.

The diagram generator consumes current repository facts before `zensical build --strict`. The generated
page uses meaningful alternative text and preserves a direct link to the full-size SVG. All diagram
labels and examples describe the current Zensical pipeline; MkDocs references are removed from the
diagram and its page explanation.

### Decision 5: Keep brand and site checks independent

`brand:check` validates generated brand SVG freshness and raster signatures/dimensions. `docs:check`
builds with Zensical and validates the rendered HTML for landmarks, headings, accessible names, image
alternatives, links, contrast, and Pages base paths. CI runs the checks on pull requests; deployment
depends on a passing docs check. Neither check publishes or modifies repository settings.

## Risks

- Reproducing `website/` and `docs/guides/` content can omit or duplicate material unless the plan
  includes a page-by-page source map.
- Zensical features may differ from Material for MkDocs. The pinned release must reject unsupported
  settings during strict build; do not assume plugin compatibility.
- Blue may not meet contrast requirements on every Macchiato surface. Use the shared checker and adjust
  foreground/background combinations without changing the selected accent.
- Social-preview metadata can build locally but still need the user to upload the generated PNG in
  GitHub repository settings. Existing GitHub previews may remain cached.
- Staging brand assets under `website/` can leave generated files behind locally. Keep that directory
  ignored and ensure the build never commits it.
- Removing old MkDocs files before the Zensical output is verified could break deployment. Keep the
  existing deployment path intact until the replacement passes local and CI checks; Git history is the
  rollback source.
- The existing Herdr config has an unrelated local modification. Implementation must preserve it.

## Extensibility

Additional visitor pages fit under `website/` and its explicit navigation. Brand variants remain
palette-driven through `brand/data/brand.json`; another repository changes its accent data without
forking the skill. New generated assets use the same canonical SVG/template/data pipeline and freshness
check. The architecture diagram remains derived from machine-readable repository sources.

## Open Questions

- None. The project accent, source repositories, site URL, content boundary, and generated diagram
  behavior are specified by the user and PRD 0033.

## Recommended Next Step

Review this architecture against PRD 0033. After the architecture review, ask the user to explicitly
approve it before creating the implementation plan.
