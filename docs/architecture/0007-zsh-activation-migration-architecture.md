# Architecture: Zsh Activation & Migration Strategy

**Number:** 0007
**Status:** Draft
**Date:** 2026-06-17
**PRD:** [0007-zsh-activation-migration.md](../prd/0007-zsh-activation-migration.md)

---

## Context

PRD 0007 defines a safe path from "managed zsh config exists in the repo but is unused" to "managed config is the source of truth," without ever modifying `$HOME` as part of the design work. The user has a working, hand-tuned `~/.zshrc` on macOS (primary) that drives Homebrew, Zinit, Oh My Posh, fzf, zoxide, eza, aliases, history, completions, and local overrides. An abrupt replacement of that file is unacceptable.

PRD 0007 evaluated four activation models and chose a direction this architecture now makes concrete:

- **Start state — Model 4:** ship a `.zshrc.example` reference template; nothing wired up.
- **Target state — Model 3:** the user keeps their own unmanaged `~/.zshrc` and adds **one guarded managed include block** that sources a single managed entry point under `~/.config/zsh/`.

This document translates that direction into structure and decisions. It implements nothing, modifies nothing in `$HOME`, creates no symlinks, runs no Stow against the real home, installs nothing, and never auto-activates Oh My Posh or auto-clones Zinit.

### Established decisions entering this architecture

- **ADR-0001** — Platform-first Stow layout (`stow/<area>/<package>/`); `common/` requires identical path, portable values, no platform tool at package level.
- **ADR-0003** — `.example` files for any config that may carry personal/identity values.
- **ADR-0004** — XDG mixed-mode; use `$XDG_CONFIG_HOME` where the tool supports it.
- **ADR-0013** — Include-based adoption: managed files are *sourced/included*, never replace user-owned files (Git package precedent).
- **ADR-0016** — All zsh-sourced files live in `stow/common/zsh/`; runtime OS detection governs what loads; `~/.zshrc` is never stowed.
- **ADR-0017** — Fake-home (`mktemp -d`) `--simulate` validation when the real `~/.config/<pkg>/` already exists.
- **ADR-0020** — Zinit is installed by a documented one-time manual `git clone`; sourced behind a guard, never auto-cloned from startup.
- **Architecture 0004** — XDG layout for zsh; `~/.config/zsh/` is the zsh package domain; `~/.zshrc` user-owned, gains a source block manually.
- **Architecture 0005** — Oh My Posh: separate `omp` package for config; guarded `eval` in `stow/common/zsh/.config/zsh/omp.zsh`; opt-in.
- **Architecture 0006** — Check / Install / Activate are three separate verbs; activation lines are guarded; shell startup never installs or clones.

### Existing assets this architecture extends

- `stow/common/zsh/.config/zsh/{shared,macos,arch,omp}.zsh.example` — already scaffolded.
- `scripts/check-zsh-deps.sh` + `task deps:check:zsh` — read-only dependency checker (Architecture 0006).
- `docs/stow-usage.md` — zsh and omp package adoption sections.

### Relationship to Architecture 0004

Architecture 0004 had the user append a **multi-line** source block to `~/.zshrc` (source `shared.zsh`, then an inline `if/elif` OS branch). This architecture **refines** that into a **single guarded include line** that sources one managed orchestrator, `index.zsh`. The orchestration logic that ADR-0016 placed inline in `~/.zshrc` moves *into* `index.zsh`. This is an evolution of 0004, not a contradiction: `~/.zshrc` still gains only appended, user-added lines, and `~/.zshrc` is still never stowed. The single-line block exists to give migration exactly one revert point.

---

## Constraints

Carried verbatim from PRD 0007:

- Implement nothing; install nothing.
- Do not modify `~/.zshrc`, `$HOME`, or any path outside the repository.
- Do not re-read or copy the user's real `~/.zshrc` (unless the user pastes it in).
- Do not create symlinks; do not run Stow against the real home (fake-home `--simulate` only, per ADR-0017).
- Do not activate Oh My Posh automatically; do not clone Zinit automatically.
- macOS and Arch material must never be mixed in one file or command.

---

## Activation Models: Why Model 4 → Model 3

### Why Model 4 is the current safe state

`.zshrc.example` only. Nothing is wired into any shell startup file.

