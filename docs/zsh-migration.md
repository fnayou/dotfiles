# Zsh Activation & Migration Runbook (Model 4 → Model 3)

User-facing runbook for safely migrating from your existing hand-tuned `~/.zshrc` to the
managed zsh layer. Nothing here runs automatically — every system-changing step is a
`⚠️  MANUAL STEP` you run and review yourself.

- **PRD:** [docs/prd/0007-zsh-activation-migration.md](prd/0007-zsh-activation-migration.md)
- **Architecture:** [docs/architecture/0007-zsh-activation-migration-architecture.md](architecture/0007-zsh-activation-migration-architecture.md)
- **Decisions:** ADR-0021 (include block + `index.zsh`), ADR-0022 (Model 4 → 3), ADR-0023 (`local.zsh`), ADR-0024 (`--no-folding`), ADR-0026 (`local.zsh` outside repo), ADR-0027 (`~/.zshrc` stays unmanaged).

---

## Migration context: `--no-folding` (ADR-0024)

The zsh package uses **`--no-folding`** for all stow operations. This means:

- `~/.config/zsh/` is a **real directory** — not a directory-fold symlink into the repo.
- Each managed file is an **explicit per-file symlink** (e.g. `~/.config/zsh/index.zsh → …/stow/common/zsh/.config/zsh/index.zsh`).
- `local.zsh` lives as a **real file** directly under `~/.config/zsh/`, physically outside the repo working tree — it cannot be committed by accident (ADR-0026).

If you previously stowed the zsh package without `--no-folding` (producing a single directory-fold symlink `~/.config/zsh → …/stow/…`), see Step 3a — Migrate from folded state below.

---

## The path: Model 4 → Model 3

- **Start (Model 4):** the repo ships a `zshrc.example` reference template. Nothing is
  wired into any startup file. Your shell is untouched.
- **Target (Model 3):** you keep your **own unmanaged** `~/.zshrc` and add **one** guarded
  include block that sources `~/.config/zsh/index.zsh`. `index.zsh` orchestrates the
  managed layers (`shared` → platform → `omp` → `local`).
- **Not used:** a managed/stowed `~/.zshrc` that replaces yours (Model 2) is rejected for
  migration — see ADR-0022. Your `~/.zshrc` is never stowed, replaced, or auto-edited.

You can stop after any step below and still have a working shell.

---

## Step 0 — Check dependencies (read-only, safe anytime)

```bash
task deps:check:zsh
```

This only reports which of `fzf`, `zoxide`, `eza`, `oh-my-posh`, and `zinit` are present.
It installs nothing. Missing tools simply mean their guarded activation lines are no-ops.

Install any missing tools **out-of-band** (never from shell startup). See
[docs/shell-dependencies.md](shell-dependencies.md) for the platform-specific commands.

### Optional one-time installs (only if you want these tools)

**Zinit** (plugin manager) — installed by a one-time manual clone; it is **never**
auto-cloned from shell startup (ADR-0020):

⚠️  MANUAL STEP — review before running
```bash
git clone https://github.com/zdharma-continuum/zinit.git \
  "${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
```

