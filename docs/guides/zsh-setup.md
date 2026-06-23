# Zsh Package Setup Guide

This guide explains how to set up the managed zsh configuration on a new machine. It is written for a human user performing the setup, not for implementation agents.

---

## 1. What this package manages

The `stow/common/zsh/` package manages files under `~/.config/zsh/`. After Stow, `~/.config/zsh/` is a **real directory** (not a symlink), and each managed file inside it is a per-file symlink into the repository.

### Real tracked managed files (committed directly — no copying required)

| Repository file | Symlink created at | Purpose |
|---|---|---|
| `stow/common/zsh/.config/zsh/index.zsh` | `~/.config/zsh/index.zsh` | Entry point — sources all layers in order |
| `stow/common/zsh/.config/zsh/shared.zsh` | `~/.config/zsh/shared.zsh` | XDG vars + portable env (EDITOR, PAGER) only |
| `stow/common/zsh/.config/zsh/path.zsh` | `~/.config/zsh/path.zsh` | PATH additions (safe, `$HOME`-relative) |
| `stow/common/zsh/.config/zsh/history.zsh` | `~/.config/zsh/history.zsh` | HISTFILE, HISTSIZE, SAVEHIST, history setopts |
| `stow/common/zsh/.config/zsh/completions.zsh` | `~/.config/zsh/completions.zsh` | Completion styles only (compinit runs in `plugins.zsh` — ADR-0049) |
| `stow/common/zsh/.config/zsh/taskfile.zsh` | `~/.config/zsh/taskfile.zsh` | go-task completion tuning — guarded, no-op without `task` |
| `stow/common/zsh/.config/zsh/keybindings.zsh` | `~/.config/zsh/keybindings.zsh` | Key bindings (autosuggest binding guarded by widget check) |
| `stow/common/zsh/.config/zsh/aliases.zsh` | `~/.config/zsh/aliases.zsh` | Portable aliases (grep) |
| `stow/common/zsh/.config/zsh/tools.zsh` | `~/.config/zsh/tools.zsh` | fzf, zoxide, eza guards |
| `stow/common/zsh/.config/zsh/plugins.zsh` | `~/.config/zsh/plugins.zsh` | Zinit guarded source (no auto-clone); owns plugin order + compinit (ADR-0049) |
| `stow/common/zsh/.config/zsh/prompt.zsh` | `~/.config/zsh/prompt.zsh` | Oh My Posh double-guarded (no-op if missing) |
| `stow/common/zsh/.config/zsh/macos.zsh` | `~/.config/zsh/macos.zsh` | macOS-specific (brew guard, `alias o='open'`) |
| `stow/common/zsh/.config/zsh/arch.zsh` | `~/.config/zsh/arch.zsh` | Arch-specific (AUR helper guard, systemctl aliases) |

### Example-only file (user copies to create private local overrides)

| Repository file | Target location | Purpose |
|---|---|---|
| `stow/common/zsh/.config/zsh/local.zsh.example` | `~/.config/zsh/local.zsh` | Skeleton showing what private overrides look like |

`local.zsh` is git-ignored and must never be committed. It lives physically outside the repository working tree.

### Reference file (not sourced by zsh)

| Repository file | Purpose |
|---|---|
| `stow/common/zsh/.config/zsh/zshrc.example` | Reference template showing the `~/.zshrc` include block |

### Separate packages — zsh and omp

The zsh and omp packages are separate. The zsh package works without the omp package — `prompt.zsh` is a no-op when `oh-my-posh` is not installed or `omp.toml` is missing.

The `stow/common/omp/` package manages `~/.config/omp/omp.toml`. Stow it separately if you want Oh My Posh.

---

## 2. What this package does NOT manage

