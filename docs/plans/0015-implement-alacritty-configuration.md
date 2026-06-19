# Plan: Implement Alacritty Configuration Package

**Number:** 0015
**Status:** Complete
**Date:** 2026-06-19
**PRD:** [0011-alacritty-configuration](../prd/0011-alacritty-configuration.md)
**Architecture:** [0011-alacritty-configuration-architecture](../architecture/0011-alacritty-configuration-architecture.md)
**Review:** [0039-alacritty-prd-architecture-review](../reviews/0039-alacritty-prd-architecture-review.md)

---

## Objective

Create the `stow/common/alacritty/` Stow package with the real managed Alacritty
configuration and Catppuccin Macchiato theme, update documentation, and validate the
package — without running Stow against `$HOME` or installing any dependency.

---

## Assumptions

- PRD 0011 is Approved.
- Architecture 0011 is Approved.
- Review 0039 findings N1–N4 are already applied to the architecture document (confirmed).
- `stow` 2.3+ is installed and available.
- Builder does not read from `~/.config/alacritty/` — all config content is specified
  in this plan.
- Builder does not run Stow against real `$HOME`.
- Builder does not use `stow --adopt`.
- Builder does not install Alacritty, fonts, or any dependency.

---

## Ordered Tasks

---

### Group A — Package skeleton

---

#### A1 — Create the package directory tree

Create the directory structure for the Alacritty Stow package.

**Action:** Create directory `stow/common/alacritty/.config/alacritty/`.

Stow requires the directory tree to mirror the target path relative to `$HOME`. Since
Alacritty config lands at `~/.config/alacritty/`, the package tree is:

```
stow/common/alacritty/
└── .config/
    └── alacritty/
```

**Safety check:** No file outside the repository is created. No `$HOME` modification.

**Validation:**

```bash
ls -la stow/common/alacritty/.config/alacritty/
```

Expected: directory exists (may be empty before B1/B2).

---

#### A2 — Create `.stow-local-ignore`

Create `stow/common/alacritty/.stow-local-ignore` to prevent Stow from symlinking
repository metadata and backup files into `$HOME`.

**Action:** Create `stow/common/alacritty/.stow-local-ignore` with this exact content:

```
^/README\.md$
^/\.git$
^/\.gitignore$
^/\.stow-local-ignore$
^.*\.bak$
^.*\.orig$
```

This matches the pattern used in `stow/common/omp/.stow-local-ignore` (the `zsh`
package adds a `local.zsh` entry — Alacritty has no local override slot, so that
line is omitted).

**Safety check:** No `$HOME` modification. Repository file only.

**Validation:**

```bash
cat stow/common/alacritty/.stow-local-ignore
```

Expected: six lines, matching the pattern above.

---

### Group B — Config files

---

#### B1 — Create `alacritty.toml`

Create the main managed Alacritty configuration file.

**Action:** Create `stow/common/alacritty/.config/alacritty/alacritty.toml` with this
exact content:

```toml
import = [
  "~/.config/alacritty/catppuccin-macchiato.toml"
]

[env]
TERM = "xterm-256color"

[window]
padding = { x = 8, y = 8 }
dynamic_padding = true
opacity = 0.98
startup_mode = "Windowed"
option_as_alt = "Both"

[font]
size = 13.0

[font.normal]
family = "JetBrainsMono Nerd Font"

[terminal.shell]
program = "/bin/zsh"
args = ["-l"]

[[keyboard.bindings]]
key = "NumpadEnter"
chars = "\r"

[[keyboard.bindings]]
key = "Numpad0"
chars = "0"

[[keyboard.bindings]]
key = "Numpad1"
chars = "1"

[[keyboard.bindings]]
key = "Numpad2"
chars = "2"

[[keyboard.bindings]]
key = "Numpad3"
chars = "3"

[[keyboard.bindings]]
key = "Numpad4"
chars = "4"

[[keyboard.bindings]]
key = "Numpad5"
chars = "5"

[[keyboard.bindings]]
key = "Numpad6"
chars = "6"

[[keyboard.bindings]]
key = "Numpad7"
chars = "7"

[[keyboard.bindings]]
key = "Numpad8"
chars = "8"

[[keyboard.bindings]]
key = "Numpad9"
chars = "9"
```

> **Note on numpad bindings:** The user confirmed numpad key bindings exist in their
> real config but did not provide exact values. The bindings above are standard
> escape-sequence pass-throughs (numerals and Enter). Builder must flag these for
> user review before commit — the user should confirm these match their real bindings
> or provide corrections.

**Portability notes (per Architecture decisions):**

- `option_as_alt = "Both"` — macOS behavior only; Linux silently ignores (Decision 5).
- `/bin/zsh` — portable via `usr-merge` on Arch/EndeavourOS (Decision 6).
- Import path uses `~` expansion — resolves correctly after stowing (Decision 4).
- `JetBrainsMono Nerd Font` — silent fallback to system monospace if absent (Decision 7).

