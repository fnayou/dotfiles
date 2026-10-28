# Scripts

Routine system maintenance runs through the project's `task` runner. The helper script
(`scripts/os-maintenance.sh`) detects the OS and runs the matching package-manager commands, so the
same tasks work on macOS and Arch. (Debian/`apt` maintenance is not wired into this script yet — see
[Supported Systems](../reference/supported-systems.md).)

Curated from `docs/guides/os-maintenance.md` and `Taskfile.yml`.

Two concerns are kept separate: **update** (sync + upgrade packages) and **clean** (orphan removal,
cache pruning, journal vacuum). Clean is non-destructive by default — it reports only, and deletes
only with the explicit apply step.

## Update

```bash
task update
```

- **Arch:** `yay -Syu` (or `sudo pacman -Syu` if `yay` is absent).
- **macOS:** `brew update && brew upgrade`.

Interactive — you'll be prompted for confirmation / sudo as usual.

## Clean — dry-run (default, safe)

```bash
task clean
```

Reports what cleanup *would* remove and deletes nothing:

- **Arch:** orphans (`pacman -Qtdq`), cached versions beyond the last 3 (`paccache`), journal disk usage.
- **macOS:** `brew cleanup --dry-run`, `brew autoremove --dry-run`, `brew doctor`.

## Clean — apply (destructive)

The apply path re-prints the report, then performs the removals.

⚠️  MANUAL STEP — review the dry-run output first

```bash
task clean:apply
```

- **Arch:** `sudo pacman -Rns <orphans>` (only if any), `sudo paccache -rk3`, `sudo paccache -ruk0`,
  `sudo journalctl --vacuum-size=200M`.
- **macOS:** `brew cleanup`, `brew autoremove`.

!!! note "Recoverable vs not"
    Removed package caches and orphans can be re-fetched by the package manager. Journal reclaim is
    bounded and non-recoverable.

## Deliberately not automated (Arch)

!!! warning "Mirrorlist and `.pacnew` merges stay manual"
    The helper never runs `pacdiff`, edits `mirrorlist`, or re-ranks mirrors — these are interactive
    and host-specific, and a blind `.pacnew` overwrite has emptied a mirrorlist before. Review pending
    config merges yourself with `sudo pacdiff`, and keep your existing `mirrorlist` rather than
    overwriting it with an empty `.pacnew` template. See the repository's `docs/guides/os-maintenance.md`
    for the mirror re-ranking commands.

## Terminal.app profile sync [macOS]

`task terminal:sync` deploys the Catppuccin Macchiato profile for the macOS Terminal.app. It is a dry
run by default and writes nothing; it works on macOS only and exits on Arch and Debian.

```bash
# macOS
task terminal:sync
```

⚠️  MANUAL STEP — quit Terminal.app and review the dry-run output first

```bash
# macOS
task terminal:sync ARGS='--apply'
```

`--apply` writes a backup first, then adds or updates only the `Catppuccin Macchiato` profile.
Add `--set-default` to also make it the default profile. See [Terminal](terminal.md#terminalapp-macos).

## Generated art

The README banner, the social preview, the logo, the favicon and the [architecture
diagram](../reference/architecture.md) are generated from the repository, in the Catppuccin Macchiato
palette. The social preview is the only raster output; it is rendered at 1280×640.

```bash
task brand:check   # read-only: are generated brand assets and palette current? (also runs in CI)
```

⚠️  MANUAL STEP — review the diff afterwards

```bash
task brand:generate # regenerate banner, social preview, logo, and favicon
```

A short reminder appears before `git commit`, `git push` and `gh pr create` when the art is stale and
the change touches what it is built from. In Claude Code it comes from a project hook; in a plain
terminal it comes from opt-in Git hooks (`task hooks:status`, then `task hooks:install`, a dry run by
default). See the [art setup guide](../guides/art-setup.md).

## Related

- [Installation](../installation.md) · [Repository Structure](../reference/repository-structure.md)
