# PRD: Agent-Facing Install and Update Documents

**Number:** 0023
**Status:** Draft
**Date:** 2026-08-04

## Context

These dotfiles are provisioned onto new machines by pointing an AI agent — Claude, opencode, or pi —
at the repository and asking it to explore and install. On already-provisioned machines the same
pattern is used to check tags and apply what changed.

It works, but it re-derives the same knowledge every time, and exploration is where variance lives.
An agent reasoning from scratch can stow without `--no-folding` (violating ADR-0024), reach for
`--adopt`, or write `PATH` into `local.zsh` — the last of which the repository's own example file was
*teaching* until ADR-0062 corrected it.

Two structural facts make this worse than it sounds:

1. **`AGENTS.md` forbids installation.** §8 says do not run stow, do not create symlinks, do not
   modify files outside the repository. An agent that reads its operating contract and is then asked
   to install will, if careful, refuse or stall. The contract is written for *authoring* the
   repository, not for *deploying* it — the two point in opposite directions.
2. **Failure is silent.** Every layer is guarded, so a mis-installed machine starts a clean shell and
   quietly lacks features. `task doctor` (ADR-0063) now exists to assert the positives; these
   documents are what will call it.

## Goals

- One document that provisions this repository onto a new machine, followed end-to-end by an agent
  with no human intervention during the run.
- One document that brings an already-provisioned machine up to the latest tag.
- Both usable by Claude, opencode, and pi from plain markdown, with no tool-specific machinery.
- Both end by running `task doctor` and reporting its result.
- Both produce a **structured final report**: what succeeded, what failed, and what still needs the
  operator — the report is a first-class deliverable, not a summary.
- Installation of *system packages* is detected and reported, never performed.
- An explicit, bounded relaxation of `AGENTS.md` §8 that applies only to an operator-initiated
  install or update run, so a careful agent knows it is permitted to proceed.
- Corner cases that currently exist only as tribal knowledge become written preconditions:
  `--no-folding` (ADR-0024), never `--adopt`, `~/.zshrc` stays unmanaged (ADR-0027), `PATH` above the
  managed block (ADR-0062), `.example` templates copied but never invented, Zinit's manual clone
  (ADR-0020), login-shell setup, and per-file re-stow after new files land.

## Non-Goals

- Replacing the human setup guides in `docs/guides/`. Those stay human-oriented; these are separate.
- Installing system packages, or holding `sudo` in any form.
- Provisioning anything outside this repository's scope — no SSH keys (ADR-0005), no secrets, no
  work configuration.
- Supporting platforms beyond macOS, Arch / EndeavourOS, and Debian.
- Automating the release/tagging flow. That is `ship-change`'s job.
- A GUI, TUI, or interactive wizard.

## User Stories

- As an operator with a fresh machine, I want to point any AI agent at this repository and get a
  working setup without answering questions mid-run, so that provisioning costs me one instruction.
- As an operator, I want a single report at the end naming every failure and every thing still
  requiring me, so that an unattended run does not hide problems.
- As an operator on an existing machine, I want the agent to determine what changed since my current
  tag and apply exactly that, so that updates do not become re-installations.
- As an operator whose machine lacks tools, I want the exact per-OS install command printed for me to
  run, so that the agent never holds `sudo`.
- As an agent, I want an explicit statement of when `AGENTS.md` §8 does not apply, so that I can
  install without violating my operating contract.

## Constraints

**Platform** — macOS, Arch / EndeavourOS, and Debian must be handled separately. Debian has no
platform zsh layer today and several tools are not in its archive (`go-task`, `oh-my-posh`,
`git-cliff`). Note: `scripts/detect-os.sh` does not currently recognise Debian (finding 1 of review
0071); these documents must not depend on it until that is fixed.

**Autonomy** — the run is unattended. There is no human gate mid-run, so every safety property must
be structural rather than conversational.

**Privilege** — the agent must never invoke `sudo`, and must never install a system package.

**Portability** — plain markdown only. No Claude skills, hooks, or frontmatter that other agents
cannot read.

**Reversibility** — every mutation the agent performs must be undoable by a documented command.

**Offline** — `task doctor` is offline; the update document may fetch, and must say so.

## Safety Requirements

Autonomy removes the per-step human gate, so these replace it. They are the core of this PRD.

