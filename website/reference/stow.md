# GNU Stow Workflow

This repository uses [GNU Stow](https://www.gnu.org/software/stow/) with a **package-based layout**
to manage dotfile symlinks safely and incrementally. Stow is never run automatically — every install
is a deliberate, manual action.

This page is the curated reference. The full source lives in the repository at `docs/stow-usage.md`.

## How Stow is used here

A **package** is a directory under `stow/` whose internal structure mirrors your home directory.
Stowing a package creates **symlinks** in the **target directory** (`$HOME`) that point back into the
repository. Edit the file in the repo, and the change is live in `$HOME` immediately.

```
stow/
├── common/          # Config that works on macOS, Arch, and Debian without modification
│   ├── alacritty/   # Alacritty terminal config + Catppuccin theme
│   ├── git/         # Git config templates
│   ├── herdr/       # Herdr multiplexer config + Catppuccin overrides
│   └── zsh/         # Zsh config (shared + macOS / Arch per-OS layer, runtime OS detection)
├── macos/           # macOS-specific config only
├── arch/            # EndeavourOS / Arch-specific config only
└── debian/          # Debian-specific config only
```

A package belongs in `common/` only if all three hold:

1. The config file path is identical across macOS, Arch, and Debian.
2. The config values work unmodified on all platforms.
3. No platform-specific tool or behavior is referenced.

Otherwise it belongs in `macos/` or `arch/`.

!!! note "Platform directories are not packages"
    `stow/macos/` and `stow/arch/` currently contain only `.gitkeep` markers. They are platform
    *areas*, not stowable packages. A valid dry-run needs a real package directory under an area, e.g.
    `stow/common/git/`.

## Dry-run before anything

Always dry-run first. The simulation shows exactly what Stow *would* do, with no changes made.

List available packages (output is `<area>/<package>`):

```bash
task list
```

Dry-run a package:

```bash
task dry-run AREA=common PACKAGE=git
```

Or directly:

```bash
stow --dir=stow/common --target="$HOME" --simulate git
```

Review the output carefully. If anything looks unexpected, **stop and investigate** before proceeding.

![Output of a stow --simulate dry-run listing the links it would create](../assets/images/stow-dryrun.png)
*GNU Stow simulation before applying a package.*

## Install a package

Install is a manual step, run only after a clean dry-run. Install one package at a time.

⚠️  MANUAL STEP — review dry-run output before running

```bash
stow --dir=stow/common --target="$HOME" git
```

## Conflict handling

If Stow reports a conflict (an existing file at the link target), **stop immediately**.

1. Identify the conflicting file in `$HOME`.
2. Decide whether to back it up, remove it, or keep it and not stow this package.
3. Re-run the dry-run after resolving.
4. Only then proceed with install.

Stow may also report a **directory-ownership** conflict — the target directory exists but wasn't
created by Stow, so Stow refuses to claim it. That is correct behaviour. Resolve by backing up and
removing the directory, comparing manually file by file, or deferring the stow and using the
`.example` template for reference until you're ready.

!!! danger "Never use `--adopt`"
    `--adopt` silently overwrites existing files with the repository version and cannot be undone
    without the original file. It is **forbidden** in this repository. Resolve conflicts manually
    instead.

## Adding a file to an already-stowed package

Stow does **not** pick up newly added files automatically. After adding a file to a package that is
already stowed, re-stow it. Dry-run first:

```bash
stow --dir=stow/common --target="$HOME" --no-folding --simulate <package>
```

⚠️  MANUAL STEP — review dry-run output before running

```bash
stow --dir=stow/common --target="$HOME" --no-folding --restow <package>
```

!!! info "`--no-folding` only where needed"
    Only `zsh`, `alacritty`, and `herdr` require `--no-folding`. `git` and `omp` do not — drop the
    flag for those.

## Forbidden

- `stow .` — stows everything without control. Always use explicit package paths.
- `stow --adopt` — silently overwrites existing files. Never use this.
- Running stow without a prior dry-run.
- Stow operations in scripts, hooks, or CI — all stow operations are manual only.

## Related

- [Installation](../installation.md) — the end-to-end install overview.
- [Shell Dependencies](shell-dependencies.md) — tools to install before stowing the zsh package.
- [Troubleshooting](troubleshooting.md) — common Stow problems.
