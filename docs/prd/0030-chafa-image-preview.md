# PRD: Image Preview in the Terminal with chafa

**Number:** 0030
**Status:** Approved
**Date:** 2026-10-19

## Problem Statement

`cat` is aliased to `bat`, and suffix aliases open `.md`, `.txt` and `.log` files in `bat` when the
file name is typed alone (`stow/common/zsh/.config/zsh/aliases.zsh`). Image files have no such path:
`cat photo.png` prints binary noise, and typing `photo.png` alone does nothing useful.

[chafa](https://github.com/hpjansson/chafa) renders images in the terminal. It picks the best output
the terminal supports: kitty graphics, sixels or iTerm2 inline images, falling back to Unicode
symbol art ("ANSI art") otherwise (`chafa(1)`, `-f/--format`). Ghostty supports the kitty graphics
protocol, so it shows real pixels. Alacritty has no image protocol, so chafa draws symbol art there
instead of failing. An earlier idea to adopt chafa was dropped on the belief that Alacritty could
not show images at all. The symbol-art fallback removes that blocker.

## Goals

- chafa is listed for installation on macOS, Arch and Debian in the existing package manifests.
- `cat` keeps its current `bat` behaviour for every non-image file, and sends image files to chafa.
- When no argument is an existing image file, all arguments go to `bat` exactly as given, in one
  call. This is today's behaviour, so `bat` options with values (`-l md`, `-r 1:20`, `--theme X`)
  and `bat`'s handling of `--` and names starting with `-` are unchanged.
- When at least one argument is an existing image file, each file is routed separately, in the order
  given: images to chafa, other files to `bat`. Example: `cat photo.png notes.md` shows the image,
  then the Markdown.
- When `bat` is not on `PATH`, the text path uses the real `cat`, as today.
- Typing an image file name alone (e.g. `photo.png`) shows it with chafa, like `notes.md` opens in
  `bat` today.
- Images are capped to the terminal height, leaving the prompt visible, so a large image never
  scrolls off-screen.
- Animated GIFs show a still frame (`--animate off`).
- Inside herdr running in Ghostty, images render as pixels, as they do in plain Ghostty.
- Image extensions: `png`, `jpg`, `jpeg`, `gif`, `tif`, `tiff`, `webp`. `cat` matches them
  case-insensitively. Suffix aliases cover lowercase and uppercase (`photo.png`, `PHOTO.PNG`); mixed
  case such as `Photo.Png` is not covered, because zsh suffix aliases are case-sensitive.
- Everything is guarded: a shell without chafa behaves exactly as it does today.

## Non-Goals

- BMP. chafa has no BMP loader of its own; it decodes BMP on macOS only through CoreGraphics. The
  Linux build's loader list (`AVIF GIF JPEG JXL PNG QOI SVG TIFF WebP XWD`) has no BMP.
- Video, PDF, SVG or AVIF preview (SVG and AVIF depend on per-distro chafa build options).
- GIF animation.
- Image previews in fzf, fzf-tab, Neovim or file managers.
- Changing Ghostty, Alacritty or herdr configuration.
- herdr running inside Alacritty. The operator runs herdr only inside Ghostty.
- Supporting an apt-installed `batcat` on Debian. Debian machines that use Homebrew on Linux get
  `bat` under its normal name from `packages/Brewfile`; the text path uses `bat` wherever it is on
  `PATH`.
- Configuring chafa itself (no chafa config file or stow package).

## User Stories

- As the operator, I want `cat photo.png` to show the image so that I can check a picture without
  leaving the terminal.
- As the operator, I want to type `photo.png` alone to view it, the same way `notes.md` opens in
  `bat`.
- As the operator, I want `cat a.png notes.md` to show both files correctly in order.
- As the operator, I want `cat photo.png > copy.png` and `cat photo.png | other-tool` to keep
  passing the raw bytes, so that scripts and pipes are not broken.
- As the operator on Alacritty or over SSH, I want a readable symbol-art fallback instead of garbage.

## Scope

- `stow/common/zsh/.config/zsh/aliases.zsh` — replace `alias cat='bat'` with routing logic, and add
  image suffix aliases.
- `packages/Brewfile`, `packages/arch/packages.txt`, `packages/debian/packages.txt` — add `chafa`.
- `stow/common/zsh/README.md` and `docs/shell-dependencies.md` — document the behaviour and the new
  optional dependency.
- `docs/guides/zsh-setup.md`, `docs/guides/packages-setup.md`, `website/usage/aliases.md`,
  `website/features/shell.md` and `website/features/packages.md` — update where they describe
  `cat`, the suffix aliases or the package lists.
- `scripts/check-zsh-deps.sh` (`task deps:check:zsh`) — report chafa as an optional tool, never as
  a failure.
- No new stow package, so no status-block change.

## Constraints

- Platforms: macOS (Homebrew `chafa`), Arch (`chafa` in `extra`, 1.18.x) and Debian trixie
  (`chafa` 1.14.5 from apt, section `graphics`, or Homebrew on Linux). The raster extension set must
  decode on all three.
- herdr 0.9.5 renders the kitty graphics protocol itself in compatible outer terminals, on by
  default (`[terminal] kitty_graphics`, herdr.dev/docs/configuration). Inside a herdr pane,
  `TERM=xterm-256color` and `TERM_PROGRAM=herdr`. chafa's `--passthrough` targets only `screen`
  and `tmux`, so it does not apply.
- Tested 2026-10-19 (chafa 1.18.3, herdr 0.9.5, Ghostty on macOS): herdr answers a kitty graphics
  query (`\e_Gi=31;OK`), but chafa still picks symbols inside herdr with `--probe auto`, `--probe on`
  and `--probe-mode ctty`. With `TERM_PROGRAM=ghostty` or `-f kitty`, chafa emits kitty graphics and
  herdr shows real pixels. So inside herdr the routing must force kitty output; a pane cannot tell
  which outer terminal herdr runs in.
- When stdout is not a terminal, chafa still writes symbol art with escape sequences, not the input
  bytes (tested). The raw-bytes safety requirement therefore needs an explicit check in the routing.
- Shared zsh content stays portable: no OS-specific branches in `aliases.zsh`.
- Option handling: `bat` options such as `-n` or `-p` keep working for text files. Images are shown
  without passing `bat` options to chafa.
- `cat` with no file argument (stdin) keeps today's behaviour.
- Existing suffix aliases (`md`, `txt`, `log`) are unchanged.
- `alias cat='bat'` must be removed before a `cat` function is defined: zsh expands an alias while
  it parses a function definition of the same name.
- SSH does not forward `TERM_PROGRAM` by default, so chafa on a server reached with plain `ssh`
  from a herdr pane gets symbols (accepted, Resolved Question 5).
- Remote herdr sessions (`herdr --remote`) behave like local herdr. Tested 2026-10-19 on a Debian
  server (herdr 0.9.3 server, chafa 1.18.3 from Homebrew on Linux) viewed from local herdr 0.9.5 in
  Ghostty: a remote pane has `TERM_PROGRAM=herdr`, chafa auto-detection picks symbols, and
  `-f kitty` shows real pixels in the local Ghostty. The `TERM_PROGRAM=herdr` rule therefore covers
  remote sessions too. Timing on a terminal: 0.22 s auto, 0.44 s kitty.

## Safety Requirements

- When stdout is not a terminal (redirect or pipe), image files are written as raw bytes, never
  as chafa output, so `cat` stays safe in pipes and scripts.
- Agents and scripts that run `cat` with captured output must see unchanged byte output.
- No stow run, no `$HOME` change, no `--adopt`. Package installation stays a manual user step.
- No new file outside the existing `zsh` package and the package manifests.

## Acceptance Criteria

- [ ] `chafa` is listed in `packages/Brewfile`, `packages/arch/packages.txt` and
      `packages/debian/packages.txt`, each in that file's existing style.
- [ ] In an interactive Ghostty shell, `cat photo.png` shows the image as pixels.
- [ ] In herdr inside Ghostty, `cat photo.png` shows the image as pixels.
- [ ] In a remote herdr session viewed from Ghostty, `cat photo.png` shows the image as pixels.
- [ ] A tall image fits within the terminal height and the prompt stays visible after it.
- [ ] `cat anim.gif` shows one still frame and returns to the prompt without `Ctrl-C`.
- [ ] In Alacritty, `cat photo.png` shows symbol art and does not print binary noise.
- [ ] `cat photo.png notes.md` shows the image, then the Markdown rendered by `bat`.
- [ ] `cat -n notes.md` behaves exactly as `bat -n notes.md` does today.
- [ ] `cat -l md notes.txt` behaves exactly as `bat -l md notes.txt` does today.
- [ ] With `bat` not on `PATH`, `cat notes.md` prints the file as the real `cat` does.
- [ ] `cat photo.png | cmp - photo.png` succeeds, and
      `t=$(mktemp) && cat photo.png > "$t" && cmp "$t" photo.png; rm -f "$t"` succeeds.
- [ ] Typing `photo.png` and `PHOTO.JPG` alone shows the image.
- [ ] `cat Photo.Png` shows the image (case-insensitive `cat` routing).
- [ ] With chafa removed from `PATH`, `cat` and the suffix aliases behave exactly as before this
      change.
- [ ] `zsh -n` passes for `aliases.zsh`, and a fresh `zsh -ic ''` exits `0`.
- [ ] The zsh README and `docs/shell-dependencies.md` document chafa as an optional dependency.
- [ ] Every document listed in Scope matches the new behaviour.
- [ ] `task deps:check:zsh` reports chafa as optional and does not fail without it.

## Resolved Questions

1. **herdr.** herdr renders kitty graphics by default, so no passthrough is needed. chafa's own
   detection fails inside herdr (see Constraints), so the routing forces kitty output when
   `TERM_PROGRAM=herdr`. Forcing kitty was confirmed to show pixels in herdr on Ghostty. herdr inside
   Alacritty is not supported (Non-Goals).
2. **Debian `bat`.** Debian servers use Homebrew on Linux and run `bat` under its normal name, so the
   text path is the same `bat` on every platform. Only an apt-installed `batcat` stays unsupported.
3. **GIF animation.** Still frame (`--animate off`).
4. **Image size.** Capped so the image fits in the terminal height with the prompt visible. The plan
   picks the exact `--size` value.
5. **SSH to Debian servers.** Symbol-art fallback is acceptable when chafa cannot detect Ghostty
   over SSH.
6. **Suffix alias case.** Lowercase and uppercase are registered; mixed case is not covered.
7. **BMP.** Dropped: it decodes only on macOS (see Non-Goals).
8. **Debian apt chafa 1.14.5.** The plan must check on a Debian machine that apt's chafa accepts the
   chosen flags (`-f kitty`, `-s`, `--animate off`). Machines on Homebrew on Linux get 1.18.x.

## Out of Scope

- Everything under Non-Goals.
- Automatic installation of chafa by any script or task.
- A dedicated `imgcat`-style command name (iTerm2 ships a tool with that name). The viewer function
  name is a plan decision.
- Upstream changes to chafa, bat, Ghostty or herdr.
