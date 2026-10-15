# Architecture: Interactive CLI Completions for `lms` and `docker desktop`

**Number:** 0025
**Status:** Approved
**Date:** 2026-10-15
**PRD:** [0027-interactive-cli-completions-lms-docker](../prd/0027-interactive-cli-completions-lms-docker.md)

## Context

The zsh package already renders tab completion through fzf-tab (plugins.zsh: zinit loads
zsh-completions → compinit → fzf-tab → widget plugins, ADR-0049). Two proven completion
patterns exist:

- `taskfile.zsh` — tune a package-shipped native completion (`_task` on fpath); styles
  only.
- `herdr.zsh` — author a completion in-repo for tools that ship none; ends with an
  explicit `compdef` registration; sourced after compinit via `index.zsh` (layer 6).

Two gaps:

1. **`lms`** (LM Studio CLI, `~/.lmstudio/bin/lms`) ships no completion at all: no `_lms`
   on any fpath, no `lms completion` subcommand (`error: unknown command 'completion'`).
   `lms <Tab>` therefore completes nothing.
2. **`docker`** (CLI 29.8.2) completion comes from Homebrew's hand-maintained
   `_docker` (~3100 lines, `#compdef docker dockerd`). Its first-level list
   (`__docker_commands`) is scraped live from `docker --help` output, so `desktop` shows
   at first level. But its nested dispatcher `__docker_subcommand` is a hardcoded
   `case $words[1]` with no `(desktop)` branch — even the official generated
   `docker completion zsh` has zero `desktop` coverage. Selecting `desktop` and
   pressing Tab again yields no candidates, so fzf-tab never opens.

## Proposed Architecture

### A. `lms.zsh` — authored completion (pattern: `herdr.zsh`)

New file `stow/common/zsh/.config/zsh/lms.zsh`, sourced from `index.zsh` in a new
`6f)` slot (after ssh, before speedtest), guarded by
`command -v lms >/dev/null 2>&1 || return`.

Structure:

- `_lms()` local function defining `_arguments -C` with global options and a first-level
  subcommand list taken from `lms --help`:
  `chat get load unload ls ps import server log link runtime clone push dev login logout
  whoami`.
- Nested `case "$line[1]"` arms for grouped subcommands with real sublevels (captured from
  `lms <group> --help` during planning; e.g. `server start/stop/status/...`,
  `link ...`). First cut commits only to arms whose help output is stable.
- Dynamic candidates, read-only only:
  - `lms ls` → installed model identifiers for `load`.
  - `lms ps` → loaded model identifiers for `unload`.
  Parsing prefers `--json` if the CLI supports the flag; otherwise plain output with
  awk parsing; both degrade to an empty list without errors.
- `compdef _lms lms` at file end.
- fzf-tab styles: `':fzf-tab:complete:lms:*'` preview filtering `lms ls` / `lms ps` on the
  highlighted word — read-only.

Model identifier strings contain version-qualified tags (e.g. `model@vX.Y`); candidates
are quoted safely per the herdr pattern.

### B. `docker.zsh` — delegating shim for `desktop` (pattern: novel, minimal)

New file `stow/common/zsh/.config/zsh/docker.zsh`, sourced in the same completion layer,
guarded by `command -v docker >/dev/null 2>&1 || return`.

Sourcing order makes the shim win the `compdef` registration: Homebrew's `_docker` was
registered at compinit time (fpath `#compdef docker dockerd`); this file's explicit late
`compdef` replaces that mapping, and the shim internally delegates so nothing upstream
behavior is lost.

Structure:

- `_docker_desktop_complies()` (interior) — static subcommand tree for Docker Desktop CLI
  captured from `docker desktop --help`: management commands `auth`, `kubernetes`,
  `disable`, `enable`; commands `diagnose`, `logs`, `restart`, `start`, `status`, `stop`,
  `update`, `version`; nested arms only where help output confirms
  sublevels (e.g. `auth login/logout`, `kubernetes enable/disable`).
- `_docker_desktop()` — `_arguments -C` over the tree above; no dynamic candidates at
  first cut. Only `docker desktop status` is used anywhere as a *possibly* live inquiry;
  if even it is queried, it is read-only and optional — default: fully static completion,
  zero subprocess calls in the completion path.