- **Zero risk to the working shell.** No include, no loader, no stowed `~/.zshrc`. The user's primary macOS environment is untouched by definition.
- **Reviewable.** The example is a static reference the user can diff against their own `~/.zshrc` at their own pace.
- **Honors every PRD 0007 constraint** trivially — there is nothing active to misbehave.
- **It is a *starting* state, not an end state.** Model 4 alone has no real adoption path (the example drifts from reality). It is correct *now*, while the managed layer is still being proven, and is superseded by Model 3 when the user chooses to adopt.

### Why Model 3 is the future target

Unmanaged `~/.zshrc` + one guarded managed include block sourcing `~/.config/zsh/index.zsh`.

- **Safety.** `~/.zshrc` stays user-owned. No Stow conflict on `~/.zshrc` (it is never stowed). The existing config keeps loading exactly as before; the block only *adds* a managed layer.
- **Reversibility.** One delimited block → delete or comment it → instant full revert. Managed files become inert.
- **Incrementality.** `index.zsh` can start nearly empty and grow one capability at a time; each move is independently verifiable.
- **No auto-install / no auto-clone.** The block sources only declarative, guarded files. Nothing installs or clones at startup.
- **Precedent.** Mirrors the Git package include-based model (ADR-0013): the user's own file gains a pointer to the managed layer.

### Why the other models are rejected for migration

- **Model 1 (manual `source` lines):** safe and reversible, but the user maintains N scattered `source` lines by hand. Model 3 collapses these into one block + one managed orchestrator — strictly better maintenance with the same safety.
- **Model 2 (tiny managed/stowed `~/.zshrc`):** requires replacing the existing `~/.zshrc` — the exact abrupt cutover the user forbids — and would conflict on stow. Rejected for migration. May be reconsidered later, in a separate PRD, for **fresh-machine provisioning only** (where no `~/.zshrc` exists yet).

```
Decision: Start at Model 4 (.zshrc.example reference). Target Model 3 (unmanaged
~/.zshrc + one guarded include block → index.zsh). Reject Model 2 for migration;
defer it to a possible fresh-machine-only PRD. Reason: Model 3 preserves the working
shell, is fully reversible, stays incremental, adds zero startup install/clone risk,
and matches the established include-based Git precedent.
```

---

## Proposed Structure

No new Stow *package* is needed — this extends the existing `stow/common/zsh/` package with two new template files. No file is created by this architecture; the tree below is the design target for the implementation phase.

```
stow/
└── common/
    └── zsh/
        └── .config/
            └── zsh/
                ├── .gitignore              # extend: add index.zsh, local.zsh
                ├── shared.zsh.example       # (existing) portable env/history/completion + fzf/zoxide/eza/zinit guards
                ├── macos.zsh.example        # (existing) Homebrew shellenv, macOS aliases
                ├── arch.zsh.example         # (existing) Arch PATH / AUR helper
                ├── omp.zsh.example          # (existing) guarded Oh My Posh eval
                ├── index.zsh.example        # NEW  managed entry point / orchestrator
                └── zshrc.example            # NEW  reference ~/.zshrc template (Model 4 start state)
```

When the user eventually stows the package (future, user-run), Stow symlinks each file into `~/.config/zsh/` (including the `.example` files, consistent with how `omp` handles them in Architecture 0005). The real files (`index.zsh`, `local.zsh`, `shared.zsh`, …) are git-ignored; the user copies each `.example` to its real name locally.

`~/.zshrc` is **not** in this tree, is **not** stowed, and is **not** modified by anything in this repository.

### Managed files that live under `~/.config/zsh/`

| File | Committed as | Role | Guarded | Git-ignored real file |
|---|---|---|---|---|
| `index.zsh` | `index.zsh.example` | Single entry point. Orchestrates source order. The *only* file the `~/.zshrc` block references. | n/a (it *is* the orchestrator) | yes |
| `shared.zsh` | `shared.zsh.example` | Portable env, history, completion, and **guarded** fzf / zoxide / eza / zinit activation (Architecture 0006, Decisions 5–6). | each tool line guarded | yes |
| `macos.zsh` | `macos.zsh.example` | macOS-only: Homebrew `shellenv`, macOS aliases. Sourced on macOS only. | OS-gated by `index.zsh` | yes |
| `arch.zsh` | `arch.zsh.example` | Arch-only: PATH, AUR helper. Sourced on Arch only. | OS-gated by `index.zsh` | yes |
| `omp.zsh` | `omp.zsh.example` | Guarded Oh My Posh `eval` (Architecture 0005). Opt-in. | binary + config guard | yes |
| `local.zsh` | *(none — never committed)* | Machine-specific / sensitive overrides. Sourced **last** so it wins. | sourced only if present | yes |
| `zshrc.example` | `zshrc.example` | Reference `~/.zshrc` template — the include block plus a fresh-machine starter. Read-only guide; user hand-copies into their real `~/.zshrc`. | n/a | n/a (template is tracked; never auto-applied) |