- **`~/.zshrc` remains unmanaged.** This package never stows, symlinks, overwrites, or reads `~/.zshrc`. Your existing `~/.zshrc` is fully preserved. After Stow, you manually add one guarded include block to `~/.zshrc` (see Step 3).
- **`~/.zshenv`, `~/.zprofile`, `~/.zlogin`** are not managed.
- **`local.zsh`** is not a Stow symlink — you copy `local.zsh.example` to `~/.config/zsh/local.zsh` with your editor (see Step 5).
- **No tool is installed** by this package. Zinit, fzf, zoxide, eza, and oh-my-posh are optional and must be installed separately if you want them.

---

## 3. Prerequisites

The following tools must be installed before stowing:

| Tool | Purpose | Required? |
|---|---|---|
| `stow` | Symlink manager | Yes |
| `zsh` | Shell | Yes |
| `git` | Repository management | Yes |

Optional tools (not required to start; all integrations are guarded and are no-ops when absent):

| Tool | Integration in | Required by |
|---|---|---|
| Zinit | `plugins.zsh` — guarded source; no-op if absent | `zsh-syntax-highlighting`, `zsh-autosuggestions`, `fzf-tab` |
| fzf (>= 0.48) | `tools.zsh`, `completions.zsh` — `fzf --zsh` guard; no-op if absent | fzf-tab previews |
| zoxide | `tools.zsh` — `zoxide init --cmd cd zsh`; no-op if absent | `cd` smart jump (aliased to zoxide) |
| eza | `tools.zsh`, `aliases.zsh`, `completions.zsh` — guarded; no-op if absent | `ls`/`ll`/`tree` aliases, fzf-tab previews |
| bat | `aliases.zsh` — suffix aliases (`.md`, `.txt`, `.log`) guarded by `command -v bat` | file preview in terminal |
| oh-my-posh | `prompt.zsh` — double-guarded; no-op if absent or if omp.toml missing | shell prompt theme |
| go-task | `taskfile.zsh` — `command -v task` guard; no-op if absent | `task <Tab>` completion (needs brew/pacman install for the `_task` file) |

Verify required tools:

```bash
zsh --version
stow --version
git --version
```

### Installing optional tools

Install all optional tools via Homebrew (macOS) or pacman/AUR (Arch) before stowing if you want full functionality.

**macOS (Homebrew):**

```bash
brew install eza
brew install fzf
brew install zoxide
brew install bat
brew install jandedobbeleer/oh-my-posh/oh-my-posh
```

**Arch / EndeavourOS:**

```bash
sudo pacman -S eza fzf zoxide bat
yay -S oh-my-posh-bin
```

**Zinit (all platforms — manual clone only, no brew formula):**

```bash
git clone https://github.com/zdharma-continuum/zinit.git \
  "${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
```

Zinit is loaded by `plugins.zsh` at shell startup. If it is absent, the shell prints an error and the plugin block is skipped.

Verify optional tools after installing:

```bash
eza --version
fzf --version   # must be >= 0.48
zoxide --version
bat --version
oh-my-posh --version
ls "${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git/zinit.zsh" && echo "zinit ok"
```

---

## Configuration philosophy

This repository commits personal daily-use configuration directly into managed zsh files.
`local.zsh` is reserved for truly private or machine-specific content only.

**Commit to versioned managed files** (e.g., `aliases.zsh`, `shared.zsh`, `macos.zsh`) when the content:
- has no secrets, credentials, tokens, or API keys,
- has no private hostnames or company-specific commands,
- uses no machine-specific absolute paths,
- guards optional tools with `command -v`,
- works safely on macOS and Linux (or is OS-gated).

**Keep in `~/.config/zsh/local.zsh`** (untracked, never committed) when the content:
- contains private paths, work binaries, or internal tools,
- is work-specific or employer-specific,
- differs meaningfully between your machines,
- contains credentials, tokens, or secrets,
- is a temporary experiment not ready to version.

---

## Step 1: Dry-run zsh package

Always dry-run before stowing. This shows exactly what symlinks would be created without making any changes.

```bash
stow --dir=stow/common --target="$HOME" --no-folding --simulate zsh
```

Note: `task dry-run` does not pass `--no-folding`; use the direct command above for this package.

