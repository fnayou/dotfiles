# Speed Test Setup Guide (`cloudflare-speed-cli`)

Terminal speed tests via [`cloudflare-speed-cli`](https://github.com/kavehtehrani/cloudflare-speed-cli),
wired into the `zsh` package as a guarded layer.

Related: PRD `docs/prd/0022-cli-speed-test-tool.md` · Architecture
`docs/architecture/0021-cli-speed-test-tool-architecture.md` · Decision
`docs/decisions/0061-cloudflare-speed-cli-for-cli-speed-tests.md`.

---

## 1. What this manages

This is **not** a Stow package — the tool ships no configuration file. The integration is one file
inside the existing `zsh` package:

```
stow/common/zsh/.config/zsh/speedtest.zsh   →   ~/.config/zsh/speedtest.zsh
```

It is sourced from `index.zsh` (slot 6e) and guarded by `command -v cloudflare-speed-cli`, so on a
machine without the binary it does nothing at all.

The file provides:

| Name | Kind | Purpose |
|---|---|---|
| `SPEEDTEST_DOWNLOAD_DURATION` | variable (default `10s`) | Download phase duration |
| `SPEEDTEST_UPLOAD_DURATION` | variable (default `10s`) | Upload phase duration |
| `SPEEDTEST_CONCURRENCY` | variable (default `6`) | Parallel workers |
| `speed` | function | Interactive TUI run using the defaults |
| `speed-json` | function | Headless run, JSON to stdout |
| `speed-log` | function | Silent run, appended to a monthly CSV |

---

## 2. Two caveats before you start

- **No theming.** The tool exposes no colour or theme options, so it does **not** match the Catppuccin
  Macchiato look of `bat`, `btop`, `eza`, and `omp`. This is a known, accepted gap.
- **It measures the path to Cloudflare.** Results describe your connection to the Cloudflare anycast
  edge, not a generic internet path, and are not directly comparable to Ookla Speedtest numbers. Good
  for tracking your own line over time; weak as evidence in an ISP dispute.

---

## 3. Platform notes

| Platform | Source | Command |
|---|---|---|
| macOS | Homebrew core (no tap) | `brew install cloudflare-speed-cli` |
| Arch / EndeavourOS | official `extra` repository (no AUR) | `sudo pacman -S cloudflare-speed-cli` |
| Debian (trixie / 13+) | not in the archive — out-of-band | `cargo install cloudflare-speed-cli` |

---

## 4. Prerequisites

### macOS

Installed by the Brewfile along with everything else:

⚠️  MANUAL STEP — review before running

```bash
# macOS
brew bundle --file=packages/Brewfile
```

Or on its own:

⚠️  MANUAL STEP — review before running

```bash
# macOS
brew install cloudflare-speed-cli
```

### Arch / EndeavourOS

⚠️  MANUAL STEP — review before running

```bash
# Arch
sudo pacman -S cloudflare-speed-cli
```

### Debian (stable, trixie / 13+)

Not in the Debian archive. Either build it with a Rust toolchain:

⚠️  MANUAL STEP — review before running

```bash
# Debian
cargo install cloudflare-speed-cli
```

Or download a static binary from the
[releases page](https://github.com/kavehtehrani/cloudflare-speed-cli/releases) and place it on your
`PATH` (e.g. `~/.local/bin`).

### Verify the install

```bash
cloudflare-speed-cli --version
cloudflare-speed-cli --help
```

Read `--help` once: the wrapper functions pass flags straight through, and `--help` is the
authoritative list for your installed version.

---

## 5. Activating the shell layer

The `zsh` package is stowed with `--no-folding`, which creates **per-file** symlinks. A newly added
file is therefore **not** linked until you re-run Stow. Dry-run first:

```bash
stow --dir=stow/common --target="$HOME" --no-folding --simulate zsh
```

Expect a single `LINK: .config/zsh/speedtest.zsh …` line and no `CONFLICT` lines. Then apply:

⚠️  MANUAL STEP — run only after reviewing the dry-run output

```bash
stow --dir=stow/common --target="$HOME" --no-folding zsh
```

Start a new shell, then confirm:

```bash
# Symlink resolves into the repository
readlink -f ~/.config/zsh/speedtest.zsh

# Functions are defined (requires cloudflare-speed-cli installed)
type speed speed-json speed-log
```

If `type` reports "not found", the binary is missing — that is the guard working as designed.

---

## 6. Daily usage

Interactive run with the repository defaults:

```bash
speed
```

Any extra flag passes through, so one-off overrides need no configuration change:

```bash
speed -4                       # IPv4 only
speed --compare-ip-versions    # IPv4 vs IPv6 side by side
speed --traceroute             # add a traceroute to the Cloudflare edge
```

Machine-readable output:

```bash
speed-json | jq '.'
```

Silent run appended to a monthly CSV under XDG state:

```bash
speed-log
ls "${XDG_STATE_HOME:-$HOME/.local/state}/cloudflare-speed-cli/"
```

`speed-log` is the one to schedule. Example hourly `cron` entry — note the absolute path, since `cron`
does not load your shell config:

```cron
# crontab -e — hourly, silent, appended to the monthly CSV.
# The backslashes before % are required: cron treats a bare % as a newline.
0 * * * * PATH="$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin" cloudflare-speed-cli --silent --export-csv "$HOME/.local/state/cloudflare-speed-cli/history-$(date +\%Y\%m).csv"
```

The directory must exist first — run `speed-log` once by hand, or `mkdir -p` it.

---

## 7. Per-machine overrides

The defaults live in a tracked, stowed file — do not edit it for one machine. Override in
`~/.config/zsh/local.zsh`, which is git-ignored and sourced last:

```zsh
# ~/.config/zsh/local.zsh — laptop on a metered connection
SPEEDTEST_DOWNLOAD_DURATION=5s
SPEEDTEST_UPLOAD_DURATION=5s
SPEEDTEST_CONCURRENCY=4
```

The same variables work as one-shot environment overrides:

```bash
SPEEDTEST_CONCURRENCY=12 speed
```

If the name `speed` clashes with something of your own, define your preferred alias in `local.zsh`;
it is sourced after this layer and wins.

---

## 8. Rollback

Remove the shell integration:

⚠️  MANUAL STEP — review before running; this discards repository changes

```bash
# Repository side — drop the layer and its source line
git checkout -- stow/common/zsh/.config/zsh/index.zsh
rm -f stow/common/zsh/.config/zsh/speedtest.zsh
```

Then re-stow (dry-run first) to drop the now-dangling symlink:

⚠️  MANUAL STEP — run only after reviewing the dry-run output

```bash
stow --dir=stow/common --target="$HOME" --no-folding --restow zsh
```

Uninstall the tool itself:

⚠️  MANUAL STEP — review before running

```bash
# macOS
brew uninstall cloudflare-speed-cli

# Arch
sudo pacman -Rs cloudflare-speed-cli

# Debian (cargo install)
cargo uninstall cloudflare-speed-cli
```

The CSV history is yours and is never removed automatically. Delete it by hand if you want it gone:

⚠️  MANUAL STEP — review before running; this deletes your saved history

```bash
rm -rf "${XDG_STATE_HOME:-$HOME/.local/state}/cloudflare-speed-cli"
```

---

## 9. Troubleshooting

### `speed: command not found`

The guard skipped the layer. Check, in order:

```bash
command -v cloudflare-speed-cli     # binary on PATH?
ls -l ~/.config/zsh/speedtest.zsh   # symlink present? (re-stow if not)
grep -n speedtest ~/.config/zsh/index.zsh
```

### `error: unexpected argument '--…' found`

Upstream renamed or dropped a flag. Compare the wrapper against your installed version:

```bash
cloudflare-speed-cli --help
```

Adjust `stow/common/zsh/.config/zsh/speedtest.zsh` to match, and note the version in the commit.

### Results look far below your line rate

Try a longer sample and more streams before blaming the ISP:

```bash
SPEEDTEST_DOWNLOAD_DURATION=30s SPEEDTEST_CONCURRENCY=12 speed
```

Wi-Fi, VPNs, and proxies all cap the result. `speed --traceroute` shows the path actually taken.

---

## 10. Expected final layout

```
Repository
  stow/common/zsh/.config/zsh/speedtest.zsh
  stow/common/zsh/.config/zsh/index.zsh          # sources it at slot 6e

Home (after stow)
  ~/.config/zsh/speedtest.zsh                    # symlink into the repository
  ~/.config/zsh/local.zsh                        # optional overrides, untracked

State (created by speed-log only)
  ~/.local/state/cloudflare-speed-cli/history-YYYYMM.csv
```
