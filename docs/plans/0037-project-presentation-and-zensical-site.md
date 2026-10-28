# Plan: Project Presentation and Zensical Website

**Number:** 0037
**Status:** Complete
**Date:** 2026-10-28
**PRD:** [0033 — Project Presentation and Zensical Website](../prd/0033-project-presentation-and-zensical-site.md) (Approved)
**Architecture:** [0029 — Project Presentation and Zensical Website](../architecture/0029-project-presentation-and-zensical-site-architecture.md) (Approved)
**Plan review:** [0108](../reviews/0108-project-presentation-plan-review.md) — no blocking issues

## Objective

Replace the existing public site with a Zensical site that follows `project-presentation`, reproduces
visitor-facing documentation, refreshes dotfiles brand artwork in Macchiato Blue, and updates the
generated architecture diagram.

## Assumptions

- Implementation starts only after Plan 0037 receives explicit user approval.
- Work remains inside this repository. The existing modified Herdr config is unrelated and must remain
  untouched.
- GitHub Pages keeps `https://fnayou.github.io/dotfiles/` and deploys from the default branch.
- Use native `zensical.toml`, not Zensical's `mkdocs.yml` compatibility input.
- Use Catppuccin Macchiato with Blue `#8aadf4`; preserve the existing terminal prompt/Git branch logo
  concept while redesigning its visual treatment.
- Use the exact Zensical version validated during implementation. If Zensical is absent locally, stop
  before installation and request approval to install the pinned docs dependency.
- Keep the current operator art reminder and opt-in Git hooks, updating them to check and regenerate the
  new brand output. Do not install or uninstall the hooks during this work.
- Use the existing `rsvg-convert` if available. If it is missing, request approval before installing
  `librsvg`.
- No commit or publish action is included. Request separate user approval after implementation review.

## Ordered Tasks

1. **Confirm the content map.** Check the source map below against the repository before writing pages.
   Preserve or rewrite every current site page at its existing route. Port all listed setup guides to
   `website/guides/`. Keep PRDs, architectures, plans, reviews, decisions, and agent runbooks out of the
   site. Treat `website/` as the canonical public copy; retain `docs/guides/` for repository-local /
   operator workflows and update their public links to the site where appropriate. Record any mismatch
   in the implementation review report before proceeding.
2. **Establish brand data and sources.** Add `brand/data/brand.json` and `facts.json`; populate the
   Macchiato palette and Blue accent from ADR 0068 and Alacritty's theme. Add SVG source templates for
   README banner, social preview, logo, and favicon under `brand/src/`. Use supported project facts only.
   Preserve the existing prompt/branch mark; redesign the composition and wordmark. Generate the
   required social-preview PNG from its SVG at 1280×640. Keep other assets as SVG unless a consuming
   platform requires raster.
3. **Add brand generation and checks.** Copy the shared skill's standard-library generator to
   `scripts/brand_generate.py`; extend it only as needed to use deterministic repository-derived counts
   already consumed by the artwork. Add `brand:generate` and `brand:check`. Generate committed outputs
   under `brand/generated/`; update README's banner reference to the generated SVG. Validate that the
   generated social-preview PNG has the declared size and that the SVGs have titles, viewBoxes, no
   unresolved tokens, no remote resources, and deterministic output.
4. **Create the Zensical site foundation.** Add native `zensical.toml`, pinned `requirements-docs.txt`,
   `overrides/main.html`, the skill's Macchiato CSS with Blue accent, and the ignored build staging path
   `website/assets/generated-brand/`. Add a preparation command that copies generated logo, favicon,
   and social-preview files into the staging path before Zensical builds. Set site metadata, explicit
   navigation, and the existing Pages URL.
5. **Rebuild public content.** Rework `website/` into the approved navigation structure. Preserve all
   existing visitor-facing site information and port relevant setup guide information to dedicated or
   consolidated public pages according to Task 1's map. Keep commands accurate and copy-pasteable; mark
   planned behavior as planned. Give all images accurate alt text. Do not include internal `docs/`
   directories in the build input.
6. **Update the architecture diagram.** Keep repository-derived facts and build-time generation. Change
   the generated diagram and its page to show Zensical build and GitHub Pages delivery. Remove MkDocs
   references from the diagram labels and the live architecture page. Preserve the diagram's generated
   (not committed) status and add it to Zensical output before `zensical build --strict`.
