# Plan: Corrective — Stow Directory Conflict and Fake-Home Validation

**Number:** 0009
**Status:** Complete
**Date:** 2026-06-17
**PRD:** 0005 (related)
**Architecture:** 0005 (related)

---

## Objective

Document the expected Stow directory-ownership conflict that occurs when
`~/.config/omp` already exists, introduce a safe fake-home validation alternative,
and update all affected documents to reflect this finding.

---

## Context

Running `task dry-run AREA=common PACKAGE=omp` against a real `$HOME` that already
contains `~/.config/omp` produces:

```
WARNING! stowing omp would cause conflicts:
  * existing target is not owned by stow: .config/omp
All operations aborted.
```

This is correct Stow behaviour — it refuses to claim a directory it does not own.
It is not a defect in the implementation. It is a documentation gap: the dry-run
guidance did not warn that directory-level ownership conflicts differ from file-level
conflicts and require a different resolution path.

Safe alternative: use a temporary fake `$HOME` target so the package layout can be
verified without touching the real home directory.

---

## Assumptions

- No stow install (non-simulate) commands are run.
- No real `~/.config/omp` is modified, moved, deleted, or read.
- No real `~/.config/omp/omp.toml` is inspected or copied.
- All changes are documentation and decision records only.
- The fake-home validation is run once as part of this plan to confirm the package
  layout, then `$TEST_HOME` is removed.

---

## Ordered Tasks

### Task 1 — Update `docs/stow-usage.md`: extend "Conflict handling" section

Extend the existing "Conflict handling" section to cover the `not owned by stow`
directory-ownership error. Add the fake-home validation technique as a safe alternative
to real-home dry-runs for packages that commonly target pre-existing directories.

**Insert after the existing `--adopt` paragraph (around line 90):**

```markdown
### Directory-ownership conflicts

Stow may also report a directory-level conflict:

```
WARNING! stowing <package> would cause conflicts:
  * existing target is not owned by stow: .config/<name>
All operations aborted.
```

This means the target directory (`~/.config/<name>`) already exists and was not
created by Stow. Stow refuses to claim it. This is correct behaviour — **do not use
`--adopt`**.

Resolution options:
1. **Back up and remove the directory**, then re-run the dry-run. Stow will create the
   directory and its symlinks cleanly.
2. **Compare manually**: inspect the existing directory and the package template side
   by side. Migrate intentionally, file by file.
3. **Defer stowing**: keep the real directory as-is and use the `.example` template
   for reference only until you are ready to migrate.

### Fake-home validation

When the real `$HOME` contains a conflicting directory, use a temporary fake home to
verify the package layout without touching real files:

```bash
TEST_HOME="$(mktemp -d)"
stow --dir=stow/common --target="$TEST_HOME" --simulate omp
rm -rf "$TEST_HOME"
```

This confirms Stow would create the correct symlinks on a clean machine, without
risking any real home directory change. Always remove `$TEST_HOME` after validation.
```

**Validation:**

```bash
grep -n 'not owned by stow' docs/stow-usage.md
# Expected: line number present

grep -n 'TEST_HOME' docs/stow-usage.md
# Expected: at least one line in the Conflict handling section
```

---

### Task 2 — Update `docs/stow-usage.md`: OMP Step 3 conflict guidance

Replace the brief conflict note in the OMP "Step 3 — Dry-run the omp package" section
with full guidance covering:
- The expected directory-ownership conflict for users with an existing `~/.config/omp`.
- The fake-home alternative for safe package validation.
- Explicit instruction not to stow the package if `~/.config/omp` already exists with
  a real config until the user is ready to migrate.

**Current text (around line 407–408):**

```
If you see a conflict on `~/.config/omp/omp.toml` (your existing real config), back it
up and remove it before proceeding. Do not use `--adopt`. See "Conflict handling" above.
```

**Replace with:**

```markdown
#### If `~/.config/omp` already exists

Stow will report:

```
WARNING! stowing omp would cause conflicts:
  * existing target is not owned by stow: .config/omp
