# Shell Dependencies

The managed Zsh configuration depends on a small set of external tools. They must be installed
**before** stowing the zsh package or sourcing the managed config files. Nothing in this repository
installs tools automatically — shell startup never runs `brew`, `pacman`, or `git clone`.

This page is curated from the repository's `docs/shell-dependencies.md` and `docs/guides/packages-setup.md`.

## Three separate concerns

| Concern | What it means | How |
|---|---|---|
| **Check** | Detect which tools are present or missing | `task deps:check:zsh` |
| **Install** | Place tools on the system | Manual — see below |
| **Activate** | Wire tools into the shell | Happens when the zsh package is stowed and sourced |

## Dependency tiers

| Tool | Tier | Required? | macOS source | Arch source | Debian source |
|---|---|---|---|---|---|
| `git` | core | Yes | `packages/Brewfile` | `pacman` | `apt` |
| `stow` | core | Yes | `packages/Brewfile` | `pacman` | `apt` |
| `go-task` | core | Yes | `packages/Brewfile` (tap) | `pacman` | out-of-band (`taskfile.dev` install.sh) |
| `fzf` | shell | Optional | `packages/Brewfile` | `pacman` | `apt` |
| `zoxide` | shell | Optional | `packages/Brewfile` | `pacman` | `apt` |
| `eza` | shell | Optional | `packages/Brewfile` | `pacman` | `apt` (trixie / 13+) |
| `bat` | shell | Optional | `packages/Brewfile` | `pacman` | `apt` (runs as `batcat`) |
| `oh-my-posh` | shell | Optional | `packages/Brewfile` (tap) | AUR (`oh-my-posh-bin`) | out-of-band (`ohmyposh.dev` install.sh) |
| `zinit` | shell | Optional | manual git clone | manual git clone | manual git clone |

!!! tip "Optional means optional"
    Every shell-tier integration is guarded with `command -v` and is a no-op when its tool is absent.
    The shell starts cleanly with none of them installed — install only what you want.

!!! info "`go-task` and `task <Tab>` completion"
    `go-task` is both the repo's task runner and a shell-tier dependency: the zsh package's
    `taskfile.zsh` enables `task <Tab>` completion. That completion relies on the native `_task` file
    shipped by the Homebrew (`go-task/tap`) and pacman (`go-task`) packages. Installing `task` another
    way (`go install`, raw `install.sh`) omits `_task`, so completion is unavailable on those installs.
    On Debian, `go-task` is not in the archive and is installed via its `install.sh`, so `task <Tab>`
    completion is not available there.

## Step 1 — Check what is missing

```bash
task deps:check:zsh
```

Or directly:

```bash
bash scripts/check-zsh-deps.sh
```

Output is `PASS: <tool>` or `FAIL: <tool> (not installed)` per tool, with an install hint on failure.
Exit code is non-zero if any required tool is missing.

## Step 2 — Install

=== "macOS"

    All tools via the repo's Brewfile (preview first, then install):

    ⚠️  MANUAL STEP — review `brew bundle list` output before running

    ```bash
    brew bundle list --file=packages/Brewfile
    brew bundle --file=packages/Brewfile
    ```

    `zinit` is not in the Brewfile — clone it once per machine:

    ⚠️  MANUAL STEP — review before running

    ```bash
    git clone https://github.com/zdharma-continuum/zinit.git \
      "${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
    ```

=== "Arch / EndeavourOS"

    Pacman packages:

    ⚠️  MANUAL STEP — review before running

    ```bash
    sudo pacman -S git stow go-task fzf zoxide eza bat
    ```

    AUR (requires `yay` or `paru`):

    ⚠️  MANUAL STEP — review before running

    ```bash
    yay -S oh-my-posh-bin
    ```

    `zinit` (same as macOS):

    ⚠️  MANUAL STEP — review before running

    ```bash
    git clone https://github.com/zdharma-continuum/zinit.git \
      "${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
    ```

    See `packages/arch/packages.txt` in the repository for a full annotated package list.

=== "Debian (trixie / 13+)"

    apt packages (binary names differ: `bat` → `batcat`, `fd` → `fdfind`):

    ⚠️  MANUAL STEP — review before running

    ```bash
    sudo apt install git stow fzf zoxide eza bat
    ```

    `go-task` and `oh-my-posh` are not in the Debian archive — install out-of-band:

    ⚠️  MANUAL STEP — review before running

    ```bash
    sh -c "$(curl -fsSL https://taskfile.dev/install.sh)" -- -d -b ~/.local/bin   # go-task
    curl -s https://ohmyposh.dev/install.sh | bash -s                              # oh-my-posh
    ```

    `zinit` (same as macOS):

    ⚠️  MANUAL STEP — review before running

    ```bash
    git clone https://github.com/zdharma-continuum/zinit.git \
      "${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
    ```

    See `packages/debian/packages.txt` in the repository for a full annotated package list.

## Step 3 — Verify

```bash
task deps:check:zsh
```

All lines should show `PASS`. Exit code `0` means all required shell-tier tools are present.

## Taskfile reference

| Task | What it does |
|---|---|
| `task check` | Check core prerequisites (`git`, `stow`, `task`) |
| `task deps:check:zsh` | Check shell-tier tools |
| `task deps:brew` | Print manual install commands for macOS / Homebrew |
| `task deps:arch` | Print manual install commands for Arch / EndeavourOS |
| `task deps:debian` | Print manual install commands for Debian (stable / trixie) |

None of these tasks install anything — they check and report, or print instructions.

## Related

- [Installation](../installation.md) · [GNU Stow Workflow](stow.md) · [Shell feature page](../features/shell.md)
