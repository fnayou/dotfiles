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

`OS icon | model | path | git branch+status | ctx % | caveman badge`

- **ctx %** reads `.context_window.used_percentage` from the status line JSON
  (Claude Code ≥ 2.1); hidden when null (early session / right after `/compact`).
- **caveman badge** is appended only when the caveman plugin is installed and active.

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
