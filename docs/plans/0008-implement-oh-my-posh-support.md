# Plan: Implement Oh My Posh Support

**Number:** 0008
**Status:** Complete
**Date:** 2026-06-17
**PRD:** 0005
**Architecture:** 0005
**Review:** 0013

---

## Objective

Scaffold the Oh My Posh Stow package and zsh activation snippet template — template files
and documentation only, no installation, no activation, no `$HOME` changes.

---

## Assumptions

- `stow/common/zsh/.config/zsh/` exists and is correctly structured (zsh plan 0007 complete).
- `stow/common/zsh/.config/zsh/.gitignore` exists and currently ignores `shared.zsh`,
  `macos.zsh`, `arch.zsh` — it will gain one new entry (`omp.zsh`).
- `stow/common/omp/` does not exist yet — this plan creates it.
- `docs/stow-usage.md` exists with git and zsh adoption sections — this plan adds an OMP
  section.
- No real `~/.config/omp/omp.toml` is read, copied, or referenced at any point.
- No stow install commands are run — only `--simulate` is permissible, and only as
  reference documentation in `docs/stow-usage.md`.

---

## Open Question — Resolved

Architecture left open whether `omp.zsh.example` should include an inner guard
(`command -v oh-my-posh` + config file check) in addition to the outer file-existence
guard in `shared.zsh`.

**Decision for this plan: include the guarded form as the recommended pattern inside
`omp.zsh.example`, fully commented.**

Rationale: the template is both a reference and a starting point. A guarded eval line is
defensive by default — if the user uncomments it, their shell startup does not break on a
machine where OMP is installed but `omp.toml` is not yet stowed, or vice versa. The user
can simplify later if they prefer. This is consistent with the incremental adoption
principle.

The guarded form to document in `omp.zsh.example`:

```zsh
[[ -x "$(command -v oh-my-posh)" ]] && \
  [[ -f "$HOME/.config/omp/omp.toml" ]] && \
  eval "$(oh-my-posh init zsh --config "$HOME/.config/omp/omp.toml")"
```

---

## Ordered Tasks

### Task 1 — Create the `stow/common/omp/` package scaffold

Create the directory tree and `.gitignore` for the new OMP Stow package.

**Files to create:**

- `stow/common/omp/.config/omp/.gitignore`

**Content:**

```gitignore
# Ignore the real OMP config (local copy of the .example file — never committed).
omp.toml
```

**Safety gate:** verify `~/.config/omp/` is NOT created — only the repository-internal
path `stow/common/omp/.config/omp/` is created.

**Validation:**

```bash
ls stow/common/omp/.config/omp/
# Expected: .gitignore only — no omp.toml, no symlinks
```

---

### Task 2 — Create `omp.toml.example` (minimal starter theme)

Create the Oh My Posh config template. Must be a minimal, valid TOML theme with no
personal identifiers: no hostname, no username, no machine-specific paths, no personal
color preferences.

**Files to create:**

- `stow/common/omp/.config/omp/omp.toml.example`

**Content requirements:**

- Valid Oh My Posh TOML (v2 schema).
- One `prompt`-type block with left alignment.
- Two segments: `path` (current directory) and `text` (prompt character `❯`).
- Plain style — no nerd font glyphs in the starter (user adds glyphs when customizing).
- No username, no hostname, no git status segment (keeps scope minimal and avoids
  any identity-related fields).
- Header comment explaining the file's purpose and that the user should customize it.

Approximate shape (Builder uses this as a reference — exact TOML field names must be
verified against the current Oh My Posh schema):

```toml
# Oh My Posh configuration template
# Copy this file to omp.toml, customize, then stow the omp package.
# See docs/stow-usage.md for adoption steps.
#
# Full schema reference: https://ohmyposh.dev/docs/configuration/overview

"$schema" = "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/schema.json"
version = 2
final_space = true

[[blocks]]
  type = "prompt"
  alignment = "left"

  [[blocks.segments]]
    type = "path"
    style = "plain"
    foreground = "cyan"
    template = "{{ .Path }} "

  [[blocks.segments]]
    type = "text"
    style = "plain"
    foreground = "white"
    template = "❯ "
```

**Privacy audit before completing this task:**

- [ ] No username present.
- [ ] No hostname present.
- [ ] No absolute paths present.
- [ ] No API keys or tokens present.
- [ ] No personal color scheme or named theme that could identify the user.

**Validation:**

```bash
cat stow/common/omp/.config/omp/omp.toml.example
# Verify: no personal data, activation line absent, valid TOML structure visible
```

---

### Task 3 — Create `omp.zsh.example` (fully commented activation snippet)

Create the zsh activation snippet template in the existing zsh Stow package. The entire
activation content must be commented out so the file is inert if accidentally sourced.

**Files to create:**

- `stow/common/zsh/.config/zsh/omp.zsh.example`

**Content:**

