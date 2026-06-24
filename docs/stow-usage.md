# GNU Stow Usage

This repository uses GNU Stow with a package-based layout to manage dotfile symlinks safely and incrementally. Stow is never run automatically — every install is a deliberate manual action.

---

## Layout

```
stow/
├── common/          # Config that works on both macOS and Arch without modification
│   ├── alacritty/   # Alacritty terminal emulator config and Catppuccin theme
│   ├── git/         # Git config templates
│   ├── herdr/       # Herdr terminal multiplexer config and Catppuccin theme overrides
│   └── zsh/         # Zsh config (shared + macOS + Arch, runtime OS detection)
├── macos/           # macOS-specific config only
└── arch/            # EndeavourOS / Arch-specific config only
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

### Directory-ownership conflicts

Stow may also report a directory-level conflict:

```
WARNING! stowing <package> would cause conflicts:
  * existing target is not owned by stow: .config/<name>
All operations aborted.
```

This means the target directory (`~/.config/<name>`) already exists and was not
created by Stow. Stow refuses to claim it. This is correct behaviour — **do not use
`--adopt`**.

Resolution options:
1. **Back up and remove the directory**, then re-run the dry-run. Stow will create the
   directory and its symlinks cleanly.
2. **Compare manually**: inspect the existing directory and the package template side
   by side. Migrate intentionally, file by file.
3. **Defer stowing**: keep the real directory as-is and use the `.example` template
   for reference only until you are ready to migrate.

### Fake-home validation

When the real `$HOME` contains a conflicting directory, use a temporary fake home to
verify the package layout without touching real files:

```bash
TEST_HOME="$(mktemp -d)"
stow --dir=stow/common --target="$TEST_HOME" --simulate omp
rm -rf "$TEST_HOME"
```

This confirms Stow would create the correct symlinks on a clean machine, without
risking any real home directory change. Always remove `$TEST_HOME` after validation.

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

## Adding a file to an already-stowed package

Stow does **not** pick up newly added files automatically. When you add a file to a
package that is already stowed into `$HOME` (for example a new `*.zsh` layer in the zsh
package, or a new tool config), the symlink is **not** created until you **re-stow** the
package.

Dry-run first:

```bash
stow --dir=stow/common --target="$HOME" --no-folding --simulate <package>
```

⚠️  MANUAL STEP — review dry-run output before running
```bash
stow --dir=stow/common --target="$HOME" --no-folding --restow <package>
```

Notes:

- `--restow` re-links the package, picking up new files while leaving existing links intact.
- Drop `--no-folding` for packages that do not require it — only `zsh`, `alacritty`, and
  `herdr` use it (the zsh requirement is ADR-0024). `git` and `omp` do not.
- Until you re-stow, the new file lives in the repo but is **not** linked into `$HOME`. To
  test it before re-stowing, source it by its full repository path.

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

Before stowing the zsh package, ensure all shell-tier dependencies are installed.
See [docs/shell-dependencies.md](shell-dependencies.md) for the check and install steps.

The `stow/common/zsh/` package uses **`--no-folding`** (ADR-0024): Stow creates `~/.config/zsh/` as a **real directory** and places **per-file symlinks** for each managed file inside it — it does not collapse the directory into a single symlink pointing at the repo. This ensures a clear boundary between managed (symlinked, repo-based) files and local/private files such as `local.zsh` that live outside the repo.

The package provides example files — a shared layer, one per platform, a managed entry point (`index.zsh`), and a reference `~/.zshrc` template. None are stowed directly — copy each locally, review, then stow. The real files (`shared.zsh`, `macos.zsh`, `arch.zsh`, `index.zsh`, and the optional `local.zsh`) are git-ignored and will not be committed.
`~/.zshrc` is **never managed by Stow**. After stowing, the user manually adds **one guarded include block** to their existing `~/.zshrc` that sources the managed entry point `~/.config/zsh/index.zsh` — see Step 5. For the full safe migration path (Model 4 → Model 3, backup, incremental cutover, rollback), see [docs/zsh-migration.md](zsh-migration.md).

### Files in this package

| Repository file | Copy target | Purpose |
|---|---|---|
| `stow/common/zsh/.config/zsh/shared.zsh.example` | `shared.zsh` | Portable cross-platform zsh config (sourced on all platforms) |
| `stow/common/zsh/.config/zsh/macos.zsh.example` | `macos.zsh` | macOS-specific zsh config (sourced on macOS only) |
| `stow/common/zsh/.config/zsh/arch.zsh.example` | `arch.zsh` | Arch/EndeavourOS-specific zsh config (sourced on Arch only) |
| `stow/common/zsh/.config/zsh/index.zsh.example` | `index.zsh` | Managed entry point — sources the layers in order (sourced by the `~/.zshrc` include block) |
| `stow/common/zsh/.config/zsh/zshrc.example` | *(reference only — never stowed to `~/.zshrc`)* | Template for your real `~/.zshrc`; contains the guarded managed include block |
| *(no `.example`)* | `local.zsh` | Machine-specific/sensitive overrides — real file created directly in `~/.config/zsh/` by the user (not from the repo), git-ignored, never symlinked, sourced last (ADR-0023, ADR-0026) |

After copying and stowing with `--no-folding`, Stow creates `~/.config/zsh/` as a **real directory** and places per-file symlinks inside it:

- `~/.config/zsh/shared.zsh` → `stow/common/zsh/.config/zsh/shared.zsh`
- `~/.config/zsh/macos.zsh` → `stow/common/zsh/.config/zsh/macos.zsh`
- `~/.config/zsh/arch.zsh` → `stow/common/zsh/.config/zsh/arch.zsh`
- `~/.config/zsh/index.zsh` → `stow/common/zsh/.config/zsh/index.zsh`

`local.zsh` is **not** a symlink — the user creates it directly in `~/.config/zsh/` with their editor. Because `~/.config/zsh/` is a real directory (not a symlink into the repo), `local.zsh` lives physically outside the repo working tree and cannot be committed by accident (ADR-0026).


All platform files are symlinked on every platform. Runtime OS detection inside `index.zsh` determines which platform file is sourced — the unused platform file is harmless. `zshrc.example` stows to `~/.config/zsh/zshrc.example` (a reference copy); it is **never** linked to `~/.zshrc`.

### Step 1 — Copy the example files locally

At minimum, copy `index.zsh.example` to activate the managed layer. Copy the other files as needed:

```bash
cp stow/common/zsh/.config/zsh/index.zsh.example  stow/common/zsh/.config/zsh/index.zsh
cp stow/common/zsh/.config/zsh/shared.zsh.example stow/common/zsh/.config/zsh/shared.zsh
# macOS only:
cp stow/common/zsh/.config/zsh/macos.zsh.example  stow/common/zsh/.config/zsh/macos.zsh
# Arch only:
cp stow/common/zsh/.config/zsh/arch.zsh.example   stow/common/zsh/.config/zsh/arch.zsh
# Optional OMP:
cp stow/common/zsh/.config/zsh/omp.zsh.example    stow/common/zsh/.config/zsh/omp.zsh
```

All copied files are git-ignored and will not be committed.

### Step 2 — Review the copies

Open each file and:

- Replace all `YOUR_*` placeholder tokens with your real values (or delete lines you do not need).
- Confirm no real secrets, tokens, hostnames, or machine-specific paths are present.
- Confirm the Homebrew prefix in `macos.zsh` is `/opt/homebrew` (Apple Silicon) or `/usr/local` (Intel).

### Step 3 — Dry-run the package

```bash
task dry-run AREA=common PACKAGE=zsh
```

Or directly (use `--no-folding` — required for the zsh package; ADR-0024):

```bash
stow --dir=stow/common --target="$HOME" --no-folding --simulate zsh
```

Review the output carefully. Expected output shows per-file symlinks that would be created under `~/.config/zsh/` (a real directory, not a symlink). If you see a conflict, stop — do not use `--adopt`. See the "Conflict handling" section above.

**If `~/.config/zsh` currently exists as a directory-fold symlink** (from an earlier stow without `--no-folding`), remove it first:

⚠️  MANUAL STEP — dry-run first; confirm only `~/.config/zsh` symlink would be removed:
```bash
stow --dir=stow/common --target="$HOME" --simulate --delete zsh
```
⚠️  MANUAL STEP — run only after dry-run is confirmed clean:
```bash
stow --dir=stow/common --target="$HOME" --delete zsh
```

Then proceed with the `--no-folding` dry-run and stow below.

### Step 4 — Stow the package

⚠️  MANUAL STEP — review dry-run output before running
```bash
stow --dir=stow/common --target="$HOME" --no-folding zsh
```

### Step 5 — Add the guarded include block to your real `~/.zshrc`

Open your real `~/.zshrc` in an editor and add the following **single guarded block**, placing it **last** so the managed defaults and `local.zsh` take effect after your own lines. This file is **never managed by Stow** — this is a one-time manual step (back up `~/.zshrc` first; see [docs/zsh-migration.md](zsh-migration.md)):

```zsh
# >>> dotfiles managed (zsh) — added manually; delete this block to disable >>>
[[ -r "$HOME/.config/zsh/index.zsh" ]] && source "$HOME/.config/zsh/index.zsh"
# <<< dotfiles managed (zsh) <<<
```

`index.zsh` sources the layers in order — `shared.zsh`, the OS-detected platform file, the optional `omp.zsh`, then the optional `local.zsh`. The block is guarded: if `index.zsh` is absent, the line is a no-op and your shell still starts. Your existing `~/.zshrc` content is unaffected — only this block is added. To revert, delete the three delimited lines.

### Step 6 — Verify adoption

```bash
# Confirm ~/.config/zsh is a real directory (not a symlink)
[[ -d "$HOME/.config/zsh" && ! -L "$HOME/.config/zsh" ]] && echo "real-dir-ok" || echo "NOT-real-dir"

