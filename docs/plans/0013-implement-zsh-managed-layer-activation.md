# Plan: Implement Zsh Managed-Layer Activation (--no-folding)

**Number:** 0013
**Status:** Complete
**Date:** 2026-06-18
**PRD:** [0008-zsh-managed-layer-activation.md](../prd/0008-zsh-managed-layer-activation.md)
**Architecture:** [0008-zsh-managed-layer-activation-architecture.md](../architecture/0008-zsh-managed-layer-activation-architecture.md)
**Review:** 0025 (PRD + Architecture, all 10 verdicts PASS, Final Verdict: APPROVED)

---

## Objective

Convert the current inert-but-safe zsh stow state (directory-fold symlink, no real managed files) into an active per-file symlink layout under `--no-folding`, so the `~/.zshrc` include guard resolves and the managed zsh layer loads. Covers status-update housekeeping, three new ADRs, creating the minimum real managed files in the repo package dir, the dry-run-gated migration from the folded state, post-migration validation, and documentation updates. Every command touching `$HOME` is a `⚠️ MANUAL STEP`.

---

## Assumptions

- PRD 0008 and Architecture 0008 are **both currently Draft** — Phase 0 marks them Approved.
- Review 0025 is already **Complete** (confirmed in the file header).
- ADR-0024 is already **Accepted** — Phase 1, Task 1 confirms this with a read-only check.
- Current filesystem state is exactly as Review 0024 confirmed: `~/.config/zsh` is a directory-fold symlink; `~/.zshrc` is a regular file containing the guarded include block; `$ZDOTDIR` is unset; only `*.example` templates exist in the package; no real managed files exist.
- The package `.gitignore` at `stow/common/zsh/.config/zsh/.gitignore` already ignores all real managed filenames (`index.zsh`, `shared.zsh`, `macos.zsh`, `arch.zsh`, `omp.zsh`, `local.zsh`). No `.gitignore` change is needed.
- Builder implements only approved plan items. No improvisation, no `$HOME` writes, no Stow without explicit `⚠️ MANUAL STEP` marker and a preceding `--simulate` dry-run.
- This plan targets macOS as the primary migration machine. Arch/EndeavourOS follows the same steps with identical commands.

---

## Ordered Tasks

### Phase 0 — Status Updates

Agent performs these file edits. No `⚠️ MANUAL STEP` marker needed (repo-internal file edits only, no `$HOME` change).

---

#### Task 0.1 — Mark PRD 0008 as Approved

**Description:** Change `**Status:** Draft` to `**Status:** Approved` in `docs/prd/0008-zsh-managed-layer-activation.md`. Review 0025 gives a Final Verdict of APPROVED; the status field must reflect this before the Builder implements any plan task.

**File to modify:** `docs/prd/0008-zsh-managed-layer-activation.md`

**Change:** Line 3 — `**Status:** Draft` → `**Status:** Approved`

**Expected result:** The file header reads `**Status:** Approved`. No other content changes.

**Validate:**

```bash
grep "^\*\*Status:\*\*" docs/prd/0008-zsh-managed-layer-activation.md
# expect: **Status:** Approved
```

**Status:** [ ] Not started

---

#### Task 0.2 — Mark Architecture 0008 as Approved

**Description:** Change `**Status:** Draft` to `**Status:** Approved` in `docs/architecture/0008-zsh-managed-layer-activation-architecture.md`. Same rationale as Task 0.1.

**File to modify:** `docs/architecture/0008-zsh-managed-layer-activation-architecture.md`

**Change:** Line 3 — `**Status:** Draft` → `**Status:** Approved`

**Expected result:** The file header reads `**Status:** Approved`. No other content changes.

**Validate:**

```bash
grep "^\*\*Status:\*\*" docs/architecture/0008-zsh-managed-layer-activation-architecture.md
# expect: **Status:** Approved
```

**Status:** [ ] Not started

---

#### Task 0.3 — Confirm Review 0025 is Complete

**Description:** Read-only check. Review 0025 was written as Complete (its header shows `**Status:** Complete`). Log the finding; no edit required.

**Expected result:** `grep "^\*\*Status:\*\*" docs/reviews/0025-zsh-managed-layer-activation-prd-architecture-review.md` returns `**Status:** Complete`. No action taken.

**Validate:**

```bash
grep "^\*\*Status:\*\*" docs/reviews/0025-zsh-managed-layer-activation-prd-architecture-review.md
# expect: **Status:** Complete
```

**Status:** [ ] Not started

---

### Phase 1 — ADRs

---

#### Task 1.1 — Confirm ADR-0024 Already Accepted (read-only check)

**Description:** Read `docs/decisions/0024-use-no-folding-for-zsh-package.md` and confirm the status field is Accepted. Log: "ADR-0024 already Accepted — no action." No file modification.

**Validate:**

```bash
grep "^\*\*Status:\*\*" docs/decisions/0024-use-no-folding-for-zsh-package.md
# expect: **Status:** Accepted
```

**Status:** [ ] Not started

---

#### Task 1.2 — Create ADR-0025

**Description:** Create `docs/decisions/0025-managed-zsh-files-git-ignored-linked-by-presence.md`.

This ADR records the decision established in Architecture 0008 §4 ("Open question resolved"): Stow links files by physical presence in the package directory, not by git-tracking status. Therefore the real managed files (`index.zsh`, `shared.zsh`, `macos.zsh`, `arch.zsh`, `omp.zsh`) can stay git-ignored — created locally by the user copying from `.example` — while Stow's `--no-folding` pass creates per-file symlinks for them in `~/.config/zsh/`. The committed source of truth remains the `*.example` templates with placeholder-only values. Committing the filled-in real files would risk personal values entering version control, violating AGENTS §9 and ADR-0003. The current `.gitignore` at `stow/common/zsh/.config/zsh/.gitignore` is correct and needs no change.

