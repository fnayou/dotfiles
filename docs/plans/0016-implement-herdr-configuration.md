# Plan: Implement Herdr Configuration Package

**Number:** 0016
**Status:** Approved
**Date:** 2026-06-20
**PRD:** [0012-herdr-configuration](../prd/0012-herdr-configuration.md)
**Architecture:** [0012-herdr-configuration-architecture](../architecture/0012-herdr-configuration-architecture.md)

---

## Objective

Create the `stow/common/herdr/` Stow package with the real managed Herdr configuration,
update documentation, and validate the package — without running Stow against `$HOME`
or installing any dependency.

---

## Assumptions

- PRD 0012 is Approved.
- Architecture 0012 is Approved.
- Builder does not read from `~/.config/herdr/` — all config content is specified in this plan.
- Builder does not run Stow against real `$HOME`.
- Builder does not use `stow --adopt`.
- Builder does not install Herdr or any dependency.
- `stow` 2.3+ is installed and available (for fake-home validation only).

---

## Ordered Tasks

---

### Group A — Package skeleton

---

#### A1 — Create the package directory tree

Create the directory structure for the Herdr Stow package.

**Action:** Create directory `stow/common/herdr/.config/herdr/`.

Stow requires the directory tree to mirror the target path relative to `$HOME`. Since
Herdr config lands at `~/.config/herdr/config.toml`, the package tree is:

```
stow/common/herdr/
└── .config/
    └── herdr/
```

**Safety check:** No file outside the repository is created. No `$HOME` modification.

**Validation:**

```bash
ls -la stow/common/herdr/.config/herdr/
```

Expected: directory exists (may be empty before B1).

---

#### A2 — Create `.stow-local-ignore`

Create `stow/common/herdr/.stow-local-ignore` to prevent Stow from symlinking
repository metadata and backup files into `$HOME`.

**Action:** Create `stow/common/herdr/.stow-local-ignore` with this exact content:

```
^/README\.md$
^/\.git$
^/\.gitignore$
^/\.stow-local-ignore$
^.*\.bak$
^.*\.orig$
```

This matches the pattern used in `stow/common/alacritty/.stow-local-ignore`.

**Safety check:** No `$HOME` modification. Repository file only.

**Validation:**

```bash
cat stow/common/herdr/.stow-local-ignore
```

Expected: six lines, matching the pattern above.

---

### Group B — Config file

---

#### B1 — Create `config.toml`

Create the managed Herdr configuration file.

**Action:** Create `stow/common/herdr/.config/herdr/config.toml` with this exact content:

```toml
onboarding = false

[theme]
# Built-in base: catppuccin (closest to Macchiato palette)
name = "catppuccin"

# Catppuccin Macchiato color overrides
[theme.custom]
panel_bg = "#24273a"   # Base
accent    = "#8aadf4"  # Blue
green     = "#a6da95"  # Green
red       = "#ed8796"  # Red
yellow    = "#eed49f"  # Yellow

[terminal]
default_shell = "zsh"  # Matches shell preference on both macOS and Arch
new_cwd = "follow"     # New panes inherit the working directory of the active pane

[scrollback]
history = 20000        # Deep buffer for extensive AI generation and terminal logs

[ui]
show_agent_labels_on_pane_borders = true

[ui.sidebar]
initial_split_width = 25

[ui.toast]
delivery = "herdr"     # Herdr-internal toast UI (not OS notification system)
```

Note: `delivery = "herdr"` is the corrected value per Architecture Decision 1. The
original live config had `delivery = "system"` which tied notifications to the macOS
Alert system. The managed file uses `delivery = "herdr"` for cross-platform
Herdr-internal toast delivery.

**Safety check:** No `$HOME` modification. No secrets — values are UI preferences
and Catppuccin hex color codes only.

**Validation:**

```bash
ls -la stow/common/herdr/.config/herdr/config.toml
```

Expected: file exists, non-zero size.

---

### Group C — Documentation updates

---

#### C1 — Update `docs/stow-usage.md` layout tree

Add `herdr/` to the package tree under `stow/common/`. Add it in alphabetical order
between `git/` and `zsh/`.

**Action:** In `docs/stow-usage.md`, replace the layout tree block:

Before:
```
stow/
├── common/          # Config that works on both macOS and Arch without modification
│   ├── alacritty/   # Alacritty terminal emulator config and Catppuccin theme
│   ├── git/         # Git config templates
│   └── zsh/         # Zsh config (shared + macOS + Arch, runtime OS detection)
├── macos/           # macOS-specific config only
└── arch/            # EndeavourOS / Arch-specific config only
```

After:
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

**Safety check:** Documentation change only. No `$HOME` modification.

**Validation:**

```bash
grep -n "herdr" docs/stow-usage.md
```

Expected: at least one match in the layout tree.

---

#### C2 — Update `docs/stow-usage.md` — add Herdr install section

Append a new install section at the end of `docs/stow-usage.md`.

**Action:** Append the following content to the end of `docs/stow-usage.md`:

```markdown
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
```

**Safety check:** Documentation change only. No `$HOME` modification.

**Validation:**

```bash
grep -n "Installing the herdr package" docs/stow-usage.md
```

Expected: one match.

---

#### C3 — Update `README.md` status block

Add `herdr` to the list of real managed dotfile packages.

**Action:** In `README.md`, find the line:

