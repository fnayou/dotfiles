# Contributing

This is a personal dotfiles repository. Issues and pull requests are welcome, but configuration
choices follow the maintainer's setup. Read `AGENTS.md` first: it is the operating contract.

## Before you start

1. Open an issue for anything beyond a small fix, so the approach can be agreed first.
2. Check `docs/decisions/` for an existing decision on the topic.

## Rules

- **No secrets.** Never commit tokens, keys, passwords, private hostnames or work-specific values.
  Use placeholders (`YOUR_API_KEY`, `hostname.example.com`) and `.example` files. See
  `.claude/rules/privacy.md`.
- **Stow safety.** Always dry-run first. Never use `stow .` or `stow --adopt`. Scripts must not
  run Stow on their own. See `.claude/rules/stow.md`.
- **Cross-platform.** Consider macOS, Arch and Debian separately. Do not assume one package
  manager exists on another platform. See `.claude/rules/cross-platform.md`.
- **Status blocks.** Adding, removing or first-stowing a package updates the status blocks in
  `AGENTS.md` and `CLAUDE.md` in the same commit.
- **Documentation.** Important decisions get a numbered record in `docs/decisions/`.

## Commits and pull requests

Commit messages and PR titles follow [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/):

```
fix(zsh): handle missing config directory
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`.
Mark breaking changes with `!` before the colon or a `BREAKING CHANGE:` footer.

## Checks

Run before opening a pull request:

```bash
task check:decisions
task dry-run AREA=common PACKAGE=<name>   # only when a Stow package changed
```

Review `git diff --staged` for real values before committing.

## Conduct

Participation is governed by the [Code of Conduct](CODE_OF_CONDUCT.md). Report security issues
following [SECURITY.md](SECURITY.md), not in public issues.
