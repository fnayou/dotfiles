# PRD: Ghostty Configuration

**Number:** 0028
**Status:** Approved
**Date:** 2026-10-17

## Problem Statement

Ghostty is installed on macOS (1.3.1 at `/Applications/Ghostty.app`) but has no managed
configuration. Out of the box it looks and behaves differently from Alacritty, the terminal
emulator this repository already manages (PRD 0011, `stow/common/alacritty/`). The operator wants
Ghostty customized exactly like Alacritty: same font, padding, opacity, scrolling, shell, key
bindings, and the same Catppuccin Macchiato colors.

Ghostty uses its own `key = value` config format and option names, so the Alacritty TOML cannot be
reused. This PRD defines a new Stow package, `stow/common/ghostty/`, records how each Alacritty
setting maps to a real Ghostty 1.3.1 option, and states where no equivalent exists.

## Goals

- Add a managed Ghostty configuration to the repository as a Stow package under
  `stow/common/ghostty/`.
- Reproduce every Alacritty setting in `stow/common/alacritty/.config/alacritty/alacritty.toml`
  that has a Ghostty equivalent, using real Ghostty option names verified against
  `ghostty +show-config --default --docs` (1.3.1).
- Add a repo-managed Catppuccin Macchiato theme file to the package whose hex values are identical
  to `stow/common/alacritty/.config/alacritty/catppuccin-macchiato.toml` (ADR 0068).
- Document every Alacritty setting that has no Ghostty equivalent, instead of inventing one.
- Document how the macOS `~/Library/Application Support/com.mitchellh.ghostty/config.ghostty` file
  is handled.
- Keep the repository safe and private throughout.

## Non-Goals

- Installing Ghostty or JetBrainsMono Nerd Font automatically on any platform.
- Installing Ghostty on Debian servers.
- Creating symlinks in `$HOME` or running `stow` during implementation.
- Writing the Ghostty config files in this PRD phase — that is the Build phase.
- Changing the Alacritty package or its palette.
- Using Ghostty features Alacritty does not have (splits, tabs, quick terminal, custom keybinds
  beyond those mirrored from Alacritty) as part of this PRD.
- Removing Alacritty.

## User Stories

- As a user, I want Ghostty to look and behave like my Alacritty setup so that I can switch
  terminals without relearning anything.
- As a user, I want Ghostty's colors to come from a repo-managed file with the same hex values as
  Alacritty so that one palette (ADR 0068) drives both terminals.
- As a user, I want the settings that cannot be mirrored listed explicitly so that I know where
  the two terminals still differ.
- As a user, I want the manual Stow commands to link the config when I am ready.

## Scope

This PRD covers:

- One Stow package: `stow/common/ghostty/`.
- Two config files: the main config `config.ghostty` and the theme file
  `themes/catppuccin-macchiato`.
- The Alacritty-to-Ghostty setting map, the portability decisions, and the handling of the macOS
  Application Support config file.
- Stow dry-run and install commands for future reference (not executed during implementation).

This PRD does not create symlinks in `$HOME` or run Stow install commands.

When the package is added, both status blocks (`AGENTS.md` §2 and `CLAUDE.md`) must be updated in
the same commit, per `.claude/rules/status-sync.md`.

## Target Structure

```
stow/
└── common/
    └── ghostty/
        └── .config/
            └── ghostty/
                ├── config.ghostty
                └── themes/
                    └── catppuccin-macchiato
```

After stowing, this maps to:

```
~/.config/ghostty/config.ghostty
~/.config/ghostty/themes/catppuccin-macchiato
```

`~/.config/ghostty` does not exist on the macOS machine at the time of writing, so no conflict is
expected; the dry run must still confirm this.

## Cross-Platform Requirements

| Platform | Ghostty installed | Package stowed |
|---|---|---|
| macOS | Yes | Yes |
| Arch / EndeavourOS | Yes | Yes |
| Debian (servers) | No | No |

The package is placed under `stow/common/` because the config is portable across macOS and Arch
with the caveats documented below. Debian servers do not install Ghostty and do not stow this
package.

**macOS installation (manual, future phase):**

```bash
# macOS
brew install --cask ghostty
```

