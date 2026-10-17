# Review: Ghostty Configuration PRD and Architecture (Re-review)

**Number:** 0081
**Status:** Complete
**Date:** 2026-10-17
**Documents reviewed:**
- `docs/prd/0028-ghostty-configuration.md`
- `docs/architecture/0026-ghostty-configuration-architecture.md`

## Summary

Re-reviewed PRD 0028 and Architecture 0026 after commits `7e1d84d` (PRD Decision 12: macOS-only
options moved to `stow/macos/ghostty/.config/ghostty/macos.ghostty`, loaded by
`config-file = ?macos.ghostty`, adopted by the operator) and `cf4b7d9` (review 0080 fixes). Ghostty
was not run during this review. Facts the documents record as verified in a sandbox run
(Ghostty 1.3.1, macOS, `XDG_CONFIG_HOME` pointed at a temporary directory) are accepted as verified.

Both blocking issues from review 0080 are resolved. Six of the eight suggestions are resolved, one
is resolved with a remaining PRD wording gap, and one stays open as an accepted operator risk.

The new content is consistent between the two documents. Architecture 0026 carries PRD Decisions
1–12 over without re-opening them (`:43-55`). File names, option values, and Stow commands agree.
All 18 hex values in the planned `themes/catppuccin-macchiato` (architecture `:281-313`) match
`stow/common/alacritty/.config/alacritty/catppuccin-macchiato.toml` key for key, as listed in the
PRD theme mapping (`:289-300`). Every `README.md` and `website/` line number cited by the
architecture was checked against the current files and is correct.

One new blocking issue: `README.md:28-29` says all common packages are stowed. The Build makes that
false, and the architecture's README change list leaves it out. This is the same defect class as
review 0080 Blocking Issue 2.

## Review 0080 Item Resolution

- **B1 (dangerous commands not fenced): Resolved.** Each install fence now has the marker on the
  line directly above it, with no blank line: PRD `:138`, `:146`, `:219`, `:225`, `:348`, `:365`;
  architecture `:456`, `:463` (guide prerequisites), `:829`, `:838`, `:855` (check 3), `:965`,
  `:979`, `:990`. The dry-run fences (PRD `:343-346`, `:359-363`; architecture `:960-963`,
  `:973-977`) and the read-only checks 1, 2, 4, 5, 6 carry no marker, which is correct.
- **B2 (incomplete `README.md` change list): Resolved for the three listed statements.**
  `README.md:24`, `:33-34`, and `:105` are in "Other files the Build creates or modifies"
  (architecture `:130-132`), in "Statements made false by a populated `stow/macos/`" (`:581-583`),
  and in plan task 6 (`:1128-1130`). The sweep now covers every "`stow/macos/` is empty" statement,
  with its search method stated (`:574-591`). All cited lines were checked against the current
  files. A further README statement is still missing: see Blocking Issue 1.
- **N1 (PRD tree missing files): Resolved.** PRD `:88-107` shows `.stow-local-ignore` and
  `README.md` for both packages, identical to architecture `:74-93`.
- **N2 (`macos-*` options in the common file): Resolved.** PRD Decision 12 (`:495-529`), Decision 1
  (`:159-164`); architecture `:222-223`, `:246`, `:251-266`, Decision 7 (`:715-741`). The common
  `config.ghostty` has no `macos-*` line.
- **N3 (dry run without `-v`): Resolved.** `-v` added, with "verify in Build": PRD `:344-345`,
  `:361-362`, `:476`; architecture `:471-477`, `:833`, `:861`, `:961-962`, `:975-976`.
- **N4 (check 7 undefined): Resolved.** Check 7 is now operator-run, does not claim to leave
  `$HOME` untouched, and names its two unverified items (architecture `:936-952`, `:747-749`).
- **N5 (harden check 3): Resolved.** `FAKE_HOME="$(mktemp -d)" || exit 1` and `${FAKE_HOME:?}` on
  every `stow --target` and `rm` (architecture `:825-873`). See suggestion 2 for a side effect.
- **N6 (verify in Build): Resolved, with a PRD wording gap.** Architecture `:754-788` splits the
  items into sandbox-verified and still-open Build checks. The PRD still states the
  `/bin/sh -c` behaviour as fact (`:245-246`, `:274`), while the architecture lists it as not
  verified (`:782-783`). See suggestion 1.
- **N7 (icon licence): Unresolved — accepted risk.** The licence is still unknown. The operator
  accepted committing the icon (PRD `:486-488`, `:397-399`; architecture `:1068-1072`). This is the
  operator's decision and does not block.
- **N8 (nested em-dash clauses in the `CLAUDE.md` bullet): Resolved.** Architecture `:539` uses
  commas and separate sentences; the meaning is unchanged.

