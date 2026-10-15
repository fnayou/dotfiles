# PRD: Interactive CLI Completions for `lms` and `docker desktop` (fzf-tab)

**Number:** 0027
**Status:** Approved
**Date:** 2026-10-15

## Goals

- Give `lms` (LM Studio CLI) a first-class zsh completion so `lms <Tab>` shows its
  subcommands and options in the fzf-tab picker, with read-only dynamic candidates for
  model names where `lms load` / `lms unload` expect them.
- Fix Docker completion depth: `docker <Tab>` works at first level (command list), but
  `docker desktop <Tab>` shows nothing because the Homebrew-shipped `_docker` completion
  has no `desktop` branch in its subcommand dispatcher. After this change, `docker desktop
  <Tab>` shows the Docker Desktop CLI subcommands (`auth`, `kubernetes`, `disable`,
  `enable`, `diagnose`, `logs`, `restart`, `start`, `status`, `stop`, `update`, `version`)
  through the same fzf-tab picker.
- Follow the established two-completion patterns already in the zsh package: *tuning* a
  package-shipped completion (`taskfile.zsh`) and *authoring* a completion for a tool that
  ships none (`herdr.zsh`).
- Keep all completion-side invocations strictly read-only (no model loads/unloads, no
  Docker Desktop start/stop/etc. during completion).

## Non-Goals

- Running Stow, modifying `$HOME`, or creating symlinks.
- Installing, upgrading, or fetching `lms`, `docker`, Docker Desktop, or any package.
- Replacing Homebrew's `_docker` wholesale with a vendored patched copy.
- Completions for other CLI tools not named in this PRD.
- Providing completions for `docker` CLI plugins beyond `desktop`.
- Any change that would execute an LM Studio or Docker mutating command from a
  completion context.

## Scope

- `stow/common/zsh/.config/zsh/lms.zsh` — new, authored `_lms` completion + fzf-tab styles
- `stow/common/zsh/.config/zsh/docker.zsh` — new, desktop-subcommand shim + fzf-tab styles
- `stow/common/zsh/.config/zsh/index.zsh` — add source lines for `lms.zsh` and `docker.zsh`
  in the completion section (after `6d)`, before `7)`)
- `stow/common/zsh/README.md` — document both completion entries
- Appropriate page under `docs/guides/` if it documents per-tool completions

## Safety Requirements

- Completion functions may only call read-only CLI forms: `lms ls`, `lms ps`,
  `lms get --experimental 'query'`-class searches only if strictly needed and verified
  read-only, `docker --help`-style parsers, `docker desktop status`, and similar. No
  `lms load/unload/push/dev`, no `docker desktop start/stop/restart/update/enable/disable`
  from any candidate generator or preview.
- Every new zsh file is guarded: `command -v <tool> >/dev/null 2>&1 || return` and no-ops
  when the tool or its completion dependency (fzf-tab) is absent.
- Nothing registers outside completion contexts; no PATH manipulation, no `$HOME` writes.
- Keep portable across macOS, EndeavourOS / Arch, and Debian: no Homebrew-only paths or
  assumptions in the new code (package-shipped `_docker` may differ per OS; graceful
  degradation required when it is absent).

## Acceptance Criteria

- [ ] `lms <Tab>` opens fzf-tab listing lms subcommands and global options.
- [ ] `lms load <Tab>` / `lms unload <Tab>` offers locally installed / loaded model
      identifiers using read-only queries, degrading gracefully when none exist.
- [ ] `docker desktop <Tab>` opens fzf-tab listing the Docker Desktop CLI subcommands.
- [ ] `docker <Tab>` and all previously working nested levels (`docker container <Tab>`,
      `docker image <Tab>`, ...) continue to work unchanged (shim delegates to the
      package-shipped `_docker`).
- [ ] `dockerd` and subservice dispatch behavior preserved.
- [ ] Pressing FZF-select candidates never passes a mutating command string anywhere
      (only prints suggestions; actual execution is the user typing/pressing Enter
      themselves).
- [ ] New files are guarded; a shell without `lms`, `docker`, or fzf-tab starts cleanly
      with no errors.
- [ ] Validation commands pass or any skipped validation is documented with reason.

## Resolved Questions

- Root cause on Docker confirmed by inspection: Homebrew `_docker` builds the first-level
  command list live from `docker --help` output (so `desktop` appears there), but the
  `__docker_subcommand` `case $words[1]` dispatch has no `(desktop)` branch, so the
  nested level returns no candidates and fzf-tab never renders. The shim approach fixes
  exactly this gap.
- Completion authoring style follows `herdr.zsh` (author + `compdef`) for `lms`, and a
  thin delegating `compdef` shim for `docker` that preserves the Homebrew completion.

## Open Questions

- Exact per-subcommand detail level: full two-level completion for `lms` (e.g. `lms
  server <Tab>` → `start/stop/status`), or one level only for the first cut?
- Whether `lms get <Tab>` should offer a search over registered Hub models (requires a
  network query at completion time) or stay local-only. Default: local-only, document the
  reason.
