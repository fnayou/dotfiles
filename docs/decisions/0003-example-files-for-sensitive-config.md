# Decision: .example Files for Sensitive Configuration

**Number:** 0003
**Date:** 2026-06-15
**Status:** Accepted

## Context

Many dotfiles contain sensitive or identity-specific values: email addresses, signing keys, API tokens, private hostnames, and work-specific settings. Two approaches were evaluated:

- **Commit real config with secrets stripped** — complete picture in the repository, but requires ongoing vigilance to avoid leaking real values.
- **.example files only** — placeholder values committed; user renames and populates locally before stowing.

The repository is private by default but may become public. Even in a private repository, committing real credentials is a permanent risk.

## Decision

Use **.example files** for all configuration that could contain sensitive or identity-specific values.

Rules:
- Files containing identity data (name, email, signing key) are committed as `<filename>.example` with placeholder values only.
- The user renames or copies the `.example` file locally and fills in real values before stowing.
- `.example` files are never stowed directly unless the user explicitly intends this.
- Non-sensitive config (aliases, completions, editor options with no identity data) may be committed directly.

Placeholder conventions:
- `your-email@example.com`
- `YOUR_SIGNING_KEY`
- `YOUR_API_KEY`
- `hostname.example.com`

Applies to at minimum:
- `stow/common/git/.gitconfig.example` — name, email, signing key
- Any file referencing API tokens, private hostnames, or credentials

## Consequences

- Zero risk of leaking real identity or credential data via the repository.
- Repo is less immediately functional on a new machine — user must rename and fill `.example` files before stowing.
- Trade-off accepted: minor setup friction in exchange for permanent privacy protection.
- Pre-commit checklist (see `AGENTS.md`) enforces this before every commit.
