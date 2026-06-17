# Architecture: Shell Dependency Management

**Number:** 0006
**Status:** Approved
**Date:** 2026-06-17
**PRD:** [0006-shell-dependencies.md](../prd/0006-shell-dependencies.md)

---

## Context

The user's zsh configuration depends on external tools that are not part of a default shell install — `fzf`, `zoxide`, `eza`, `oh-my-posh`, and the `zinit` plugin manager — plus baseline repository tooling (`git`, `stow`, `go-task`). On macOS these are installed via Homebrew today, but the repository does not yet record, verify, or reproduce that dependency set.

PRD 0006 requires a strategy that:

- declares dependencies (macOS first, via Homebrew Brewfiles),
- **checks** for missing tools without installing them,
- keeps **install** a deliberate manual step,
- never runs installs, clones, or network operations from shell startup,
- separates macOS and Arch,
- plans Arch (pacman/paru/yay) without implementing it.

This document translates that PRD into structure and decisions. It implements nothing.

### Established decisions entering this architecture

- **ADR-0002**: `go-task` is the task runner. The repository Taskfile is the discoverable entry point for safe operations.
- **ADR-0007**: Homebrew packages are split into category Brewfiles under `packages/macos/`. The original category list (`core`, `cli`, `dev`, `gui`, `optional`) was illustrative — this architecture refines it for the shell-dependency scope (see Decision 2).
- **ADR-0009**: The foundation-phase Taskfile contains **only read-only and `--simulate` tasks**. Adding any mutating task requires a new PRD that explicitly lifts that restriction.
- **ADR-0010**: `packages/macos/` is deferred until a Brewfile PRD is approved. PRD 0006 is that PRD — it authorizes creating the directory.
- **ADR-0011 / ADR-0012**: The Stow task interface uses `AREA` and `PACKAGE` variables; tasks are explicit and single-package.
- **ADR-0016**: All zsh-sourced files live in `stow/common/zsh/`. Runtime OS detection in `~/.zshrc` governs what is loaded. `~/.zshrc` is never stowed.
- **Architecture 0005 / `docs/stow-usage.md`**: Oh My Posh install (Homebrew tap on macOS, AUR on Arch) and activation are already documented and guarded.

### Existing assets this architecture extends

- `scripts/detect-os.sh` — prints `macos` or `arch`; exits non-zero on unsupported OS.
- `scripts/check.sh` — prints `PASS`/`FAIL` per core tool (`stow`, `git`, `task`); exits non-zero if any fail.
- `Taskfile.yml` — flat tasks: `detect`, `check`, `list`, `dry-run`.

---

## Constraints

From PRD 0006 (carried verbatim into the architecture):

- Implement nothing; install nothing.
- Do not modify `~/.zshrc`, `$HOME`, or any path outside the repository.
- Do not run Stow (fake-home `--simulate` validation only, per ADR-0017, if ever needed).
- Do not add installs, clones, or network operations to shell startup.
- Do not auto-clone `zinit`.
- Checker scripts detect and explain; they never install.
- macOS and Arch must never be mixed in one file or one command.

---

## The Three Verbs: Check / Install / Activate

The architecture's central idea is that dependency management is **three separate concerns**, each with a different owner, safety level, and trigger. Conflating them is what makes "auto-install on shell startup" dangerous.

| Verb | What it does | Owner | Side effects | Trigger |
|---|---|---|---|---|
| **Check** | Detect which tools are present/absent and report clearly | `scripts/check-zsh-deps.sh` | None — read-only, no network | Safe anytime; `task deps:check:zsh` |
| **Install** | Place tools on the system | Homebrew (`brew bundle`) / future pacman+paru | Mutates the system (packages) | Manual, deliberate, copy-paste |
| **Activate** | Wire installed tools into the shell (`eval`, aliases, plugin load) | zsh package files (`shared.zsh`, `macos.zsh`), all guarded | Affects shell startup only | When the user adopts the zsh package |

Rules that fall out of this split:

1. **Check never installs.** It is the only verb that is safe to run unattended.
2. **Install is never automatic.** Not from shell startup, not from scripts, not from CI, not from a Taskfile that executes it (see Decision 4).
3. **Activate is guarded.** Every activation line is wrapped so it is a no-op when the tool is absent — a machine missing a tool still gets a working shell (see Decision 5).