**What to look for:** Lines like `LINK: .config/zsh/index.zsh => …` for each managed file. No `CONFLICT` or `WARNING` lines.

**If you see a conflict:** Do not use `--adopt`. See the Troubleshooting section.

---

## Step 2: Apply zsh package

⚠️  MANUAL STEP — review dry-run output before running

```bash
stow --dir=stow/common --target="$HOME" --no-folding zsh
```

This creates `~/.config/zsh/` as a real directory and places per-file symlinks inside it. After this step, `~/.config/zsh/` exists but your shell does not yet use the managed config — see Step 3.

---

## Step 2b: Set zsh as your login shell

This repository never changes your login shell (ADR-0027 / PRD-0007 — `chsh` is a
forbidden repo action). You must do it yourself, once, as a manual step.

Check your current default shell:

```bash
getent passwd "$USER" | cut -d: -f7
```

If it is not `zsh`, set it:

⚠️  MANUAL STEP — changes your login shell; review before running

```bash
chsh -s "$(command -v zsh)"
```

Log out and back in for it to take effect. Without this, your login shell stays
(for example) bash, and the managed `~/.zshrc` layer never loads on a fresh login.

---

## Step 3: Wire `~/.zshrc` to the managed layer

`~/.zshrc` is never managed by Stow (ADR-0027). After stowing, use `zsh:bootstrap` to append the managed include block to your real `~/.zshrc`. The block is guarded: if `index.zsh` is absent, it is a no-op and your shell starts normally.

### 3a. Preview what would change (dry-run)

```bash
task zsh:bootstrap:dry-run
```

This shows whether `~/.zshrc` exists, whether the managed block is already present, and the exact block that would be appended. No files are modified.

**Symlink check:** if `~/.zshrc` is a symlink, the task reports "would REFUSE (symlink)" and stops. Do not wire a symlink target — resolve this before proceeding.

### 3b. Apply the managed block

⚠️  MANUAL STEP — review dry-run output before running

```bash
task zsh:bootstrap
```

**What this does:**
- If `~/.zshrc` is a symlink → refuses and exits with an error. No file is written.
- If `~/.zshrc` exists and the managed block is already present → prints "already present — nothing to do" and exits. Safe to run again.
- If `~/.zshrc` exists and the managed block is absent → creates a timestamped backup (`~/.zshrc.bak.YYYYMMDDHHMMSS`), then appends the block.
- If `~/.zshrc` does not exist → creates the file with the managed block.

**Backup:** a timestamped backup is always created before any modification. The path is printed to the terminal.

**Idempotency:** running `task zsh:bootstrap` twice is safe — no duplicate blocks, no errors.

**Managed block appended:**

```zsh
# >>> dotfiles managed zsh layer >>>
if [[ -r "$HOME/.config/zsh/index.zsh" ]]; then
  source "$HOME/.config/zsh/index.zsh"
fi
# <<< dotfiles managed zsh layer <<<
```

### 3c. Rollback

To undo the managed block:

- **Restore from backup:** replace `~/.zshrc` with the timestamped backup printed by `task zsh:bootstrap`.
- **Manual removal:** open `~/.zshrc` and delete the five managed-block lines (from `# >>> dotfiles managed zsh layer >>>` to `# <<< dotfiles managed zsh layer <<<`).

After removing the block, open a new shell to confirm the managed layer is inactive.

---

## Step 4 (optional): Stow omp package

The omp package manages `~/.config/omp/omp.toml`, which is the theme config for Oh My Posh. The zsh `prompt.zsh` activates only when both the binary and this file are present.

Dry-run first:

```bash
stow --dir=stow/common --target="$HOME" --no-folding --simulate omp
```

⚠️  MANUAL STEP — review dry-run output before running

```bash
stow --dir=stow/common --target="$HOME" --no-folding omp
```

Note: oh-my-posh binary must be installed separately before the prompt activates. Install options:

```bash
# macOS (Homebrew):
brew install jandedobbeleer/oh-my-posh/oh-my-posh

# Arch / EndeavourOS (AUR):
yay -S oh-my-posh-bin
```

