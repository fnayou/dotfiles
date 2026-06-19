# Review: Alacritty Configuration PRD and Architecture

**Number:** 0039
**Status:** Complete
**Date:** 2026-06-19
**Documents reviewed:**
- `docs/prd/0011-alacritty-configuration.md`
- `docs/architecture/0011-alacritty-configuration-architecture.md`

---

## Summary

Architecture review for the Alacritty configuration Stow package adoption (PRD 0011 /
Architecture 0011). This is a pre-implementation review: no files outside `docs/` have
been created yet. The review covers safety, privacy, documentation, cross-platform
correctness, and the three explicitly called-out portability decisions.

Two validation commands in the architecture contain concrete technical errors. Both are
non-blocking and correctable during planning.

---

## Blocking Issues

None.

---

## Non-Blocking Issues

### N1 — Fake-home simulation: `ls` after `--simulate` always fails

**File:** `docs/architecture/0011-alacritty-configuration-architecture.md`, Validation §2

**Evidence:** Tested on this machine with stow 2.4.1:

```
WARNING: in simulation mode so not modifying filesystem.
ls: /tmp/.../tmp.xxx/.config/: No such file or directory
```

`stow --simulate` prints what would happen but creates no files or directories. The
`ls -la "$FAKE_HOME/.config/alacritty/"` line that follows will always produce
"No such file or directory", causing a misleading error that a Builder cannot
distinguish from a real problem.

**Fix (two valid options):**

Option A — check exit code only (pure simulation, no filesystem write):
```bash
FAKE_HOME="$(mktemp -d)"
stow --dir=stow/common --target="$FAKE_HOME" --simulate --no-folding alacritty \
  && echo "Simulation passed: no conflicts detected"
rm -rf "$FAKE_HOME"
```

Option B — actually stow into the fake home, inspect, then clean up:
```bash
FAKE_HOME="$(mktemp -d)"
stow --dir=stow/common --target="$FAKE_HOME" --no-folding alacritty
ls -la "$FAKE_HOME/.config/alacritty/"
stow --dir=stow/common --target="$FAKE_HOME" --delete alacritty
rm -rf "$FAKE_HOME"
```

Option A is lighter. Option B provides stronger proof that symlinks land correctly.
Either is acceptable. Builder must pick one.

---

### N2 — `tomllib` requires Python 3.11+; system has Python 3.9.6

**File:** `docs/architecture/0011-alacritty-configuration-architecture.md`, Validation §1

**Evidence:**

```
$ python3 --version
Python 3.9.6
$ python3 -c "import tomllib"
ModuleNotFoundError: No module named 'tomllib'
```

`tomllib` was added to the standard library in Python 3.11. The architecture correctly
states "Python 3.11+", but the validation command will silently fail on this machine.

**Fix options (Builder picks one):**

Option A — add a version guard:
```bash
python3 -c "
import sys
if sys.version_info < (3, 11):
    print('SKIP: tomllib requires Python 3.11+, found ' + sys.version)
    sys.exit(0)
import tomllib
for f in sys.argv[1:]:
    with open(f, 'rb') as fh:
        tomllib.load(fh)
    print('OK: ' + f)
" stow/common/alacritty/.config/alacritty/alacritty.toml \
  stow/common/alacritty/.config/alacritty/catppuccin-macchiato.toml
```

Option B — use `tomli` backport if available, fall back gracefully:
```bash
python3 -c "
try:
    import tomllib
except ImportError:
    try:
        import tomli as tomllib
    except ImportError:
        print('SKIP: neither tomllib (3.11+) nor tomli backport available')
        raise SystemExit(0)
import sys
for f in sys.argv[1:]:
    with open(f, 'rb') as fh:
        tomllib.load(fh)
    print('OK: ' + f)
" stow/common/alacritty/.config/alacritty/alacritty.toml \
  stow/common/alacritty/.config/alacritty/catppuccin-macchiato.toml
```

Option A is cleaner given no `tomli` package is installed. The Planner should select
Option A and note that TOML validation via tomllib is skipped on this machine; manual
review of TOML syntax is the fallback.

---

