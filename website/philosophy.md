# Philosophy

The principles behind this repository. These explain *why* it is shaped the way it is — useful if you
want to understand the choices, or borrow the approach for your own dotfiles.

!!! note "Personal, not a framework"
    This is my own setup, kept tidy enough to share. It is **not** a universal dotfiles framework and
    doesn't try to be one. There's no plugin system, no abstraction layer to learn — just configuration
    files organised so they're easy to read and easy to take pieces from.

## Safe by default

Nothing touches your home directory on its own. There is no install script that runs Stow, and Stow is
always a deliberate, reviewed step:

- **Dry-run first.** Every install is preceded by a `--simulate` run you read before applying.
- **No `--adopt`, ever.** It silently overwrites files; conflicts are resolved by hand instead.
- **One package at a time.** Small, reversible steps over a big-bang setup.

If you only take one idea from here, take this one: a dotfiles repo should never surprise your home directory.

## Modular, not monolithic

Each tool is its own Stow package. You can install zsh without git, git without alacritty, and so on.
This keeps the repository honest — a package that can't stand alone doesn't belong in `common/`. It also
means **you can adopt one package and ignore the rest.**

## Documented on purpose

Configuration that isn't explained gets cargo-culted. So every package carries a README and a human
setup guide, and significant technical choices are written down as decision records inside the
repository. The intent is that you can always answer "why is this here?" without archaeology.

!!! info "This site is a curated view"
    The repository also contains a larger body of internal notes — product requirements, plans, reviews,
    and decision records — used while building it. This public site is **curated** from that material:
    it surfaces what's useful to a visitor and leaves the process documentation in the repository's
    `docs/` directory for anyone who wants to dig deeper. The internal notes are not reproduced here
    verbatim.

## Reproducible and cross-platform

The repository is the source of truth. A new machine is brought up *from* it, deliberately, rather than
configured ad hoc. macOS, Arch, and Debian are treated as first-class together: `common/` packages are
written to behave identically across them, and anything genuinely platform-specific is isolated rather
than mixed in.

!!! warning "Honest about compatibility"
    Tested on macOS (primary) and EndeavourOS / Arch Linux. It is not claimed to work on other systems —
    if you're elsewhere, treat it as a reference to read and adapt, not a drop-in install.

## Built for reuse and inspiration

The repository is structured so the smallest useful unit is easy to lift out:

- Want one alias? Copy the line.
- Want the prompt? Take the Oh My Posh config.
- Want the whole shell setup? Stow the zsh package.

You don't have to agree with every choice to get value here. Read it, disagree where you like, and keep
the parts that fit your own workflow.

## Acknowledgements

This project and its documentation were built through a mix of personal experience, manual curation, and
AI-assisted work.

Claude helped with repository-oriented implementation, refactoring, and documentation tasks. ChatGPT
helped with planning, structure, review, and documentation guidance.

The final decisions, testing, configuration choices, and publishing remain human-controlled.

## Next

- [Getting Started](getting-started.md) — how to approach the repo.
- [Installation](installation.md) — the dry-run-first install workflow.
- [Features](features/index.md) — what each package configures.
