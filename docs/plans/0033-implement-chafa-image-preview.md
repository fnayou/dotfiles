# Plan: Implement chafa Image Preview

**Number:** 0033
**Status:** Draft
**Date:** 2026-10-19
**PRD:** [0030-chafa-image-preview](../prd/0030-chafa-image-preview.md) (Approved)
**Architecture:** none — PRD 0030 adds no package or layout decision (reviews 0090, 0091)
**Plan review:** [0092](../reviews/0092-chafa-image-preview-plan-review.md)

## Objective

Make `cat` and image suffix aliases show image files with chafa, keep every other `cat` call
unchanged, list chafa in the package manifests, and document it.

## Assumptions

- PRD 0030 is Approved. Its Constraints record the facts this plan relies on, tested on 2026-10-19:
  - Inside herdr (local or `herdr --remote`), chafa auto-detection picks symbols, and `-f kitty`
    shows pixels in Ghostty.
  - When stdout is not a terminal, chafa writes symbol art, while `bat` passes image bytes through
    unchanged (`bat --paging=never t.png | cmp - t.png` succeeds).
  - zsh suffix aliases are case-sensitive.
- Verified while drafting this plan (prototype in a scratch directory, chafa 1.18.3, zsh on macOS):
  - chafa does **not** accept `--`; it tries to open a file named `--`. Paths that start with `-`
    must be passed as `./-name`.
  - `unalias cat` inside the same `if … fi` block as `cat() { … }` does not help: zsh parses the
    whole block, including alias expansion, before running it, and fails with
    `defining function based on alias 'cat'`. The `function cat { … }` form avoids this, because
    the name is not in command position.
  - `-s x<rows>` caps only the height; `--animate off` shows a still frame.
- chafa 1.18.3 is installed on the macOS machine (Homebrew). Docker is available for the Debian
  check in Task 1.