### N3 — `alacritty --check-config` flag does not exist in Alacritty

**File:** `docs/architecture/0011-alacritty-configuration-architecture.md`, Validation §1

Alacritty does not expose a `--check-config` CLI flag. The architecture guards this
with "If Alacritty is available on the build machine, also run:" — but the flag itself
is incorrect regardless of whether Alacritty is installed.

Known Alacritty config validation approaches:
- Parse with `tomllib` / `tomli` (covered by the primary validation command).
- Run Alacritty normally and observe startup errors (not practical in CI or headless).
- Alacritty v0.13+ prints config parse errors to stderr on launch.

**Fix:** Remove the `alacritty --check-config` block from the architecture document or
replace with a comment noting that no offline validation CLI exists and `tomllib` is
the primary check.

---

### N4 — PRD install command missing `--no-folding`

**File:** `docs/prd/0011-alacritty-configuration.md`, §Stow Commands

The PRD's Step 2 install command:
```bash
stow --dir=stow/common --target="$HOME" alacritty
```
does not include `--no-folding`, which was decided in Architecture Decision 3. The
architecture's Manual Installation Reference is correct:
```bash
stow --dir=stow/common --target="$HOME" --no-folding alacritty
```

The PRD predates the architecture decision so this is expected. The architecture is the
authoritative source. Non-blocking — the Planner's implementation plan should reference
the architecture command, not the PRD command.

---

## Safety Verdict

**PASS**

- No `stow --adopt` present.
- No `rm`, `mv`, or `ln -s` targeting `$HOME` in automated context.
- All stow install and delete commands are explicitly marked `⚠️ MANUAL STEP`.
- Dry-run (`--simulate`) step precedes install in all documented sequences.
- Architecture explicitly states Builder must not run Stow against real `$HOME`.
- No dependency installation (Alacritty, fonts) anywhere in the architecture.
- The fake-home simulation command has a bug (N1) but the safety intent is correct and
  the fix is straightforward.

---

## Privacy Verdict

**PASS**

- Architecture documents config content (TERM, padding, font name, color scheme name)
  — none of these are secrets.
- No API keys, tokens, credentials, passwords, SSH keys, private hostnames, or
  work-specific settings appear anywhere.
- Privacy audit grep command is present and correct.
- Dependency audit grep command is present and correct.
- Real-file adoption is correctly justified: config carries no sensitive content.
- `.example` pattern correctly deferred to configs that carry secret risk.

---

## Documentation Verdict

**PASS**

- All decisions include tradeoff analysis with explicit rationale.
- `⚠️ MANUAL STEP` markers present before every stow install and delete command.
- Font install commands correctly labeled `# macOS` and `# Arch / EndeavourOS`.
- PRD cross-reference is accurate.
- Three specific portability decisions are reviewed below:

  **`/bin/zsh`:** Sound. Arch/EndeavourOS uses `usr-merge` since 2012; `/bin` is a
  symlink to `/usr/bin`, so `/bin/zsh` resolves to `/usr/bin/zsh`. No change needed.
  Risk documented for non-`usr-merge` Linux (non-goal for this PRD).

  **`option_as_alt = "Both"`:** Sound. Alacritty on Linux silently ignores this setting —
  it is parsed without error and has no behavioral effect. Keeping it in the common
  package avoids unnecessary platform split. Decision is correctly documented.

  **Import path (`~/.config/alacritty/catppuccin-macchiato.toml`):** Sound. After
  stowing, both files land in `~/.config/alacritty/`. The absolute `~`-path resolves
  correctly on macOS and Linux. Broader version compatibility than relative imports
  (v0.13+). No change needed.

---

## Recommended Next Action

Architecture is **approved** with four non-blocking notes.

Planner should:

1. Fix fake-home validation command (N1) — pick Option A or B.
2. Add Python version guard to `tomllib` validation (N2).
3. Remove `alacritty --check-config` block (N3).
4. Reference architecture install command (with `--no-folding`), not PRD command (N4).
5. Mark PRD 0011 status `Approved`.
6. Mark Architecture 0011 status `Approved`.
7. Produce implementation plan for Builder.
