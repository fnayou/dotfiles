# Architecture: macOS Terminal.app Profile

**Number:** 0027
**Status:** Approved
**Date:** 2026-10-22
**PRD:** 0031 (Approved)

## Context

PRD 0031 asks for a Catppuccin Macchiato Terminal.app profile with a Nerd Font, deployed by a
user-run `task terminal:sync` that is a dry run by default.

State of the repository and the machine, verified on 2026-10-22:

- Terminal.app stores profiles in the `Window Settings` dictionary of the `com.apple.Terminal`
  preference domain, keyed by profile name. Colors and fonts are `NSKeyedArchiver` data blobs.
  The default and startup profile are the strings `Default Window Settings` and
  `Startup Window Settings` (both `Clear Dark` today).
- The installed font is `JetBrainsMono Nerd Font` with PostScript name `JetBrainsMonoNF-Regular`
  (read with `fc-scan`, not guessed). Ghostty uses the same family at size 13.
- Alacritty's theme `stow/common/alacritty/.config/alacritty/catppuccin-macchiato.toml` is the
  ANSI reference (PRD 0026) and is the palette source for this profile.
- `scripts/codex-sync.sh` is the precedent for a repo-to-live sync: template not linked by Stow,
  inspect by default, `--apply` backs up then writes, one-directional, bash wrapper with embedded
  Python.
- A Stow package whose files are all ignored exits 0 and links nothing (checked with
  `stow --simulate` against a scratch directory).

## Proposed Structure

```
stow/macos/terminal/
├── .stow-local-ignore                  # ignores everything: nothing is ever linked
├── Catppuccin Macchiato.terminal       # the profile: source of truth, XML plist
└── README.md                           # package doc (ignored by Stow too)

scripts/terminal-sync.sh                # bash wrapper + embedded Python, like codex-sync.sh
Taskfile.yml                            # terminal:sync target
docs/guides/terminal-app-setup.md       # deploy flow, rollback, 24-bit limit
website/features/terminal.md            # Terminal.app section (existing page)
website/features/scripts.md             # lists the new script
website/features/packages.md            # lists the package if it belongs there
```

`terminal-sync.sh` modes:

| Invocation | Effect | Writes |
|---|---|---|
| `task terminal:sync` | Report: profile present or not, drift against the repo file, current default | Nothing |
| `task terminal:sync ARGS='--apply'` | Back up the domain, add or update `Catppuccin Macchiato` | `com.apple.Terminal` only |
| `task terminal:sync ARGS='--apply --set-default'` | As above, then set it as default and startup profile | `com.apple.Terminal` only |
| `task terminal:sync ARGS='--build'` | Regenerate the `.terminal` file from the Alacritty theme | Repository only |

## Design Decisions

### Decision 1: Deliver through a user-run Task, not Stow

```
Option A: Stow the profile
  Pro: the repo's normal mechanism
  Con: Terminal.app does not read a file; a link would do nothing

Option B: Task target modeled on codex:sync
  Pro: fits the precedent; dry run by default; explicit user action
  Con: one more script to maintain

Decision: B. The package still lives under stow/macos/ so it sits with the other macOS
configuration, but .stow-local-ignore ignores every file, so Stow links nothing.
```

### Decision 2: Write the live preferences with `defaults`, not `open` and not a raw plist edit

```
Option A: `open "Catppuccin Macchiato.terminal"`
  Pro: Apple's own import path
  Con: launches Terminal.app and opens a window; behavior when a profile with the same name
       exists is unverified, so a re-run could duplicate or prompt; cannot be dry-run

Option B: edit ~/Library/Preferences/com.apple.Terminal.plist directly
  Pro: simple
  Con: bypasses cfprefsd, which caches the domain and rewrites the file; a live edit can be lost
       or corrupt state

Option C: `defaults write com.apple.Terminal "Window Settings" -dict-add "<name>" "<xml>"`
  Pro: goes through cfprefsd; replaces only the one key, so it is idempotent and leaves every
       other profile untouched; the current state is readable with `defaults export` for the
       dry run and the backup
  Con: the profile is embedded as an XML string argument

Decision: C.
```

### Decision 3: Refuse `--apply` while Terminal.app is running

Terminal.app keeps its profiles in memory and rewrites them when it quits, which can drop a key
added behind its back. `--apply` checks for a running Terminal.app and exits with "quit
Terminal.app (⌘Q) and run this from another terminal" and changes nothing. The dry run has no
such restriction. This is the cost of a deterministic result.

### Decision 4: Setting the default is a separate flag