---

## Why Shell Startup Must Not Install Tools

This is a load-bearing principle, recorded explicitly because the anti-pattern is common and tempting.

An auto-install / auto-clone block in `~/.zshrc` (e.g. "if zinit missing, `git clone` it") is rejected for these reasons:

- **Startup latency.** Every new shell pays a `command -v` + branch cost at minimum, and a full network clone/install on first run — interactive shells must stay instant.
- **Network dependency.** Shell startup would fail or hang on an offline or captive-portal network. A shell must start without a network.
- **Silent mutation.** Installs change the system without the user watching. PRD 0006 and AGENTS §1/§9 require risky operations to be shown, not executed.
- **Non-determinism.** Auto-install pulls "latest" at unpredictable times, so two machines drift. Declarative Brewfiles + a deliberate install step keep installs reproducible and reviewable.
- **Error blast radius.** A failing install in `.zshrc` can wedge every new shell, including the one the user would use to fix it.

Therefore: shell startup files only **activate** tools that already exist, behind existence guards. They never check-and-install, and they never clone.

---

## Proposed Structure

```
packages/
└── macos/                       # NEW — authorized by PRD 0006 (lifts ADR-0010 deferral)
    ├── Brewfile.core            # git, stow, go-task        (repo prerequisites)
    ├── Brewfile.shell           # fzf, zoxide, eza, oh-my-posh (zsh runtime tools)
    └── Brewfile.optional        # optional extras (list deferred)

scripts/
├── detect-os.sh                 # existing — reused
├── check.sh                     # existing — core repo tooling (stow, git, task)
└── check-zsh-deps.sh            # NEW — shell-tier tooling (fzf, zoxide, eza, oh-my-posh, zinit)

Taskfile.yml                     # extended with the deps: namespace
```

Arch is **planned only** — no `packages/arch/` directory is created by this architecture (see Decision 3).

Brewfiles live under `packages/macos/`, never under `stow/` — they are declarative package lists, not symlinked into `$HOME` (consistent with ADR-0007).

---

## Tool-by-Tool Handling

| Tool | Tier | macOS source | Arch source (future) | Activation (zsh) | Checker detects |
|---|---|---|---|---|---|
| `git` | core | `Brewfile.core` (formula) | `pacman` | n/a | `command -v git` |
| `stow` | core | `Brewfile.core` (formula) | `pacman` | n/a | `command -v stow` |
| `go-task` | core | `Brewfile.core` (`go-task/tap/go-task`) | AUR (`go-task` or `task-bin` — not in official repos; resolve when Arch is implemented) | n/a | `command -v task` |
| `fzf` | shell | `Brewfile.shell` (formula) | `pacman` | `eval "$(fzf --zsh)"` (guarded) | `command -v fzf` |
| `zoxide` | shell | `Brewfile.shell` (formula) | `pacman` | `eval "$(zoxide init zsh)"` (guarded) | `command -v zoxide` |
| `eza` | shell | `Brewfile.shell` (formula) | `pacman` | alias only (guarded) | `command -v eza` |
| `oh-my-posh` | shell | `Brewfile.shell` (`jandedobbeleer/oh-my-posh/oh-my-posh`) | AUR (`oh-my-posh-bin`) | guarded `eval` (Architecture 0005) | `command -v oh-my-posh` |
| `zinit` | shell | **not a Brewfile entry** — git clone (Decision 6) | git clone / AUR | guarded `source` of zinit (Decision 6) | `${ZINIT_HOME}` dir / `zinit` function |

Notes:

- **Core vs shell split**: `git`/`stow`/`go-task` are already covered by `scripts/check.sh`; they appear in `Brewfile.core`. The shell tier is the new surface area and the focus of `check-zsh-deps.sh`.
- **`fzf` activation**: modern `fzf` provides `fzf --zsh` for key bindings + completion — no separate `$(brew --prefix)/opt/fzf/install` script is needed. This keeps activation a single guarded `eval` with no install side effect.
- **`eza`** is a drop-in `ls` replacement; activation is a guarded alias only — no `eval`, no network.

---

## Design Decisions

### Decision 1: Dependency check is a dedicated read-only script mirroring `check.sh`