```zsh
# Oh My Posh — prompt engine activation snippet
#
# This file is a template. To activate Oh My Posh:
#   1. Copy this file to omp.zsh (git-ignored, never committed):
#        cp stow/common/zsh/.config/zsh/omp.zsh.example \
#           stow/common/zsh/.config/zsh/omp.zsh
#   2. Uncomment the eval block below.
#   3. Add the guard source call to ~/.config/zsh/shared.zsh or ~/.zshrc:
#        [[ -f "$HOME/.config/zsh/omp.zsh" ]] && source "$HOME/.config/zsh/omp.zsh"
#   4. Stow (or re-stow) the zsh package to create the symlink:
#        stow --dir=stow/common --target="$HOME" zsh
#   5. Open a new shell to verify.
#
# Prerequisites before uncommenting:
#   - Oh My Posh installed (see docs/stow-usage.md for macOS/Arch steps)
#   - stow/common/omp/ stowed — ~/.config/omp/omp.toml must exist
#   - A Nerd Font installed and selected in your terminal emulator
#
# Recommended activation (guarded — safe on machines where OMP is absent):
# [[ -x "$(command -v oh-my-posh)" ]] && \
#   [[ -f "$HOME/.config/omp/omp.toml" ]] && \
#   eval "$(oh-my-posh init zsh --config "$HOME/.config/omp/omp.toml")"
```

**Validation:**

```bash
cat stow/common/zsh/.config/zsh/omp.zsh.example
# Verify: no uncommented eval line, no uncommented source line, all content is comments

grep -v '^#' stow/common/zsh/.config/zsh/omp.zsh.example | grep -v '^$'
# Expected: no output — the file must contain only comments and blank lines
```

---

### Task 4 — Update `stow/common/zsh/.config/zsh/.gitignore`

Add `omp.zsh` to the existing zsh package `.gitignore` so the user's local copy of the
activation snippet (the real, uncommitted file) is never staged.

**Files to modify:**

- `stow/common/zsh/.config/zsh/.gitignore`

**Change:** append one line:

```gitignore
omp.zsh
```

The existing content must be preserved exactly. Final file content:

```gitignore
# Ignore real (filled-in) zsh files; keep .example templates tracked.
shared.zsh
macos.zsh
arch.zsh
omp.zsh
```

**Validation:**

```bash
cat stow/common/zsh/.config/zsh/.gitignore
# Verify: omp.zsh is present, existing entries are intact

git status
# Verify: only .gitignore shows as modified — no omp.zsh file accidentally staged
```

---

### Task 5 — Update `docs/stow-usage.md` (add OMP package adoption section)

Add an OMP package section to `docs/stow-usage.md` following the established pattern of
the git and zsh package sections. The section must document the full manual adoption
flow, resolve review finding 4 (note that `omp.toml.example` symlink is expected and
harmless), and keep macOS and Arch installation notes strictly separated.

**Files to modify:**

- `docs/stow-usage.md`

**Section to add** — append after the existing "Zsh package adoption" section:

```markdown
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

If you see a conflict on `~/.config/omp/omp.toml` (your existing real config), back it
up and remove it before proceeding. Do not use `--adopt`. See "Conflict handling" above.

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
  [[ -f "$HOME/.config/omp/omp.toml" ]] && \
  eval "$(oh-my-posh init zsh --config "$HOME/.config/omp/omp.toml")"
```

### Step 6 — Stow (or re-stow) the zsh package

Stow does not pick up newly added files automatically. Re-run stow for the zsh package
to create the `omp.zsh` symlink at `~/.config/zsh/omp.zsh`:

```bash
task dry-run AREA=common PACKAGE=zsh
```

⚠️  MANUAL STEP — review dry-run output before running
```bash
stow --dir=stow/common --target="$HOME" zsh
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
```

