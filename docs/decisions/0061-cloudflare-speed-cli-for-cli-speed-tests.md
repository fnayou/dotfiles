# Decision: cloudflare-speed-cli for CLI Speed Tests, Wired Through the zsh Layer

**Number:** 0061
**Date:** 2026-08-03
**Status:** Accepted

## Context

The repository had no way to measure internet throughput from the terminal. Two candidates were on
the table:

- [`Foxemsx/riptide`](https://github.com/Foxemsx/riptide) — Go, bubbletea TUI, ~169 stars.
- [`kavehtehrani/cloudflare-speed-cli`](https://github.com/kavehtehrani/cloudflare-speed-cli) — Rust,
  ratatui TUI plus headless modes, ~971 stars.

Two repository facts constrain the answer:

1. **Package manifests are the install contract.** `packages/Brewfile`, `packages/arch/packages.txt`,
   and `packages/debian/packages.txt` name a per-platform source for every tool. A tool installable
   only by `curl … | sh` has no manifest home.
2. **A Stow package must own text configuration.** Every package under `stow/common/` exists to manage
   real, diffable config files.

Measured against those:

- Riptide installs via `install.sh` or `go install` only — no Homebrew formula, no Arch repository, no
  Debian path — and stores its preferences and history in a **SQLite database** (`riptide.db`). Binary
  state cannot be version-controlled, diffed, or stowed, so Riptide could never become a package here.
- `cloudflare-speed-cli` is in **Homebrew core** (macOS, no tap) and the **Arch `extra`** repository
  (no AUR). Debian has no package, which is the familiar out-of-band case already handled for
  `go-task`, `oh-my-posh`, `git-cliff`, and `herdr`. It also has `--json` / `--text` / `--silent` /
  `--export-csv`, so it scripts and crons; Riptide is TUI-only with no export.

Other tools were considered and rejected: Ookla's official `speedtest` (proprietary, EULA prompt,
vendor apt repository — against the repository's open, reproducible stance), `librespeed-cli` (good,
but packaged in neither Arch's repositories nor Debian's archive), `fast-cli` (Node dependency,
download-biased), `speedtest-go` (no distribution packaging), and `crusader` (bufferbloat testing —
complementary, needs its own server).

## Decision

Adopt `cloudflare-speed-cli`, and integrate it through the **existing `zsh` package** rather than a
new Stow package.

- Add it to all three manifests: `brew "cloudflare-speed-cli"` [macOS], `pacman -S
  cloudflare-speed-cli` from `extra` [Arch], `cargo install` or a release binary [Debian].
- Add `stow/common/zsh/.config/zsh/speedtest.zsh`, guarded by `command -v cloudflare-speed-cli`,
  sourced from `index.zsh` at slot 6e.
- Because the tool has **no configuration file**, that layer *is* its configuration: three defaults
  (`SPEEDTEST_DOWNLOAD_DURATION`, `SPEEDTEST_UPLOAD_DURATION`, `SPEEDTEST_CONCURRENCY`) set with
  `: "${VAR:=…}"` so `~/.config/zsh/local.zsh` and the environment win, plus three functions:
  `speed` (TUI), `speed-json` (machine-readable), `speed-log` (silent CSV append under XDG state).
- No new Stow package, no `deps:check:*` entry, no Taskfile task — the tool is optional, exactly like
  `herdr`, and is never invoked automatically.

Explicitly rejected: Riptide, a dedicated `stow/common/speedtest/` package, hardcoding flags inside
the functions, and any `apt install` line for Debian.

## Consequences

- **No Catppuccin Macchiato parity.** The tool exposes no colour or theme options, so it will not
  match `bat`, `btop`, `eza`, and `omp`. This gap is **accepted** by the user; revisit only if
  upstream adds theming.
- **Cloudflare-edge semantics.** Results describe the path to the Cloudflare anycast edge, not a
  generic internet path, and are not directly comparable to Ookla figures. Adequate for trend
  tracking; weak as evidence in an ISP dispute.
- **The status blocks do not change.** No Stow package was added or removed, so the `status-sync` rule
  is satisfied without touching `AGENTS.md` §2 or `CLAUDE.md`.
- **The zsh package grows one more tool-specific layer**, alongside `taskfile.zsh`, `herdr.zsh`, and
  `ssh.zsh`. As a new file inside an already-stowed package, it becomes live only after the user
  re-runs `stow` manually.
- **Flags are the API.** The wrappers depend on upstream flag names; a rename fails loudly with an
  unknown-argument error rather than silently. `docs/guides/speedtest-setup.md` tells the user to
  confirm with `cloudflare-speed-cli --help` after install.
- **GPL-3.0** applies to the tool only. It is invoked as a separate binary — no linking, no effect on
  this repository's licence.