`--set-default` writes both `Default Window Settings` and `Startup Window Settings`, and is only
accepted together with `--apply`. Without it the profile is available in Terminal.app's Profiles
list and the current default stays as it is, which gives the user a safe way to try it first.

### Decision 5: The committed `.terminal` is the source of truth, built from the Alacritty theme

```
Option A: write the plist by hand
  Pro: no generator
  Con: archived colors are unreadable, so a palette change cannot be reviewed or reproduced

Option B: `--build` generates the file from the Alacritty theme, and the file is committed
  Pro: one palette source; reproducible; the sync report can compare the two
  Con: a generator mode to maintain

Decision: B. The sync never reads the Alacritty file at deploy time; it reads the committed
profile. --build is a repository-only action.
```

Profile contents:
- `name`, `type = Window Settings`, `ProfileCurrentVersion` copied from an existing profile.
- `BackgroundColor #24273a`, `TextColor #cad3f5`, `TextBoldColor #cad3f5`, `CursorColor #f4dbd6`.
- 16 ANSI colors mapped to the same slots as the Alacritty theme.
- `Font` = `JetBrainsMonoNF-Regular` at size 13, `FontAntialias` on.
- Window size, bell, blur and keyboard keys are not set, so Terminal.app defaults apply (PRD
  out of scope).

### Decision 6: Selection color departs from Alacritty

Alacritty and Ghostty use rosewater `#f4dbd6` with dark text for the selection. Terminal.app can
set only the selection background and keeps the text color, so a rosewater background would make
light text unreadable. The profile uses Surface2 `#5b6078` instead. The palette check in the
dry run exempts this one slot and states why.

### Decision 7: Backups

Before any write, `--apply` exports the current domain with `defaults export com.apple.Terminal`
to a timestamped file kept outside the repository, following the location and naming used by
`codex-sync.sh`. That file is the rollback: `defaults import com.apple.Terminal <file>`, documented
in the guide as a manual step.

### Decision 8: macOS guard

The script calls `scripts/detect-os.sh` and exits 1 with a clear message on `arch`, `debian` or
unsupported systems, before reading any preference. It also exits if `defaults` or the
`com.apple.Terminal` domain is missing.

## Risks

- **Archive format:** the `NSKeyedArchiver` structure for colors and fonts is built by the
  generator, not by Terminal.app. A wrong structure could make Terminal.app ignore the profile or
  show defaults. Mitigation: decode it with `NSKeyedUnarchiver` before shipping, compare with the
  structure of an existing profile, and test the write against a scratch preference domain, never
  the live one.
- **cfprefsd caching:** a profile written while Terminal.app is closed should appear on next
  launch. Decision 3 reduces, but does not eliminate, the chance of a stale cache. The guide
  documents `killall cfprefsd` as a manual fallback.
- **Font rendering:** the glyph depends on the PostScript name and on the font being installed. If
  it is missing the profile falls back to a system font and the Apple glyph is again a placeholder.
  The dry run reports whether the font is installed.
- **24-bit color:** Terminal.app approximates hex colors from omp, nvim and bat to 256 colors.
  Nothing here fixes that; the guide says so.
- **Cross-platform:** macOS-only by construction. Arch and Debian are untouched, and the script
  exits early there. Homebrew is required only for the font, which the Brewfile already installs.
- **Privacy:** the profile and script contain colors, a font name and a profile name only. Backups
  are written outside the repository, so personal profile data never enters version control.
- **Reversibility:** `--apply` only adds or replaces its own key. The backup plus
  `defaults import` restores the whole domain, and deleting the profile in Terminal.app removes it.
- **Stow:** a package with every file ignored might be reported as empty by tooling that lists
  packages. To be confirmed in the plan against `docs/stow-usage.md` and any status check.

## Extensibility

Another terminal-specific sync (for example iTerm2) can reuse the same shape: a committed profile,
a dry-run-by-default script, and a Task target. The palette source stays the Alacritty theme, so a
palette change flows through one `--build` and one reviewed `--apply`.

## Open Questions

- Does the user want the Surface2 selection color, or a different readable choice? (Decision 6)
- Does Terminal.app pick up the new profile at next launch without further action, or is
  `killall cfprefsd` needed? To be answered on a scratch domain in the plan's validation, and once
  on the live machine at the user's `--apply`.
- Should the backup location mirror `codex-sync.sh` exactly? To be confirmed from that script in
  the plan.

## Recommended Next Step

On approval, the Planner writes plan 0035 with ordered tasks: generator and profile, sync script
and Task target, scratch-domain validation, guide, website pages, status-block update, and
Reviewer checks. The plan must keep every live-system command as a `⚠️  MANUAL STEP` and include
the website update from PRD 0031 in its acceptance criteria.