## Blocking Issues

1. **`README.md:28-29` becomes false and is not in the change list.** It reads: "`stow/common/` is
   the source of truth for which packages exist. All common packages are stowed: live symlinks
   point from `$HOME` into the repo." After the Build, `stow/common/ghostty/` exists but is not
   stowed, and `stow/macos/ghostty/` also defines a package. Architecture `:542-543` limits the
   "except ghostty" wording to two README status lines: `Home directory: stowed — all common
   packages linked` (`README.md:25`) and the first Safety bullet (`README.md:85`). Neither
   `:128-132` nor `:579-591` nor plan task 6 (`:1128-1130`) lists `:28-29`. A Builder following the
   architecture exactly leaves a false statement. Fix: add `README.md:28-29` to "Other files the
   Build creates or modifies" and to plan task 6. Give it the "except ghostty" wording, and name
   `stow/macos/` as a source of truth as well (ADR 0048, as for `README.md:24`).

## Non-Blocking Suggestions

1. PRD `:245-246` ("Ghostty runs a `command` that contains arguments through `/bin/sh -c`") and the
   mapping row `:274` state as fact what architecture `:782-783` lists as not verified. Mark the
   PRD statement "per Ghostty docs; verified in Build", so the two documents agree.
2. `FAKE_HOME="$(mktemp -d)" || exit 1` (architecture `:832`, `:842`, `:859`) closes the
   operator's interactive shell if `mktemp` fails, because the blocks are copy-paste steps. Prefer
   a form that stops without exiting the shell, for example running each block in a subshell
   `( … )`, or a guard such as `FAKE_HOME="$(mktemp -d)" && { …; }`. The safety
   property (an empty value never reaches `stow` or `rm`) already holds through `${FAKE_HOME:?}`.
3. Risks `:1073-1076` and `:1081-1083` say "both READMEs" document the macOS-only case and the
   unchanged Finder icon. The common package README (architecture `:340-360`) says neither. Add one
   line to it, for example "On macOS, also stow `stow/macos/ghostty` for Option-as-Alt and the
   custom icon", or change the Risks text to "the guide and the macOS README".
4. `website/reference/repository-structure.md:41-42` says "The `stow/common/` directory defines which
   packages exist". After the Build, `stow/macos/` defines one too. The architecture row for
   `:42-44` changes only the "currently empty" sentence. Extend that row to name `stow/macos/`,
   matching the `README.md:24` change.
5. `README.md:15-16` says configs are version-controlled "in `stow/common/`". Consider naming
   `stow/macos/` there as well when the Build edits the README.
6. `website/reference/supported-systems.md:31` says "some Alacritty lines are macOS-only but harmless
   on Linux". When Ghostty joins that row, state that the Ghostty common file has no macOS-only
   lines (PRD Decision 12), so the row stays accurate.

## Safety Verdict

PASS — neither document has an agent write to `$HOME`, use `--adopt`, or run a Stow install. Every
Stow install is preceded by a `--simulate` dry run and carries the marker. The macOS Application
Support file and the signed app bundle stay untouched. The icon source is copied read-only. Check 3
writes only into its own `mktemp -d` directory, guarded by `|| exit 1` and `${FAKE_HOME:?}`. Check 7
is operator-run and does not claim to leave `$HOME` untouched.

## Privacy Verdict

PASS — the planned files contain display and key preferences only. They contain no secrets,
hostnames, or user-specific paths: `~` and `$HOME` are used, plus placeholders in the guide. The new
`macos.ghostty` holds two options and comments only. The icon's unknown licence is recorded with
its source and SHA-256, and the operator accepted it.

## Cross-Platform Verdict

PASS — macOS, Arch, and Debian are treated separately. The common `config.ghostty` has no `macos-*`
option, which satisfies `.claude/rules/cross-platform.md` exactly. The macOS options and the icon
live in `stow/macos/ghostty/`. Arch stows only the common package, and the optional include is
skipped (sandbox-verified for an absent file; the Arch run stays a Build check). Debian stows
neither package. The macOS-only-common-package case is documented as expected.

## Documentation Verdict

FAIL — every dangerous fence now has the marker on the line directly above it, and the status-block
wording matches `.claude/rules/status-sync.md` and ADR 0048. But the architecture's `README.md`
change list still leaves one statement that the Build makes false (Blocking Issue 1).

## Recommended Next Action

Architect: amend Architecture 0026 to add `README.md:28-29` to the README change list and to plan
task 6 (Blocking Issue 1). Consider suggestions 1 and 3 in the same amendment. The Reviewer then
confirms the fix; the change is small enough for a short re-check. The operator re-approves the
amended architecture before the Planner writes the implementation plan.
