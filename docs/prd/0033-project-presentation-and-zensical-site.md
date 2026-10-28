# PRD: Project Presentation and Zensical Website

**Number:** 0033
**Status:** Approved
**Date:** 2026-10-28

## Goals

- Replace the current MkDocs website with a rebuilt public documentation site using Zensical's native `zensical.toml` configuration.
- Reproduce and organize the existing visitor-facing website content and relevant human setup guides under `website/`.
- Keep internal engineering documents under `docs/` unpublished.
- Align the site layout, theme setup, accessibility checks, build tasks, and GitHub Pages workflow with the `project-presentation` skill and its use in the other public repositories.
- Redesign the generated README banner, GitHub social preview, logo, and favicon as one coherent dotfiles identity.
- Update the generated big-picture architecture diagram to show the Zensical site build and Pages delivery, with no obsolete MkDocs workflow references.
- Use Catppuccin Macchiato with Blue (`#8aadf4`) as the primary project accent, consistent with the existing palette and ADR 0068.
- Keep artwork fact-based, deterministic, accessible, and generated from reviewable repository-owned sources.

## Non-Goals

- Changing dotfile behavior, Stow packages, machine configuration, or `$HOME`.
- Publishing internal PRDs, architecture documents, plans, reviews, decision records, or agent runbooks as website content.
- Changing the project's selected color palette or accent.
- Redesigning terminal screenshots or unrelated documentation images.
- Changing the GitHub Pages URL or publishing site content from a personal token.
- Uploading the GitHub repository social preview through repository settings.
- Generating artwork from unverified product claims or machine-specific information.

## User Stories

- As a visitor, I want a coherent site that explains dotfiles, setup, features, and daily use so that I can understand and adopt the repository safely.
- As a reader, I want complete, organized public documentation so that the existing website and applicable setup guidance remain available after replacement.
- As the maintainer, I want the site and brand assets to follow the shared project-presentation system so that public repositories look related while keeping their own accents.
- As a reviewer, I want deterministic source templates and checks for generated artwork so that visual changes remain reproducible and reviewable.

## Constraints

- Zensical must be pinned to the exact version used for the validated build.
- Site content lives in `website/`; internal engineering material in `docs/` stays unpublished.
- GitHub Pages remains at `https://fnayou.github.io/dotfiles/` and deploys through GitHub Actions.
- The site uses Catppuccin Macchiato as its dark-first base and Blue (`#8aadf4`) as the project accent.
- Artwork must follow the `project-presentation` brand track: canonical SVG sources, repository-owned data, deterministic generated outputs, and committed raster derivatives where required.
- Current generated facts and architecture diagram must remain accurate to repository state.
- All changes stay inside this repository. No Stow action, symlink creation, home-directory modification, or publication occurs as part of implementation.

## Safety Requirements

- Do not publish `docs/` or expose internal engineering records through navigation, search, or generated output.
- Do not include credentials, private hostnames, machine paths, or unsupported claims in site content or artwork.
- Do not change GitHub Pages repository settings or upload the social preview; report those as operator steps if needed.
- Keep deployment on the existing Pages URL and use the repository's built-in GitHub Actions token with narrowly scoped permissions.
- Keep the old generated assets and site available in Git history for rollback; remove or replace files only as specified by the approved implementation plan.
- Do not install dependencies or run publishing actions without explicit approval.

## Acceptance Criteria

- [ ] The replacement site uses native `zensical.toml` and a pinned Zensical version.
- [ ] Existing public website information and relevant human setup guidance are represented in a clear navigation structure under `website/`.
- [ ] Internal engineering documentation remains unpublished.
- [ ] The site follows the project-presentation documentation track, including build/check tasks, accessible image text, internal-link validation, contrast validation, and GitHub Pages base-path validation.
- [ ] The Pages workflow checks pull requests and deploys the default branch to the existing site URL, without a personal token.
- [ ] README banner, social preview, logo, and favicon are redesigned together, generated deterministically from canonical SVG sources, and use Macchiato Blue as the main accent.
- [ ] The generated big-picture diagram reflects the replacement site's Zensical build and deployment workflow and contains no MkDocs references.
- [ ] Artwork has accessible names, contains no remote resources, and states only facts supported by repository data.
- [ ] The README references the generated banner with accurate alternative text.
- [ ] The site builds successfully with strict Zensical validation, and the documentation checker passes on the built site.
- [ ] Brand generation and freshness checks pass, including validation of generated raster assets.
- [ ] No home-directory files, Stow links, unrelated screenshots, or repository settings are changed.

## Out of Scope

- Any modification to installed dotfiles or deployed machine state.
- Public release, Pages setting changes, or GitHub social-preview upload.
- New application features or changes to package configuration.
- Redesigning unrelated screenshots.
