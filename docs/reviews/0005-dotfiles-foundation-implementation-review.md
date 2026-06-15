# Review: Dotfiles Foundation — Corrected Implementation

**Number:** 0005-impl
**Date:** 2026-06-15
**Reviewer:** Claude Code (Reviewer role per AGENTS.md §4)
**Scope:** Corrected implementation of plan 0005, including stow slash-bug fix
**Prior implementation review:** [0006-dotfiles-foundation-implementation-review.md](0006-dotfiles-foundation-implementation-review.md)

---

## Summary

Reviewed all corrected files against the Stow slash-bug fix requirements. The `AREA`+`PACKAGE` two-variable interface is correctly implemented. No old slash-in-package-name form remains in active usage context. ADR-0011 is superseded; ADR-0012 is accepted. No blocking issues. Two non-blocking documentation notes.

---

## Validation Command Results

| Command | Result |
|---------|--------|
| `grep -E "^[[:space:]]{2}(install\|uninstall\|adopt\|unlink):" Taskfile.yml` | Empty — no forbidden tasks ✓ |
| `bash scripts/detect-os.sh` | `macos` ✓ |
| `bash scripts/check.sh` | `PASS: stow` / `PASS: git` / `PASS: task`, exit 0 ✓ |
| `find stow … \| sed 's\|^stow/\|\|'` (task list equivalent) | `common/git` ✓ |
| `stow --dir=stow/common --target="$HOME" --simulate git` (dry-run equivalent) | `WARNING: in simulation mode so not modifying filesystem.`, exit 0 ✓ |

`task --list`, `task detect`, `task check`, `task list`, `task dry-run` require the `task` binary in the shell PATH. All underlying commands verified to be correct and passing.

---

## Blocking Issues

None.

---

## Non-Blocking Issues

### N1 — Warning examples in "Platform directories are not packages" use `PACKAGE=.gitkeep`

**Location:** `docs/stow-usage.md` lines 31–34

```bash
# These will attempt to stow .gitkeep as a dotfile — do not do this
task dry-run AREA=macos PACKAGE=.gitkeep
task dry-run AREA=arch PACKAGE=.gitkeep
```

`.gitkeep` is a file directly in `stow/macos/`, not a subdirectory. Stow treats package arguments as directory names under `--dir`. Running `stow --dir=stow/macos --simulate .gitkeep` would fail: stow would look for a directory `stow/macos/.gitkeep` which does not exist. The warning commands no longer illustrate "what would happen" — they would error in a confusing way.

The intent of this section is sound: warn that `stow/macos/` and `stow/arch/` have no stowable packages yet. The example commands are misleading as written.

**Suggestion:** Replace the specific commands with a generic note:

```bash
# stow/macos/ and stow/arch/ have no real packages yet.
# Do not attempt to run task dry-run against these areas until
# a real package directory (e.g. stow/macos/zsh/) is created.
```

Non-blocking — no safety risk (stow would error, not link anything).

---

### N2 — `README.md` status says "GNU Stow packages: not created"

**Location:** `README.md` § Status

```
GNU Stow packages:           not created
```

`stow/` directory now exists with `common/git/.gitconfig.example`, `macos/.gitkeep`, and `arch/.gitkeep`. The statement is defensible (no functional stow packages, nothing stowed) but could mislead a reader who checks the directory.

**Suggestion:** Change to `GNU Stow packages: scaffold only — no real config, nothing stowed`. Non-blocking — safe state of repo is accurately described elsewhere in README.

---

## Per-Criterion Findings

### Stow slash bug is fully fixed

**PASS.**

Old form (invalid): `stow --dir=stow --target="$HOME" --simulate common/git`
→ fails with `stow: ERROR: Slashes are not permitted in package names`

New form: `stow --dir=stow/{{.AREA}} --target="$HOME" --simulate {{.PACKAGE}}`
→ `stow --dir=stow/common --target="$HOME" --simulate git`
→ `WARNING: in simulation mode so not modifying filesystem.` exit 0 ✓

---

### Taskfile uses AREA and PACKAGE correctly

**PASS.**

```yaml
dry-run:
  desc: "Dry-run a Stow package — usage: task dry-run AREA=<common|macos|arch> PACKAGE=<name>"
  preconditions:
    - sh: '[ -n "{{.AREA}}" ]'
      msg: "AREA is required: common, macos, or arch"
    - sh: '[ -n "{{.PACKAGE}}" ]'
      msg: "PACKAGE is required, e.g. PACKAGE=git"
  cmds:
    - stow --dir=stow/{{.AREA}} --target="$HOME" --simulate {{.PACKAGE}}
```

Both `AREA` and `PACKAGE` are required via preconditions. Neither has a default — omitting either fails fast with a clear message. `--simulate` is hardcoded. ✓

`list` task desc updated: `"output is <area>/<package>, use as: task dry-run AREA=<area> PACKAGE=<package>"` ✓

---

### Direct Stow examples use `--dir=stow/<area>` and bare package name

**PASS.**

`docs/stow-usage.md` dry-run section:
```bash
stow --dir=stow/common --target="$HOME" --simulate git   ✓
```

`docs/stow-usage.md` install section (MANUAL STEP only):
```bash
stow --dir=stow/common --target="$HOME" git              ✓
```