**Full file content to write:**

```markdown
# Decision: Managed Zsh Real Files Are Linked by Stow from Physical Presence While Staying Git-Ignored; Only `.example` Templates Are Versioned

**Number:** 0025
**Date:** 2026-06-18
**Status:** Accepted
**PRD:** 0008-zsh-managed-layer-activation
**Architecture:** 0008-zsh-managed-layer-activation-architecture (§4)

## Context

PRD 0008 raised a concern: the package `.gitignore` excludes the real managed filenames
(`index.zsh`, `shared.zsh`, `macos.zsh`, `arch.zsh`, `omp.zsh`), yet `--no-folding` must
symlink exactly those files from the package directory into `~/.config/zsh/`. If the files
are git-ignored, can Stow still link them?

Architecture 0008 §4 resolved this: Stow determines what to symlink by scanning the package
directory for files **physically present on disk**, not by reading the git index. A
git-ignored file that exists on disk is linked by Stow just as any tracked file would be.

## Decision

Keep the package `.gitignore` exactly as-is. Do not un-ignore `index.zsh`, `shared.zsh`,
`macos.zsh`, `arch.zsh`, or `omp.zsh`.

The workflow is:

1. User copies `.example` → real filename locally (e.g. `index.zsh.example` → `index.zsh`).
2. The real file exists on disk in the package dir; it is git-ignored and never committed.
3. `stow --no-folding` scans the package dir and creates a per-file symlink for each
   physical file it finds, tracked or not.
4. The `*.example` templates remain the only committed source of truth — placeholder values
   only, no personal or sensitive data.

"Versioned" in PRD 0008 means the template is versioned (the `.example`), not the
filled-in real file.

## Consequences

- Filled-in real files (which may contain personal paths, tool choices, or machine-specific
  values) are never committed, satisfying AGENTS §9 (privacy) and ADR-0003.
- The `.gitignore` at `stow/common/zsh/.config/zsh/.gitignore` needs no change.
- Each new managed file requires a `--no-folding --restow` to create its symlink —
  accepted trade-off (PRD 0008, ADR-0024).
- `local.zsh` remains ignored and additionally lives physically outside the repo (ADR-0026),
  so it cannot be `git add`-ed by accident.
- If a future requirement genuinely demands committing a fully-portable managed file with no
  personal values, that would require a separate ADR un-ignoring only that specific filename
  and is not recommended now.
```

**Create:** `docs/decisions/0025-managed-zsh-files-git-ignored-linked-by-presence.md`

**Validate:**

```bash
grep "^\*\*Status:\*\*" docs/decisions/0025-managed-zsh-files-git-ignored-linked-by-presence.md
# expect: **Status:** Accepted
grep -c "git-ignored" docs/decisions/0025-managed-zsh-files-git-ignored-linked-by-presence.md
# expect: ≥ 1
```

**Status:** [ ] Not started

---

#### Task 1.3 — Create ADR-0026

**Description:** Create `docs/decisions/0026-local-zsh-real-file-outside-repo-never-symlinked.md`.

This ADR refines ADR-0023 specifically for the `--no-folding` context established by Architecture 0008 §5. Under folding, `local.zsh` would land inside the repo working tree (because `~/.config/zsh` is the repo dir). Under `--no-folding`, `~/.config/zsh` is a real directory that Stow owns but does not equate to the repo dir — so `local.zsh`, created directly there by the user, lives **physically outside the repo working tree**. This is a stronger privacy boundary than `.gitignore` alone.

**Full file content to write:**

```markdown
# Decision: `local.zsh` Is a Real, Unversioned File Created Outside the Repo Under `~/.config/zsh/`, Never Symlinked

**Number:** 0026
**Date:** 2026-06-18
**Status:** Accepted
**PRD:** 0008-zsh-managed-layer-activation
**Architecture:** 0008-zsh-managed-layer-activation-architecture (§5)
**Refines:** ADR-0023

## Context

ADR-0023 established `local.zsh` as the git-ignored, last-sourced override slot. Under the
old directory-fold stow, `~/.config/zsh` was a symlink into the repo package dir — so a
`local.zsh` created in `~/.config/zsh/` would physically reside inside the repo working
tree; the only protection against accidental commit was the `.gitignore` entry.

ADR-0024 switched the intended stow strategy to `--no-folding`. Under `--no-folding`,
`~/.config/zsh/` is a **real directory** that Stow owns, not a symlink into the repo.
Stow places per-file symlinks for managed files inside it; any non-symlinked file placed
there resides **outside the repo working tree** and cannot be `git add`-ed by accident.

## Decision

`local.zsh` is a **real, unversioned file** that the user creates directly under
`~/.config/zsh/` using their editor:

```
⚠️  MANUAL STEP — create a REAL private file (not from the repo); put machine-specific and
    sensitive values only here; never commit
