# Git

The `stow/common/git/` package provides a portable Git configuration — settings, aliases, and a
global ignore file — without touching your identity or any secrets.

This page is curated from the repository's `docs/guides/git-setup.md`.

## What it manages

Three files, stowed into `~/.config/git/`:

| File | Purpose |
|---|---|
| `config-common` | Portable settings — editor, colors, pull strategy, merge conflict style, diff options |
| `aliases` | Git aliases — shorthand for common operations |
| `ignore` | Global ignore patterns — OS artifacts, editor files, logs |

!!! info "Your identity stays yours"
    This package **never** manages `~/.gitconfig`. `user.name`, `user.email`, signing keys,
    credentials, and any `[includeIf]` work config stay in your own `~/.gitconfig`. The managed files
    are wired in via `[include]` entries — your existing config is preserved.

## Install

Verify prerequisites (`git`, `stow`, `task`):

```bash
task check
```

Dry-run (this package requires `--no-folding`):

```bash
task dry-run AREA=common PACKAGE=git
# or directly:
stow --dir=stow/common --target="$HOME" --no-folding --simulate git
```

Expect three `LINK:` lines and no conflicts. Then apply:

⚠️  MANUAL STEP — review dry-run output before running

```bash
stow --dir=stow/common --target="$HOME" --no-folding git
```

## Wire it into `~/.gitconfig`

Stowing only places the symlinks. A bootstrap task adds the `[include]` entries to `~/.gitconfig`.
Preview first — it changes nothing:

```bash
task git:bootstrap:dry-run
```

Then apply:

⚠️  MANUAL STEP — review dry-run output before running

```bash
task git:bootstrap
```

!!! note "Safe by construction"
    `task git:bootstrap` creates a **timestamped backup** of `~/.gitconfig` before any change, and only
    **appends** the include entries — it never removes or overwrites existing content. Running it a
    second time detects the entries already present and skips them.

Set your identity directly (never managed by this repository):

⚠️  MANUAL STEP — replace placeholders with your own values

```bash
git config --global user.name "Your Name"
git config --global user.email "your-email@example.com"
```

## Verify

```bash
git config --global --get-all include.path   # shows the two managed includes
git config --global core.excludesfile        # ~/.config/git/ignore
```

## Related

- [GNU Stow Workflow](../reference/stow.md) · [Installation](../installation.md)
