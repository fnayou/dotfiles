# Decision: Operator-Initiated Provisioning Runs Lift the `AGENTS.md` §8 Stow Ban

**Number:** 0065
**Date:** 2026-08-04
**Status:** Accepted
**PRD:** 0023 — Agent-Facing Install and Update Documents
**Architecture:** 0022 — Agent-Facing Install and Update Documents
**Supersedes:** N/A (lifts specific `AGENTS.md` §8 prohibitions for one bounded invocation)

## Context

`AGENTS.md` §8 forbids exactly the operations that installing these dotfiles consists of:

> - Do not run `stow` without explicit user approval.
> - Do not create symlinks without explicit user approval.
> - Do not run `rm`, `mv`, or `ln -s` against `$HOME`.
> - Do not modify files outside the repository.

That is correct for the work `AGENTS.md` was written to govern: **authoring** this repository. An
agent changing packages, docs, or scripts has no business touching `$HOME`, and the ban is what keeps
a development session from wandering into the operator's live configuration.

**Deploying the repository points the opposite way.** Symlinking into `$HOME` is not a hazard to be
avoided there; it is the entire task. An agent asked to provision a machine reads its operating
contract, finds the task forbidden, and — if it is careful, which is the behaviour we want — refuses
or stalls at every step.

PRD 0023 makes this concrete: runs are unattended, so "without explicit user approval" cannot be
satisfied per-command mid-run. Either the approval is understood to attach to the invocation, or an
autonomous run is impossible.

ADR-0052 established the precedent. It lifted the ADR-0009 ban on mutating Taskfile tasks for
`os-maintenance` specifically, by naming what was lifted and for which case rather than by softening
the original rule.

## Decision

**When an operator asks an agent to perform an install or update run using `docs/agent/install.md`
or `docs/agent/update.md`, the operator's request is the approval that `AGENTS.md` §8 requires.**

For the duration of that run, and only then, these are permitted:

- `stow --no-folding` and `stow --simulate` against `$HOME`, for packages in `stow/common/`
- the symlinks that stow thereby creates in `$HOME`
- `task zsh:bootstrap` and `task git:bootstrap`, which modify `~/.zshrc` and `~/.gitconfig` behind
  their own backup and idempotency guarantees
- `bat cache --build`, which writes only `~/.cache/bat`
- `git switch -C deployed <tag>` within the checkout, subject to Architecture 0022 decision 7

**These remain absolutely forbidden, during a run and outside it:**

- `sudo`, and installing any system package
- `stow --adopt`, under every circumstance
- `rm` or `mv` against `$HOME`, or any deletion or overwrite of an existing user file
- writing anywhere outside `$HOME` and the repository checkout
- fetching third-party code, including the Zinit clone
- hand-editing `~/.zshrc` rather than using `task zsh:bootstrap`
- creating `local.zsh` or any private file (ADR-0064)
- `chsh` (ADR-0027, PRD-0007)
- resolving a stow conflict by any means

The forbidden list is stated **before** the permitted list in both agent documents, and is longer
than it. That ordering is deliberate: a reader who stops early should stop on the constraints.

## Scope

The relaxation is keyed to **the invocation**, not to a class of agent, a repository state, or a
trusted tool.

- It applies when an operator asks for an install or update run and the agent is following
  `docs/agent/install.md` or `docs/agent/update.md`.
- It does not apply to ordinary development sessions in this repository, whatever the agent.
- It does not apply because a machine looks unprovisioned, because `doctor` reports failures, or
  because an agent judges provisioning to be helpful.
- It cannot be inferred. Absent an explicit request, §8 applies unchanged.

Nothing here weakens §8 for any other purpose. `AGENTS.md` is loaded into every session in this
repository, so this ADR must not read as a general softening — it reads as: *when the operator asks
you to provision this machine, stowing is the task, not a violation.*

## Consequences

- An agent can complete an unattended provisioning run without violating its operating contract, and
  without needing the contract weakened for everyone else.
- Because the per-step human gate is gone, safety rests on structure instead: Assess is read-only so
  an abort is provably harmless; stow preflights every package before installing any, so no
  partial-stow state exists; every permitted mutation is idempotent and reversible by a documented
  command. Those properties are load-bearing, not incidental — weakening one weakens this ADR.
- The permitted list is a closed set. A step not on it is forbidden, including steps that seem
  obviously helpful. Extending it requires amending this ADR, which is the point.
- `AGENTS.md` §8 gains a pointer to this ADR so a reader of the ban finds its one exception.
- A conflict, a missing prerequisite, or an unexpected state ends the run. The agent never improvises
  a way past an obstacle, because "use judgement" is precisely what an unattended run cannot do
  safely.

## Alternatives rejected

- **Amend `AGENTS.md` §8 directly to permit stow.** Would weaken the ban for every session, including
  ordinary development where it is exactly right. The ban's value is that it is unconditional in the
  context it governs.
- **Grant the relaxation to a trusted agent or tool.** Unenforceable — nothing verifies which agent is
  reading the file — and wrong in principle: the operator's request is what constitutes approval, not
  the identity of whoever received it.
- **Require per-step confirmation instead.** Rejected by PRD 0023, which chose unattended runs
  deliberately. It would also mean roughly ten prompts per machine, which the operator explicitly did
  not want.
- **Put the relaxation in the documents rather than an ADR.** The documents are the thing being
  authorised; a permission that authorises itself is not a control. It belongs where the original
  prohibition lives, in the decision record.