---

## The Guarded Include Block

The single block the user adds **by hand** to their existing `~/.zshrc` (Model 3 target). Delimiters make the managed region unambiguous to a human and trivial to locate for a clean revert. No tool in this repository ever writes this block — `~/.zshrc` is edited only by the user.

```zsh
# >>> dotfiles managed (zsh) — added manually; delete this block to disable >>>
[[ -r "$HOME/.config/zsh/index.zsh" ]] && source "$HOME/.config/zsh/index.zsh"
# <<< dotfiles managed (zsh) <<<
```

Properties:

- **One line of effect.** A single guarded `source`. If `index.zsh` is absent (not yet copied/stowed), the `[[ -r ... ]]` guard makes it a no-op — the shell still starts.
- **One revert point.** Deleting the three delimiter-wrapped lines fully disables the managed layer.
- **No order assumptions imposed on the user.** The user decides where in their `~/.zshrc` to place the block (typically at the end, so managed defaults can be overridden above/below by their own lines, with `local.zsh` as the final word — see ordering below).
- **Never auto-inserted.** Inserting it is a `⚠️  MANUAL STEP`, shown in docs, run by the user.

---

## The Managed Entry Point: `index.zsh`

`index.zsh` is the orchestrator the include block sources. It owns **source order only**; the actual env/tool logic lives in the layer files (`shared.zsh`, `macos.zsh`, `arch.zsh`, `omp.zsh`). This keeps `~/.zshrc` referencing exactly one managed file while preserving the layer separation from Architecture 0004/0006.

Design target for `index.zsh.example` (content authored in the implementation phase; shown here to fix the contract):

```zsh
# index.zsh — managed entry point. Sourced by the ~/.zshrc managed include block.
# Owns source ORDER only. Each layer file owns its own guarded logic.

# 1) Portable layer: env, history, completion, and guarded fzf/zoxide/eza/zinit.
[[ -r "$HOME/.config/zsh/shared.zsh" ]] && source "$HOME/.config/zsh/shared.zsh"

# 2) Platform layer: OS-detected, sourced only if present (ADR-0016 logic, moved here).
if [[ "$OSTYPE" == "darwin"* ]]; then
  [[ -r "$HOME/.config/zsh/macos.zsh" ]] && source "$HOME/.config/zsh/macos.zsh"
elif [[ -f /etc/arch-release ]]; then
  [[ -r "$HOME/.config/zsh/arch.zsh" ]] && source "$HOME/.config/zsh/arch.zsh"
fi

# 3) Prompt: Oh My Posh — opt-in, guarded inside omp.zsh (Architecture 0005).
[[ -r "$HOME/.config/zsh/omp.zsh" ]] && source "$HOME/.config/zsh/omp.zsh"

# 4) Local overrides — machine-specific / sensitive, git-ignored, sourced LAST so it wins.
[[ -r "$HOME/.config/zsh/local.zsh" ]] && source "$HOME/.config/zsh/local.zsh"
```

Every source is guarded (`[[ -r ... ]]`), so a partially-adopted machine (e.g. `shared.zsh` copied but `macos.zsh` not yet) still starts a clean shell. This is the activation-side embodiment of the "activate-if-present, never install-if-absent" rule (Architecture 0006).

---

## Dependency Checks vs. Activation

This architecture inherits the **Check / Install / Activate** split from Architecture 0006 and adds nothing that installs. The relationship for migration:

| Verb | Owner | Trigger | Role in migration |
|---|---|---|---|
| **Check** | `scripts/check-zsh-deps.sh` / `task deps:check:zsh` | Safe anytime, read-only | Before adopting Model 3, the user runs the checker to see which of fzf/zoxide/eza/oh-my-posh/zinit are present. Absent tools simply mean their guarded activation lines no-op. |
| **Install** | Homebrew `brew bundle` (macOS) / future pacman+AUR (Arch) | Manual, copy-paste, shown not run | Out-of-band, deliberate. Never part of shell startup, never part of the include block. |
| **Activate** | `index.zsh` + guarded layer files | When the user adopts the package | The migration target. Every line guarded; presence-gated on Check, never triggering Install. |

