# Architecture: Interactive Taskfile Completion (go-task + fzf-tab)

**Number:** 0015
**Status:** Approved
**Date:** 2026-06-22
**PRD:** 0015 (`docs/prd/0015-taskfile-completion.md`)

> **Scope update (approved):** The user elected the full option — the `fzf-tab`
> load-order fix (Decision 4, Option C) and the `task` preview (Decision 3) are **both
> included in this milestone**. Decisions 3 and 4 below record the final choices; the
> earlier "defer" framing is retained only as the rejected alternative.

## Context

The managed zsh layer already loads `Aloxaf/fzf-tab` (via `zinit light` in `plugins.zsh`)
and runs an unconditional `compinit` in `completions.zsh` (ADR-0046). The user wants
`task <Tab>` to present a contextual `fzf-tab` picker of the current Taskfile's tasks, with
descriptions, where selecting a task only inserts `task <name>` and the user presses `Enter`
to run it.

Probing the live macOS machine (go-task 3.50.0, Homebrew prefix `/usr/local`) established
the decisive fact:

- The native `_task` completion file **already exists** at
  `/usr/local/share/zsh/site-functions/_task` — installed by Homebrew, on the default
  `fpath`. `compinit` autoloads it through its `#compdef task` tag. **`task <Tab>`
  completion already works today with no extra zsh code**, and `fzf-tab` already wraps it.
- `task --completion zsh` emits only:

  ```zsh
  #compdef task
  typeset -A opt_args
  TASK_CMD="${TASK_EXE:-task}"
  compdef _task "$TASK_CMD"
  ```

  It is a registration shim that **assumes `_task` is already on `fpath`**. It does not
  carry the completion logic. Sourcing it is redundant when `_task` is present and
  non-functional when it is absent.

This reframes the work: the feature is mostly **already delivered by the package manager**.
The managed layer's job is to (a) own a small, guarded `taskfile.zsh` for task-specific
completion styling and future task-scoped tuning, and (b) decide — separately — whether to
correct a pre-existing `fzf-tab` load-order deviation.

## Proposed Structure

```
stow/common/zsh/.config/zsh/
├── index.zsh          # adds a guarded source of taskfile.zsh after completions.zsh
├── plugins.zsh        # CHANGED — owns the ordered init: zsh-completions (fpath) → compinit
│                      #   → fzf-tab → syntax-highlighting/autosuggestions (Option C)
├── completions.zsh    # CHANGED — styles-only; no longer runs compinit
├── taskfile.zsh       # NEW — guarded task-scoped completion styling + read-only preview
└── local.zsh.example  # cleanup of two stale examples (Decision 5)
```

`index.zsh` source order becomes:

```
... 5) plugins.zsh         # plugin + completion init, INCLUDING compinit (Option C)
    6) completions.zsh     # completion STYLES only — no compinit; runs after fzf-tab
    6b) taskfile.zsh  NEW  # task zstyles + preview → after compinit
    7) keybindings.zsh
    8) tools.zsh ...
```

## Design Decisions

### Decision 1: Source candidates from native `_task`, not from `task --completion zsh`

```
Option A: Source `task --completion zsh` in taskfile.zsh.
  Pro: Looks like "loading completion from the binary."
  Con: It is only a `compdef _task task` shim; it needs `_task` on fpath to work, so it
       adds nothing where it works and fails where it does not. Spawns a `task` subprocess
       every shell start.

Option B: Rely on the package-shipped `_task` file on the default fpath; compinit autoloads
          it via `#compdef task`.
  Pro: Truly native, zero startup cost, identical on brew and pacman, no subprocess.
  Con: Unavailable for non-package installs (go install / install.sh) that omit `_task`.

Decision: Option B. taskfile.zsh does not source `task --completion zsh`. Document the
brew/pacman install path as the supported one; note the non-package-install limitation in
the package README / setup guide.
```

### Decision 2: `taskfile.zsh` is guarded styling only — minimal contents

The file must be a no-op without `task`, and must only set completion `zstyle`s (which is
why it sources after `compinit`). It carries no heavy logic, no subprocess, no widget.

Proposed contents (final wording deferred to the plan/build step):

```zsh
# taskfile.zsh — go-task (Taskfile) completion tuning. Guarded; no-op without `task`.
#
# Native completion comes from the package-shipped `_task` file on the default fpath
# (Homebrew: .../share/zsh/site-functions/_task; Arch: /usr/share/zsh/site-functions/_task),
# autoloaded by compinit via its `#compdef task` tag. This file only tunes how those
# native candidates are presented. It must be sourced AFTER compinit.

