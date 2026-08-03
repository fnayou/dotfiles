# Plan: Implement CLI Speed Test Tool

**Number:** 0027
**Status:** Complete
**Date:** 2026-08-03
**PRD:** 0022 — CLI Speed Test Tool
**Architecture:** 0021 — CLI Speed Test Tool Architecture

## Objective

Add `cloudflare-speed-cli` to the three package manifests and give it a guarded configuration layer
(`speedtest.zsh`) in the existing `zsh` Stow package, with a setup guide, an ADR, and matching README
and website updates.

## Assumptions

- The `zsh` package is already stowed with `--no-folding`; a new file inside it is **not** linked until
  the user re-runs `stow` manually. No agent runs `stow`.
- `cloudflare-speed-cli` is not installed on this machine. The layer is guarded, so nothing breaks.
- Flag names come from upstream `src/cli.rs` (clap, kebab-cased). The guide instructs verification
  with `--help` after install.
- No Stow package is added or removed, so the `AGENTS.md` §2 / `CLAUDE.md` status blocks are untouched
  (`status-sync` rule self-check passes).

## Ordered Tasks

### Task 1 — Add the macOS entry to `packages/Brewfile`

Append a network section after the system-monitor section:

```ruby
# --- Network speed test ---
# Optional — powers the `speed` / `speed-json` / `speed-log` helpers in the zsh package.
# See: docs/guides/speedtest-setup.md
brew "cloudflare-speed-cli"
```

Homebrew core formula — no tap.

### Task 2 — Add the Arch entry to `packages/arch/packages.txt`

Append, in the file's comment style (commands stay commented — this file is a manifest, not a script):

```
# --- Network speed test (pacman, extra repo) ---
# Optional — powers the `speed` / `speed-json` / `speed-log` helpers in the zsh package.
# See: docs/guides/speedtest-setup.md
# sudo pacman -S cloudflare-speed-cli
```

Official `extra` repository — no AUR.

### Task 3 — Add the Debian entry to `packages/debian/packages.txt`

Extend the existing `--- Out-of-band (not in the Debian archive) ---` section with a
`cloudflare-speed-cli` block offering `cargo install` and the release-binary alternative. Do **not**
add an `apt install` line — the package is not in the archive.

### Task 4 — Create `stow/common/zsh/.config/zsh/speedtest.zsh`

New guarded layer: `command -v cloudflare-speed-cli >/dev/null 2>&1 || return`, three
`: "${SPEEDTEST_*:=...}"` defaults, and the functions `speed`, `speed-json`, `speed-log`. Header
comment must state that the tool has no config file and that `local.zsh` overrides the defaults.

Rules for the file:

- No command runs at source time other than the `command -v` guard.
- No `rm`, `mv`, or `ln -s`; the only write is `mkdir -p` inside `speed-log`, under XDG state.
- All paths derived from `$HOME` / XDG variables — nothing machine-specific.

### Task 5 — Source the layer from `index.zsh`

Insert a new slot `6e` after the `ssh.zsh` line (6d), before the keybindings section:

```zsh
# 6e) cloudflare-speed-cli helpers — guarded; no-op without the binary.
[[ -r "$HOME/.config/zsh/speedtest.zsh" ]] && source "$HOME/.config/zsh/speedtest.zsh"
```

Existing ordering guarantees (compinit, fzf, zoxide-last) must not change.

### Task 6 — Write `docs/decisions/0061-cloudflare-speed-cli-for-cli-speed-tests.md`

ADR: context, the `riptide` comparison, alternatives rejected (Ookla, librespeed-cli, fast-cli,
speedtest-go, crusader), decision, consequences — including the accepted theming gap and the
Cloudflare-edge measurement caveat.

### Task 7 — Write `docs/guides/speedtest-setup.md`

Per-platform install (each block labelled, dangerous commands marked), what the three functions do,
the override recipe via `local.zsh`, the re-stow step with dry-run first, the cron/timer example, and
the two caveats (no theming, Cloudflare-edge measurement).

### Task 8 — Update `stow/common/zsh/README.md`

Add a `speedtest.zsh` row to the file table and a short section describing the three functions and
the override variables.

