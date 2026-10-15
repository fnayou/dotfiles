# Plan: Interactive CLI Completions for `lms` and `docker desktop`

**Number:** 0030
**Status:** Approved
**Date:** 2026-10-15
**PRD:** [0027-interactive-cli-completions-lms-docker](../prd/0027-interactive-cli-completions-lms-docker.md) (Approved)
**Architecture:** [0025-interactive-cli-completions-lms-docker-architecture](../architecture/0025-interactive-cli-completions-lms-docker-architecture.md) (Approved)

## Objective

Add repo-owned zsh completions so that `lms <Tab>` (LM Studio CLI) opens the fzf-tab picker
with subcommands, options, and read-only model candidates, and `docker desktop <Tab>` opens
the picker with the Docker Desktop CLI subcommands that the Homebrew `_docker` completion
does not cover.

## Assumptions

- fzf-tab loads per ADR-0049 (plugins.zsh order: zsh-completions → compinit → fzf-tab →
  widget plugins). New completion files are authored after compinit, following
  `herdr.zsh` / `taskfile.zsh` placement rules.
- Validated tool versions at draft time (record in file comments):
  - `lms` — CLI commit `69d945a` (LM Studio CLI at `~/.lmstudio/bin/lms` on macOS; spec is
    platform-agnostic, guarded by `command -v lms`).
  - `docker` CLI `29.8.2`; Homebrew `_docker` at
    `$(brew --prefix)/share/zsh/site-functions/_docker` (~3100 lines,
    `#compdef docker dockerd`), confirmed to have no `(desktop)` branch in
    `__docker_subcommand` (grep for `desktop` in the file returns nothing; the official
    generated `docker completion zsh` also has zero `desktop` coverage).
- Environment data confirmed while drafting (Builder should re-verify cheaply during
  Task 1/2, not regenerate):
  - `lms ls --json` and `lms ps --json` work and are read-only.
  - `lms ps` entries expose an `identifier` field (unload target); `lms ls` entries expose
    `modelKey` and `selectedVariant` (load candidates).
  - `lms --help` tree: `chat get load unload ls ps import server log link runtime clone
    push dev login logout whoami`.
  - Nested trees: `server` → start/stop/status; `log` → stream; `link` →
    enable/disable/status/set-device-name/set-preferred-device; `runtime` →
    ls/select/remove/update/get/survey. `get import clone push dev login logout whoami
    chat` are leaf commands.
  - `docker desktop --help` tree: management commands `auth` (→ status),
    `kubernetes` (→ images/reset-cluster/status), `disable`, `enable`; commands
    `diagnose`, `logs`, `restart`, `start`, `status`, `stop`, `update` (options only:
    `-k/--check-only`, `-q/--quiet`), `version`.
  - Homebrew's `_docker` builds its first-level list live from `docker --help`
    (`__docker_commands`), which is why `desktop` appears at first level while its
    dispatcher lacks the nested case.

## Ordered Tasks

### Task 1 — Create `lms.zsh` (authored completion, herdr pattern)

Create `stow/common/zsh/.config/zsh/lms.zsh`:

1. Header comment documenting: authored completion (no upstream `_lms`, `lms completion`
   returns `error: unknown command 'completion'`), validated `lms` CLI commit
   (`69d945a`), strictly read-only subprocess usage, sourced-after-compinit expectation.
2. Guard: `command -v lms >/dev/null 2>&1 || return`.
3. Dynamic candidate helpers, jq-preferred with defensive non-fatal fallback:
   - `_lms_disk_models` → models on disk: prefer
     `lms ls --json 2>/dev/null | jq -r '.[].selectedVariant // .[].modelKey // empty'`;
     capture each field access defensively (`try`-style jq paths); empty list on any
     failure.
   - `_lms_loaded_models` → loaded identifiers: prefer
     `lms ps --json 2>/dev/null | jq -r '.[].identifier // empty'`; awk fallback optional
     (plain `lms ps` table format is not stable — if no jq, return empty rather than
     guessing).
