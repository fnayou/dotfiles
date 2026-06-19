# Architecture: Alacritty Configuration Stow Package

**Number:** 0011
**Status:** Approved
**Date:** 2026-06-19
**PRD:** [0011-alacritty-configuration](../prd/0011-alacritty-configuration.md)

---

## Context

PRD 0011 scopes the adoption of the real personal Alacritty configuration into the
dotfiles repository as a managed Stow package. Two files are involved: the main config
(`alacritty.toml`) and a Catppuccin Macchiato theme (`catppuccin-macchiato.toml`).

Both files are safe personal preferences with no secrets, credentials, or work-specific
content. The PRD policy is to commit them as real managed files — not `.example` files.

The four portability decisions (shell path, `option_as_alt`, font, import path) were
resolved in the PRD. This architecture operationalises those decisions into a concrete
package layout, a Stow strategy, and a validation approach.

Out of scope for this architecture (per PRD 0011):

- Installing Alacritty or JetBrainsMono Nerd Font.
- Creating symlinks in `$HOME`.
- macOS-specific or Arch-specific override packages.
- Integration with zsh or Oh My Posh packages.
- Any keybinding changes.

---

## Proposed Structure

### Directory layout

```
stow/
└── common/
    └── alacritty/
        └── .config/
            └── alacritty/
                ├── alacritty.toml
                └── catppuccin-macchiato.toml
```

No `stow/macos/alacritty/` or `stow/arch/alacritty/` packages are created. See
Decision 1 for the rationale.

### File inventory

| File | Type | Stowed directly? | Maps to |
|------|------|-----------------|---------|
| `stow/common/alacritty/.config/alacritty/alacritty.toml` | Real managed config | Yes | `~/.config/alacritty/alacritty.toml` |
| `stow/common/alacritty/.config/alacritty/catppuccin-macchiato.toml` | Real managed theme | Yes | `~/.config/alacritty/catppuccin-macchiato.toml` |

Both files are committed to the repository and stowed directly. No rename or copy step
is required by the user before stowing.

### Symlink model (after stowing)

```
~/.config/alacritty/alacritty.toml
  → stow/common/alacritty/.config/alacritty/alacritty.toml

~/.config/alacritty/catppuccin-macchiato.toml
  → stow/common/alacritty/.config/alacritty/catppuccin-macchiato.toml
```

Stow creates the `~/.config/alacritty/` directory if absent. Both symlinks land in the
same directory, so the absolute import path in `alacritty.toml` resolves correctly
without modification.

---

## Design Decisions

### Decision 1: Package placement — `stow/common/` only, no platform split

**Option A: Single common package (`stow/common/alacritty/`)**

Pro: Simple — one package, one place to edit.
Pro: No duplication of shared settings across macOS and Arch packages.
Pro: `option_as_alt = "Both"` is silently ignored on Linux — no harm in keeping it.
Pro: `/bin/zsh` resolves on Arch via `usr-merge` — no Arch-specific override needed.
Con: If a macOS-only or Arch-only setting must be added in future, the package must be
  split or a supplementary override package created.

**Option B: Platform split (`stow/macos/alacritty/` + `stow/arch/alacritty/`)**

Pro: Explicit separation — macOS-only settings never appear in Arch config.
Con: Requires duplication of all shared settings across both packages.
Con: Higher maintenance burden for no current practical benefit.
Con: No setting in the current config actually breaks on either platform.

**Decision:** Option A. The two platform-sensitive settings (`option_as_alt`, `/bin/zsh`)
are both safe in a common package. `option_as_alt` is silently ignored on Linux.
`/bin/zsh` resolves on Arch via the `usr-merge` symlink convention. No split is needed
today. A future supplementary `stow/macos/alacritty/` package remains possible if
macOS-only settings accumulate.

---

### Decision 2: Real managed files vs `.example` files

**Option A: Real managed files (committed directly, stowed directly)**

Pro: No rename step required — clone and stow.
Pro: Accurate representation of the live configuration.
Pro: Changes to config are tracked in git history with full diff.
Con: If any sensitive value is accidentally included, it enters git history.

**Option B: `.example` files (committed as templates, user renames locally)**

Pro: Safe default — user reviews content before stowing.
Pro: Established pattern in this repository for configs with sensitive potential.
Con: Adds friction for a config that contains no secrets.
Con: The user must manually maintain parity between the example and their local copy.

**Decision:** Option A. The Alacritty configuration contains no secrets, credentials,
or work-specific content. It is safe personal daily-use preference. The `.example`
pattern is reserved for configs that carry a real risk of accidental secret exposure.
A post-implementation privacy audit (see Validation) provides the safety gate.

---

### Decision 3: `--no-folding` flag for Stow install

**Option A: Standard Stow (with folding)**