$EDITOR "$HOME/.config/zsh/local.zsh"
```

It is:
- **Not** copied from the repo (no `.example` template exists for it — ADR-0023).
- **Not** a symlink — Stow has no `local.zsh` in the package dir to link from.
- **Not** tracked by git: the `.gitignore` entry is a belt-and-suspenders second line of
  defence, but the primary boundary is physical: the file is outside the repo working tree
  and cannot be staged.

`index.zsh` sources it last (`[[ -r "$HOME/.config/zsh/local.zsh" ]] && source …`) and
only if present, so machines without a `local.zsh` start a clean shell.

## Consequences

- `local.zsh` has a stronger privacy boundary than under folding: even without `.gitignore`,
  it could not enter git because it lives outside the repo (ADR-0003 / AGENTS §9).
- The `.gitignore` entry for `local.zsh` in `stow/common/zsh/.config/zsh/.gitignore`
  remains correct and is kept as the belt-and-suspenders guard.
- No `.example` template exists for `local.zsh`; this is intentional — the content is
  machine-specific and sensitive by design.
- Refines ADR-0023: the "git-ignored" property still holds, but the stronger "physically
  outside the repo" property now also holds under `--no-folding`.
```

**Create:** `docs/decisions/0026-local-zsh-real-file-outside-repo-never-symlinked.md`

**Validate:**

```bash
grep "^\*\*Status:\*\*" docs/decisions/0026-local-zsh-real-file-outside-repo-never-symlinked.md
# expect: **Status:** Accepted
grep "Refines" docs/decisions/0026-local-zsh-real-file-outside-repo-never-symlinked.md
# expect: Refines: ADR-0023
```

**Status:** [ ] Not started

---

#### Task 1.4 — Create ADR-0027

**Description:** Create `docs/decisions/0027-zshrc-stays-unmanaged-no-folding-migration-does-not-touch-it.md`.

This ADR reaffirms ADR-0021 in the specific context of the `--no-folding` migration. The migration only alters the shape of `~/.config/zsh/` — it never touches `~/.zshrc`. The package covers only `.config/zsh/`; `~/.zshrc` is at the `$HOME` root and outside the package's stow reach.

**Full file content to write:**

```markdown
# Decision: `~/.zshrc` Stays an Unmanaged User-Owned Regular File; the `--no-folding` Migration Does Not Touch It

**Number:** 0027
**Date:** 2026-06-18
**Status:** Accepted
**PRD:** 0008-zsh-managed-layer-activation
**Architecture:** 0008-zsh-managed-layer-activation-architecture (§6)
**Reaffirms:** ADR-0021

## Context

ADR-0021 established that `~/.zshrc` is never stowed, never symlinked, and never
auto-edited — the user adds the single guarded include block by hand. ADR-0024 introduced
the `--no-folding` migration, which changes how the zsh package is stowed. A question
arises: does the migration affect `~/.zshrc`?

Review 0024 confirmed `~/.zshrc` is already a regular file (7 lines, not a symlink)
containing the guarded include block. Architecture 0008 §6 confirmed the migration alters
only the shape of `~/.config/zsh/` — converting the directory-fold symlink into a real
directory with per-file symlinks — and never touches `~/.zshrc`.

## Decision

`~/.zshrc` remains an unmanaged, user-owned regular file throughout and after the
`--no-folding` migration.

Specifically:
- The zsh package path is `stow/common/zsh/.config/zsh/`. Stow targets `~/.config/zsh/`.
  `~/.zshrc` is at the `$HOME` root — outside the package's reach. Stow cannot link or
  touch it regardless of flags.
- No migration step (unstow fold, restow with `--no-folding`, copy `.example` → real file)
  reads, writes, or checks `~/.zshrc` content. The guarded include block already present
  is the sole, sufficient trigger: once `index.zsh` becomes a real per-file symlink, the
  guard passes on the next interactive shell open — no `~/.zshrc` edit required.
- `zshrc.example` in the package stows only to `~/.config/zsh/zshrc.example` (a reference
  copy); it is never linked to `~/.zshrc` (ADR-0021).
- No agent, script, or task in this repository ever writes to `~/.zshrc` (AGENTS §8).

## Consequences

- The migration path is simpler: it is purely a stow-shape change. The user edits only
  `$HOME` stow targets inside `~/.config/zsh/`; `~/.zshrc` is untouched.
- The guarded include block the user added (confirmed by Review 0024) is the activation
  trigger and requires no modification for the `--no-folding` migration to take effect.
- Reaffirms ADR-0021 against the new migration context: the managed footprint in `~/.zshrc`
  remains exactly one delimited three-line block, and the sole revert path (delete those
  three lines) is unchanged.
```

**Create:** `docs/decisions/0027-zshrc-stays-unmanaged-no-folding-migration-does-not-touch-it.md`

**Validate:**

```bash
grep "^\*\*Status:\*\*" docs/decisions/0027-zshrc-stays-unmanaged-no-folding-migration-does-not-touch-it.md
# expect: **Status:** Accepted
grep "Reaffirms" docs/decisions/0027-zshrc-stays-unmanaged-no-folding-migration-does-not-touch-it.md
# expect: Reaffirms: ADR-0021
```

**Status:** [ ] Not started

---

#### Task 1.5 — Update `docs/decisions/README.md` Index

**Description:** Add the three new ADRs (0025, 0026, 0027) to the index table in `docs/decisions/README.md`. Append after the ADR-0024 row.

**Rows to append:**

```markdown
| [0025](0025-managed-zsh-files-git-ignored-linked-by-presence.md) | Managed zsh real files are linked by Stow from physical presence while staying git-ignored | Accepted |
| [0026](0026-local-zsh-real-file-outside-repo-never-symlinked.md) | `local.zsh` is a real, unversioned file outside the repo, never symlinked | Accepted |
| [0027](0027-zshrc-stays-unmanaged-no-folding-migration-does-not-touch-it.md) | `~/.zshrc` stays unmanaged; `--no-folding` migration does not touch it | Accepted |
```

