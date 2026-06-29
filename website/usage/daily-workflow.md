# Daily Workflow

A sketch of how the pieces fit together in normal use. This is *a* workflow, not a required one — take
the parts that suit you.

## Open a terminal

Alacritty starts with `zsh` and the Oh My Posh prompt, which shows the current path and Git status. If
you use Herdr, panes inherit the working directory of the active pane, so new panes open where you are.

## Navigate

`cd` is backed by [zoxide](https://github.com/ajeetdsouza/zoxide) (initialised as `cd` in `tools.zsh`), so it
learns the directories you visit and lets you jump by partial name:

```bash
cd dotfiles      # jumps to a known path matching "dotfiles"
```

Changing directory automatically lists its contents — the `chpwd` hook runs `ll` after every `cd` (see
[Functions](functions.md)).

## List files

With `eza` installed, listing is colorised and icon-aware:

```bash
ls       # eza --icons --long
ll       # eza --icons --all --long
tree     # eza --icons --tree
```

See [Aliases](aliases.md) for the full set and the `ls` fallback when `eza` is absent.

## Work with Git

The Git package ships a large set of short aliases. Common ones in a normal cycle:

```bash
git s      # status
git a      # add --all
git cm "message"   # commit -m
git ps     # push
git lg     # log --oneline --graph --decorate
```

The full alias list is on the [Aliases](aliases.md) page. Identity and includes are wired once during
setup — see [Git](../features/git.md).

## Run repository tasks

Inside the dotfiles repo, `task` is the entrypoint for listing packages, dry-running Stow, and checking
dependencies:

```bash
task             # list available tasks
task list        # list Stow packages
task deps:check:zsh   # check shell-tier tools
```

Safe (read-only) tasks versus system-modifying ones are spelled out on the [Taskfile](taskfile.md) page.

With the optional plugins installed, `<Tab>` completion is fzf-backed and context-aware — `task <Tab>`
lists tasks with descriptions, `herdr <Tab>` lists session names, and file/directory completions show
`eza` / `bat` previews. See [Completions](../features/shell.md#completions).

!!! warning "Tested on macOS, Arch, and Debian"
    These conveniences are tested on macOS (primary), EndeavourOS / Arch Linux, and Debian (trixie / 13+).
    Elsewhere, treat them as a reference and adapt.
