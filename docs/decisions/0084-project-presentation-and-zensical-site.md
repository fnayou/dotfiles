# Decision: Rebuild the Public Site with Zensical and Shared Brand Sources

**Number:** 0084
**Date:** 2026-10-28
**Status:** Accepted
**PRD:** 0033 — Project Presentation and Zensical Website
**Architecture:** 0029 — Project Presentation and Zensical Website
**Plan:** 0037 — Project Presentation and Zensical Website

## Context

The public website and artwork should follow the shared `project-presentation` layout used by the
maintainer's other public repositories. The site must reproduce the existing visitor-facing material
and setup guides while excluding internal project records. The old MkDocs site also needs replacement
with native Zensical configuration.

## Decision

- Rebuild the site from `website/` with native `zensical.toml` and pinned Zensical dependency.
- Preserve the existing Pages URL and deploy only from the default branch. Pull requests build and
  check the site without deployment.
- Keep artwork sources in `brand/src/`, project palette and facts in `brand/data/`, and committed
  generated assets in `brand/generated/`. Use Catppuccin Macchiato Blue (`#8aadf4`) as accent.
- Keep banner, logo, and favicon as SVG. Commit a 1280×640 social-preview PNG rendered from SVG.
- Generate the architecture diagram from repository facts at site build time; keep it ignored and
  include Zensical and Pages delivery in the diagram.
- Keep the art reminder read-only, non-blocking, and opt-in for Git hooks. Its repair command is
  `task brand:generate`.
- ADR 0082's adjacent-PNG policy is historical. This decision replaces it for current project assets.

## Consequences

Contributors edit source templates and data, regenerate committed assets with `task brand:generate`,
and validate with `task brand:check`. `task docs:check` builds the site and checks public routes,
accessible names, image alt text, social metadata, palette contrast, and the `/dotfiles/` Pages prefix.
Internal PRDs, architectures, plans, reviews, decisions, and agent runbooks remain outside the site's
`docs_dir`.
