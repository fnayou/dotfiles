# Architecture: Ghostty Configuration Architecture

**Number:** 0026
**Status:** Approved
**Date:** 2026-10-17
**PRD:** [0028-ghostty-configuration](../prd/0028-ghostty-configuration.md)

---

## Context

PRD 0028 (Approved) adds a managed Ghostty configuration as a new Stow package,
`stow/common/ghostty/`, that mirrors the Alacritty package (`stow/common/alacritty/`, PRD 0011,
architecture 0011). Ghostty 1.3.1 is installed on macOS at `/Applications/Ghostty.app`; the binary
is not on `PATH` there.

PRD 0028 was amended on 2026-10-17 with Decision 11: a custom macOS app icon, shipped in a second,
macOS-only package, `stow/macos/ghostty/`. It is the first package under `stow/macos/`.

The PRD already fixed every product decision. This architecture does **not** re-open them. It turns
them into structure:

- the exact package file trees and file inventory for both packages;
- the full intended content of `config.ghostty` and `themes/catppuccin-macchiato`;
- the `.stow-local-ignore` and `README.md` of both packages;
- the human setup guide `docs/guides/ghostty-setup.md` (ADR 0028);
- the status-block updates (`.claude/rules/status-sync.md`);
- the documentation and website pages that mention Alacritty and need a Ghostty mention;
- the read-only validation strategy the plan will use.

### Decisions inherited from PRD 0028 (not re-opened)

| PRD decision | Fixed outcome |
|---|---|
| 1. Package location | One common package, `stow/common/ghostty/`; macOS and Arch; not on Debian. macOS-only options stay in the common file |
| 2. Config file name | `config.ghostty` (not the legacy `config`) |
| 3. Application Support file | `~/Library/Application Support/com.mitchellh.ghostty/config.ghostty` left untouched |
| 4. Theme | Repo-managed `themes/catppuccin-macchiato`, loaded with `theme = catppuccin-macchiato` |
| 5. Font | `JetBrainsMono Nerd Font` committed as-is; no install step |
| 6. `TERM` | `term = xterm-256color` |
| 7. Shell | `command = /bin/zsh -l` |
| 8. Scrollback | `scrollback-limit` not set (Ghostty default, bytes) |
| 9. Numpad bindings | Not ported; verified during Build; a line is added only for a key that misbehaves |
| 10. Shell integration | Ghostty default kept; `shell-integration*` not set |
| 11. Custom macOS icon | `macos-icon = custom` in the common file; `macos-custom-icon` not set (default `~/.config/ghostty/Ghostty.icns`); icon in `stow/macos/ghostty/.config/ghostty/Ghostty.icns`, copied from `~/Downloads/ghosty.icns` and renamed; SHA-256 `6796c0f423a066009fef4f69ab7800a086627304fc633d3cba69a4ca173632ac`; licence unknown, operator's responsibility |
| Stow | `--no-folding` for both packages, manual dry-run then manual install |

Out of scope for this architecture (per PRD 0028):

- Installing Ghostty or JetBrainsMono Nerd Font on any platform.
- Installing or stowing Ghostty on Debian servers.
- Creating symlinks in `$HOME` or running a Stow install.
- Editing, moving, or deleting the macOS Application Support `config.ghostty` file.
- Changing the Alacritty package or the Catppuccin Macchiato palette.
- Ghostty-only features (splits, tabs, quick terminal, extra keybinds), except the macOS icon.
- Modifying the signed `/Applications/Ghostty.app` bundle.
- The Finder icon, the update-dialog icon, and any Ghostty icon on Arch.

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
                └── Ghostty.icns