The migration never couples Check or Install into Activate. The include block can be adopted on a machine that is missing every tool — the shell still starts, and capabilities light up as the user installs tools out-of-band.

### Why shell startup must not install dependencies

Carried from Architecture 0006 (load-bearing, restated because the anti-pattern is tempting during migration):

- **Latency** — startup must stay instant; a clone/install on first run blocks every new shell.
- **Network** — startup must work offline / behind captive portals.
- **Silent mutation** — installs change the system unwatched; AGENTS §8 requires risky ops shown, not executed.
- **Non-determinism** — auto-install pulls "latest" at unpredictable times → machine drift.
- **Blast radius** — a failing install in startup can wedge every new shell, including the one needed to fix it.

Therefore the include block and `index.zsh` only **activate** what already exists, behind guards. They never check-and-install and never clone.

---

## Tool Handling (fzf, zoxide, eza, Zinit, Oh My Posh)

All five are handled by **guarded activation only** — installation stays manual and out-of-band (Architecture 0006). No change to those decisions; this architecture only fixes *where* they are sourced via `index.zsh`.

| Tool | Activation home | Pattern | Install (out-of-band, never startup) |
|---|---|---|---|
| `fzf` | `shared.zsh` | `command -v fzf >/dev/null 2>&1 && eval "$(fzf --zsh)"` | `Brewfile.shell` (macOS) / pacman (Arch) |
| `zoxide` | `shared.zsh` | `command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"` | `Brewfile.shell` / pacman |
| `eza` | `shared.zsh` | `command -v eza >/dev/null 2>&1 && alias ls='eza'` | `Brewfile.shell` / pacman |
| `zinit` | `shared.zsh` | `ZINIT_HOME=...; [[ -f "$ZINIT_HOME/zinit.zsh" ]] && source "$ZINIT_HOME/zinit.zsh"` | **manual `git clone`** (ADR-0020) — never auto-cloned |
| `oh-my-posh` | `omp.zsh` (sourced by `index.zsh`) | `command -v oh-my-posh` **and** `[[ -f "$HOME/.config/omp/omp.toml" ]]` before `eval` (Architecture 0005) | `Brewfile.shell` tap / AUR |

### Oh My Posh stays optional and guarded

- OMP activation is its own file, `omp.zsh`, copied from `omp.zsh.example` and **git-ignored** as a real file (Architecture 0005).
- `index.zsh` sources `omp.zsh` only if present (`[[ -r ... ]]`). A user who does not want OMP simply never creates `omp.zsh` — the prompt layer is absent, the shell is unaffected.
- Inside `omp.zsh`, the `eval` is double-guarded on the binary **and** the `omp.toml` config (Architecture 0005, Decision 3). OMP never activates automatically and never errors when absent.

### Zinit stays manual-clone-only

- Per ADR-0020, the upstream auto-clone-on-startup snippet is **forbidden**. `index.zsh`/`shared.zsh` only *source* zinit behind a directory-existence guard.
- The one-time clone is a documented `⚠️  MANUAL STEP` (ADR-0020), detected by `check-zsh-deps.sh` via `${ZINIT_HOME}` directory, never installed at startup.

---

## Stow Layout

- **No new package.** Files land in the existing `stow/common/zsh/` package (ADR-0001 / ADR-0016 — `~/.config/zsh/` is identical on both platforms, all logic guarded/OS-detected at runtime).
- **`~/.zshrc` is never stowed.** Model 3 manages `~/.config/zsh/*` only; the `~/.zshrc` include block is user-added, not a symlink.
- **Single invocation per machine** (future, user-run): `stow --dir=stow/common --target="$HOME" zsh`.

### Placement of `zshrc.example`

`zshrc.example` is a template for a file that lives at `~/.zshrc` (home root), not at `~/.config/zsh/`. It must **never** be auto-linked to `~/.zshrc`.