### Task 9 — Update `README.md`

Add the new guide to the documentation list. The package table is **not** touched — no Stow package
was added.

### Task 10 — Update the website pages

- `website/features/shell.md` — add a `speedtest.zsh` row to the layer table.
- `website/usage/functions.md` — document `speed`, `speed-json`, `speed-log` as user-facing functions.

### Task 11 — Validate

Run the validation commands below. Fix anything that fails before review.

## Files Affected

- `packages/Brewfile` — modified
- `packages/arch/packages.txt` — modified
- `packages/debian/packages.txt` — modified
- `stow/common/zsh/.config/zsh/speedtest.zsh` — created
- `stow/common/zsh/.config/zsh/index.zsh` — modified
- `stow/common/zsh/README.md` — modified
- `README.md` — modified
- `docs/decisions/0061-cloudflare-speed-cli-for-cli-speed-tests.md` — created
- `docs/guides/speedtest-setup.md` — created
- `website/features/shell.md` — modified
- `website/usage/functions.md` — modified
- `docs/prd/0022-cli-speed-test-tool.md` — created
- `docs/architecture/0021-cli-speed-test-tool-architecture.md` — created
- `docs/plans/0027-implement-cli-speed-test-tool.md` — created (this file)

No file is deleted.

## Safety Checks

- Before starting: working tree is on a feature branch, not `main`.
- No command touches `$HOME` — the new file is written inside the repository only.
- No `stow` invocation at any point.
- No speed test is executed by an agent (the tool is not installed here anyway).
- `git status` at the end shows only the files listed above.

## Validation Commands

```bash
# Only the expected files changed
git status --short

# The new layer and the entry point parse
zsh -n stow/common/zsh/.config/zsh/speedtest.zsh
zsh -n stow/common/zsh/.config/zsh/index.zsh

# The guard is present and is the first executable line
grep -n "command -v cloudflare-speed-cli" stow/common/zsh/.config/zsh/speedtest.zsh

# No destructive verbs in the new layer
grep -nE "\brm\b|\bmv\b|ln -s|--adopt" stow/common/zsh/.config/zsh/speedtest.zsh \
  && echo "FAIL: destructive verb" || echo "OK: no destructive verbs"

# index.zsh sources the layer exactly once
grep -c "speedtest.zsh" stow/common/zsh/.config/zsh/index.zsh

# Manifests mention the tool on all three platforms
grep -rn "cloudflare-speed-cli" packages/

# No secrets, no machine-specific paths
git diff | grep -iE "password|token|api[_-]?key|secret|BEGIN.*PRIVATE|/Users/|/home/" \
  && echo "FAIL: audit hit" || echo "OK: audit clean"
```

Expected: `zsh -n` silent, guard found, "OK" for both audits, `1` for the source count, three manifest
files matched.

## Rollback Strategy

Nothing is stowed and nothing outside the repository is touched, so rollback is purely git:

⚠️  MANUAL STEP — review before running; these discard repository changes

```bash
# Undo a single file
git checkout -- <file>

# Drop the new files
rm -f stow/common/zsh/.config/zsh/speedtest.zsh docs/guides/speedtest-setup.md

# Or abandon the whole branch (before any merge)
git switch main && git branch -D feat/cloudflare-speed-cli
```

Users who already stowed and want out: remove the `6e` block from `index.zsh`, re-stow, and delete
`${XDG_STATE_HOME:-$HOME/.local/state}/cloudflare-speed-cli/` by hand if they no longer want the CSV
history.

## Completion Criteria

- [x] All three manifests list the tool with the correct per-platform install source.
- [x] `speedtest.zsh` exists, is guarded, defines the three overridable defaults and three functions.
- [x] `index.zsh` sources it once, at slot 6e, with existing ordering unchanged.
- [x] `zsh -n` passes on both files.
- [x] ADR 0061 and `docs/guides/speedtest-setup.md` exist and cross-reference PRD 0022 / this plan.
- [x] `stow/common/zsh/README.md`, `README.md`, and the two website pages are updated.
- [x] Status blocks untouched — verified no Stow package was added or removed.
- [x] Review report written under `docs/reviews/` — 0067, three PASS verdicts.