```

`stow/macos/ghostty/` holds only the icon (PRD Decision 11). No `stow/arch/ghostty/` package is
created (PRD Decision 1). Both packages are named `ghostty`; Stow tells them apart by `--dir`.

### File inventory

| File | Type | Stowed? | Maps to |
|---|---|---|---|
| `stow/common/ghostty/.config/ghostty/config.ghostty` | Real managed config | Yes | `~/.config/ghostty/config.ghostty` |
| `stow/common/ghostty/.config/ghostty/themes/catppuccin-macchiato` | Real managed theme | Yes | `~/.config/ghostty/themes/catppuccin-macchiato` |
| `stow/common/ghostty/.stow-local-ignore` | Stow ignore list | No (ignored) | — |
| `stow/common/ghostty/README.md` | Package README | No (ignored) | — |
| `stow/macos/ghostty/.config/ghostty/Ghostty.icns` | Binary icon (ICNS, 152344 bytes) | Yes, macOS only | `~/.config/ghostty/Ghostty.icns` |
| `stow/macos/ghostty/.stow-local-ignore` | Stow ignore list | No (ignored) | — |
| `stow/macos/ghostty/README.md` | Package README; records icon source and SHA-256 | No (ignored) | — |

Both config files are committed and stowed directly. No `.example` step: the content is personal
display and key preferences, mirrored from the already committed Alacritty package, with no secrets
(same policy as architecture 0011, Decision 2).

The icon is committed and stowed directly as well. The Build copies `~/Downloads/ghosty.icns`
(misspelled source name) to `stow/macos/ghostty/.config/ghostty/Ghostty.icns`. The file name
`Ghostty.icns` must match exactly, because `macos-custom-icon` is left at its default,
`~/.config/ghostty/Ghostty.icns`. Git does not carry the file's extended attributes (quarantine,
where-from).

### Other files the Build creates or modifies

| File | Change | Rule |
|---|---|---|
| `docs/guides/ghostty-setup.md` | Created | ADR 0028 |
| `AGENTS.md` (§1 bullet, §2 block) | Modified | `.claude/rules/status-sync.md` |
| `CLAUDE.md` (status block) | Modified | `.claude/rules/status-sync.md` |
| `README.md` (package table row, per-package guide link, status lines) | Modified | Package table lists every `stow/common/` package; the ghostty row names the macOS icon package |
| `docs/stow-usage.md` and website pages | Modified | See "Documentation and website mentions" |

The status blocks must be updated in the **same commit** that adds `stow/common/ghostty/` and
`stow/macos/ghostty/`. Both packages are added in that one commit.

### Symlink model (after a manual stow)

```
~/.config/ghostty/                         real directory (--no-folding)
├── config.ghostty
│     → <repo>/stow/common/ghostty/.config/ghostty/config.ghostty
├── Ghostty.icns                           macOS only
│     → <repo>/stow/macos/ghostty/.config/ghostty/Ghostty.icns
└── themes/                                real directory (--no-folding)
    └── catppuccin-macchiato
          → <repo>/stow/common/ghostty/.config/ghostty/themes/catppuccin-macchiato
```

`~/.config/ghostty` does not exist on the macOS machine today, so no conflict is expected. The dry
run must still confirm this. Both packages link files into the same real directory; neither owns
it. On Arch only the common package is stowed, so `Ghostty.icns` is absent there. Ghostty searches `~/.config/ghostty/themes/` first for a non-absolute
theme name, so `theme = catppuccin-macchiato` resolves to the stowed file with no home path in the
config.

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
# macOS only: Dock and app switcher icon from ~/.config/ghostty/Ghostty.icns (stow/macos/ghostty).
# Ignored on Linux. PRD 0028 Decision 11
macos-icon = custom

# macOS only: both Option keys act as Alt. Ignored on Linux.
macos-option-as-alt = true

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
```

**Not in the file, by decision:**

- No numpad `keybind` lines (PRD Decision 9). If the Build verification finds a numpad key whose
  output differs from its literal character, its `keybind = numpad_<key>=text:<char>` line goes at
  the end of the key-binding block, under a comment that cites PRD 0028 Decision 9. The result is
  recorded in the implementation review either way.