All operations aborted.
```

This is expected and correct — Stow refuses to claim a directory it does not own.
**Do not use `--adopt`.**

Options:
- **Defer**: the `omp.toml.example` template is available for reference. Do not stow
  yet. Compare your real `~/.config/omp/omp.toml` with the template manually and
  migrate when ready.
- **Migrate**: back up your real `~/.config/omp/` contents, remove the directory,
  copy the example to `omp.toml`, customize, then re-run the dry-run.

To verify the package layout without touching real files, use fake-home validation:

```bash
TEST_HOME="$(mktemp -d)"
stow --dir=stow/common --target="$TEST_HOME" --simulate omp
rm -rf "$TEST_HOME"
```

See "Conflict handling" and "Fake-home validation" above for full detail.
```

**Validation:**

```bash
grep -n 'existing target is not owned by stow' docs/stow-usage.md
# Expected: present in both Conflict handling section and OMP Step 3

grep -n 'TEST_HOME' docs/stow-usage.md
# Expected: present in both sections

grep -n 'adopt' docs/stow-usage.md | grep -i 'forbid\|do not\|never'
# Expected: --adopt is forbidden language present
```

---

### Task 3 — Add correction note to `docs/plans/0008-implement-oh-my-posh-support.md`

Append a post-completion correction note recording that real-home dry-run validation
produced an expected directory-ownership conflict, and that this is addressed in Plan
0009.

**Append after the Completion Criteria section:**

```markdown
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
```

**Validation:**

```bash
grep -n 'Post-Completion Correction' docs/plans/0008-implement-oh-my-posh-support.md
# Expected: section heading present
```

---

### Task 4 — Update `docs/reviews/0015-oh-my-posh-implementation-review.md`

Add the real-home dry-run conflict as a non-blocking post-review finding. Append to
the "Non-Blocking Observations" section.

**Append to existing Non-Blocking Observations:**

```markdown
4. **Expected directory-ownership conflict on real-home dry-run (post-review finding).**
   Running `task dry-run AREA=common PACKAGE=omp` against a machine where
   `~/.config/omp` already exists produces:
   ```
   WARNING! stowing omp would cause conflicts:
     * existing target is not owned by stow: .config/omp
   All operations aborted.
   ```
   This is correct Stow behaviour — not a defect. The package layout is valid and
   confirmed by fake-home validation (Plan 0009). `docs/stow-usage.md` updated in
   Plan 0009 to document this conflict class and the fake-home alternative. No `$HOME`
   files were modified. No `--adopt` was used.
```

**Validation:**

```bash
grep -n 'post-review finding' docs/reviews/0015-oh-my-posh-implementation-review.md
# Expected: present in Non-Blocking Observations
```

---

### Task 5 — Create `docs/decisions/0017-use-fake-home-for-stow-validation.md`

Record the fake-home validation technique as an accepted ADR. Note: ADR-0013 is already
taken (`include-based-git-config-strategy`). Next available number is 0017.

**Content:**

```markdown
# Decision: Use Fake Home for Stow Validation When Real Home Has Conflicts

**Number:** 0017
**Date:** 2026-06-17
**Status:** Accepted
**Context:** Plan 0009 — corrective after OMP package dry-run conflict

## Context

Running `stow --simulate` against `$HOME` is the standard way to preview what a
package would do. For packages whose target paths (`~/.config/<name>`) commonly
already exist as real directories on a developer's machine, the dry-run produces:

```
WARNING! stowing <package> would cause conflicts:
  * existing target is not owned by stow: .config/<name>
All operations aborted.
```

This is correct Stow behaviour. The package layout may be completely valid — the
conflict only means the directory existed before Stow tried to claim it. A real-home
dry-run alone cannot confirm layout validity in this case.

## Decision

For packages targeting paths that commonly already exist (e.g., `~/.config/omp/`,
`~/.config/git/`), prefer fake-home validation to confirm package layout:

```bash
TEST_HOME="$(mktemp -d)"
stow --dir=stow/<area> --target="$TEST_HOME" --simulate <package>
rm -rf "$TEST_HOME"
```

Rules:
- Always remove `$TEST_HOME` immediately after validation.
- `$TEST_HOME` must be created with `mktemp -d` — never reuse a path.
- Real-home dry-run is still useful to surface the conflict explicitly; it is not
  replaced, only supplemented.
- `--adopt` remains forbidden. A conflict is a stop signal, not a flag to bypass.

## Consequences

- Package layout can be verified without a clean home directory.
- Conflicts on real home are still surfaced and remain stop signals.
- `--adopt` prohibition is unchanged and absolute.
- `docs/stow-usage.md` documents this technique under "Conflict handling".
- Applies to the OMP package and any future package whose target path may already
  exist.
```

