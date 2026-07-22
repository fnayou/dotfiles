# Decision: Changelog Generated from Conventional Commits via git-cliff (CalVer)

**Number:** 0055
**Date:** 2026-07-22
**Status:** Accepted

## Context

The repo is deployed to many machines (local + servers). The recurring question
was whether to pin versions and maintain a changelog for releases.

Two concerns were separated:

1. **Versioning the repo** — tags and a changelog.
2. **Pinning tool versions** the configs target (e.g. btop 1.4.7).

Facts about this repo that constrain the answer:

- It has **no downstream API consumers** — the only consumer is the author across
  their own machines. SemVer's breaking-change contract does not apply.
- Commits already follow **Conventional Commits** (`feat(btop):`, `fix(btop):`),
  so the commit log is already a structured changelog.
- A hand-maintained `CHANGELOG.md` would duplicate git history and drift.
- Each machine's deployed state is already identified for free by its checked-out
  SHA (`git rev-parse HEAD`) — no per-machine version scheme is needed.
- OS package managers (brew, pacman, apt) roll forward; pinning tool versions in
  dotfiles is high-effort and breaks on upgrade. Package **manifests** already
  track intended package names (`packages/`), not versions.

## Decision

Generate the changelog; do not hand-maintain it, and do not pin tool versions.

- Add `cliff.toml` — [git-cliff](https://git-cliff.org) config that renders
  `CHANGELOG.md` from Conventional Commits, Keep-a-Changelog flavoured.
- Versioning is **CalVer** (`vYYYY.MM`), not SemVer. Tag a deploy milestone with
  e.g. `git tag v2026.07`, then regenerate.
- Add task interface:
  - `task changelog` — regenerate `CHANGELOG.md` in place.
  - `task changelog:preview` — print the unreleased section to stdout.
  - `task changelog:install` — print per-OS install commands (prints only).
- `git-cliff` is a maintenance tool, installed out-of-band per OS (brew / pacman /
  cargo-or-binary on Debian). It is **not** added to the shell/nvim dependency
  tiers, and the changelog is **never generated automatically** (ADR-0009 spirit).

Explicitly rejected: hand-written `CHANGELOG.md`, SemVer, and pinning tool
versions inside dotfiles.

## Consequences

- `CHANGELOG.md` is a rendered artifact — regenerated, never edited by hand. Its
  quality tracks commit-message quality, reinforcing the Conventional Commits
  discipline already in use.
- Changelog generation requires `git-cliff` present; the tasks fail closed with an
  install hint (`task changelog:install`) rather than doing anything implicit.
- CalVer tags carry no compatibility meaning — they are deploy milestones only.
- Per-machine "which version" stays answered by the checked-out SHA; no new
  per-machine bookkeeping is introduced.
- `cliff.toml` and `CHANGELOG.md` are tracked in the repo; `CHANGELOG.md` is not
  generated until `git-cliff` is installed and `task changelog` is run.
