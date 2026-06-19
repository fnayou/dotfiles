# Architecture: Oh My Posh Configuration Management

**Number:** 0005
**Status:** Approved — superseded in part by ADR-0044 and implementation
**Date:** 2026-06-17
**PRD:** [0005-oh-my-posh.md](../prd/0005-oh-my-posh.md)

> **Amendment (ADR-0044 — 2026-06-19):** The implementation diverged from this architecture in three ways:
>
> 1. **`omp.toml` is committed directly** (not as `.example`). ADR-0044 permits personal preferences in committed files when they contain no secrets. `omp.toml` contains only visual styling — no credentials, hostnames, or machine-specific values. The `.gitignore` in the omp package reflects this: it tracks `omp.toml` directly.
>
> 2. **OMP activation uses `prompt.zsh`**, not `omp.zsh`/`omp.zsh.example`. A committed `prompt.zsh` file with a double guard (`command -v oh-my-posh` + config file existence) handles activation. The `omp.zsh.example` template described in this architecture was never created; `prompt.zsh` made it unnecessary.
>
> 3. **`omp.zsh` is not tracked and not git-ignored.** Since `omp.zsh` was never created as a pattern, the `.gitignore` addition for `omp.zsh` described in this architecture was not applied. The zsh `.gitignore` only ignores `local.zsh`.
>
> The Proposed Structure, File Responsibilities (omp.zsh.example), Adoption Phases (Phases 2–4), and the guard-wrapped source call pattern (Decision 3) in this document describe the original design — replaced by the above.

---

## Context

The user has an existing Oh My Posh configuration at `~/.config/omp/omp.toml` that is not version-controlled. Oh My Posh is a prompt engine — it renders the zsh prompt by reading a TOML theme file and emitting styled output. Activation requires a single `eval` line sourced by zsh at startup.

This architecture adds Oh My Posh support to the dotfiles repository in two phases: a config template in its own Stow package, and a zsh activation snippet template in the existing zsh Stow package. Neither is activated automatically. No shell startup file is modified. No real personal config is committed.

Established decisions entering this architecture:

- **ADR-0001**: Platform-first Stow layout with `stow/<area>/<package>/`. A package belongs in `common/` if: (1) target path is identical on both platforms, (2) values work unmodified on both platforms, (3) no platform-specific tool is referenced at the package level.
- **ADR-0003**: `.example` files required for any config that may contain personal or sensitive values.
- **ADR-0004**: XDG mixed-mode — use `$XDG_CONFIG_HOME` where the tool supports it.
- **ADR-0013**: Include-based adoption — managed files are sourced/included rather than replacing user-owned files.
- **ADR-0016**: All zsh-sourced files live in `stow/common/zsh/`. Runtime OS detection in `~/.zshrc` governs what is loaded.
- **Architecture 0004**: `~/.zshrc` is never managed by Stow; the zsh package manages `~/.config/zsh/` only.

Oh My Posh's config path `~/.config/omp/omp.toml` is identical on macOS and Arch. The tool is cross-platform. Both platforms satisfy ADR-0001 criteria for `stow/common/`.

---

## Constraints

From PRD 0005:

- Must not copy or inspect `~/.config/omp/omp.toml`.
- Must not modify `~/.zshrc` or any shell startup file.
- Must not install Oh My Posh or fonts automatically.
- Must not create symlinks in `$HOME` without explicit per-session user approval.
- Must not run `stow` (other than `--simulate` dry-run).
- All committed files are `.example` only — no real personal config.
- macOS and Arch installation notes must be documented separately.

---

## Proposed Structure

Two concerns are separated: the OMP config file and the zsh activation snippet. They live in different Stow packages.

```
stow/
└── common/
    ├── omp/                              # New package — Oh My Posh config
    │   └── .config/
    │       └── omp/
    │           ├── .gitignore            # Ignores real omp.toml (local copy, never committed)
    │           └── omp.toml.example      # Minimal starter theme — placeholder only
    └── zsh/                              # Existing package — extended by one file
        └── .config/
            └── zsh/
                ├── .gitignore            # Extended: add omp.zsh to ignored list
                ├── shared.zsh.example    # (existing)
                ├── macos.zsh.example     # (existing)
                ├── arch.zsh.example      # (existing)
                └── omp.zsh.example       # New: activation snippet template
```

When the user adopts both packages (future phase), Stow creates:

```
~/.config/omp/omp.toml          →  stow/common/omp/.config/omp/omp.toml
~/.config/omp/omp.toml.example  →  stow/common/omp/.config/omp/omp.toml.example
~/.config/zsh/omp.zsh           →  stow/common/zsh/.config/zsh/omp.zsh
~/.config/zsh/omp.zsh.example   →  stow/common/zsh/.config/zsh/omp.zsh.example
```

`~/.zshrc` is not managed by Stow and is not modified.

---

## File Responsibilities

### `stow/common/omp/.config/omp/omp.toml.example`

A minimal, functional Oh My Posh theme in TOML format. Uses no personal identifiers.
Contains: a single simple segment block (e.g., path + prompt character). No hostname, no
username, no machine-specific values.

The user copies this to `omp.toml` locally, customizes it, and stows. The `.example` file
is never stowed directly.

### `stow/common/zsh/.config/zsh/omp.zsh.example`

A zsh snippet that documents the OMP activation line. The content is fully commented out
in the `.example` form — the user copies, uncomments, and sources it when ready.

Content of the `.example` file:

```zsh
# Oh My Posh — prompt engine activation
# Prerequisites:
#   1. Oh My Posh is installed (see docs for macOS/Arch installation)
#   2. stow/common/omp/ is stowed — ~/.config/omp/omp.toml exists
#   3. A Nerd Font is installed and active in your terminal emulator
#
# Uncomment the line below to activate:
# eval "$(oh-my-posh init zsh --config "$HOME/.config/omp/omp.toml")"
```

The user copies this to `omp.zsh` locally. They add a `source` call to their
`~/.config/zsh/shared.zsh` (or directly to `~/.zshrc`) pointing to `omp.zsh`:

```zsh
# In shared.zsh or ~/.zshrc — added manually by the user when ready:
[[ -f "$HOME/.config/zsh/omp.zsh" ]] && source "$HOME/.config/zsh/omp.zsh"
```

The guard `[[ -f ... ]]` is important — it allows the source call to exist in `shared.zsh`
without breaking machines where OMP is not yet installed or not stowed.

### `.gitignore` additions

`stow/common/omp/.config/omp/.gitignore`:

```gitignore
# Ignore the real OMP config (local copy of the .example file — never committed)
omp.toml
```

`stow/common/zsh/.config/zsh/.gitignore` — add one line to the existing file:

```gitignore
omp.zsh
```

---

## Adoption Phases

### Phase 1 — Architecture (this document)

No files created. No `$HOME` changes.

### Phase 2 — Scaffold templates (implementation)

Create:
- `stow/common/omp/.config/omp/.gitignore`
- `stow/common/omp/.config/omp/omp.toml.example`
- `stow/common/zsh/.config/zsh/omp.zsh.example`
- Update `stow/common/zsh/.config/zsh/.gitignore` (add `omp.zsh`)
- Update `docs/stow-usage.md` with an OMP package section

No Stow invoked. No symlinks. No `$HOME` changes.

### Phase 3 — User local adoption (user action only)

The user:

1. Installs Oh My Posh manually (macOS or Arch — see Installation section below).
2. Installs a Nerd Font manually.
3. Copies the example files locally:

```bash
cp stow/common/omp/.config/omp/omp.toml.example \
   stow/common/omp/.config/omp/omp.toml
```

```bash
cp stow/common/zsh/.config/zsh/omp.zsh.example \
   stow/common/zsh/.config/zsh/omp.zsh
```

4. Customizes `omp.toml` with their desired theme.
5. Uncommits the activation line in `omp.zsh`.
6. Dry-runs the OMP package:

```bash
task dry-run AREA=common PACKAGE=omp
```

7. Stows the OMP package (manual step):

```
⚠️  MANUAL STEP — review dry-run output before running
```

```bash
stow --dir=stow/common --target="$HOME" omp
```

8. Create the `omp.zsh` symlink in `~/.config/zsh/`. Stow does not pick up newly added
   files automatically — the user must re-run `stow` for the zsh package whether or not
   it was previously stowed:

```
⚠️  MANUAL STEP — review dry-run output before running
```

```bash
stow --dir=stow/common --target="$HOME" zsh
```

9. Adds the guard source call to their `~/.config/zsh/shared.zsh` (local copy) or
   directly to `~/.zshrc`.
10. Opens a new shell to verify.

### Phase 4 — Active use

Both packages stowed. `~/.config/omp/omp.toml` is a symlink to the Stow package.
`~/.config/zsh/omp.zsh` is a symlink. Oh My Posh initializes on every zsh start.

---

## Installation Reference

Oh My Posh and Nerd Fonts are never installed automatically. These commands are
reference documentation only.

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

**Verify:**