- Work happens on branch `docs/chafa-image-preview-prd` (draft PR #85).

## Ordered Tasks

### Task 1 — Check Debian's apt chafa (1.14.5) accepts the flags

Debian trixie ships chafa 1.14.5; machines on Homebrew on Linux get 1.18.x. The check runs in a
throwaway container: chafa is installed only inside it, the repo images are mounted read-only, and
nothing is written to the repo. The host does change: Docker pulls the `debian:trixie` image.

⚠️  MANUAL STEP — pulls the debian:trixie image into Docker on this machine (remove later with `docker image rm debian:trixie`)
```bash
# macOS (Docker Desktop)
docker run --rm -v "$PWD/website/assets/images:/img:ro" debian:trixie bash -c '
  set -euo pipefail
  apt-get update -qq
  apt-get install -y -qq chafa >/dev/null
  chafa --version | head -1
  chafa -f kitty --animate off -s x10 /img/dotfiles-readme-banner.png > /tmp/kitty.out
  head -c 3 /tmp/kitty.out | od -c | head -1
  chafa --animate off -s x10 /img/dotfiles-readme-banner.png > /tmp/symbols.out
  wc -l < /tmp/symbols.out
  if chafa --animate off -s x10 ./--missing.png 2>/dev/null; then
    echo "missing-file: accepted"; exit 1
  fi
  echo "missing-file: rejected"'
echo "exit=$?"
```

Expect: `Chafa version 1.14.5`, an `od` line starting `033   _   G` (kitty graphics), `10`,
`missing-file: rejected`, and `exit=0`. Any rejected flag ends the script early with a non-zero
`exit=`. **Stop and report** in that case: the block in Task 2 would then need a version-dependent
option list, which this plan does not cover.

### Task 2 — Add the image preview block to `aliases.zsh`

Edit `stow/common/zsh/.config/zsh/aliases.zsh`. Insert this block after the existing
`# --- Suffix aliases (bat) ---` block and before `# --- Functions ---`. Leave the bat block
unchanged: without chafa, `alias cat='bat'` stays in effect.

```zsh
# --- Image preview (chafa) ---
# cat sends image files to chafa and everything else to bat (or the real cat
# when bat is absent). Calls without an image, and every call whose output is
# not a terminal, keep today's behaviour exactly.
if command -v chafa >/dev/null 2>&1; then
  _cat_text() {
    if (( $+commands[bat] )); then bat "$@"; else command cat "$@"; fi
  }

  _is_image() {
    [[ -f $1 ]] || return 1
    case ${1:e:l} in
      (png|jpg|jpeg|gif|tif|tiff|webp) return 0 ;;
    esac
    return 1
  }

  # Show image files with chafa. herdr answers kitty graphics but chafa cannot
  # detect it there, so force kitty inside herdr. Height leaves the prompt visible.
  imgview() {
    if [[ ! -t 1 ]]; then _cat_text "$@"; return; fi
    local -a opts=(--animate off -s "x$(( LINES > 9 ? LINES - 4 : LINES ))")
    [[ $TERM_PROGRAM == herdr ]] && opts=(-f kitty $opts)
    local f
    for f in "$@"; do
      [[ $f == -* ]] && f=./$f   # chafa reads `--` as a file name
      chafa $opts "$f"
    done
  }

  unalias cat 2>/dev/null       # drop the bat alias; `function cat` avoids parse-time alias expansion
  function cat {
    local a has_image=0
    for a in "$@"; do _is_image "$a" && { has_image=1; break; }; done
    if (( ! has_image )) || [[ ! -t 1 ]]; then _cat_text "$@"; return; fi
    local -a bat_opts files
    for a in "$@"; do
      if [[ $a == -* ]] && ! _is_image "$a"; then bat_opts+=("$a"); else files+=("$a"); fi
    done
    for a in "${files[@]}"; do
      if _is_image "$a"; then imgview "$a"; else _cat_text "${bat_opts[@]}" "$a"; fi
    done
  }

  for _ext in png jpg jpeg gif tif tiff webp; do
    alias -s $_ext=imgview ${(U)_ext}=imgview
  done
  unset _ext
fi
```

Design notes, for the reviewer:

- **No image argument, or output not a terminal:** one `_cat_text "$@"` call with all arguments,
  which is today's `bat "$@"`. `bat` passes image bytes unchanged in a pipe, so pipes and redirects
  stay byte-exact.
- **Mixed call:** arguments that start with `-` and are not image files go to every `bat` call as
  options; the rest are routed per file, in order. Known limit: an option whose value is a separate
  word (`-l md`) in a call that **also** has an image would treat `md` as a file. Use the attached
  form (`--language=md`) there. Calls without an image are unaffected.
- **Size:** `LINES - 4` keeps a two-line prompt and a blank line visible. Below 10 rows, the full
  height is used.
- **Name:** `imgview` avoids iTerm2's `imgcat`.

### Task 3 — Add chafa to the package manifests

Follow each file's existing optional-tool style:

- `packages/Brewfile` — new section after `# --- Network speed test ---`:

  ```ruby
  # --- Image preview ---
  # Optional — lets `cat` and image suffix aliases in the zsh package show images.
  brew "chafa"
  ```

- `packages/arch/packages.txt` — new section after the network speed test section:

  ```text
  # --- Image preview (pacman, extra repo) ---
  # Optional — lets `cat` and image suffix aliases in the zsh package show images.
  # sudo pacman -S chafa
  ```

- `packages/debian/packages.txt` — new section in the apt part:

  ```text
  # --- Image preview (apt) ---
  # Optional — lets `cat` and image suffix aliases in the zsh package show images.
  # trixie ships chafa 1.14.5; Homebrew on Linux gets 1.18.x via packages/Brewfile.
  # sudo apt install chafa
  ```

### Task 4 — Report chafa as optional in `scripts/check-zsh-deps.sh`

Add after the shell-tier loop and before the zinit check. It never sets `FAILED`:

```bash
# --- Check optional shell-tier tools (reported, never a failure) ---
for tool in chafa; do
  if command -v "$tool" >/dev/null 2>&1; then
    echo "PASS: $tool"
  else
    echo "INFO: $tool (optional, not installed — image preview in cat and suffix aliases)"
  fi
done
```

Update the header comment: "Exits 1 if any required tool is missing; optional tools are reported
with INFO."

### Task 5 — Document in the zsh package README

Add a `## Image preview (chafa)` section to `stow/common/zsh/README.md` before
`## Where machine-specific setup goes`. Cover, briefly:

- `cat` routing (images to chafa, others to `bat`; calls without an image unchanged; pipes keep raw
  bytes).
- Suffix aliases for `png jpg jpeg gif tif tiff webp`, lowercase and uppercase only.
- Terminal behaviour: Ghostty pixels; herdr forces kitty; Alacritty and plain SSH get symbol art.
- Still frame for GIFs; height capped to the terminal.
- The mixed-call `-l md` limit and the `--language=md` workaround.

### Task 6 — Update `docs/shell-dependencies.md`

- Add a `chafa` row to the tool table: tier `shell (optional)`, source `packages/Brewfile`, Arch
  `pacman`.
- Note that `scripts/check-zsh-deps.sh` reports chafa as optional (INFO), never as a failure.

### Task 7 — Update the guides

- `docs/guides/zsh-setup.md:82` — extend the bat row, or add a chafa row: `aliases.zsh` — image
  routing for `cat` and image suffix aliases, guarded by `command -v chafa`.
- `docs/guides/packages-setup.md`:
  - add a `chafa` row to the optional tools table (after `bat`): "terminal image viewer (`cat`
    and suffix aliases for images)";
  - add `chafa` after `bat` in the "This installs all tools in one step" sentence (line 67), in
    `sudo pacman -S git stow go-task git-cliff fzf zoxide eza bat` (line 99), in
    `sudo apt install git stow fzf zoxide eza bat` (line 157), and as one line in each of the three
    "individual tools" lists (`brew install chafa`, `sudo pacman -S chafa`, `sudo apt install chafa`).
