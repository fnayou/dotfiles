# Git Package Setup Guide

This guide explains how to set up the managed Git configuration on a new machine. It is written for a human user, not for implementation agents.

---

## 1. What this package manages

The `stow/common/git/` package manages three files, stowed into `~/.config/git/`:

| Repository file | Symlink created at | Purpose |
|---|---|---|
| `stow/common/git/.config/git/config-common` | `~/.config/git/config-common` | Portable Git settings — editor, colors, pull strategy, merge conflict style, diff options |
| `stow/common/git/.config/git/aliases` | `~/.config/git/aliases` | Git aliases — shorthand commands for common operations |
| `stow/common/git/.config/git/ignore` | `~/.config/git/ignore` | Global ignore patterns — macOS artifacts, editor files, archive formats, logs |

---

## 2. What this package does NOT manage

- **`~/.gitconfig` remains unmanaged.** This package never stows, symlinks, or overwrites `~/.gitconfig`. Your existing `~/.gitconfig` content is fully preserved.
- **`~/.gitconfig` is not symlinked** by this package. Stow only creates three symlinks under `~/.config/git/`.
- **`user.name`, `user.email`, signing keys, and credentials** are not managed by this repository. You configure identity directly in `~/.gitconfig` via `git config --global`.
- **`[includeIf]` blocks and work-specific configuration** are not managed. These go directly in your `~/.gitconfig`.

After setup, the managed files are wired into `~/.gitconfig` via `[include] path = ...` entries. See the activation steps below.

---

## 3. Prerequisites

The following tools must be installed before you begin:

- `git` — the version control tool (must be at least 2.x for `include` support)
- `stow` — GNU Stow, the symlink manager
- `task` — go-task runner

Verify all three are present:

```bash
task check
```

---

## 4. Dry-run step

Always dry-run the Stow package before applying it. This shows exactly what symlinks would be created without making any changes.

```bash
task dry-run AREA=common PACKAGE=git
```

Or directly:

```bash
stow --dir=stow/common --target="$HOME" --simulate git
```

**What to look for:** Three `LINK:` lines, one for each managed file:

```
LINK: .config/git/config-common => <repo>/stow/common/git/.config/git/config-common
LINK: .config/git/aliases => <repo>/stow/common/git/.config/git/aliases
LINK: .config/git/ignore => <repo>/stow/common/git/.config/git/ignore
```

No conflict lines. Exit code 0.

**If you see a conflict:** A real file already exists at the target path. Do NOT use `stow --adopt`. See the Troubleshooting section below.

---

## 5. Apply step (Stow)

After reviewing the dry-run output and confirming no conflicts, apply the Stow package:

⚠️  MANUAL STEP — review dry-run output before running
```bash
stow --dir=stow/common --target="$HOME" git
```

**`stow --adopt` is forbidden.** The `--adopt` flag silently overwrites files in `$HOME` with the repository version, destroying your existing content without a backup. It must never be used. If a conflict exists, resolve it manually — see the Troubleshooting section.

---

## 6. Manual activation steps

Stow creates symlinks in `~/.config/git/`. It does NOT modify `~/.gitconfig`. You must wire the managed files into your `~/.gitconfig` and configure your identity separately.

### a. Preview bootstrap (read-only, no changes)

Run this first to see what the bootstrap task would add to `~/.gitconfig`:

```bash
task git:bootstrap:dry-run
```

Expected output (before bootstrap has run):

```
git:bootstrap dry-run — no changes will be made
=================================================

~/.gitconfig exists: yes

Current include.path values:
  (none)

Required entries:
  would add:       include.path = ~/.config/git/config-common
  would add:       include.path = ~/.config/git/aliases

Backup: yes — a timestamped backup would be created before any change
```

### b. Apply bootstrap

After reviewing the dry-run output, wire the includes into `~/.gitconfig`:

⚠️  MANUAL STEP — review dry-run output before running
```bash
task git:bootstrap
```

This adds two `[include] path = ...` entries to `~/.gitconfig`. Before making any change, it creates a timestamped backup of your existing `~/.gitconfig`:

```
Backup created: ~/.gitconfig.bak.20260618120000
```

Your existing `~/.gitconfig` content is fully preserved. The bootstrap task only appends; it never removes or overwrites existing content.

Running `task git:bootstrap` a second time is safe — it detects that the entries are already present and skips them.

### c. Configure identity

Your Git identity must be set directly in `~/.gitconfig`. This is never managed by this repository.

⚠️  MANUAL STEP — replace placeholder values with your own
```bash
git config --global user.name "Your Name"
git config --global user.email "your-email@example.com"
```

This writes to `~/.gitconfig` directly, which is correct. Identity values (name, email, signing keys) belong in `~/.gitconfig`, not in the managed files in this repository.