# Confirm per-file symlinks exist
ls -l ~/.config/zsh/index.zsh ~/.config/zsh/shared.zsh

# Confirm zsh starts cleanly and sources the managed config
zsh -ic 'echo zsh-ok'
```

The `real-dir-ok` check is the key indicator that `--no-folding` produced the expected layout. If it prints `NOT-real-dir`, stop and re-run Step 3–4.

### Optional — Create `local.zsh` for machine-specific / sensitive overrides

Create `local.zsh` **directly** in `~/.config/zsh/` — not by copying from the repo. Because `~/.config/zsh/` is a real directory under `--no-folding`, this file lives physically outside the repo and cannot be committed by accident (ADR-0026):

⚠️  MANUAL STEP — create a REAL private file; put secrets and machine-specific values only here
```bash
$EDITOR "$HOME/.config/zsh/local.zsh"
```

`index.zsh` sources it last, so it wins over all managed layers.

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

---

## Oh My Posh package adoption

The `stow/common/omp/` package provides one example file. Do not stow it directly —
copy it locally, customize, then stow. The real file (`omp.toml`) is git-ignored and
will not be committed.

The activation snippet (`omp.zsh`) lives in the zsh package
(`stow/common/zsh/.config/zsh/`), not in the omp package. Both packages must be stowed
for full OMP adoption.

### Prerequisites

Before stowing the omp package, install Oh My Posh and a Nerd Font manually.

**macOS:**

```bash
# Oh My Posh — Option A: Homebrew (recommended)
brew install jandedobbeleer/oh-my-posh/oh-my-posh

