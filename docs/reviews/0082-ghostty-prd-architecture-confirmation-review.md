# Review: Ghostty Configuration PRD and Architecture (Confirmation)

**Number:** 0082
**Status:** Complete
**Date:** 2026-10-17
**Documents reviewed:**
- `docs/prd/0028-ghostty-configuration.md`
- `docs/architecture/0026-ghostty-configuration-architecture.md`

## Summary

Confirmation review of commit `c1ada48` ("docs(architecture): resolve review 0081 findings for
Ghostty") against the findings of review 0081. Scope is the `c1ada48` diff and the 0081 items only;
unchanged content was not re-reviewed. Ghostty was not run during this review. No plan is completed
by this review; the implementation plan is not yet written.

The diff changes PRD 0028 in three lines (the `**Amended:**` line, Decision 7, and the
`terminal.shell` mapping row) and Architecture 0026 in eight regions (the `**Amended:**` line, the
"Other files the Build creates or modifies" table, the common package `README.md`, the status-block
README paragraph, both "Documentation and Website Mentions" tables, validation check 3, the Finder
icon risk, and plan task 6).

The blocking issue and all six suggestions of review 0081 are resolved. Every `README.md` and
`website/` line cited by the new rows was checked against the current files and is correct. The diff
introduces no blocking issue.

## Review 0081 Item Resolution

- **B1 (`README.md:28-29` missing from the change list): Resolved.** The statement is now in "Other
  files the Build creates or modifies" (architecture `:132`), in "Statements made false by a
  populated `stow/macos/`" (`:591`), in the status-block README paragraph (`:546-551`), and in plan
  task 6 (`:1151-1154`). Each gives the "except ghostty" wording and names `stow/macos/` as a source
  of truth (ADR 0048). The cited text matches `README.md:28-29`. The search method of the sweep now
  covers statements that name `stow/common/` alone (`:583-585`).
- **S1 (PRD states `/bin/sh -c` as fact): Resolved.** PRD Decision 7 (`:245-246`) and the
  `terminal.shell` mapping row (`:274`) now say "per Ghostty docs; verified in Build". This agrees
  with architecture `:793-794`, which lists the behaviour as a Build check.
- **S2 (`|| exit 1` closes the operator's shell): Resolved.** Check 3 steps 1 to 3 now run in a
  subshell `( set -eu; … )` (architecture `:845-851`, `:858-868`, `:878-894`), and the prose explains
  the effect (`:836-840`). No `exit` remains. `${FAKE_HOME:?}` is kept on every `stow --target` and
  `rm`, and is now also used in the `test` and `XDG_CONFIG_HOME` lines.
- **S3 ("both READMEs" in Risks): Resolved.** The common package README now says "On macOS, also
  stow `stow/macos/ghostty` for Option-as-Alt and the custom icon" (architecture `:363`), so the
  "both READMEs" claim for the macOS-only-common-package risk (`:1095-1098`) holds. The Finder icon
  risk now says "the guide and the macOS README" (`:1105`); the macOS README states it (`:401-402`).
- **S4 (`repository-structure.md:41-42`): Resolved.** New row at architecture `:597`. The cited text
  matches `website/reference/repository-structure.md:42`.
- **S5 (`README.md:15-16`): Resolved.** Added at architecture `:130` and `:589`, and to plan task 6
  (`:1154`). The cited text matches `README.md:15-16`.
- **S6 (`supported-systems.md:31`): Resolved.** The row now names line `:31` and states that the
  Ghostty common file has no macOS-only lines (architecture `:574`). The cited text matches
  `website/reference/supported-systems.md:31`.

## Blocking Issues

None.

## Non-Blocking Suggestions

1. Architecture `:836-837` says "If `mktemp` or any later command fails, `set -e` stops the subshell
   only". That is not true for a command on the left of `&&`: `set -e` ignores its failure. So a
   failed `stow -v … --simulate` (`:848`, `:882`) or a failed `test` (`:862`, `:885-887`) does not
   stop the block; the only sign is the missing `echo` line. The commands write only into the fake
   home, so this is safe. Consider rewording to "If `mktemp` or any command not followed by `&&`
   fails", or name the missing `echo` line as the failure signal under "Expected".
2. PRD `:246` is about 140 characters long; the surrounding prose wraps near 100. Rewrap when the
   PRD is next edited.

## Safety Verdict

PASS — the diff adds no write to `$HOME`, no `--adopt`, and no Stow install outside the fake home.
Check 3 still writes only into its own `mktemp -d` directory. `${FAKE_HOME:?}` still guards every
`stow --target` and `rm`, and the subshell keeps a failure from closing the operator's shell. A
temporary directory left behind after a failure is outside the repository and `$HOME`, as the
prose states.

## Privacy Verdict

PASS — the diff adds wording, file references, and fake-home commands only. It contains no
secrets, hostnames, or user-specific paths; `$HOME`, `~`, and `mktemp -d` are used.

## Documentation Verdict

PASS — the three changed dangerous fences in check 3 keep the `⚠️  MANUAL STEP — review before
running` marker on the line directly above the fence (architecture `:842`, `:854`, `:874`). The new
common README line sits inside a non-dangerous `markdown` fence. All new line citations match the
current files. The README and status-block wording follows `.claude/rules/status-sync.md` and ADR
0048, with `stow/common/` and `stow/macos/` named as the directories, not a per-package list.

## Cross-Platform Verdict

PASS — the subshell form `( set -eu; … )` and `${FAKE_HOME:?}` work the same in bash and zsh, on
macOS and on Arch. Check 3 step 3 keeps its `# macOS` label. The new `supported-systems.md` wording
keeps PRD Decision 12: the common Ghostty file has no macOS-only lines. The common README line
names macOS as the platform for the extra package.

## Recommended Next Action

Operator: re-approve the amended PRD 0028 and Architecture 0026 (both carry `**Status:**
Approved` with a new "review 0081 fixes" amendment). Suggestions 1 and 2 can be folded into the
implementation plan or a later edit; they do not need another review. The Planner then writes the
implementation plan from architecture `:1137-1158`.