**Option A:** Extend `scripts/check.sh` to also check the shell tools.
  - Pro: One script, one command.
  - Con: Conflates "can I manage dotfiles at all" (core) with "is my shell fully equipped" (shell). A machine can legitimately have core tools but skip the shell tier. Mixing them muddies the exit-code contract.

**Option B:** New `scripts/check-zsh-deps.sh` dedicated to the shell tier, same `PASS`/`FAIL` format and non-zero-on-failure contract as `check.sh`.
  - Pro: Clear separation matching the core/shell tier model. Each script has one job and one exit-code meaning.
  - Pro: `check-zsh-deps.sh` can print **per-tool, OS-detected install hints** (which `check.sh` does not), because it is scoped to user-facing shell tooling.
  - Con: Two scripts to maintain.

**Decision: Option B.** Separation matches the tier model and keeps exit-code semantics clean. `check-zsh-deps.sh`:

- uses `command -v <tool>` only — **no mutation, no network**;
- prints `PASS: <tool>` / `FAIL: <tool> (not installed)` per tool, matching `check.sh`;
- on any failure, prints an OS-detected install hint (via `scripts/detect-os.sh` logic) — e.g. the `brew bundle --file=packages/macos/Brewfile.shell` command on macOS — **but does not run it**;
- exits non-zero if any required shell tool is missing, so it can gate a manual workflow;
- treats `zinit` specially (Decision 6) — it is detected by install directory, not a binary on `$PATH`.

### Decision 2: Brewfile categories for this scope are `core` / `shell` / `optional`

ADR-0007 introduced split Brewfiles with an illustrative category list (`core`, `cli`, `dev`, `gui`, `optional`). PRD 0006 scopes shell dependencies specifically and asks for `core` / `shell` / `optional`.

**Option A:** Reuse ADR-0007's literal list and put shell tools into `Brewfile.cli`.
  - Pro: No change to ADR-0007.
  - Con: "cli" is a grab-bag; it hides which tools the zsh config actually requires. PRD 0006 explicitly wants a `shell` tier that maps 1:1 to zsh runtime needs.

**Option B:** Treat ADR-0007's list as illustrative and create exactly the three tiers PRD 0006 needs now: `Brewfile.core`, `Brewfile.shell`, `Brewfile.optional`.
  - Pro: The Brewfile set maps directly to the dependency tiers and to `check-zsh-deps.sh`.
  - Pro: Other categories (`cli`, `dev`, `gui`) can still be added later when a PRD scopes them — the split-by-category principle from ADR-0007 is preserved.
  - Con: ADR-0007's category list needs a clarifying follow-up ADR so the two documents do not appear to contradict.

**Decision: Option B.** Create `core` / `shell` / `optional` now. Write a new ADR clarifying that ADR-0007's category list is a non-exhaustive, evolving set and that categories are added per-PRD as scoped (see "ADRs to Create"). `Brewfile.optional`'s contents are deferred — it is created as a documented placeholder, not populated.

### Decision 3: Arch is planned, not scaffolded

**Option A:** Create `packages/arch/` with placeholder package lists now.
  - Pro: Symmetry with macOS.
  - Con: PRD 0006 explicitly defers Arch. Empty/placeholder Arch files invite premature, untested commands and violate the ADR-0010 spirit (no directory without authorized content).

**Option B:** Document the future Arch strategy in this architecture and in `check-zsh-deps.sh` install hints, but create **no** `packages/arch/` files.
  - Pro: Honors PRD 0006's deferral. No untested Arch artifact ships.
  - Pro: `check-zsh-deps.sh` can still print an Arch install hint (pacman for repo tools, paru/yay for AUR like `oh-my-posh`) without a package-list file existing.
  - Con: Arch users get hints, not a one-command install, until a future PRD.

**Decision: Option B.** Future Arch layout (illustrative only, not created):

```
packages/arch/
├── pkglist.core        # pacman: git, stow, go-task(+AUR)
├── pkglist.shell       # pacman: fzf, zoxide, eza ; AUR: oh-my-posh-bin
└── pkglist.optional
```

Tool-name and source differences must be resolved per-tool when Arch is implemented (e.g. `oh-my-posh` is AUR on Arch but a tap formula on macOS). No pacman/paru/yay command may ever enter shell startup.

### Decision 4: `deps:macos:shell` prints the install command; it does not execute it

