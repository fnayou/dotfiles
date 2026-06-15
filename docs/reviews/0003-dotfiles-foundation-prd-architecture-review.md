# Review: Dotfiles Foundation — PRD and Architecture

**Number:** 0003
**Date:** 2026-06-15
**Reviewer:** Claude Code (Reviewer role per AGENTS.md §4)
**Artifacts reviewed:**
- `docs/prd/0002-dotfiles-foundation.md`
- `docs/architecture/0002-dotfiles-foundation-architecture.md`

---

## Summary

Reviewed PRD 0002 and Architecture 0002 for safety, privacy, cross-platform correctness, GNU Stow correctness, and scope discipline. Both documents are well-structured and aligned with AGENTS.md. Three blocking issues found, four non-blocking issues found. No secrets or destructive operations present in the documents themselves.

---

## Blocking Issues

### B1 — `check.sh` + `set -euo pipefail` conflict

**Location:** Architecture 0002 § Scripts Strategy

Both scripts are specified to use `set -euo pipefail`. In `check.sh`, each check is a `command -v <tool>` call. With `set -e` active, the first failing `command -v` causes the script to exit immediately — remaining checks are never reached.

The specified behavior ("`output: one line per check — PASS or FAIL`") is impossible under `set -e` if any tool is absent.

**Required fix:** Builder must either:
- Remove `set -e` from `check.sh` and use explicit `|| echo "FAIL: ..."` per check, or
- Use `command -v <tool> >/dev/null 2>&1 && echo "PASS: <tool>" || { echo "FAIL: <tool> (not installed)"; FAILED=1; }` pattern with `set -e` disabled.

`detect-os.sh` is unaffected — it does not enumerate multiple checks.

---

### B2 — `task list` output path does not match `task dry-run PACKAGE=` format

**Location:** Architecture 0002 § Taskfile Strategy

The `task list` command is:

```bash
find stow -mindepth 2 -maxdepth 2 -type d -print
```

Output on current foundation: `stow/common/git`

The `task dry-run` command passes `{{.PACKAGE}}` directly to stow:

```bash
stow --dir=stow --target="$HOME" --simulate {{.PACKAGE}}
```

With `--dir=stow`, stow resolves the package path relative to `stow/`. So `PACKAGE=common/git` is correct. But `task list` returns `stow/common/git`, not `common/git`.

The Architecture doc claims "find output from `task list` is already in this form, so copy-paste works directly." This is false. The user must manually strip the `stow/` prefix from `task list` output before using it with `task dry-run`. The claim must be corrected.

**Required fix (one of):**
- Change `task list` to strip the prefix: `find stow -mindepth 2 -maxdepth 2 -type d -print | sed 's|^stow/||'`
- Or update the architecture doc to drop the copy-paste claim and note the manual strip step.

---

### B3 — PRD Safety rule contradicts `task dry-run`

**Location:** PRD 0002 § Safety Requirements

> "Must not run `stow` without explicit user approval (never in scripts, hooks, or Taskfile tasks)."

`task dry-run` runs `stow --simulate` inside a Taskfile task. This directly contradicts the stated rule.

The intent is clearly "no mutating stow operations" — `--simulate` is safe and intended. But the rule as written forbids all stow invocations from Taskfile, including dry-run.

**Required fix:** Correct the safety rule to:

> "Must not run `stow` without `--simulate` in scripts, hooks, or Taskfile tasks. Stow install operations require explicit manual invocation by the user."

---

## Non-Blocking Issues

### N1 — ADR-0009 slot collision across architecture documents

**Location:** Architecture 0001 § Proposed ADRs vs. Architecture 0002 § ADRs to Create

Architecture 0001 reserves ADR-0009 for "Docker as optional dotfiles test harness."
Architecture 0002 proposes ADR-0009 for "Foundation-phase Taskfile excludes install / mutating tasks."

Architecture 0002 acknowledges this and says Docker/pass ADRs "become ADR-0012, ADR-0013 at write time." The renumbering intent is documented but the collision is not yet resolved in the source. If ADRs are written from arch 0001 first, the number is taken.

**Suggestion:** The Plan for this phase must explicitly state: write ADR-0009/0010/0011 (per arch 0002) first, before any attempt to write the Docker/pass ADRs. Or update arch 0001's table to show the reserved slots as moved. Low urgency until ADRs are actually written.

---

### N2 — Acceptance criterion #13 is unverifiable as written

**Location:** PRD 0002 § Acceptance Criteria

> "No symlinks exist in `$HOME`."

