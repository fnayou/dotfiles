# claude — Claude Code statusline

Category: **common** (portable across macOS and Arch / EndeavourOS).

Manages the Claude Code status line script. The look mirrors the Oh My Posh
theme shipped by the `omp` package (Catppuccin Macchiato), so the terminal
prompt and the Claude Code status line stay visually consistent.

## Contents

| Source (repo)                                  | Target (`$HOME`)                  |
|------------------------------------------------|-----------------------------------|
| `stow/common/claude/.claude/statusline-command.sh` | `$HOME/.claude/statusline-command.sh` |

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

Appends the `[CAVEMAN]` mode badge + token-savings suffix from the
[caveman](https://github.com/JuliusBrussee/caveman) Claude Code plugin. Caveman
exposes no query CLI, so instead of reparsing its private state files we **call its
own hardened statusline script** — that script is its stable seam.

The script path is **globbed**, not hardcoded, because Claude Code installs plugins
under either layout, and the cache hash changes per release:

```
~/.claude/plugins/marketplaces/caveman/src/hooks/caveman-statusline.sh   # canonical
~/.claude/plugins/cache/caveman/*/*/src/hooks/caveman-statusline.sh      # versioned checkout
```

First existing match wins. The badge only appears when caveman is both installed
**and** active (`~/.claude/.caveman-active` set via `/caveman <level>`).

To add caveman: install the plugin, then activate a mode with `/caveman full`
(or `lite`/`ultra`). No dotfiles change needed — the segment lights up automatically.

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

⚠️  MANUAL STEP — run only after reviewing dry-run output and resolving any conflict
```bash
stow --dir=stow/common --target="$HOME" --no-folding claude
```

Do not use `stow --adopt`. If the dry run reports a conflict with an existing
real file, back it up and remove it yourself, then re-run the dry run before
installing.
