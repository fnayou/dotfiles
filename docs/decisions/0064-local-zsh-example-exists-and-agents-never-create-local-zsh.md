# Decision: `local.zsh.example` Exists for Humans; Agents Never Create `local.zsh`

**Number:** 0064
**Date:** 2026-08-04
**Status:** Accepted
**Supersedes:** [ADR-0036](0036-local-zsh-created-by-editor-not-example.md)

## Context

The decision record contradicted itself, and had done so silently for weeks.

[ADR-0036](0036-local-zsh-created-by-editor-not-example.md) (2026-06-19) decided that `local.zsh`
would have no template:

> `local.zsh` has no `.example` template and no documented default content. […] **No `.example` file
> exists for `local.zsh` in the repo. This is intentional.**

It gave three reasons a template was worse than editor-creation: a template implies a canonical
structure that `local.zsh` does not have; a copied template can be `git add .`-ed back into the repo
by accident; and the setup guide can describe content categories without implying they are exhaustive.

`stow/common/zsh/.config/zsh/local.zsh.example` was then added in **`fb807ea`** ("feat(zsh): adopt
real guarded configuration") with **no accompanying ADR**. Nothing recorded the reversal.

[ADR-0054](0054-example-templates-excluded-from-stow.md) (2026-07-03) later described the file as the
"skeleton the user copies to a real, git-ignored `~/.config/zsh/local.zsh`" — but 0054 is a decision
about *excluding templates from stow*. It assumed the template's existence; it never argued for it.

So the state of the world was: ADR-0036 `Accepted` and false, ADR-0054 `Accepted` and dependent on
0036 being false, `docs/guides/zsh-setup.md` Step 5 instructing the `cp`, and the file present in the
tree. The `docs/decisions/README.md` index listed both as `Accepted`. Review 0069's index audit did
not catch it, because that audit compared each ADR's status field against its index row and never
compared ADRs against each other.

Found while grilling Architecture 0022, where it mattered concretely: the install document needed to
know whether copying `.example` templates was a permitted agent action.

## Decision

**Two parts.**

**1. `local.zsh.example` exists and stays.** ADR-0036 is superseded by this record — not by ADR-0054,
which never made the argument. Marking 0054 as the superseding decision would credit it with
reasoning it never performed and would conceal that the real change arrived undocumented.

ADR-0036's three concerns, revisited:

- *A template implies a canonical structure.* Answered by the template's content: it is entirely
  comments, with every example line commented out. It documents categories and traps — notably the
  ADR-0062 `PATH` placement rule — and prescribes no structure.
- *A copied template can be committed by accident.* Now covered twice over:
  `stow/common/zsh/.config/zsh/.gitignore` ignores `local.zsh`, and ADR-0054 keeps the template
  unstowed so the operator copies from the repo path rather than from a `$HOME` symlink.
- *The guide can describe categories without a template.* True, and it still does. This is a
  preference, not a blocker, and it is outweighed by the template being the natural place to warn
  about `PATH` — the trap that produced ADR-0062.

**2. Agents never create `local.zsh`.** Any agent-driven install or update run reports its absence
under *needs the operator* and stops there. It does not copy the template, and it does not author the
file.

`local.zsh` is the designated home for private, machine-specific values (ADR-0023, ADR-0026).
Authoring it is the operator's act. An agent placing a skeleton there on their behalf would put a
guess where their secrets belong, and would make an empty-but-present `local.zsh` indistinguishable
from a considered one.

The human `cp` workflow in `docs/guides/zsh-setup.md` is unaffected. This constrains agents only.

## Consequences

- The contradiction is closed: ADR-0036 becomes `Superseded by 0064`, and the index reflects it.
- The agent install document has an unambiguous answer, and `cp` leaves its permitted-action set
  entirely — the set now contains no verb that authors a configuration file.
- A machine provisioned entirely by an agent will have **no** `local.zsh`. That is correct and safe:
  `index.zsh` guards the source, so its absence is a no-op, and `task doctor` reports it as `SKIP`.
- **A gap in the audit method is now known.** Comparing each ADR against its own index row cannot
  detect two ADRs that disagree with each other. Nothing currently checks for that, and this
  contradiction survived an audit performed the same day it was found.

## Alternatives rejected

- **Mark ADR-0036 `Superseded by 0054`.** Cheapest, and consistent with how 0037/0041/0042/0046 were
  handled — but false. 0054 decided a different question, and this framing would make an
  undocumented change look like a documented one.
- **Delete the template, restoring ADR-0036.** Internally consistent, but it would remove the
  natural home for the `PATH` warning added in ADR-0062, and require reverting guide Step 5 and part
  of ADR-0054 to reinstate a decision nobody has wanted since June.
- **Let agents copy the template.** Rejected in part 2 above.