```
Option A: stow/common/zsh/zshrc.example  (package root)
  Pro: Name and location read as "the ~/.zshrc template."
  Con: Stow would symlink it to ~/zshrc.example unless excluded via
       .stow-local-ignore — but a local ignore file REPLACES Stow's default
       ignore list for the package, a subtle footgun for a safety-first repo.

Option B: stow/common/zsh/.config/zsh/zshrc.example  (alongside other examples)
  Pro: Consistent with how every other .example is handled (Architecture 0005).
  Pro: Stows harmlessly to ~/.config/zsh/zshrc.example — NEVER to ~/.zshrc.
  Pro: No .stow-local-ignore, no change to Stow's default ignore behavior.
  Con: A ~/.zshrc template sitting under ~/.config/zsh/ is a minor semantic oddity.

Decision: Option B. Safety and consistency win over the cosmetic naming nicety.
The file is a read-only reference; the user hand-copies the include block (or, on a
fresh machine with no ~/.zshrc, the whole template) into their real ~/.zshrc. Zero
chance of overwriting ~/.zshrc; no new Stow ignore mechanics to reason about.
```

### `.gitignore` extension

Add the two new real filenames to `stow/common/zsh/.config/zsh/.gitignore`:

```gitignore
index.zsh
local.zsh
```

(`shared.zsh`, `macos.zsh`, `arch.zsh`, `omp.zsh` are already ignored.) `zshrc.example` is **tracked** (it is a placeholder-only template); there is no real `zshrc` file in the package to ignore.

---

## Fake-Home Validation

This architecture creates no files, so no Stow run is needed now. When the implementation phase adds `index.zsh.example` and `zshrc.example`, validate package layout without touching the real home (ADR-0017): the user's `~/.config/zsh/` likely already exists, so a real-home `--simulate` will report an ownership conflict that is expected, not a layout error.

```bash
# Layout validation only — temp home, removed immediately (ADR-0017)
TEST_HOME="$(mktemp -d)"
stow --dir=stow/common --target="$TEST_HOME" --simulate zsh
rm -rf "$TEST_HOME"
```

Rules (ADR-0017): always `mktemp -d`, always remove `$TEST_HOME` immediately, never `--adopt`, a real-home conflict is a stop signal not a bypass flag. The real-home `--simulate` is still run to surface the conflict explicitly; fake-home only confirms the package itself is well-formed.

---

## Rollback Strategy

Because `~/.zshrc` is never stowed and the managed layer is guarded, rollback is low-risk and staged.

1. **Before adding the block — back up `~/.zshrc`.** `⚠️  MANUAL STEP`, user-run:

   ```
   ⚠️  MANUAL STEP — review before running
   cp "$HOME/.zshrc" "$HOME/.zshrc.bak.$(date +%Y%m%d)"
   ```

2. **Instant disable (Model 3).** Delete or comment the delimited managed block in `~/.zshrc`; open a new shell. The managed layer becomes inert; no data loss. This is the primary, one-step revert.

3. **Per-capability revert.** Because cutover is incremental, undoing one capability means restoring that one block in `~/.zshrc` from the backup (or removing one guarded line from the relevant managed file); the rest stays managed.

4. **Disable a single layer without touching `~/.zshrc`.** Remove the real `omp.zsh` (drops the prompt), or remove a guarded tool line in `shared.zsh` — guards make partial states safe.

5. **Full abort.** Restore `~/.zshrc` from the backup; optionally unstow the package and remove the git-ignored real files under `~/.config/zsh/`:

   ```
   ⚠️  MANUAL STEP — review dry-run output before running
   stow --dir=stow/common --target="$HOME" --delete zsh
   ```

   No symlinks were created by this repository automatically, so nothing in `$HOME` is left dangling by an agent.

6. **Verify:**

   ```bash
   zsh --no-rcs -c 'echo ok'        # zsh starts cleanly with no rc files
   ls -l ~/.config/zsh/             # confirm which entries are managed symlinks
   ```

Every destructive rollback command is documented and user-run; no rollback step touches `$HOME` automatically.

---

## Design Decisions

### Decision 1: Single guarded include block + `index.zsh` orchestrator (Model 3)

**Option A:** User appends Architecture 0004's multi-line block directly to `~/.zshrc` (source `shared.zsh`, inline OS `if/elif`, plus later additions for omp/local).
  - Pro: No new file.
  - Con: The managed footprint in `~/.zshrc` grows over time (omp line, local line, future layers), so there is no single revert point and every new layer means another hand-edit of `~/.zshrc`.

