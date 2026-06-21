# dotfiles

Private, safe, cross-platform personal dotfiles for **macOS** and **EndeavourOS / Arch Linux**,
managed with [GNU Stow](https://www.gnu.org/software/stow/).

macOS is the primary environment; Arch is supported from the start. Configs are version-controlled
in `stow/common/` and only ever symlinked into `$HOME` by a **deliberate, manual** Stow step —
never automatically.

## Status

```
Claude Code operating layer:    complete
GNU Stow scaffold:              created
Managed packages:               see stow/common/
Home directory:                 unmodified (nothing stowed yet)
```

`stow/common/` is the source of truth for which packages exist. Nothing has been stowed; no
symlinks exist; no file in `$HOME` has been modified.

## What's included

Each package is self-contained and carries its own README. `stow/macos/` and `stow/arch/` are
reserved for platform-specific packages and are currently empty.

| Package | What it manages | Details | Guide |
|---|---|---|---|
| **alacritty** | Alacritty terminal — window, font, keybinds, Catppuccin Macchiato theme | [README](stow/common/alacritty/README.md) | [guide](docs/guides/alacritty-setup.md) |
| **bat** | bat pager — style, wrap, paging, Catppuccin Macchiato theme | [README](stow/common/bat/README.md) | [guide](docs/guides/bat-setup.md) |
| **eza** | eza `ls` replacement — Catppuccin Macchiato (Blue) color theme | [README](stow/common/eza/README.md) | [guide](docs/guides/eza-setup.md) |
| **git** | Portable Git config — settings, aliases, global ignore (no secrets) | [README](stow/common/git/README.md) | [guide](docs/guides/git-setup.md) |
| **herdr** | Herdr agent multiplexer — theme, terminal, UI, toast | [README](stow/common/herdr/README.md) | [guide](docs/guides/herdr-setup.md) |
| **omp** | Oh My Posh prompt — segments + Catppuccin Macchiato palette | [README](stow/common/omp/README.md) | — |
| **zsh** | Layered Zsh config — path, history, plugins, tools, prompt, per-OS layers | [README](stow/common/zsh/README.md) | [guide](docs/guides/zsh-setup.md) |

## Documentation

Setup guides are written for a human operator, not for agents.

- [Packages setup](docs/guides/packages-setup.md) — install the tools every package depends on (`git`, `stow`, `go-task`, …).
- [GNU Stow usage](docs/stow-usage.md) — dry-run workflow, install steps, conflict handling, adding packages.
- Per-package setup guides — [alacritty](docs/guides/alacritty-setup.md) · [bat](docs/guides/bat-setup.md) · [eza](docs/guides/eza-setup.md) · [git](docs/guides/git-setup.md) · [herdr](docs/guides/herdr-setup.md) · [zsh](docs/guides/zsh-setup.md).
- [Shell dependencies](docs/shell-dependencies.md) · [Zsh migration notes](docs/zsh-migration.md).

## Installing a package

Stow is always a manual, reviewed step. Dry-run first, install only after reviewing the output.

```bash
# Step 1 — dry run, review what would be linked
stow --dir=stow/common --target="$HOME" --simulate <package>
```

⚠️  MANUAL STEP — run only after approving the dry-run output

```bash
stow --dir=stow/common --target="$HOME" <package>
```

If the dry run reports a conflict, **stop** and resolve it manually. Never use `--adopt` — it
overwrites existing files. See the [Stow usage guide](docs/stow-usage.md) for full detail.

## Safety

- No Stow has been run; no symlinks exist; no `$HOME` file has been modified.
- Stow and symlink operations happen only with explicit per-session approval and a reviewed plan.
- No secrets, credentials, or private hostnames are committed.
- Local-only and sensitive values live in unstowed `.example` templates that you copy and fill in.
- Every significant change follows: PRD → Architecture → Review → Plan → Review → Build → Review → Commit.

## For Claude Code

Read `AGENTS.md` first — it is the main operating contract. It defines agent roles, the PRD-first
workflow, safety / privacy / cross-platform rules, the documentation workflow, and commit rules.

Do not implement dotfiles, run Stow, create symlinks, or modify `$HOME` without explicit user
approval and an approved plan.

## Repository structure

```
.claude/          Claude Code agents, rules, and skills
stow/
  common/         Packages that work on both platforms (source of truth)
  macos/          macOS-specific packages (empty)
  arch/           Arch / EndeavourOS-specific packages (empty)
docs/
  guides/         Human setup guides, one per package
  architecture/   Structure decisions and tradeoffs
  decisions/      ADR-style decision records
  plans/          Ordered implementation plans
  prd/            Product requirements documents
  reviews/        Review reports
  claude/         Agent guides and workflow documentation
AGENTS.md         Main operating contract — read this first
CLAUDE.md         Claude Code entry point
```

## CI

GitHub Actions runs on every push and pull request, performing non-destructive hygiene checks only:
verifies expected files/directories exist, checks Markdown is present, runs `bash -n` on shell
scripts, and scans for obvious secret patterns. It never runs Stow, creates symlinks, modifies
`$HOME`, uses secrets, or deploys anything.

## License

See `LICENSE`.
