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
`task git:bootstrap`, `bat cache --build`, `task doctor`, and read-only inspection. That is the whole
list.

`bat cache --build` is there because `bat` is the only package needing a step after stowing: it loads
themes from a compiled cache, so a stowed config naming an unbuilt theme is ignored. bat then exits 0
and prints normally with its default theme, which makes the failure invisible even to inspection. The
command is idempotent, writes only to `~/.cache/bat`, is reversible with `bat cache --clear`, and
needs no privilege. On Debian the binary is `batcat`.

The forbidden set, absolute and unchanged by the §8 relaxation: `sudo`, `stow --adopt`, `rm`, `mv`,
any write outside `$HOME` and the checkout, any fetch of third-party code, hand-editing `~/.zshrc`,
and resolving a stow conflict by any means.

**The agent never creates `local.zsh`.** It reports its absence under *needs the operator* and stops
there. `local.zsh` is the designated home for private, machine-specific values (ADR-0023, ADR-0026),
and authoring it is the operator's act — copying a skeleton in on their behalf would put an agent's
guess where their secrets belong. This also honours ADR-0036's original intent even though ADR-0054
later reintroduced the template for human use.

This leaves the permitted set with **no configuration-file creation verb**. Every mutation is a stow
symlink, a repository-owned bootstrap task, or one tool-owned cache build — each idempotent and
reversible by a documented command. The agent authors no file whose contents it had to decide.

That is the property worth defending as new steps are proposed. It is deliberately narrower than the
"no file-creation verb at all" phrasing this document carried before `bat cache --build` was added:
the stronger claim was true only for as long as the permitted set happened to omit an activation step,
and overstating it would have made the next such step look like a violation rather than a normal
extension.

### 4. The §8 relaxation is bounded by invocation, not by agent

One ADR, following ADR-0052's precedent of naming exactly what is lifted and for which case. The
relaxation is keyed to **an operator asking for an install or update run** — not to a class of agent
and not to a repository state. Outside that invocation, §8 applies unchanged.

This matters because `AGENTS.md` is loaded in every session in this repository. The ADR must not read
as a general softening; it must read as "when the operator asks you to provision this machine,
stowing is the task, not a violation."

### 3a. Missing prerequisites abort in Assess

Three tools are blocking: **`stow`**, **`task`**, and **`zsh`**. Absent any of them, the run aborts in
Assess having changed nothing, and reports the per-OS install command. (`git` is present by
definition — the checkout could not otherwise exist.)

Everything else is optional. A missing `fzf`, `eza`, or `oh-my-posh` produces an inert layer by
design and belongs in *needs the operator*, not in an abort.

This matters most on Debian, which is where the servers are: `packages/debian/packages.txt` records
that **go-task is not in the Debian archive**, installable only through a `curl | sh` script the agent
is forbidden to run. So the expected first outcome on a fresh Debian server is `aborted`, with the
go-task command printed; the operator installs it out-of-band and invokes again. Two invocations, by
design, consistent with the PRD's detect-print-never-install stance.

A tempting alternative was rejected: having the documents carry raw equivalents of the bootstrap
tasks so `task` would not be required. `zsh:bootstrap` performs symlink refusal, timestamped backup,
and idempotent block insertion. A markdown reimplementation of that will drift from the Taskfile, and
the copy is the one running unattended against the operator's real `~/.zshrc`.

### 3b. Install stows every package, with no per-machine subset

All ten packages, on every machine, with no exclusion mechanism. No package is platform-conditional —
they all live in `stow/common/`, and `macos/`, `arch/`, `debian/` are empty — so there is no technical
filter to apply, only a policy.

The deciding argument is not that inert configs are harmless, though they are. It is that **a
per-machine subset would destroy `doctor`'s central invariant.** Today it can report:

```
INFO: 10 of 10 package(s) stowed
```

If machines legitimately carried different subsets, `doctor` could never distinguish "deliberately
excluded" from "failed to stow" or "someone unstowed it". `SKIP: alacritty (not stowed)` would become
permanent background noise on every server — and noise an operator learns to skip past is how a
checker stops being read at all. That is the same failure mode that made `FAIL` the wrong severity
for a deliberately-chosen login shell.

Stowing everything makes **fully-stowed the only healthy state**, so any deviation is a real signal.
The cost is a handful of inert symlinks under `~/.config` on headless servers — exactly what the
guard design already tolerates everywhere else.

### 4b. Update pins the checkout to a tag, on a named branch