command -v task >/dev/null 2>&1 || return

# Show task descriptions in the completion menu (fzf-tab renders this list).
zstyle ':completion:*:*:task:*' verbose true
```

```
Option A: Put this styling inside completions.zsh.
  Pro: One fewer file.
  Con: Mixes a tool-specific concern into the global completion file; user explicitly asked
       for a dedicated taskfile.zsh.

Option B: Dedicated taskfile.zsh, sourced after completions.zsh.
  Pro: Isolated, guarded, matches the per-tool file convention; easy to extend later
       (preview, launcher) without touching global completion config.
  Con: One more file + one more source line.

Decision: Option B.
```

### Decision 3: Include a conservative read-only task preview (with list fallback)

```
Option A: Add the preview now, read-only, with a safe fallback:
          zstyle ':fzf-tab:complete:task:*' fzf-preview \
            'task --summary "$word" 2>/dev/null || task --list-all 2>/dev/null'
  Pro: Shows the highlighted task's summary while browsing; when a task has no `summary:`,
       falls back to listing all tasks so the pane is never empty. Both `--summary` and
       `--list-all` print text only and never execute a task.
  Con: Slightly more surface than "summary only"; candidate words can be namespaced
       (`ns:task`) — handled because both subcommands are read-only and error-swallowed.

Option B: Defer the preview.
  Pro: Smallest change.
  Con: No inline information while browsing — rejected by the approved full scope.

Decision: Option A (approved). Preview is read-only: `task --summary "$word"` with a
`task --list-all` fallback, both `2>/dev/null`. Never `--dry`/`-n` (those can evaluate
preconditions/variables). The preview lives in `taskfile.zsh` next to its guard.
```

### Decision 4: fzf-tab load order — fixed in this milestone (Option C)

Upstream fzf-tab requires loading **after `compinit`** and **before** widget-wrapping
plugins (`zsh-syntax-highlighting`, `zsh-autosuggestions`). The current layer violates both:

- `plugins.zsh` (step 5) loads `fzf-tab` **before** `compinit` (step 6, `completions.zsh`).
- Within `plugins.zsh`, `fzf-tab` loads **after** syntax-highlighting and autosuggestions.

This milestone corrects both. (The fix is independent of the task feature itself — task
completion is plain `compinit`/`fpath` behavior — but it is in scope here by the approved
full-option decision.)

The correct ordering also has to respect `zsh-completions`, which must populate `fpath`
**before** `compinit`. That forces `compinit` to sit *between* `zsh-completions` and
`fzf-tab` — i.e. interleaved with plugin loading, which only `plugins.zsh` controls.

```
Option A: Leave order as-is.
  Pro: Zero change; empirically works.
  Con: Stays contrary to fzf-tab docs; fragile foundation as more completion features land.

Option B: Minimal reorder — move fzf-tab before the widget plugins inside plugins.zsh,
          keep compinit in completions.zsh.
  Pro: Fixes the "before widget plugins" half cheaply.
  Con: Still loads fzf-tab before compinit (the other half remains wrong).

Option C: Canonical reorder — move compinit into plugins.zsh, interleaved:
            zinit blockf for zsh-users/zsh-completions   # fpath
            autoload -Uz compinit && compinit            # after fpath, before fzf-tab
            zinit light Aloxaf/fzf-tab                    # after compinit
            zinit light zsh-users/zsh-syntax-highlighting # widget-wrap, after fzf-tab
            zinit light zsh-users/zsh-autosuggestions     # widget-wrap, after fzf-tab
          The no-zinit `else` branch keeps a fallback `autoload -Uz compinit && compinit`
          so completion still works without zinit. completions.zsh becomes styles-only.
  Pro: Satisfies both fzf-tab rules and the zsh-completions fpath rule; one compinit per
       path; correct, durable foundation.
  Con: Moves compinit ownership from completions.zsh to plugins.zsh → supersedes ADR-0046;
       larger diff; needs its own ADR + review.

