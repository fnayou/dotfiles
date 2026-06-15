# Architecture: Dotfiles Foundation (PRD 0002)

**Number:** 0002
**Status:** Approved
**Date:** 2026-06-15
**PRD:** [0002-dotfiles-foundation](../prd/0002-dotfiles-foundation.md)
**Parent:** [0001-dotfiles-repository-architecture](./0001-dotfiles-repository-architecture.md)

---

## Context

Architecture 0001 defines the long-term repository structure end to end (stow layout, packages, scripts, test harness, Docker, ADRs 0001–0008). PRD 0002 narrows the **first implementation phase** to a minimal foundation: directory scaffolding, placeholder packages, helper scripts, Taskfile, and Stow usage documentation.

This document does **not** redesign anything in 0001. It scopes 0001 down to the slice that PRD 0002 authorizes, and resolves the tensions where 0001's full scope exceeds PRD 0002's minimal scope.

Key tensions to resolve:

| Topic                  | Arch 0001                                | PRD 0002                                                     |
|------------------------|------------------------------------------|--------------------------------------------------------------|
| `packages/macos/`      | Reserved for future Brewfiles            | Not mentioned — out of scope                                 |
| Taskfile `stow:install`| Included as a task                       | Forbidden — must not exist in foundation phase               |
| `.gitignore_global.example` | Created in initial scaffold         | Not listed in PRD 0002 "Initial Packages"                    |
| `scripts/check.sh`     | Not in 0001 scaffold                     | Required by PRD 0002                                         |
| Taskfile `dry-run` API | `PLATFORM=<p> PACKAGE=<n>`               | `PACKAGE=<name>` (no `PLATFORM` shown)                       |
| CI workflow            | ADR-0008 accepted (`.github/workflows/`) | Out of scope language; ADR-0008 still active                 |

All tensions resolved below.

---

## Proposed Structure (PRD 0002 slice)

```
dotfiles/
├── .claude/                       # Exists — untouched
├── docs/
│   ├── architecture/              # This document
│   ├── decisions/                 # ADRs 0001–0008 exist; new ADRs proposed below
│   ├── plans/
│   ├── prd/
│   ├── reviews/
│   ├── claude/
│   └── stow-usage.md              # NEW — required by PRD 0002
├── stow/                          # NEW — minimal foundation only
│   ├── common/
│   │   └── git/
│   │       └── .gitconfig.example
│   ├── macos/
│   │   └── .gitkeep
│   └── arch/
│       └── .gitkeep
├── scripts/                       # NEW
│   ├── detect-os.sh
│   └── check.sh
├── Taskfile.yml                   # NEW — non-destructive tasks only
├── .gitignore                     # Already present from operating layer
├── README.md                      # Already present
├── AGENTS.md                      # Already present
└── CLAUDE.md                      # Already present
```

**Deliberately absent in this phase:**

- `packages/macos/` — no Brewfiles needed yet; create when Brewfile ADR is scoped.
- `test/` — no Docker harness yet (ADR-0009 future).
- `stow/common/zsh/`, `stow/macos/zsh/`, `stow/arch/zsh/` — zsh deferred.
- `stow/common/git/.gitignore_global.example` — not in PRD 0002 scope (see Decision 4).
- Any `task stow:install` or equivalent — explicitly forbidden by PRD 0002.

---

## `stow/` Layout

Inherits ADR-0001 (platform-first). PRD 0002 instantiates the minimum subset:

```
stow/
├── common/
│   └── git/                          # Package — example template only
│       └── .gitconfig.example        # Placeholder identity values
├── macos/
│   └── .gitkeep                      # Marker — package directory reserved
└── arch/
    └── .gitkeep                      # Marker — package directory reserved
```

Rules:

- `stow/common/` holds configs meeting ADR-0001 Decision 8 common-package criteria.
- `stow/macos/` and `stow/arch/` are empty placeholders this phase — `.gitkeep` keeps them in git.
- `.example` files are never stowed directly (ADR-0003).
- Stow command shape is always `stow --dir=stow --target="$HOME" <platform>/<package>`.

---

## Common / macOS / Arch Separation

No change from ADR-0001 Decision 8. Restated here for PRD 0002 enforcement:

A directory under `stow/common/` is permitted **only if all three** hold:

1. Config file path identical on macOS and Arch.
2. Config values work unmodified on both platforms.
3. No platform-specific tool or behavior referenced.

`stow/common/git/.gitconfig.example` satisfies all three (identity placeholders; no platform-specific values).

`stow/macos/` and `stow/arch/` contain `.gitkeep` only — no platform-specific configs are added in this phase.

---

## Safe Example-Based Adoption

Inherits ADR-0003. PRD 0002 enforcement:

- Only `.example` files are committed in `stow/`.
- `stow/common/git/.gitconfig.example` uses placeholders:
  - `name = Your Name`
  - `email = your-email@example.com`
  - No signing key, no `[user] signingkey` line. The example demonstrates structure; signing setup is out of scope (ADR-0006).
- The user copies `.gitconfig.example` → `.gitconfig` locally before stowing. Never automated.
- No real `~/.gitconfig` is inspected, copied, or replaced. ADR-0006 holds.

---

## Taskfile Strategy

Architecture 0001 defines the full Taskfile vocabulary. PRD 0002 restricts the foundation phase to a **read-only / dry-run-only** subset. **Install tasks must not exist in this phase** (resolved by Decision 1 below).

Approved tasks for the foundation phase:

```yaml
version: "3"

tasks:
  detect:
    desc: "Print detected OS (macos or arch)"
    cmds:
      - bash scripts/detect-os.sh

  check:
    desc: "Verify prerequisites (stow, git, task) are installed"
    cmds:
      - bash scripts/check.sh

  list:
    desc: "List Stow packages available under stow/"
    cmds:
      - find stow -mindepth 2 -maxdepth 2 -type d -print | sed 's|^stow/||'

  dry-run:
    desc: "Dry-run a Stow package — usage: task dry-run PACKAGE=<platform>/<name>"
    preconditions:
      - sh: '[ -n "{{.PACKAGE}}" ]'
        msg: "PACKAGE is required, e.g. PACKAGE=common/git"
    cmds:
      - stow --dir=stow --target="$HOME" --simulate {{.PACKAGE}}
```

Notes:

- `dry-run` takes one variable `PACKAGE=<platform>/<name>` (resolves PRD-vs-arch tension — PRD 0002's `PACKAGE=<name>` is interpreted as the full path under `stow/`).
- No `install`, `uninstall`, `adopt`, or any task that mutates `$HOME`.
- `--simulate` is hardcoded in `dry-run` — cannot be bypassed by variable.

---

## Scripts Strategy

Two scripts only this phase. Both **read-only**, both **must work on macOS and Arch**.

### `scripts/detect-os.sh`

Purpose: print platform name to stdout.

Behavior:

```
input:  none
output: "macos" | "arch"
exit:   0 on supported OS, 1 on unsupported
side effects: none
```

Detection pattern (per AGENTS.md §10 and arch 0001):

```bash
if [[ "$OSTYPE" == "darwin"* ]]; then
  echo "macos"
elif [[ -f /etc/arch-release ]]; then
  echo "arch"
else
  echo "unsupported: $OSTYPE" >&2
  exit 1
fi
```

### `scripts/check.sh`

Purpose: verify foundation prerequisites are installed.

Behavior:

```
input:  none
output: one line per check — "PASS: <tool>" or "FAIL: <tool> (not installed)"
exit:   0 if all pass, 1 if any fail
side effects: none
```

Tools to check: `stow`, `git`, `task`. Uses `command -v <tool>` — no execution of the tools themselves.

`scripts/detect-os.sh` uses `#!/usr/bin/env bash`, `set -euo pipefail`, and a leading usage comment.

`scripts/check.sh` uses `#!/usr/bin/env bash` and a leading usage comment, but must **not** use `set -e`. With early exit enabled, the first failing `command -v` would abort before printing results for remaining tools. Instead each check uses an explicit pattern:

```bash
if command -v stow >/dev/null 2>&1; then
  echo "PASS: stow"
else
  echo "FAIL: stow (not installed)"
  FAILED=1
fi
```

The script exits with `${FAILED:-0}` — 0 if all pass, 1 if any fail.

---

## Documentation Strategy

PRD 0002 mandates `docs/stow-usage.md`. Content sections:

1. **Purpose** — why this repo uses Stow with a package-based layout.
2. **Dry-run first** — required step; copy-pasteable command.
3. **Install** — manual-only; **must be preceded by** `⚠️  MANUAL STEP — review dry-run output before running`.
4. **Conflict handling** — stop and resolve manually; `--adopt` forbidden.
5. **Adding a new package** — pointer to ADR-0001 and the common-package criteria.

The doc lives at `docs/stow-usage.md` (not under `docs/claude/`) because it is user-facing operational documentation, not agent-facing guidance.

Cross-references: `README.md` links to `docs/stow-usage.md` in this phase; `AGENTS.md` already covers Stow rules at a contract level.

---

## CI Impact

ADR-0008 stands. The minimal hygiene workflow already approved continues to apply:

- `bash -n` on `scripts/detect-os.sh` and `scripts/check.sh` (new files this phase).
- Existence checks for `stow/`, `Taskfile.yml`, `docs/stow-usage.md`.
- Secret pattern scan — must not fail on `your-email@example.com` placeholder.

No CI changes required by PRD 0002 beyond extending the existing workflow's existence checks once the foundation lands. The CI must never run `stow` (ADR-0008 constraint).

If `.github/workflows/ci.yml` does not yet exist when the foundation lands, it is a separate scaffold task tracked by ADR-0008's own plan — not pulled into PRD 0002 scope.

---

## Future Docker Testing

No change from arch 0001 Decision 12. PRD 0002 leaves `test/` out entirely — no fixtures, no Dockerfiles, no `test:docker:*` tasks.

When Docker testing is scoped (future PRD), the foundation already supports it:

- `scripts/detect-os.sh` runs inside an Arch container with no modification.
- `scripts/check.sh` runs inside any container with `stow`, `git`, `task` installed.
- `task dry-run PACKAGE=common/git` runs against the container's `$HOME` (which must be `test/fixtures/home/`, never the real `$HOME`).

ADR-0009 (Docker harness) is pending and **not written** in this PRD. PRD 0002 only confirms that nothing in the foundation blocks it.

---

## Design Decisions

### Decision 1: No `install` or mutating tasks in foundation phase

**Option A:** Include `stow:install` and `stow:uninstall` as in arch 0001, document them as "use with care."

- Pro: complete Taskfile surface from day one.
- Con: violates PRD 0002 acceptance criterion "No `task install` task exists."
- Con: any mutating task in `Taskfile.yml` is one `task install PACKAGE=...` away from modifying `$HOME` — a single typo risk the user explicitly excluded.

**Option B:** Foundation Taskfile contains read-only / dry-run tasks only. Install commands documented in `docs/stow-usage.md` as `⚠️  MANUAL STEP` copy-paste blocks.

- Pro: matches PRD 0002 acceptance criteria exactly.
- Pro: install is a deliberate human action, not a button.
- Pro: when install is later added, it goes through a new PRD/architecture cycle.
- Con: two surfaces to maintain (Taskfile + doc) — accepted; doc is the source of truth for install in this phase.

**Decision: Option B.** Aligns with PRD 0002 and Safety §8 of AGENTS.md.

Recorded as ADR-0009 (proposed below).

---

### Decision 2: `packages/macos/` not created in foundation phase

**Option A:** Pre-create `packages/macos/` as in arch 0001 to reserve the slot.

- Pro: consistent with long-term architecture.
- Con: PRD 0002 does not mention it; creating it is scope creep.
- Con: empty `packages/macos/` invites accidental commits of real Brewfile content before its own PRD is written.

**Option B:** Defer `packages/macos/` until the Brewfile PRD is scoped.

- Pro: matches PRD 0002 acceptance criteria.
- Pro: each top-level directory is created only when it has authorized content.
- Con: minor — directory must be added later. Trivial.

**Decision: Option B.** Directory created when Brewfile scope is approved.

---

### Decision 3: `task dry-run` takes one variable, `PACKAGE=<platform>/<name>`

**Option A:** Two variables (`PLATFORM=<p> PACKAGE=<n>`) as in arch 0001.

- Pro: explicit platform separation in invocation.
- Con: PRD 0002 specifies single `PACKAGE=<name>` variable.
- Con: two-variable form invites the user to invoke `PLATFORM=macos PACKAGE=arch-only-pkg` — a misuse vector.

**Option B:** Single `PACKAGE=<platform>/<name>` — the user types the full sub-path under `stow/`.

- Pro: matches PRD 0002.
- Pro: forces the user to write the exact directory they want stowed — typo-resistant.
- Pro: `task list` strips the `stow/` prefix (via `sed`) so output is already in `<platform>/<name>` form — direct copy-paste into `task dry-run PACKAGE=...` works.
- Con: slightly longer command. Acceptable.

**Decision: Option B.** Recorded behaviorally in the Taskfile section above.

---

### Decision 4: Foundation `.example` set is `.gitconfig.example` only

**Option A:** Also create `.gitignore_global.example` as in arch 0001 scaffold.

- Pro: consistent with arch 0001.
- Con: PRD 0002 "Initial Packages" table lists only `.gitconfig.example`.
- Con: `.gitignore_global` is non-sensitive (ADR-0003) and can ship as a real file later — no urgency to commit a template.

**Option B:** Only `.gitconfig.example` this phase. `.gitignore_global` deferred until git package is properly scoped.

- Pro: matches PRD 0002 acceptance criteria exactly.
- Pro: minimal foundation — each addition has a PRD behind it.

**Decision: Option B.** Defer `.gitignore_global.example` to the git-package PRD.

---

### Decision 5: `scripts/check.sh` verifies presence, not version

**Option A:** Check tool versions (e.g., `stow >= 2.3.0`).

- Pro: catches stow versions that lack required flags.
- Con: parsing version output is brittle across distros.
- Con: PRD 0002 says "verify prerequisites" — presence is sufficient.

**Option B:** Verify presence only via `command -v`.

- Pro: simple, portable, no version-parsing fragility.
- Pro: matches PRD 0002 scope.
- Con: cannot catch stow lacking `--dir`. Accepted — `--dir` exists in stow 2.x which is universal on macOS/Arch.

**Decision: Option B.** Version checks added only if a real incompatibility surfaces.

---

### Decision 6: `docs/stow-usage.md` lives directly under `docs/`, not `docs/claude/`

**Option A:** Place under `docs/claude/` next to agent guides.

- Con: this doc is for the human user, not the agent contract.

**Option B:** Place under `docs/` at top level.

- Pro: user-facing operational doc; mirrors how `README.md` sits at repo root.
- Pro: AGENTS.md §7 enumerates `docs/claude/` as agent guides — `stow-usage.md` is not that.
- Con: `docs/` becomes a flat doc directory with one file. Acceptable; future user-facing docs join it (`docs/setup.md`, etc.).

**Decision: Option B.** Add to README's link list when the foundation lands.

---

## Risks and Mitigations

| Risk                                                                  | Likelihood | Severity | Mitigation                                                                                              |
|-----------------------------------------------------------------------|-----------:|---------:|---------------------------------------------------------------------------------------------------------|
| User runs `task` task that mutates `$HOME`                            |        Low |     High | Decision 1 — no mutating tasks exist; install is doc-only with `⚠️ MANUAL STEP`                          |
| Empty `stow/macos/` or `stow/arch/` accidentally stowed               |        Low |   Medium | Empty package stows nothing in stow's model; `.gitkeep` is filtered; `task dry-run` still safe          |
| `scripts/check.sh` reports false positive on stow lacking `--dir`     |        Low |      Low | Decision 5 — flagged in `docs/stow-usage.md` as required stow version                                   |
| `.gitconfig.example` committed with real identity                     |        Low |     High | Reviewer pre-commit checklist (AGENTS.md §9); CI secret scan (ADR-0008)                                  |
| User invokes `stow --dir=stow .` ignoring the package-based layout    |     Medium |     High | `docs/stow-usage.md` explicitly forbids it; AGENTS.md §11 already forbids it                            |
| Foundation grows past PRD 0002 scope during build                     |     Medium |   Medium | Plan must list every file; Reviewer rejects anything not in PRD 0002 acceptance criteria                |
| OS detection fails silently on unsupported OS                         |        Low |   Medium | `scripts/detect-os.sh` exits 1 with stderr message; `task detect` propagates exit code                  |
| `Taskfile.yml` parsed by wrong runner (Make vs. go-task)              |        Low |      Low | `version: "3"` header is go-task specific; `scripts/check.sh` verifies `task` binary is installed       |
| `find` command in `task list` differs across BSD/GNU                  |        Low |      Low | Flags (`-mindepth`, `-maxdepth`, `-type`, `-print`) and `sed 's\|^stow/\|\|'` are supported by both BSD and GNU |

---

## ADRs to Create

The following ADRs are new and tied to this PRD. ADRs 0001–0008 already cover the prior architecture; they are not duplicated.

| Number   | Title                                                                | Status   |
|----------|----------------------------------------------------------------------|----------|
| ADR-0009 | Foundation-phase Taskfile excludes install / mutating tasks          | Proposed |
| ADR-0010 | `packages/` directory deferred until Brewfile scope is approved      | Proposed |
| ADR-0011 | `task dry-run` accepts single `PACKAGE=<platform>/<name>` argument   | Proposed |

ADRs previously reserved at slots 0009 (Docker harness) and 0010 (`pass`) in arch 0001's "Proposed ADRs" table are renumbered to land **after** PRD 0002's ADRs above when they are scoped (i.e., they become ADR-0012, ADR-0013 at write time). This avoids overwriting an unrelated reservation.

---

## Extensibility (preserved from 0001)

The foundation supports incremental growth without redesign:

- New stow package: drop a directory under the matching platform; reuse `task dry-run PACKAGE=<platform>/<pkg>`.
- New script: place under `scripts/`; reuse the OS-detection pattern.
- Mutating task: requires its own PRD that explicitly lifts ADR-0009.
- Brewfiles: lift ADR-0010 in a future PRD, then create `packages/macos/`.
- Docker harness: covered by arch 0001 Decision 12; no foundation change required.

---

## Open Questions

None blocking. PRD 0002 is internally complete; arch 0001 covers all upstream decisions; the only deltas needed are Decisions 1–6 above.

---

## Recommended Next Step

Planner converts this architecture into an ordered implementation plan under `docs/plans/0002-dotfiles-foundation-plan.md`. Plan must include:

- File creation order (scripts → Taskfile → stow tree → docs).
- Per-task validation step (e.g., `task detect` returns `macos` on dev machine).
- Per-task safety check (no command modifies `$HOME`).
- ADR-0009, ADR-0010, ADR-0011 written before the foundation files are committed, so the rationale is captured before the artifacts.