**Option B:** User adds **one** delimited, guarded line that sources `~/.config/zsh/index.zsh`; all orchestration lives in `index.zsh`.
  - Pro: `~/.zshrc` gains exactly one managed region — one revert point. New layers are wired inside `index.zsh`, never in `~/.zshrc`.
  - Pro: Delimiters make the managed region unambiguous for a human revert.
  - Pro: Reproducible block text — identical on every machine.
  - Con: One extra managed file (`index.zsh`) and an indirection hop.

**Decision: Option B.** Minimizing and stabilizing the `~/.zshrc` footprint is the whole point of a safe migration. The indirection is cheap; the single revert point is the safety property we want. This refines Architecture 0004 / ADR-0016 (the inline block becomes the body of `index.zsh`).

### Decision 2: `index.zsh` owns source order only; layer files own logic

**Option A:** Collapse everything into one big `index.zsh` (env, tools, OS branches, prompt).
  - Con: Destroys the shared/macos/arch separation mandated by AGENTS §10 and Architecture 0004; mixes platform logic in one file.

**Option B:** `index.zsh` sources the existing layer files in a fixed order; each layer keeps its own guarded logic.
  - Pro: Preserves ADR-0016 / Architecture 0004 layer separation and Architecture 0006 guard placement unchanged.
  - Pro: `index.zsh` stays tiny and reviewable — pure orchestration.
  - Con: One more level of sourcing.

**Decision: Option B.** Separation of concerns is preserved; `index.zsh` is only a manifest of load order.

### Decision 3: `local.zsh` is the git-ignored, last-sourced override slot

Architecture 0004 left a `local.zsh` slot as an open question. Migration makes it necessary: the user's real `~/.zshrc` today contains machine-specific and potentially sensitive "local overrides." Those must have a home that is **never committed** and that **wins** over managed defaults.

**Decision:** `local.zsh` is sourced **last** by `index.zsh`, only if present, and is git-ignored (never has an `.example`, never tracked). It is the migration target for the user's existing local-override section. This satisfies AGENTS §9 (privacy) — secrets live in an untracked file by design.

### Decision 4: `.zshrc.example` placement under `~/.config/zsh/` (not package root)

See "Placement of `zshrc.example`" above. Chosen Option B to avoid `.stow-local-ignore` footguns and guarantee the template can never be auto-linked to `~/.zshrc`.

### Decision 5: Migration starts at Model 4, targets Model 3, rejects Model 2 for migration

See "Activation Models" above. Recorded as the load-bearing strategic decision.

---

## Risks and Mitigations

| Risk | Likelihood | Severity | Mitigation |
|---|---|---|---|
| User pastes the include block before copying/stowing `index.zsh` → source no-ops silently, user thinks adoption failed | Medium | Low | Guard makes it a clean no-op (not an error); docs order the steps (copy/stow first, then block) and show a one-line verify. |
| Someone re-introduces an auto-install/auto-clone into `index.zsh` or the block | Low | High | This doc + ADR-0020 + Architecture 0006 forbid it; guards-only pattern; Reviewer checklist. |
| `index.zsh` indirection hides a sourcing error in a layer file | Low | Low | Each layer guarded by `[[ -r ]]`; a broken layer can be bypassed by removing its real file; `zsh -x` documented for debugging. |
| `zshrc.example` mistaken for a stowable `~/.zshrc` and symlinked into home | Low | High | Decision 4 places it under `~/.config/zsh/`; it can only ever stow to `~/.config/zsh/zshrc.example`, never `~/.zshrc`. |
| User's local overrides committed via `local.zsh` | Low | High | `local.zsh` git-ignored by Decision 3; no `.example`; Reviewer checks `.gitignore` entry exists. |
| OMP activates unexpectedly | Low | Low | `omp.zsh` opt-in + double-guarded (Architecture 0005); `index.zsh` sources it only if the real file exists. |
| Zinit auto-clones at startup | Low | High | ADR-0020 forbids it; only a guarded `source` ships; checker prints the manual clone hint, never runs it. |
| Real-home `stow --simulate` conflict on `~/.config/zsh/` misread as a layout bug | Medium | Low | ADR-0017 fake-home validation distinguishes layout validity from pre-existing directory ownership. |
| Migration stalls half-done, leaving duplicate config (managed + original lines both active) | Medium | Low | Incremental cutover moves one capability at a time and removes the original line as each managed equivalent is verified; backup enables clean revert. |
| OS detection wrong → platform file not sourced | Low | Low | `$OSTYPE` / `/etc/arch-release` checks (ADR-0016); an unsourced platform file is a harmless no-op. |

