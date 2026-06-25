# Getting Started

This page explains how to approach the repository before you change anything on your machine. The
goal is to help you understand the setup first, then adopt only the parts you want.

!!! warning "Don't run everything blindly"
    This repository is meant to be **read and adopted deliberately**, not piped into a shell. There is
    no one-shot install script, and that is intentional. Every step that touches your home directory is
    something you run yourself after reviewing it.

## Inspect the structure first

Clone the repository and look around before doing anything else:

```bash
git clone https://github.com/fnayou/dotfiles.git
cd dotfiles
```

The layout you care about as a visitor:

```
stow/
  common/     # Packages that work on macOS and Arch (source of truth)
  macos/      # macOS-specific packages (currently empty)
  arch/       # Arch / EndeavourOS-specific packages (currently empty)
docs/         # Internal project notes (kept as-is; not part of this site)
website/      # The source of this documentation site
README.md     # Repository overview and package table
```

Each package under `stow/common/` is self-contained and carries its own `README.md`. Start there —
read the package that interests you and the matching guide before deciding what to do with it.

See [Repository Structure](reference/repository-structure.md) for the full map.

## Reading vs. copying vs. installing

Three different levels of adoption — pick per package, not for the whole repo:

| Level | What it means | Risk |
|---|---|---|
| **Read** | Open files to understand or learn from them | None |
| **Copy** | Take a snippet (an alias, a setting) into your own config | You own the result |
| **Install (stow)** | Symlink a whole package into `$HOME` via GNU Stow | Changes your home dir — do a dry-run first |

!!! tip "Copying is often enough"
    If you only want one alias or one prompt segment, copy it. You don't need to stow anything. Stowing
    is for when you want this repository to *own* a config file as a live symlink.

## Two paths

### Beginner path — read and borrow

1. Browse the [package table in the README](https://github.com/fnayou/dotfiles#readme) and this site's
   [Features](features/index.md).
2. Open the package and guide for anything that looks useful.
3. Copy the specific lines you want into your own dotfiles. Done — nothing else required.

### Advanced path — install with Stow

1. Read [Installation](installation.md) end to end.
2. Install the [required dependencies](installation.md#dependencies) for the packages you want.
3. **Dry-run** each package with `--simulate` and review the output.
4. Resolve any conflicts manually (never `--adopt`).
5. Install one package at a time, only after its dry-run looks correct.

!!! danger "Stow modifies your home directory"
    Installing a package creates symlinks in `$HOME`. Always run the dry-run first and read it. If a
    dry-run reports a conflict, **stop** and resolve it manually — see
    [Troubleshooting](reference/troubleshooting.md) and the [GNU Stow Workflow](reference/stow.md).

## Next

- [Installation](installation.md) — the safe, dry-run-first install workflow.
- [Philosophy](philosophy.md) — why the repository is shaped this way.