Update moves the working tree to the newest tag — genuinely, not by tracking `main`. Because packages
are symlinked *into this checkout*, the checkout's content **is** the deployed configuration, so
pinning it to a tag is what makes "this machine runs v2026.08.1" a true statement.

It does so with a **named branch pointer, never a detached HEAD**:

```bash
git switch -C deployed <tag>
```

The content is exactly the tag's. The difference is that the live configuration is served from a
named ref rather than an unnamed one — which matters here far more than in a normal repository,
because a confused later `git` operation would be operating on the files the running shell is reading.

**Refusal rule: update will not move to a tag older than the checkout it is running from.**

The reason is specific to this repository's shape. `stow/common/**` is deployed configuration;
everything else — `scripts/`, `docs/agent/`, `Taskfile.yml` — is the tooling that performs the
deployment. A tag checkout is a whole-tree operation, so pinning the configuration also pins the
tools. Checking out a tag that predates `scripts/doctor.sh` would delete the verifier that the
update's own final step calls, and delete `update.md` mid-run.

So:

```
target  = newest tag on origin
tooling = HEAD of the current checkout

if target is an ancestor of HEAD:   refuse, report, change nothing
else:                                git switch -C deployed <target>
```

**Install obeys the same rule, and the clone command is what makes that possible.** If install left
the checkout on `main` while update pinned to tags, every freshly installed machine would be born
refusing its first update, since `main` is always ahead of the newest tag. So install pins too — and
to stop a fresh clone from refusing its own first install for that same reason, the documented entry
point clones *at the tag*:

```bash
git clone --branch <newest-tag> https://github.com/fnayou/dotfiles.git ~/work/dotfiles
```

`HEAD` is then the tag itself, so the `install.md` driving the run and the `doctor` ending it are both
from the version being deployed — there is no skew left to reason about. `--branch <tag>` leaves a
detached HEAD, so install's first act is `git switch -C deployed <tag>`.

Install and update therefore share one rule with two entry points: *be at a tag, on `deployed`, never
move backwards.* The branch is named `deployed` because it states what it is, collides with no git
convention, and cannot be mistaken for `main`.

**Migration cost, stated once:** existing machines are on `main` ahead of the newest tag, so adopting
this needs either a fresh tag or a deliberate `git switch -C deployed <tag>` per machine. One-time
step, not an ongoing tax.

This guarantees the document and the verifier are always the pair that was tested together — never a
new document driving an old `doctor`, nor the reverse.

**Adoption consequence, stated because it will be hit immediately:** a machine currently tracking
`main` ahead of the newest tag — which is every machine today — will be *refused* on its first update
until a new tag is cut. That is the correct outcome, not a bug: moving it to the newest tag would be
a tooling downgrade. Cutting a tag is the documented unblock, and it is a step this repository
already performs routinely.

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
                       non-zsh login shell, absent local.zsh, unresolved conflicts
5. task doctor         verbatim output
6. Verdict             complete / complete-with-caveats / aborted
```

Section 4 is the one that earns the design. An unattended run's failure mode is a silently
half-finished machine, and on a Zinit-less machine that section is the *expected* outcome, not an
exception. The verdict deliberately has three values rather than two: `complete-with-caveats` is what
a correct run on a machine missing Zinit or `oh-my-posh` returns, and collapsing it into either
`complete` or `aborted` would misinform.

### 6b. The login shell is checked, never changed

`chsh` is a forbidden repository action (ADR-0027 / PRD-0007), and it prompts for a password an
unattended run could not answer even if it were permitted. So the run detects the login shell,
reports it, and prints the `chsh` command.

This matters more than its size suggests. On a machine whose login shell is still bash, every package
can stow correctly, every bootstrap task can succeed, and the machine still opens terminals into bash
where none of it loads. A run that reported `complete` there would be wrong in the most misleading
way available — everything it did was correct, and none of it is reachable.

A non-zsh login shell therefore forces `complete-with-caveats`, never `complete`.

`doctor` gained the same check for the same reason: its probe invokes `zsh -ic` explicitly, which
proves the configuration is right while saying nothing about whether the machine ever reaches it. It
reports `WARN` rather than `FAIL`, because a terminal configured to launch zsh directly is a
legitimate setup, and a failure the operator has deliberately chosen becomes noise they learn to
ignore.

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

None. The prerequisite question this section previously carried is resolved in Design Decision 3a:
`stow`, `task`, and `zsh` are blocking; everything else is a caveat.

## Recommended Next Step

Review this architecture against PRD 0023. On pass, write the §8 ADR first — it is a prerequisite for
the documents, since they must cite it — then plan the two documents and their sandbox validation.