---

## Extensibility

- **New capability:** add a guarded line to the relevant layer file; no change to `~/.zshrc` or the include block.
- **New layer/platform:** add a file + one `source` line (and, for a platform, one OS branch) in `index.zsh`; `~/.zshrc` untouched.
- **Fresh-machine provisioning (possible future Model 2):** a later PRD could ship a stowed `~/.zshrc` that *is* the include block, for machines with no existing `~/.zshrc`. The `zshrc.example` template is already the seed for that; this architecture leaves a clean seam without committing to it.
- **`$ZDOTDIR` migration:** still deferred (Architecture 0004, Decision 4); `index.zsh` would simply become `$ZDOTDIR/.zshrc`'s body if ever adopted.
- **Other shells:** the Check/Install layers are shell-agnostic; only the activation layer is zsh-specific.

---

## ADRs to Create

| Number | Title | Why |
|---|---|---|
| ADR-0021 | Zsh activation via a single guarded `~/.zshrc` include block + managed `index.zsh` entry point | Records Decisions 1–2: one delimited, user-added, guarded line; `index.zsh` owns source order; `~/.zshrc` never auto-edited, never stowed. Refines ADR-0016's inline source block. |
| ADR-0022 | Zsh migration starts at Model 4 (`.zshrc.example`) and targets Model 3; Model 2 rejected for migration | Records Decision 5: the strategic start/target/rejected-model choice and the fresh-machine-only deferral of Model 2. |
| ADR-0023 | `local.zsh` is the git-ignored, last-sourced zsh override slot | Records Decision 3: resolves Architecture 0004's open question; gives the user's machine-specific/sensitive overrides an untracked, always-wins home. |

Existing ADRs that already govern this architecture (no new record needed): ADR-0001, ADR-0003, ADR-0004, ADR-0013, ADR-0016, ADR-0017, ADR-0020. The `zshrc.example` placement (Decision 4) is recorded inside ADR-0021 rather than as a separate ADR.

---

## Open Questions

1. **Where the migration runbook lives** — extend `docs/stow-usage.md` (zsh section) with a "Model 3 adoption + incremental cutover" subsection, or add a dedicated `docs/zsh-migration.md`? Recommend a dedicated doc, since the cutover spans more than Stow. Decide during planning. Non-blocking.
2. **`zshrc.example` scope** — should it be (a) just the include block + comments, or (b) a full fresh-machine starter `~/.zshrc`? Recommend (b) with the include block clearly delimited at the top, so it serves both the "I already have a `~/.zshrc`" (copy the block) and "fresh machine" (use the whole file) cases. Decide during implementation. Non-blocking.
3. **Zinit guard home** — keep the zinit guard in `shared.zsh` (portable, per Architecture 0006) vs. surfacing it in `index.zsh`. Recommend leaving it in `shared.zsh` to preserve 0006's placement. Non-blocking.

---

## Recommended Next Step

Planner converts this architecture into an ordered implementation plan under `docs/plans/0007-zsh-activation-migration-plan.md`. The plan must include:

- Author `stow/common/zsh/.config/zsh/index.zsh.example` (orchestrator; source order only; every source guarded).
- Author `stow/common/zsh/.config/zsh/zshrc.example` (include block at top, delimited; optional fresh-machine starter body per Open Question 2).
- Extend `stow/common/zsh/.config/zsh/.gitignore` with `index.zsh` and `local.zsh`.
- Write ADR-0021, ADR-0022, ADR-0023.
- Add the migration runbook (location per Open Question 1): Model 4 → Model 3 steps, the backup step, the incremental per-capability cutover, and the rollback — every risky line marked `⚠️  MANUAL STEP`.
- Per-task validation, all read-only: `zsh -n` on the example files, fake-home `stow --simulate` (ADR-0017), `bash -n` on any helper.
- Explicit safety check per task: `~/.zshrc` not modified, `$HOME` not modified, no symlinks created, no Stow run against real home, no dependency installed, no Zinit clone, no OMP activation.
- A rollback note per the Rollback Strategy above.

Do not implement. This document is Draft until reviewed and approved.