**Oh My Posh** (prompt engine, optional) — install the binary and a Nerd Font manually;
activation stays guarded and opt-in. See the
[Oh My Posh package adoption](stow-usage.md#oh-my-posh-package-adoption) section.

---

## Step 1 — Back up your real `~/.zshrc`

⚠️  MANUAL STEP — review before running
```bash
cp "$HOME/.zshrc" "$HOME/.zshrc.bak.$(date +%Y%m%d)"
```

Keep this backup until migration is complete and verified. It is your full-abort path.

---

## Step 2 — Copy the example files locally

At minimum, copy `index.zsh.example` to activate the managed layer. Copy other files as needed:

```bash
cp stow/common/zsh/.config/zsh/index.zsh.example  stow/common/zsh/.config/zsh/index.zsh
cp stow/common/zsh/.config/zsh/shared.zsh.example stow/common/zsh/.config/zsh/shared.zsh
# macOS only:
cp stow/common/zsh/.config/zsh/macos.zsh.example  stow/common/zsh/.config/zsh/macos.zsh
# Arch only:
cp stow/common/zsh/.config/zsh/arch.zsh.example   stow/common/zsh/.config/zsh/arch.zsh
```

All copied files are git-ignored and will not be committed. Review each, replacing any
`YOUR_*` placeholders. Put machine-specific or sensitive lines in `local.zsh` (next step),
not in the tracked layers.

### Optional — create `local.zsh` for machine-specific / sensitive overrides

`local.zsh` has no `.example` and is never committed (ADR-0023, ADR-0026). Under
`--no-folding`, `~/.config/zsh/` is a real directory — create `local.zsh` **directly
there** (not in the repo), so it lives physically outside the repo working tree:

⚠️  MANUAL STEP — create a REAL private file; put machine-specific and sensitive values only here
```bash
$EDITOR "$HOME/.config/zsh/local.zsh"
```

Do **not** create `local.zsh` inside the repo at `stow/common/zsh/.config/zsh/local.zsh`
— it belongs only in `~/.config/zsh/local.zsh` as a real, uncommitted file.
---

## Step 3 — Validate the package layout (no real `$HOME` change)

Confirm the package produces the expected per-file symlink layout using a fake home
(ADR-0017; does not touch real `$HOME`):

```bash
TEST_HOME="$(mktemp -d)"
stow --dir=stow/common --target="$TEST_HOME" --no-folding --simulate zsh
rm -rf "$TEST_HOME"
```

Expected output: `MKDIR: .config/zsh`, then `LINK:` lines for each physical file in the
package (`index.zsh`, `shared.zsh`, `.example` templates). No errors.

### Step 3a — Migrate from folded state (if `~/.config/zsh` is currently a directory-fold symlink)

If `ls -ld "$HOME/.config/zsh"` shows a symlink (`lrwxr-xr-x`), you have a directory-fold
from an earlier stow. Remove the fold before restowing with `--no-folding`:

⚠️  MANUAL STEP — dry-run first; confirm only `~/.config/zsh` symlink is listed; review before running:
```bash
stow --dir=stow/common --target="$HOME" --simulate --delete zsh
```

⚠️  MANUAL STEP — run only after dry-run is confirmed clean:
```bash
stow --dir=stow/common --target="$HOME" --delete zsh
```

If the dry-run reports a conflict, **STOP** — do not use `--adopt`. Resolve manually.

---

## Step 4 — Stow the package with `--no-folding`

⚠️  MANUAL STEP — dry-run first:
```bash
stow --dir=stow/common --target="$HOME" --no-folding --simulate zsh
```

⚠️  MANUAL STEP — run only after dry-run is confirmed clean:
```bash
stow --dir=stow/common --target="$HOME" --no-folding zsh
```

This creates a **real directory** `~/.config/zsh/` with **per-file symlinks** for each
managed file. It does **not** touch `~/.zshrc`.

### Verify post-stow layout

```bash
# Confirm real directory (not a symlink)
[[ -d "$HOME/.config/zsh" && ! -L "$HOME/.config/zsh" ]] && echo "real-dir-ok" || echo "NOT-real-dir"

# Confirm per-file symlinks
for f in index.zsh shared.zsh; do
  [[ -L "$HOME/.config/zsh/$f" ]] && echo "$f -> $(readlink "$HOME/.config/zsh/$f")" \
                                  || echo "$f MISSING or not a symlink"
done
```

---

## Step 5 — Add the guarded include block to `~/.zshrc` (placed LAST)

Open your real `~/.zshrc` and add this block **at the end**, so managed defaults and
`local.zsh` take effect after your own lines:

⚠️  MANUAL STEP — edit your own `~/.zshrc` by hand
```zsh
# >>> dotfiles managed (zsh) — added manually; delete this block to disable >>>
[[ -r "$HOME/.config/zsh/index.zsh" ]] && source "$HOME/.config/zsh/index.zsh"
# <<< dotfiles managed (zsh) <<<
```

Open a new shell to verify:

```bash
zsh -ic 'echo zsh-ok'
```

---

## Step 6 — Incremental cutover (one capability at a time)

Move capabilities from your original `~/.zshrc` lines into the managed layers gradually,
verifying after each move. Suggested order:

1. History settings → already in `shared.zsh`; remove the duplicates from `~/.zshrc`.
2. Completions → `shared.zsh` (note the compinit/Zinit ordering already handled there).
3. Portable aliases → `shared.zsh`.
4. Tool integrations (fzf / zoxide / eza) → `shared.zsh` (guarded; no-op when absent).
5. Platform bits (Homebrew `shellenv`, macOS aliases) → `macos.zsh` **[macOS]**; PATH/AUR
   helpers → `arch.zsh` **[Arch]**.
6. Prompt (Oh My Posh) → `omp.zsh` (opt-in, guarded).
7. Machine-specific / sensitive lines → `local.zsh`.

After each move: open a new shell, confirm behavior, then delete the now-redundant line
from `~/.zshrc`. Tool installs and the Zinit clone remain manual, out-of-band steps —
never add them to any startup file.

---

## Rollback

Staged and low-risk — your `~/.zshrc` was never stowed.

1. **Instant disable:** delete (or comment) the three delimited lines of the managed block
   in `~/.zshrc`, open a new shell. The managed layer goes inert immediately. No data loss.

2. **Per-capability revert:** restore the relevant line in `~/.zshrc` from your backup, or
   remove the one guarded line from the managed layer file.

3. **Disable a single layer:** remove the real `omp.zsh` (drops the prompt) or one guarded
   tool line in `shared.zsh`. Guards make partial states safe.

4. **Full abort:** restore your backup, then optionally unstow and remove the copied files.

   ⚠️  MANUAL STEP — dry-run first; review before running:
   ```bash
   stow --dir=stow/common --target="$HOME" --simulate --delete zsh
   ```
   ⚠️  MANUAL STEP — run after reviewing dry-run:
   ```bash
   cp "$HOME/.zshrc.bak.$(date +%Y%m%d)" "$HOME/.zshrc"   # restore your backup (adjust date)
   stow --dir=stow/common --target="$HOME" --delete zsh    # remove per-file symlinks
   ```

   To remove the copied real files, delete them **by name only** — **never** run a broad
   `rm -rf ~/.config/zsh`:

   ⚠️  MANUAL STEP — review before running; removes ONLY these named files
   ```bash
   rm -f ~/.config/zsh/index.zsh ~/.config/zsh/shared.zsh \
         ~/.config/zsh/macos.zsh ~/.config/zsh/arch.zsh \
         ~/.config/zsh/omp.zsh
   # Optional — only if you want to remove your private local.zsh:
   rm -f ~/.config/zsh/local.zsh
   ```

5. **Re-fold fallback (optional):** to restore the prior folded state, re-stow without
   `--no-folding` (dry-run first):

   ⚠️  MANUAL STEP — dry-run first:
   ```bash
   stow --dir=stow/common --target="$HOME" --simulate zsh
   ```
   ⚠️  MANUAL STEP — run after reviewing dry-run:
   ```bash
   stow --dir=stow/common --target="$HOME" zsh
   ```

6. **Verify:**

   ```bash
   zsh --no-rcs -c 'echo ok'   # zsh starts cleanly with no rc files
   ls -l ~/.config/zsh/        # confirm which entries remain
   ```

---

## Safety summary

- Your real `~/.zshrc` is never stowed, replaced, or auto-edited — you add one block by hand.
- No shell startup file installs tools or clones Zinit. Activation is guarded
  (activate-if-present); installation is always a separate, manual, out-of-band step.
- Oh My Posh is opt-in and double-guarded (binary + config); it never activates
  automatically.
- Stow is only ever dry-run against a fake home for layout checks; conflicts on real
  `$HOME` are stop signals, never resolved with `--adopt`.
- Rollback never uses a broad destructive command; cleanup is scoped to named files.
