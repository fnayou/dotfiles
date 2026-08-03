# Review: CLI Speed Test Tool Implementation

**Number:** 0067
**Status:** Complete
**Date:** 2026-08-03
**Plan reviewed:** 0027 — Implement CLI Speed Test Tool
**Files reviewed:**

- `packages/Brewfile` (modified)
- `packages/arch/packages.txt` (modified)
- `packages/debian/packages.txt` (modified)
- `stow/common/zsh/.config/zsh/speedtest.zsh` (created)
- `stow/common/zsh/.config/zsh/index.zsh` (modified)
- `stow/common/zsh/README.md` (modified)
- `README.md` (modified)
- `docs/prd/0022-cli-speed-test-tool.md` (created)
- `docs/architecture/0021-cli-speed-test-tool-architecture.md` (created)
- `docs/plans/0027-implement-cli-speed-test-tool.md` (created)
- `docs/decisions/0061-cloudflare-speed-cli-for-cli-speed-tests.md` (created)
- `docs/guides/speedtest-setup.md` (created)
- `website/features/shell.md` (modified)
- `website/usage/functions.md` (modified)

## Summary

Reviewed the implementation of **Plan 0027 — Implement CLI Speed Test Tool** (PRD 0022,
Architecture 0021): `cloudflare-speed-cli` added to the three platform manifests, and a guarded
`speedtest.zsh` layer added to the existing `zsh` Stow package providing `speed`, `speed-json`, and
`speed-log` plus three overridable defaults. No new Stow package; the tool ships no config file, so
the shell layer is its configuration surface.

Validation run and passing:

- `zsh -n` clean on `speedtest.zsh` and `index.zsh`.
- Guard `command -v cloudflare-speed-cli` present and the only command executed at source time.
- `index.zsh` sources the layer exactly once (slot 6e); existing ordering guarantees (`compinit` in
  `plugins.zsh`, fzf before completion styles, zoxide last) unchanged.
- All three manifests reference the tool with the correct per-platform source.
- `git status --short` shows only the 14 files listed above.

## Blocking Issues

None.

## Non-Blocking Suggestions

- Flag names (`--download-duration`, `--upload-duration`, `--concurrency`, `--json`, `--silent`,
  `--export-csv`) were derived from upstream `src/cli.rs`, not from a locally installed binary — the
  tool is not installed on this machine. Confirm with `cloudflare-speed-cli --help` on first install.
  A mismatch fails loudly (unknown argument), never silently; the guide already documents this.
- `speed` is a short, generic name. Nothing in the repository currently defines it, and the guide
  documents overriding it from `local.zsh` if it ever collides.
- If upstream adds a completion generator, the `compdef` wiring belongs in this same file — slot 6e is
  already after `compinit`, so no reordering would be needed.

## Safety Verdict

PASS — No `stow --adopt`, no `stow` invocation of any kind, no `ln -s`, and no `rm`/`mv` targeting
`$HOME` or anything outside the repository. `speedtest.zsh` executes nothing at source time beyond its
`command -v` guard, defines functions only, and its single write (`mkdir -p` under
`${XDG_STATE_HOME:-$HOME/.local/state}/cloudflare-speed-cli`) happens only when the user calls
`speed-log`. No speed test runs automatically. Every destructive command in
`docs/guides/speedtest-setup.md` (§8 rollback, history deletion) and in the plan's rollback section
carries a `⚠️  MANUAL STEP` marker on the line directly preceding the fence, and both Stow commands
are preceded by a dry-run. Files written are all inside the repository root.

## Privacy Verdict

PASS — Staged content contains no credentials, tokens, keys, passwords, private hostnames, or internal
IPs. `git diff | grep -iE "password|token|api[_-]?key|secret|BEGIN.*PRIVATE|/Users/|/home/"` returns
nothing. Paths are `$HOME`- and XDG-derived only, with no machine-specific values. The CSV history is
written outside the repository working tree and is never committed. Note for the user: exported JSON
and CSV results contain the public IP and ISP of the machine that ran the test — they are personal
data and must not be pasted into the repository or an issue.

## Documentation Verdict

PASS — `docs/guides/speedtest-setup.md` is copy-pasteable and per-platform, with `# macOS` / `# Arch`
/ `# Debian` comments on install blocks and a platform-source table. Debian is documented as
out-of-band (`cargo install` or release binary), never as a fake `apt install` line; the Arch entry
correctly points to the official `extra` repository (no AUR) and the macOS entry to Homebrew core (no
tap). ADR 0061 records the choice, the rejected alternatives, and the accepted theming gap. PRD 0022,
Architecture 0021, and Plan 0027 cross-reference each other by number, and the guide links all three.
The Cloudflare-edge measurement caveat and the absence of Catppuccin theming are stated in the guide,
the ADR, and the website page.

## Status Sync Check

No Stow package was added, removed, or first stowed — the change extends the already-stowed `zsh`
package with one file. The `AGENTS.md` §2 and `CLAUDE.md` status blocks correctly remain untouched
(`.claude/rules/status-sync.md` self-check passes).

## Recommended Next Action

Approve and commit. Plan 0027 is marked **Complete**.

After merging, on each machine: install the binary for that platform, then re-run the `zsh` package
dry-run and Stow (per-file symlinks — a new file is not linked until you re-stow).