- Dispatcher re-registration (name `_docker_shim`):
  - If `$service == dockerd` → call the original `_docker` directly (unchanged path).
  - If `words[1] == docker && words[2] == desktop` → `_docker_desktop`.
  - Else → call `_docker "$@"` directly (the Homebrew autoload function, not through
    `compdef`, so no recursion; brew's own `$service`-subservice dispatch stays intact).
- `compdef _docker_shim docker` at file end (do not remap `dockerd` on the same shim if
  `#compdef` already covers it — verify during planning which registration ends up
  winning, and preserve dockerd behavior exactly).
- fzf-tab styles: preview showing `docker desktop <subcommand> --help` text of the
  highlighted subcommand — read-only.

The shim deliberately does not vendor or patch the 3100-line `_docker`. Homebrew keeps
authority over generic docker completion; the repo owns only the missing branch. When
Homebrew's `_docker` eventually gains a `(desktop)` case, the shim's delegation order
keeps working: the shim should prefer a *detected* native capability if it ever materializes
(actual detection deferred; a one-line comment marks the future check).

## Decisions

1. **Author-in-repo for `lms`.** No upstream completion exists to tune; `herdr.zsh` is
   the precedent. Repo owns and maintains the tree.
2. **Delegating shim for `docker`, not a vendored patched `_docker`.** A vendored copy
   would fork ~3100 lines against Homebrew updates for a one-branch fix. Late
   `compdef` + direct internal delegation keeps upstream as authority.
3. **Strictly static completion for `docker desktop`.** The gap is a missing static
   branch, not missing dynamic data; zero subprocess calls keeps latency and
   read-only guarantees trivial.
4. **`lms` dynamic candidates limited to `load`/`unload` model identifiers**, read-only
   (`lms ls`, `lms ps`), parsed defensively, empty on failure.
5. **Source order:** both files live in the completion layer (6b–6e block) after
   `completions.zsh`, guarded, no-op without the binary — matching `herdr.zsh` placement
   rules.
6. **Portability:** completion logic never hardcodes macOS paths. On Linux distros where
   `_docker` may be missing entirely, the shim still registers `_docker_desktop` for the
   desktop branch and silently no-ops the delegation — degraded, not broken.

## Risks

- **Shim registration order:** late `compdef` must actually replace brew's mapping; if a
  Linux distro or future zinit change re-registers later, upstream `_docker` wins again
  and `desktop` support disappears silently. Mitigation: a validation check confirms the
  resolved function is the shim in an interactive shell.
- **Autoload semantics of delegation:** calling `_docker "$@"` directly from the shim relies
  on fpath autoload and brew's file defining + self-invoking a function of the same name.
  Must be verified in a fresh shell (first Tab after startup, and subsequent Tabs).
- **`lms` CLI drift:** LM Studio CLI is not semver-stable in shape; subcommand/help text
  can change. Mitigation: candidates parsed defensively; static tree comments record the
  validated `lms --version` (`CLI commit: 69d945a`).
- **Docker `desktop` sublevel drift:** Docker Desktop CLI subcommand set may grow.
  Static tree goes stale gracefully (a missing subcommand simply fails to complete).
  Mitigation: comment records the validated Docker CLI version (29.8.2).
- **Network query temptation for `lms get`:** avoided — no Hub/network search in
  completion.
- **Stow risk:** two more files under an already-stowed package directory. Same-file
  additions need no re-stowing (directory-level symlinked tree); validate with
  `stow --simulate` anyway before any approval.

## Open Questions

- For `lms server`: confirm its real sublevels from `lms server --help` before deciding
  the tree depth for the first cut.
- Whether `lms` supports `--json` output on `ls`/`ps` to make parsing deterministic.
- Whether the Desktop shim should also cover `docker dockerd`-scoped subservices any
  differently (expected: no; keep pass-through).

## Recommended Next Step

User reviews PRD 0027 + Architecture 0025. On explicit approval, Planner drafts the
implementation plan (0030) capturing exact `lms <group> --help` and
`docker desktop --help` trees, the index.zsh source slots, and the validation commands.