**Note on markdown fences:** the stow-usage.md section above contains nested code blocks.
When writing to the file, the outer markdown fence for each sub-block must be correct
triple-backtick fences (`` ``` ``) with the language specifier where shown. The Builder
must verify that no fence is accidentally closed early.

**Validation:**

```bash
grep -n 'Oh My Posh' docs/stow-usage.md
# Verify: section heading is present

grep 'omp.toml.example.*harmless\|harmless.*omp.toml.example' docs/stow-usage.md
# Verify: finding 4 (symlink note) is addressed

grep 'brew install' docs/stow-usage.md | grep 'oh-my-posh'
# Verify: macOS OMP install note present

grep 'yay -S' docs/stow-usage.md | grep 'oh-my-posh'
# Verify: Arch OMP install note present
```

---

## Files Affected

| File | Action |
|---|---|
| `stow/common/omp/.config/omp/.gitignore` | created |
| `stow/common/omp/.config/omp/omp.toml.example` | created |
| `stow/common/zsh/.config/zsh/omp.zsh.example` | created |
| `stow/common/zsh/.config/zsh/.gitignore` | modified (append one line) |
| `docs/stow-usage.md` | modified (append OMP section) |

No files outside the repository root are modified.
No symlinks are created.
No stow install commands are run.

---

## Safety Checks

Before starting:

- [ ] Confirm `~/.config/omp/omp.toml` is not read, opened, or `cat`-ted at any point.
- [ ] Confirm no stow install command is run (only `--simulate` may appear in documentation).
- [ ] Confirm `stow/common/omp/` does not yet exist (`ls stow/common/` should not show `omp/`).

During execution:

- [ ] After each task, run `git status` to confirm only expected files are staged or modified.
- [ ] After Task 2, run the privacy audit checklist before proceeding.
- [ ] After Task 3, run `grep -v '^#' omp.zsh.example | grep -v '^$'` — must produce no output.

---

## Privacy Checks

Before completing the plan:

- [ ] `omp.toml.example` contains no username, hostname, or machine-specific path.
- [ ] `omp.toml.example` contains no API keys, tokens, or credentials.
- [ ] `omp.zsh.example` activation line is fully commented — no uncommented `eval` present.
- [ ] `stow/common/zsh/.config/zsh/.gitignore` includes `omp.zsh`.
- [ ] `stow/common/omp/.config/omp/.gitignore` includes `omp.toml`.
- [ ] `git diff --staged` reviewed for any real values before commit.

---

## Validation Commands (full set)

Run these after all tasks are complete, before committing:

```bash
# Verify directory structure
ls stow/common/omp/.config/omp/
# Expected: .gitignore  omp.toml.example

# Verify OMP gitignore
cat stow/common/omp/.config/omp/.gitignore
# Expected: omp.toml entry present

# Verify example file has no uncommented eval
grep -v '^#' stow/common/zsh/.config/zsh/omp.zsh.example | grep -v '^$'
# Expected: no output

# Verify zsh gitignore updated
grep 'omp.zsh' stow/common/zsh/.config/zsh/.gitignore
# Expected: omp.zsh

# Verify stow-usage.md OMP section present
grep -n 'Oh My Posh package adoption' docs/stow-usage.md
# Expected: line number printed

# Verify finding 4 addressed in stow-usage.md
grep 'harmless' docs/stow-usage.md
# Expected: line about omp.toml.example symlink being harmless

# Verify no real home directory changes
ls -la ~/.config/omp/ 2>/dev/null || echo "~/.config/omp/ does not exist — correct"
# Expected: either does not exist, or contains only pre-existing user files (no stow symlinks)

# Pre-commit safety check
git status
git diff --staged
# Expected: only the 5 planned files shown, no real values visible in diff
```

---

## Rollback Strategy

This plan creates only repository-internal files. No `$HOME` is modified. Rollback is
git-only.

**Undo a specific file (before commit):**

```bash
git checkout -- stow/common/zsh/.config/zsh/.gitignore
git checkout -- docs/stow-usage.md
```

**Remove a newly created file (before commit):**

```bash
git rm --cached stow/common/omp/.config/omp/omp.toml.example
rm stow/common/omp/.config/omp/omp.toml.example
# Repeat for each new file
```

**Undo after commit (before push):**

```bash
git reset HEAD~1
# Then selectively restore or remove files
```

No `$HOME` rollback is needed — nothing in `$HOME` is changed by this plan.

---

## Completion Criteria

From PRD 0005 acceptance criteria:

- [ ] `stow/common/omp/.config/omp/omp.toml.example` exists with a minimal starter theme.
- [ ] `stow/common/zsh/.config/zsh/omp.zsh.example` exists with the activation line
  documented in fully commented form.
- [ ] No real personal `~/.config/omp/omp.toml` content is present anywhere in the repo.
- [ ] No shell startup file (`~/.zshrc`, etc.) has been modified.
- [ ] No package (Oh My Posh or fonts) has been installed automatically.
- [ ] No symlinks have been created in `$HOME`.
- [ ] `docs/stow-usage.md` covers macOS and Arch OMP installation steps separately.
- [ ] `docs/stow-usage.md` covers Nerd Font requirements and manual installation.
- [ ] `docs/stow-usage.md` explains the manual activation step and the guarded eval line.
- [ ] `stow/common/zsh/.config/zsh/.gitignore` includes `omp.zsh`.
- [ ] `stow/common/omp/.config/omp/.gitignore` includes `omp.toml`.
- [ ] `docs/stow-usage.md` notes that the `omp.toml.example` symlink is expected and
  harmless (review finding 4 addressed).
- [ ] All validation commands above pass with no unexpected output.
- [ ] `git diff --staged` reviewed — no real values, no secrets, no personal data.

---

## Post-Completion Correction Note

**Date:** 2026-06-17
**Filed under:** Plan 0009

Running `task dry-run AREA=common PACKAGE=omp` against a real `$HOME` that already
contains `~/.config/omp/` produced:

```
WARNING! stowing omp would cause conflicts:
  * existing target is not owned by stow: .config/omp
All operations aborted.
```

This is expected and correct Stow behaviour — not a defect in the implementation.
The package layout is valid. A fake-home dry-run confirms it:

```bash
TEST_HOME="$(mktemp -d)"
stow --dir=stow/common --target="$TEST_HOME" --simulate omp
rm -rf "$TEST_HOME"
```

Documentation updates to cover this case are tracked in Plan 0009. No `$HOME` files
were modified. No `--adopt` was used.