- **Preflight everything, then commit.** Every package must be simulated (`stow --simulate`) *before
  any* package is stowed. If any simulation reports a conflict, the run aborts having changed
  nothing, and reports. Partial installs are not acceptable.
- **A conflict is a stop, never a resolution.** The agent must not delete, move, rename, or back up
  a conflicting file, and must never use `--adopt`. It reports and leaves it for the operator.
- **Must not delete or overwrite any existing user file.** No `rm`, no `mv`, no truncation anywhere
  in `$HOME`.
- **Must not write outside `$HOME` and the repository checkout.**
- **`--no-folding` is mandatory** on every stow invocation (ADR-0024).
- **`~/.zshrc` is modified only via `task zsh:bootstrap`**, which is idempotent and takes a
  timestamped backup. The agent must not hand-edit it, and must refuse if it is a symlink.
- **`.example` templates are copied, never filled.** The agent must not invent values for private
  files. It copies the template where the repo prescribes and lists what needs human completion.
- **No secrets are generated, requested, or written.**
- **The run must be interruptible without leaving a broken shell.** Because every layer is guarded, a
  half-stowed machine must still open a working shell — this is asserted, not assumed.
- **`task doctor` runs last**, and its findings appear in the report even when everything passed.

## Acceptance Criteria

- [ ] `docs/agent/install.md` exists and is tool-neutral plain markdown.
- [ ] `docs/agent/update.md` exists and is tool-neutral plain markdown.
- [ ] Both state their preconditions, the permitted-actions boundary, and the abort conditions before
      any command appears.
- [ ] An ADR records the bounded §8 relaxation for operator-initiated install/update runs, following
      the ADR-0052 precedent of naming exactly what is lifted and for which case.
- [ ] `AGENTS.md` and `CLAUDE.md` each carry a one-line pointer to `docs/agent/`, and state that it
      is a different contract from the authoring workflow. The install content itself is **not**
      inlined into either file.
- [ ] The install document defines the full preflight-then-commit sequence, with the abort-on-any-
      conflict rule stated before the first stow command.
- [ ] The install document detects missing tools per OS and prints the exact install command without
      running it.
- [ ] The update document determines the current tag, identifies what changed since it, and
      distinguishes changes that need a re-stow (new files) from those that do not (edits to
      already-linked files) — the distinction that made `speedtest.zsh` invisible on a pulled-but-
      not-re-stowed machine.
- [ ] Both documents define the same report structure: succeeded / failed / needs-operator, with
      `task doctor` output included.
- [ ] Every corner case listed under Goals appears as an explicit precondition or step.
- [ ] Both documents were executed end-to-end by an agent against a **sandbox `$HOME`**, and the
      resulting report and `task doctor` output are recorded in a review under `docs/reviews/`.
- [ ] Neither document instructs any use of `sudo`, `--adopt`, `rm`, or `mv` against `$HOME`.

## Open Questions

1. **Does an install run resolve ADR-0020's Zinit clone?** ADR-0020's five stated reasons are all
   shell-startup concerns — latency, offline start, wedged shells, drift — none of which apply to a
   provisioning run. But its decision text says the clone is one "the user runs deliberately," which
   an autonomous agent contradicts literally. Either the install document clones Zinit under a
   bounded exception, or it reports Zinit as missing and prints the command. **Must be settled by ADR
   before the install document is written.**
2. **Is the §8 relaxation one ADR or two?** Install mutates `$HOME` substantially; update mutates far
   less. One ADR covering "operator-initiated provisioning runs" is simpler; two would let update
   keep a tighter boundary.
3. **Where does the report go?** Printed to the operator only, or also written to a file? A file is
   greppable across many machines but is a new artifact in `$HOME`.
4. **Does update handle a dirty working tree**, or abort? Aborting is safer and simpler; handling it
   is friendlier on a machine where the operator has been experimenting.

## Out of Scope

- Running `sudo` or installing system packages.
- Resolving stow conflicts automatically, under any circumstance.
- SSH configuration and key management (ADR-0005).
- Secret provisioning, credential helpers (ADR-0015), and anything private.
- Debian's missing platform zsh layer, and the `detect-os.sh` Debian gap — both are separate fixes.
- Uninstall / de-provisioning. Rollback commands are documented, but a full uninstall runbook is not
  part of this.
- Multi-machine orchestration; each run targets the machine it is on.
- CI execution of these documents. CI has no stowed `$HOME`.
