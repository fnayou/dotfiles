# Plan: Implement bat Configuration Package

**Number:** 0017
**Status:** Approved
**Date:** 2026-06-21
**PRD:** [0013-bat-configuration](../prd/0013-bat-configuration.md)
**Architecture:** [0013-bat-configuration-architecture](../architecture/0013-bat-configuration-architecture.md)

> **Backfill note:** This plan was written after the implementation already existed. It
> documents the steps that were (and should have been) taken, so the change can be reviewed
> against a concrete plan before commit. See review 0042.

---

## Objective

Create the `stow/common/bat/` Stow package with a real managed bat config and a vendored
Catppuccin Macchiato theme, add a README and setup guide, register the package in the root
README, and validate — without running Stow against `$HOME` or running `bat cache --build`
on the host.

---

## Assumptions

- PRD 0013 and Architecture 0013 are Approved.
- Builder does not run Stow against real `$HOME`.
- Builder does not run `bat cache --build` against the host.
- Builder does not use `stow --adopt`.
- Builder does not install bat or any dependency.
- `stow` 2.3+ is available (fake-home validation only).
- Network is available once, to fetch the upstream `.tmTheme` (Decision 1).

---

## Ordered Tasks

### Group A — Package skeleton

#### A1 — Create the directory tree

**Action:** Create `stow/common/bat/.config/bat/themes/`.

```
stow/common/bat/
└── .config/
    └── bat/
        └── themes/
```

**Validation:** `ls -la stow/common/bat/.config/bat/themes/` — directory exists.

#### A2 — Create `.stow-local-ignore`

**Action:** Create `stow/common/bat/.stow-local-ignore` with the standard six-line pattern
(matching `stow/common/alacritty/.stow-local-ignore`):

```
^/README\.md$
^/\.git$
^/\.gitignore$
^/\.stow-local-ignore$
^.*\.bak$
^.*\.orig$
```

**Validation:** `cat stow/common/bat/.stow-local-ignore` — six lines.

---

### Group B — Config and theme

#### B1 — Create `config`

**Action:** Create `stow/common/bat/.config/bat/config`:

```
# bat configuration
# https://github.com/sharkdp/bat
--theme="Catppuccin Macchiato"
--style="numbers,changes,header"
--wrap="auto"
--italic-text="always"
--paging="auto"
```

**Validation:** `grep theme stow/common/bat/.config/bat/config` — theme line present.

#### B2 — Vendor the Catppuccin Macchiato theme

**Action:** Fetch the upstream theme once into the package (Decision 1):

```bash
curl -fsSL "https://github.com/catppuccin/bat/raw/main/themes/Catppuccin%20Macchiato.tmTheme" \
  -o "stow/common/bat/.config/bat/themes/Catppuccin Macchiato.tmTheme"
```

**Safety check:** Writes into the repository only. No `$HOME` modification.

**Validation:** `head -5 "stow/common/bat/.config/bat/themes/Catppuccin Macchiato.tmTheme"` —
valid plist XML with `<string>Catppuccin Macchiato</string>` as the theme name.

---

### Group C — Documentation

#### C1 — Package README

**Action:** Create `stow/common/bat/README.md` describing what the package configures, the
file table, and a link to the setup guide. Mirror `stow/common/alacritty/README.md`.

#### C2 — Setup guide

**Action:** Create `docs/guides/bat-setup.md` mirroring `docs/guides/alacritty-setup.md`,
with an additional **section 6 "Activate the theme (build the cache)"** documenting
`bat cache --build` and a troubleshooting entry for "theme not applied".

#### C3 — Root README

**Action:** In `README.md`, add a `bat` row to the package table (alphabetical, between
`alacritty` and `git`) and add `bat` to the per-package setup-guides line.

> Note: the root README uses a package **table** that links to per-package READMEs and
> guides — there is no flat "Real managed packages: …" line to edit (unlike the older Herdr
> plan 0016). The status blocks in `AGENTS.md`/`CLAUDE.md` point to `stow/common/` as the
> source of truth and say "no package stowed yet", which remains true — so they are **not**
> edited by this plan (status-sync rule: prose state only changes on add/remove/first-stow,
> and adding an un-stowed package does not change the stowed-vs-not prose).

