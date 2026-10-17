# Architecture: Ghostty Configuration Architecture

**Number:** 0026
**Status:** Draft
**Date:** 2026-10-17
**PRD:** [0028-ghostty-configuration](../prd/0028-ghostty-configuration.md)

---

## Context

PRD 0028 (Approved) adds a managed Ghostty configuration as a new Stow package,
`stow/common/ghostty/`, that mirrors the Alacritty package (`stow/common/alacritty/`, PRD 0011,
architecture 0011). Ghostty 1.3.1 is installed on macOS at `/Applications/Ghostty.app`; the binary
is not on `PATH` there.

The PRD already fixed every product decision. This architecture does **not** re-open them. It turns
them into structure:

- the exact package file tree and file inventory;
- the full intended content of `config.ghostty` and `themes/catppuccin-macchiato`;
- the package `.stow-local-ignore` and `README.md`;
- the human setup guide `docs/guides/ghostty-setup.md` (ADR 0028);
- the status-block updates (`.claude/rules/status-sync.md`);
- the documentation and website pages that mention Alacritty and need a Ghostty mention;
- the read-only validation strategy the plan will use.

### Decisions inherited from PRD 0028 (not re-opened)

| PRD decision | Fixed outcome |
|---|---|
| 1. Package location | One common package, `stow/common/ghostty/`; macOS and Arch; not on Debian |
| 2. Config file name | `config.ghostty` (not the legacy `config`) |
| 3. Application Support file | `~/Library/Application Support/com.mitchellh.ghostty/config.ghostty` left untouched |
| 4. Theme | Repo-managed `themes/catppuccin-macchiato`, loaded with `theme = catppuccin-macchiato` |
| 5. Font | `JetBrainsMono Nerd Font` committed as-is; no install step |
| 6. `TERM` | `term = xterm-256color` |
| 7. Shell | `command = /bin/zsh -l` |
| 8. Scrollback | `scrollback-limit` not set (Ghostty default, bytes) |
| 9. Numpad bindings | Not ported; verified during Build; a line is added only for a key that misbehaves |
| 10. Shell integration | Ghostty default kept; `shell-integration*` not set |
| Stow | `--no-folding`, manual dry-run then manual install |

Out of scope for this architecture (per PRD 0028):

- Installing Ghostty or JetBrainsMono Nerd Font on any platform.
- Installing or stowing Ghostty on Debian servers.
- Creating symlinks in `$HOME` or running a Stow install.
- Editing, moving, or deleting the macOS Application Support `config.ghostty` file.
- Changing the Alacritty package or the Catppuccin Macchiato palette.
- Ghostty-only features (splits, tabs, quick terminal, extra keybinds).

---

## Proposed Structure

### Directory layout

```
stow/
└── common/
    └── ghostty/
        ├── .stow-local-ignore
        ├── README.md
        └── .config/
            └── ghostty/
                ├── config.ghostty
                └── themes/
                    └── catppuccin-macchiato
```

No `stow/macos/ghostty/` or `stow/arch/ghostty/` package is created (PRD Decision 1).

### File inventory

| File | Type | Stowed? | Maps to |
|---|---|---|---|
| `stow/common/ghostty/.config/ghostty/config.ghostty` | Real managed config | Yes | `~/.config/ghostty/config.ghostty` |
| `stow/common/ghostty/.config/ghostty/themes/catppuccin-macchiato` | Real managed theme | Yes | `~/.config/ghostty/themes/catppuccin-macchiato` |
| `stow/common/ghostty/.stow-local-ignore` | Stow ignore list | No (ignored) | — |
| `stow/common/ghostty/README.md` | Package README | No (ignored) | — |

Both config files are committed and stowed directly. No `.example` step: the content is personal
display and key preferences, mirrored from the already committed Alacritty package, with no secrets
(same policy as architecture 0011, Decision 2).

### Other files the Build creates or modifies

| File | Change | Rule |
|---|---|---|
| `docs/guides/ghostty-setup.md` | Created | ADR 0028 |
| `AGENTS.md` (§1 bullet, §2 block) | Modified | `.claude/rules/status-sync.md` |
| `CLAUDE.md` (status block) | Modified | `.claude/rules/status-sync.md` |
| `README.md` (package table row, per-package guide link, status lines) | Modified | Package table lists every `stow/common/` package |
| `docs/stow-usage.md` and website pages | Modified | See "Documentation and website mentions" |

The status blocks must be updated in the **same commit** that adds `stow/common/ghostty/`.

### Symlink model (after a manual stow)

```
~/.config/ghostty/                         real directory (--no-folding)
├── config.ghostty
│     → <repo>/stow/common/ghostty/.config/ghostty/config.ghostty
└── themes/                                real directory (--no-folding)
    └── catppuccin-macchiato
          → <repo>/stow/common/ghostty/.config/ghostty/themes/catppuccin-macchiato
```

`~/.config/ghostty` does not exist on the macOS machine today, so no conflict is expected. The dry
run must still confirm this. Ghostty searches `~/.config/ghostty/themes/` first for a non-absolute
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

---

## Human Setup Guide: `docs/guides/ghostty-setup.md`

Required by ADR 0028: the package needs a manual Stow step, a post-Stow validation, a numpad check
(Decision 9), and has an unmanaged-file boundary (the macOS Application Support file). The guide
follows `docs/guides/alacritty-setup.md` and uses the ADR's ten sections in order:

1. **What this package manages** — the two files and their symlink targets; Ghostty loads
   `~/.config/ghostty/config.ghostty` on start, and the theme by name from `themes/`.
