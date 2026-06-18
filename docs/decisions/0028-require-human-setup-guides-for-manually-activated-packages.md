# Decision: Require Human Setup Guides for Manually Activated Packages

**Number:** 0028
**Date:** 2026-06-18
**Status:** Accepted

## Context

This repository intentionally avoids automatic modification of sensitive user files. `~/.zshrc`, `~/.gitconfig`, SSH config, and other home-level files are never written to, overwritten, or stowed by any tool or script in this repository without explicit user action. This is a deliberate safety boundary established across multiple ADRs.

That boundary creates a class of packages that require human action after Stow. Git requires the user to wire `~/.gitconfig` includes, either manually or via `task git:bootstrap`. Zsh requires the user to add a single guarded include block to their real `~/.zshrc` by hand — `~/.zshrc` is never stowed and no script in this repository writes to it. Future packages such as Alacritty or Neovim may require font selection, terminal settings, or deferred dependency installation that cannot be automated safely. All packages require the user to decide on local and private overrides — for example, `local.zsh`, `~/.gitconfig` identity, and machine-specific values — which are git-ignored by design and must be authored locally.

PRDs, architecture documents, and implementation plans are written for agents and contributors working on the repository. They describe design decisions, tradeoffs, safety invariants, and ordered implementation tasks. They are not written for a human user sitting down to set up a new machine. Without a separate, user-facing reference, a person bootstrapping their environment must extract setup steps from implementation documents that were never designed for that purpose. This increases the chance of missed steps, incorrect ordering, unsafe commands, and confusion about which files are managed and which are not.

## Decision

Any package that requires manual setup, activation, local identity configuration, private overrides, OS-specific action, or post-Stow validation must include a guide under `docs/guides/`. The guide must be written for a human user performing the setup, not for Claude or implementation agents. It is the authoritative end-user reference for that package.

The filename convention is `docs/guides/<package-name>-setup.md`. Examples: `docs/guides/git-setup.md`, `docs/guides/zsh-setup.md`.

Each guide must cover all of the following sections, in this order:

1. **What this package manages** — files stowed, symlink targets.
2. **What it does NOT manage** — explicitly named unmanaged files (e.g., `~/.gitconfig`, `~/.zshrc`).
3. **Prerequisites** — tools that must be installed before stowing.
4. **Dry-run step** — the `stow --simulate` command to run, what output to look for, and how to confirm no conflicts exist.
5. **Apply step (Stow)** — the actual `stow` command, marked as a manual step.
6. **Manual activation steps** — anything the user must do after Stow: adding include blocks, running bootstrap tasks, configuring identity, selecting local overrides.
7. **Validation steps** — copy-pasteable commands to verify the setup is working correctly.
8. **Rollback steps** — how to undo Stow and deactivate any manual activation, returning to the pre-setup state.
9. **Troubleshooting** — known issues and how to diagnose them.
10. **Expected final file layout** — what `~/.config/<package>/`, `$HOME/`, or other affected directories should look like after successful setup.

The following rules apply to every guide:

- Must not include secrets, private values, real email addresses, real names, or tokens. All examples use placeholder values only.
- Must not encourage unsafe commands. `stow --adopt`, `rm -rf $HOME`, force operations, and similar destructive commands must not appear.
- Must clearly mark any command that modifies `$HOME` with the marker: `⚠️  MANUAL STEP — review before running`
- Must explicitly state that `stow --adopt` is forbidden and explain why (it silently overwrites files without a backup).
- Must explain the unmanaged entrypoint boundary for packages that have one. For Git: "`~/.gitconfig` remains unmanaged — this guide explains how to wire the includes." For Zsh: "`~/.zshrc` remains unmanaged — this guide explains how to add the include block."

Future package implementations — Git, Zsh, Alacritty, Neovim, and any other package that requires manual action — must include or update their `docs/guides/<package>-setup.md` as part of the implementation PR. A package PR without a required guide is incomplete and must not be merged.

Packages that are fully automatic and require no manual action after Stow do not need a guide. The requirement is scoped to packages with manual setup steps.

## Consequences

- Adds documentation overhead to every package implementation PR that requires manual action. A guide must be written and reviewed alongside the implementation.
- Improves repeatability: a user setting up a new machine follows the guide rather than reading PRDs and architecture documents that were not written for that purpose.
- Reduces the risk of unsafe manual setup: explicit `⚠️  MANUAL STEP` markers, forbidden command statements, and rollback sections are required in every guide, making the safe path clear.
- Creates a consistent standard for future package PRs. Reviewers can treat the presence of a required guide as a mandatory artifact — its absence is a blocking issue.
- The `docs/guides/` directory becomes the user-facing reference for the repository. `docs/plans/` and `docs/architecture/` remain implementation-facing documents for agents and contributors.
- Packages that are fully automatic — requiring no manual action after Stow — do not need a guide. The requirement is scoped only to packages with manual steps, keeping the documentation burden proportionate.