**Validation:** `grep -n bat README.md` — table row and guide link present.

---

### Group D — Validation (all read-only / repo-only)

#### D1 — Fake-home Stow simulation (two-step)

```bash
# Step 1 — conflict check
FAKE_HOME="$(mktemp -d)"
stow --dir=stow/common --target="$FAKE_HOME" --simulate --no-folding bat \
  && echo "Simulation passed: no conflicts detected"
rm -rf "$FAKE_HOME"

# Step 2 — symlink verification
FAKE_HOME="$(mktemp -d)"
stow --dir=stow/common --target="$FAKE_HOME" --no-folding bat
ls -la "$FAKE_HOME/.config/bat/" "$FAKE_HOME/.config/bat/themes/"
stow --dir=stow/common --target="$FAKE_HOME" --delete bat
rm -rf "$FAKE_HOME"
```

Expected: Step 1 "Simulation passed"; Step 2 shows `config` and the theme symlinks pointing
into the repository, then clean removal.

#### D2 — Privacy audit

```bash
grep -rEi \
  'password|token|secret|api.?key|private.?key|BEGIN (RSA|OPENSSH|EC)|hostname\.' \
  stow/common/bat/
```

Expected: no matches.

#### D3 — Pre-commit diff review

```bash
git status
git diff
```

Expected new/modified files:

```
new file:   stow/common/bat/.stow-local-ignore
new file:   stow/common/bat/.config/bat/config
new file:   stow/common/bat/.config/bat/themes/Catppuccin Macchiato.tmTheme
new file:   stow/common/bat/README.md
new file:   docs/guides/bat-setup.md
modified:   README.md
```

Plus the backfilled docs (PRD 0013, Architecture 0013, this plan, reviews 0041 & 0042).

---

## Files Affected

| File | Action |
|------|--------|
| `stow/common/bat/.stow-local-ignore` | created |
| `stow/common/bat/.config/bat/config` | created |
| `stow/common/bat/.config/bat/themes/Catppuccin Macchiato.tmTheme` | created (vendored) |
| `stow/common/bat/README.md` | created |
| `docs/guides/bat-setup.md` | created |
| `README.md` | modified — package table row + guide link |

No files outside the repository are created or modified.

---

## Safety Checks

- [ ] Builder does not run `stow` against real `$HOME`.
- [ ] Builder does not run `bat cache --build` against the host.
- [ ] Builder does not use `stow --adopt`.
- [ ] Builder does not install bat or any dependency.
- [ ] All stow install/delete commands in docs are marked `⚠️ MANUAL STEP`.
- [ ] `bat cache --build` in docs is presented as a user step, never auto-run.
- [ ] Privacy audit (D2) returns no matches before forwarding to Reviewer.

---

## Manual Install Reference (Document Only — Never Run by Builder)

```bash
# Dry run
stow --dir=stow/common --target="$HOME" --simulate --no-folding bat
```

⚠️  MANUAL STEP — run only after reviewing dry-run output

```bash
# Install
stow --dir=stow/common --target="$HOME" --no-folding bat

# Activate theme
bat cache --build
```

---

## Rollback Strategy

All changes are repository files only.

```bash
git checkout -- README.md
rm -rf stow/common/bat/ docs/guides/bat-setup.md
```

If files were staged:

```bash
git reset HEAD stow/common/bat/ docs/guides/bat-setup.md README.md
```

---

## Completion Criteria

- [x] `stow/common/bat/.stow-local-ignore` exists with six patterns.
- [x] `stow/common/bat/.config/bat/config` sets `--theme="Catppuccin Macchiato"`.
- [x] `Catppuccin Macchiato.tmTheme` vendored and valid plist XML.
- [x] `stow/common/bat/README.md` and `docs/guides/bat-setup.md` exist; guide documents
      `bat cache --build`.
- [x] Root README package table lists `bat`.
- [x] D1 fake-home simulation: Step 1 exits 0; Step 2 symlinks correct, clean removal.
- [x] D2 privacy audit: no matches.
- [x] D3 `git status` shows only expected files.
- [ ] Reviewer approves before commit.