**Safety check:** No `$HOME` modification. No reading from `~/.config/alacritty/`.

**Validation:**

```bash
ls -la stow/common/alacritty/.config/alacritty/alacritty.toml
```

Expected: file exists, non-zero size.

---

#### B2 — Create `catppuccin-macchiato.toml`

Create the Catppuccin Macchiato color theme file.

**Action:** Create
`stow/common/alacritty/.config/alacritty/catppuccin-macchiato.toml` with this exact
content (official Catppuccin Macchiato palette for Alacritty):

```toml
# Catppuccin Macchiato — Alacritty color scheme

[colors.primary]
background = "#24273a"
foreground = "#cad3f5"

[colors.cursor]
text = "#24273a"
cursor = "#f4dbd6"

[colors.vi_mode_cursor]
text = "#24273a"
cursor = "#b7bdf8"

[colors.search.matches]
foreground = "#24273a"
background = "#a5adcb"

[colors.search.focused_match]
foreground = "#24273a"
background = "#a6da95"

[colors.footer_bar]
background = "#a5adcb"
foreground = "#24273a"

[colors.hints.start]
foreground = "#24273a"
background = "#eed49f"

[colors.hints.end]
foreground = "#24273a"
background = "#a5adcb"

[colors.selection]
text = "#24273a"
background = "#f4dbd6"

[colors.normal]
black   = "#494d64"
red     = "#ed8796"
green   = "#a6da95"
yellow  = "#eed49f"
blue    = "#8aadf4"
magenta = "#f5bde6"
cyan    = "#8bd5ca"
white   = "#b8c0e0"

[colors.bright]
black   = "#5b6078"
red     = "#ed8796"
green   = "#a6da95"
yellow  = "#eed49f"
blue    = "#8aadf4"
magenta = "#f5bde6"
cyan    = "#8bd5ca"
white   = "#a5adcb"

[colors.dim]
black   = "#494d64"
red     = "#ed8796"
green   = "#a6da95"
yellow  = "#eed49f"
blue    = "#8aadf4"
magenta = "#f5bde6"
cyan    = "#8bd5ca"
white   = "#b8c0e0"
```

**Safety check:** No `$HOME` modification. No secrets — these are hex color values.

**Validation:**

```bash
ls -la stow/common/alacritty/.config/alacritty/catppuccin-macchiato.toml
```

Expected: file exists, non-zero size.

---

### Group C — Documentation updates

---

#### C1 — Update `docs/stow-usage.md`

Two changes required:

**Change 1 — Layout section:** Add `alacritty/` to the package tree under
`stow/common/`. The existing tree lists `git/` and `zsh/`. Add `alacritty/` in
alphabetical order:

Before:
```
stow/
├── common/     # Config that works on both macOS and Arch without modification
│   ├── git/    # Git config templates
│   └── zsh/    # Zsh config (shared + macOS + Arch, runtime OS detection)
├── macos/      # macOS-specific config only
└── arch/       # EndeavourOS / Arch-specific config only
```

After:
```
stow/
├── common/          # Config that works on both macOS and Arch without modification
│   ├── alacritty/   # Alacritty terminal emulator config and Catppuccin theme
│   ├── git/         # Git config templates
│   └── zsh/         # Zsh config (shared + macOS + Arch, runtime OS detection)
├── macos/           # macOS-specific config only
└── arch/            # EndeavourOS / Arch-specific config only
```

**Change 2 — Add install section:** Append a new section for the Alacritty package
at the end of the file (before any existing end-of-file marker if present, otherwise
at the end). Title: `## Installing the alacritty package`.

Content to append:

```markdown
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
```

**Safety check:** Documentation change only. No `$HOME` modification.

**Validation:**

```bash
grep -n "alacritty" docs/stow-usage.md
```

Expected: alacritty appears in the layout tree and in the install section heading.

---

#### C2 — Update `README.md` status block

The README status block currently says:

```
GNU Stow scaffold:           created (placeholder/example files only)
Real managed dotfile packages: not started
Home directory:              unmodified
```

This is stale — git, zsh, and (after this plan) alacritty are real managed packages.

**Action:** Replace the status block with:

```
GNU Stow scaffold:           created
Real managed dotfile packages: alacritty, git, zsh
Home directory:              unmodified
```

Also update the paragraph below the status block that says:

> **No dotfiles have been stowed yet. No home directory has been modified.**

Replace with:

> Real managed dotfiles are version-controlled in `stow/common/`. No dotfiles have
> been stowed yet — Stow install is a deliberate manual step. No home directory has
> been modified.

**Safety check:** Documentation change only. No `$HOME` modification.

**Validation:**

```bash
grep -A4 "## Status" README.md
```

Expected: updated status block visible.

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
  stow/common/alacritty/.config/alacritty/alacritty.toml \
  stow/common/alacritty/.config/alacritty/catppuccin-macchiato.toml