**Validation:**

```bash
ls docs/decisions/0017-use-fake-home-for-stow-validation.md
# Expected: file present

grep -n 'Accepted' docs/decisions/0017-use-fake-home-for-stow-validation.md
# Expected: Status: Accepted present
```

---

### Task 6 — Run fake-home validation

Run the fake-home dry-run to confirm the `omp` package layout is valid. Remove
`$TEST_HOME` immediately after.

```bash
TEST_HOME="$(mktemp -d)"
stow --dir=stow/common --target="$TEST_HOME" --simulate omp
rm -rf "$TEST_HOME"
```

**Expected output:** Stow lists the symlinks it would create under `$TEST_HOME` with
no conflicts, then exits cleanly.

**This is the only command in this plan that executes Stow.** It targets a temporary
directory, not `$HOME`. It uses `--simulate`. It is safe to run.

**Validation:** observe output — no `WARNING` or `conflicts` in Stow output.

---

## Files Affected

| File | Action |
|---|---|
| `docs/stow-usage.md` | modified (Tasks 1 and 2) |
| `docs/plans/0008-implement-oh-my-posh-support.md` | modified (Task 3) |
| `docs/reviews/0015-oh-my-posh-implementation-review.md` | modified (Task 4) |
| `docs/decisions/0017-use-fake-home-for-stow-validation.md` | created (Task 5) |

No files outside the repository are modified.
No symlinks created.
No real `$HOME` paths touched.
No stow install (non-simulate) run.

---

## Safety Checks

Before starting:

- [ ] `stow/common/omp/` exists and contains `.config/omp/.gitignore` and
  `omp.toml.example`.
- [ ] `~/.config/omp/omp.toml` is NOT inspected, read, or opened at any point.
- [ ] No `--adopt` flag used in any command.

During execution:

- [ ] Task 6 fake-home validation: confirm `$TEST_HOME` is removed after the run.
- [ ] After each task, run `git status` to confirm only expected files are changed.

---

## Validation Commands

```bash
# Task 1 + 2: stow-usage.md conflict guidance present
grep -n 'not owned by stow' docs/stow-usage.md
grep -n 'TEST_HOME' docs/stow-usage.md
grep -n 'Do not use.*adopt\|adopt.*forbidden' docs/stow-usage.md

# Task 3: plan correction note present
grep -n 'Post-Completion Correction' docs/plans/0008-implement-oh-my-posh-support.md

# Task 4: review observation present
grep -n 'post-review finding' docs/reviews/0015-oh-my-posh-implementation-review.md

# Task 5: ADR created
ls docs/decisions/0017-use-fake-home-for-stow-validation.md
grep -n 'Accepted' docs/decisions/0017-use-fake-home-for-stow-validation.md

# Overall
git status
git diff --staged
```

---

## Rollback Strategy

All changes are documentation-only and repository-internal.

```bash
# Undo modified files
git checkout -- docs/stow-usage.md
git checkout -- docs/plans/0008-implement-oh-my-posh-support.md
git checkout -- docs/reviews/0015-oh-my-posh-implementation-review.md

# Remove new ADR
git rm --cached docs/decisions/0017-use-fake-home-for-stow-validation.md
rm docs/decisions/0017-use-fake-home-for-stow-validation.md
```

No `$HOME` rollback needed — nothing in `$HOME` is changed.

---

## Completion Criteria

- [ ] `docs/stow-usage.md` "Conflict handling" section covers directory-ownership
  conflicts and fake-home validation.
- [ ] `docs/stow-usage.md` OMP Step 3 covers the expected conflict for users with
  existing `~/.config/omp/` and offers defer/migrate/fake-home paths.
- [ ] `docs/plans/0008-implement-oh-my-posh-support.md` has post-completion note.
- [ ] `docs/reviews/0015-oh-my-posh-implementation-review.md` has post-review finding.
- [ ] `docs/decisions/0017-use-fake-home-for-stow-validation.md` created and accepted.
- [ ] Fake-home validation runs cleanly with no conflicts and no warnings.
- [ ] `$TEST_HOME` removed after validation.
- [ ] `~/.config/omp/omp.toml` untouched throughout.
- [ ] No `--adopt` used anywhere.