**Arch / EndeavourOS installation (manual, future phase):**

```bash
# Arch
sudo pacman -S ghostty
```

On macOS the `ghostty` binary is not on `PATH`. CLI actions use the full path:
`/Applications/Ghostty.app/Contents/MacOS/ghostty`.

## Portability Decisions

### 1. Package location: `stow/common/ghostty/`

**Decision:** One common package, used on macOS and Arch. Debian servers do not install it.
macOS-only options (`macos-option-as-alt`) stay in the common file, as `option_as_alt` does in the
Alacritty package.

### 2. Config file name: `config.ghostty`

Ghostty 1.3.1 documents its default config path as `$XDG_CONFIG_HOME/ghostty/config.ghostty`
(`config-default-files` docs). Alacritty uses `alacritty.toml`; Ghostty has no TOML format.

**Decision:** Name the main file `config.ghostty`. Do not use the legacy name `config`.

### 3. macOS Application Support config file

Ghostty on macOS also reads
`~/Library/Application Support/com.mitchellh.ghostty/config.ghostty`. On this machine that file
exists and is empty (0 bytes), so it contributes no settings.

**Decision:** Leave the file untouched. Do not delete it, move it, or stow into it. The repo
config lives only at the XDG path.

**Risk:** If a setting is later added to the Application Support file (for example through
Ghostty's `open_config` action, `super+,`, which may open that file), it can layer over the
repo-managed config. Settings must be changed in the repository, not in that file.

### 4. Theme: repo-managed Catppuccin Macchiato file

Ghostty bundles a theme named `Catppuccin Macchiato`. Its values are not controlled by this
repository.

**Decision:** Ship a repo-managed theme file at `.config/ghostty/themes/catppuccin-macchiato` with
hex values identical to Alacritty's `catppuccin-macchiato.toml` (ADR 0068). Do not use the bundled
theme.

**Loading:** `config.ghostty` sets `theme = catppuccin-macchiato`. Ghostty searches
`~/.config/ghostty/themes/` first for a non-absolute theme name, so the stowed file is found
without a hardcoded home path. The hyphenated name cannot match the bundled
`Catppuccin Macchiato`.

**Alternatives (not adopted):**

- `theme = <absolute path>` — needs a machine-specific absolute path, which the cross-platform
  rules forbid.
- `config-file = themes/catppuccin-macchiato` — works (paths are relative to the including file),
  but a `config-file` include can set any option. Theme files cannot set `theme` or `config-file`,
  which keeps the palette file limited to colors.

### 5. JetBrainsMono Nerd Font

Same as PRD 0011: commit the font preference as-is. If the font is missing, Ghostty falls back to
a system font.

**Manual font installation (for reference, not automated):**

```bash
# macOS
brew install --cask font-jetbrains-mono-nerd-font

# Arch
sudo pacman -S ttf-jetbrains-mono-nerd
```

### 6. `TERM`

Alacritty sets `TERM = "xterm-256color"`. Ghostty's default is `term = xterm-ghostty`, whose
terminfo entry ships with Ghostty but is usually missing on remote hosts such as the Debian
servers.

**Decision:** Set `term = xterm-256color` to match Alacritty. This avoids missing-terminfo errors
over SSH. It gives up the extra capabilities advertised by `xterm-ghostty`.

### 7. Shell: `/bin/zsh -l`

Alacritty runs `/bin/zsh` with `args = ["-l"]`. PRD 0011 established that `/bin/zsh` is valid on
macOS and on Arch (`usr-merge`).

**Decision:** Set `command = /bin/zsh -l`. Ghostty runs a `command` that contains arguments
through `/bin/sh -c`. Ghostty's shell integration (enabled by default) is a behavior Alacritty does
not have; it is kept at its default (Decision 10).

## Alacritty to Ghostty Mapping

Source: `stow/common/alacritty/.config/alacritty/alacritty.toml`. Ghostty options verified with
`ghostty +show-config --default --docs` and `ghostty +list-keybinds --default` on Ghostty 1.3.1
(macOS).

| Alacritty setting | Alacritty value | Ghostty option | Ghostty value | Match | Notes |
|---|---|---|---|---|---|
| `general.import` | `~/.config/alacritty/catppuccin-macchiato.toml` | `theme` | `catppuccin-macchiato` | Equivalent | Resolved from `~/.config/ghostty/themes/`. See Decision 4. |
| Config file | `alacritty.toml` (TOML) | — | `config.ghostty` (`key = value`) | Different format | See Decision 2. |
| `env.TERM` | `xterm-256color` | `term` | `xterm-256color` | Equivalent | Ghostty default is `xterm-ghostty`. See Decision 6. |
| `window.padding` | `x = 12, y = 12` | `window-padding-x`, `window-padding-y` | `12`, `12` | Equivalent | Both scale by DPI; Ghostty units are points. |
| `window.dynamic_padding` | `true` | `window-padding-balance` | `true` | Equivalent | Spreads leftover space across all four edges. |
| `window.decorations` | commented out | — | not set | — | Not active in Alacritty; not mirrored. |
| `window.opacity` | `0.98` | `background-opacity` | `0.98` | Partial | Change needs a full Ghostty restart on macOS; disabled in native fullscreen. Cell backgrounds stay opaque in both (`background-opacity-cells = false` default). |
| `window.startup_mode` | `Windowed` | `maximize`, `fullscreen` | defaults (`false`) | Equivalent | No setting needed. |
| `window.option_as_alt` | `Both` | `macos-option-as-alt` | `true` | Equivalent | `true` = both Option keys. macOS only, like Alacritty. Ghostty's unset default depends on keyboard layout. |
| `scrolling.history` | `10000` (lines) | `scrollback-limit` | not set (Ghostty default `10000000` bytes) | Mismatch | Ghostty limits scrollback in **bytes** per surface (default `10000000`), not lines. No line-count option exists. |
| `scrolling.multiplier` | `3` | `mouse-scroll-multiplier` | `3` | Partial | Unprefixed value applies to all devices, like Alacritty. Ghostty default is `precision:1,discrete:3`, so trackpad scrolling becomes 3x the Ghostty default. Feel is not guaranteed identical. |
| `font.size` | `13.0` | `font-size` | `13` | Equivalent | Ghostty default is also 13. Set explicitly. |
| `font.normal` | `JetBrainsMono Nerd Font`, `Regular` | `font-family`, `font-style` | `JetBrainsMono Nerd Font`, `Regular` | Equivalent | |
| `font.bold` | `JetBrainsMono Nerd Font`, `Bold` | `font-family-bold`, `font-style-bold` | `JetBrainsMono Nerd Font`, `Bold` | Equivalent | |
| `font.italic` | `JetBrainsMono Nerd Font`, `Italic` | `font-family-italic`, `font-style-italic` | `JetBrainsMono Nerd Font`, `Italic` | Equivalent | |
| `font.bold_italic` | `JetBrainsMono Nerd Font`, `Bold Italic` | `font-family-bold-italic`, `font-style-bold-italic` | `JetBrainsMono Nerd Font`, `Bold Italic` | Equivalent | |
| `font.offset.y` | `1` | `adjust-cell-height` | `1` | Partial | Both add 1 to cell height. Ghostty centers the glyph vertically in the taller cell; Alacritty keeps it at `glyph_offset` (0). `adjust-font-baseline` is a separate option and is not used. |
| `terminal.shell` | `/bin/zsh`, `["-l"]` | `command` | `/bin/zsh -l` | Partial | Run through `/bin/sh -c` because it has arguments. Ghostty adds shell integration, kept at its default (Decision 10). |
| Numpad bindings | `Numpad0`–`Numpad9`, `NumpadAdd`, `NumpadSubtract`, `NumpadMultiply`, `NumpadDivide`, `NumpadDecimal`, `NumpadEnter` → literal chars | `keybind` | e.g. `numpad_0=text:0`, `numpad_enter=text:\r` | Unverified | Ghostty accepts W3C key codes in snake case. Whether Ghostty needs these bindings at all is verified during Build (Decision 9). |
| `Alt+N` | `~` | `keybind` | `alt+n=text:~` | Equivalent | Needed because Option is treated as Alt, so Option+N no longer composes `~`. |
| `Alt+Shift+L` | `\|` | `keybind` | `alt+shift+l=text:\|` | Equivalent | Same reason as `Alt+N`. |
| `Alt+Left` | `\u001Bb` | `keybind` | `alt+arrow_left=esc:b` | Equivalent | Already a Ghostty default on macOS. Set explicitly so Arch matches. |
| `Alt+Right` | `\u001Bf` | `keybind` | `alt+arrow_right=esc:f` | Equivalent | Already a Ghostty default on macOS. Set explicitly so Arch matches. |
| `Shift+Return` | `\n` | `keybind` | `shift+enter=text:\n` | Equivalent | Sends a literal LF, as in Alacritty. |

### Theme mapping

Source: `stow/common/alacritty/.config/alacritty/catppuccin-macchiato.toml`. All hex values are
copied unchanged (ADR 0068).

| Alacritty key | Hex | Ghostty option |
|---|---|---|
| `colors.primary.background` | `#24273a` | `background` |
| `colors.primary.foreground` | `#cad3f5` | `foreground` |
| `colors.cursor.cursor` | `#f4dbd6` | `cursor-color` |
| `colors.cursor.text` | `#24273a` | `cursor-text` |
| `colors.selection.background` | `#f4dbd6` | `selection-background` |
| `colors.selection.text` | `#24273a` | `selection-foreground` |
| `colors.search.matches.background` | `#a5adcb` | `search-background` |
| `colors.search.matches.foreground` | `#24273a` | `search-foreground` |
| `colors.search.focused_match.background` | `#a6da95` | `search-selected-background` |
| `colors.search.focused_match.foreground` | `#24273a` | `search-selected-foreground` |
| `colors.normal.black` … `white` | `#494d64` `#ed8796` `#a6da95` `#eed49f` `#8aadf4` `#f5bde6` `#8bd5ca` `#b8c0e0` | `palette = 0=` … `palette = 7=` |
| `colors.bright.black` … `white` | `#5b6078` `#ed8796` `#a6da95` `#eed49f` `#8aadf4` `#f5bde6` `#8bd5ca` `#a5adcb` | `palette = 8=` … `palette = 15=` |

### Settings with no Ghostty equivalent

| Alacritty setting | Reason |
|---|---|
| `colors.vi_mode_cursor` | Ghostty has no vi mode. |
| `colors.hints.start`, `colors.hints.end` | Ghostty has no hints mode. |
| `colors.footer_bar` | Ghostty's search UI is native; it has no footer bar color. |
| `colors.dim.*` | Ghostty has no dim palette; it renders faint text with `faint-opacity`. Alacritty's dim values equal its normal values. |

## Configuration Summary

The future `config.ghostty` encodes these preferences:

| Setting | Value | Notes |
|---|---|---|
| `theme` | `catppuccin-macchiato` | Repo-managed file in `themes/` |
| `term` | `xterm-256color` | Matches Alacritty |
| `window-padding-x` / `window-padding-y` | `12` / `12` | Matches Alacritty |
| `window-padding-balance` | `true` | Matches `dynamic_padding` |
| `background-opacity` | `0.98` | Matches Alacritty |
| `macos-option-as-alt` | `true` | macOS only |
| `mouse-scroll-multiplier` | `3` | All devices |
| `scrollback-limit` | not set | Ghostty default (`10000000` bytes); Decision 8 |
| `font-family` (+ bold/italic/bold-italic) | `JetBrainsMono Nerd Font` | Fallback if missing |
| `font-style` (+ bold/italic/bold-italic) | `Regular` / `Bold` / `Italic` / `Bold Italic` | Matches Alacritty |
| `font-size` | `13` | Matches Alacritty |
| `adjust-cell-height` | `1` | Approximates `font.offset.y = 1` |
| `command` | `/bin/zsh -l` | Portable via `usr-merge` on Arch |
| `keybind` | Alt, Shift+Enter, and (pending) numpad bindings | See mapping table |

## Stow Commands (Future Reference — Not Executed During Implementation)

When ready to link the config:

```bash
# Step 1 — dry run
stow --dir=stow/common --target="$HOME" --simulate --no-folding ghostty
```

⚠️  MANUAL STEP — run only after reviewing dry-run output

```bash
# Step 2 — install
stow --dir=stow/common --target="$HOME" --no-folding ghostty
```

`--no-folding` keeps `~/.config/ghostty/` and `~/.config/ghostty/themes/` as real directories, so
files Ghostty or the user create there do not land in the repository.

## Safety Requirements

- Must not run `stow` install commands automatically.
- Must not create symlinks in `$HOME` without explicit per-session user approval.
- Must not delete, move, or overwrite any existing dotfile.
- Must not delete, move, or write to
  `~/Library/Application Support/com.mitchellh.ghostty/config.ghostty`.
- Must not run `rm`, `mv`, or `ln -s` against `$HOME` or any path outside the repo.
- Must not use `stow --adopt`.
- Must not install Ghostty or fonts automatically.
- Must stop and report if the dry run shows a conflict.

## Privacy Requirements

- The Ghostty configuration contains no secrets, credentials, tokens, API keys, SSH keys, private
  hostnames, or work-specific settings.
- The configuration is personal display and key preferences only, mirrored from the already
  committed Alacritty package.
- The repository is treated as private by default.

## Acceptance Criteria

- [ ] `stow/common/ghostty/.config/ghostty/config.ghostty` exists and sets every option in the
  Configuration Summary and follows Decisions 8–10.
- [ ] `stow/common/ghostty/.config/ghostty/themes/catppuccin-macchiato` exists and every hex value
  in it matches `stow/common/alacritty/.config/alacritty/catppuccin-macchiato.toml`.
- [ ] `config.ghostty` loads the theme with `theme = catppuccin-macchiato`, not the bundled
  `Catppuccin Macchiato` and not an absolute path.
- [ ] Ghostty's `+validate-config` action reports no errors for the new file (exact invocation is
  defined in the plan).