---

## 7. Validation steps

After completing all setup steps, verify the installation:

```bash
# Confirm three symlinks exist in ~/.config/git/
ls -la ~/.config/git/
```

Expected: `config-common`, `aliases`, and `ignore` all shown as symlinks.

```bash
# Confirm each symlink resolves into the repository
readlink ~/.config/git/config-common
readlink ~/.config/git/aliases
readlink ~/.config/git/ignore
```

```bash
# Confirm both include.path entries are wired
git config --global --get-all include.path
```

Expected output:
```
~/.config/git/config-common
~/.config/git/aliases
```

```bash
# Confirm excludesfile is active
git config --global core.excludesfile
```

Expected: `~/.config/git/ignore`

```bash
# Confirm no duplicate include.path entries
git config --global --get-all include.path | sort | uniq -d
```

Expected: no output (empty — no duplicates).

```bash
# Confirm identity is attributed to ~/.gitconfig (not managed files)
git config --show-origin user.name
git config --show-origin user.email
```

Expected: both lines show `file:~/.gitconfig` — never `~/.config/git/config-common` or `~/.config/git/aliases`.

---

## 8. Rollback steps

To undo the setup, reverse the steps in order:

### Undo bootstrap

Remove or comment out the two `[include]` entries that `task git:bootstrap` added to `~/.gitconfig`:

```gitconfig
[include]
    path = ~/.config/git/config-common

[include]
    path = ~/.config/git/aliases
```

Or restore from the timestamped backup created during bootstrap (replace `TIMESTAMP` with the actual value printed when you ran `task git:bootstrap`):

```bash
cp ~/.gitconfig.bak.TIMESTAMP ~/.gitconfig
```

Git immediately uses only the remaining `~/.gitconfig` settings. The managed files remain as symlinks but are not applied.

### Undo Stow

⚠️  MANUAL STEP — review before running
```bash
stow --dir=stow/common --target="$HOME" --delete git
```

This removes the three symlinks from `~/.config/git/`. Your `~/.gitconfig` is not affected.

---

## 9. Troubleshooting

### Stow conflict: real file exists at target

Symptom: Stow dry-run reports a conflict such as:

```
WARNING! stowing git would cause conflicts:
  * existing target is not owned by stow: .config/git/config-common
All operations aborted.
```

Resolution:
1. Identify the conflicting file: `ls -la ~/.config/git/config-common`
2. If it is a file you want to keep, move it out of the way: `mv ~/.config/git/config-common ~/.config/git/config-common.bak`
3. Re-run the dry-run to confirm the conflict is gone.
4. Then run the Stow apply step.

Do NOT use `stow --adopt` — it would silently overwrite your existing file with the repository version without any backup.

### Stow conflict: directory not owned by Stow

Symptom:

```
WARNING! stowing git would cause conflicts:
  * existing target is not owned by stow: .config/git
All operations aborted.
```

Resolution:
1. Check what is in `~/.config/git/`: `ls -la ~/.config/git/`
2. Back up the directory: `cp -r ~/.config/git/ ~/.config/git.bak`
3. Remove the directory: `rm -rf ~/.config/git/`
4. Re-run the dry-run to confirm no conflict.
5. Then run the Stow apply step.

### Bootstrap duplicate entries

Symptom: `git config --global --get-all include.path | sort | uniq -d` shows a duplicate.

Resolution:
1. Open `~/.gitconfig` in an editor.
2. Remove the duplicate `[include]` entry manually.
3. Run `task git:bootstrap` again — it will skip entries that are already present.
4. Re-run the duplicate check to confirm it is clean.

### Identity not set

Symptom: `git config --show-origin user.name` produces no output.

Resolution: Run the identity configuration step from Section 6c above, replacing placeholders with your real values.

---

## 10. Expected final file layout

After successful setup, your files should look like this:

```
~/.config/git/
  config-common  ->  /path/to/dotfiles/stow/common/git/.config/git/config-common
  aliases        ->  /path/to/dotfiles/stow/common/git/.config/git/aliases
  ignore         ->  /path/to/dotfiles/stow/common/git/.config/git/ignore
```

Your `~/.gitconfig` (the portions relevant to this setup — use placeholder values as shown):

```gitconfig
[user]
    name = Your Name
    email = your-email@example.com

[include]
    path = ~/.config/git/config-common

[include]
    path = ~/.config/git/aliases
```

The `core.excludesfile = ~/.config/git/ignore` entry is set inside `config-common` — no separate include is needed for the ignore file.

`~/.gitconfig` remains under your direct control. This repository never stows it, symlinks it, or writes to it except through the explicit `task git:bootstrap` command you run manually.