- `Taskfile.yml` — `task deps:arch` and `task deps:debian` print the install line as text. Add
  `chafa` after `bat` in both:
  - line 191: `echo "  sudo pacman -S git stow go-task git-cliff fzf zoxide eza bat \\"`
    → `echo "  sudo pacman -S git stow go-task git-cliff fzf zoxide eza bat chafa \\"`
  - line 230: `echo "  sudo apt install git stow fzf zoxide eza bat \\"`
    → `echo "  sudo apt install git stow fzf zoxide eza bat chafa \\"`
  `task deps:brew` needs no change: it points at `packages/Brewfile`.

### Task 8 — Update the website

- `website/usage/aliases.md` — in "File viewing (bat)", add rows: `cat` with images → chafa, and
  image suffix aliases → `imgview`; one sentence that calls without an image are unchanged.
- `website/features/shell.md:66` — add a bullet: `chafa` lets `cat` and image file names show images.
- `website/features/packages.md:12-13` — leave the bat sentence unchanged; it describes text files
  only, which stays true.

### Task 9 — Automated validation

Run from the repo root:

```bash
zsh -n stow/common/zsh/.config/zsh/aliases.zsh
zsh -ic '' >/dev/null; echo "exit=$?"
zsh -ic 'whence -w cat imgview; alias -s | grep -c imgview'   # cat: function, imgview: function, 14
bash -n scripts/check-zsh-deps.sh && bash scripts/check-zsh-deps.sh | grep chafa
```

Pipe and redirect safety with the real tools (run in a terminal, `zsh -i`):

```bash
p=website/assets/images/dotfiles-readme-banner.png
cat "$p" | cmp - "$p" && echo pipe-ok
t=$(mktemp) && cat "$p" > "$t" && cmp "$t" "$p" && echo redirect-ok
```

The redirect target is a `mktemp` file in `$TMPDIR`. The plan does not delete it: `rm` outside the
repository is forbidden (`.claude/rules/safety.md`), and the OS clears `$TMPDIR`.

Routing with stub commands under a pseudo-terminal (no real image output needed). Create the
harness in a temporary directory:

```bash
D=$(mktemp -d)
mkdir -p "$D/bin" "$D/nobat" "$D/nochafa" "$D/w"
printf '#!/bin/sh\necho "CHAFA $*"\n' > "$D/bin/chafa"
printf '#!/bin/sh\necho "BAT $*"\n'   > "$D/bin/bat"
/bin/cp "$D/bin/chafa" "$D/nobat/chafa"
/bin/cp "$D/bin/bat" "$D/nochafa/bat"
chmod +x "$D"/bin/* "$D"/nobat/* "$D"/nochafa/*
: > "$D/w/a.png"; : > "$D/w/B.JPG"; : > "$D/w/Photo.Png"; : > "$D/w/n.md"; : > "$D/w/-x.png"
A="$PWD/stow/common/zsh/.config/zsh/aliases.zsh"
run() {  # $1 = stub dir, $2 = command line
  printf '%s\n' "PATH=$1:/usr/bin:/bin; LINES=40; alias cat=bat; source $A; cd $D/w" "$2" > "$D/cmd.zsh"
  env -u TERM_PROGRAM script -q /dev/null zsh -f "$D/cmd.zsh" </dev/null | tr -d '\r' | sed 's/\^D//g'
}
for c in 'cat n.md' 'cat -l md n.md' 'cat a.png n.md' 'cat -n a.png n.md' 'cat B.JPG' \
         'cat Photo.Png' 'TERM_PROGRAM=herdr cat a.png' 'cat -- -x.png' './a.png' './B.JPG'; do
  printf '[%s] => %s\n' "$c" "$(run "$D/bin" "$c" | tr '\n' ';')"
done
printf '[no bat] => %s\n' "$(run "$D/nobat" 'cat a.png n.md' | tr '\n' ';')"
printf '[no chafa] => %s\n' "$(run "$D/nochafa" 'whence -w cat; cat a.png; alias -s | grep -c imgview' | tr '\n' ';')"
```

Expected (prototype results):

| Command | Output |
|---|---|
| `cat n.md` | `BAT n.md` |
| `cat -l md n.md` | `BAT -l md n.md` |
| `cat a.png n.md` | `CHAFA --animate off -s x36 a.png;BAT n.md` |
| `cat -n a.png n.md` | `CHAFA --animate off -s x36 a.png;BAT -n n.md` |
| `cat B.JPG` | `CHAFA --animate off -s x36 B.JPG` |
| `cat Photo.Png` | `CHAFA --animate off -s x36 Photo.Png` |
| `TERM_PROGRAM=herdr cat a.png` | `CHAFA -f kitty --animate off -s x36 a.png` |
| `cat -- -x.png` | `CHAFA --animate off -s x36 ./-x.png` |
| `./a.png`, `./B.JPG` | `CHAFA --animate off -s x36 ./a.png` (and `./B.JPG`) |
| no bat: `cat a.png n.md` | `CHAFA … a.png` then the real `cat` of `n.md` (empty) |
| no chafa | `cat: alias;BAT a.png;0` — the bat alias stays, no image suffix alias |

The `aliases.zsh` file also defines `ls`/`ll` aliases and `chpwd`; the stub `PATH` has no `eza`, so
those take their fallback branch. The harness stays in its `mktemp -d` directory under `$TMPDIR`;
the plan does not delete it (no `rm` outside the repository), and the OS clears `$TMPDIR`.

### Task 10 — Operator visual checks

The Builder cannot see terminal output. The operator confirms, in a fresh shell (`exec zsh`) after
the change is live through the stowed `zsh` package:

1. Plain Ghostty: `cat p.png` shows pixels; `cat Photo.Png` (copy with that name) too.
2. herdr in Ghostty: `cat p.png` shows pixels.
3. Remote herdr session (`herdr --remote <machine>`) viewed from Ghostty, on a machine with chafa
   and the updated dotfiles: `cat p.png` shows pixels.