---

## Step 5 (optional): Create `local.zsh`

`local.zsh` is the machine-specific, private layer. It is sourced last by `index.zsh` and wins over all managed layers. Copy the example skeleton to get started:

⚠️  MANUAL STEP — this creates a private file at ~/.config/zsh/local.zsh; never commit it

```bash
cp stow/common/zsh/.config/zsh/local.zsh.example ~/.config/zsh/local.zsh
```

Then edit the file to add your private overrides:

⚠️  MANUAL STEP — review before running

```bash
$EDITOR "$HOME/.config/zsh/local.zsh"
```

Because `~/.config/zsh/` is a real directory (not a symlink into the repo), `local.zsh` lives physically outside the repository working tree and cannot be committed by accident.

`local.zsh` is absent by default. Its absence is safe — `index.zsh` guards the source with `[[ -r … ]]`.

---

## Verification

After stowing and adding the include block, verify the setup with these commands:

```bash
# 1. Confirm ~/.config/zsh is a real directory (not a symlink)
[[ -d "$HOME/.config/zsh" && ! -L "$HOME/.config/zsh" ]] && echo "real-dir-ok" || echo "NOT-real-dir"
# Expected: real-dir-ok

# 2. Confirm per-file symlinks exist
ls -la "$HOME/.config/zsh/index.zsh" "$HOME/.config/zsh/shared.zsh"
# Expected: two symlinks pointing into the repo

# 3. Confirm the managed layer loads cleanly
zsh --no-rcs -c 'source ~/.config/zsh/index.zsh; echo OK'
# Expected: OK (no errors)

# 4. Confirm EDITOR and PAGER are set
zsh --no-rcs -c 'source ~/.config/zsh/index.zsh; echo "$EDITOR $PAGER"'
# Expected: nvim less (or your local.zsh override)

# 5. Confirm XDG_CONFIG_HOME is set
zsh --no-rcs -c 'source ~/.config/zsh/index.zsh; echo "$XDG_CONFIG_HOME"'
# Expected: /Users/YOUR_USERNAME/.config (or your custom value)

# 6. Confirm HISTFILE is set correctly
zsh --no-rcs -c 'source ~/.config/zsh/index.zsh; echo "$HISTFILE"'
# Expected: /Users/YOUR_USERNAME/.zsh_history

# 7. Confirm zoxide is available (if installed)
zsh --no-rcs -c 'source ~/.config/zsh/index.zsh; type z'
# Expected: z is a shell function (if zoxide installed), or "z not found" without error

# 8. Confirm eza alias is active (if eza installed)
zsh --no-rcs -c 'source ~/.config/zsh/index.zsh; type ls'
# Expected: ls is an alias for eza (if eza installed), or ls is /bin/ls

# 9. Confirm local.zsh is a real file, not a symlink (if present)
p="$HOME/.config/zsh/local.zsh"
if   [[ -L $p ]]; then echo "SYMLINK — WRONG"
elif [[ -e $p ]]; then echo "real file — ok"
else echo "absent — ok"; fi
# Expected: real file — ok, or absent — ok
```

---

## Rollback

To remove the managed zsh layer completely:

**Step 1 — Remove the include block from `~/.zshrc`:**

⚠️  MANUAL STEP — open ~/.zshrc and delete the managed-block lines

Delete these lines from `~/.zshrc`:

```zsh
# >>> dotfiles managed zsh layer >>>
if [[ -r "$HOME/.config/zsh/index.zsh" ]]; then
  source "$HOME/.config/zsh/index.zsh"
fi
# <<< dotfiles managed zsh layer <<<
```

Alternatively, restore the timestamped backup created by `task zsh:bootstrap` (path was printed when the task ran).

After removing the block, the managed layer is inert. Open a new shell to confirm.

**Step 2 — Remove Stow symlinks (optional):**

⚠️  MANUAL STEP — dry-run first to confirm what will be removed

```bash
stow --dir=stow/common --target="$HOME" --no-folding --simulate --delete zsh
```

