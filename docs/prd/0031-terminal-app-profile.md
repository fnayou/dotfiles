# PRD: macOS Terminal.app Profile

**Number:** 0031
**Status:** Approved
**Date:** 2026-10-22

## Goals

- Make the default macOS Terminal.app render the prompt and tools like Alacritty and Ghostty do:
  the Oh My Posh Apple glyph (a Nerd Font codepoint) shows instead of a square with a question mark.
- Give Terminal.app the repository's Catppuccin Macchiato palette (blue accent `#8aadf4`) so its
  background, foreground, cursor, selection and 16 ANSI colors match the other terminals.
- Track the configuration in the repository as a Terminal.app profile file, so a new Mac can be set
  up from the repo instead of by hand.
- Deploy the profile with a user-run Task target, `task terminal:sync`, following the
  `task codex:sync` pattern: dry run by default, writes only with `ARGS='--apply'`. This is how the
  profile reaches this machine and any other Mac.
- Make setting the profile as Terminal.app's default an explicit, separate opt-in on that target.
- Document the deploy flow, rollback and how to make the profile the default.
- Document known Terminal.app limits (no 24-bit color) so the remaining visual differences are
  understood and not mistaken for drift.

## Non-Goals

- Letting an agent, bootstrap script, install script, shell init or any other flow import the
  profile or touch `~/Library/Preferences/com.apple.Terminal.plist`. Only the user, running
  `task terminal:sync ARGS='--apply'` themselves, may do that.
- Stowing anything for Terminal.app. Its settings are not file-based dotfiles and cannot be linked,
  so Stow is not the deploy mechanism.
- Installing the font. `font-jetbrains-mono-nerd-font` is already managed by the Brewfile and
  installed on the primary machine.
- Changing Alacritty, Ghostty, Oh My Posh, or any other tool's theme or font.
- Supporting iTerm2 or any terminal other than Terminal.app in this PRD.
- Working around Terminal.app's lack of 24-bit color (for example by changing hex colors in omp or
  nvim to ANSI names).

## User Stories

- As the user, I want the Apple glyph in my Oh My Posh prompt to render in Terminal.app so that the
  prompt looks the same as in Alacritty and Ghostty.
- As the user, I want Terminal.app to use Catppuccin Macchiato so that background and ANSI colors
  match my other terminals.
- As the user, I want the profile stored in this repository so that I can recreate the setup on a new
  Mac.
- As the user, I want a `task terminal:sync` that previews by default and only changes Terminal.app
  with `--apply`, so that deploying to this machine or another Mac is one reviewed command.

## Constraints

- **Platform:** macOS only. Lives under `stow/macos/`; nothing is added to `stow/common/`.
- **Format:** a Terminal.app `.terminal` profile (XML property list) containing archived `NSColor`
  and `NSFont` values. It can be produced by a script, but the committed file is the source of truth.
- **Font:** `JetBrainsMono Nerd Font`, size 13, matching `config.ghostty`. The exact PostScript name
  must be verified against the installed font during architecture, not guessed.
- **Deploy:** `task terminal:sync` runs a script under `scripts/` (like `scripts/codex-sync.sh`).
  It is macOS-only and refuses on Arch and Debian using the repo's OS detection. The exact import
  and set-default mechanism is decided in architecture.
- **Palette:** every color is an official Catppuccin Macchiato value, mapped to the same ANSI slots
  as `stow/common/alacritty/.config/alacritty/catppuccin-macchiato.toml` and the Ghostty theme.
- **Terminal.app limit:** no 24-bit color. Hex colors from omp, nvim and bat are approximated to
  256 colors. The profile fixes the background, foreground and ANSI slots only.
- **Privacy:** the profile contains colors and a font name only. No hostnames, paths or user names.
- **Workflow:** follows PRD → Architecture → Plan → Build → Review. A new package triggers the
  status-sync rule (`AGENTS.md` §2 and `CLAUDE.md`, same commit).

## Safety Requirements

- Must be a dry run by default: without `--apply`, `task terminal:sync` reads state and prints what
  it would do, and writes nothing.
- Must change the live Terminal.app configuration only under `--apply`, and only when the user runs
  it. An agent never runs `--apply`; it shows the command marked `⚠️  MANUAL STEP`.
- Must set the default profile only under a separate explicit flag, never as a side effect of
  `--apply`.
- Must not overwrite, rename or delete the user's existing profiles, including "Clear Dark". It may
  only add or update the profile it owns, `Catppuccin Macchiato`.
- Must refuse to run on non-macOS systems and when Terminal.app's preferences are not present.
- Must not call `task terminal:sync` from any bootstrap, install, shell init or other script.
- Must not use Stow for this package, and must not touch any file outside the repository except the
  Terminal.app preferences under `--apply`.
- Must give a way back: the guide explains how to switch the default profile back to the previous one
  and delete the imported profile in Terminal.app.

## Acceptance Criteria

- [ ] A `Catppuccin Macchiato.terminal` profile is committed under `stow/macos/terminal/` and parses
      as a valid property list (`plutil -lint`).
- [ ] The profile sets `JetBrainsMono Nerd Font` size 13, with the PostScript name verified.
- [ ] Background, foreground, cursor, selection and all 16 ANSI colors equal the Macchiato values
      used by the Alacritty theme, checked by a script against that file.
- [ ] After `task terminal:sync ARGS='--apply'`, the Oh My Posh Apple glyph renders in Terminal.app.
- [ ] After the same step, the background is `#24273a` and text is `#cad3f5`.
- [ ] `task terminal:sync` exists in `Taskfile.yml`, backed by a script under `scripts/`, and is
      listed by `task --list`.
- [ ] `task terminal:sync` without arguments changes nothing and reports whether the profile is
      present and which profile is the default.
- [ ] `task terminal:sync ARGS='--apply'` imports the profile and leaves every other profile and
      the default untouched; re-running it does not create a duplicate profile.
- [ ] Setting the default needs a separate explicit flag and is documented.
- [ ] On Arch or Debian the target exits with a clear message and changes nothing.
- [ ] A guide under `docs/guides/` documents the deploy flow (dry run, apply, set default),
      rollback and the 24-bit color limitation, with every live-system command marked as a manual
      step.
- [ ] The website is updated in the same change: `website/features/terminal.md` covers Terminal.app
      and the `task terminal:sync` flow, `website/features/scripts.md` lists the new script, and
      `website/features/packages.md` lists the package if it belongs there. `mkdocs build --strict`
      passes.
- [ ] `stow/macos/terminal/` is not linked into `$HOME`, and its Stow behavior is documented
      (ignored, same pattern as `stow/common/codex`).
- [ ] Both status blocks (`AGENTS.md` §2 and `CLAUDE.md`) are updated in the same commit.
- [ ] The macOS-only scope is stated, and no Arch or Debian file changes.
- [ ] No secrets, private hostnames or machine-specific paths appear in the diff.

## Out of Scope

- Terminal.app window size, opacity, blur, bell, tab behavior and keyboard mappings.
- Option-as-Alt (Meta) mapping and the Alacritty/Ghostty key bindings.
- Shell command, login-shell flags and the Terminal.app startup command (Terminal.app already runs
  the user's login shell).
- A `doctor.sh` check for the Terminal.app profile.
- Running the sync automatically, on a schedule, or as part of any other task.
- Syncing back changes made in the Terminal.app GUI into the repository.