4. Alacritty: `cat p.png` shows symbol art, no binary noise.
5. A tall image fits; the prompt stays visible after it.
6. An animated GIF shows one frame and returns to the prompt without `Ctrl-C`.
7. Typing `p.png` and `P.PNG` alone shows the image.
8. `cat -n notes.md` and `cat -l md notes.txt` look exactly as before.

### Task 11 — Commit

Small commits, Conventional Commits, no AI attribution, audit each staged diff for secrets:

1. `docs(plans): add plan 0033 for chafa image preview` — this plan, `docs/plans/README.md`.
2. `feat(zsh): show images with chafa from cat and suffix aliases` — `aliases.zsh`.
3. `feat(packages): add chafa to the package manifests` — the three manifests.
4. `feat(deps): report chafa as an optional shell tool` — `scripts/check-zsh-deps.sh`.
5. `docs: document chafa image preview` — README, `docs/shell-dependencies.md`, guides, website,
   and the `Taskfile.yml` install lines.

## Files Affected

- `stow/common/zsh/.config/zsh/aliases.zsh` — modified
- `packages/Brewfile` — modified
- `packages/arch/packages.txt` — modified
- `packages/debian/packages.txt` — modified
- `scripts/check-zsh-deps.sh` — modified
- `stow/common/zsh/README.md` — modified
- `docs/shell-dependencies.md` — modified
- `docs/guides/zsh-setup.md` — modified
- `docs/guides/packages-setup.md` — modified
- `website/usage/aliases.md` — modified
- `website/features/shell.md` — modified
- `Taskfile.yml` — modified (`deps:arch`, `deps:debian` install lines)
- `docs/plans/README.md` — modified (index row)
- `docs/plans/0033-implement-chafa-image-preview.md` — created

No file is deleted. No new file outside `docs/plans/`.

## Safety Checks

- Before starting: `git status` is clean on `docs/chafa-image-preview-prd`; the plan is
  `**Status:** Approved`.
- No `stow` run, no `--adopt`, no `rm`/`mv`/`ln -s` against `$HOME`. `aliases.zsh` is already
  linked into `$HOME` through the stowed `zsh` package, so the edit is live in new shells without
  any stow command.
- No package is installed on the host by any script or task. Task 1 installs chafa only inside a
  throwaway container; it is a marked manual step because Docker pulls `debian:trixie`.
- No `rm` outside the repository: Task 9 leaves its temporary files to the OS.
- The block is guarded by `command -v chafa`; without chafa the shell is unchanged.
- No status-block change: no package is added, removed or first stowed.
- Every staged diff is checked for hostnames, user paths and secrets.

## Validation Commands

```bash
git status
git diff --stat                                   # only the files listed above
zsh -n stow/common/zsh/.config/zsh/aliases.zsh
zsh -ic '' >/dev/null; echo "exit=$?"
zsh -ic 'whence -w cat imgview'
bash scripts/check-zsh-deps.sh | grep chafa
bash scripts/check-decisions.sh
```

Plus the Task 9 pipe, redirect and stub routing checks.

## Rollback Strategy

All changes are edits to tracked files.

1. Before commit: `git checkout -- <file>` for any file.
2. After commit, before push: `git reset HEAD~1` for the last commit.
3. After push: `git revert <sha>` for the `feat(zsh)` commit restores `alias cat='bat'` at once in
   new shells. Existing shells pick it up with `exec zsh`.
4. chafa itself stays installed; removing it is a manual step (`brew uninstall chafa`,
   `sudo pacman -R chafa`, `sudo apt remove chafa`), and the guard makes the shell ignore it anyway.

## Completion Criteria

- [ ] Task 1 confirms Debian chafa 1.14.5 accepts `-f kitty`, `-s x<rows>` and `--animate off`.
- [ ] Every Task 9 check passes with the expected outputs.
- [ ] The operator confirms every Task 10 visual check.
- [ ] Every PRD 0030 acceptance criterion is met.
- [ ] Every file in "Files Affected" matches the new behaviour; no other file changed.
- [ ] Implementation review passes with no blocking issue.