- No `scrollback-limit` (Decision 8).
- No `shell-integration` or `shell-integration-features` (Decision 10).
- No `maximize` / `fullscreen` (`startup_mode = Windowed` equals Ghostty's defaults).
- No `window-decoration` (Alacritty's `decorations` line is commented out).
- No `config-file` include and no absolute path anywhere.
- No `macos-custom-icon` (Decision 11): its default, `~/.config/ghostty/Ghostty.icns`, is the path
  the macOS package stows to.

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

Full intended content (outer fence uses four backticks because the README contains a code block):

````markdown
# ghostty (macOS)

Custom macOS app icon for [Ghostty](https://ghostty.org/). Stows into `~/.config/ghostty/`, next to
the common `ghostty` package.

## What it configures

- The Ghostty icon in the macOS Dock and app switcher.

The common `config.ghostty` sets `macos-icon = custom`. `macos-custom-icon` is not set: its default
is `~/.config/ghostty/Ghostty.icns`, which is where this package links the icon.

Not changed: the Finder icon (the app bundle is signed and is not modified) and the update dialog,
which always shows the official icon.

## Files

| File | Stowed to | Purpose |
|---|---|---|
| `.config/ghostty/Ghostty.icns` | `~/.config/ghostty/Ghostty.icns` | Custom app icon (ICNS) |

## Icon source

| Field | Value |
|---|---|
| Origin | macosicons.com — "Ghostty Darken" |
| Format | Mac OS X icon (ICNS) |
| Size | 152344 bytes |
| SHA-256 | `6796c0f423a066009fef4f69ab7800a086627304fc633d3cba69a4ca173632ac` |
| Licence | Unknown |

The licence of this icon is unknown. It is committed at the repository owner's choice;
redistribution rights are the owner's responsibility.

Check the file:

```bash
shasum -a 256 .config/ghostty/Ghostty.icns
```

## Setup

macOS only. Stow the common `ghostty` package first, then this one. Both use `--no-folding`.
See [Ghostty Package Setup Guide](../../../docs/guides/ghostty-setup.md) for the full dry-run →
install workflow. Quit Ghostty fully and start it again to see the new icon.
````

---

## Human Setup Guide: `docs/guides/ghostty-setup.md`

Required by ADR 0028: the package needs a manual Stow step, a post-Stow validation, a numpad check
(Decision 9), and has an unmanaged-file boundary (the macOS Application Support file). The guide
follows `docs/guides/alacritty-setup.md` and uses the ADR's ten sections in order:

1. **What this package manages** — the two common files and their symlink targets; Ghostty loads
   `~/.config/ghostty/config.ghostty` on start, and the theme by name from `themes/`. [macOS] The
   second package, `stow/macos/ghostty/`, links `Ghostty.icns`; `macos-icon = custom` loads it for
   the Dock and app switcher.
2. **What it does NOT manage** — `~/Library/Application Support/com.mitchellh.ghostty/config.ghostty`
   [macOS] stays unmanaged and must stay empty; Ghostty's own state; fonts; the
   `/Applications/Ghostty.app` bundle (never modified); the Finder icon and the update-dialog icon
   (unchanged by design). Includes a platform-notes paragraph: `macos-option-as-alt` and
   `macos-icon` are ignored on Linux; Arch stows only the common package; Debian servers use
   neither package.
3. **Prerequisites** — per platform:

   ```bash
   # macOS
   brew install --cask ghostty
   brew install --cask font-jetbrains-mono-nerd-font
   ```

   ```bash
   # Arch
   sudo pacman -S ghostty ttf-jetbrains-mono-nerd
   ```

   Each block is preceded by `⚠️  MANUAL STEP — review before running`. Version check uses the full
   macOS path (`/Applications/Ghostty.app/Contents/MacOS/ghostty --version`) and plain `ghostty` on
   Arch.
4. **Dry-run step** — `stow --dir=stow/common --target="$HOME" --simulate --no-folding ghostty`;
   expect two `LINK:` lines (`.config/ghostty/config.ghostty`,
   `.config/ghostty/themes/catppuccin-macchiato`), no conflict lines, exit code 0. Then, [macOS]
   only, `stow --dir=stow/macos --target="$HOME" --simulate --no-folding ghostty`; expect one
   `LINK:` line (`.config/ghostty/Ghostty.icns`), no conflict lines, exit code 0.
5. **Apply step (Stow)** — the common install command under `⚠️  MANUAL STEP`; then, [macOS] only,
   `stow --dir=stow/macos --target="$HOME" --no-folding ghostty` under its own
   `⚠️  MANUAL STEP` marker; why `--no-folding` is required for both (two packages share
   `~/.config/ghostty/`); `stow --adopt` is forbidden because it silently overwrites files without
   a backup.
6. **Manual activation steps** — quit and restart Ghostty fully (opacity and icon changes need a
   full restart on macOS); [macOS] check that the Dock and app switcher show the custom icon, and
   that the Finder icon is unchanged (expected); then the numpad check from PRD Decision 9
   (`cat -v`, then again after `tput smkx`), and what to do if a key misbehaves (change the repo,
   not the Application Support file).
7. **Validation steps** — real-directory checks for `~/.config/ghostty` and `themes/`; `readlink`
   on both common symlinks and, [macOS], on `~/.config/ghostty/Ghostty.icns`; `+validate-config`
   with the platform binary; visual check of the theme; [macOS] Dock icon check.
8. **Rollback steps** — [macOS] `stow --dir=stow/macos --target="$HOME" --delete ghostty` first,
   then `stow --dir=stow/common --target="$HOME" --delete ghostty`, each under
   `⚠️  MANUAL STEP`; Ghostty falls back to its defaults and, after a full restart, the official
   icon.
9. **Troubleshooting** — Stow conflict on an existing file; folded directory; theme not applied
   (bundled `Catppuccin Macchiato` vs repo `catppuccin-macchiato`, missing `themes/` symlink);
   settings overridden by a non-empty Application Support file; `xterm-ghostty` vs `xterm-256color`
   over SSH; font fallback; [macOS] icon unchanged (Ghostty not fully restarted, macOS package not
   stowed, or file not named exactly `Ghostty.icns`); Finder icon unchanged (by design).
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
- All `stow/common/` packages are stowed to `$HOME` (live symlinks into the repo), including `codex` — whose `.stow-local-ignore` keeps `config.toml` unlinked; that template is propagated with `task codex:sync` instead — except `ghostty`, which is added but not yet stowed, as is the macOS-only `stow/macos/ghostty` (manual step: `docs/guides/ghostty-setup.md`). Home directory is modified by the existing symlinks. `stow/common/` and `stow/macos/` remain the source of truth for which packages exist.
```

`README.md` status lines (`Home directory: stowed — all common packages linked` and the first
Safety bullet) get the same "except ghostty" wording.

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
| `website/reference/supported-systems.md` | Yes | Portability row "Alacritty, bat, eza, btop, Neovim themes" |
| `website/reference/troubleshooting.md` | Yes | `--no-folding` package list |
| `docs/stow-usage.md` | Yes | Package tree (add `ghostty/` under `common/` and under `macos/`), `--no-folding` package list, the "Platform directories are not packages" section (`stow/macos/` is no longer only a `.gitkeep`; example `task dry-run AREA=macos PACKAGE=ghostty`), and a new "Installing the ghostty package" section after the alacritty one that covers both packages |

These edits are a separate plan task. They describe Ghostty as available alongside Alacritty; they do
not claim it is stowed. The `stow/macos/` mentions state that `stow/macos/ghostty/` is macOS-only
and holds only the Ghostty icon.

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

### Decision 6: Icon location — `stow/macos/ghostty/` vs `stow/common/ghostty/`

**Option A: Separate macOS-only package, `stow/macos/ghostty/`** (PRD Decision 11)

Pro: Follows the cross-platform rule: a macOS-only asset lives under `stow/macos/`, not in
`common/`.
Pro: Arch machines never receive a file they cannot use.
Pro: `macos-custom-icon` stays at its default path, so the config has no absolute path.
Con: A second package, README, and ignore file; two stow commands on macOS.
Con: Both packages share `~/.config/ghostty/`, so `--no-folding` is mandatory for both.

**Option B: Icon inside `stow/common/ghostty/.config/ghostty/Ghostty.icns`**

Pro: One package and one stow command on every platform.
Con: Puts a macOS-only binary in `common/`, which breaks the rule that `common/` holds only config
that works on all platforms (`docs/stow-usage.md`, `.claude/rules/cross-platform.md`).
Con: Arch gets an unused 152344-byte file linked into `~/.config/ghostty/`.

**Decision:** Option A. The `macos-icon = custom` line itself stays in the common file, because
Ghostty ignores `macos-*` options on Linux, as with `macos-option-as-alt` (PRD Decision 1).

---

## Validation Strategy

All commands are read-only for `$HOME` and safe to run during implementation. The plan defines the
exact invocations; this section names them. Nothing here was run while writing this document.

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

Expected: no errors, with the `macos-icon = custom` line present. A theme-not-found message for
`catppuccin-macchiato` before any stow is expected and is settled by check 3.

### 2. Theme file validation

```bash
"$GHOSTTY" +validate-config \
  --config-file=stow/common/ghostty/.config/ghostty/themes/catppuccin-macchiato
```

Expected: no errors (theme files use the same syntax).

### 3. Fake-home Stow simulation and theme resolution

```bash
# Step 1 — conflict check
FAKE_HOME="$(mktemp -d)"
stow --dir=stow/common --target="$FAKE_HOME" --simulate --no-folding ghostty \
  && echo "Simulation passed: no conflicts detected"
rm -rf "$FAKE_HOME"

# Step 2 — link into a fake home, resolve the theme by name, clean up
FAKE_HOME="$(mktemp -d)"
stow --dir=stow/common --target="$FAKE_HOME" --no-folding ghostty
test ! -L "$FAKE_HOME/.config/ghostty" && test ! -L "$FAKE_HOME/.config/ghostty/themes" \
  && echo "OK: real directories"
XDG_CONFIG_HOME="$FAKE_HOME/.config" "$GHOSTTY" +validate-config \
  --config-file="$FAKE_HOME/.config/ghostty/config.ghostty"
stow --dir=stow/common --target="$FAKE_HOME" --delete ghostty
rm -rf "$FAKE_HOME"
```

Expected: two links, two real directories, no validation errors.

```bash
# macOS
# Step 3 — both packages into one fake home
FAKE_HOME="$(mktemp -d)"
stow --dir=stow/common --target="$FAKE_HOME" --no-folding ghostty
stow --dir=stow/macos --target="$FAKE_HOME" --simulate --no-folding ghostty \
  && echo "Simulation passed: no conflicts detected"
stow --dir=stow/macos --target="$FAKE_HOME" --no-folding ghostty
test ! -L "$FAKE_HOME/.config/ghostty" && test -L "$FAKE_HOME/.config/ghostty/Ghostty.icns" \
  && echo "OK: icon linked into real directory"
stow --dir=stow/macos --target="$FAKE_HOME" --delete ghostty
stow --dir=stow/common --target="$FAKE_HOME" --delete ghostty
rm -rf "$FAKE_HOME"
```

Expected: one extra link (`.config/ghostty/Ghostty.icns`), `~/.config/ghostty` still a real
directory, no conflicts.

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
  stow/macos/ghostty/README.md stow/macos/ghostty/.stow-local-ignore
```

Expected: no matches.

### 6. Icon file integrity [macOS package]

```bash
shasum -a 256 stow/macos/ghostty/.config/ghostty/Ghostty.icns
file stow/macos/ghostty/.config/ghostty/Ghostty.icns
wc -c < stow/macos/ghostty/.config/ghostty/Ghostty.icns
diff stow/common/ghostty/.stow-local-ignore stow/macos/ghostty/.stow-local-ignore
grep -n '^macos-icon = custom$' stow/common/ghostty/.config/ghostty/config.ghostty
grep -n 'macos-custom-icon' stow/common/ghostty/.config/ghostty/config.ghostty
```

Expected:

- `shasum` prints `6796c0f423a066009fef4f69ab7800a086627304fc633d3cba69a4ca173632ac`, equal to the
  value recorded in `stow/macos/ghostty/README.md` and PRD Decision 11.
- `file` reports `Mac OS X icon`.
- `wc -c` prints `152344`.
- `diff` prints nothing.
- The first `grep` prints one line; the second prints nothing.
- Check 1 (`+validate-config`) still passes with the `macos-icon` line.

### 7. `macos-icon = custom` without the icon [macOS, Build check]

Behaviour is unverified when the common package is stowed and `~/.config/ghostty/Ghostty.icns` is
absent. The Build checks it without touching `$HOME`: run check 1 and a fake-home launch with only
the common package, and record whether Ghostty reports an error, falls back to the official icon, or
fails. The result goes in the implementation review.

---

## Manual Installation Reference

Not executed by any agent or script.

```bash
# Step 1 — dry run (safe, changes nothing)
stow --dir=stow/common --target="$HOME" --simulate --no-folding ghostty
```

⚠️  MANUAL STEP — run only after reviewing dry-run output

```bash
# Step 2 — install
stow --dir=stow/common --target="$HOME" --no-folding ghostty
```

macOS only, after the common package:

```bash
# macOS
# Step 3 — dry run (safe, changes nothing)
stow --dir=stow/macos --target="$HOME" --simulate --no-folding ghostty
```

⚠️  MANUAL STEP — run only after reviewing dry-run output

```bash
# macOS
# Step 4 — install
stow --dir=stow/macos --target="$HOME" --no-folding ghostty
```

Then quit Ghostty fully, start it again, and check the Dock icon.

To unlink later:

⚠️  MANUAL STEP

```bash
# macOS only: remove the icon link first
stow --dir=stow/macos --target="$HOME" --delete ghostty
stow --dir=stow/common --target="$HOME" --delete ghostty
```

---

## Cross-Platform Notes

### macOS

- Ghostty 1.3.1 is installed; the CLI binary is `/Applications/Ghostty.app/Contents/MacOS/ghostty`.
- The Application Support `config.ghostty` exists and is empty. Ghostty reads it in addition to the
  XDG file. It stays untouched and unmanaged; settings change only in the repository.
- `macos-option-as-alt = true` is active; the `alt+n` and `alt+shift+l` bindings restore `~` and `|`.
- `alt+arrow_left` / `alt+arrow_right` are already Ghostty defaults here; the explicit lines are
  harmless.
- `background-opacity` changes need a full Ghostty restart.
- `/bin/zsh` exists by default.
- `macos-icon = custom` loads `~/.config/ghostty/Ghostty.icns` from the `stow/macos/ghostty`
  package. The icon changes in the Dock and app switcher only, after a full Ghostty restart. The
  Finder icon stays the official one (signed bundle, not modified); so does the update dialog.

### Arch / EndeavourOS

- Install with `sudo pacman -S ghostty`; the binary is on `PATH`.
- `macos-option-as-alt` is ignored. The `alt+…` bindings still apply to the Alt key.
- `macos-icon` is ignored. `stow/macos/ghostty` is not stowed; no icon file is linked.
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
- **Unknown icon licence in a public repository.** `Ghostty.icns` comes from macosicons.com
  ("Ghostty Darken") with no known licence. The operator chose to commit it. Mitigation: the macOS
  package README records the source and SHA-256; redistribution rights are the operator's
  responsibility (PRD Decision 11). Removing it later is one file delete, but it stays in git
  history.
- **`macos-icon = custom` with no icon present [macOS].** On a Mac where only the common package is
  stowed, `~/.config/ghostty/Ghostty.icns` is missing. Ghostty's behaviour in that case is
  unverified. Mitigation: the Build checks it (validation check 7) and records the result; the guide
  says to stow both packages on macOS.
- **Finder icon unchanged, by design [macOS].** The custom icon sets `NSApplication.icon` (Dock and
  app switcher) only. The signed bundle is not modified, so Finder and the update dialog keep the
  official icon. Mitigation: the guide and both READMEs state this so it is not reported as a bug.
- **Folding across two packages.** Stowing either package without `--no-folding` into an empty
  `~/.config/ghostty` could fold the directory into a link to one package and block the other.
  Mitigation: both commands carry `--no-folding`; validation check 3 step 3 stows both into one fake
  home.
- **Icon file renamed wrongly.** The source is `ghosty.icns` (misspelled); a copy that keeps that
  name does not match the `macos-custom-icon` default. Mitigation: validation check 6 and the
  file inventory name `Ghostty.icns` exactly.

---

## Extensibility

- **Numpad bindings:** added as single `keybind` lines at the end of the key-binding block if
  Decision 9 requires them; no structural change.
- **Platform overrides:** the existing `stow/macos/ghostty/` package, or a new `stow/arch/ghostty/`
  package, could add a separate file loaded with `config-file = ?<name>` (optional include) if
  platform-only settings accumulate. Not needed today.
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
2. Create `stow/macos/ghostty/` with `.stow-local-ignore` and `README.md` as specified above, and
   copy `~/Downloads/ghosty.icns` to `stow/macos/ghostty/.config/ghostty/Ghostty.icns` (read-only
   for the source; renamed on copy).
3. Run validation checks 1 to 7.
4. Operator runs the numpad verification (PRD Decision 9); add lines only if needed; record the
   result in the implementation review.
5. Create `docs/guides/ghostty-setup.md`.
6. Update the `AGENTS.md` (§1, §2) and `CLAUDE.md` status blocks, and the `README.md` package table,
   guide link, and status lines, in the same commit that adds both packages.
7. Add Ghostty mentions to the documentation and website pages marked "Yes", including the
   `stow/macos/` mentions.
8. Leave stowing to the operator, following the guide; the operator records the Dock icon check in
   the implementation review.
