# Architecture: Agent-Facing Install and Update Documents

**Number:** 0022
**Status:** Draft
**Date:** 2026-08-04
**PRD:** 0023 — Agent-Facing Install and Update Documents

## Context

PRD 0023 is approved with all four open questions resolved: Zinit is reported rather than cloned, one
ADR carries the `AGENTS.md` §8 relaxation, the report is printed rather than written, and update
aborts on a dirty working tree.

Two properties of the target shape the design more than anything else:

- **The reader is a language model, not a shell.** These are documents, not scripts. They are
  interpreted by Claude, opencode, or pi, each with different context handling and no shared runtime.
  Precision has to come from prose and explicit command blocks, not from control flow.
- **The run is unattended.** There is no human to resolve an ambiguity mid-run, so every branch the
  agent could face must be pre-decided in the document, and anything undecided must map to *stop and
  report* rather than *use judgement*.

## Proposed Structure

```
docs/agent/
├── README.md      Entry point: which document to use, and the shared contract
├── install.md     Fresh machine → fully provisioned
└── update.md      Provisioned machine → current with the latest tag
```

`docs/agent/` is a new sibling of `docs/guides/`. The separation is deliberate and already implied by
the repository: `README.md` states that setup guides are "written for a human operator, not for
agents". These are the counterpart, and mixing them would degrade both — human guides would gain
machine-oriented preconditions, and agent documents would gain explanatory prose that costs context
without changing behaviour.

`README.md` holds what both documents share — the permitted-actions boundary, the abort rules, the
report format — so neither document restates it and the two cannot drift apart.

## Design Decisions

### 1. Three-phase structure, identical in both documents

Every run is **Assess → Act → Report**, with a hard gate between the first two.

```
Assess   read-only. Detect OS, tools, current state, what needs doing.
         Produces a plan and a list of blockers. Changes nothing.
   │
   ├── any blocker? ──→ Report and STOP. Nothing has changed.
   ▼
Act      execute the plan. Mutations happen only here.
   ▼
Report   task doctor, then the structured report.
```

The gate is the safety architecture. Because Assess is entirely read-only, a run that aborts there is
provably harmless, which is what makes an unattended run defensible without a per-step human gate.

### 2. Preflight-all-then-commit for stow

Within Act, all stow simulations run before any stow install:

```
for each package:  stow --simulate --no-folding   →  collect conflicts
if any conflict:   report and stop, nothing stowed
else:              stow --no-folding, package by package
```

The alternative — simulate-then-install per package — is rejected. It produces a partially stowed
machine when package seven conflicts, which is the state hardest to reason about and the one a
report can least usefully describe.

### 3. The contract section is the first thing in each document

Before any command appears, each document states what the agent may and may not do. This is
positioned first because a model that reads the commands before the constraints may act on the
commands.

The permitted set (install): `stow --simulate`, `stow --no-folding`, `task zsh:bootstrap`,
`task git:bootstrap`, `cp` of `.example` templates to their documented destinations, `task doctor`,
and read-only inspection.

The forbidden set, absolute and unchanged by the §8 relaxation: `sudo`, `stow --adopt`, `rm`, `mv`,
any write outside `$HOME` and the checkout, any fetch of third-party code, hand-editing `~/.zshrc`,
inventing values for `.example` templates, and resolving a stow conflict by any means.

### 4. The §8 relaxation is bounded by invocation, not by agent

One ADR, following ADR-0052's precedent of naming exactly what is lifted and for which case. The
relaxation is keyed to **an operator asking for an install or update run** — not to a class of agent
and not to a repository state. Outside that invocation, §8 applies unchanged.

This matters because `AGENTS.md` is loaded in every session in this repository. The ADR must not read
as a general softening; it must read as "when the operator asks you to provision this machine,
stowing is the task, not a violation."

### 5. Update classifies changes by whether they need a re-stow

The distinction that made `speedtest.zsh` invisible on a pulled-but-not-re-stowed machine:

| Change since the operator's tag | Action needed |
|---|---|
| Edit to a file already linked | None — the symlink already points at it |
| **New file in an existing package** | **Re-stow that package** |
| New package | Stow it, if the operator wants it |
| Removed file | Re-stow; report the orphaned link |
| `.example` template changed | Report — the operator's real file is theirs to update |

Only the second row is counter-intuitive, and it is the one that fails silently. `task doctor`'s
linkage check detects it independently, which gives update a verifier it does not have to trust
itself for.

### 6. The report is a fixed structure, printed

```
1. What ran            OS, tag range, packages touched
2. Succeeded           per package / per step
3. Failed              with the exact error, and what was NOT attempted as a result
4. Needs the operator  missing tools with install commands, Zinit clone,
                       .example files awaiting real values, unresolved conflicts
5. task doctor         verbatim output
6. Verdict             complete / complete-with-caveats / aborted
```

Section 4 is the one that earns the design. An unattended run's failure mode is a silently
half-finished machine, and on a Zinit-less machine that section is the *expected* outcome, not an
exception. The verdict deliberately has three values rather than two: `complete-with-caveats` is what
a correct run on a machine missing Zinit or `oh-my-posh` returns, and collapsing it into either
`complete` or `aborted` would misinform.

### 7. Documents assert, `doctor` verifies

Neither document re-derives what "correctly installed" means. Both end with `task doctor` and quote
it. This is why it was built first (ADR-0063), and it keeps the definition of health in one place
that is independently tested.

## Risks

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Agent improvises past the contract | Medium | High | Contract stated first; every undecided branch maps to stop-and-report; forbidden set is explicit and short |
| Agent resolves a stow conflict "helpfully" | Medium | **High** | Named as absolutely forbidden in both documents and the ADR; conflicts abort the run |
| §8 ADR read as a general softening | Low | High | Relaxation keyed to invocation; ADR states what remains absolute before what is lifted |
| Documents drift from the repository | Medium | Medium | Shared contract in one file; `doctor` is the single definition of health; acceptance criteria require a sandbox run |
| Model without the context window for the whole document | Medium | Medium | Keep each document short and imperative; push shared material into `README.md`; no long rationale |
| Debian path least exercised | High | Medium | Debian has no platform zsh layer and lacks `go-task`/`oh-my-posh`/`git-cliff`; document explicitly, expect `complete-with-caveats` |
| Sandbox validation not representative | Medium | Medium | Validate against a sandbox `$HOME`, and state plainly that it is not a real fresh machine |

## Extensibility

- A third document (`uninstall.md`) fits the same three-phase shape if wanted later; PRD 0023 scopes
  it out.
- New packages need no document change — both documents iterate `stow/common/*` rather than naming
  packages, so the directory stays the source of truth.
- If `os-maintenance` gains Debian support, update could optionally call it; deliberately not now.

## Open Questions

None blocking. One worth revisiting after first use: whether `install.md` should refuse to run at all
when `git`, `stow`, `task`, or `zsh` is missing, or proceed with what it can and report the rest.
Current lean is refuse — a machine without `stow` cannot be provisioned in any meaningful sense, and
a partial run muddies the report.

## Recommended Next Step

Review this architecture against PRD 0023. On pass, write the §8 ADR first — it is a prerequisite for
the documents, since they must cite it — then plan the two documents and their sandbox validation.