**Validate:**

```bash
grep -c "0025\|0026\|0027" docs/decisions/README.md
# expect: 3
```

**Status:** [ ] Not started

---

### Phase 2 — Managed File Decisions

The package `.gitignore` already ignores all real filenames. Stow links by physical presence, not git-tracking (ADR-0025). The agent performs the repo-internal copy commands below (within `stow/`, no `$HOME` change). Only `index.zsh` and `shared.zsh` become real managed files in this plan. `omp.zsh`, `macos.zsh`, and `arch.zsh` remain `.example` only for now (deferred to a later plan or user action).

---

#### Task 2.1 — Create `index.zsh` from `.example` (repo-internal copy)

**Description:** Copy `index.zsh.example` to `index.zsh` within the repo package directory. This is a repo-internal copy only — no `$HOME` change. The resulting file is git-ignored (confirmed by the existing `.gitignore`). The file will be linked per-file to `~/.config/zsh/index.zsh` after the `--no-folding` restow in Phase 3.

**Command (agent-run, repo-internal — no `⚠️ MANUAL STEP` needed):**

```bash
cp stow/common/zsh/.config/zsh/index.zsh.example stow/common/zsh/.config/zsh/index.zsh
```

**Confirm git-ignored:**

```bash
git check-ignore stow/common/zsh/.config/zsh/index.zsh
# expect: stow/common/zsh/.config/zsh/index.zsh (the path is reported as ignored)
```

**Expected result:** `stow/common/zsh/.config/zsh/index.zsh` exists on disk; `git status` does not show it as an untracked or modified file; `ls stow/common/zsh/.config/zsh/` lists both `index.zsh` and `index.zsh.example`.

**Validate:**

```bash
ls stow/common/zsh/.config/zsh/index.zsh
# expect: file exists (no error)
git status --short stow/common/zsh/.config/zsh/
# expect: index.zsh does NOT appear (it is git-ignored)
```

**Note:** `omp.zsh`, `macos.zsh`, and `arch.zsh` remain `.example` only for now and are not copied in this plan.

**Status:** [ ] Not started

---

#### Task 2.2 — Create `shared.zsh` from `.example` (repo-internal copy)

**Description:** Copy `shared.zsh.example` to `shared.zsh` within the repo package directory. Same rationale as Task 2.1. `shared.zsh` is the portable environment/history/completion/tool-integration layer. The file is git-ignored by the existing `.gitignore`.

**Command (agent-run, repo-internal — no `⚠️ MANUAL STEP` needed):**

```bash
cp stow/common/zsh/.config/zsh/shared.zsh.example stow/common/zsh/.config/zsh/shared.zsh
```

**Confirm git-ignored:**

```bash
git check-ignore stow/common/zsh/.config/zsh/shared.zsh
# expect: stow/common/zsh/.config/zsh/shared.zsh
```

**Expected result:** `stow/common/zsh/.config/zsh/shared.zsh` exists on disk; `git status` does not show it; both `shared.zsh` and `shared.zsh.example` appear in `ls` output.

**Validate:**

```bash
ls stow/common/zsh/.config/zsh/shared.zsh
# expect: file exists (no error)
git status --short stow/common/zsh/.config/zsh/
# expect: shared.zsh does NOT appear (git-ignored)
```

**Note:** Before Phase 3, review `shared.zsh` and replace any placeholder tokens (e.g. `YOUR_EDITOR`, `YOUR_PAGER`) with real values, or delete those lines. This is a local-only edit — the file is never committed.

**Status:** [ ] Not started

---

#### Task 2.3 — Git Safety Re-check (read-only)

**Description:** Confirm that only `.example` templates and `.gitignore` are tracked in the zsh package directory after Tasks 2.1–2.2. No real managed file should appear in `git ls-files`.

**Validate:**

```bash
git ls-files stow/common/zsh/.config/zsh/ | grep -vE '\.example$|\.gitignore$'
# expect: no output (only .example and .gitignore are tracked)
```

If any non-`.example`, non-`.gitignore` file appears in the output, STOP and investigate before proceeding to Phase 3.

**Status:** [ ] Not started

---

### Phase 3 — Migration: Folded → `--no-folding`

Every stow command or `rm` command touching `$HOME` is a `⚠️ MANUAL STEP`. The dry-run must be reviewed before the live command is run. Any dry-run that reports a conflict is a hard STOP — resolve manually, never use `--adopt`.

---

#### Task 3a — Pre-migration Validation (read-only)

**Description:** Confirm the start state matches what Review 0024 established. All commands are read-only. No `$HOME` content is dumped.

**Commands:**

```bash
# Confirm ~/.config/zsh is still the folded directory symlink
ls -ld "$HOME/.config/zsh"
# expect: lrwxr-xr-x ... ~/.config/zsh -> ...works/dotfiles/stow/common/zsh/.config/zsh

[[ -L "$HOME/.config/zsh" ]] && echo "folded(dir-symlink)" || echo "NOT-a-fold — investigate before proceeding"

# Confirm ~/.zshrc contains the guarded block (count only — no content dumped)
grep -c '>>> dotfiles managed (zsh)' "$HOME/.zshrc" 2>/dev/null
# expect: 1

# Confirm $ZDOTDIR is unset
echo "ZDOTDIR='${ZDOTDIR:-<unset>}'"
# expect: ZDOTDIR='<unset>'
```

**Expected result:** `~/.config/zsh` is a symlink; delimiter count is 1; `$ZDOTDIR` is unset. If any check fails, STOP and investigate — do not proceed with Phase 3 stow steps.