# Oh My Posh — Option B: direct binary
curl -s https://ohmyposh.dev/install.sh | bash -s

# Nerd Font — Option A: Homebrew Cask
brew install --cask font-meslo-lg-nerd-font

# Nerd Font — Option B: Oh My Posh font installer (requires OMP installed first)
oh-my-posh font install meslo
```

**Arch / EndeavourOS:**

```bash
# Oh My Posh — AUR
yay -S oh-my-posh-bin

# Oh My Posh — direct binary
curl -s https://ohmyposh.dev/install.sh | bash -s

# Nerd Font — AUR
yay -S ttf-meslo-nerd

# Nerd Font — Oh My Posh font installer (requires OMP installed first)
oh-my-posh font install meslo
```

After installing a Nerd Font, configure your terminal emulator to use it before
activating Oh My Posh.

Verify Oh My Posh installation:

```bash
oh-my-posh --version
```

### Files in the omp package

| Repository file | Copy target | Purpose |
|---|---|---|
| `stow/common/omp/.config/omp/omp.toml.example` | `omp.toml` | Minimal starter theme — customize before stowing |

After copying and stowing, Stow creates:

- `~/.config/omp/omp.toml` → `stow/common/omp/.config/omp/omp.toml`
- `~/.config/omp/omp.toml.example` → `stow/common/omp/.config/omp/omp.toml.example`

The `omp.toml.example` symlink is expected and harmless — Oh My Posh reads only
`omp.toml` and ignores all other files in the directory.

### Step 1 — Copy the example file locally

```bash
cp stow/common/omp/.config/omp/omp.toml.example \
   stow/common/omp/.config/omp/omp.toml
