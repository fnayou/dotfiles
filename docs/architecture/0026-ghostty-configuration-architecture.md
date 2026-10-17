# Architecture: Ghostty Configuration Architecture

**Number:** 0026
**Status:** Approved
**Date:** 2026-10-17
**Amended:** 2026-10-17 — Decision 12 and review 0080 fixes, at operator request; review 0081 fixes; Decision 11 withdrawn (custom icon not rendered on macOS 27)
**PRD:** [0028-ghostty-configuration](../prd/0028-ghostty-configuration.md)

---

## Context

PRD 0028 (Approved) adds a managed Ghostty configuration as a new Stow package,
`stow/common/ghostty/`, that mirrors the Alacritty package (`stow/common/alacritty/`, PRD 0011,
architecture 0011). Ghostty 1.3.1 is installed on macOS at `/Applications/Ghostty.app`; the binary
is not on `PATH` there.

PRD 0028 was amended on 2026-10-17 with Decision 11: a custom macOS app icon, shipped in a second,
macOS-only package, `stow/macos/ghostty/`. It is the first package under `stow/macos/`. Decision 11
was withdrawn on 2026-10-17: the custom icon is not rendered on macOS 27 (PRD 0028 Decision 11).
The macOS package stays and holds `macos.ghostty` only.

PRD 0028 was amended again on 2026-10-17 with Decision 12, after review 0080: the macOS-only options
leave the common config and move to `macos.ghostty` in the macOS package, loaded by the optional
include `config-file = ?macos.ghostty` at the end of the common `config.ghostty`. This amendment
also fixes the review 0080 findings.

The PRD already fixed every product decision. This architecture does **not** re-open them. It turns
them into structure:

- the exact package file trees and file inventory for both packages;
- the full intended content of `config.ghostty`, `themes/catppuccin-macchiato`, and
  `macos.ghostty`;
- the `.stow-local-ignore` and `README.md` of both packages;
- the human setup guide `docs/guides/ghostty-setup.md` (ADR 0028);
- the status-block updates (`.claude/rules/status-sync.md`);
- the documentation and website pages that mention Alacritty and need a Ghostty mention, and every
  statement that becomes false once `stow/macos/` is populated;
- the read-only validation strategy the plan will use.

### Decisions inherited from PRD 0028 (not re-opened)

| PRD decision | Fixed outcome |
|---|---|
| 1. Package location | One common package, `stow/common/ghostty/`; macOS and Arch; not on Debian. The common file has no `macos-*` option (Decision 12) |
| 2. Config file name | `config.ghostty` (not the legacy `config`) |
| 3. Application Support file | `~/Library/Application Support/com.mitchellh.ghostty/config.ghostty` left untouched |
| 4. Theme | Repo-managed `themes/catppuccin-macchiato`, loaded with `theme = catppuccin-macchiato` |
| 5. Font | `JetBrainsMono Nerd Font` committed as-is; no install step |
| 6. `TERM` | `term = xterm-256color` |
| 7. Shell | `command = /bin/zsh -l` |
| 8. Scrollback | `scrollback-limit` not set (Ghostty default, bytes) |
| 9. Numpad bindings | Not ported; verified during Build; a line is added only for a key that misbehaves |
| 10. Shell integration | Ghostty default kept; `shell-integration*` not set |
| 11. Custom macOS icon | **Withdrawn** 2026-10-17: not rendered on macOS 27 with Ghostty 1.3.1; no icon file and no `macos-icon` line ship |
| 12. macOS-only options | `macos-option-as-alt = true` in `stow/macos/ghostty/.config/ghostty/macos.ghostty`; the common `config.ghostty` ends with `config-file = ?macos.ghostty` (optional, so Arch skips it) |
| Stow | `--no-folding` for both packages, manual dry-run then manual install |

Out of scope for this architecture (per PRD 0028):

- Installing Ghostty or JetBrainsMono Nerd Font on any platform.
- Installing or stowing Ghostty on Debian servers.
- Creating symlinks in `$HOME` or running a Stow install.
- Editing, moving, or deleting the macOS Application Support `config.ghostty` file.
- Changing the Alacritty package or the Catppuccin Macchiato palette.
- Ghostty-only features (splits, tabs, quick terminal, extra keybinds).
- Modifying the signed `/Applications/Ghostty.app` bundle.
- A custom Ghostty Dock icon (PRD Decision 11 withdrawn).

---

## Proposed Structure

### Directory layout

```
stow/
├── common/
│   └── ghostty/
│       ├── .stow-local-ignore
│       ├── README.md
│       └── .config/
│           └── ghostty/
│               ├── config.ghostty
│               └── themes/
│                   └── catppuccin-macchiato
└── macos/
    └── ghostty/
        ├── .stow-local-ignore
        ├── README.md
        └── .config/
            └── ghostty/
                └── macos.ghostty
```

`stow/macos/ghostty/` holds only the macOS-only options file (PRD Decision 12). No
`stow/arch/ghostty/` package is
created (PRD Decision 1). Both packages are named `ghostty`; Stow tells them apart by `--dir`.

### File inventory

| File | Type | Stowed? | Maps to |
|---|---|---|---|
| `stow/common/ghostty/.config/ghostty/config.ghostty` | Real managed config | Yes | `~/.config/ghostty/config.ghostty` |
| `stow/common/ghostty/.config/ghostty/themes/catppuccin-macchiato` | Real managed theme | Yes | `~/.config/ghostty/themes/catppuccin-macchiato` |
| `stow/common/ghostty/.stow-local-ignore` | Stow ignore list | No (ignored) | — |
| `stow/common/ghostty/README.md` | Package README | No (ignored) | — |
| `stow/macos/ghostty/.config/ghostty/macos.ghostty` | Real managed config (macOS-only options) | Yes, macOS only | `~/.config/ghostty/macos.ghostty` |
| `stow/macos/ghostty/.stow-local-ignore` | Stow ignore list | No (ignored) | — |
| `stow/macos/ghostty/README.md` | Package README | No (ignored) | — |

All three config files are committed and stowed directly. No `.example` step: the content is personal
display and key preferences, mirrored from the already committed Alacritty package, with no secrets
(same policy as architecture 0011, Decision 2).

### Other files the Build creates or modifies

