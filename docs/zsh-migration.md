# Zsh Activation & Migration Runbook (Model 4 → Model 3)

User-facing runbook for safely migrating from your existing hand-tuned `~/.zshrc` to the
managed zsh layer. Nothing here runs automatically — every system-changing step is a
`⚠️  MANUAL STEP` you run and review yourself.

- **PRD:** [docs/prd/0007-zsh-activation-migration.md](prd/0007-zsh-activation-migration.md)
- **Architecture:** [docs/architecture/0007-zsh-activation-migration-architecture.md](architecture/0007-zsh-activation-migration-architecture.md)
- **Decisions:** ADR-0021 (include block + `index.zsh`), ADR-0022 (Model 4 → 3), ADR-0023 (`local.zsh`).

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

```bash
cp stow/common/zsh/.config/zsh/shared.zsh.example stow/common/zsh/.config/zsh/shared.zsh
cp stow/common/zsh/.config/zsh/macos.zsh.example  stow/common/zsh/.config/zsh/macos.zsh   # macOS
cp stow/common/zsh/.config/zsh/arch.zsh.example   stow/common/zsh/.config/zsh/arch.zsh    # Arch
cp stow/common/zsh/.config/zsh/index.zsh.example  stow/common/zsh/.config/zsh/index.zsh
```

All copied files are git-ignored and will not be committed. Review each, replacing any
`YOUR_*` placeholders. Put machine-specific or sensitive lines in `local.zsh` (next step),
not in the tracked layers.

### Optional — create `local.zsh` for machine-specific / sensitive overrides

`local.zsh` has no `.example` and is never committed (ADR-0023). Create it only if you
have local overrides to move out of your `~/.zshrc`:

```bash
: > stow/common/zsh/.config/zsh/local.zsh   # create empty; then edit in your overrides
```

---

## Step 3 — Validate the package layout (no real `$HOME` change)

```bash
task dry-run AREA=common PACKAGE=zsh
```

If your `~/.config/zsh/` already exists, the real-home dry-run may report an ownership
conflict — that is expected, not a layout error. Confirm the package itself is well-formed
with fake-home validation:

```bash
TEST_HOME="$(mktemp -d)"
stow --dir=stow/common --target="$TEST_HOME" --simulate zsh
rm -rf "$TEST_HOME"
```

If you see a conflict on real `$HOME`, **stop** — do not use `--adopt`. Resolve it
manually (back up/move the conflicting file) before stowing.

---

## Step 4 — Stow the package

⚠️  MANUAL STEP — review dry-run output before running
```bash
stow --dir=stow/common --target="$HOME" zsh
```

This creates symlinks under `~/.config/zsh/` (including `index.zsh`). It does **not** touch
`~/.zshrc`.

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

1. **Instant disable:** delete (or comment) the delimited managed block in `~/.zshrc`,
   open a new shell. The managed layer goes inert. No data loss.

2. **Per-capability revert:** restore the relevant line in `~/.zshrc` from your backup, or
   remove the one guarded line from the managed layer file.

3. **Disable a single layer:** remove the real `omp.zsh` (drops the prompt) or one guarded
   tool line in `shared.zsh`. Guards make partial states safe.

4. **Full abort:** restore your backup, then optionally unstow and remove the copied files.

   ⚠️  MANUAL STEP — review before running
   ```bash
   cp "$HOME/.zshrc.bak.$(date +%Y%m%d)" "$HOME/.zshrc"   # restore your backup (adjust date)
   stow --dir=stow/common --target="$HOME" --delete zsh    # remove managed symlinks
   ```

   To remove the copied real files, delete them by name — **never** run a broad
   `rm -rf ~/.config/zsh`:

   ⚠️  MANUAL STEP — review before running; remove only these named files
   ```bash
   rm -f ~/.config/zsh/shared.zsh ~/.config/zsh/macos.zsh ~/.config/zsh/arch.zsh \
         ~/.config/zsh/index.zsh ~/.config/zsh/omp.zsh ~/.config/zsh/local.zsh
   ```

5. **Verify:**

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