**Status:** [ ] Not started

---

#### Task 3b — Fake-Home Validation (agent-run, confirms `--no-folding` layout without touching `$HOME`)

**Description:** Run a fake-home `--simulate` to confirm the package produces the expected per-file symlink layout under `--no-folding`, without touching the real `$HOME`. Per ADR-0017. Remove the temporary directory immediately after.

**Commands:**

```bash
TEST_HOME="$(mktemp -d)"
stow --dir=stow/common --target="$TEST_HOME" --no-folding --simulate zsh
rm -rf "$TEST_HOME"
```

**Expected result:** Stow lists per-file symlinks for each file present in the package under `$TEST_HOME/.config/zsh/` — at minimum `index.zsh`, `shared.zsh`, `index.zsh.example`, `shared.zsh.example`, `zshrc.example`, `.gitignore`. No errors; no conflict output. If conflicts appear, STOP.

**Note:** The `rm -rf "$TEST_HOME"` targets only the ephemeral `mktemp` directory, not `~/.config/zsh`. This is safe and expected.

**Status:** [ ] Not started

---

#### Task 3c — Unstow the Fold (MANUAL STEPS)

**Description:** Remove the existing directory-fold symlink `~/.config/zsh`. This is done via `stow --delete`, which removes only the single directory symlink Stow created — it does not touch `~/.zshrc` or the repo package files.

⚠️ MANUAL STEP — dry-run first; confirm only `~/.config/zsh` symlink would be removed; review before running:

```bash
stow --dir=stow/common --target="$HOME" --simulate --delete zsh
```

Expected dry-run output: Stow reports it would unlink `~/.config/zsh`. `~/.zshrc` must NOT appear. If anything unexpected appears, STOP.

⚠️ MANUAL STEP — run only after dry-run output is confirmed clean:

```bash
stow --dir=stow/common --target="$HOME" --delete zsh
```

**Expected result:** `~/.config/zsh` no longer exists. The repo package files are unaffected. `~/.zshrc` is unaffected.

**Verify (read-only):**

```bash
[[ -e "$HOME/.config/zsh" ]] && echo "still-exists — investigate" || echo "fold-removed-ok"
ls -la "$HOME/.zshrc"
# expect: ~/.zshrc still present as a regular file
```

**Status:** [ ] Not started

---

#### Task 3d — Restow with `--no-folding` (MANUAL STEPS)

**Description:** Restow the zsh package with `--no-folding` so Stow creates a real `~/.config/zsh/` directory and places per-file symlinks for every physical file in the package directory.

⚠️ MANUAL STEP — dry-run first; review the per-file symlink list before running:

```bash
stow --dir=stow/common --target="$HOME" --no-folding --simulate zsh
```

Expected dry-run output: Stow reports creating `~/.config/zsh/` as a real directory, then listing per-file symlinks for `index.zsh`, `shared.zsh`, `index.zsh.example`, `shared.zsh.example`, `macos.zsh.example`, `arch.zsh.example`, `omp.zsh.example`, `zshrc.example`, `.gitignore`. `~/.zshrc` must NOT appear. If a conflict is reported (e.g. `existing target is not owned by stow`), STOP — do not `--adopt`. Resolve manually and re-run the dry-run.

⚠️ MANUAL STEP — run only after dry-run output is confirmed clean:

```bash
stow --dir=stow/common --target="$HOME" --no-folding zsh
```

**Expected result:** `~/.config/zsh/` is now a real directory; managed files are per-file symlinks resolving into the repo; `~/.zshrc` is unaffected.

**Conflict rule:** Any conflict → STOP. Resolve manually. Never use `--adopt`. Use the fake-home validation from Task 3b to debug package layout independently of the real-home state.

**Status:** [ ] Not started

---

#### Task 3e — Post-Migration Form Check (read-only)

**Description:** Confirm the migration produced the expected layout: `~/.config/zsh` is a real directory; `index.zsh` and `shared.zsh` are per-file symlinks resolving into the repo.

**Commands:**

```bash
# Confirm real directory
[[ -d "$HOME/.config/zsh" && ! -L "$HOME/.config/zsh" ]] && echo "real-dir-ok" || echo "NOT-real-dir — investigate"

# Confirm per-file symlinks for the two promoted managed files
for f in index.zsh shared.zsh; do
  [[ -L "$HOME/.config/zsh/$f" ]] && echo "$f -> $(readlink "$HOME/.config/zsh/$f")" || echo "$f MISSING or not a symlink"
done
# expect: each resolves into .../stow/common/zsh/.config/zsh/<filename>

# Confirm local.zsh — if present, must be a real file, never a symlink
p="$HOME/.config/zsh/local.zsh"
if   [[ -L "$p" ]]; then echo "local.zsh (SYMLINK — WRONG)"
elif [[ -e "$p" ]]; then echo "local.zsh (real file — ok)"
else echo "local.zsh (absent — ok, optional)"; fi
```

**Expected result:** `real-dir-ok`; `index.zsh` and `shared.zsh` each print a `->` resolution pointing into the repo package dir; `local.zsh` is absent or is a real file.

**Status:** [ ] Not started

---

### Phase 4 — Validation

All commands are read-only. No `$HOME` content is dumped. Commands derived from Architecture 0008 §12.

---

#### Task 4a — Activation Load-Marker Check

**Description:** Confirm the managed layer loads cleanly in an interactive shell.

**Commands:**

```bash
zsh -ic 'echo zsh-ok'
# expect: exits 0, prints "zsh-ok"
```

