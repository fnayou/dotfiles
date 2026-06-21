# Plan: Implement eza Configuration Package

**Number:** 0018
**Status:** Approved
**Date:** 2026-06-21
**PRD:** [0014-eza-configuration](../prd/0014-eza-configuration.md)
**Architecture:** [0014-eza-configuration-architecture](../architecture/0014-eza-configuration-architecture.md)

---

## Objective

Create the `stow/common/eza/` Stow package with a real managed eza theme (Catppuccin
Macchiato Blue), add a README and setup guide, register the package in the root README, and
validate — without running Stow against `$HOME`.

---

## Assumptions

- PRD 0014 and Architecture 0014 are Approved (review 0043).
- Builder does not run Stow against real `$HOME`.
- Builder does not use `stow --adopt`.
- Builder does not install eza or any dependency.
- `stow` 2.3+ is available (fake-home validation only).
- Network is available once, to fetch the upstream theme (Decision 1).

---

## Ordered Tasks

### Group A — Package skeleton

#### A1 — Create the directory tree

**Action:** Create `stow/common/eza/.config/eza/`.

**Validation:** `ls -la stow/common/eza/.config/eza/` — directory exists.

#### A2 — Create `.stow-local-ignore`

**Action:** Create `stow/common/eza/.stow-local-ignore` with the standard six-line pattern
(matching `stow/common/alacritty/.stow-local-ignore`):

```
^/README\.md$
^/\.git$
^/\.gitignore$
^/\.stow-local-ignore$
^.*\.bak$
^.*\.orig$
```

**Validation:** `cat stow/common/eza/.stow-local-ignore` — six lines.

---

### Group B — Theme

#### B1 — Vendor the Catppuccin Macchiato (Blue) theme as `theme.yml`

**Action:** Fetch the upstream theme once into the package as `theme.yml` (Decisions 1 & 3):

```bash
curl -fsSL "https://github.com/catppuccin/eza/raw/main/themes/macchiato/catppuccin-macchiato-blue.yml" \
  -o "stow/common/eza/.config/eza/theme.yml"
```

**Safety check:** Writes into the repository only. No `$HOME` modification.

**Validation:** `head -20 stow/common/eza/.config/eza/theme.yml` — valid YAML with color keys
(e.g. `colourful`, `filekinds`, `git`, `punctuation`). File is non-empty.

---

### Group C — Documentation

#### C1 — Package README

**Action:** Create `stow/common/eza/README.md` mirroring `stow/common/bat/README.md`:
purpose, file table, link to the setup guide. Note no cache-build step.

#### C2 — Setup guide

**Action:** Create `docs/guides/eza-setup.md` mirroring `docs/guides/bat-setup.md`, but:
- **Omit** the bat cache-build section — eza reads `theme.yml` directly.
- **Add** an `EZA_CONFIG_DIR` troubleshooting note (review 0043 N1): if the env var points
  elsewhere, the stowed `~/.config/eza/theme.yml` is not read.

#### C3 — Root README

**Action:** In `README.md`, add an `eza` row to the package table (alphabetical, between
`bat` and `git`) and add `eza` to the per-package setup-guides line.

> Status blocks in `AGENTS.md`/`CLAUDE.md` are NOT edited: they point to `stow/common/` as
> source of truth and state "no package stowed yet" — still true (adding an un-stowed package
> changes neither phase nor stowed-vs-not prose; status-sync rule).

**Validation:** `grep -n eza README.md` — table row and guide link present.

---

### Group D — Validation (read-only / repo-only)

#### D1 — Fake-home Stow simulation (two-step)

```bash
# Step 1 — conflict check
FAKE_HOME="$(mktemp -d)"
stow --dir=stow/common --target="$FAKE_HOME" --simulate --no-folding eza \
  && echo "Simulation passed: no conflicts detected"
rm -rf "$FAKE_HOME"

# Step 2 — symlink verification
FAKE_HOME="$(mktemp -d)"
stow --dir=stow/common --target="$FAKE_HOME" --no-folding eza
ls -la "$FAKE_HOME/.config/eza/"
test ! -L "$FAKE_HOME/.config/eza" && echo "OK: .config/eza is a real dir"
stow --dir=stow/common --target="$FAKE_HOME" --delete eza && echo "Cleanup OK"
rm -rf "$FAKE_HOME"
```

Expected: Step 1 "Simulation passed"; Step 2 shows `theme.yml` symlink into the repo,
`~/.config/eza` is a real dir, then clean removal.

#### D2 — YAML syntax check

```bash
python3 -c "import yaml,sys; yaml.safe_load(open(sys.argv[1])); print('OK')" \
  stow/common/eza/.config/eza/theme.yml 2>/dev/null \
  || echo "SKIP: PyYAML not available — manual YAML review"
```

Expected: `OK`, or graceful `SKIP` if PyYAML absent (manual review fallback).

#### D3 — Privacy audit

```bash
grep -rEi \
  'password|token|secret|api.?key|private.?key|BEGIN (RSA|OPENSSH|EC)|hostname\.' \
  stow/common/eza/
```

Expected: no matches.

#### D4 — Pre-commit diff review

```bash
git status
```

Expected new/modified files:

```
new file:   stow/common/eza/.stow-local-ignore
new file:   stow/common/eza/.config/eza/theme.yml
new file:   stow/common/eza/README.md
new file:   docs/guides/eza-setup.md
modified:   README.md
```

Plus the chain docs (PRD 0014, architecture 0014, this plan, reviews 0043 & 0044).

---

## Files Affected

| File | Action |
|------|--------|
| `stow/common/eza/.stow-local-ignore` | created |
| `stow/common/eza/.config/eza/theme.yml` | created (vendored, Macchiato Blue) |
| `stow/common/eza/README.md` | created |
| `docs/guides/eza-setup.md` | created |
| `README.md` | modified — package table row + guide link |

No files outside the repository are created or modified.

---

## Safety Checks

- [ ] Builder does not run `stow` against real `$HOME`.
- [ ] Builder does not use `stow --adopt`.
- [ ] Builder does not install eza or any dependency.
- [ ] All stow install/delete commands in docs marked `⚠️ MANUAL STEP`.
- [ ] Privacy audit (D3) returns no matches before forwarding to Reviewer.

---

## Manual Install Reference (Document Only — Never Run by Builder)

```bash
# Dry run
stow --dir=stow/common --target="$HOME" --simulate --no-folding eza
```

⚠️  MANUAL STEP — run only after reviewing dry-run output

```bash
# Install
stow --dir=stow/common --target="$HOME" --no-folding eza
```

No cache-build step — eza reads `theme.yml` directly.

---

## Rollback Strategy

All changes are repository files only.

```bash
git checkout -- README.md
rm -rf stow/common/eza/ docs/guides/eza-setup.md
```

If staged:

```bash
git reset HEAD stow/common/eza/ docs/guides/eza-setup.md README.md
```

---

## Completion Criteria

- [ ] `stow/common/eza/.stow-local-ignore` exists with six patterns.
- [ ] `stow/common/eza/.config/eza/theme.yml` exists (Macchiato Blue), valid YAML.
- [ ] `stow/common/eza/README.md` and `docs/guides/eza-setup.md` exist.
- [ ] Root README package table lists `eza`.
- [ ] D1 fake-home simulation: Step 1 exits 0; Step 2 symlink correct, real dir, clean removal.
- [ ] D2 YAML check: passes or skips gracefully.
- [ ] D3 privacy audit: no matches.
- [ ] D4 `git status` shows only expected files.
- [ ] Reviewer approves before commit.
