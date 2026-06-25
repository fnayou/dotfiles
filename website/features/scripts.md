# Scripts

Routine system maintenance runs through the project's `task` runner. The helper script
(`scripts/os-maintenance.sh`) detects the OS and runs the matching package-manager commands, so the
same tasks work on macOS and Arch.

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

## Related

- [Installation](../installation.md) · [Repository Structure](../reference/repository-structure.md)
