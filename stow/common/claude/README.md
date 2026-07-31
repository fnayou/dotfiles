# claude — Claude Code statusline

Category: **common** (portable across macOS and Arch / EndeavourOS).

Manages the Claude Code status line script. The look mirrors the Oh My Posh
theme shipped by the `omp` package (Catppuccin Macchiato), so the terminal
prompt and the Claude Code status line stay visually consistent.

## Contents

| Source (repo)                                  | Target (`$HOME`)                  |
|------------------------------------------------|-----------------------------------|
| `stow/common/claude/.claude/statusline-command.sh` | `$HOME/.claude/statusline-command.sh` |
| `stow/common/claude/.claude/statusline-caveman.js` | `$HOME/.claude/statusline-caveman.js` |

`statusline-command.sh` reads the Claude Code status line JSON from stdin
**exactly once** and holds it in `$input`. Segments that need the payload are
handed that copy — no segment re-reads the stream. `statusline-caveman.js` is the
only segment implemented outside the main script; it is resolved as a sibling of
`statusline-command.sh`, so it works both stowed and when run from the repository.

`stow/common/claude/tests/` holds the segment's test suite. It is not a stow
source and is never linked into `$HOME` (`.stow-local-ignore` excludes it).

The script is fully portable — it detects the OS at runtime, uses `$HOME`, and
contains **no secrets or machine-specific paths**. No `.example` step needed.

## Scope — what this package deliberately excludes

`~/.claude/` holds credentials, session transcripts, and runtime state. Only the
portable status line script is tracked here. **Never** add these to the package:

- `.credentials.json` — auth tokens
- `settings.local.json` — machine-local overrides
- `projects/`, `plugins/`, `history.jsonl`, `*.log`, `stats-cache.json`, caveman
  runtime files (`.caveman-*`)

## Segments

`OS icon | model | path | git branch+status | PR/MR | ctx % | rtk savings | caveman badge`

- **path** shows the home-relative path, truncated to the last 3 components
  (`.../projects/document-generator`) when deeper.
- **PR/MR** shows the open request for the current branch. The forge is detected
  from the `origin` remote URL: GitHub → `gh`, `#` sigil, github glyph; GitLab →
  `glab`, `!` sigil, gitlab glyph. Cached per repo+branch, refreshed in the
  background so it never blocks; the number appears one render after the branch
  first gains a request. Set `STATUSLINE_NERD_FONT=0` to render the ASCII label
  (`PR`/`MR`) instead of the icon — a shell cannot detect whether the terminal
  font has the glyph, so this fallback is a manual toggle, not automatic.
- **ctx %** reads `.context_window.used_percentage` from the status line JSON
  (Claude Code ≥ 2.1); hidden when null (early session / right after `/compact`).
- **rtk savings** and **caveman badge** are the two optional segments below.

## Optional segments (external tools)

The last two segments depend on tools this package does **not** install. Each is
guarded — absent tool → the segment renders nothing (no error, no placeholder).

### rtk savings

Shows tokens saved + average savings % for the **current directory** from
[rtk](https://github.com/rtk-ai/rtk) (Rust Token Killer). The script calls
`rtk gain --project --format json` — a public CLI, so we own the rendering.
`--project` filters to the **exact** working directory — not the whole repo, so
`cd`-ing into a subdirectory shows only that directory's stats (drop the flag for
the global all-time total). In a Claude Code session the working directory is the
workspace dir, usually the repo root. Guarded by `command -v rtk`; also hidden
until rtk has at least one recorded run for this directory.

### caveman badge