If this prints an error or does not exit 0, check `index.zsh` and `shared.zsh` for syntax issues:

```bash
zsh -n stow/common/zsh/.config/zsh/index.zsh
zsh -n stow/common/zsh/.config/zsh/shared.zsh
```

**Status:** [ ] Not started

---

#### Task 4b — Guard Fail-Safe Check

**Description:** Confirm zsh still starts cleanly without rc files (covers partial-adoption machines and validates the guarded design).

**Commands:**

```bash
zsh --no-rcs -c 'echo zsh-norc-ok'
# expect: exits 0, prints "zsh-norc-ok"
```

**Status:** [ ] Not started

---

#### Task 4c — Managed-File Symlink Resolution Check

**Description:** Confirm each expected per-file symlink resolves into the repo package dir and is readable.

**Commands:**

```bash
for f in index.zsh shared.zsh; do
  p="$HOME/.config/zsh/$f"
  if [[ -L "$p" ]]; then
    echo "$f -> $(readlink "$p")"
  elif [[ -e "$p" ]]; then
    echo "$f (real file — unexpected for managed)"
  else
    echo "$f (absent)"
  fi
done
# expect: each prints "$f -> ...stow/common/zsh/.config/zsh/$f"

[[ -r "$HOME/.config/zsh/index.zsh" ]] && echo "index.zsh present (activation enabled)" \
                                        || echo "index.zsh absent (layer inert — investigate)"
```

**Status:** [ ] Not started

---

#### Task 4d — Git Safety Re-check

**Description:** Confirm no real managed file appears as tracked in `git ls-files`.

**Commands:**

```bash
git ls-files stow/common/zsh/.config/zsh/ | grep -vE '\.example$|\.gitignore$'
# expect: no output — only .example and .gitignore are tracked
# if any file is printed, STOP and investigate
```

**Status:** [ ] Not started

---

#### Task 4e — `local.zsh` Not Tracked Check

**Description:** Confirm `local.zsh` is git-ignored and not tracked.

**Commands:**

```bash
git -C "$(git rev-parse --show-toplevel)" check-ignore \
  stow/common/zsh/.config/zsh/local.zsh \
  && echo "local.zsh ignored-ok" || echo "local.zsh NOT ignored — investigate"

git ls-files --error-unmatch stow/common/zsh/.config/zsh/local.zsh 2>/dev/null \
  && echo "TRACKED — WRONG" || echo "local.zsh not tracked — ok"
```

**Status:** [ ] Not started

---

#### Task 4f — Optional-Tool Guard Check

**Description:** Confirm `shared.zsh` uses `command -v` guards for all tool `eval` lines. No unconditional eval.

**Commands:**

```bash
# Check for unconditional eval lines (should be empty)
grep -nE "^[[:space:]]*eval " stow/common/zsh/.config/zsh/shared.zsh \
  | grep -v "command -v" \
  | grep -v "zinit" \
  | grep -v "^[^:]*:[0-9]*:[[:space:]]*#"
# expect: no output

# Confirm the three expected guards are present
grep -nE "command -v (fzf|zoxide|eza)" stow/common/zsh/.config/zsh/shared.zsh
# expect: three matching lines
```

**Status:** [ ] Not started

---

### Phase 5 — Documentation Updates

Agent performs these file edits (repo-internal, no `$HOME` change).

---

#### Task 5.1 — Update `docs/stow-usage.md` Zsh Section

**Description:** Update the zsh adoption section of `docs/stow-usage.md` to reflect `--no-folding` as the current intended approach. Changes required:

1. Update the intro paragraph: `--no-folding` is intended for the zsh package (ADR-0024); `~/.config/zsh` is a real directory with per-file symlinks, not a directory-fold.
2. Update Step 3 (dry-run) — replace bare stow command with `--no-folding --simulate`:
   `stow --dir=stow/common --target="$HOME" --no-folding --simulate zsh`
3. Update Step 4 (live stow) — replace bare stow command with `--no-folding`:
   `stow --dir=stow/common --target="$HOME" --no-folding zsh`
4. Update Step 6 (verify adoption) — add real-directory check:
   `[[ -d "$HOME/.config/zsh" && ! -L "$HOME/.config/zsh" ]] && echo "real-dir-ok" || echo "NOT-real-dir"`
5. Add ADR-0024 reference note near the top of the zsh adoption section.
6. Add `local.zsh` usage note: created directly in `~/.config/zsh/` by the user with their editor — not copied from the repo; never stowed; never committed; sourced last by `index.zsh`.

**File to modify:** `docs/stow-usage.md`

**Validate:**

```bash
grep -c "\-\-no-folding" docs/stow-usage.md
# expect: ≥ 2

grep -c "real directory\|real-dir-ok" docs/stow-usage.md
# expect: ≥ 1

grep "ADR-0024" docs/stow-usage.md
# expect: reference present
```

**Status:** [ ] Not started

---

#### Task 5.2 — Update `docs/zsh-migration.md`

**Description:** Update `docs/zsh-migration.md` to replace folding-based stow steps with the `--no-folding` migration runbook and per-file layout. Changes required:

1. Add a migration context section stating the migration converts from directory-fold to `--no-folding` per-file symlinks (ADR-0024, Review 0024 Issue 3).
2. Replace any bare `stow --dir=stow/common --target="$HOME" zsh` commands with the `--no-folding` form. All stow commands retain `⚠️ MANUAL STEP` markers and preceding `--simulate` dry-runs.
3. Add the fold-removal step (before `--no-folding` stow):

   ⚠️ MANUAL STEP — dry-run first:
   ```bash
   stow --dir=stow/common --target="$HOME" --simulate --delete zsh
   ```
   ⚠️ MANUAL STEP — run after reviewing dry-run:
   ```bash
   stow --dir=stow/common --target="$HOME" --delete zsh
   ```

