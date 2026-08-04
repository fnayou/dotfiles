# Decision: Machine Health Verification Is a Read-Only, Offline `task doctor`

**Number:** 0063
**Date:** 2026-08-04
**Status:** Accepted

## Context

The repository could tell you what it *intends*, but not whether a machine *matched* that intent.
Existing checks each answer a narrower question: `task check` covers repository prerequisites
(`stow`, `git`, `task`), `deps:check:zsh` and `deps:check:nvim` cover tool presence, and
`check-statusline.sh` covers one package's behaviour. None of them answers "is this machine set up the
way the repository says it should be?"

That gap matters more here than it would in most projects, because of a deliberate design property:
**every managed layer is guarded.**

```zsh
command -v herdr >/dev/null 2>&1 || return
[[ -r "$HOME/.config/zsh/speedtest.zsh" ]] && source ...
```

Guards are what let a partially-adopted machine start a clean shell — a property worth keeping. The
cost is that failure is expressed as **absence, not error**. A missing tool, an unlinked file, an
uncopied `.example`, or a mis-ordered `PATH` all produce a shell that starts perfectly and quietly
lacks a feature. "It works" is therefore not observable by running it.

ADR-0062 is the proof. A completion silently failed to register for months on a machine that looked
healthy by every available check, and was found only when a human noticed `<Tab>` behaving oddly.

Two further failure modes have no detector at all:

- **Re-stow drift.** Because packages are per-file symlinks (ADR-0024), pulling a commit that adds a
  *new* file to an existing package leaves that file unlinked in `$HOME`. `index.zsh` guards the
  absence into silence. `speedtest.zsh` was exactly this shape.
- **Directory folding.** A package stowed without `--no-folding` makes `~/.config/<pkg>` a symlink,
  which silently prevents local-only files from living beside managed ones.

## Decision

Add **`task doctor`**, backed by a single `scripts/doctor.sh`, as the machine-state verifier.

Four properties define it:

1. **Read-only, always.** It installs, stows, links, moves, and deletes nothing, and writes nothing
   inside `$HOME`. This is what makes it safe to run *when you already suspect something is wrong* —
   the moment a repair-capable tool is most dangerous. The one subprocess it starts, the probe shell,
   runs with `HISTFILE` redirected into a temp directory so real shell history is never touched.
2. **Offline.** Version reporting uses local refs only; no `fetch`. A doctor must work on a freshly
   provisioned or disconnected machine, and must not stall on network.
3. **It asserts positives.** Because guards make absence silent, the check cannot infer health from
   the lack of errors. It starts a **probe shell with a deliberately minimal `PATH`** — reproducing a
   terminal launched from a desktop session rather than inherited from an already-configured one —
   and reads back what actually registered (`${+_comps[herdr]}`, `${+functions[speed]}`, the zoxide
   hook count). This reproduces the ADR-0062 condition directly rather than describing it.
4. **Absence of an optional tool is not a failure.** Layers no-op by design, so a missing tool is
   reported as `INFO`. `FAIL` is reserved for a machine that contradicts the repository's intent:
   installed-but-unregistered, unlinked managed files, folded directories, a symlinked `~/.zshrc`.
   Only `FAIL` sets a non-zero exit.

## Consequences

- Machine state becomes checkable in one command, on all three platforms, without touching anything.
- The ADR-0062 class of bug is now detected instead of endured — both statically (`PATH` assignments
  in `local.zsh`, reported by line number only, never by content, since `local.zsh` is private) and
  dynamically (the probe).
- Re-stow drift and folding violations gain their first detector.
- The planned agent-facing install and update documents get a trustworthy terminal step: both can end
  with `task doctor` rather than each re-deriving what "correctly installed" means. This was the
  reason to build it first.
- The check must itself be verified, since a detector that never fires is worse than none. Its
  failure path is exercised against a sandbox `$HOME` — see review 0071.
- Adding a package or a guarded layer now carries a second obligation: give `doctor` something to
  assert about it, or it is invisible.

## Alternatives rejected

- **Extend `scripts/check.sh`.** It answers "can I work *on* this repository?" — a prerequisite
  question asked from a clean checkout. `doctor` answers "is this machine correctly *running* the
  repository?" Merging them would produce a script whose meaning depends on where it is run.
- **A doctor per package.** Mirrors the package structure, but re-derives OS detection, symlink
  resolution, and probing ten times and drifts apart. Rejected for the same reason ADR-0050 chose one
  detecting script over per-OS files.
- **Run it in CI.** CI has no stowed `$HOME`, so every meaningful assertion would be skipped, and the
  hygiene workflow's non-destructive guarantee would be muddied. `doctor` is a local instrument.
- **Let it offer to fix what it finds.** A repairing doctor cannot honestly claim read-only, which is
  the property that makes it safe to reach for first. It prints the dry-run command instead and
  leaves the decision with the operator, consistent with the repository's no-destructive-automation
  stance.
