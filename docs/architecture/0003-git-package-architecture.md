# Architecture: Git Configuration Stow Package

**Number:** 0003
**Status:** Approved
**Date:** 2026-06-17
**PRD:** [0003-git-package](../prd/0003-git-package.md)
**Parent:** [0002-dotfiles-foundation-architecture](./0002-dotfiles-foundation-architecture.md)

---

## Context

Architecture 0002 established the foundation scaffold, including `stow/common/git/.gitconfig.example` as a minimal placeholder. PRD 0003 scopes the first real Git configuration package: two example files, an include-based adoption strategy, a global gitignore strategy, and complete adoption documentation.

This architecture does not redesign the scaffold. It fills in the content and adoption mechanics for the existing `stow/common/git/` slot.

Out of scope for this architecture (per PRD 0003 and ADR-0006):
- Git signing strategy (deferred, undecided).
- SSH configuration (ADR-0005, permanent non-goal).
- GitHub CLI authentication.
- Work-specific identities or `[includeIf]` conditionals.
- Any modification to the user's real `~/.gitconfig`.

---

## Proposed Structure

### Directory layout

```
stow/
└── common/
    └── git/
        ├── .gitconfig.example          # Portable common Git settings, placeholder values
        └── .gitignore_global.example   # Common global ignore patterns, no real paths
```

No `stow/macos/git/` or `stow/arch/git/` packages are needed. All settings in this package satisfy ADR-0001's three common-package criteria (see Compatibility section).

### File inventory

| File | Type | Purpose | Stowed directly? |
|------|------|---------|-----------------|
| `stow/common/git/.gitconfig.example` | Example/template | Portable common Git settings with placeholder values | No — user renames to `.gitconfig.common` locally before stowing |
| `stow/common/git/.gitignore_global.example` | Example/template | Common global ignore patterns | No — user renames to `.gitignore_global` locally before stowing |

Both files are committed to the repository. Neither is stowed as-is. The user renames or copies each file locally, then optionally stows the renamed version (ADR-0003).

---

## Include-Based Adoption Strategy

### Model

The user's real `~/.gitconfig` is never replaced or overwritten. Instead, Git's native `[include]` directive wires the managed common config into the user's existing config as an opt-in layer.

```
~/.gitconfig              ← user-owned, not tracked, contains identity + private settings
  └── [include] path = ~/.gitconfig.common    ← Stow-managed symlink (optional, when adopted)

~/.gitconfig.common       ← symlink → stow/common/git/.gitconfig.common (after rename + stow)
~/.gitignore_global       ← symlink → stow/common/git/.gitignore_global (after rename + stow)
```

### Adoption steps (user-performed, not automated)

1. Copy `.gitconfig.example` to a local working copy:

   ```bash
   cp stow/common/git/.gitconfig.example stow/common/git/.gitconfig.common
   ```

2. Review `.gitconfig.common` — no identity values should appear; placeholders only.

3. Dry-run the package:

   ```bash
   task dry-run AREA=common PACKAGE=git
   ```

   Review the output. Confirm that `.gitconfig.common` and `.gitignore_global` would be linked to `~/.gitconfig.common` and `~/.gitignore_global` respectively.

4. ⚠️  MANUAL STEP — review dry-run output before running
   ```bash
   stow --dir=stow/common --target="$HOME" git
   ```

5. Add the include line to the real `~/.gitconfig` (manually, outside the repository):

   ```ini
   [include]
       path = ~/.gitconfig.common
   ```

6. Verify the include is active:

   ```bash
   git config --list --show-origin | grep -i 'gitconfig.common'
   ```

### What goes in `.gitconfig.common` vs. stays local

| Setting category | Managed in `.gitconfig.common` | Stays in local `~/.gitconfig` |
|---|---|---|
| Editor (`core.editor`) | Yes — portable editors only (e.g., `vim`) | Override locally if needed |
| `core.autocrlf` | Yes — `input` is safe on both platforms | — |
| `core.whitespace` | Yes — `trailing-space,space-before-tab` | — |
| `pull.rebase` | Yes — `false` (explicit, safe default) | Override if preferred |
| `merge.conflictstyle` | Yes — `diff3` | — |
| `diff.colorMoved` | Yes — `default` | — |
| `color.ui` | Yes — `auto` | — |
| Aliases | Yes — portable, non-identity aliases only | — |
| `core.excludesfile` | Yes — pointer to `~/.gitignore_global` | — |
| User identity (`user.name`, `user.email`) | No — placeholder only in `.example`; never in `.gitconfig.common` | Always stays local |
| Signing (`user.signingkey`, `commit.gpgsign`, `gpg.*`) | No — deferred, ADR-0006 | Always stays local |
| Credential helpers | No — platform-specific | Stays in platform layer (`stow/macos/` or `stow/arch/`) |
| `[includeIf]` work profiles | No — PRD 0003 non-goal | Stays local |
| Machine-specific paths | No | Stays local |