4. Update the expected post-stow layout to describe a real directory with per-file symlinks. Include the post-migration form check commands from Task 3e.
5. Update the `local.zsh` section: real file outside the repo, created directly in `~/.config/zsh/` with the user's editor — primary boundary is physical (outside repo tree), not just `.gitignore` (ADR-0026).
6. Update the rollback section: unstow removes per-file links; named-file `rm -f` only (never `rm -rf ~/.config/zsh`); optional re-fold step per Architecture 0008 §13.

**File to modify:** `docs/zsh-migration.md`

**Validate:**

```bash
grep -c "\-\-no-folding" docs/zsh-migration.md
# expect: ≥ 3

grep "rm -rf.*config/zsh" docs/zsh-migration.md
# expect: no output (rm -rf ~/.config/zsh must NOT appear as an instruction)

grep "real directory\|real-dir-ok\|NOT-real-dir" docs/zsh-migration.md
# expect: ≥ 1 match
```

**Status:** [ ] Not started

---

### Phase 6 — Rollback Note

This is a reference section, not a task to execute. Do not run any of these commands unless actively rolling back a failed or unwanted migration.

**Summary (Architecture 0008 §13):**

1. **Disable the layer (one step, instant):** comment or delete the three delimited lines of the managed include block in `~/.zshrc`. New shells start clean; the managed layer is inert.

2. **Unstow per-file links:**

   ⚠️ MANUAL STEP — dry-run first:
   ```bash
   stow --dir=stow/common --target="$HOME" --simulate --delete zsh
   ```
   ⚠️ MANUAL STEP — run after reviewing dry-run:
   ```bash
   stow --dir=stow/common --target="$HOME" --delete zsh
   ```

3. **Remove copied managed files by name only — NEVER `rm -rf ~/.config/zsh`:**

   ⚠️ MANUAL STEP — removes ONLY these named files:
   ```bash
   rm -f "$HOME/.config/zsh/index.zsh" "$HOME/.config/zsh/shared.zsh" \
         "$HOME/.config/zsh/macos.zsh" "$HOME/.config/zsh/arch.zsh" \
         "$HOME/.config/zsh/omp.zsh"
   # Optional — only if you want to remove your private local.zsh:
   rm -f "$HOME/.config/zsh/local.zsh"
   ```

4. **Re-fold fallback (optional):**

   ⚠️ MANUAL STEP — dry-run first:
   ```bash
   stow --dir=stow/common --target="$HOME" --simulate zsh
   ```
   ⚠️ MANUAL STEP — run after reviewing dry-run:
   ```bash
   stow --dir=stow/common --target="$HOME" zsh
   ```

5. **Verify:**
   ```bash
   zsh --no-rcs -c 'echo ok'
   ls -l "$HOME/.config/zsh"
   ```

---

## Files Affected

**Modified (status field only — Phase 0):**
- `docs/prd/0008-zsh-managed-layer-activation.md` — `**Status:** Draft` → `**Status:** Approved`
- `docs/architecture/0008-zsh-managed-layer-activation-architecture.md` — `**Status:** Draft` → `**Status:** Approved`

**Created (Phase 1 — ADRs):**
- `docs/decisions/0025-managed-zsh-files-git-ignored-linked-by-presence.md`
- `docs/decisions/0026-local-zsh-real-file-outside-repo-never-symlinked.md`
- `docs/decisions/0027-zshrc-stays-unmanaged-no-folding-migration-does-not-touch-it.md`

**Modified (Phase 1 — README index):**
- `docs/decisions/README.md` — three new rows appended to the index table

**Created (Phase 2 — repo-internal managed file copies; git-ignored, not committed):**
- `stow/common/zsh/.config/zsh/index.zsh` — copied from `index.zsh.example`
- `stow/common/zsh/.config/zsh/shared.zsh` — copied from `shared.zsh.example`

**No `$HOME` files created or modified by the agent.** Phase 3 stow steps are `⚠️ MANUAL STEP` and modify `$HOME` only when the user runs them explicitly.

**Modified (Phase 5 — documentation):**
- `docs/stow-usage.md` — zsh section updated for `--no-folding`, per-file layout, `local.zsh` note
- `docs/zsh-migration.md` — fold-removal step, `--no-folding` restow, per-file layout, updated rollback

---

## Safety Checks

- [ ] No task creates a symlink in `$HOME` automatically — all stow commands touching `$HOME` are `⚠️ MANUAL STEP`.
- [ ] No task runs `stow --adopt` — forbidden (AGENTS §8, ADR-0017).
- [ ] No task modifies `~/.zshrc` — the include block already present is sufficient.
- [ ] Every live stow command against `$HOME` is preceded by a `--simulate` dry-run reviewed before execution.
- [ ] Any dry-run that reports a conflict is a hard STOP — no bypass, no `--adopt`, no force.
- [ ] `rm -rf ~/.config/zsh` never appears as an instruction — rollback uses named-file `rm -f` only.
- [ ] No dependency installed (no `brew install`, `pacman`, `git clone`, `zinit` bootstrap) as part of this plan.
- [ ] Real managed files (`index.zsh`, `shared.zsh`) are git-ignored — confirmed by `git check-ignore` and `git ls-files` checks.
- [ ] `local.zsh` is never created by the agent — user-created real file outside the repo.
- [ ] All `$HOME` operations (Phase 3, rollback) require explicit user action.