Stow creates a single symlink at `~/.config/alacritty/` pointing to the package
directory, rather than symlinking individual files.

Pro: Fewer symlinks created.
Con: Blocks adding local override files alongside managed files — any file written to
  `~/.config/alacritty/` must go through Stow or the symlink is broken.
Con: If the user has an existing `~/.config/alacritty/` directory with other files,
  Stow will refuse to fold and the install will fail.

**Option B: `--no-folding` Stow**

Stow creates individual symlinks per file, leaving `~/.config/alacritty/` as a real
directory.

Pro: Existing files in `~/.config/alacritty/` coexist without conflict.
Pro: Local override or supplementary files can be added alongside managed symlinks.
Pro: Safer default for a directory that may already exist on the target machine.
Con: More symlinks created (two instead of one).

**Decision:** Option B — `--no-folding`. Alacritty's config directory is a
well-known location that may already exist or may receive local additions. `--no-folding`
is the safer default and preserves the ability to add local-only files (e.g., a
machine-specific override) without restructuring the package.

---

### Decision 4: Import path — absolute `~` vs relative

**Option A: Absolute `~` path (current)**

```toml
import = [
  "~/.config/alacritty/catppuccin-macchiato.toml"
]
```

Pro: Supported since early Alacritty TOML config versions — broadest compatibility.
Pro: Unambiguous — does not depend on the resolved symlink path.
Con: Hardcodes `~` expansion — works on all POSIX systems but is not a file-relative path.

**Option B: Relative path (`./catppuccin-macchiato.toml`)**

Pro: Independent of where the config directory lives.
Con: Supported only since Alacritty v0.13 — older installations break.
Con: Relative resolution is from the symlink target (the repo file), not `~/.config/alacritty/`.
  Both files land in the same directory after stowing, so it works, but it is less
  immediately obvious why.

**Decision:** Option A — keep the absolute `~` path. Both files land in
`~/.config/alacritty/` after stowing, so the import resolves correctly. The absolute
path has broader version compatibility and matches the user's existing configuration
without modification.

---

### Decision 5: `option_as_alt = "Both"` placement

**Option A: Keep in common config**

Pro: No package split required.
Pro: Alacritty on Linux parses and silently ignores the setting — no error, no
  behavioral change.

**Option B: Move to a macOS-specific override package**

Pro: Explicit — the setting is semantically macOS-only.
Con: Requires a `stow/macos/alacritty/` package solely for one setting.
Con: Introduces TOML override mechanics that Alacritty handles via the `import` key —
  more complex and not needed today.

**Decision:** Option A — keep in common config. The runtime behavior on Linux is
a silent no-op. The setting need not be isolated unless a future requirement explicitly
demands macOS-only package separation.

---

### Decision 6: `/bin/zsh` shell path

**Option A: `/bin/zsh` (current)**

```toml
[shell]
program = "/bin/zsh"
args = ["-l"]
```

Pro: Correct on macOS (ships with zsh at `/bin/zsh`).
Pro: Valid on Arch — `usr-merge` makes `/bin` a symlink to `/usr/bin`, so `/bin/zsh`
  resolves to `/usr/bin/zsh`.
Con: Technically non-canonical on Arch (canonical path is `/usr/bin/zsh`).

**Option B: `/usr/bin/env` shim**

```toml
[shell]
program = "/usr/bin/env"
args = ["zsh", "-l"]
```

Pro: Canonically portable — resolves zsh from `$PATH`.
Con: Adds indirection; depends on `/usr/bin/env` (present everywhere, but less explicit).
Con: Does not guarantee a login shell in all environments the same way.
Con: Changes existing config without necessity.

**Decision:** Option A — keep `/bin/zsh`. The `usr-merge` convention makes this
portable on Arch. The env shim adds complexity without practical benefit on the supported
platforms.

---

### Decision 7: Font preference — commit as personal preference, no install step

**Option A: Commit font family as-is**

```toml
[font.normal]
family = "JetBrainsMono Nerd Font"
```

Pro: Accurate to the user's real config.
Pro: Alacritty falls back to a system monospace font if the font is absent — no crash.
Con: On a fresh machine without the font, the terminal launches with the fallback font
  silently.

**Option B: Comment out the font setting in the committed config**

Pro: No fallback surprise on machines without the font.
Con: Changes the committed config from what the user actually uses.
Con: Adds maintenance burden (user must uncomment after font install).

**Decision:** Option A — commit the font preference as-is. Missing font causes a
silent fallback, not an error. Font installation is a user-managed prerequisite,
documented in the PRD, and not the responsibility of the config file.

---

## Validation Strategy

All validation commands are read-only and safe to run during implementation.

### 1. TOML syntax validation

Python 3.11+ ships `tomllib` in the standard library:

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

### 2. Fake-home Stow simulation

Verify the package layout is conflict-free, then verify symlinks land correctly:

```bash
# Step 1 — conflict check (no filesystem writes)
FAKE_HOME="$(mktemp -d)"
stow --dir=stow/common --target="$FAKE_HOME" --simulate --no-folding alacritty \
  && echo "Simulation passed: no conflicts detected"
rm -rf "$FAKE_HOME"

# Step 2 — symlink verification (stow into fake home, inspect, clean up)
FAKE_HOME="$(mktemp -d)"
stow --dir=stow/common --target="$FAKE_HOME" --no-folding alacritty
ls -la "$FAKE_HOME/.config/alacritty/"
stow --dir=stow/common --target="$FAKE_HOME" --delete alacritty
rm -rf "$FAKE_HOME"
```

Expected output for Step 1: "Simulation passed: no conflicts detected".
Expected output for Step 2: two symlinks under `$FAKE_HOME/.config/alacritty/`.

### 3. Privacy audit

Grep the committed files for common secret patterns:

```bash
grep -rEi \
  'password|token|secret|api.?key|private.?key|BEGIN (RSA|OPENSSH|EC)|hostname\.' \
  stow/common/alacritty/
```

Expected output: no matches.

### 4. Dependency and network audit

Confirm no install or network behavior is embedded in the config files:

```bash
grep -rEi 'brew|pacman|curl|wget|npm|pip|cargo|apt' \
  stow/common/alacritty/
```

Expected output: no matches.

---

## Manual Installation Reference

The following commands are documented here for future reference. They must not be
executed automatically by any agent or script.

```bash
# Step 1 — dry run (safe to run, does not modify anything)
stow --dir=stow/common --target="$HOME" --simulate --no-folding alacritty
```

⚠️  MANUAL STEP — run only after reviewing dry-run output

```bash
# Step 2 — install
stow --dir=stow/common --target="$HOME" --no-folding alacritty
```

To unlink the package later:

⚠️  MANUAL STEP

```bash
stow --dir=stow/common --target="$HOME" --delete alacritty
```

---

## Risks

- **Existing `~/.config/alacritty/` on target machine.** If the user has existing files
  in `~/.config/alacritty/`, Stow will warn about conflicts before creating any
  symlinks. The `--no-folding` flag ensures Stow operates at file level, not directory
  level. The dry-run step will surface any conflicts before installation. Resolution is
  manual.

- **`/bin/zsh` absent on non-`usr-merge` Linux.** On a Linux distribution that does not
  use `usr-merge`, `/bin/zsh` may not exist if zsh is installed only at `/usr/bin/zsh`.
  This is not expected on Arch / EndeavourOS (which has used `usr-merge` since 2012),
  but would require a config edit on non-Arch Linux systems. Out of scope for this PRD.

- **TOML version mismatch.** Alacritty's TOML config format has evolved across versions.
  The settings in `alacritty.toml` use keys from Alacritty v0.13+ (TOML-native format).
  Older Alacritty installations using YAML would not parse this file. Not a risk on
  current macOS or Arch packages, but worth noting for documentation.

- **Font fallback is silent.** If JetBrainsMono Nerd Font is not installed, Alacritty
  falls back without logging a visible error. The user may not notice the fallback on a
  fresh machine. This is accepted behavior (Decision 7).

- **Privacy audit false negatives.** The grep-based privacy audit in validation catches
  known patterns but cannot enumerate all possible secrets. Pre-commit hygiene and manual
  review remain the primary privacy controls.

---

## Extensibility

This architecture is intentionally narrow — one common package, two files, no platform
split. It can grow in the following directions without requiring a redesign:

- **macOS-specific override:** A `stow/macos/alacritty/` package could be added to hold
  macOS-only settings if they accumulate. The two-package model is supported by the
  existing `stow/common/` and `stow/macos/` directory structure.

- **Additional theme files:** Extra `*.toml` theme files can be added to
  `stow/common/alacritty/.config/alacritty/` without changing the package structure.
  The import array in `alacritty.toml` supports multiple entries.

- **Local machine overrides:** Because `--no-folding` is used, users can place
  machine-specific files directly in `~/.config/alacritty/` alongside the managed
  symlinks without conflicting with Stow.

---

## Open Questions

None at this time. All four portability decisions from PRD 0011 have been resolved and
translated into architecture decisions above.

---

## Recommended Next Step

Forward to Reviewer for safety and privacy sign-off on the architecture decisions.
On approval, Planner creates an implementation plan scoped to:

1. Create `stow/common/alacritty/.config/alacritty/alacritty.toml` with the user's
   configuration.
2. Create `stow/common/alacritty/.config/alacritty/catppuccin-macchiato.toml` with the
   Catppuccin Macchiato theme.
3. Run validation (TOML syntax, fake-home simulation, privacy audit).
4. Update PRD status to Approved.
5. Update this architecture status to Approved.