```
Real managed dotfile packages: alacritty, git, zsh
```

Replace with:

```
Real managed dotfile packages: alacritty, git, herdr, zsh
```

**Safety check:** Documentation change only. No `$HOME` modification.

**Validation:**

```bash
grep "Real managed" README.md
```

Expected: `herdr` appears in the list.

---

### Group D — Validation

Run all validation commands after Group B is complete. All commands are read-only and
safe.

---

#### D1 — TOML syntax validation

```bash
python3 -c "
import sys
if sys.version_info < (3, 11):
    print('SKIP: tomllib requires Python 3.11+, found ' + sys.version.split()[0])
    sys.exit(0)
import tomllib
for f in sys.argv[1:]:
    with open(f, 'rb') as fh:
        tomllib.load(fh)
    print('OK: ' + f)
" \
  stow/common/herdr/.config/herdr/config.toml
```

Expected: `OK:` for the file, or `SKIP:` on Python < 3.11. Any parse error is a
failure.

---

#### D2 — Fake-home Stow simulation (two-step)

```bash
# Step 1 — conflict check (no filesystem writes)
FAKE_HOME="$(mktemp -d)"
stow --dir=stow/common --target="$FAKE_HOME" --simulate --no-folding herdr \
  && echo "Simulation passed: no conflicts detected"
rm -rf "$FAKE_HOME"

# Step 2 — symlink verification
FAKE_HOME="$(mktemp -d)"
stow --dir=stow/common --target="$FAKE_HOME" --no-folding herdr
ls -la "$FAKE_HOME/.config/herdr/"
stow --dir=stow/common --target="$FAKE_HOME" --delete herdr
rm -rf "$FAKE_HOME"
```

Expected for Step 1: "Simulation passed: no conflicts detected".
Expected for Step 2: `config.toml` symlink visible pointing into the repository, then
clean removal.

---

#### D3 — Privacy audit

```bash
grep -rEi \
  'password|token|secret|api.?key|private.?key|BEGIN (RSA|OPENSSH|EC)|hostname\.' \
  stow/common/herdr/
```

Expected: no matches. Any match is a blocker.

---

#### D4 — Dependency and network audit

```bash
grep -rEi 'brew|pacman|curl|wget|npm|pip|cargo|apt' \
  stow/common/herdr/
```

Expected: no matches.

---

#### D5 — Pre-commit diff review

```bash
git status
git diff
```

Expected files changed:

```
new file:   stow/common/herdr/.config/herdr/config.toml
new file:   stow/common/herdr/.stow-local-ignore
modified:   README.md
modified:   docs/stow-usage.md
```

No other files should appear. If unexpected files are staged, stop and investigate
before proceeding to review.

---

## Files Affected

| File | Action |
|------|--------|
| `stow/common/herdr/.stow-local-ignore` | created |
| `stow/common/herdr/.config/herdr/config.toml` | created |
| `docs/stow-usage.md` | modified — layout tree + new install section |
| `README.md` | modified — herdr added to real managed packages list |

No files outside the repository are created or modified.

---

## Safety Checks

- [ ] Builder does not run `stow` against real `$HOME` at any point.
- [ ] Builder does not use `stow --adopt`.
- [ ] Builder does not read files from `~/.config/herdr/`.
- [ ] Builder does not install Herdr or any dependency.
- [ ] All stow install/delete commands in docs are marked `⚠️ MANUAL STEP`.
- [ ] Privacy audit (D3) returns no matches before forwarding to Reviewer.
- [ ] `delivery = "herdr"` confirmed in committed file (not `delivery = "system"`).

---

## Manual Install Reference (Document Only — Never Run by Builder)

For future use after plan is complete and Reviewer approves:

```bash
# Dry run
stow --dir=stow/common --target="$HOME" --simulate --no-folding herdr
```

⚠️  MANUAL STEP — run only after reviewing dry-run output

```bash
# Install
stow --dir=stow/common --target="$HOME" --no-folding herdr
```

---

## Rollback Strategy

All changes are repository files only. No `$HOME` modifications are made.

```bash
# Undo documentation changes
git checkout -- README.md docs/stow-usage.md

# Remove the package directory
rm -rf stow/common/herdr/
```

If files were accidentally staged:

```bash
git reset HEAD stow/common/herdr/ README.md docs/stow-usage.md
```

---

## Completion Criteria

- [ ] `stow/common/herdr/.stow-local-ignore` exists with six ignore patterns.
- [ ] `stow/common/herdr/.config/herdr/config.toml` exists with all settings from PRD 0012.
- [ ] `delivery = "herdr"` present (not `delivery = "system"`).
- [ ] All Catppuccin Macchiato color overrides present and correct.
- [ ] All inline comments preserved.
- [ ] D1 TOML validation: passes or skips gracefully on Python < 3.11.
- [ ] D2 fake-home simulation Step 1: exits 0 with "Simulation passed".
- [ ] D2 fake-home simulation Step 2: `config.toml` symlink visible, clean removal.
- [ ] D3 privacy audit: no matches.
- [ ] D4 dependency audit: no matches.
- [ ] D5 `git status` shows only the four expected files.
- [ ] `docs/stow-usage.md` lists `herdr/` in layout tree and includes install section with `⚠️ MANUAL STEP` markers.
- [ ] `README.md` lists `herdr` in real managed packages.
- [ ] Reviewer approves before commit.
