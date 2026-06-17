# GNU Stow Usage

This repository uses GNU Stow with a package-based layout to manage dotfile symlinks safely and incrementally. Stow is never run automatically — every install is a deliberate manual action.

---

## Layout

```
stow/
├── common/     # Config that works on both macOS and Arch without modification
│   ├── git/    # Git config templates
│   └── zsh/    # Zsh config (shared + macOS + Arch, runtime OS detection)
├── macos/      # macOS-specific config only
└── arch/       # EndeavourOS / Arch-specific config only
```

A package belongs in `common/` only if all three hold:
1. The config file path is identical on macOS and Arch.
2. The config values work unmodified on both platforms.
3. No platform-specific tool or behavior is referenced.

Otherwise it belongs in `macos/` or `arch/`.

---

## Platform directories are not packages

`stow/macos/` and `stow/arch/` currently contain only `.gitkeep` marker files. They are platform areas, not stowable packages. A valid `task dry-run` requires a real package directory under an area — for example `stow/common/git/`.

The only valid dry-run in this phase is:

```bash
task dry-run AREA=common PACKAGE=git
```

When a real package is added under a platform area (e.g., `stow/macos/zsh/`), run `task dry-run AREA=macos PACKAGE=zsh`.

---

## Dry-run a package

Always dry-run before installing. This shows what stow would do without making any changes.

List available packages:

```bash
task list
```

Dry-run a package (`task list` output is `<area>/<package>` — split on `/` to get `AREA` and `PACKAGE`):

```bash
task dry-run AREA=common PACKAGE=git
```

Or directly:

```bash
stow --dir=stow/common --target="$HOME" --simulate git
```

Review the output carefully. If anything looks unexpected, stop and investigate before proceeding.

---

## Install a package

Install is a manual step. Run the dry-run first and review the output.

⚠️  MANUAL STEP — review dry-run output before running
```bash
stow --dir=stow/common --target="$HOME" git
```

Repeat per package. Install one package at a time.

---

## Conflict handling

If stow reports a conflict (an existing file at the link target), **stop immediately**. Do not use `--adopt`.

Resolve manually:
1. Identify the conflicting file in `$HOME`.
2. Decide whether to back it up, remove it, or keep it and not stow this package.
3. Re-run the dry-run after resolving.
4. Only then proceed with install.

`--adopt` is forbidden in this repository — it silently overwrites existing files with the repository version and cannot be undone without the original file.

---

## Adding a new package

1. Determine the correct platform directory:
   - `stow/common/<name>/` — works on both platforms unchanged (see criteria above).
   - `stow/macos/<name>/` — macOS-specific only.
   - `stow/arch/<name>/` — Arch / EndeavourOS-specific only.

2. Create the package directory and add config files. Use `.example` files for any config containing identity, credentials, or sensitive values (see ADR-0003).

3. Dry-run before stowing:

   ```bash
   task dry-run AREA=<platform> PACKAGE=<name>
   ```

4. Review output, then install manually if correct (see above).

---

## Forbidden

The following are forbidden in this repository:

- `stow .` — stows everything without control. Always use explicit package paths.
- `stow --adopt` — silently overwrites existing files. Never use this.
- Running stow without a prior dry-run.
- Stow tasks in scripts, hooks, or CI — all stow operations are manual only.

---

## Git package adoption

The `stow/common/git/` package provides two example files. Neither is stowed directly — copy each locally, fill in any personal additions, then stow.

### Files in this package

| Repository file | Purpose |
|---|---|
| `stow/common/git/.gitconfig.example` | Portable common Git settings (copy to `.gitconfig.common` before stowing) |
| `stow/common/git/.gitignore_global.example` | Common global ignore patterns (copy to `.gitignore_global` before stowing) |

After copying and stowing:

| Local file (user-created, git-ignored) | Symlink created at |
|---|---|
| `stow/common/git/.gitconfig.common` | `~/.gitconfig.common` |
| `stow/common/git/.gitignore_global` | `~/.gitignore_global` |

### Step 1 — Copy the example files locally

```bash
cp stow/common/git/.gitconfig.example stow/common/git/.gitconfig.common
cp stow/common/git/.gitignore_global.example stow/common/git/.gitignore_global
```

Both copied files are git-ignored and will not be committed.

### Step 2 — Review the copies

Open each file and confirm:

- `.gitconfig.common` contains only placeholder values (`Your Name`, `your-email@example.com`) — do not replace placeholders with real values.
- `.gitignore_global` — add any personal ignore patterns you need.

### Step 3 — Dry-run the package

```bash
task dry-run AREA=common PACKAGE=git
```

Or directly:

```bash
stow --dir=stow/common --target="$HOME" --simulate git
```

Expected output shows two symlinks that would be created. If you see a conflict, stop — do not use `--adopt`. See the "Conflict handling" section above.

### Step 4 — Stow the package

⚠️  MANUAL STEP — review dry-run output before running
```bash
stow --dir=stow/common --target="$HOME" git
```

### Step 5 — Add the include directive to your real `~/.gitconfig`

Open your real `~/.gitconfig` in an editor and add:

```ini
[include]
    path = ~/.gitconfig.common
```

Your existing identity, signing setup, and machine-specific settings are unaffected.

### Step 6 — Verify adoption