- [ ] No secrets, credentials, or private data are present in either file.
- [ ] No symlinks are created in `$HOME` during implementation.
- [ ] No `stow` install command is executed automatically.
- [ ] The macOS Application Support `config.ghostty` file is left untouched.
- [ ] Settings with no Ghostty equivalent are listed in this PRD and not invented in the config.
- [ ] The Stow dry-run and install commands are documented for future reference.
- [ ] Both status blocks (`AGENTS.md` §2, `CLAUDE.md`) are updated in the commit that adds the
  package.

## Resolved Questions

Resolved by the operator on 2026-10-17 when approving this PRD.

### 8. Scrollback: keep Ghostty's default

Ghostty limits scrollback in bytes per surface, not lines. **Decision:** do not set
`scrollback-limit`; keep Ghostty's default (`10000000` bytes). Alacritty's 10000-line value has no
exact Ghostty equivalent and is not approximated.

### 9. Numpad bindings: verify before porting

Alacritty needs explicit numpad bindings to send literal characters. **Decision:** do not port them
blindly. During Build, with the new config loaded and no numpad bindings, the operator presses each
numpad key (`0`–`9`, `+`, `-`, `*`, `/`, `.`, `Enter`) in Ghostty on macOS inside `cat -v`, then
repeats after `tput smkx` (application keypad mode). Only a key whose output differs from its
literal character gets a `keybind = numpad_<key>=text:<char>` line. The result is recorded in the
implementation review.

### 10. Shell integration: keep the default

**Decision:** keep Ghostty's default `shell-integration = detect` and default
`shell-integration-features`. Do not set either option. This is an accepted difference from
Alacritty.

## Out of Scope

- Installing Ghostty or JetBrainsMono Nerd Font on any platform.
- Installing or stowing Ghostty on Debian servers.
- Creating a macOS-specific or Arch-specific Ghostty override package.
- Modifying `$HOME` or creating any symlinks during implementation.
- Editing, deleting, or migrating the macOS Application Support `config.ghostty` file.
- Running `stow` install (non-simulate) without explicit user approval.
- Changing the Alacritty package or the Catppuccin Macchiato palette.
- Ghostty-only features: splits, tabs, quick terminal, extra keybinds.
- Windows or WSL support.
