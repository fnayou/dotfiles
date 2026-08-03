# PRD: CLI Speed Test Tool

**Number:** 0022
**Status:** Approved
**Date:** 2026-08-03

## Context

The repository has no way to measure internet throughput from the terminal. Two candidates were
evaluated: [`Foxemsx/riptide`](https://github.com/Foxemsx/riptide) (Go, TUI, SQLite state) and
[`kavehtehrani/cloudflare-speed-cli`](https://github.com/kavehtehrani/cloudflare-speed-cli) (Rust,
TUI + headless, Cloudflare backend).

`cloudflare-speed-cli` was selected. The rationale is recorded in
`docs/decisions/0061-cloudflare-speed-cli-for-cli-speed-tests.md`.

## Goals

- Add `cloudflare-speed-cli` to all three platform package manifests (macOS, Arch, Debian).
- Give the tool a managed configuration surface, since it ships **no config file** — every knob is a
  CLI flag.
- Provide short, memorable shell entry points for the three real uses: interactive run,
  machine-readable run, and unattended logging.
- Keep the integration optional and guarded — a machine without the binary must start a clean shell.
- Document install, usage, and overrides in a per-tool setup guide.

## Non-Goals

- Creating a new Stow package. The tool has no config file to manage, so there is nothing for a
  dedicated package to hold.
- Theming. The tool exposes no colour or theme options, so Catppuccin Macchiato parity with `bat`,
  `btop`, `eza`, and `omp` is **not** achieved. This gap is accepted by the user.
- Replacing Ookla Speedtest for ISP disputes. The measured path is to the Cloudflare edge only.
- Adding a `deps:check:*` entry or a Taskfile task. The tool is optional and not part of the shell
  dependency tier, matching how `herdr` is handled.
- Running any speed test automatically at shell startup, on a timer, or from a hook.

## User Stories

- As a user, I want `speed` to run a speed test with sane defaults so that I do not retype flags.
- As a user, I want `speed-json` to emit machine-readable output so that I can pipe results to `jq`.
- As a user, I want `speed-log` to record silent results so that I can track my connection over time
  from `cron` or a systemd timer, and `speed-history` to export those results to a CSV on demand.
- As a user, I want the integration to vanish cleanly on machines without the binary so that the same
  stowed config works everywhere.
- As a user, I want per-machine tuning (durations, concurrency) without editing a tracked file.

## Constraints

- **Platform:** common. The binary exists for macOS, Arch, and Debian; only the install source differs.
  - [macOS] Homebrew core formula — `brew install cloudflare-speed-cli`.
  - [Arch] official `extra` repository — `sudo pacman -S cloudflare-speed-cli`.
  - [Debian] absent from the Debian archive — out-of-band, like `go-task`, `oh-my-posh`, `git-cliff`.
- **No config file:** the tool is flag-driven. Defaults must live in the shell layer.
- **Ordering:** the new layer defines functions only (no `compdef`), so it does not depend on
  `compinit`.
- **Licence:** GPL-3.0. Invoked as a separate binary — no linking, no effect on this repository.
- **Overrides:** must be possible from `~/.config/zsh/local.zsh`, which is git-ignored and sourced
  last.

## Safety Requirements

- Must not create, delete, move, or overwrite any file in `$HOME` during implementation.
- Must not run `stow` — the `zsh` package is already stowed, so the new file becomes live only after
  the user re-runs `stow` manually.
- Must not run a speed test automatically; every function is user-invoked.
- `speed-log` may create only its own directory under `${XDG_STATE_HOME:-$HOME/.local/state}` and only
  when the user calls it.
- Must not hardcode machine-specific paths — `$HOME` / XDG variables only.
- Install commands in docs carry `⚠️  MANUAL STEP` markers and are never executed by an agent.

## Acceptance Criteria

- [ ] `packages/Brewfile` lists `cloudflare-speed-cli` under a network section.
- [ ] `packages/arch/packages.txt` documents the `pacman` install under a network section.
- [ ] `packages/debian/packages.txt` documents the out-of-band install with the other non-archive tools.
- [ ] `stow/common/zsh/.config/zsh/speedtest.zsh` exists, is guarded by `command -v
      cloudflare-speed-cli`, and defines `speed`, `speed-json`, `speed-log`, and `speed-history`.
- [ ] Defaults are set with `: "${VAR:=...}"` so `local.zsh` and the environment can override them.
- [ ] `index.zsh` sources the new layer, guarded, without altering existing ordering guarantees.
- [ ] `docs/guides/speedtest-setup.md` documents per-platform install, the three functions, the
      override recipe, and the re-stow step.
- [ ] `docs/decisions/0061-cloudflare-speed-cli-for-cli-speed-tests.md` records the choice, the
      rejected alternatives, and the accepted theming gap.
- [ ] `stow/common/zsh/README.md`, `README.md`, and the affected `website/` pages mention the layer.
- [ ] `zsh -n` parses the new layer and `index.zsh` cleanly.
- [ ] No Stow package added or removed, so the `AGENTS.md` §2 / `CLAUDE.md` status blocks stay as-is.

## Out of Scope

- A `debian.zsh` per-OS layer (still does not exist).
- Zsh completion for `cloudflare-speed-cli` (the binary ships no completion generator today).
- Self-hosted alternatives (`librespeed-cli`) and proprietary Ookla `speedtest`.
- Bufferbloat / latency-under-load tooling (`crusader`).
- Dashboards or plotting over the CSV history.
