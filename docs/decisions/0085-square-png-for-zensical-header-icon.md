# Decision: Use a Standalone Square PNG for the Zensical Header Icon

**Number:** 0085
**Date:** 2026-10-29
**Status:** Accepted
**PRD:** 0033 — Project Presentation and Zensical Website
**Architecture:** 0029 — Project Presentation and Zensical Website

## Context

The Zensical header already shows the repository name beside its logo. The existing favicon is a
separate browser asset and should not be reused as the site's header logo.

## Decision

- Create a standalone square SVG template containing only the logo mark.
- Generate and commit a 256×256 PNG derivative for Zensical's header.
- Keep the favicon as a separate SVG asset.
- Stage the generated header PNG with the other ignored Zensical build assets.

## Consequences

The header displays a clear standalone mark at small size while the repository name remains visible
as Zensical's site title. Contributors regenerate the PNG with `task brand:generate` and validate it
with `task brand:check`.