7. **Add documentation build and checks.** Add `docs:build` and `docs:check`; the latter builds then
   runs the shared `scripts/check_docs.py`. Check landmarks, heading count, accessible names, image alt
   text, internal links/anchors, contrast, absolute Open Graph image URLs, and `/dotfiles/` base paths.
   Use only settings and features supported by the pinned Zensical release.
8. **Update task and reminder integration.** Keep `art:remind`, the Claude Code reminder, and opt-in
   `.githooks/` behavior. Point the reminder implementation at `brand:check` and make it print
   `brand:generate` as the repair command. Keep reminder paths read-only, non-blocking, and limited to
   this repository. Leave the Git hook wrappers unchanged. Update `.claude/skills/ship-change/SKILL.md`
   and `docs/guides/art-setup.md`; remove obsolete asset commands and paths.
9. **Replace GitHub Pages build.** Update `.github/workflows/docs.yml` to install the pinned docs
   requirements, prepare brand assets, generate the architecture diagram, run the docs check on pull
   requests, and deploy only from the default branch. Use the built-in token, minimal job permissions,
   full-SHA action pins, and the current `site/` artifact. Add `brand:check` to CI on the default branch
   and on pull requests that change brand inputs. Do not modify repository Pages settings.
10. **Remove obsolete MkDocs integration.** After Zensical builds and checks successfully, delete
    `mkdocs.yml`, remove MkDocs installation/build commands, and update live references in README,
    `Taskfile.yml`, website structure/troubleshooting pages, and art setup docs. Keep historical
    references in internal decision and plan records. Update the root README and website structure page
    to show Zensical.
11. **Record the new decisions.** Add the next numbered ADR explaining the Zensical site, brand source
    structure, generated output paths, diagram build, and the asset raster policy that supersedes the
    relevant PNG-sidecar rule in ADR 0082. Add its row to `docs/decisions/README.md`. Do not rewrite
    ADR 0082's historical record. Add Plan 0037 to `docs/plans/README.md` and update website indexes as
    needed.
12. **Validate and inspect.** Run `brand:generate`, `brand:check`, `docs:build`, `docs:check`,
    `task check:decisions`, `git diff --check`, and the repository privacy audit. Verify the full
    content map, page routes, diagram text, Pages base paths, social metadata, and no published internal
    docs. Inspect site layout at desktop and about 360 px wide; verify no horizontal page scroll, visible
    focus, reduced-motion behavior, and Blue/text contrast of at least 4.5:1. Confirm the old site build
    commands and configuration are gone from live paths. Do not publish.
13. **Implementation review.** Reviewer checks the complete diff for safety, privacy, content coverage,
    cross-platform correctness, Zensical build results, generated-art freshness, accessibility, and
    documentation. Reviewer marks this plan Complete only after all verdicts pass.

## Files Affected

Created:

- `zensical.toml`
- `requirements-docs.txt`
- `overrides/main.html`
- `brand/data/brand.json`, `brand/data/facts.json`
- `brand/src/readme-banner.svg`, `brand/src/social-preview.svg`, `brand/src/logo.svg`, `brand/src/favicon.svg`
- `brand/generated/` banner, social preview, logo, favicon SVGs and required PNG derivative
- `scripts/brand_generate.py`, `scripts/check_docs.py`
- `website/assets/generated-brand/` as ignored build output
- New public guide pages under `website/guides/`; updated pages under `website/`
- `docs/decisions/0084-project-presentation-and-zensical-site.md` (confirm next free number before writing)
- Plan and implementation review reports

Modified:

- `website/` pages, navigation content, stylesheet, and generated diagram page
- `README.md`, `Taskfile.yml`, `.gitignore`
- `docs/plans/README.md`
- `.github/workflows/ci.yml`, `.github/workflows/docs.yml`
- `scripts/art/` diagram/facts generation and reminder integration
- `.claude/skills/ship-change/SKILL.md`
- `docs/guides/art-setup.md`, other guide links, `docs/decisions/README.md`

Deleted after replacement validation:

- `mkdocs.yml`
- `scripts/art/banner.py`, `scripts/art/social.py`, and `scripts/art/logo.py` after brand generation replaces them
- `website/assets/images/dotfiles-readme-banner.svg` and `.png`
- `website/assets/images/dotfiles-social-preview.svg` and `.png`
- `website/assets/images/dotfiles-logo.svg` and `.png`
- `website/assets/images/favicon.png`

No home-directory files, Stow packages, GitHub settings, or the existing Herdr config are affected.

## Safety Checks

- Before implementation, confirm only approved plan documents and the known unrelated Herdr edit are
  present; preserve that edit.