Decision: Option C (approved), folded INTO this milestone. compinit moves into
`plugins.zsh`, interleaved between `zsh-completions` (fpath) and `fzf-tab`; the no-zinit
`else` branch keeps a fallback `compinit`; `completions.zsh` becomes styles-only. A new ADR
(0049) supersedes ADR-0046 for compinit *location*. taskfile.zsh sources after compinit
regardless, so it is robust to the new placement.

Note on completion *styles* vs *paths*: only `fpath` plugins (`zsh-completions`) must precede
compinit. Completion `zstyle`s are read at completion time, not compinit time, so the style
files (`completions.zsh`, `taskfile.zsh`) correctly run *after* compinit — and `completions.zsh`
must run after `fzf-tab` anyway because it sets `:fzf-tab:*` preview styles.
```

### Decision 5: Clean up stale `local.zsh.example` entries

Two example blocks in `local.zsh.example` are now outdated and should be removed/updated in
the same effort, since this milestone touches the zsh package and the user flagged them:

- **Extended eza aliases** (`alias ll='eza -lh' && alias la='eza -lha'`): contradicts
  ADR-0042 (eza minimal alias-only) and ADR-0044 (personal preferences live in committed
  zsh files), and duplicates the `ll` already defined in `aliases.zsh`. Remove.
- **zoxide `--cmd cd` override** example: redundant — `tools.zsh` already initializes
  `zoxide init --cmd cd` by default per ADR-0047. Remove.

The location-specific weather alias example stays (genuinely machine/local-specific).

## Risks

- **Install-method gap:** non-package `task` installs lack `_task`; completion silently
  unavailable. Mitigation: document brew/pacman as the supported path; guard means no error.
- **Platform divergence:** Arch's site-functions dir differs from macOS's; both are on the
  default `fpath`, but a machine with a stripped `fpath` could miss `_task`. Mitigation:
  documented as a limitation, not worked around in code.
- **Ordering change (Option C, included):** moving compinit risks double-init or a missing
  fallback when zinit is absent. Mitigation: exactly one `compinit` per path — the zinit
  branch runs it once, the no-zinit `else` branch keeps a fallback, and it is removed from
  `completions.zsh`; covered by ADR-0049 (supersedes 0046) + review.
- **Reversibility:** taskfile.zsh + one source line are trivially reversible; no `$HOME`
  changes in this milestone.
- **Privacy:** none — file holds only completion zstyles.

## Extensibility

- A future standalone launcher (a `zle` widget bound to a key, or a `taskmenu` function) can
  live in the same `taskfile.zsh` without disturbing the source order.
- The corrected Option C order is now the durable base for any additional completion-driven
  features (more per-tool previews, additional fpath completions before compinit).

## Open Questions

- None. Both prior open questions resolved by the approved full scope: Option C (fzf-tab
  reorder + ADR-0049 superseding 0046) and the read-only preview are both in this milestone.

## Recommended Next Step

The implementation plan already exists: **`docs/plans/0019-implement-taskfile-completion.md`**.
It covers the full approved scope in one milestone:

1. Reorder `plugins.zsh` to Option C (zsh-completions fpath → `compinit` → `fzf-tab` →
   syntax-highlighting/autosuggestions; fallback `compinit` in the no-zinit branch).
2. Trim `compinit` out of `completions.zsh` (styles-only).
3. Create guarded `taskfile.zsh` (Decision 2) with the read-only preview (Decision 3).
4. Source `taskfile.zsh` from `index.zsh` after `completions.zsh`.
5. `local.zsh.example` cleanup (Decision 5).
6. Write **ADR-0049** superseding ADR-0046 (compinit location); mark 0046 Superseded.
7. zsh setup guide / package README note; `stow --simulate` dry-run for the user.

The fzf-tab reorder and ADR-0049 are part of this milestone (Plan 0019), not a separate
future change. No implementation until Plan 0019 is approved by the user.