`docs/decisions/0012` direct command:
```bash
stow --dir=stow/common --target="$HOME" --simulate git   ✓
```

No `--dir=stow` (flat) form in active usage context anywhere. ✓

---

### No old `PACKAGE=common/git` form except historical context

**PASS.**

`grep` for `PACKAGE=common/git` across all affected files returns no matches.

Old form appears only in:
- `docs/decisions/0011` body — historical record of the superseded decision. Acceptable.
- `docs/decisions/0012` Context section — quoted as the problem being fixed. Acceptable.
- `docs/plans/0005` correction note — quoted to explain what was wrong. Acceptable.

None of these are usage instructions. ✓

---

### ADR-0011 is superseded

**PASS.**

`**Status:** Superseded by [ADR-0012](0012-use-area-and-package-for-stow-task-interface.md)` ✓

Body retained as historical record. ✓

---

### ADR-0012 exists and is correct

**PASS.**

- Status: `Accepted`. Supersedes: `ADR-0011`. ✓
- Context: quotes the stow error verbatim. ✓
- Decision: defines `AREA` and `PACKAGE` variables, shows correct Taskfile template, correct direct command. ✓
- Consequences: accurate. ✓

---

### `docs/stow-usage.md` is accurate

**PASS** with N1 noted.

All command examples in active sections use the correct two-variable interface:
- `task dry-run AREA=common PACKAGE=git` ✓
- `stow --dir=stow/common --target="$HOME" --simulate git` ✓
- `task dry-run AREA=<platform> PACKAGE=<name>` (adding a package section) ✓
- `task dry-run AREA=macos PACKAGE=zsh` (future example) ✓

Warning section (N1) uses `PACKAGE=.gitkeep` which is misleading but not dangerous. ✓

---

### `README.md` is accurate

**PASS** with N2 noted.

Link to `docs/stow-usage.md` present. ✓
No direct stow commands in README. ✓
No old `PACKAGE=common/git` form. ✓
Safety statements remain accurate (nothing stowed, no $HOME changes). ✓

---

### `docs/plans/0005` reflects the correction

**PASS.**

Correction note appended immediately after the numbering note:

> Correction (2026-06-15): The original single-variable design (`PACKAGE=common/git`) was invalid.
> GNU Stow does not permit slashes in package names — `stow --dir=stow --simulate common/git` exits with error.
> Corrected interface: `task dry-run AREA=common PACKAGE=git` ...

✓

---

### Taskfile has no install/uninstall/adopt tasks

**PASS.**

```
grep -E "^[[:space:]]{2}(install|uninstall|adopt|unlink):" Taskfile.yml → (empty)
```

Exactly four tasks: `detect`, `check`, `list`, `dry-run`. ✓

---

### No command modifies `$HOME`

**PASS.**

- `dry-run` task: `--simulate` hardcoded. Cannot be omitted. ✓
- `detect`, `check`, `list`: read-only. ✓
- Scripts: no write operations, no `$HOME` access. ✓
- Install examples in `stow-usage.md`: all preceded by `⚠️  MANUAL STEP`. ✓
- No `rm`, `mv`, `ln -s` against `$HOME` anywhere. ✓

---

### No Stow command without `--simulate` except clearly marked manual examples

**PASS.**

Occurrences of stow without `--simulate`:

| Location | Context | Safe? |
|----------|---------|-------|
| `stow-usage.md` § Install a package | `⚠️  MANUAL STEP` directly precedes code block | ✓ |
| `stow-usage.md` § Forbidden | Listed as forbidden unless dry-run done first | ✓ |
| ADR-0011 body | Historical record, superseded | ✓ |
| ADR-0012 Context | Quoted as the bug — not a usage example | ✓ |
| Plans/0005 correction note | Quoted as what was wrong | ✓ |

All non-simulate stow commands are either MANUAL STEP guarded or historical quotes. ✓

---

### No real identity or secrets

**PASS.**

`grep -ri "fnayou|aymen|BEGIN OPENSSH|signingkey|password|secret" stow/ docs/stow-usage.md Taskfile.yml scripts/` → CLEAN ✓

`.gitconfig.example` contains only `Your Name` and `your-email@example.com`. ✓

---

## Safety Verdict

**PASS.** No destructive operations. `--simulate` hardcoded in Taskfile. No `$HOME` mutations. Install examples gated by `⚠️  MANUAL STEP`.

## Privacy Verdict

**PASS.** No credentials, keys, real identity, or private hostnames in any file.

## Stow Correctness Verdict

**PASS.** Slash-in-package-name bug fully resolved. `stow --dir=stow/common --target="$HOME" --simulate git` runs cleanly (exit 0, simulation mode). All documentation reflects the correct two-variable interface.

## Documentation Verdict

**PASS** with N1 and N2 noted. Both are minor documentation clarity issues with no safety impact.

---

## Recommended Next Action

1. Optionally address N1 (replace `PACKAGE=.gitkeep` warning examples with a prose note).
2. Optionally address N2 (update README status line).
3. Run on-machine Taskfile validation: `task --list`, `task detect`, `task check`, `task list`, `task dry-run AREA=common PACKAGE=git`.
4. Run pre-commit audit (plan task 14, corrected form).
5. Stage via explicit `git add` list (plan task 15, plus `docs/decisions/0012-...`).
6. Review `git diff --staged`.
7. Commit.