This cannot be verified by this phase. Symlinks created by other tools (e.g., Homebrew, nvm, pyenv) exist in `$HOME` already. The criterion should verify only what this phase controls.

**Suggestion:** Change to:

> "No symlinks were created in `$HOME` by this phase. No stow install operation was run."

---

### N3 — `.gitconfig.example` content not specified beyond user.name/email

**Location:** Architecture 0002 § Safe Example-Based Adoption

The document specifies `name = Your Name` and `email = your-email@example.com`, explicitly excludes `[user] signingkey`, and defers signing to ADR-0006. What git sections beyond `[user]` must appear in the example is not defined.

Without a defined structure, the Builder will choose arbitrarily, and a later PRD may need to revise the example when the git package is properly scoped.

**Suggestion:** Either (a) note in the Plan that the example covers `[user]` and `[core]` only, or (b) add one sentence to the Architecture doc stating the minimum section set. Non-blocking — the Planner can capture this.

---

### N4 — `.gitkeep` packages will surface unexpected output in `task dry-run`

**Location:** Architecture 0002 § `stow/` Layout / Risks table

If a user runs `task dry-run PACKAGE=macos`, stow dry-runs `stow/macos/` which contains only `.gitkeep`. Stow would report a simulated link: `~/.gitkeep`. This is safe (--simulate) but confusing — the user may think `.gitkeep` is an intended dotfile.

The Risks table acknowledges "Empty package stows nothing in stow's model" but this is partially incorrect: stow does not consider `.gitkeep` an empty package — it would attempt to stow it as a dotfile.

**Suggestion:** `docs/stow-usage.md` should document: `stow/macos/` and `stow/arch/` are empty platform directories, not stowable packages. Do not run `task dry-run PACKAGE=macos` or `task dry-run PACKAGE=arch` — they contain only Git markers. Or use a subdirectory (e.g. `stow/macos/git/`) even for placeholder packages to make the two-level structure consistent.

---

## Safety Verdict

**PASS with blocking issue B3 resolved.**

No destructive operations, no `rm`/`mv`/`ln -s` against `$HOME`, no `stow --adopt`, no auto-stow in scripts or tasks. The architecture correctly restricts the Taskfile to read-only/dry-run-only operations. B3 is a documentation error, not an implementation danger, but it must be corrected before the PRD is marked Approved so the Builder has an accurate safety contract.

---

## Privacy Verdict

**PASS.**

No credentials, tokens, keys, private hostnames, or real identity data in either document. `.gitconfig.example` placeholder values are explicitly defined (`Your Name`, `your-email@example.com`). ADR-0003 is correctly inherited. Pre-commit audit process referenced.

---

## Cross-Platform Verdict

**PASS.**

Platform separation (common / macos / arch) is correctly enforced. `detect-os.sh` detection pattern is portable. `find` flags used in `task list` are BSD/GNU compatible. No Homebrew commands appear in Arch context or vice versa. `set -euo pipefail` is bash-specific but both scripts correctly use `#!/usr/bin/env bash` — no POSIX sh ambiguity.

---

## GNU Stow Correctness Verdict

**PASS with notes.**

Stow command flags (`--dir=stow --target="$HOME" --simulate`) are correct. Package path convention (`<platform>/<package>`) is consistent with ADR-0001. `stow .` is explicitly forbidden. `stow --adopt` is explicitly forbidden. Dry-run-before-install gate is enforced at the Taskfile level. B2 (path mismatch) and N4 (`.gitkeep` dry-run output) need resolution in the Plan or docs, but do not represent a Stow design error.

---

## Documentation Verdict

**PASS.**

Both documents are clear, consistent, numbered, and cross-referenced. PRD includes verifiable acceptance criteria. Architecture resolves all six tensions with arch 0001 explicitly and with tradeoff analysis. The `docs/stow-usage.md` content structure is defined. B3's incorrect safety rule must be corrected before the PRD is used as a Builder contract.

---

## Recommended Next Action

1. **Resolve B3** — correct the PRD 0002 safety rule wording (two-line edit).
2. **Resolve B2** — decide: fix `task list` output format or correct the copy-paste claim in arch 0002.
3. **Resolve B1** — note in arch 0002 that `check.sh` must not use `set -e` if it needs to print all results.
4. Update PRD 0002 and Architecture 0002 status from **Draft** to **Approved** once B1–B3 are resolved.
5. Proceed to Planner: produce `docs/plans/0002-dotfiles-foundation-plan.md`. Plan must include ADR-0009/0010/0011 as first tasks (before file creation) and must capture the B1/B2 resolutions as implementation constraints.