4. `_lms()` main function:
   - `_arguments -C` with global options (`-h/--help`, `-V/--version`) and first-level
     subcommands with descriptions:
     `chat get load unload ls ps import server log link runtime clone push dev login
     logout whoami`.
   - `case "$line[1]"` arms for grouped commands using the validated nested trees above.
     Leaf commands get a minimal options set only where the help output was captured
     (see assumptions); unknown details deliberately omitted rather than invented.
   - `load` position 2: `_lms_disk_models`; `unload` position 2: `_lms_loaded_models`.
     Keep `load`'s remaining options minimal (`--gpu`, `-c/--context-length`,
     `--ttl`, `-y/--yes`) from captured help; `unload` gets `-a/--all`.
5. `compdef _lms lms` at file end.
6. fzf-tab styles (read-only previews):
   - `':fzf-tab:complete:lms:load:*'` → filter `lms ls --json` on `$word`.
   - `':fzf-tab:complete:lms:unload:*'` → filter `lms ps --json` on `$word`.
   - `':fzf-tab:complete:lms:*'` → `lms $word --help 2>/dev/null || lms --help
     2>/dev/null` for subcommand previews.
7. No network candidates for `get` (PRD decision: local-only). A comment records this.

### Task 2 — Create `docker.zsh` (delegating shim)

Create `stow/common/zsh/.config/zsh/docker.zsh`:

1. Header comment documenting: Homebrew `_docker` lacks the `(desktop)` branch; shim
   re-registers docker and delegates everything else to the package-shipped `_docker`
   unchanged; validated docker CLI `29.8.2`; strictly static desktop tree (zero
   subprocess calls in the completion path; upstream `_docker`'s own subprocess parsing
   is untouched shash-backed behavior).
2. Guard: `command -v docker >/dev/null 2>&1 || return`.
3. `_docker_desktop()` local function:
   - `_arguments -C` first-level management commands + commands from the validated tree:
     `auth kubernetes disable enable diagnose logs restart start status stop update
     version`.
   - Nested arms: `auth` → `status`; `kubernetes` → `images reset-cluster status`;
     `logs` → options `-b/--boot`, `-c/--color`, `-m/--color-mode`, `-D/--directory`
     (options-only arm); `update` → options `-k/--check-only`, `-q/--quiet`.
     No dynamic candidates, no subprocess calls.
4. Shim registration:
   - `_docker_shim()`:
     - If `$service == dockerd` → `_docker "$@"` (exact preserve of dockerd path).
     - If `words[1] == docker && words[2] == desktop` → `_docker_desktop`.
     - Else → `_docker "$@"`.
   - Delegation calls `_docker` directly (the loaded autoload function), never through
     `compdef`, so no recursion. Include a short comment explaining the
     define-then-self-invoke autoload semantics this relies on.
   - Final line: `compdef _docker_shim docker`. Add a comment noting the later explicit
     registration wins over compinit's earlier `#compdef docker dockerd` mapping, and
     that `dockerd` keeps using the upstream file.
   - Add a one-line comment noting the future detection opportunity: once upstream
     `_docker` grows a `(desktop)` case, this shim can be removed.
5. fzf-tab style: `':fzf-tab:complete:docker:desktop:*'` preview →
   `docker desktop $word --help 2>/dev/null || docker desktop --help 2>/dev/null`
   (read-only: `--help` only — never `status`-class or mutating subcommands in the
   completion path).
6. Cross-platform note in the comment: on systems without the package-shipped `_docker`
   the shim still registers successfully; generic docker completion silently no-ops.

### Task 3 — Wire into `index.zsh` source order

Edit `stow/common/zsh/.config/zsh/index.zsh` in the completion-tuning block, keeping the
lettered-slot pattern:

- After the `6e)` speedtest block, add:
  - `# 6f) lms (LM Studio CLI) completion — guarded; no-op without `lms`.` source line for
    `lms.zsh`.
  - `# 6g) docker desktop completion shim — guarded; no-op without `docker`.` source line
    for `docker.zsh`.
- Do not reorder any existing slots.

### Task 4 — Document in the zsh package README

Edit `stow/common/zsh/README.md` following the existing "go-task (Taskfile) completion"
section pattern. Add:

- An `lms` completion section: authored completion, load/unload dynamic candidates,
  read-only guarantees.
- A Docker completion section: Homebrew `_docker` delegates, shim adds `docker desktop`,
  fzf-tab previews.

Keep wording short; do not duplicate the file headers verbatim.

### Task 5 — Validation (read-only shell checks)

Run each; all must pass in a fresh interactive shell (`zsh -i`):