### Rationale for include-based approach

- Non-destructive: the user's existing `~/.gitconfig` is untouched until they add the `[include]` line themselves.
- Reversible: removing the `[include]` line from `~/.gitconfig` fully disables the managed config.
- Additive: new settings are picked up automatically once the include is active.
- Portable: `[include]` has been supported since Git 1.7.10 (2012); present on all current macOS and Arch installations.

---

## `.gitconfig.example` Content Strategy

The committed example covers only settings that are:
- Safe on both macOS and Arch without modification.
- Not identity-sensitive.
- Not signing-related.

Placeholder values follow ADR-0003 conventions. The `[user]` block in the example uses `Your Name` and `your-email@example.com` — these values must never be replaced with real data.

The example does not include a `[user] signingkey` line. Signing configuration is explicitly deferred (ADR-0006).

Settings included in `.gitconfig.example`:

```ini
# Example only — do not stow directly.
# Copy to .gitconfig.common, verify placeholders, then stow.

[user]
    name = Your Name
    email = your-email@example.com

[core]
    editor = vim
    autocrlf = input
    whitespace = trailing-space,space-before-tab
    excludesfile = ~/.gitignore_global

[pull]
    rebase = false

[merge]
    conflictstyle = diff3

[diff]
    colorMoved = default

[color]
    ui = auto

[alias]
    st = status
    co = checkout
    br = branch
    lg = log --oneline --graph --decorate --all
```

No `[credential]` block. No `[gpg]` block. No `[commit]` signing block.

---

## Global Gitignore Strategy

### Model

`.gitignore_global.example` is committed as a safe reference. The user copies it to `stow/common/git/.gitignore_global` locally, then stows it (creating `~/.gitignore_global`). The `core.excludesfile = ~/.gitignore_global` pointer in `.gitconfig.common` activates it.

The real global gitignore is never committed to this repository.

### Patterns in `.gitignore_global.example`

- **macOS artifacts:** `.DS_Store`, `.AppleDouble`, `.LSOverride`, `._*`
- **Linux desktop artifacts:** `.Trash-*`, `lost+found`
- **Editor artifacts:** `.idea/`, `.vscode/`, `*.swp`, `*.swo`, `*~`, `*.orig`
- **Compiled / build artifacts:** `*.pyc`, `__pycache__/`, `*.class`, `*.o`, `*.out`
- **Thumbnail caches:** `Thumbs.db`, `ehthumbs.db`
- **Environment files (generic):** `.env.local`, `.env.*.local`

Not included: project-specific patterns (belong in project-level `.gitignore`), language toolchain patterns beyond the above.

### Adoption steps (user-performed)

1. Copy the example locally:

   ```bash
   cp stow/common/git/.gitignore_global.example stow/common/git/.gitignore_global
   ```

2. Review and add any personal patterns.

3. Dry-run:

   ```bash
   task dry-run AREA=common PACKAGE=git
   ```

4. ⚠️  MANUAL STEP — review dry-run output before running
   ```bash
   stow --dir=stow/common --target="$HOME" git
   ```

5. Verify Git sees it:

   ```bash
   git config --global core.excludesfile
   ```

---

## GNU Stow Layout and Mapping

### How Stow maps files into `$HOME`

Stow mirrors the directory tree under the package root into `$HOME`. For `stow/common/git/`:

| Repository path | Symlink created at |
|---|---|
| `stow/common/git/.gitconfig.common` | `~/.gitconfig.common` |
| `stow/common/git/.gitignore_global` | `~/.gitignore_global` |

The `.example` files are not stowed. Only the user-renamed copies (without `.example` suffix) are stowed. This is enforced by ADR-0003: `.example` files are never stowed directly.

### Commands