| File | Change | Rule |
|---|---|---|
| `docs/guides/ghostty-setup.md` | Created | ADR 0028 |
| `AGENTS.md` (§1 bullet, §2 block) | Modified | `.claude/rules/status-sync.md` |
| `CLAUDE.md` (status block) | Modified | `.claude/rules/status-sync.md` |
| `README.md` (package table row, per-package guide link, status lines) | Modified | Package table lists every `stow/common/` package; the ghostty row names the macOS package (`macos.ghostty`) |
| `README.md:15-16` (configs are version-controlled "in `stow/common/`") | Modified | Name `stow/macos/` too: "in `stow/common/` and `stow/macos/`" |
| `README.md:24` (`Managed packages: see stow/common/`) | Modified | ADR 0048: the pointer names `stow/macos/` once it is populated: `see stow/common/ and stow/macos/` |
| `README.md:28-29` (`stow/common/` is the source of truth … All common packages are stowed …) | Modified | ADR 0048: "`stow/common/` and `stow/macos/` are the source of truth for which packages exist. All common packages except `ghostty` are stowed: live symlinks point from `$HOME` into the repo. `ghostty` and the macOS-only `stow/macos/ghostty` are added, not yet stowed." |
| `README.md:33-34` (`stow/macos/`, `stow/arch/`, and `stow/debian/` … are currently empty) | Modified | `stow/macos/` now holds `ghostty`; only `stow/arch/` and `stow/debian/` stay empty |
| `README.md:105` (`macos/          macOS-specific packages (empty)`) | Modified | Drop `(empty)` for `macos/`; `arch/` and `debian/` keep it |
| `docs/stow-usage.md` and website pages | Modified | See "Documentation and Website Mentions", including the `stow/macos/`-is-empty statements |

The status blocks must be updated in the **same commit** that adds `stow/common/ghostty/` and
`stow/macos/ghostty/`. Both packages are added in that one commit.

### Symlink model (after a manual stow)

```
~/.config/ghostty/                         real directory (--no-folding)
├── config.ghostty
│     → <repo>/stow/common/ghostty/.config/ghostty/config.ghostty
├── macos.ghostty                          macOS only
│     → <repo>/stow/macos/ghostty/.config/ghostty/macos.ghostty
└── themes/                                real directory (--no-folding)
    └── catppuccin-macchiato
          → <repo>/stow/common/ghostty/.config/ghostty/themes/catppuccin-macchiato
```

`~/.config/ghostty` does not exist on the macOS machine today, so no conflict is expected. The dry
run must still confirm this. Both packages link files into the same real directory; neither owns
it. On Arch only the common package is stowed, so `macos.ghostty` is absent
there, and the optional include `config-file = ?macos.ghostty` is skipped. Ghostty searches
`~/.config/ghostty/themes/` first for a non-absolute theme name, so `theme = catppuccin-macchiato`
resolves to the stowed file with no home path in the config.

Verified (Ghostty 1.3.1, macOS, `XDG_CONFIG_HOME` pointed at a temporary directory): the relative
include resolves against the directory of the including file as seen at `~/.config/ghostty`, also
when `config.ghostty` and `macos.ghostty` are symlinks into two different package directories, as
in this model. The included options loaded.

---

## File Content

### `config.ghostty`

Full intended content. Values come from the PRD mapping table and Configuration Summary. Ghostty
comments must sit on their own line (`#` at line start); no trailing comments are used.

```
# Ghostty configuration
# Mirrors stow/common/alacritty/.config/alacritty/alacritty.toml.
# Mapping and portability decisions: docs/prd/0028-ghostty-configuration.md

# Theme: repo-managed file at ~/.config/ghostty/themes/catppuccin-macchiato (ADR 0068)
theme = catppuccin-macchiato

# Terminal type: matches Alacritty; avoids missing xterm-ghostty terminfo over SSH
term = xterm-256color

# Window
window-padding-x = 12
window-padding-y = 12
window-padding-balance = true
background-opacity = 0.98

# Scrolling
# scrollback-limit is not set: Ghostty limits scrollback in bytes, not lines (PRD 0028 Decision 8)
mouse-scroll-multiplier = 3

# Font
font-size = 13
font-family = "JetBrainsMono Nerd Font"
font-style = "Regular"
font-family-bold = "JetBrainsMono Nerd Font"
font-style-bold = "Bold"
font-family-italic = "JetBrainsMono Nerd Font"
font-style-italic = "Italic"
font-family-bold-italic = "JetBrainsMono Nerd Font"
font-style-bold-italic = "Bold Italic"

# Approximates Alacritty font.offset.y = 1
adjust-cell-height = 1

# Shell: login zsh. Shell integration stays at Ghostty's default (PRD 0028 Decision 10)
command = /bin/zsh -l

# Key bindings mirrored from Alacritty
# Option+N and Option+Shift+L no longer compose characters once Option is Alt
keybind = alt+n=text:~
keybind = alt+shift+l=text:|
# Word navigation; already a Ghostty default on macOS, set explicitly so Arch matches
keybind = alt+arrow_left=esc:b
keybind = alt+arrow_right=esc:f
# Shift+Enter sends a literal LF, as in Alacritty
keybind = shift+enter=text:\n

# macOS-only settings from stow/macos/ghostty; optional, so Arch skips it
config-file = ?macos.ghostty
```

**Verified (Ghostty 1.3.1, macOS, `XDG_CONFIG_HOME` pointed at a temporary directory):** this
content, with `themes/catppuccin-macchiato` below, passes `+validate-config` (exit 0). Loaded as
written: `window-padding-x` / `window-padding-y` `12`, `window-padding-balance`,
`background-opacity` `0.98`, `adjust-cell-height` `1`, the `font-family*` options, and the
keybinds `alt+n`, `alt+shift+l`, `alt+arrow_left=esc:b`, `alt+arrow_right=esc:f`, and
`shift+enter=text:\n`. `+show-config` reports `mouse-scroll-multiplier = 3` as
`precision:3,discrete:3`. With `macos.ghostty` absent, `config-file = ?macos.ghostty` gives exit 0
and no message; without the `?`, the same case exits 1 with
`error opening config-file ...: error.FileNotFound`.

**Not in the file, by decision:**

- No numpad `keybind` lines (PRD Decision 9). If the Build verification finds a numpad key whose
  output differs from its literal character, its `keybind = numpad_<key>=text:<char>` line goes at
  the end of the key-binding block, before the final `config-file` line, under a comment that cites PRD 0028 Decision 9. The result is
  recorded in the implementation review either way.