This is the most safety-sensitive decision. PRD 0006's bootstrap strategy says scripts should "explain missing dependencies, not silently install them," and ADR-0009 forbids mutating Taskfile tasks without a PRD that explicitly lifts the restriction.

**Option A:** `deps:macos:shell` runs `brew bundle --file=packages/macos/Brewfile.shell`.
  - Pro: One-command install convenience.
  - Con: Directly contradicts ADR-0009's no-mutation boundary and PRD 0006's "explain, don't install" stance. A mistyped `task deps:...` would mutate the system.
  - Con: Hides the actual command from the user, reducing reviewability.

**Option B:** `deps:macos:shell` **prints** the exact, copy-pasteable `brew bundle` command (marked `⚠️  MANUAL STEP`) and exits. The user copies and runs it deliberately.
  - Pro: Preserves the ADR-0009 no-mutation boundary — no Taskfile task installs anything.
  - Pro: The install command is shown, not executed — satisfies AGENTS §8 and PRD 0006.
  - Pro: Keeps Check/Install separation intact: Task tooling stays in the "check + explain" half.
  - Con: Slightly less convenient — install remains a manual copy-paste.

**Decision: Option B.** Both `deps:` tasks stay non-mutating:

- `deps:check:zsh` → runs `bash scripts/check-zsh-deps.sh` (read-only).
- `deps:macos:shell` → prints the `brew bundle` commands for the requested tier(s) and the OMP/zinit notes; executes nothing.

This means PRD 0006 does **not** lift the ADR-0009 mutation ban — it operates entirely within it. If the user later wants a genuinely executing install task, that is a separate PRD and a separate ADR. Recorded as an Open Question.

### Decision 5: Activation lines are guarded; tools are never required at startup

Every shell-integration line for a shell-tier tool is wrapped in an existence guard so a machine missing the tool still starts a clean shell. Pattern (lives in the zsh package, per ADR-0016 — `shared.zsh` for portable tools, `macos.zsh`/`arch.zsh` for platform-specific):

```zsh
# fzf — key bindings + completion (guarded)
command -v fzf >/dev/null 2>&1 && eval "$(fzf --zsh)"

# zoxide — smarter cd (guarded)
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"

# eza — ls replacement (guarded alias)
command -v eza >/dev/null 2>&1 && alias ls='eza'
```

This mirrors the OMP guard already established in Architecture 0005 / Decision 3. A guard is a no-op when the tool is absent — no error, no startup failure. This is the safe substitute for auto-install: activate-if-present, never install-if-absent.

### Decision 6: Zinit is installed by a documented one-time manual clone — never auto-cloned

`zinit` is a zsh plugin manager. Its canonical install is a `git clone` into `${ZINIT_HOME}` (e.g. `${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git`), not a Homebrew formula. The strong anti-pattern this architecture forbids is the upstream-suggested `.zshrc` snippet that auto-clones zinit on first run.

**Option A:** Keep the upstream auto-clone-on-startup snippet in the zsh config.
  - Con: Direct violation of PRD 0006 ("do not clone Zinit automatically from shell startup") and the "Why Shell Startup Must Not Install Tools" principle above. Rejected outright.

**Option B:** Install zinit via a **documented one-time manual `git clone`** (shown, not executed), and have the zsh config only **source** zinit behind an existence guard.
  - Pro: Honors the no-startup-clone rule absolutely.
  - Pro: Activation is a guarded `source` — absent zinit means no plugin manager, but the shell still starts.
  - Con: New-machine setup has one extra documented manual step.

**Decision: Option B.** Specifics:

- `zinit` does **not** go in any Brewfile (it is not a formula in this setup).
- `check-zsh-deps.sh` detects zinit by checking for the install directory (`${ZINIT_HOME}`), since it is not a `$PATH` binary, and prints the manual clone command as the "install hint" on failure.
- The one-time install command is documented (in `docs/stow-usage.md` zsh section or a deps doc) and marked `⚠️  MANUAL STEP`:

  ```
  ⚠️  MANUAL STEP — review before running
  git clone https://github.com/zdharma-continuum/zinit.git \
    "${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
  ```

- The zsh config sources zinit behind a guard, never clones it:

  ```zsh
  ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
  [[ -f "${ZINIT_HOME}/zinit.zsh" ]] && source "${ZINIT_HOME}/zinit.zsh"
  ```