Dry-run (safe, always first):

```bash
task dry-run AREA=common PACKAGE=git
```

Or directly:

```bash
stow --dir=stow/common --target="$HOME" --simulate git
```

⚠️  MANUAL STEP — review dry-run output before running
```bash
stow --dir=stow/common --target="$HOME" git
```

### Platform directory status

`stow/macos/` and `stow/arch/` currently contain `.gitkeep` only. No Git packages added to platform layers in this scope. Credential helpers (future) would go in `stow/macos/git/` or `stow/arch/git/` under a separate PRD.

---

## macOS and Arch Compatibility

### Per-setting analysis

| Setting | macOS | Arch | Verdict |
|---|---|---|---|
| `core.editor = vim` | vim present (system or Homebrew) | vim present (pacman) | Safe — user can override |
| `core.autocrlf = input` | Correct for LF-native repos | Correct | Safe |
| `core.whitespace` | Supported | Supported | Safe |
| `core.excludesfile = ~/.gitignore_global` | Supported | Supported | Safe |
| `pull.rebase = false` | Supported | Supported | Safe |
| `merge.conflictstyle = diff3` | Supported (Git 2.3+) | Supported | Safe |
| `diff.colorMoved = default` | Supported (Git 2.17+) | Supported | Safe |
| `color.ui = auto` | Supported | Supported | Safe |
| Aliases | Portable | Portable | Safe |
| `[include]` directive | Supported (Git 1.7.10+) | Supported | Safe |

No macOS-only tools (e.g., `osxkeychain`) appear in the common config. No Arch-only tools appear. Package satisfies all three ADR-0001 common-package criteria:

1. Config file path (`~/.gitconfig.common`, `~/.gitignore_global`) is identical on both platforms.
2. Config values work unmodified on both platforms.
3. No platform-specific tool or behavior is referenced.

### XDG status (ADR-0004)

Git does not natively respect `$XDG_CONFIG_HOME` for `~/.gitconfig` on macOS reliably. This package targets `~/.gitconfig.common` and `~/.gitignore_global` — conventional `$HOME`-relative paths that work on both platforms. XDG path for Git config is not used.

---

## Validation Strategy

### Before stowing

```bash
# 1. Verify package structure
ls -la stow/common/git/

# 2. Confirm no sensitive values in .gitconfig.common
grep -i 'signingkey\|gpg\|osxkeychain\|token\|password' stow/common/git/.gitconfig.common

# 3. Dry-run
task dry-run AREA=common PACKAGE=git
```

### After stowing

```bash
# 4. Verify symlinks exist
ls -la ~/.gitconfig.common ~/.gitignore_global

# 5. Verify Git resolves the include
git config --list --show-origin | head -30

# 6. Confirm excludesfile is active
git config --global core.excludesfile

# 7. Verify identity is NOT coming from .gitconfig.common
git config --show-origin user.name
git config --show-origin user.email
# Both should point to ~/.gitconfig, not ~/.gitconfig.common
```

### Conflict resolution

If Stow reports a conflict on `~/.gitconfig.common` or `~/.gitignore_global`:

1. Stop. Do not use `--adopt`.
2. Inspect the existing file at the conflict path.
3. Decide whether to back it up, remove it, or skip stowing.
4. Re-run dry-run.
5. Proceed only after dry-run is clean.

---

## Design Decisions

### Decision 1: Include-based strategy, not direct `~/.gitconfig` replacement

**Option A:** Stow `.gitconfig` directly to `~/.gitconfig`, replacing the existing file.
- Pro: simpler — one file manages everything.
- Con: overwrites the user's existing Git identity, signing setup, and machine-specific settings. Irreversible without backup.
- Con: violates ADR-0006 (templates only) and PRD 0003 safety requirements.

**Option B:** Stow `.gitconfig.common` as a separate file; user adds `[include]` to their real `~/.gitconfig`.
- Pro: fully non-destructive — existing `~/.gitconfig` is untouched.
- Pro: reversible — remove the `[include]` line to disable.
- Pro: clean separation between portable settings (managed) and identity/private settings (local).
- Con: one additional manual step.

**Decision: Option B.**

---

### Decision 2: Two example files, not one

**Option A:** Single `.gitconfig.example` covering both Git settings and gitignore pointer.
- Con: gitignore is a separate concern with different adoption steps and different file path.

