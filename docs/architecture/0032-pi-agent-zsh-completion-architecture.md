# Architecture: zsh Completion for the pi Coding Agent CLI

**Number:** 0032
**Status:** Approved
**Date:** 2026-11-11
**PRD:** 0036 — zsh Completion for the pi Coding Agent CLI

## Context

`pi` (1.5.2, installed at `~/.local/bin/pi`) ships no zsh completion: `pi completion zsh` prints no
script and there is no `_pi` on `fpath`. The `zsh` stow package already authors completions for tools
in the same position: `herdr.zsh` and `lms.zsh` (ADR-0049: `compinit` runs once in `plugins.zsh`; tool
files only call `compdef`). `index.zsh` sources them in numbered slots after `completions.zsh`; the
last completion slots are 6f (`lms`) and 6g (`docker`).

## Proposed Structure

```
stow/common/zsh/.config/zsh/
├── pi.zsh        # new: guarded completion for `pi` (function _pi + compdef)
└── index.zsh     # modified: new slot 6h sources pi.zsh
scripts/
└── test-pi-completion.sh   # new: static safety and load checks
```

`pi.zsh` follows `lms.zsh`: `command -v pi >/dev/null 2>&1 || return` first, a header with the pi
version the trees were validated against, helper functions for live candidates, one `_pi` function
built on `_arguments -C`, `compdef _pi pi`, and fzf-tab preview zstyles that run read-only help
commands.

## Design Decisions

### Decision 1: Hand-written `_arguments` function

Option A: hand-written `_pi`, as `lms.zsh` does.
  Pro: no runtime cost, no subprocess for static trees, matches the existing pattern.
  Con: drifts when pi adds commands; the validated version in the header is the mitigation.

Option B: generate the tree at completion time by parsing `pi --help`.
  Pro: never drifts.
  Con: the help is prose, not a stable format; parsing is fragile and runs on every Tab.

Decision: **A**.

### Decision 2: Live candidates, read-only only

| Candidate | Source | Why safe |
|---|---|---|
| `--model`, `--provider` values | `pi --list-models` (columns 1 and 2, header skipped) | local table, 0.2 s, no network |
| `pi remove` / `uninstall` source | `pi list` (lines starting with two spaces and a source prefix) | prints settings, no network |
| `pi mcp remove|login|logout` server | `jq -r 'keys[]'` over `~/.pi/agent/mcp.json` (the `mcpServers` object when present) | reads key names only |

`pi mcp list` is rejected as a source: it starts servers and can exit 1. `pi auth ...` is never run.
Each helper runs with `2>/dev/null` and falls back to no candidates. `jq` missing means no server
names.

A call to `pi --list-models` for a `--model` value may list the same model under several providers;
candidates keep the `provider/id` form so the value is unambiguous and matches pi's own syntax.

### Decision 3: Fixed value lists for documented options

`--mode (text json rpc)`, `--thinking (off minimal low medium high xhigh max)`,
`--tui-mode (fullscreen regular)`. The `update` flags (`--self --extensions --models --all`), the
`auth` subcommands (`login logout print-api-key print-bearer-token check`) and the `mcp` subcommands
(`add remove list login logout`) are listed statically. `--provider` and `--model` also accept free
text, so `_pi` offers the live list without forcing a match.

### Decision 4: Slot and registration

A new slot 6h in `index.zsh`, after `docker.zsh`, guarded like its neighbours. `compdef _pi pi` runs
inside `pi.zsh`, after `compinit`.

### Decision 5: Tests

A bash script `scripts/test-pi-completion.sh` that needs only zsh and the repo:

- `zsh -n pi.zsh`.
- In an interactive-less `zsh -f` with a stub `pi` on `PATH`, sourcing `pi.zsh` returns 0 and defines
  `_pi`; with `pi` missing it defines nothing.
- The file contains no mutating pi call: it fails if `pi.zsh` mentions `pi install`, `pi update`,
  `pi auth`, `pi mcp list`, `print-api-key` or `auth.json` outside comments.
- The `mcp.json` helper, run against a made-up file, returns only key names and never a value.

Real Tab behaviour is checked by the user in a new terminal (plan user-validation task).

## Risks

- **Drift:** new pi commands are not completed until the file is updated. Header notes the version.
- **Extension flags:** extensions add flags (`--plan`) that `_pi` does not know; zsh falls back to file
  completion for them. Accepted.
- **Slow `pi` start:** `pi --list-models` and `pi list` run only on a Tab at that position; measured
  0.2 s and 0.15 s here.
- **`mcp.json` content:** may hold secrets in values. The helper extracts keys with `jq` and never
  reads or prints values; the test asserts that.
- **Platform:** tested on macOS only. The file uses `compdef`, `_arguments`, `compadd` and `jq`
  (optional), so it should work on Arch and Debian; untested.
- **Stow:** `pi.zsh` is a new file in a stowed package; it needs a re-stow (dry run first).

## Extensibility

Adding a command is one new `case` branch. If pi later ships its own completion, delete `pi.zsh`
and its `index.zsh` slot.

## Open Questions

- Exact output shapes of `pi list` and `pi --list-models` under other settings (no packages, no
  models): the spike in the plan checks the empty cases return no candidates and no error.
- Whether the extra flags of `pi mcp add` (`--url`, `--env`, `--cwd`) should be completed: planned yes,
  static only.

## Recommended Next Step

User approves this architecture; the Planner writes plan 0040 with a short spike on the two list
parsers, then the build, tests, docs, ADR 0088 and review 0112.

## Spike Results

Run on pi 1.5.2 (2026-11-11), read-only:

- `pi --list-models` prints a whitespace table with a header row (`provider model context max-out
  thinking images`); the provider is column 1 and the model id column 2. Model ids can contain `/`
  and `@`. `provider/id` is the value form pi documents for `--model`.
- `pi list` prints `User packages:` then one source per line indented by two spaces
  (`  npm:...`), each followed by its path indented by four spaces. The empty case was not
  produced (it would need removing the user's packages); the parser yields no candidates for any
  output without two-space lines.
- `mcp.json` holds the servers under a `mcpServers` object; the helper reads only its keys.
- `pi mcp add` has more flags than the PRD listed (`--header`, `--bearer-token-env-var`,
  `--oauth-*`, `--exposure`, `--description`); all are completed statically, value-less.

