# Architecture: CLI Speed Test Tool

**Number:** 0021
**Status:** Approved
**Date:** 2026-08-03
**PRD:** 0022 — CLI Speed Test Tool

## Context

`cloudflare-speed-cli` was chosen over `riptide` (see PRD 0022). The tool is a single Rust binary
that runs a TUI by default and a headless test with `--json` / `--text` / `--silent`. It reads **no
configuration file**: all ~30 knobs are CLI flags, and run history is written to a state directory it
owns.

The repository's normal shape for a tool is a Stow package under `stow/common/<tool>/` holding real
config files. That shape does not apply here, so the integration has to land somewhere else.

## Proposed Structure

```
packages/
├── Brewfile                  # + brew "cloudflare-speed-cli"          [macOS]
├── arch/packages.txt         # + pacman -S cloudflare-speed-cli       [Arch]
└── debian/packages.txt       # + out-of-band install notes            [Debian]

stow/common/zsh/.config/zsh/
├── index.zsh                 # + guarded source of speedtest.zsh (slot 6e)
└── speedtest.zsh             # NEW — defaults + speed / speed-json / speed-log

docs/
├── guides/speedtest-setup.md # NEW — install, usage, overrides, re-stow
└── decisions/0061-...md      # NEW — ADR for the tool choice
```

## Design Decisions

### Decision 1: No new Stow package — extend the `zsh` package

```
Option A: New package stow/common/speedtest/
  Pro: Symmetric with bat / btop / eza / omp; self-contained.
  Con: The package would contain zero configuration files for the tool — only a zsh
       snippet, which is the zsh package's job. It would also force both status blocks
       to change for a package that manages nothing.

Option B: New guarded layer file inside the existing zsh package
  Pro: The shell layer is exactly where flag defaults and wrapper functions belong;
       matches taskfile.zsh / herdr.zsh / ssh.zsh, which are also tool-specific layers
       shipped by the zsh package. No status-block churn.
  Con: The zsh package grows one more file; the tool's integration is not discoverable
       from the package list alone (mitigated by the setup guide and READMEs).

Decision: Option B. A Stow package must own config files; this tool has none.
```

### Decision 2: Environment variables as the configuration surface

```
Option A: Hardcode flags inside the wrapper functions.
  Pro: Simplest.
  Con: A per-machine change means editing a tracked, stowed file — exactly what
       local.zsh exists to avoid (a fibre desktop and a tethered laptop want
       different durations and concurrency).

Option B: `: "${SPEEDTEST_*:=default}"` defaults, consumed by the functions.
  Pro: Overridable from the environment or from ~/.config/zsh/local.zsh, which is
       sourced last and git-ignored. Repository keeps sane defaults.
  Con: Three extra variables in the shell environment.

Decision: Option B. This is the file's real purpose — it substitutes for the config
file the tool does not have.
```

### Decision 3: Three functions, not one alias

```
Option A: alias speed='cloudflare-speed-cli'
  Pro: One line.
  Con: Carries no defaults and no pass-through composition; the JSON and cron uses
       still need long flag strings by hand.

Option B: speed (TUI) + speed-json (machine-readable) + speed-log (silent CSV append)
  Pro: Covers the three real uses. speed-json and speed-log both delegate to speed, so
       defaults are defined once. Extra flags still pass through via "$@".
  Con: Three names instead of one.

Decision: Option B. speed-log is the reason — an unattended run needs --silent plus a
dated export path, which is not something to retype.
```

### Decision 4: Source position — slot 6e, before keybindings

```
The file defines functions only. It calls no compdef, so it does not depend on compinit
(plugins.zsh, ADR-0049) and does not register hooks, so it is unaffected by the Oh My
Posh hook rewrite that forces zoxide to initialise last (ADR-0049 / tools.zsh comment).

Placing it at 6e — after ssh.zsh, before keybindings — groups it with the other
tool-specific layers and keeps index.zsh readable. Any position after shared.zsh would
work; 6e is chosen for grouping, not for correctness.
```

### Decision 5: History path under XDG state, monthly file

```
speed-log writes ${XDG_STATE_HOME:-$HOME/.local/state}/cloudflare-speed-cli/history-YYYYMM.csv.

State (not config, not cache): it is generated, machine-local, and worth keeping.
Monthly rotation keeps a single file from growing without bound and makes a month's
data easy to hand to a spreadsheet. mkdir -p runs only inside the function — never at
shell startup — so a shell on a machine without the binary creates nothing.
```

### Decision 6: Debian handled out-of-band, not with a fake apt line

```
[macOS] Homebrew core formula — no tap needed.
[Arch]  Official extra repository — no AUR needed.
[Debian] Absent from the archive. Documented under the existing "Out-of-band" section
        of packages/debian/packages.txt with cargo and release-binary options, the same
        treatment already given to go-task, oh-my-posh, git-cliff, and herdr.

Writing `apt install cloudflare-speed-cli` would violate the cross-platform rule and
fail on a real machine.
```

## Risks

- **Flag drift.** Flags were read from upstream `src/cli.rs`, not from a locally installed binary.
  If upstream renames a flag, the wrappers break loudly (unknown argument), not silently. The guide
  tells the user to confirm with `--help` after install.
- **No theming.** The tool has no colour options, so it will not match the Catppuccin Macchiato look
  of the other packages. Accepted by the user; recorded in the ADR.
- **Measurement semantics.** Results describe the path to the Cloudflare edge, not a generic internet
  path, and are not directly comparable to Ookla numbers. Stated in the guide.
- **Name collision.** `speed` is short. Nothing in the repository defines it today, and the file is
  guarded, so it appears only where the binary exists. A user who wants a different name overrides in
  `local.zsh`.
- **Stow timing.** The `zsh` package is already stowed as per-file symlinks with `--no-folding`, so a
  **new** file is not linked until the user re-runs `stow`. The guide states this explicitly.
- **Reversibility.** Full: delete one file, remove one line from `index.zsh`, drop the manifest lines.

## Extensibility

- More knobs are additive: another `: "${SPEEDTEST_*:=...}"` line plus a flag in `speed`.
- If upstream ever ships a completion generator, a `compdef` block can move into this same file — it
  would then need to be sourced after `compinit`, which slot 6e already satisfies.
- If a second network tool arrives (`mtr`, `crusader`), the file generalises to a `network.zsh` layer
  or a sibling layer with the same guarded shape.

## Open Questions

None. Theming gap accepted; Debian path settled; no Taskfile surface.

## Recommended Next Step

Planner: produce the ordered implementation plan (manifests → layer file → index wiring → docs →
website), with `zsh -n` validation and a git-based rollback.