**Option B:** Two separate example files: `.gitconfig.example` and `.gitignore_global.example`.
- Pro: single responsibility per file; user can adopt one without the other.

**Decision: Option B.**

---

### Decision 3: `.gitconfig.common` as the stowed filename

**Option A:** Rename example to `.gitconfig` — stows as `~/.gitconfig`.
- Con: conflicts with any existing `~/.gitconfig`; Stow would refuse or `--adopt` would overwrite.

**Option B:** Use `.gitconfig.common` — stows as `~/.gitconfig.common`; user's real `~/.gitconfig` includes it.
- Pro: zero conflict risk with existing `~/.gitconfig`.

**Decision: Option B.**

---

### Decision 4: No credential helpers in the common package

Credential helpers are platform-specific by nature. They belong in `stow/macos/git/` or `stow/arch/git/` under a separate PRD. The common package stays portable.

---

### Decision 5: `pull.rebase = false` as the explicit common default

Git 2.27+ warns about missing `pull.rebase` on every `git pull`. Setting it explicitly to `false` silences the warning, is safe on both platforms, and is easily overridden locally.

---

## Risks and Mitigations

| Risk | Likelihood | Severity | Mitigation |
|---|---:|---:|---|
| User stows `.example` file directly | Low | Low | `.example` suffix signals intent; dry-run shows filename; documented in adoption steps |
| User adds `[include]` before stowing (missing file) | Low | Low | Git silently ignores includes for missing files; no error; stowing later activates it |
| `.gitconfig.common` committed with real identity values | Low | High | ADR-0003 checklist; CI secret scan (ADR-0008); Reviewer pre-commit checklist |
| `.gitconfig.common` committed with signing config | Low | High | ADR-0006; explicit no-signingkey rule; CI secret scan |
| Stow conflict on `~/.gitconfig.common` | Medium | Medium | Dry-run catches it; conflict resolution documented; `--adopt` forbidden |
| Stow conflict on `~/.gitignore_global` | Medium | Medium | Same as above |
| Platform-specific setting in common config | Low | Medium | ADR-0001 criteria enforced at Reviewer stage |
| `diff.colorMoved` unsupported on old Git | Very Low | Low | Supported since Git 2.17 (2018); universal on current macOS/Arch |
| User populates and commits `.gitconfig.common` with real identity | Low | High | `.gitconfig.common` and `.gitignore_global` added to `.gitignore` (see below) |

### Required `.gitignore` addition

To prevent accidental commit of populated local files, the repository `.gitignore` must include:

```
stow/common/git/.gitconfig.common
stow/common/git/.gitignore_global
```

This ensures only the `.example` versions are tracked.

---

## Extensibility

- **Platform credential helpers:** add `stow/macos/git/` or `stow/arch/git/` under a separate PRD; common package unaffected.
- **Work identity:** `[includeIf]` blocks go in the user's local `~/.gitconfig` — not in the managed package.
- **Signing configuration:** when strategy is decided, add to local `~/.gitconfig` or a separate managed file; this package unchanged.
- **New aliases or settings:** add to `.gitconfig.example`; users who adopted the package pull them in after re-stow.
- **Additional gitignore patterns:** add to `.gitignore_global.example`; users re-copy locally to get updates.

---

## ADRs to Create

| Number | Title | Status |
|---|---|---|
| ADR-0013 | Include-based Git config strategy — `.gitconfig.common` as managed layer | Proposed |
| ADR-0014 | `.gitconfig.common` filename chosen over `.gitconfig` to avoid home directory conflict | Proposed |
| ADR-0015 | Git credential helpers deferred to platform-specific packages | Proposed |

---

## Open Questions

None blocking. All PRD 0003 safety and scope requirements are addressed. Signing strategy remains deferred per ADR-0006.

---

## Recommended Next Step

Planner converts this architecture into an ordered implementation plan under `docs/plans/0003-git-package-plan.md`. Plan must include:

1. Write ADR-0013, ADR-0014, ADR-0015.
2. Update `stow/common/git/.gitconfig.example` with the full content defined here.
3. Create `stow/common/git/.gitignore_global.example` with the pattern categories defined here.
4. Add `.gitconfig.common` and `.gitignore_global` to the repository `.gitignore`.
5. Produce adoption documentation.
6. Per-task validation commands and Reviewer pre-commit checklist.
