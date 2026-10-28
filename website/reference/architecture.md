# Architecture

One page that shows how the repository, its deployment steps and the machine fit together:
governance, the source of truth, deployment, the machine, and delivery.

[![Architecture of fnayou/dotfiles: governance, source of truth, deployment, the machine and delivery](../assets/images/dotfiles-architecture.svg)](../assets/images/dotfiles-architecture.svg)

[Open the diagram on its own page](../assets/images/dotfiles-architecture.svg) to zoom in.

!!! note "Generated from the repository"
    This diagram is not drawn by hand. `scripts/art/architecture.py` reads the repository itself, so
    the packages and where they link, the files Stow ignores, the tasks by group, the zsh layers, the
    CI steps and the counts follow the repository. It is generated each time the site is built, and is
    not committed. To see it locally, run `task docs:build`.

!!! info "How to read it"
    - **Filled blue dot** on a package: its files carry the Macchiato palette. **Hollow dot**: it has no
      colors of its own and inherits the terminal.
    - **Orange text**: a file kept out of Stow and propagated by a task instead.
    - **Dashed arrow**: a manual step, run by you.

See also [Repository Structure](repository-structure.md) and [GNU Stow Workflow](stow.md).