⚠️  MANUAL STEP — run only after confirming the dry-run output

```bash
stow --dir=stow/common --target="$HOME" --no-folding --delete zsh
```

This removes the per-file symlinks from `~/.config/zsh/`. The `~/.config/zsh/` directory itself is not removed — it may still contain `local.zsh`.

**Step 3 — Remove local.zsh (optional):**

⚠️  MANUAL STEP — this removes your private local overrides permanently

```bash
rm "$HOME/.config/zsh/local.zsh"
```

---

## Troubleshooting

**Stow reports a conflict on `~/.config/zsh`:**

```
WARNING! stowing zsh would cause conflicts:
  * existing target is not owned by stow: .config/zsh
All operations aborted.
```

This means `~/.config/zsh/` already exists and was not created by Stow. Do not use `--adopt` — it silently overwrites files without a backup.

Options:
- **Back up and remove the directory**, then re-run the dry-run:

  ⚠️  MANUAL STEP — back up first; confirm the directory can be removed safely

  ```bash
  cp -r "$HOME/.config/zsh" "$HOME/.config/zsh.bak.$(date +%Y%m%d%H%M%S)"
  rm -rf "$HOME/.config/zsh"
  stow --dir=stow/common --target="$HOME" --no-folding --simulate zsh
  ```

- **Defer stowing:** keep the existing directory for reference and migrate manually when ready.

**`real-dir-ok` check fails (prints `NOT-real-dir`):**

`~/.config/zsh` is a symlink rather than a real directory. This happens if you previously stowed without `--no-folding`. Fix:

⚠️  MANUAL STEP — remove the old directory symlink first

```bash
stow --dir=stow/common --target="$HOME" --simulate --delete zsh
stow --dir=stow/common --target="$HOME" --delete zsh
stow --dir=stow/common --target="$HOME" --no-folding --simulate zsh
stow --dir=stow/common --target="$HOME" --no-folding zsh
```

**`fzf --zsh` reports an error:**

Your fzf version is older than 0.48. Check: `fzf --version`. Options:
- Upgrade fzf.
- In your `local.zsh`, override with the manual integration path for your fzf install method (see `~/.fzf.zsh` or `/usr/share/fzf/key-bindings.zsh`).

**Oh My Posh does not activate:**

Confirm both guards pass:

```bash
command -v oh-my-posh && echo "binary ok" || echo "binary missing"
ls "${XDG_CONFIG_HOME:-$HOME/.config}/omp/omp.toml" && echo "config ok" || echo "config missing"
```

If the config is missing, ensure the `common/omp` Stow package has been stowed.

**`local.zsh` changes not taking effect:**

Confirm `local.zsh` is at `~/.config/zsh/local.zsh` (not inside the repo):

```bash
ls -la "$HOME/.config/zsh/local.zsh"
# Expected: a regular file (not a symlink)
```

Open a new shell after saving changes — `local.zsh` is sourced at shell startup, not dynamically.

**A tool is installed but `command not found` in zsh (e.g. `zoxide`, `fzf`, `task`):**

The tool is on PATH in your old shell (often bash) but not in zsh. The most common
cause on Arch / EndeavourOS is a tool installed via **Homebrew on Linux** (linuxbrew):
`arch.zsh` intentionally does **not** run `brew shellenv` (no Homebrew assumptions on
Arch — see the cross-platform rules), so brew's bin directory never reaches zsh's PATH.
The macOS layer (`macos.zsh`) wires brew; the Arch layer deliberately does not.

Fix it in your untracked `~/.config/zsh/local.zsh` (machine-specific, sourced last).
Because `tools.zsh` runs **before** `local.zsh`, the PATH-dependent tool integrations
(`zoxide init`, `fzf --zsh`) already ran and were skipped — so re-run them here after
putting brew on PATH:

