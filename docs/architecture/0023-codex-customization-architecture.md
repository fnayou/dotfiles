# Architecture: Codex Customization Package

**Number:** 0023
**Status:** Approved
**Date:** 2026-08-27
**PRD:** 0025 — Codex Customization Package

## Context

The live Codex config at `~/.codex/config.toml` contains portable UI choices and machine-local
project trust entries. Codex `0.149.1` loads `tui.theme`, `tui.status_line_use_colors`, and
`tui.status_line`, and `codex doctor` reports the config as valid. The installed binary advertises
the built-in status line items currently used here:

- `model-with-reasoning`
- `current-dir`
- `git-branch`
- `pull-request-number`
- `branch-changes`
- `context-used`
- `five-hour-limit`
- `weekly-limit`

The binary also contains `command` as a status line item name, but this inspection did not find a
documented way to bind an arbitrary external command to that item. `codex doctor --strict-config`
does not reject unknown status line item values, so it cannot be used as proof that a custom savings
segment will render.

The existing Claude Code status line already solves the two scoped-savings problems:

- `rtk` uses `rtk gain --project --format json`, so it is scoped to the current working directory
  instead of lifetime totals.
- caveman uses `transcript_path` for session savings and a status-line-owned per-session repository
  ledger, explicitly avoiding caveman's machine-wide lifetime suffix.

## Proposed Structure

```
stow/common/codex/
├── .codex/
│   └── config.toml
└── README.md
```

Target after a future manual stow:

```
stow/common/codex/.codex/config.toml
  -> $HOME/.codex/config.toml
```

## Decisions

1. **Package category: `common`.** The config path and values are portable across macOS, Arch /
   EndeavourOS, and Debian. No platform-specific package split is needed.
2. **Manage `config.toml` only.** Auth, caches, logs, plugins, project state, and model caches stay
   outside the package. This mirrors the Claude package's single-file-in-sensitive-directory model.
3. **Do not commit `[projects]`.** Trust paths are machine-specific absolute paths. A user stowing
   this package will re-add trusted projects locally through Codex or by editing their local config.
4. **Use `--no-folding`.** A folded `~/.codex` symlink would hide auth and runtime state behind a
   repository directory. The package README requires per-file stowing.
5. **Ship built-in status line customization now.** The config tracks the supported built-in status
   line items and color setting. It does not add `rtk` or caveman items.
6. **Defer Codex `rtk` and caveman savings segments.** They are feasible only if Codex exposes a
   documented external status line command/payload or first-class plugin hook. The Claude algorithms
   can be reused once such a surface is available; until then, adding them would rely on unsupported
   behaviour.

## Recommended Additional Customizations

- Keep `terminal_title` managed later if a stable preferred title layout emerges.
- Add optional profile files only when there is a real split, such as `fast` versus `thorough`.
- Keep hooks enabled in base config, but manage actual hooks in a separate PRD because hooks can run
  commands and need their own trust and safety review.
- Avoid managing MCP servers in this package; those often carry credentials or service-specific
  setup and should be reviewed one integration at a time.

## Risks

- **Codex schema drift:** status line item names may change. Mitigation: document the Codex version
  used for validation and keep the package small.
- **Loss of local trust entries:** stowing `config.toml` would replace a live config that contains
  `[projects]`. Mitigation: README tells the operator to back up and merge local project trust
  entries manually.
- **Sensitive directory folding:** mitigated by mandatory `--no-folding`.
- **False scoped-savings display:** avoided by not implementing `rtk` or caveman segments until Codex
  exposes a supported custom segment interface.

## Open Questions

- Does a future Codex release document the `command` status line item as an external command segment?
- Should this repository eventually manage a global `~/.codex/AGENTS.md`? The live file imports
  `RTK.md` with an absolute path, so it is intentionally out of scope for this package.

## Recommended Next Step

Planner: create a narrow implementation plan that adds the package and docs, updates status blocks,
validates with read-only commands, and does not stow anything into `$HOME`.
