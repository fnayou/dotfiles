# OS Maintenance Guide

Routine system maintenance for **macOS** and **EndeavourOS / Arch**, run through the project's
`task` runner. The helper script is `scripts/os-maintenance.sh`; it detects the OS and runs the
matching package-manager commands.

Two concerns are kept separate:

- **update** — sync + upgrade installed packages.
- **clean** — routine hygiene: orphan removal, package-cache pruning, journal vacuum.
  Non-destructive by default (reports only); deletes only with `--apply`.

## Update

```bash
task update
```

- **Arch:** runs `yay -Syu` (or `sudo pacman -Syu` if `yay` is absent).
- **macOS:** runs `brew update && brew upgrade`.

Interactive — you will be prompted for confirmation / sudo as usual.

## Clean — dry run (default, safe)

```bash
task clean
```

Reports what cleanup *would* remove and deletes nothing:

- **Arch:** orphans (`pacman -Qtdq`), cached versions beyond the last 3 (`paccache`), and current
  journal disk usage.
- **macOS:** `brew cleanup --dry-run`, `brew autoremove --dry-run`, `brew doctor`.

## Clean — apply (destructive)

The applying path re-prints the report, then performs the removals.

⚠️  MANUAL STEP — review the dry-run output first
```bash
task clean:apply
```

- **Arch:** `sudo pacman -Rns <orphans>` (only if any), `sudo paccache -rk3`,
  `sudo paccache -ruk0`, `sudo journalctl --vacuum-size=200M`.
- **macOS:** `brew cleanup`, `brew autoremove`.

Recovery: removed package caches and orphans can be re-fetched by the package manager; journal
reclaim is bounded and non-recoverable.

## Not automated: mirrorlist and `.pacnew` merges (Arch)

The helper deliberately never runs `pacdiff`, edits `mirrorlist`, or re-ranks mirrors — these are
interactive and host-specific, and a blind `.pacnew` overwrite has emptied a mirrorlist before.
Do them by hand.

### Review pending `.pacnew` config merges

⚠️  MANUAL STEP — review each diff; never blind-overwrite mirrorlist
```bash
sudo pacdiff
```

For `mirrorlist` and `endeavouros-mirrorlist`: **keep your existing file** (do not overwrite with
the empty `.pacnew` template) or re-rank afterwards.

### Re-rank Arch mirrors after a mirrorlist reset

⚠️  MANUAL STEP — adjust `--country` to your region
```bash
sudo reflector --protocol https --latest 20 --sort rate --country 'France,Germany' --save /etc/pacman.d/mirrorlist
```

EndeavourOS mirrors only:

```bash
sudo eos-rankmirrors
```

## Notes

- There is intentionally no zsh alias for these commands yet; run them via `task` from the repo.
  A guarded shell wrapper is deferred until the repo has a stable path anchor (see ADR 0051).
- The existing pacman/AUR aliases (`pacu`, `pacs`, `paci`, `aur`) are unchanged.