Shows the [caveman](https://github.com/JuliusBrussee/caveman) plugin's mode badge
plus estimated tokens saved, **scoped to this session and this repository**.

| State | Renders |
|---|---|
| mode `full`, one session | `[CAVEMAN] ⛏ 68.3k` |
| mode `full`, repo has more | `[CAVEMAN] ⛏ 68.3k sess · 844.7k repo` |
| mode `lite` / `ultra` / `wenyan-*` | `[CAVEMAN:ULTRA]` — no benchmark data exists for those modes |
| installed, no mode active | `[CAVEMAN:OFF]` |
| not installed, or any failure | *(nothing)* |

#### Why not caveman's own statusline script

We used to call `caveman-statusline.sh`, which renders
`~/.claude/.caveman-statusline-suffix`. That file holds the sum of **every
caveman session ever recorded on this machine, across every project** — a
machine-wide lifetime total sitting in a project-scoped status line, immediately
next to the project-scoped `rtk` figure, reading as if it belonged to the current
project. It is also frozen between `/caveman-stats` runs.

`statusline-caveman.js` replaces it. See
`docs/prd/0021-caveman-session-scoped-savings.md` and ADRs 0056–0060.

#### How the numbers are produced

**Session** — recomputed every render from the `transcript_path` Claude Code
supplies in the status line payload. That transcript belongs to exactly one
session, so no other session can contribute. Caveman's own `parseSession` and
`deriveSavings` are called directly; the estimate is caveman's, not a
reimplementation. Warm renders parse only the bytes appended since the last one,
via a byte-offset cache.

**Repository** — the sum of a small ledger this script maintains, one file per
session, so a session can never be counted twice:

```
${XDG_CACHE_HOME:-$HOME/.cache}/claude-statusline/caveman/repos/<hash>/<session-id>.json
${XDG_CACHE_HOME:-$HOME/.cache}/claude-statusline/caveman/sessions/<session-id>.json
```

Caveman's `.caveman-history.jsonl` cannot supply this — its rows carry no project
or repository field, and are written only when you run `/caveman-stats`.

The repository key prefers the git remote (`github.com/owner/name`, from the
payload or `git remote get-url origin`), falling back to the canonicalised git
top level, then `project_dir`, then `current_dir`. Nothing requires a remote.

#### Things worth knowing

- **Repository totals start when this segment is installed.** Sessions from
  before it cannot be counted — caveman never recorded which mode they ran in.
- **Two clones or worktrees of one repository share one total**, by design: they
  resolve to the same remote-derived identity.
- **The ledger is a cache.** Deleting
  `${XDG_CACHE_HOME:-$HOME/.cache}/claude-statusline/caveman/` loses repository
  history and nothing else; the session figure is recomputed regardless.
- **Caveman's mode flag is global** (`~/.claude/.caveman-active`, one file for the
  whole machine). Two concurrent sessions cannot run different modes, and
  `/caveman off` in one session disables caveman in the other. That is upstream
  behaviour and predates this change; token figures stay independent per session
  because they come from separate transcripts. See ADR 0060.
- **Cost.** The segment adds roughly 50 ms per render, almost all of it Node
  start-up. The status line is debounced at 300 ms.
- Caveman's plugin path is **globbed**, not hardcoded — `marketplaces/` first,
  then the newest `cache/<name>/<name>/<hash>/` checkout by mtime, with
  `$CAVEMAN_HOOKS_DIR` as an override. Nothing under `~/.claude/plugins/` is ever
  written; the plugin checkout is read-only to us (ADR 0056).

#### Degradation

If `node` is missing or `statusline-caveman.js` is not stowed, the script falls
back to caveman's own badge with `CAVEMAN_STATUSLINE_SAVINGS=0` — the mode badge
with **no number**. Degrading to less information, never to the wrong number.

To add caveman: install the plugin, then activate a mode with `/caveman full`
(or `lite`/`ultra`). No dotfiles change needed — the segment lights up automatically.

#### Tests

```bash
# Unit tests — the segment's internals (parser equivalence, ledger, identity)
task test:statusline

# End-to-end — drives the real statusline-command.sh as Claude Code does
task check:statusline
```

Both run against a temporary `XDG_CACHE_HOME`; neither touches the real cache,
caveman's state files, or `$HOME`. The unit tests skip the caveman-dependent
cases when the plugin is absent, so the suite passes on a machine without it
(this is what CI runs).

`scripts/check-statusline.sh` goes further and redirects `CLAUDE_CONFIG_DIR` to a
temp directory holding its own mode flag, so the result does not depend on which
caveman mode you happen to have active and your real flag is never read. Its
transcripts are synthesised rather than taken from `~/.claude/projects/`, so it
depends on none of your session history and reveals nothing from it.

## Wiring

Claude Code reads the script path from `~/.claude/settings.json`:

```json
"statusLine": { "type": "command", "command": "bash \"$HOME/.claude/statusline-command.sh\"" }
```

`settings.json` is **not** managed by this package (kept local).

## Install

`--no-folding` forces per-file symlinks so stow links only
`statusline-command.sh` and never the whole `~/.claude/` directory (which holds
credentials and session data).

```bash
# Step 1 — dry run (verify what would be linked; expect a CONFLICT if a real
# ~/.claude/statusline-command.sh already exists — resolve it manually first)
stow --dir=stow/common --target="$HOME" --no-folding --simulate claude
```

Re-run the same pair after pulling a change that adds a file to this package —
already-correct links are left alone and only the new one is created. `tests/` is
excluded by `.stow-local-ignore` and is never linked into `$HOME`.

⚠️  MANUAL STEP — run only after reviewing dry-run output and resolving any conflict
```bash
stow --dir=stow/common --target="$HOME" --no-folding claude
```

Do not use `stow --adopt`. If the dry run reports a conflict with an existing
real file, back it up and remove it yourself, then re-run the dry run before
installing.