- The exact zinit install path (manual clone vs. a future packaged option) and whether plugin definitions are version-controlled are left to the zsh implementation phase — out of scope here.

### Decision 7: Oh My Posh dependency handling reuses Architecture 0005

OMP is already fully specified by Architecture 0005 and `docs/stow-usage.md`: installed via the Homebrew tap on macOS (`jandedobbeleer/oh-my-posh/oh-my-posh`) or AUR on Arch, activated by a guarded `eval` in `stow/common/zsh/.config/zsh/omp.zsh`. This architecture adds exactly one thing: OMP appears as an entry in `Brewfile.shell` (with its tap) so it is captured declaratively, and `check-zsh-deps.sh` reports it via `command -v oh-my-posh`. No change to the existing OMP activation design.

---

## Safety and Privacy

- **No mutation anywhere automatic.** No script, task, or shell startup file installs, clones, or performs network operations. `check-zsh-deps.sh` is read-only; `deps:` tasks are read-only/print-only (Decisions 1, 4).
- **No `$HOME` or out-of-repo changes.** This architecture creates only files under `packages/macos/`, `scripts/`, and `Taskfile.yml`. No symlinks, no Stow execution (fake-home `--simulate` only if ever needed, per ADR-0017).
- **Install commands are shown, not run**, and dangerous lines carry the `⚠️  MANUAL STEP` marker (AGENTS §8, §12).
- **Privacy (AGENTS §9):** Brewfiles list only public formula/cask/tap names — no secrets, no private taps, no credentials. Scripts contain no tokens, hostnames, or machine-specific paths; they use `$HOME`/`$XDG_DATA_HOME`. Brewfiles are not `.example` files because they contain no sensitive values — they are public package manifests (consistent with ADR-0003's intent, which targets identity/credential-bearing config).
- **Cross-platform (AGENTS §10):** macOS Homebrew references never appear in Arch material and vice versa. `check-zsh-deps.sh` detects tools platform-neutrally (`command -v`) but emits OS-specific install hints via `detect-os.sh` logic.

---

## Rollback Strategy

Because nothing is installed automatically, rollback is inherently low-risk:

- **Repository artifacts** (Brewfiles, `check-zsh-deps.sh`, Taskfile edits): revert with `git` — they create nothing outside the repo.
- **Installed packages** (if the user ran `brew bundle` manually): use `brew bundle cleanup --dry-run --file=packages/macos/Brewfile.shell` to preview what would be removed without removing anything. Actual removal requires a deliberate manual `brew uninstall` — shown by the user, never executed by the repo. Do not use `brew bundle cleanup` without `--dry-run`; it removes packages immediately.
- **zinit**: remove the cloned directory manually (`rm -rf "${ZINIT_HOME}"` — a `⚠️  MANUAL STEP`, user-run only) and remove the guarded source line.
- **Activation**: deleting or commenting a guarded line in the user's local zsh files disables a tool's integration without affecting anything else; guards make partial states safe.
- **Stow packages** (zsh/omp): unstow per the existing `docs/stow-usage.md` procedure.

No rollback step touches `$HOME` automatically; all destructive rollback commands are documented and user-run.

---

## Risks

| Risk | Likelihood | Severity | Mitigation |
|---|---|---|---|
| Someone re-adds an auto-install/auto-clone block to shell startup | Medium | High | This document + PRD 0006 forbid it explicitly; Reviewer checklist; guards-only activation pattern (Decisions 5, 6). |
| ADR-0007 category list appears to conflict with `core/shell/optional` | High | Low | New clarifying ADR records categories as evolving/per-PRD (Decision 2, "ADRs to Create"). |
| User runs `task deps:macos:shell` expecting it to install | Medium | Low | Task prints the command with a `⚠️  MANUAL STEP` marker and explains it does not execute (Decision 4); task `desc` states "prints, does not run". |
| `zinit` detection false-negative (installed at non-default path) | Low | Low | Checker honors `${ZINIT_HOME}`/`${XDG_DATA_HOME}`; documents the expected path; failure only prints a hint, never blocks the shell. |
| Brewfile drift from actual installed set | Medium | Low | Brewfiles are the declarative source of truth; `brew bundle cleanup` (manual) surfaces drift; no auto-sync. |
| `oh-my-posh` source differs macOS (tap) vs Arch (AUR) | Low | Low | Documented separately per platform; activation uses `oh-my-posh` on `$PATH`, not a hardcoded path (Architecture 0005). |
| `fzf` activation method changes upstream | Low | Low | Use `fzf --zsh` (current supported integration); guarded, so a failure degrades gracefully. |
| Checker exit code misused in automation | Low | Medium | Non-zero exit documented as "missing tool" only; checker never mutates, so gating on it is safe. |

---

## Extensibility

- **New shell tool**: add one line to `Brewfile.shell`, one detection block to `check-zsh-deps.sh`, and one guarded activation line in the zsh package. No structural change.
- **New Brewfile category** (e.g. `cli`, `dev`, `gui` from ADR-0007): add `Brewfile.<category>` under `packages/macos/` when a PRD scopes it. The split-by-category principle already accommodates this.
- **Arch implementation**: add `packages/arch/pkglist.*` and an Arch branch to the install-hint logic (already OS-detected) when a future PRD lifts the deferral. The checker is already platform-aware.
- **Executing install task** (if ever desired): a future PRD + ADR can introduce a genuinely mutating `deps:macos:shell:install` task. The current print-only design leaves a clean seam for that without breaking the no-mutation default.
- **Other shells**: the Brewfile/check layer is shell-agnostic; only the activation layer is zsh-specific. Bash/fish packages can reuse the same Brewfiles and checker.

---

## ADRs to Create

| Number | Title | Why |
|---|---|---|
| ADR-0018 | Brewfile categories are an evolving, per-PRD set (`core`/`shell`/`optional` for shell deps) | Reconciles Decision 2 with ADR-0007's illustrative list so they do not appear to contradict. |
| ADR-0019 | `deps:` Taskfile tasks are non-mutating (check + print only) | Records Decision 4 — confirms PRD 0006 operates within ADR-0009's mutation ban rather than lifting it. |
| ADR-0020 | Zinit installed via documented manual clone; sourced behind a guard, never auto-cloned | Records Decision 6 — the load-bearing anti-auto-clone rule. |

Existing ADRs that already govern this architecture (no new record needed): ADR-0002 (go-task), ADR-0007 (split Brewfiles), ADR-0009 (no mutating tasks), ADR-0010 (packages dir gated on PRD — lifted by PRD 0006), ADR-0016 (zsh files location + guards), ADR-0017 (fake-home validation).

---

## Open Questions

1. **`Brewfile.optional` contents** — left empty/placeholder for now. Which extras (if any) belong there is deferred to a future scoping pass. Non-blocking.
2. **Executing install task** — should a future PRD add a genuinely mutating `deps:macos:shell:install`? Current decision is print-only (Decision 4). Non-blocking; deferred.
3. **Where the zinit + deps install commands are documented** — extend `docs/stow-usage.md`, or add a dedicated `docs/shell-dependencies.md`? Recommend a dedicated doc since deps span more than Stow. Decide during planning. Non-blocking.
4. **Should `deps:check:zsh` call `check.sh` first** (core before shell) or stay independent? Recommend independent with a one-line note pointing users to `task check` for core tooling. Decide during planning. Non-blocking.

---

## Recommended Next Step

Planner converts this architecture into an ordered implementation plan under `docs/plans/0006-shell-dependencies-plan.md`. The plan must include:

- Create `packages/macos/` (lifting ADR-0010) with `Brewfile.core`, `Brewfile.shell`, and a placeholder `Brewfile.optional`.
- Create `scripts/check-zsh-deps.sh` — read-only, `PASS`/`FAIL` format matching `check.sh`, OS-detected install hints, special-case zinit by directory, non-zero exit on missing required tool.
- Extend `Taskfile.yml` with non-mutating `deps:check:zsh` (runs the checker) and `deps:macos:shell` (prints the `brew bundle` command — executes nothing).
- Write ADR-0018, ADR-0019, ADR-0020.
- Document the manual zinit clone and the `brew bundle` install steps (location per Open Question 3), each marked `⚠️  MANUAL STEP`.
- Per-task validation steps — all read-only (e.g. `task deps:check:zsh`, `bash -n scripts/check-zsh-deps.sh`).
- Explicit safety check per task: no install run, no `$HOME` modified, no Stow invoked, no network call.
- A rollback note per the Rollback Strategy above.
```
