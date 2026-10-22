# Review: Generated Art Implementation

**Number:** 0105
**Status:** Complete
**Plan reviewed:** [0036-generated-art-and-architecture-diagram](../plans/0036-generated-art-and-architecture-diagram.md) (Approved)
**Review type:** Implementation review

## Summary

Reviewed the uncommitted implementation for Plan 0036 against PRD 0032 and Architecture 0028. The read-only freshness check, shell syntax, task listing, ADR consistency check, hook dry runs, and in-memory SVG generation checks pass. Blocking defects remain in output replacement safety, the architecture page image path, required manual-step markers, the diagram's `Other` family, privacy criteria, and the unplanned `scripts/hooks.sh` file.

Plan 0036 stays **Approved** until the user completes Task 21. The Claude Code hook visibility and compound-command behavior, Git hooks with `hooks:install --apply`, and the first `docs.yml` run on `main` remain pending user validation; they are not treated as failures here.

## Blocking Issues

- `scripts/art/render.py:62-66` replaces the SVG before replacing its PNG. If the PNG replacement fails, the new SVG remains beside the old PNG, violating the required previous-pair preservation on failure (Architecture 0028 Decision 4; ADR 0082). Preserve or roll back the old SVG if the second replacement fails.
- `website/reference/architecture.md:6-7` resolves `../../assets/images/dotfiles-architecture.svg` from `website/reference/` to the nonexistent repository-root `assets/` path. The valid sibling link at line 10 uses `../assets/...`. The embedded image and open-link target must resolve for `mkdocs build --strict`.
- `docs/guides/art-setup.md:144-145` and `website/reference/architecture.md:16` instruct the reader to run `task art:build` without the required immediately preceding `⚠️  MANUAL STEP` marker. The website scripts page marks its write commands correctly at lines 93-98.
- `scripts/art/architecture.py:181-194` creates an `Other` data entry, but renders its package cards under the AI column and never renders an `Other` label. An in-memory probe confirmed an unknown package appears but `>Other<` does not. This does not implement the planned visible “Other” slot.
- `scripts/art/banner.py:31,46`, `scripts/art/social.py:22-23,33`, `scripts/art/logo.py:25`, and `scripts/art/architecture.py:128-130` embed `fnayou`; the generated SVGs also contain it in visible text or metadata. This is the machine username and conflicts with the review's no-user-name requirement and PRD 0032 acceptance criterion at lines 161-163. The PRD also explicitly requests `fnayou/` branding at line 21, so its requirements conflict and need resolution before approval.
- `scripts/hooks.sh` is created but absent from Plan 0036's Files Affected list (`docs/plans/0036-generated-art-and-architecture-diagram.md:199-222`). The plan restricts the Builder to approved plan items. Add this helper to an approved plan revision or move its behavior into listed files before treating the implementation as plan-complete.

## Checks

