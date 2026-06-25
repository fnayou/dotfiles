# Reference

Deeper technical detail for when you want to understand how the repository works under the hood. If
you're just getting set up, start with [Getting Started](../getting-started.md) and [Usage](../usage/index.md)
— those are the practical onboarding path. The pages here are for looking things up.

| Page | What it covers |
|---|---|
| [Repository Structure](repository-structure.md) | The top-level layout — what `stow/`, `docs/`, `website/`, `Taskfile.yml`, and `.github/` are for |
| [GNU Stow Workflow](stow.md) | How packages become symlinks: dry-run, install, conflicts, `--no-folding`, re-stow |
| [Shell Dependencies](shell-dependencies.md) | The tools the shell config uses, their tiers, and how to check/install them |
| [Supported Systems](supported-systems.md) | Which platforms are tested, and what's portable vs system-specific |
| [Troubleshooting](troubleshooting.md) | Fixes for common issues — Stow conflicts, broken symlinks, missing deps, fonts |

!!! note "Reference vs onboarding"
    Getting Started and Usage tell you *what to do*. Reference tells you *how it works* and *why* — use it
    when something doesn't behave as expected, or when you want the full picture before adapting a part of
    the setup for yourself.