```bash
oh-my-posh --version
```

After installing a Nerd Font: configure the terminal emulator to use it before
activating Oh My Posh.

---

## Design Decisions

### Decision 1: Separate `stow/common/omp/` package, not embedded in the zsh package

**Option A:** Embed the `omp.toml.example` inside `stow/common/zsh/` alongside the zsh
files.

- Pro: Fewer Stow packages — one invocation manages everything.
- Con: The OMP config and zsh config become a single unit. Stowing zsh would also stow
  OMP config even if OMP is not installed. Removing OMP later requires editing the zsh
  package.
- Con: The `stow/common/zsh/` package's purpose blurs — it would contain both shell
  initialization and prompt engine config.

**Option B:** Dedicated `stow/common/omp/` package for the OMP config. Zsh activation
snippet lives in `stow/common/zsh/`.

- Pro: Clean separation of concerns. OMP config is stowed independently. A machine
  without OMP can stow the zsh package and simply not stow the OMP package.
- Pro: Consistent with the established one-package-per-tool pattern (git, zsh).
- Pro: Removing OMP is self-contained — unstow the `omp` package, remove the source
  guard from `shared.zsh`.
- Con: Two Stow invocations required to fully adopt OMP (one for `omp`, one for `zsh`
  if not already done).

**Decision: Option B.** Separation of concerns wins. The `omp` package manages OMP config.
The `zsh` package manages zsh initialization. Two packages is the correct split.

---

### Decision 2: Zsh activation snippet in `stow/common/zsh/`, not in `stow/common/omp/`

**Option A:** Put `omp.zsh.example` inside `stow/common/omp/` under `.config/zsh/`.
Both OMP config and activation snippet stow together as one unit.

- Pro: OMP is fully self-contained — stowing `omp` gives everything OMP-related.
- Con: The `omp` Stow package would write files into `~/.config/zsh/`, which is managed
  by the `zsh` package. While Stow manages at file level (not directory), this creates
  a cross-package directory claim that is confusing to reason about during conflict
  resolution.
- Con: Contradicts ADR-0016 — all zsh-sourced files live in `stow/common/zsh/`.

**Option B:** Put `omp.zsh.example` in `stow/common/zsh/.config/zsh/`. The zsh
Stow package holds all files that end up in `~/.config/zsh/`.

- Pro: ADR-0016 is upheld — `~/.config/zsh/` is owned exclusively by the zsh package.
  No cross-package directory ambiguity.
- Pro: The user finds all zsh-sourced files in one package.
- Con: Stowing just `omp` does not produce the activation snippet. The user must also
  stow (or have already stowed) the `zsh` package.

**Decision: Option B.** ADR-0016 is unambiguous: `~/.config/zsh/` is the zsh package's
domain. Putting any file into `~/.config/zsh/` from another package violates that
boundary. The two-step stow requirement (omp + zsh) is documented clearly.

---

### Decision 3: Guard-wrapped source call, not unconditional

When the user adds a source call for `omp.zsh` to their `shared.zsh`, it must be
wrapped in a file-existence guard:

```zsh
[[ -f "$HOME/.config/zsh/omp.zsh" ]] && source "$HOME/.config/zsh/omp.zsh"
```

**Without a guard:** If the user uses their `shared.zsh` on a machine where OMP is not
installed or not stowed, the `source` call errors. This breaks shell startup silently
on new machines.

**With a guard:** The source call is a no-op on machines where `omp.zsh` is absent.
Shell startup is unaffected. OMP is opt-in at the machine level.

**Decision: Guard required.** Document this pattern in `omp.zsh.example` and in
`docs/stow-usage.md`. Consistent with the incremental adoption principle.

---

### Decision 4: `omp.toml.example` uses a minimal placeholder theme, not a copy of the real config

The user's real `~/.config/omp/omp.toml` is not inspected, copied, or referenced. The
`.example` file is a minimal functional theme authored from scratch — enough to verify
that Oh My Posh activates correctly, without encoding any personal preferences.

This satisfies ADR-0003 and PRD 0005. The user replaces the starter theme with their
real content after copying the file locally.

**Decision: Minimal starter theme only.** Privacy is non-negotiable.

---

### Decision 5: `~/.config/omp/` directory — no conflict with existing zsh package

The `omp` Stow package targets `~/.config/omp/`. The `zsh` Stow package targets
`~/.config/zsh/`. These are distinct subdirectories under `~/.config/`. Stow manages
directory creation at the file level — no conflict between the two packages.