| Check | Result | Evidence |
|---|---|---|
| PRD 0032 acceptance criteria 1–4 | Met | Palette values and theme mapping are in `scripts/art/palette.py:10-66`; `bash scripts/art.sh check` exited 0. Generators and stdlib imports are under `scripts/art/`; output paths and README SVG reference are `scripts/art/art.py:8-10,46-55` and `README.md:4`. SVG and PNG output files are present in `website/assets/images/`. |
| PRD criteria 5–7 | Met | Banner, social and logo use the shared lavender/blue colors and contain no glow filter (`scripts/art/banner.py:34-46`, `scripts/art/social.py:31-34`, `scripts/art/logo.py:8-28`). Social copy and repository-derived values are in `scripts/art/social.py:20-23,88-111` and `scripts/art/banner.py:28-33`. Four in-memory repeat comparisons returned `True`; `art.sh check` also passed. |
| PRD criteria 8–9 | Met | All seven targets appear in `Taskfile.yml:443-484` and `task --list`; CI runs `bash scripts/art.sh check` at `.github/workflows/ci.yml:138-142`. The step calls neither `task` nor `rsvg-convert`. |
| PRD criteria 10–13 | Partial / pending | Hook filters and timeout are in `.claude/settings.json:3-24`; the handler rechecks commands and returns JSON or silent success in `.claude/hooks/art-reminder.sh:16-45`. Git hooks call only `remind`, use `|| true`, and exit 0 (`.githooks/pre-commit:5-7`, `.githooks/pre-push:7-14`). `scripts/hooks.sh:24-63` refuses foreign settings and only changes local config under `--apply`; dry-run tasks left `core.hooksPath` unset. Task 21 live behavior and apply tests remain pending. |
| PRD criterion 14 | Met | `task art:check` is before staging in `.claude/skills/ship-change/SKILL.md:35-45`. |
| PRD criteria 15–16 | Partial / pending | Diagram generation precedes MkDocs at `.github/workflows/docs.yml:34-40`; both diagram paths are ignored (`.gitignore:42-45`); no `task`, tags, or `rsvg-convert` are needed. The embedded image path is broken (blocking issue above). First `docs.yml` run on `main` remains pending. Optional librsvg entries and doctor detection are present in `packages/Brewfile:53-56`, `packages/arch/packages.txt:39-42`, `packages/debian/packages.txt:46-49`, and `scripts/doctor.sh:366`. |
| PRD criteria 17–19 | Not met / partial | ADR 0082 and its index row exist (`docs/decisions/0082-generated-art-with-svg-png-sidecars.md`, `docs/decisions/README.md:142`). Missing manual-step markers are listed above. README and MkDocs logo/favicon paths were inspected; the architecture page path is broken. Username conflict is listed above. |
| Architecture decisions 1–3 | Met | Python package and thin entry point: `scripts/art.sh:1-16`; file-derived facts: `scripts/art/facts.py:1-5,90-121`; committed/ignored outputs and docs generation: `scripts/art/art.py:12-18`, `.gitignore:42-45`, `.github/workflows/docs.yml:34-40`. |
| Architecture decision 4 | Partial | SVG validation and temporary rendering happen before replacement (`scripts/art/render.py:51-61`), and missing `rsvg-convert` returns a skip message (`:32-36,67-68`). Sequential replacements do not preserve the prior pair if the PNG rename fails (`:62-66`). |
| Architecture decisions 5–6 | Met | Freshness step and palette verification are `scripts/art/art.py:72-83` and `.github/workflows/ci.yml:138-142`; current check passes. |
| Architecture decision 7 | Met | Read-only changed-file selection and exception-to-silent-success are `scripts/art/art.py:86-121`; no staged reminder was emitted. `fnmatch`'s `*` matches `/`, so patterns such as `scripts/art/*` also match nested paths; this broadens matching but does not miss the planned inputs. |
| Architecture decision 8 | Partial / pending | Static filtering, `git -C` upstream lookup, `commit -a` handling, JSON output, and exception handling are in `.claude/hooks/art-reminder.sh:16-45`. The runtime visibility and compound-command filter tests remain pending under Task 21. |
| Architecture decisions 9–10 | Met / pending | Git hook behavior is at `.githooks/pre-commit:5-7` and `.githooks/pre-push:7-14`; local-only, dry-run configuration is at `scripts/hooks.sh:24-63`. `ship-change` includes the check before staging. Task 21's installed-hook live test remains pending. |
| Architecture decisions 11–12 | Partial / Met | README SVG and nav entry are present (`README.md:4`, `mkdocs.yml:56-61`); architecture image path is broken as noted. Platform-specific librsvg entries and doctor check are present at the paths above. |
| Deterministic facts and formatting | Met | `facts.py` imports no subprocess and reads repository files; Taskfile parsing, install counts and release parsing are at `scripts/art/facts.py:57-87,90-120`. Generated facts show 38 tasks and release `v2026.10`; in-memory repeated renders of all four SVG functions were byte-identical. No timestamp, hash, or dynamic branch is emitted; prompt branch is the constant `main`. |
| Renderer scope and failure behavior | Partial | CLI directs generator output under `website/assets/images/` (`scripts/art/art.py:8-10,46-55`); renderer temp files are created beside targets (`scripts/art/render.py:25-29,49-57`). XML validation and failed renderer conversion precede SVG replacement. The second rename failure case remains unsafe as noted. No generator invokes network, pip, Stow, `defaults`, or an `rm` command. |
| Reminder and hook non-blocking behavior | Met by inspection | `remind` catches exceptions and returns 0 (`scripts/art/art.py:101-121`); Git hooks use `|| true` and `exit 0`; Claude hook has no `permissionDecision` and ends in `sys.exit(0)` (`.claude/hooks/art-reminder.sh:37-49`). No hook regenerates, edits, stages, or commits. |
| Task 21 live tests | Pending, not a failure | This session did not load the new Claude hook; `git commit -a --dry-run` showed no reminder. The user must test Claude hook visibility/filtering and Git hooks with `hooks:install --apply` on the throwaway branch, as Plan 0036 Task 21 requires. |
| Decision-record and task checks | Met | `task check:decisions` reported `PASS: decision record is self-consistent (71 ADRs)`. `task --list` showed all seven art/hooks targets. `task hooks:status`, `task hooks:install`, and `task hooks:uninstall` ran as dry runs; config remained unset. |
| Syntax, freshness, and diff hygiene | Met | `bash -n scripts/art.sh scripts/hooks.sh .githooks/pre-commit .githooks/pre-push .claude/hooks/art-reminder.sh` exited 0; `bash scripts/art.sh check` exited 0; `git diff --check` passed. |
| Status sync | Met | No Stow package was added, removed, or first-stowed; package manifests changed, but `stow/` did not. No AGENTS.md or CLAUDE.md status-block update is needed. |
| Privacy scan | Not met | No `/Users/`, `/home/`, secret, token, password, or hostname value appeared in the scanned scripts and generated SVGs. The intentional `fnayou` username appears in generator source and SVG content, as detailed above. |

## Non-Blocking Suggestions

- `scripts/art/art.py:22-24` uses patterns with `fnmatch`; because `*` matches `/`, some nested paths and non-generated files under `website/assets/images/` can trigger extra reminders.
- Workflow YAML was reviewed structurally but not passed through a YAML parser in this review. The first strict MkDocs build remains pending with the first `docs.yml` run on `main`.

## Safety Verdict

FAIL — output replacement can leave an SVG/PNG pair inconsistent if the PNG rename fails. Hook and configuration behavior is read-only by default and scoped to this repository's local Git config.

## Privacy Verdict

FAIL — `fnayou`, the machine username, appears in generated SVGs and their generator source; this conflicts with the specified privacy criterion.

## Documentation Verdict

FAIL — the architecture page's embedded image path is unresolved, and two documented image-writing commands lack the required manual-step marker.

## Recommended Next Action

Resolve the blocking issues and re-review. Keep Plan 0036 Approved until the user completes Task 21; then record the live results before any plan-status change.