```

Expected: `OK:` for each file, or `SKIP:` on Python < 3.11. Any `ModuleNotFoundError`
or parse error is a failure.

---

#### D2 — Fake-home Stow simulation (two-step)

```bash
# Step 1 — conflict check (no filesystem writes)
FAKE_HOME="$(mktemp -d)"
stow --dir=stow/common --target="$FAKE_HOME" --simulate --no-folding alacritty \
  && echo "Simulation passed: no conflicts detected"
rm -rf "$FAKE_HOME"

# Step 2 — symlink verification
FAKE_HOME="$(mktemp -d)"
stow --dir=stow/common --target="$FAKE_HOME" --no-folding alacritty
ls -la "$FAKE_HOME/.config/alacritty/"
stow --dir=stow/common --target="$FAKE_HOME" --delete alacritty
rm -rf "$FAKE_HOME"
```

Expected for Step 1: "Simulation passed: no conflicts detected".
Expected for Step 2: two symlinks (`alacritty.toml` and `catppuccin-macchiato.toml`)
pointing into the repository, then clean removal.

---

#### D3 — Privacy audit

```bash
grep -rEi \
  'password|token|secret|api.?key|private.?key|BEGIN (RSA|OPENSSH|EC)|hostname\.' \
  stow/common/alacritty/
```

Expected: no matches. Any match is a blocker.

---

#### D4 — Dependency and network audit

```bash
grep -rEi 'brew|pacman|curl|wget|npm|pip|cargo|apt' \
  stow/common/alacritty/
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
new file:   stow/common/alacritty/.config/alacritty/alacritty.toml
new file:   stow/common/alacritty/.config/alacritty/catppuccin-macchiato.toml
new file:   stow/common/alacritty/.stow-local-ignore
modified:   README.md
modified:   docs/stow-usage.md
```

No other files should appear. If unexpected files are staged, stop and investigate
before proceeding to review.

---

## Files Affected

| File | Action |
|------|--------|
| `stow/common/alacritty/.stow-local-ignore` | created |
| `stow/common/alacritty/.config/alacritty/alacritty.toml` | created |
| `stow/common/alacritty/.config/alacritty/catppuccin-macchiato.toml` | created |
| `docs/stow-usage.md` | modified — layout tree + new install section |
| `README.md` | modified — status block updated |

No files outside the repository are created or modified.

---

## Safety Checks

- [ ] Builder does not run `stow` against real `$HOME` at any point.
- [ ] Builder does not use `stow --adopt`.
- [ ] Builder does not read files from `~/.config/alacritty/`.
- [ ] Builder does not install Alacritty, fonts, or any other dependency.
- [ ] All stow install/delete commands in docs are marked `⚠️ MANUAL STEP`.
- [ ] Privacy audit (D3) returns no matches before forwarding to Reviewer.
- [ ] Builder flags the numpad bindings (B1 note) to the user before review.

---

## Manual Install Reference (Document Only — Never Run by Builder)

For future use after plan is complete and Reviewer approves:

```bash
# Dry run
stow --dir=stow/common --target="$HOME" --simulate --no-folding alacritty
```

⚠️  MANUAL STEP — run only after reviewing dry-run output

```bash
# Install
stow --dir=stow/common --target="$HOME" --no-folding alacritty
```

---

## Rollback Strategy

All changes are repository files only. No `$HOME` modifications are made.

```bash
# Undo documentation changes
git checkout -- README.md docs/stow-usage.md

# Remove the package directory
rm -rf stow/common/alacritty/
```

If files were accidentally staged:

```bash
git reset HEAD stow/common/alacritty/ README.md docs/stow-usage.md
```

---

## Completion Criteria

- [ ] `stow/common/alacritty/.stow-local-ignore` exists with six ignore patterns.
- [ ] `stow/common/alacritty/.config/alacritty/alacritty.toml` exists with all
  settings from PRD 0011.
- [ ] `stow/common/alacritty/.config/alacritty/catppuccin-macchiato.toml` exists with
  Catppuccin Macchiato color values.
- [ ] Numpad bindings flagged to user and confirmed or corrected before commit.
- [ ] D1 TOML validation: passes or skips gracefully on Python < 3.11.
- [ ] D2 fake-home simulation Step 1: exits 0 with "Simulation passed".
- [ ] D2 fake-home simulation Step 2: two symlinks visible, clean removal.
- [ ] D3 privacy audit: no matches.
- [ ] D4 dependency audit: no matches.
- [ ] D5 `git status` shows only the five expected files.
- [ ] `docs/stow-usage.md` lists `alacritty/` in layout tree and includes install
  section with `⚠️ MANUAL STEP` markers.
- [ ] `README.md` status block lists `alacritty, git, zsh` as real managed packages.
- [ ] Reviewer approves before commit.