- No `scrollback-limit` (Decision 8).
- No `shell-integration` or `shell-integration-features` (Decision 10).
- No `maximize` / `fullscreen` (`startup_mode = Windowed` equals Ghostty's defaults).
- No `window-decoration` (Alacritty's `decorations` line is commented out).
- No `macos-*` option (PRD Decision 12): they live in `macos.ghostty`.
- No `config-file` include other than the optional `?macos.ghostty`, and no absolute path anywhere.

### `stow/macos/ghostty/.config/ghostty/macos.ghostty`

Full intended content (PRD Decision 12). Comments sit on their own line.

```
# Ghostty macOS-only settings
# Loaded by config-file = ?macos.ghostty at the end of the common config.ghostty.
# PRD 0028 Decision 12

# Both Option keys act as Alt (Alacritty option_as_alt = "Both")
macos-option-as-alt = true
```

Verified (Ghostty 1.3.1, macOS): with this file present, `macos-option-as-alt` loads.

### `themes/catppuccin-macchiato`

Full intended content. Every hex value is copied unchanged from
`stow/common/alacritty/.config/alacritty/catppuccin-macchiato.toml` (ADR 0068). Theme files use the
same `key = value` syntax as the main config; they cannot set `theme` or `config-file`.

```
# Catppuccin Macchiato — Ghostty theme
# Hex values identical to stow/common/alacritty/.config/alacritty/catppuccin-macchiato.toml (ADR 0068)

background = #24273a
foreground = #cad3f5

cursor-color = #f4dbd6
cursor-text = #24273a

selection-background = #f4dbd6
selection-foreground = #24273a

search-background = #a5adcb
search-foreground = #24273a
search-selected-background = #a6da95
search-selected-foreground = #24273a

# Normal colors: black, red, green, yellow, blue, magenta, cyan, white
palette = 0=#494d64
palette = 1=#ed8796
palette = 2=#a6da95
palette = 3=#eed49f
palette = 4=#8aadf4
palette = 5=#f5bde6
palette = 6=#8bd5ca
palette = 7=#b8c0e0

# Bright colors: black, red, green, yellow, blue, magenta, cyan, white
palette = 8=#5b6078
palette = 9=#ed8796
palette = 10=#a6da95
palette = 11=#eed49f
palette = 12=#8aadf4
palette = 13=#f5bde6
palette = 14=#8bd5ca
palette = 15=#a5adcb
```

Alacritty sections with no Ghostty equivalent are not represented: `vi_mode_cursor`, `hints.start`,
`hints.end`, `footer_bar`, `dim.*` (PRD "Settings with no Ghostty equivalent").

### `.stow-local-ignore`

Identical to `stow/common/alacritty/.stow-local-ignore`:

```
^/README\.md$
^/\.git$
^/\.gitignore$
^/\.stow-local-ignore$
^.*\.bak$
^.*\.orig$
```

A custom `.stow-local-ignore` replaces Stow's built-in default list, so the package keeps the same
explicit entries as Alacritty: the README and the ignore file itself never reach `$HOME`, and stray
`*.bak` / `*.orig` files never get linked.

### Package `README.md`

Mirrors `stow/common/alacritty/README.md`:

```markdown
# ghostty

Managed [Ghostty](https://ghostty.org/) terminal configuration. Stows into `~/.config/ghostty/`.

## What it configures

- Window, font, scrolling, key bindings, and shell, mirrored from the alacritty package.
- Catppuccin Macchiato color theme, loaded from a separate repo-managed theme file.

## Files

| File | Stowed to | Purpose |
|---|---|---|
| `.config/ghostty/config.ghostty` | `~/.config/ghostty/config.ghostty` | Main config — window, font, key bindings, shell, theme selection |
| `.config/ghostty/themes/catppuccin-macchiato` | `~/.config/ghostty/themes/catppuccin-macchiato` | Catppuccin Macchiato color theme |

## Setup

See [Ghostty Package Setup Guide](../../../docs/guides/ghostty-setup.md) for the full dry-run → install workflow.

On macOS, also stow `stow/macos/ghostty` for Option-as-Alt (see the setup guide).
```

### `stow/macos/ghostty/.stow-local-ignore`

Same entries as the common package's file:

```
^/README\.md$
^/\.git$
^/\.gitignore$
^/\.stow-local-ignore$
^.*\.bak$
^.*\.orig$
```

### `stow/macos/ghostty/README.md`

Full intended content (matches build commit `a6a6225`):

```markdown
# ghostty (macOS)

macOS-only settings for [Ghostty](https://ghostty.org/). Stows into `~/.config/ghostty/`, next to
the common `ghostty` package.

## What it configures

- Both Option keys act as Alt (`macos-option-as-alt = true`).

The common `config.ghostty` ends with `config-file = ?macos.ghostty`, an optional include: it loads
this package's `macos.ghostty` when it is linked and skips it otherwise.

Without this package, Ghostty on macOS still starts with the common config, but Option is not Alt.

No custom app icon is shipped: on macOS 27 with Ghostty 1.3.1, `macos-icon` (custom or built-in)
was read by Ghostty but not shown by the Dock (PRD 0028, Decision 11 withdrawn).

## Files

| File | Stowed to | Purpose |
|---|---|---|
| `.config/ghostty/macos.ghostty` | `~/.config/ghostty/macos.ghostty` | macOS-only options — Option as Alt |

## Setup

macOS only. Stow the common `ghostty` package first, then this one. Both use `--no-folding`.
See [Ghostty Package Setup Guide](../../../docs/guides/ghostty-setup.md) for the full dry-run →
install workflow. Quit Ghostty fully and start it again to apply the setting.
```

---

## Human Setup Guide: `docs/guides/ghostty-setup.md`

Required by ADR 0028: the package needs a manual Stow step, a post-Stow validation, a numpad check
(Decision 9), and has an unmanaged-file boundary (the macOS Application Support file). The guide
follows `docs/guides/alacritty-setup.md` and uses the ADR's ten sections in order:

1. **What this package manages** — the two common files and their symlink targets; Ghostty loads
   `~/.config/ghostty/config.ghostty` on start, and the theme by name from `themes/`. [macOS] The
   second package, `stow/macos/ghostty/`, links `macos.ghostty`; the common file's last line,
   `config-file = ?macos.ghostty`, loads `macos.ghostty`, which sets `macos-option-as-alt = true`.
2. **What it does NOT manage** — `~/Library/Application Support/com.mitchellh.ghostty/config.ghostty`
   [macOS] stays unmanaged and must stay empty; Ghostty's own state; fonts; the
   `/Applications/Ghostty.app` bundle (never modified); the app icon (no custom icon is shipped).
   Includes a platform-notes paragraph: the common file has no `macos-*` option; Arch stows only
   the common package, so the optional include is skipped there; on macOS with only the common
   package stowed, Option is not Alt (expected); Debian servers use neither package.
3. **Prerequisites** — per platform, each block with the marker on the line directly above its
   fence:

   ⚠️  MANUAL STEP — review before running
   ```bash
   # macOS
   brew install --cask ghostty
   brew install --cask font-jetbrains-mono-nerd-font
   ```

   ⚠️  MANUAL STEP — review before running
   ```bash
   # Arch
   sudo pacman -S ghostty ttf-jetbrains-mono-nerd
   ```

   Version check uses the full macOS path
   (`/Applications/Ghostty.app/Contents/MacOS/ghostty --version`) and plain `ghostty` on Arch.
4. **Dry-run step** — `stow -v --dir=stow/common --target="$HOME" --simulate --no-folding ghostty`;
   `-v` makes Stow print the `LINK:` lines (verify in Build); expect two `LINK:` lines
   (`.config/ghostty/config.ghostty`, `.config/ghostty/themes/catppuccin-macchiato`), no conflict
   lines, exit code 0. Then, [macOS] only,
   `stow -v --dir=stow/macos --target="$HOME" --simulate --no-folding ghostty`; expect one `LINK:`
   line (`.config/ghostty/macos.ghostty`), no conflict lines, exit code 0.
5. **Apply step (Stow)** — the common install command under `⚠️  MANUAL STEP — review before
   running` on the line directly above its fence; then, [macOS] only,
   `stow --dir=stow/macos --target="$HOME" --no-folding ghostty` under its own marker, placed the
   same way; why `--no-folding` is required for both (two packages share
   `~/.config/ghostty/`); `stow --adopt` is forbidden because it silently overwrites files without
   a backup.
6. **Manual activation steps** — quit and restart Ghostty fully (opacity changes need a full
   restart on macOS); [macOS] check that Option acts as Alt (Option+N types `~`); then the numpad
   check from PRD Decision 9
   (`cat -v`, then again after `tput smkx`), and what to do if a key misbehaves (change the repo,
   not the Application Support file).
7. **Validation steps** — real-directory checks for `~/.config/ghostty` and `themes/`; `readlink`
   on both common symlinks and, [macOS], on `~/.config/ghostty/macos.ghostty`; `+validate-config`
   with the platform binary; visual check of the theme.
8. **Rollback steps** — [macOS] `stow --dir=stow/macos --target="$HOME" --delete ghostty` first,
   then `stow --dir=stow/common --target="$HOME" --delete ghostty`, each under
   `⚠️  MANUAL STEP — review before running` on the line directly above its fence; Ghostty falls back to its defaults after a
   full restart. Removing only the macOS package leaves the common
   config working: the optional include is skipped.
9. **Troubleshooting** — Stow conflict on an existing file; folded directory; theme not applied
   (bundled `Catppuccin Macchiato` vs repo `catppuccin-macchiato`, missing `themes/` symlink);
   settings overridden by a non-empty Application Support file; `xterm-ghostty` vs `xterm-256color`
   over SSH; font fallback; [macOS] Option not acting as Alt (Ghostty not fully restarted, macOS
   package not stowed, or `macos.ghostty` not linked); [macOS] a custom Dock icon is not supported
   on macOS 27 with Ghostty 1.3.1: `macos-icon` (custom or built-in) is read by Ghostty but the Dock
   keeps the official icon (PRD 0028 Decision 11, withdrawn).
10. **Expected final file layout** — the symlink model above, with `/path/to/dotfiles` placeholders.

The guide contains no real paths, names, or hostnames; examples use placeholders.

---

## Status-Block Updates

Both packages, `stow/common/ghostty/` and `stow/macos/ghostty/`, are **added** in the Build commit
but **not stowed** (PRD: no Stow install during implementation). Today both blocks say every
`stow/common/` package is stowed and that `macos/` is empty; both statements would become false.
The Build commit changes them: `stow/macos/` is no longer empty, and both `ghostty` packages are
named as added but not yet stowed, in prose, without a per-package list beyond that exception.

`AGENTS.md` §2:

```
Current status:          Claude Code operating layer complete; common packages stowed (both ghostty packages pending).
Dotfiles implementation: stowed — all stow/common/ packages symlinked into $HOME except ghostty.
GNU Stow packages:       see stow/common/ and stow/macos/ (source of truth; arch/, debian/ empty).
Stowed to $HOME:         all stow/common/ packages except ghostty; stow/macos/ghostty not stowed either (both added, not yet stowed) — live symlinks into the repo.
Home directory:          modified by these symlinks; further modifications forbidden unless explicitly requested.
```

`AGENTS.md` §1 bullet:

```
- Dotfiles are **stowed** — all `stow/common/` packages except `ghostty` are symlinked into `$HOME`; `ghostty` and the macOS-only `stow/macos/ghostty` are added, not yet stowed.
```

`CLAUDE.md` bullets (the first replaces the "GNU Stow packages live under" bullet, the second the
"All `stow/common/` packages are stowed" bullet):

```
- GNU Stow packages live under `stow/common/` and `stow/macos/` (source of truth; `arch/`, `debian/` empty). Real config, plus some `.example` templates for local-only files.
- All `stow/common/` packages except `ghostty` are stowed to `$HOME` (live symlinks into the repo), including `codex`, whose `.stow-local-ignore` keeps `config.toml` unlinked; that template is propagated with `task codex:sync` instead. `ghostty` is added but not yet stowed, and so is the macOS-only `stow/macos/ghostty` (manual step: `docs/guides/ghostty-setup.md`). Home directory is modified by the existing symlinks. `stow/common/` and `stow/macos/` remain the source of truth for which packages exist.
```

`README.md` status lines (`Home directory: stowed — all common packages linked` and the first
Safety bullet) get the same "except ghostty" wording, and so does the source-of-truth paragraph
(`README.md:28-29`), which also names `stow/macos/` as a source of truth (ADR 0048). The other
`README.md` statements that become false once `stow/macos/` is populated (`:15-16`, `:24`,
`:33-34`, `:105`) are listed in "Other files the Build
creates or modifies" and in "Documentation and Website Mentions".

When the operator first stows the `ghostty` packages, that is a "first stowed" event: a later commit
removes the exception from all blocks again, per `.claude/rules/status-sync.md`. If the operator
stows the common package and the macOS package in separate sessions, each first stow gets its own
status update.

---

## Documentation and Website Mentions

Every page under `website/` (the MkDocs `docs_dir`, all pages from the `mkdocs.yml` nav) and
`docs/stow-usage.md` that mentions Alacritty, with the decision:

| Path | Ghostty mention? | Reason |
|---|---|---|
| `website/index.md` | Yes | Feature overview "Terminal" row lists Alacritty |
| `website/philosophy.md` | No | "git without alacritty" is an example sentence, not a package list |
| `website/features/index.md` | Yes | "Terminal" row and the Catppuccin Macchiato tool list |
| `website/features/terminal.md` | Yes | Gets a Ghostty section next to Alacritty, with dry-run and install |
| `website/features/packages.md` | Yes | Codex note says "Alacritty owns terminal colors"; Ghostty does too |
| `website/usage/daily-workflow.md` | Yes | "Alacritty starts with zsh"; Ghostty starts the same login zsh |
| `website/reference/stow.md` | Yes | Package tree (add `ghostty/` under `common/` and under `macos/`), the `--no-folding` package list, and the "Platform directories are not packages" note (`stow/macos/` now holds a real package) |
| `website/reference/supported-systems.md:31` | Yes | Portability row "Alacritty, bat, eza, btop, Neovim themes". When Ghostty joins the row, state that the Ghostty common file has no macOS-only lines (PRD Decision 12), next to "some Alacritty lines are macOS-only but harmless on Linux" |
| `website/reference/troubleshooting.md` | Yes | `--no-folding` package list |
| `docs/stow-usage.md` | Yes | Package tree (add `ghostty/` under `common/` and under `macos/`), `--no-folding` package list, the "Platform directories are not packages" section (`stow/macos/` is no longer only a `.gitkeep`; example `task dry-run AREA=macos PACKAGE=ghostty`), and a new "Installing the ghostty package" section after the alacritty one that covers both packages |

### Statements made false by a populated `stow/macos/`

Adding `stow/macos/ghostty/` makes every "`stow/macos/` is empty" statement false, whether or not the
page mentions Alacritty. Found by reading `README.md`, `AGENTS.md`, `CLAUDE.md`,
`docs/stow-usage.md`, and the `website/` pages listed in the `mkdocs.yml` nav for `empty` (and
"only `.gitkeep`") near `macos`, and for statements that name `stow/common/` alone as where packages
are defined or stowed ("source of truth", "defines which packages exist", "in `stow/common/`",
"All common packages are stowed"):

| Path | Statement | Change |
|---|---|---|
| `README.md:15-16` | "Configs are version-controlled in `stow/common/`" | Name `stow/macos/` too |
| `README.md:24` | `Managed packages:               see stow/common/` | Name `stow/macos/` too (ADR 0048) |
| `README.md:28-29` | "`stow/common/` is the source of truth for which packages exist. All common packages are stowed: live symlinks point from `$HOME` into the repo." | Name `stow/macos/` as a source of truth too (ADR 0048); "All common packages except `ghostty` are stowed"; `ghostty` and `stow/macos/ghostty` are added, not yet stowed |
| `README.md:33-34` | "`stow/macos/`, `stow/arch/`, and `stow/debian/` are reserved for platform-specific packages and are currently empty" | `stow/macos/` holds `ghostty`; only `stow/arch/` and `stow/debian/` are empty |
| `README.md:105` | `macos/          macOS-specific packages (empty)` | Drop `(empty)` for `macos/` |
| `website/getting-started.md:25` | `macos/      # macOS-specific packages (currently empty)` | Drop "currently empty" |
| `website/installation.md:19` | `macos/      # macOS-only packages (currently empty)` | Drop "currently empty" |
| `website/reference/repository-structure.md:14` | `│   ├── macos/         # macOS-specific (currently empty)` | Drop "currently empty" |
| `website/reference/repository-structure.md:41-42` | "The `stow/common/` directory defines which packages exist" | Name `stow/macos/` too: "`stow/common/` and `stow/macos/` define which packages exist" (ADR 0048, as for `README.md:24`) |
| `website/reference/repository-structure.md:42-44` | "`stow/macos/`, `stow/arch/`, and `stow/debian/` are reserved for platform-specific packages and are currently empty" | `stow/macos/` holds `ghostty`; only `stow/arch/` and `stow/debian/` are empty |
| `website/reference/stow.md:37` | "`stow/macos/`, `stow/arch/`, and `stow/debian/` currently contain only `.gitkeep` markers" | Already in the table above (the "Platform directories are not packages" note) |
| `docs/stow-usage.md:33` | "`stow/macos/`, `stow/arch/`, and `stow/debian/` currently contain only `.gitkeep` marker files" | Already in the table above (the "Platform directories are not packages" section) |
| `AGENTS.md` §2 (`:27`) | `GNU Stow packages:       see stow/common/ (source of truth; macos/, arch/, debian/ empty).` | Covered in "Status-Block Updates" |
| `CLAUDE.md` status block | "`macos/`, `arch/`, `debian/` empty" | Covered in "Status-Block Updates" |

The README rows are also in "Other files the Build creates or modifies". The website rows are part of
the same plan task as the Alacritty mentions above.

These edits are a separate plan task. They describe Ghostty as available alongside Alacritty; they do
not claim it is stowed. The `stow/macos/` mentions state that `stow/macos/ghostty/` is macOS-only
and holds only the macOS-only options file, `macos.ghostty`.

---

## Design Decisions

### Decision 1: Package layout — mirror the Alacritty package

**Option A: Mirror `stow/common/alacritty/`** (README, `.stow-local-ignore`, files under
`.config/<tool>/`)

Pro: One familiar shape; reviewers compare the two packages line by line.
Pro: The ignore list keeps README and helper files out of `$HOME`.
Con: Two near-duplicate ignore files to maintain.

**Option B: Minimal package (config files only, no README or ignore file)**

Pro: Fewer files.
Con: Breaks the repo rule that every package carries a README.
Con: Without `.stow-local-ignore`, nothing stops a later README from being linked into `$HOME`.

**Decision:** Option A.

---

### Decision 2: Theme file in a `themes/` subdirectory, stowed with `--no-folding`

**Option A: `--no-folding`** (PRD)

Pro: `~/.config/ghostty/` and `~/.config/ghostty/themes/` stay real directories; files Ghostty or the
user create there do not land in the repository.
Con: Two directories and two symlinks to manage instead of one folded link.

**Option B: Default folding**

Pro: One symlink.
Con: `~/.config/ghostty` becomes a link into the repo; anything written there is written into the
working tree.

**Decision:** Option A, as fixed by the PRD. The guide and validation both check that neither
directory is a symlink.

---

### Decision 3: Comments and grouping in `config.ghostty`

**Option A: Group by Alacritty section, comment on own lines, cite the PRD where a value differs**

Pro: A reader maps each block back to `alacritty.toml` and to the PRD row.
Pro: Ghostty does not support trailing comments, so own-line comments are the only safe form.
Con: Slightly longer file.

**Option B: Bare option list, no comments**

Pro: Shortest file.
Con: Omitted options (scrollback, shell integration, numpad) look like oversights.

**Decision:** Option A.

---

### Decision 4: Validation entry point — `+validate-config` on the repo file

**Option A: `+validate-config --config-file=<repo file>`**

Pro: Read-only; checks syntax and option names of the exact committed file; runs before any stow.
Con: Theme lookup searches `~/.config/ghostty/themes/`, which does not exist before stowing, so a
theme-not-found message is possible and must be read in context.

**Option B: Only check after the real stow**

Con: Errors surface only after `$HOME` is touched.

**Decision:** Option A as the plan's primary check, plus the theme file validated on its own and a
fake-home check with `XDG_CONFIG_HOME` that resolves the theme by name without touching `$HOME`. See
Validation Strategy.

---

### Decision 5: Status blocks name the not-yet-stowed exception

**Option A: Add an "except ghostty" clause in prose**

Pro: Blocks stay true without a per-package list (`.claude/rules/status-sync.md` forbids one).
Con: A follow-up commit is needed after the first stow.

**Option B: Leave "all packages stowed" unchanged**

Con: The blocks become false, which the status-sync rule exists to prevent.

**Decision:** Option A.

---

### Decision 6: Icon location — **Withdrawn**

Withdrawn 2026-10-17 with PRD 0028 Decision 11. This decision placed `Ghostty.icns` in the
macOS-only package `stow/macos/ghostty/` rather than in `stow/common/ghostty/`. On macOS 27 with
Ghostty 1.3.1 no `macos-icon` value (custom or built-in) is rendered by the Dock, so the operator
dropped the custom icon: no icon file and no `macos-icon` line ship, and the macOS package holds
`macos.ghostty` only (Decision 7). The evidence is recorded in PRD 0028 Decision 11.

---

### Decision 7: macOS-only options — optional include vs keeping `macos-*` in common

**Option A: Optional include** (PRD Decision 12). The macOS package ships `macos.ghostty` with
`macos-option-as-alt = true`; the common `config.ghostty` ends with
`config-file = ?macos.ghostty`.

Pro: Satisfies `.claude/rules/cross-platform.md` exactly: "Do not mix OS-specific settings into
common/shared config files". The common file holds no `macos-*` line.
Pro: Verified on Ghostty 1.3.1: with the file absent, the `?` include is skipped with exit 0 and no
message; with it present, its options load, also through two symlinks into different package
directories.
Con: On macOS, Option-as-Alt now depends on stowing the second package; with only the common
package stowed, Option is not Alt (documented).
Con: One more file in the macOS package, and a `config-file` line in the common file.

**Option B: Keep `macos-*` in the common `config.ghostty`** (the Alacritty `option_as_alt`
precedent)

Pro: One file holds every option; Option-as-Alt works on macOS with only the common package.
Pro: Ghostty ignores `macos-*` options on Linux.
Con: A documented departure from the cross-platform rule.

**Decision:** Option A, chosen by the operator after review 0080 (suggestion 2).

---

## Validation Strategy

Checks 1 to 6 are read-only for `$HOME` and safe to run during implementation. Check 3 writes only
into its own `mktemp -d` directory, outside the repository, so its blocks carry the
`⚠️  MANUAL STEP` marker. Check 7 is an operator-run step. The plan defines the exact invocations;
this section names them. Facts marked "verified" come from a sandbox run (Ghostty 1.3.1, macOS,
`XDG_CONFIG_HOME` pointed at a temporary directory); the commands below were not run while writing
this document.

### Verification status (review 0080, suggestion 6)

Verified in a sandbox run (Ghostty 1.3.1, macOS, `XDG_CONFIG_HOME` pointed at a temporary
directory):

- `config.ghostty` and `themes/catppuccin-macchiato`, as written in this document, pass
  `+validate-config` (exit 0). This covers the theme option names, including `cursor-text`,
  `selection-foreground`, `search-background`, `search-foreground`, `search-selected-background`,
  and `search-selected-foreground`.
- `theme = catppuccin-macchiato` resolves from `$XDG_CONFIG_HOME/ghostty/themes/`; the palette is
  applied (`0=#494d64` … `15=#a5adcb`).
- Loaded as written: `window-padding-x` / `window-padding-y` `12`, `window-padding-balance`,
  `background-opacity` `0.98`, `adjust-cell-height` `1`, the `font-family*` options, and the
  keybinds `alt+n`, `alt+shift+l`, `alt+arrow_left=esc:b`, `alt+arrow_right=esc:f`,
  `shift+enter=text:\n`. This covers the key names `arrow_left` and `enter` and the `text:\n`
  escape.
- `+show-config` reports `mouse-scroll-multiplier = 3` as `precision:3,discrete:3`.
- `config-file = ?macos.ghostty`: absent file, exit 0 and no message; present file, its options
  load; without `?` and absent, exit 1 with `error opening config-file ...: error.FileNotFound`.
  The relative include resolves against `~/.config/ghostty`, also through symlinks into two
  different package directories.

Not verified; the first three stay Build checks:

- `numpad_<key>` key names (PRD Decision 9, operator numpad check).
- Whether `command = /bin/zsh -l` runs through `/bin/sh -c` (guide activation step: start Ghostty
  and confirm a login zsh).
- The exact `+validate-config --config-file=` form, and whether it also loads the default config
  files (plan; checks 1 to 3).
- `faint-opacity`, `background-opacity-cells`, and `config-default-files` are cited from
  `ghostty +show-config --default --docs` only; the config does not set them, so no Build check
  depends on them.

Binary per platform:

```bash
# macOS
GHOSTTY=/Applications/Ghostty.app/Contents/MacOS/ghostty
```

```bash
# Arch
GHOSTTY=ghostty
```

### 1. Ghostty config validation (primary)

```bash
"$GHOSTTY" +validate-config \
  --config-file=stow/common/ghostty/.config/ghostty/config.ghostty
```

Expected: no errors. `macos.ghostty` does not sit next to the repo file, so the optional
`config-file = ?macos.ghostty` is skipped with no message (verified behaviour for an absent file).
A theme-not-found message for `catppuccin-macchiato` before any stow is expected and is settled by
check 3.

### 2. Theme file validation

```bash
"$GHOSTTY" +validate-config \
  --config-file=stow/common/ghostty/.config/ghostty/themes/catppuccin-macchiato
```

Expected: no errors (theme files use the same syntax).

### 3. Fake-home Stow simulation and theme resolution

Each block runs in a subshell `( set -eu; … )`. If `mktemp` or any later command fails, `set -e`
stops the subshell only; the operator's interactive shell stays open. `set -u` also refuses an
unset `$GHOSTTY`. `${FAKE_HOME:?}` makes the shell refuse an empty variable, so an empty value never
reaches `stow --target` or `rm`. A failure after `mktemp` can leave the temporary directory behind;
it is outside the repository and `$HOME`.

⚠️  MANUAL STEP — review before running
```bash
# Step 1 — conflict check
(
  set -eu
  FAKE_HOME="$(mktemp -d)"
  stow -v --dir=stow/common --target="${FAKE_HOME:?}" --simulate --no-folding ghostty \
    && echo "Simulation passed: no conflicts detected"
  rm -rf "${FAKE_HOME:?}"
)
```

⚠️  MANUAL STEP — review before running
```bash
# Step 2 — common package only (Arch case): link into a fake home, resolve the theme by name,
# check that the optional include is skipped, clean up
(
  set -eu
  FAKE_HOME="$(mktemp -d)"
  stow --dir=stow/common --target="${FAKE_HOME:?}" --no-folding ghostty
  test ! -L "${FAKE_HOME:?}/.config/ghostty" && test ! -L "${FAKE_HOME:?}/.config/ghostty/themes" \
    && echo "OK: real directories"
  XDG_CONFIG_HOME="${FAKE_HOME:?}/.config" "$GHOSTTY" +validate-config \
    --config-file="${FAKE_HOME:?}/.config/ghostty/config.ghostty"
  stow --dir=stow/common --target="${FAKE_HOME:?}" --delete ghostty
  rm -rf "${FAKE_HOME:?}"
)
```

Expected: two links, two real directories, `+validate-config` exit 0 with no message (verified: the
theme resolves from `$XDG_CONFIG_HOME/ghostty/themes/`, and the absent `macos.ghostty` is skipped).

⚠️  MANUAL STEP — review before running
```bash
# macOS
# Step 3 — both packages into one fake home
(
  set -eu
  FAKE_HOME="$(mktemp -d)"
  stow --dir=stow/common --target="${FAKE_HOME:?}" --no-folding ghostty
  stow -v --dir=stow/macos --target="${FAKE_HOME:?}" --simulate --no-folding ghostty \
    && echo "Simulation passed: no conflicts detected"
  stow --dir=stow/macos --target="${FAKE_HOME:?}" --no-folding ghostty
  test ! -L "${FAKE_HOME:?}/.config/ghostty" \
    && test -L "${FAKE_HOME:?}/.config/ghostty/macos.ghostty" \
    && echo "OK: macOS files linked into real directory"
  XDG_CONFIG_HOME="${FAKE_HOME:?}/.config" "$GHOSTTY" +validate-config \
    --config-file="${FAKE_HOME:?}/.config/ghostty/config.ghostty"
  stow --dir=stow/macos --target="${FAKE_HOME:?}" --delete ghostty
  stow --dir=stow/common --target="${FAKE_HOME:?}" --delete ghostty
  rm -rf "${FAKE_HOME:?}"
)
```

Expected: one extra link (`.config/ghostty/macos.ghostty`), `.config/ghostty` still a real
directory, no conflicts, `+validate-config` exit 0. Verified: the include resolves through the two
symlinks into different package directories, and `macos-option-as-alt` loads.

### 4. Palette parity with Alacritty

Every hex value in the theme file must appear in the Alacritty theme:

```bash
comm -23 \
  <(grep -oE '#[0-9a-f]{6}' stow/common/ghostty/.config/ghostty/themes/catppuccin-macchiato | sort -u) \
  <(grep -oE '#[0-9a-f]{6}' stow/common/alacritty/.config/alacritty/catppuccin-macchiato.toml | sort -u)
```

Expected: no output. The plan also compares each value to its PRD theme-mapping row.

### 5. Privacy and dependency audit

```bash
grep -rEi \
  'password|token|secret|api.?key|private.?key|BEGIN (RSA|OPENSSH|EC)|hostname\.' \
  stow/common/ghostty/
grep -rEi 'brew|pacman|curl|wget|npm|pip|cargo|apt' stow/common/ghostty/.config/
grep -rE '/Users/|/home/' stow/common/ghostty/
grep -rEi \
  'password|token|secret|api.?key|private.?key|BEGIN (RSA|OPENSSH|EC)|hostname\.|/Users/|/home/' \
  stow/macos/ghostty/README.md stow/macos/ghostty/.stow-local-ignore \
  stow/macos/ghostty/.config/ghostty/macos.ghostty
```

Expected: no matches.

### 6. macOS package integrity [macOS package]

```bash
diff stow/common/ghostty/.stow-local-ignore stow/macos/ghostty/.stow-local-ignore
grep -n '^macos-' stow/common/ghostty/.config/ghostty/config.ghostty
tail -n 1 stow/common/ghostty/.config/ghostty/config.ghostty
grep -n '^macos-option-as-alt = true$' stow/macos/ghostty/.config/ghostty/macos.ghostty
```

Expected:

- `diff` prints nothing.
- `grep '^macos-'` on the common file prints nothing (PRD Decision 12).
- `tail` prints `config-file = ?macos.ghostty`.
- The `macos.ghostty` grep prints one line.

### 7. Option as Alt [macOS, operator-run]

This check is run by the operator, not by an agent or the plan's scripts. Launching `Ghostty.app`
writes app state under `~/Library`, also when `XDG_CONFIG_HOME` is set, so this step does not claim
to leave `$HOME` untouched.

After the operator stows both packages (guide, Apply step), the operator quits Ghostty fully, starts
it again, and records in the implementation review whether Option+N types `~`.

---

## Manual Installation Reference

Not executed by any agent or script.

```bash
# Step 1 — dry run (safe, changes nothing; -v prints the LINK lines, verify in Build)
stow -v --dir=stow/common --target="$HOME" --simulate --no-folding ghostty
```

⚠️  MANUAL STEP — run only after reviewing dry-run output
```bash
# Step 2 — install
stow --dir=stow/common --target="$HOME" --no-folding ghostty
```

macOS only, after the common package:

```bash
# macOS
# Step 3 — dry run (safe, changes nothing; -v prints the LINK lines, verify in Build)
stow -v --dir=stow/macos --target="$HOME" --simulate --no-folding ghostty
```

⚠️  MANUAL STEP — run only after reviewing dry-run output
```bash
# macOS
# Step 4 — install
stow --dir=stow/macos --target="$HOME" --no-folding ghostty
```

Then quit Ghostty fully, start it again, and check that Option acts as Alt.

To unlink later:

⚠️  MANUAL STEP — review before running
```bash
# macOS only: remove the macOS package link (macos.ghostty) first
stow --dir=stow/macos --target="$HOME" --delete ghostty
stow --dir=stow/common --target="$HOME" --delete ghostty
```

---

## Cross-Platform Notes

### macOS

- Ghostty 1.3.1 is installed; the CLI binary is `/Applications/Ghostty.app/Contents/MacOS/ghostty`.
- The Application Support `config.ghostty` exists and is empty. Ghostty reads it in addition to the
  XDG file. It stays untouched and unmanaged; settings change only in the repository.
- `macos-option-as-alt = true` is active once the macOS package is stowed (it lives in
  `macos.ghostty`); the `alt+n` and `alt+shift+l` bindings restore `~` and `|`.
- `alt+arrow_left` / `alt+arrow_right` are already Ghostty defaults here; the explicit lines are
  harmless.
- `background-opacity` changes need a full Ghostty restart.
- `/bin/zsh` exists by default.
- With only the common package stowed, `config-file = ?macos.ghostty` is skipped: Option is not
  Alt. Expected, documented in the guide.

### Arch / EndeavourOS

- Install with `sudo pacman -S ghostty`; the binary is on `PATH`.
- The common file has no `macos-*` option. `stow/macos/ghostty` is not stowed, so
  `macos.ghostty` is not linked, and the optional `config-file = ?macos.ghostty` is skipped
  with no message (verified on macOS with the file absent; the same code path on Arch is checked by
  `+validate-config` in Build). The `alt+…` bindings apply to the Alt key.
- The explicit `alt+arrow_*` lines give word navigation that the Linux defaults do not.
- `/bin/zsh` resolves through `usr-merge` (as in architecture 0011, Decision 6).
- Font package: `ttf-jetbrains-mono-nerd`.
- `xterm-ghostty` terminfo ships with the package, but `term = xterm-256color` is used anyway.

### Debian

- Ghostty is not installed and neither package is stowed on Debian servers.
- Debian is still affected indirectly: `term = xterm-256color` means SSH sessions from Ghostty into
  Debian hosts find a terminfo entry that Debian already ships.
- Like `alacritty`, the package sits in `common/` though Debian does not use it; nothing in it
  breaks on Debian, and nothing installs it there.

---

## Risks

- **Application Support file layering [macOS].** If something writes settings into
  `~/Library/Application Support/com.mitchellh.ghostty/config.ghostty` (for example Ghostty's
  `open_config` action, `super+,`), those settings layer over the repo config. Mitigation: the guide
  states the file must stay empty and lists the symptom under Troubleshooting. The Build never
  touches it.
- **Bundled theme confusion.** `theme = Catppuccin Macchiato` (bundled) and
  `theme = catppuccin-macchiato` (repo) look alike. A typo silently selects the bundled palette or
  none. Mitigation: validation checks 1 to 3 and a visual check in the guide.
- **Theme lookup before stow.** Check 1 may report the theme missing because
  `~/.config/ghostty/themes/` does not exist yet. Mitigation: check 3 resolves it in a fake home.
- **Existing `~/.config/ghostty/` on another machine.** The dry run surfaces conflicts; resolution
  is manual; `--adopt` stays forbidden.
- **Visual differences that cannot be configured.** Scrollback is bytes not lines, trackpad scroll
  speed differs, and `adjust-cell-height` centers glyphs. These are accepted in the PRD; the guide
  lists them so they are not reported as bugs.
- **Numpad behavior unknown until Build.** Decision 9 verification may add lines on macOS only;
  Arch numpad behavior is not verified by the PRD. Mitigation: the review records the result.
- **`text:` escape parsing.** `shift+enter=text:\n` depends on Ghostty parsing `\n` as an escape.
  Check 1 catches a parse error; the guide includes a manual Shift+Enter test.
- **Status blocks drift.** Forgetting the "except ghostty" clause, or forgetting to remove it after
  the first stow, makes both blocks false. Mitigation: the status-sync self-check before commit.
- **Font fallback is silent.** Missing JetBrainsMono Nerd Font gives a system font with no error
  (accepted, as in architecture 0011).
- **Privacy audit false negatives.** The grep audit catches known patterns only; review of
  `git diff --staged` stays the primary control.
- **Only the common package stowed on macOS.** `config-file = ?macos.ghostty` is skipped, so Option
  is not Alt (Option+N and Option+Shift+L compose characters again). This is expected, not a failure. Mitigation: the guide and both READMEs document it and say to
  stow both packages on macOS.
- **Include without `?`.** A later edit that drops the `?` makes Ghostty fail on Arch, where
  `macos.ghostty` is absent: exit 1, `error opening config-file ...: error.FileNotFound` (verified).
  Mitigation: validation check 6 checks the exact last line; check 3 step 2 validates the
  common-only case.
- **macos-icon not rendered on macOS 27; feature withdrawn.**
- **Folding across two packages.** Stowing either package without `--no-folding` into an empty
  `~/.config/ghostty` could fold the directory into a link to one package and block the other.
  Mitigation: both commands carry `--no-folding`; validation check 3 step 3 stows both into one fake
  home.

---

## Extensibility

- **Numpad bindings:** added as single `keybind` lines at the end of the key-binding block if
  Decision 9 requires them; no structural change.
- **Platform overrides:** further macOS-only options go into `macos.ghostty`. A new
  `stow/arch/ghostty/` package could add its own file, loaded by another optional
  `config-file = ?<name>` line, if Arch-only settings appear. Not needed today.
- **More themes:** additional files under `themes/` need no structural change; switching is one
  `theme =` line.
- **Local overrides:** with `--no-folding`, machine-only files can sit in `~/.config/ghostty/` next to
  the managed links without entering the repository.

---

## Open Questions

None.

---

## Recommended Next Step

Forward to the Reviewer for safety, privacy, and cross-platform sign-off. On user approval, the
Planner writes an implementation plan with these tasks:

1. Create `stow/common/ghostty/` with `config.ghostty`, `themes/catppuccin-macchiato`,
   `.stow-local-ignore`, and `README.md`, exactly as specified above.
2. Create `stow/macos/ghostty/` with `.stow-local-ignore`, `README.md`, and
   `.config/ghostty/macos.ghostty` as specified above.
3. Run validation checks 1 to 6. Check 7 is the operator's (task 8).
4. Operator runs the numpad verification (PRD Decision 9); add lines only if needed; record the
   result in the implementation review.
5. Create `docs/guides/ghostty-setup.md`.
6. Update the `AGENTS.md` (§1, §2) and `CLAUDE.md` status blocks, and the `README.md` package table,
   guide link, status lines, the source-of-truth paragraph (`:28-29`, "except ghostty" wording,
   naming `stow/macos/` as a source of truth too, ADR 0048), and the `stow/macos/` statements
   (`:15-16`, `:24`, `:33-34`, `:105`), in the same commit that adds both packages.
7. Add Ghostty mentions to the documentation and website pages marked "Yes", and fix every
   statement listed under "Statements made false by a populated `stow/macos/`".
8. Leave stowing to the operator, following the guide; the operator runs validation check 7 and
   records the Option-as-Alt result in the implementation review.