1. New files parse cleanly:
   `zsh -n stow/common/zsh/.config/zsh/lms.zsh` and
   `zsh -n stow/common/zsh/.config/zsh/docker.zsh` (syntax only).
2. Fresh shell starts without errors: `zsh -ic '' >/dev/null; echo $?` → `0`.
3. Both files are externally guarded (no-ops in a shell without the respective binary —
   confirm by inspection: any source of the file without `lms`/`docker` in PATH returns
   early).
4. Registration lands as the shim:
   `zsh -ic 'functions _docker_shim >/dev/null && echo shim-loaded'`
   must print `shim-loaded`, and
   `zsh -ic 'functions _lms >/dev/null && echo lms-loaded'` must print `lms-loaded`.
5. Delegation sanity (non-interactive check of candidate generation only):
   `zsh -ic '_lms_loaded_models'` returns the loaded model identifiers via
   `lms ps --json` (or an empty list when none loaded) without erroring.
6. Homebrew `_docker` behavior preserved downstream: confirm file mode after stow is a
   symlink such that editing `docker.zsh` never edits the Homebrew file (`ls -l ~/.config
   /zsh/docker.zsh` shows only the repo-link).
7. Recursion check: completion path does not call `_docker_shim` from itself (code
   review of Task 2); confirm delegation path uses one `_docker "$@"` call only.

Emulation caveats documented only — actual interactive Tab behavior is verified by the
user; Builder performs the automated checks above.

### Task 6 — Commit

- `git status`, `git diff` review before staging (existing AGENTS.md rules).
- Commit message: `feat(zsh): add lms and docker desktop completion support`
- Files staged: `lms.zsh`, `docker.zsh`, `index.zsh`, `stow/common/zsh/README.md`.
- Do **not** commit the PRD/architecture/plan review file churn in this commit — the
  milestone docs were committed separately (see completion criteria).

## Files Affected

- `stow/common/zsh/.config/zsh/lms.zsh` — created
- `stow/common/zsh/.config/zsh/docker.zsh` — created
- `stow/common/zsh/.config/zsh/index.zsh` — modified (two source lines added)
- `stow/common/zsh/README.md` — modified (two short docs sections added)

## Safety Checks

- No file touches `$HOME` outside the already-stowed zsh package tree; no new stow
  directives; no `stow --adopt` anywhere.
- Both completion files are guarded and no-op without their binaries.
- Every shell invocation from a completion path is read-only (`lms ls/ps --json`,
  `--help` forms); no `lms load/unload/push/dev`, no
  `docker desktop start/stop/restart/update/enable/disable/auth` candidates, no network
  queries.
- Never modifies Homebrew's `_docker`; the shim delegates to it read-only.

## Validation Commands

```bash
zsh -n stow/common/zsh/.config/zsh/lms.zsh
zsh -n stow/common/zsh/.config/zsh/docker.zsh
zsh -ic '' >/dev/null; echo "exit=$?"            # fresh shell clean start
zsh -ic 'functions _lms >/dev/null && echo lms-loaded'
zsh -ic 'functions _docker_shim >/dev/null && echo shim-loaded'
zsh -ic '_lms_loaded_models'                      # read-only candidate generation
grep -n "lms.zsh\|docker.zsh" stow/common/zsh/.config/zsh/index.zsh
git diff --stat                                    # scope check: only 4 files
```

## Rollback Strategy

Purely additive, single-package. Revert:

1. `git revert <commit>` or, before commit, `git checkout -- stow/common/zsh` plus
   `rm` of the two new files (`rm` only inside the repo; never against `$HOME`).
2. Symlinked `$HOME/.config/zsh/lms.zsh` / `docker.zsh` disappear with the files once
   stow tree is reverted; a `stow --simulate` dry-run confirms clean state. `$HOME`
   restore (if ever needed) is a manual user step — never scripted by this plan.

## Completion Criteria

- All six tasks done; validation commands pass.
- `lms <Tab>` and `docker desktop <Tab>` verified working in an interactive shell
  (user confirmation), other docker levels unaffected.
- `stow/common/zsh/README.md` documents both entries.
- Existing repo docs remain consistent; CHANGELOG entry added by the reviewer or builder
  following the established `CHANGELOG.md` format (`feat(zsh): ...` line at the top of
  Unreleased, matching the prior `Taskfile completion` entry style).