If `~/.config/omp/` already exists on the user's machine (because the real config is
already there), Stow will report a conflict during dry-run. The user must remove or
back up the existing `omp.toml` before stowing. This is expected and documented.

---

## Risks and Mitigations

| Risk | Likelihood | Severity | Mitigation |
|---|---|---|---|
| User's real `~/.config/omp/omp.toml` conflicts with stow dry-run | High | Low | Dry-run surfaces this. User backs up and removes the file before stowing. Document this explicitly. |
| OMP not installed when `omp.zsh` is sourced — `eval` fails | Medium | Medium | Guard in Decision 3 prevents shell startup failure. `omp.zsh.example` documents the prerequisite clearly. |
| Nerd Font absent — prompt renders as boxes or question marks | Medium | Low | Documented as a prerequisite. Not a safety issue — purely visual. |
| Real `omp.toml` committed (personal theme details, hostnames) | Low | High | ADR-0003 enforced. `.example` first. `.gitignore` in the package directory. Reviewer checklist. |
| `omp.zsh` committed (with the activation line uncommented) | Low | Low | `omp.zsh` (real file) is git-ignored. Only `.example` is tracked. Privacy-neutral — activation line has no sensitive data. |
| OMP binary path differs between macOS and Arch install methods | Low | Low | `oh-my-posh` is placed on `$PATH` by all install methods. The `eval` line uses `oh-my-posh` (not a hardcoded path). |
| User sources `omp.zsh` before `omp.toml` exists — eval fails at config path | Low | Medium | The outer `[[ -f "$HOME/.config/zsh/omp.zsh" ]]` guard in `shared.zsh` prevents shell startup failure when `omp.zsh` is absent. An optional inner binary/config guard inside `omp.zsh` is deferred to implementation (see Open Questions). Document the chosen approach. |
| Stow `omp` package writes into `~/.config/zsh/` (if design changes) | Low | Medium | Decision 2 explicitly keeps `omp.zsh.example` in the zsh package. Cross-package directory writes are forbidden. |

---

## Extensibility

- **Multiple themes:** Additional `.toml.example` files can be added to the `omp`
  package. The user selects one by path in the `eval` line.
- **Platform-specific themes:** An `omp-macos.toml.example` and `omp-arch.toml.example`
  can be added. The activation snippet in `omp.zsh` selects the theme via OS detection —
  no Stow package change needed.
- **Other shells:** A `omp.bash.example` or `omp.fish.example` can be added to the
  respective shell packages when those packages are created. The OMP config package is
  shell-agnostic.
- **Theme updates:** The user edits their local `omp.toml` (git-ignored). If they want
  to version-control their customized theme, a future phase can commit a real (but
  sanitized) `omp.toml` — this PRD does not block that.

---

## ADRs to Create

No new ADR is strictly required — this architecture applies existing decisions. One
optional record may be written:

| Number | Title | Status |
|---|---|---|
| ADR-0017 | Oh My Posh activation in a guarded sourced snippet | Optional |

Existing ADRs that directly govern this architecture:

- ADR-0001: Platform-first layout — `stow/common/omp/` satisfies all three criteria.
- ADR-0003: `.example` files — `omp.toml.example` is the committed artifact.
- ADR-0013: Include-based adoption — OMP activation mirrors the Git include model.
- ADR-0016: Zsh files in `stow/common/zsh/` — `omp.zsh.example` lives there.

---

## Open Questions

None blocking.

Optional future discussion:

- Should `omp.zsh.example` include a check for the OMP binary (`command -v oh-my-posh`)
  in addition to the config file guard? Decide during implementation — either choice is
  safe.
- Should `docs/stow-usage.md` gain an "OMP package adoption" section parallel to the
  existing git and zsh sections, or is the existing structure sufficient? Recommend yes —
  decide during implementation.

---

## Recommended Next Step

Planner converts this architecture into an ordered implementation plan under
`docs/plans/0005-oh-my-posh-plan.md`. The plan must include:

- Creation of `stow/common/omp/.config/omp/` directory scaffold.
- Creation of `stow/common/omp/.config/omp/.gitignore`.
- Creation of `stow/common/omp/.config/omp/omp.toml.example` with a minimal starter theme.
- Creation of `stow/common/zsh/.config/zsh/omp.zsh.example` with fully commented activation line.
- Update of `stow/common/zsh/.config/zsh/.gitignore` to add `omp.zsh`.
- Update of `docs/stow-usage.md` with an OMP package adoption section.
- Per-task validation steps (all read-only).
- Explicit safety check: no stow invoked, no `$HOME` modified, no real config read.