```zsh
# Homebrew on Linux (machine-specific — keep in local.zsh, never in committed arch.zsh)
[[ -x /home/linuxbrew/.linuxbrew/bin/brew ]] && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# Re-init tools that tools.zsh skipped before brew was on PATH
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init --cmd cd zsh)"
command -v fzf    >/dev/null 2>&1 && eval "$(fzf --zsh)"
```

Open a new shell to confirm: `command -v zoxide` should now resolve. Alternatively,
install the tools from pacman instead of brew (`sudo pacman -S zoxide fzf`) so they
land in `/usr/bin`, which is already on PATH — then no `local.zsh` wiring is needed.

---

## File model

| File | Tracked in repo | Private/local | Notes |
|---|---|---|---|
| `index.zsh` | Yes | No | Entry point — committed directly |
| `shared.zsh` | Yes | No | XDG + env — committed directly |
| `path.zsh` | Yes | No | PATH additions — committed directly |
| `history.zsh` | Yes | No | History config — committed directly |
| `completions.zsh` | Yes | No | Completion styles — committed directly |
| `taskfile.zsh` | Yes | No | go-task completion tuning — committed directly |
| `keybindings.zsh` | Yes | No | Key bindings — committed directly |
| `aliases.zsh` | Yes | No | Portable aliases — committed directly |
| `tools.zsh` | Yes | No | Tool guards — committed directly |
| `plugins.zsh` | Yes | No | Zinit guard + compinit — committed directly |
| `prompt.zsh` | Yes | No | OMP double-guard — committed directly |
| `macos.zsh` | Yes | No | macOS layer — committed directly |
| `arch.zsh` | Yes | No | Arch layer — committed directly |
| `local.zsh.example` | Yes | No | Skeleton only — user copies to `~/.config/zsh/local.zsh` |
| `local.zsh` | No (git-ignored) | Yes | Machine-specific overrides; lives outside repo working tree |
| `zshrc.example` | Yes | No | Reference only — shows the `~/.zshrc` include block |
| `omp.toml` (omp pkg) | Yes | No | OMP theme — committed directly in `stow/common/omp/` |

---

## Expected final file layout

After all steps are complete, `~/.config/zsh/` should look like this:

```
~/.config/zsh/                             (real directory — created by Stow)
├── index.zsh          -> …/stow/common/zsh/.config/zsh/index.zsh
├── shared.zsh         -> …/stow/common/zsh/.config/zsh/shared.zsh
├── path.zsh           -> …/stow/common/zsh/.config/zsh/path.zsh
├── history.zsh        -> …/stow/common/zsh/.config/zsh/history.zsh
├── completions.zsh    -> …/stow/common/zsh/.config/zsh/completions.zsh
├── taskfile.zsh       -> …/stow/common/zsh/.config/zsh/taskfile.zsh
├── keybindings.zsh    -> …/stow/common/zsh/.config/zsh/keybindings.zsh
├── aliases.zsh        -> …/stow/common/zsh/.config/zsh/aliases.zsh
├── tools.zsh          -> …/stow/common/zsh/.config/zsh/tools.zsh
├── plugins.zsh        -> …/stow/common/zsh/.config/zsh/plugins.zsh
├── prompt.zsh         -> …/stow/common/zsh/.config/zsh/prompt.zsh
├── macos.zsh          -> …/stow/common/zsh/.config/zsh/macos.zsh
├── arch.zsh           -> …/stow/common/zsh/.config/zsh/arch.zsh
├── local.zsh.example  -> …/stow/common/zsh/.config/zsh/local.zsh.example
├── zshrc.example      -> …/stow/common/zsh/.config/zsh/zshrc.example
└── local.zsh                              (real file — created by you; NOT a symlink)
```

And after stowing the omp package:

```
~/.config/omp/                             (real directory — created by Stow)
└── omp.toml           -> …/stow/common/omp/.config/omp/omp.toml
```

Key properties:
- `~/.config/zsh/` itself is a **real directory**, not a symlink.
- Every managed `.zsh` file is a **per-file symlink** into the repository.
- `local.zsh` is a **real file**, physically outside the repository.
- `~/.zshrc` is unchanged and unmanaged by this package.