```bash
# Confirm symlinks exist
ls -la ~/.gitconfig.common ~/.gitignore_global

# Confirm Git resolves the include
git config --list --show-origin | grep -i 'gitconfig.common'

# Confirm excludesfile is active
git config --global core.excludesfile

# Confirm identity is NOT coming from .gitconfig.common (must point to ~/.gitconfig)
git config --show-origin user.name
git config --show-origin user.email
```

### What stays in your local `~/.gitconfig`

Never put any of the following into `.gitconfig.common`:

- `user.name` and `user.email` (identity)
- Any signing configuration
- Credential helpers (platform-specific — not in the common package)
- Work-specific `[includeIf]` blocks
- Machine-specific paths

---

## Zsh package adoption

The `stow/common/zsh/` package provides three example files — one shared layer and one per platform. None are stowed directly — copy each locally, review, then stow. The real files (`shared.zsh`, `macos.zsh`, `arch.zsh`) are git-ignored and will not be committed.

`~/.zshrc` is **never managed by Stow**. After stowing, the user manually appends a source block to their existing `~/.zshrc` — see Step 5.

### Files in this package

| Repository file | Copy target | Purpose |
|---|---|---|
| `stow/common/zsh/.config/zsh/shared.zsh.example` | `shared.zsh` | Portable cross-platform zsh config (sourced on all platforms) |
| `stow/common/zsh/.config/zsh/macos.zsh.example` | `macos.zsh` | macOS-specific zsh config (sourced on macOS only) |
| `stow/common/zsh/.config/zsh/arch.zsh.example` | `arch.zsh` | Arch/EndeavourOS-specific zsh config (sourced on Arch only) |

After copying and stowing, Stow creates symlinks in `~/.config/zsh/`:

- `~/.config/zsh/shared.zsh` → `stow/common/zsh/.config/zsh/shared.zsh`
- `~/.config/zsh/macos.zsh` → `stow/common/zsh/.config/zsh/macos.zsh`
- `~/.config/zsh/arch.zsh` → `stow/common/zsh/.config/zsh/arch.zsh`

All three are symlinked on every platform. Runtime OS detection in `~/.zshrc` determines which platform file is sourced — the unused platform file is harmless.

### Step 1 — Copy the example files locally

```bash
cp stow/common/zsh/.config/zsh/shared.zsh.example stow/common/zsh/.config/zsh/shared.zsh
cp stow/common/zsh/.config/zsh/macos.zsh.example  stow/common/zsh/.config/zsh/macos.zsh
cp stow/common/zsh/.config/zsh/arch.zsh.example   stow/common/zsh/.config/zsh/arch.zsh
```

All three copied files are git-ignored and will not be committed.

### Step 2 — Review the copies

Open each file and:

- Replace all `YOUR_*` placeholder tokens with your real values (or delete lines you do not need).
- Confirm no real secrets, tokens, hostnames, or machine-specific paths are present.
- Confirm the Homebrew prefix in `macos.zsh` is `/opt/homebrew` (Apple Silicon) or `/usr/local` (Intel).

### Step 3 — Dry-run the package

```bash
task dry-run AREA=common PACKAGE=zsh
```

Or directly:

```bash
stow --dir=stow/common --target="$HOME" --simulate zsh
```

Review the output carefully. Expected output shows three symlinks that would be created under `~/.config/zsh/`. If you see a conflict, stop — do not use `--adopt`. See the "Conflict handling" section above.

### Step 4 — Stow the package

⚠️  MANUAL STEP — review dry-run output before running
```bash
stow --dir=stow/common --target="$HOME" zsh
```

### Step 5 — Add the source block to your real `~/.zshrc`

Open your real `~/.zshrc` in an editor and append the following block. This file is **never managed by Stow** — this is a one-time manual step:

```zsh
# Managed zsh config — sourced from dotfiles
source "$HOME/.config/zsh/shared.zsh"

if [[ "$OSTYPE" == "darwin"* ]]; then
  source "$HOME/.config/zsh/macos.zsh"
elif [[ -f /etc/arch-release ]]; then
  source "$HOME/.config/zsh/arch.zsh"
fi
```

Your existing `~/.zshrc` content is unaffected — these lines are appended after it.

### Step 6 — Verify adoption

```bash
# Confirm symlinks exist
ls -l ~/.config/zsh/shared.zsh ~/.config/zsh/macos.zsh ~/.config/zsh/arch.zsh

# Confirm zsh starts cleanly and sources the managed config
zsh -ic 'echo zsh-ok'
```

### Optional — Oh My Posh integration

Oh My Posh is a prompt engine — it is **not** Oh My Zsh and has no plugin manager.
It requires a separate installation step and is never activated automatically.

The `stow/common/omp/` package provides the config template (`omp.toml.example`).
Full adoption steps — including installing Oh My Posh, stowing the omp package, and
wiring up the activation snippet — are documented in the
[Oh My Posh package adoption](#oh-my-posh-package-adoption) section below.

`shared.zsh.example` contains a commented-out OMP block for reference. To activate it:

1. Copy `shared.zsh.example` to `shared.zsh` (git-ignored) and uncomment the OMP block.
2. Follow the full Oh My Posh adoption steps in the section below.

To verify the zsh and omp packages are conflict-free on a clean machine, use
fake-home validation before stowing against real `$HOME`:

```bash
TEST_HOME="$(mktemp -d)"
stow --dir=stow/common --target="$TEST_HOME" --simulate zsh
stow --dir=stow/common --target="$TEST_HOME" --simulate omp
rm -rf "$TEST_HOME"
```

Both commands must return no output (no conflicts). Always remove `$TEST_HOME` after
validation.
