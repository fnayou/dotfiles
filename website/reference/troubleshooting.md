# Troubleshooting

Common problems and how to resolve them safely. **Inspect first, change second** — every section starts
with read-only checks before any fix. Destructive or modifying steps are marked.

!!! danger "Never use `stow --adopt`"
    `--adopt` silently overwrites your existing files with the repository version and cannot be undone
    without the original. It is forbidden in this repository. Resolve conflicts manually instead.

## Stow reports a conflict

A real file already exists at the link target. Inspect it:

```bash
ls -la ~/.config/<package>/
```

Resolve by moving the existing file aside, then re-running the dry-run:

⚠️  MANUAL STEP — moves your existing file; review first

```bash
mv ~/.config/<package>/<file> ~/.config/<package>/<file>.bak
stow --dir=stow/common --target="$HOME" --simulate <package>
```

Only apply once the dry-run is clean. Full detail in the [GNU Stow Workflow](stow.md).

## A config directory became a symlink (directory folding)

If `~/.config/<package>` is itself a symlink (leading `l`), Stow folded the directory. Several packages
require `--no-folding` (`zsh`, `alacritty`, `herdr`, `git`, `bat`, `eza`, `claude`).

Check:

```bash
ls -ld ~/.config/<package>    # leading "l" = folded symlink
```

Fix — unstow, recreate as a real directory, re-stow with `--no-folding`:

⚠️  MANUAL STEP — review each command before running

```bash
stow --dir=stow/common --target="$HOME" --delete <package>
mkdir -p ~/.config/<package>
stow --dir=stow/common --target="$HOME" --no-folding <package>
test ! -L "$HOME/.config/<package>" && echo "OK: real directory"
```

## Broken or wrong symlinks

Confirm a symlink resolves back into the repository:

```bash
readlink ~/.config/<package>/<file>
```

If it points somewhere unexpected or is dangling, unstow and re-stow the package (dry-run first).

## Missing dependencies / `command not found`

Most tools are optional and guarded — the shell starts cleanly without them, and an alias simply won't
exist. Check what's present:

```bash
task check            # core: stow, git, task
task deps:check:zsh   # shell tools
task deps:check:nvim  # editor tools
```

Install what's missing using the commands on the [Shell Dependencies](shell-dependencies.md) and
[Installation](../installation.md) pages. Nothing installs automatically.

## Shell not loading the managed config

The zsh package never touches `~/.zshrc`; you add one guarded include block yourself. Preview what the
bootstrap would add:

```bash
task zsh:bootstrap:dry-run
```

Apply it (idempotent, creates a timestamped backup):

⚠️  MANUAL STEP — review the dry-run output first

```bash
task zsh:bootstrap
```

Then start a new shell. See [Shell](../features/shell.md).

## Git config not applied

Confirm the managed includes are wired into `~/.gitconfig`:

```bash
git config --global --get-all include.path   # expect the two managed paths
git config --global core.excludesfile        # expect ~/.config/git/ignore
```

If empty, run the bootstrap (preview first):

```bash
task git:bootstrap:dry-run
```

⚠️  MANUAL STEP — review the dry-run output first

```bash
task git:bootstrap
```

See [Git](../features/git.md).

## Icons or fonts not rendering

OS glyphs, git symbols, and eza icons need a **Nerd Font** in your terminal. If the Oh My Posh prompt
renders its glyphs, the Claude status line and `eza` icons will too. Set your terminal font to a Nerd
Font and restart it.

## bat theme not applied

bat reads themes from a compiled cache — build it once after stowing:

```bash
bat cache --build
bat --list-themes | grep "Catppuccin Macchiato"
```

## eza colors look default

Usually `EZA_CONFIG_DIR` points away from `~/.config/eza`. Check:

```bash
echo "$EZA_CONFIG_DIR"
readlink ~/.config/eza/theme.yml
```

If the variable is set, eza reads `theme.yml` from there instead — unset it or point it at
`~/.config/eza`.

## MkDocs local preview issues

To preview this site locally without installing anything, serve it via Docker from the repository root:

```bash
docker run --rm -it -p 8000:8000 -v "$PWD":/docs squidfunk/mkdocs-material serve --dev-addr=0.0.0.0:8000
```

Open <http://localhost:8000>. The `--dev-addr=0.0.0.0:8000` binding is required so the container is
reachable from the host.

## Related

- [GNU Stow Workflow](stow.md) · [Shell Dependencies](shell-dependencies.md) · [Installation](../installation.md) · [Taskfile](../usage/taskfile.md)