---

## Privacy Checks

- [ ] No `$HOME` file content (especially `~/.zshrc`, `local.zsh`) is copied into any repo file or review.
- [ ] `shared.zsh` (copied from `.example`) contains only placeholder values in the shipped state — user fills in locally; never committed.
- [ ] `index.zsh` (copied from `.example`) contains no personal values — orchestration only.
- [ ] `local.zsh` does not exist in the repo and is never created by the agent.
- [ ] ADR content (Tasks 1.2–1.4) uses no real hostnames, paths, usernames, or credentials.

---

## Validation Commands (Full Suite)

Run from the repository root after Phase 3 is complete.

```bash
# 1. Activation load-marker check
zsh -ic 'echo zsh-ok'

# 2. Guard fail-safe check
zsh --no-rcs -c 'echo zsh-norc-ok'

# 3. Real directory check
[[ -d "$HOME/.config/zsh" && ! -L "$HOME/.config/zsh" ]] && echo "real-dir-ok" || echo "NOT-real-dir"

# 4. Per-file symlink resolution check
for f in index.zsh shared.zsh; do
  p="$HOME/.config/zsh/$f"
  if [[ -L "$p" ]]; then echo "$f -> $(readlink "$p")"
  elif [[ -e "$p" ]]; then echo "$f (real file — unexpected for managed)"
  else echo "$f (absent)"; fi
done

# 5. local.zsh form check (must not be a symlink if present)
p="$HOME/.config/zsh/local.zsh"
if   [[ -L "$p" ]]; then echo "local.zsh (SYMLINK — WRONG)"
elif [[ -e "$p" ]]; then echo "local.zsh (real file — ok)"
else echo "local.zsh (absent — ok, optional)"; fi

# 6. Git safety re-check
git ls-files stow/common/zsh/.config/zsh/ | grep -vE '\.example$|\.gitignore$'
# expect: no output

# 7. local.zsh not tracked
git -C "$(git rev-parse --show-toplevel)" check-ignore \
  stow/common/zsh/.config/zsh/local.zsh \
  && echo "local.zsh ignored-ok"
git ls-files --error-unmatch stow/common/zsh/.config/zsh/local.zsh 2>/dev/null \
  && echo "TRACKED — WRONG" || echo "local.zsh not tracked — ok"

# 8. Optional-tool guard check
grep -nE "command -v (fzf|zoxide|eza)" stow/common/zsh/.config/zsh/shared.zsh
# expect: three guarded lines

# 9. No active install/clone line in managed files
grep -RnE "brew install|pacman -S|git clone" \
  stow/common/zsh/.config/zsh/index.zsh \
  stow/common/zsh/.config/zsh/shared.zsh 2>/dev/null \
  | grep -v '^[^:]*:[0-9]*:[[:space:]]*#' \
  || echo "OK: no active install/clone lines"
```

---

## Completion Criteria

- [ ] PRD 0008 `**Status:**` = Approved
- [ ] Architecture 0008 `**Status:**` = Approved
- [ ] ADR-0024 confirmed Accepted (read-only check logged)
- [ ] ADR-0025 created at `docs/decisions/0025-managed-zsh-files-git-ignored-linked-by-presence.md`, Status Accepted
- [ ] ADR-0026 created at `docs/decisions/0026-local-zsh-real-file-outside-repo-never-symlinked.md`, Status Accepted
- [ ] ADR-0027 created at `docs/decisions/0027-zshrc-stays-unmanaged-no-folding-migration-does-not-touch-it.md`, Status Accepted
- [ ] `docs/decisions/README.md` index includes ADR-0025, ADR-0026, ADR-0027
- [ ] `stow/common/zsh/.config/zsh/index.zsh` exists on disk and is git-ignored (not tracked)
- [ ] `stow/common/zsh/.config/zsh/shared.zsh` exists on disk and is git-ignored (not tracked)
- [ ] `git ls-files stow/common/zsh/.config/zsh/ | grep -vE '\.example$|\.gitignore$'` produces no output
- [ ] `~/.config/zsh` is NOT a symlink (`real-dir-ok`)
- [ ] `~/.config/zsh/index.zsh` is a per-file symlink resolving into the repo package dir
- [ ] `~/.config/zsh/shared.zsh` is a per-file symlink resolving into the repo package dir
- [ ] `local.zsh` is not tracked by git; not a symlink if present
- [ ] `zsh -ic 'echo zsh-ok'` exits 0 and prints `zsh-ok`
- [ ] `zsh --no-rcs -c 'echo zsh-norc-ok'` exits 0
- [ ] `docs/stow-usage.md` shows `--no-folding` as the zsh stow command and per-file layout
- [ ] `docs/zsh-migration.md` reflects `--no-folding`, fold-removal step, per-file layout, and `local.zsh` as real file outside repo
- [ ] No `stow --adopt` used at any step
- [ ] No `rm -rf ~/.config/zsh` used at any step
- [ ] No dependency installed; no Zinit cloned; no OMP activated
- [ ] Plan status remains Approved until Reviewer marks it Complete

---

## Recommended Next Step

Builder implements Phases 0–5 in order, running per-task validation after each phase, committing per logical group, and stopping without changing the plan status. Phase 3 tasks 3c and 3d are `⚠️ MANUAL STEP` — the Builder presents the commands; the user runs them. A follow-up implementation review (`docs/reviews/` next number) verifies all completion criteria and, if all verdicts PASS, marks this plan Complete.