```

The copied file is git-ignored and will not be committed.

### Step 2 — Customize your theme

Open `stow/common/omp/.config/omp/omp.toml` and replace the starter theme with your
preferred configuration. Confirm:

- No real hostnames, usernames, or machine-specific paths.
- No API keys or sensitive values.

### Step 3 — Dry-run the omp package

```bash
task dry-run AREA=common PACKAGE=omp
```

Or directly:

```bash
stow --dir=stow/common --target="$HOME" --simulate omp
```

#### If `~/.config/omp` already exists

Stow will report:

```
WARNING! stowing omp would cause conflicts:
  * existing target is not owned by stow: .config/omp
All operations aborted.
```

This is expected and correct — Stow refuses to claim a directory it does not own.
**Do not use `--adopt`.**

Options:
- **Defer**: the `omp.toml.example` template is available for reference. Do not stow
  yet. Compare your real `~/.config/omp/omp.toml` with the template manually and
  migrate when ready.
- **Migrate**: back up your real `~/.config/omp/` contents, remove the directory,
  copy the example to `omp.toml`, customize, then re-run the dry-run.

To verify the package layout without touching real files, use fake-home validation:

```bash
TEST_HOME="$(mktemp -d)"
stow --dir=stow/common --target="$TEST_HOME" --simulate omp
rm -rf "$TEST_HOME"
```

See "Directory-ownership conflicts" and "Fake-home validation" under "Conflict
handling" above for full detail.

### Step 4 — Stow the omp package

⚠️  MANUAL STEP — review dry-run output before running
```bash
stow --dir=stow/common --target="$HOME" omp
```

### Step 5 — Set up the zsh activation snippet

Copy the activation snippet template from the zsh package:

```bash
cp stow/common/zsh/.config/zsh/omp.zsh.example \
   stow/common/zsh/.config/zsh/omp.zsh
```

Open `omp.zsh` and uncomment the guarded activation block:

```zsh
[[ -x "$(command -v oh-my-posh)" ]] && \
  [[ -f "${HOME}/.config/omp/omp.toml" ]] && \
  eval "$(oh-my-posh init zsh --config "${HOME}/.config/omp/omp.toml")"