2. **What it does NOT manage** — `~/Library/Application Support/com.mitchellh.ghostty/config.ghostty`
   [macOS] stays unmanaged and must stay empty; Ghostty's own state; fonts. Includes a platform-notes
   paragraph: `macos-option-as-alt` is ignored on Linux; Debian servers do not use this package.
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
   `.config/ghostty/themes/catppuccin-macchiato`), no conflict lines, exit code 0.
5. **Apply step (Stow)** — the install command under `⚠️  MANUAL STEP`; why `--no-folding` is
   required; `stow --adopt` is forbidden because it silently overwrites files without a backup.
6. **Manual activation steps** — quit and restart Ghostty fully (opacity changes need a full restart
   on macOS); then the numpad check from PRD Decision 9 (`cat -v`, then again after `tput smkx`),
   and what to do if a key misbehaves (change the repo, not the Application Support file).
7. **Validation steps** — real-directory checks for `~/.config/ghostty` and `themes/`; `readlink`
   on both symlinks; `+validate-config` with the platform binary; visual check of the theme.
8. **Rollback steps** — `stow --dir=stow/common --target="$HOME" --delete ghostty` under
   `⚠️  MANUAL STEP`; Ghostty falls back to its defaults.
9. **Troubleshooting** — Stow conflict on an existing file; folded directory; theme not applied
   (bundled `Catppuccin Macchiato` vs repo `catppuccin-macchiato`, missing `themes/` symlink);
   settings overridden by a non-empty Application Support file; `xterm-ghostty` vs `xterm-256color`
   over SSH; font fallback.
10. **Expected final file layout** — the symlink model above, with `/path/to/dotfiles` placeholders.

The guide contains no real paths, names, or hostnames; examples use placeholders.

---

## Status-Block Updates

The package is **added** in the Build commit but **not stowed** (PRD: no Stow install during
implementation). Today both blocks say every `stow/common/` package is stowed, which would become
false. The Build commit changes them to name the exception, in prose, without a per-package list
beyond that exception.

`AGENTS.md` §2:

```
Current status:          Claude Code operating layer complete; common packages stowed (ghostty pending).
Dotfiles implementation: stowed — all stow/common/ packages symlinked into $HOME except ghostty.
GNU Stow packages:       see stow/common/ (source of truth; macos/, arch/, debian/ empty).
Stowed to $HOME:         all stow/common/ packages except ghostty (added, not yet stowed) — live symlinks into the repo.
Home directory:          modified by these symlinks; further modifications forbidden unless explicitly requested.
```

`AGENTS.md` §1 bullet:

```
- Dotfiles are **stowed** — all `stow/common/` packages except `ghostty` (added, not yet stowed) are symlinked into `$HOME`.
```

`CLAUDE.md` bullet:

```
- All `stow/common/` packages are stowed to `$HOME` (live symlinks into the repo), including `codex` — whose `.stow-local-ignore` keeps `config.toml` unlinked; that template is propagated with `task codex:sync` instead — except `ghostty`, which is added but not yet stowed (manual step: `docs/guides/ghostty-setup.md`). Home directory is modified by the existing symlinks. `stow/common/` remains the source of truth for which packages exist.
```

`README.md` status lines (`Home directory: stowed — all common packages linked` and the first
Safety bullet) get the same "except ghostty" wording.

When the operator first stows `ghostty`, that is a "first stowed" event: a later commit removes the
exception from all blocks again, per `.claude/rules/status-sync.md`.

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
| `website/reference/stow.md` | Yes | Package tree and the `--no-folding` package list |
| `website/reference/supported-systems.md` | Yes | Portability row "Alacritty, bat, eza, btop, Neovim themes" |
| `website/reference/troubleshooting.md` | Yes | `--no-folding` package list |
| `docs/stow-usage.md` | Yes | Package tree, `--no-folding` package list, and a new "Installing the ghostty package" section after the alacritty one |

These edits are a separate plan task. They describe Ghostty as available alongside Alacritty; they do
not claim it is stowed.

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

Expected: no errors. A theme-not-found message for `catppuccin-macchiato` before any stow is expected
and is settled by check 3.

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
```

Expected: no matches.

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

To unlink later:

⚠️  MANUAL STEP

```bash
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

### Arch / EndeavourOS

- Install with `sudo pacman -S ghostty`; the binary is on `PATH`.
- `macos-option-as-alt` is ignored. The `alt+…` bindings still apply to the Alt key.
- The explicit `alt+arrow_*` lines give word navigation that the Linux defaults do not.
- `/bin/zsh` resolves through `usr-merge` (as in architecture 0011, Decision 6).
- Font package: `ttf-jetbrains-mono-nerd`.
- `xterm-ghostty` terminfo ships with the package, but `term = xterm-256color` is used anyway.

### Debian

- Ghostty is not installed and this package is not stowed on Debian servers.
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

---

## Extensibility

- **Numpad bindings:** added as single `keybind` lines at the end of the key-binding block if
  Decision 9 requires them; no structural change.
- **Platform overrides:** a `stow/macos/ghostty/` or `stow/arch/ghostty/` package could add a
  separate file loaded with `config-file = ?<name>` (optional include) if platform-only settings
  accumulate. Not needed today.
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
2. Run validation checks 1 to 5.
3. Operator runs the numpad verification (PRD Decision 9); add lines only if needed; record the
   result in the implementation review.
4. Create `docs/guides/ghostty-setup.md`.
5. Update the `AGENTS.md` (§1, §2) and `CLAUDE.md` status blocks, and the `README.md` package table,
   guide link, and status lines, in the same commit that adds the package.
6. Add Ghostty mentions to the documentation and website pages marked "Yes".
7. Leave stowing to the operator, following the guide.
