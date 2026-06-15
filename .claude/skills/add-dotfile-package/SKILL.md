# Skill: add-dotfile-package

Defines the future workflow for adding a new dotfile package to the repository.

**Note:** Dotfiles implementation has not started. This skill documents the process for when it does.

## When to use

- User wants to add a new tool's configuration to the dotfiles repository.
- Examples: `nvim`, `zsh`, `tmux`, `git`, `starship`, `alacritty`.

## Process

### Step 1 — Confirm package name

Ask the user:

- What is the tool name? (e.g., `nvim`, `zsh`, `tmux`)
- What config files or directories are involved?
- What is the target path in `$HOME`? (e.g., `~/.config/nvim/`)

### Step 2 — Classify the package

Determine the platform category:

- **common** — config works identically on macOS and Arch.
- **macos** — config is macOS-specific (macOS paths, Homebrew paths, macOS-only features).
- **arch** — config is Arch-specific (Arch paths, pacman hooks, Arch-only features).

If uncertain, default to `common` and note the assumption.

### Step 3 — Prefer `.example` first

During initial adoption:

- Create a `.example` version of the config, not the real config.
- The user reviews and renames the `.example` file locally.
- This prevents accidentally stowing a config that needs local customization.

Example:

```
stow/common/zsh/.zshrc.example   # Template — user copies to .zshrc
```

### Step 4 — Document target paths

Write clear documentation stating:

- Source path in the repository: `stow/<category>/<package>/<path>`
- Target path after stowing: `$HOME/<path>`

Example:

```
stow/common/zsh/.zshrc
  → $HOME/.zshrc

stow/common/nvim/.config/nvim/init.lua
  → $HOME/.config/nvim/init.lua
```

### Step 5 — Add dry-run command

Always document the dry-run command before the install command:

```bash
# Dry run — verify what would be linked
stow --dir=stow --target="$HOME" --simulate <package>
```

### Step 6 — Add install command (after dry-run approval only)

```bash
⚠️  MANUAL STEP — run only after reviewing dry-run output
stow --dir=stow --target="$HOME" <package>
```

### Step 7 — Update README

Add the new package to the repository README:

- Package name.
- Platform category.
- Target path.
- Install command (with dry-run reference).

### Step 8 — Update architecture decisions if needed

If this package changes the overall structure or introduces a new category, update `docs/architecture/` and add a decision record to `docs/decisions/`.

### Step 9 — Never copy real configs automatically

Do not:

- Copy files from `$HOME` into the repository.
- Use `stow --adopt` to pull in existing files.
- Run any command that reads or modifies `$HOME` without explicit user approval.

The user provides the config content manually or adapts the `.example` file.