```

### Step 6 — Stow (or re-stow) the zsh package

Stow does not pick up newly added files automatically. Re-run stow for the zsh package
to create the `omp.zsh` symlink at `~/.config/zsh/omp.zsh`:

```bash
stow --dir=stow/common --target="$HOME" --no-folding --simulate zsh
```

⚠️  MANUAL STEP — review dry-run output before running
```bash
stow --dir=stow/common --target="$HOME" --no-folding --restow zsh
```

### Step 7 — Add the source guard to your zsh config

In your local `~/.config/zsh/shared.zsh` (or directly in `~/.zshrc`), add:

```zsh
[[ -f "$HOME/.config/zsh/omp.zsh" ]] && source "$HOME/.config/zsh/omp.zsh"
```

This guard is a no-op on machines where `omp.zsh` is absent — shell startup is
unaffected on machines without OMP.

### Step 8 — Verify

```bash
# Confirm omp.toml symlink exists
ls -la ~/.config/omp/omp.toml

# Confirm omp.zsh symlink exists
ls -la ~/.config/zsh/omp.zsh

# Open a new shell and confirm Oh My Posh is active
zsh -ic 'oh-my-posh --version && echo omp-ok'
```

---

## Installing the alacritty package

The `alacritty` package contains:

- `~/.config/alacritty/alacritty.toml` — main Alacritty configuration
- `~/.config/alacritty/catppuccin-macchiato.toml` — Catppuccin Macchiato color theme

Both files are real managed dotfiles (not `.example` templates). No rename or copy
step is needed before stowing.

### Prerequisites

- Alacritty installed (`brew install --cask alacritty` on macOS or
  `sudo pacman -S alacritty` on Arch).
- JetBrainsMono Nerd Font installed (optional — Alacritty falls back to system
  monospace if absent).

### Step 1 — Dry-run

```bash
stow --dir=stow/common --target="$HOME" --simulate --no-folding alacritty
```

Expected: no conflicts reported. If a conflict appears, resolve it manually before
proceeding (do not use `--adopt`).

### Step 2 — Install

⚠️  MANUAL STEP — run only after reviewing dry-run output

```bash
stow --dir=stow/common --target="$HOME" --no-folding alacritty
```

This creates two symlinks:

```
~/.config/alacritty/alacritty.toml
~/.config/alacritty/catppuccin-macchiato.toml
```

### Step 3 — Verify

```bash
ls -la ~/.config/alacritty/
```

Expected: both `alacritty.toml` and `catppuccin-macchiato.toml` are symlinks pointing
into the repository.

### To unlink

⚠️  MANUAL STEP

```bash
stow --dir=stow/common --target="$HOME" --delete alacritty
```

---

## Installing the herdr package

The `herdr` package contains:

- `~/.config/herdr/config.toml` — Herdr terminal multiplexer configuration

This is a real managed dotfile (not an `.example` template). No rename or copy step
is needed before stowing.

### Prerequisites

- Herdr installed (`brew install herdr` on both macOS and Arch/Linux).

### Step 1 — Dry-run

```bash
stow --dir=stow/common --target="$HOME" --simulate --no-folding herdr
```

Expected: no conflicts reported. If a conflict appears, resolve it manually before
proceeding (do not use `--adopt`).

If `~/.config/herdr/` already exists as a real directory, Stow will report a
directory-ownership conflict. Back up and remove the directory, then re-run the
dry-run. See "Conflict handling" above for full detail.

### Step 2 — Install

⚠️  MANUAL STEP — run only after reviewing dry-run output

```bash
stow --dir=stow/common --target="$HOME" --no-folding herdr
```

This creates one symlink:

```
~/.config/herdr/config.toml
```

### Step 3 — Verify

```bash
ls -la ~/.config/herdr/
```

Expected: `config.toml` is a symlink pointing into the repository.

### To unlink

⚠️  MANUAL STEP

```bash
stow --dir=stow/common --target="$HOME" --delete herdr
```