- Confirm the exact Zensical version and supported settings before pinning. Do not install if absent
  without explicit approval.
- Build only into repository-local `site/` and the declared ignored generated-asset paths.
- Publish only content explicitly mapped from `website/` and visitor-facing setup guidance. Never point
  `docs_dir` at the repository root or copy internal docs into the site.
- Keep Git hooks opt-in and do not modify local Git configuration during implementation.
- Do not delete old configuration/assets until the replacement build and checks pass. Keep Git history
  as rollback.
- Do not commit, push, change Pages settings, or upload the GitHub social preview without separate
  explicit approval.

## Validation Commands

```bash
task brand:check
task docs:build
task docs:check
task check:decisions
git diff --check
git status --short
```

`docs:build` and `docs:check` write only to ignored site/staging output. `brand:generate` is a planned
write step; `brand:check` is read-only. Additional checks: compare source map to all existing
`website/**/*.md` and `docs/guides/*.md`; inspect
the generated architecture SVG for stale `MkDocs` labels; run link, image, contrast, Open Graph, and
base-path checks; inspect desktop and narrow viewport layouts. Validate the checker's failure modes
using temporary fixture output without editing tracked content.

## Content Source Map

| Current source | Public destination |
|---|---|
| `website/index.md` | `website/index.md` |
| `website/getting-started.md`, `installation.md`, `philosophy.md` | Preserve current routes; refine onboarding navigation |
| `website/features/*.md` | Preserve feature routes under `website/features/` |
| `website/usage/*.md` | Preserve usage routes under `website/usage/` |
| `website/reference/*.md` | Preserve reference routes; update architecture and repository-structure pages |
| `website/screenshots.md` | Preserve current screenshots page and assets |
| `docs/guides/agent-tooling-setup.md` | `website/guides/agent-tooling-setup.md` |
| `docs/guides/alacritty-setup.md` | `website/guides/alacritty-setup.md` |
| `docs/guides/art-setup.md` | `website/guides/art-setup.md` |
| `docs/guides/bat-setup.md` | `website/guides/bat-setup.md` |
| `docs/guides/btop-setup.md` | `website/guides/btop-setup.md` |
| `docs/guides/claude-setup.md` | `website/guides/claude-setup.md` |
| `docs/guides/codex-setup.md` | `website/guides/codex-setup.md` |
| `docs/guides/doctor.md` | `website/guides/doctor.md` |
| `docs/guides/eza-setup.md` | `website/guides/eza-setup.md` |
| `docs/guides/ghostty-setup.md` | `website/guides/ghostty-setup.md` |
| `docs/guides/git-setup.md` | `website/guides/git-setup.md` |
| `docs/guides/herdr-setup.md` | `website/guides/herdr-setup.md` |
| `docs/guides/os-maintenance.md` | `website/guides/os-maintenance.md` |
| `docs/guides/packages-setup.md` | `website/guides/packages-setup.md` |
| `docs/guides/speedtest-setup.md` | `website/guides/speedtest-setup.md` |
| `docs/guides/terminal-app-setup.md` | `website/guides/terminal-app-setup.md` |
| `docs/guides/zsh-setup.md` | `website/guides/zsh-setup.md` |

## Rollback Strategy

- Keep changes uncommitted through implementation review. Revert only files created or modified by this
  plan; preserve unrelated user changes.
- If site generation fails, keep the existing `mkdocs.yml`, docs workflow, and images until Zensical is
  repaired. The Pages deployment remains unchanged until the approved replacement reaches the default
  branch.
- If the new site fails after merge, revert the site-replacement commit to restore the prior MkDocs
  deployment and asset references.
- Ignored generated files under `site/` and `website/assets/generated-brand/` are disposable build
  output; they are not source files and must not be committed.

## Completion Criteria

- [x] Plan 0037 was approved before implementation.
- [x] Every current public page and relevant setup guide is accounted for in the content map.
- [x] Zensical builds the replacement site strictly with the pinned version.
- [x] `docs:check` and `brand:check` pass; check failure modes are confirmed with temporary fixtures.
- [x] The rebuilt site preserves public documentation while excluding internal engineering documents.
- [x] Banner, social preview, logo, favicon, and architecture diagram use the intended Macchiato Blue identity.
- [x] The architecture diagram and page describe Zensical delivery and contain no obsolete MkDocs workflow references.
- [x] GitHub Pages workflow validates pull requests and deploys the default branch to the existing URL.
- [x] All three implementation review verdicts pass with no blocking issues; see [review 0109](../reviews/0109-project-presentation-implementation-review.md).
