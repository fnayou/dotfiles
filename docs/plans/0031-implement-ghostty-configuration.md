# Plan: Implement Ghostty Configuration

**Number:** 0031
**Status:** Approved
**Date:** 2026-10-17
**PRD:** [0028-ghostty-configuration](../prd/0028-ghostty-configuration.md)
**Architecture:** [0026-ghostty-configuration-architecture](../architecture/0026-ghostty-configuration-architecture.md)

## Objective

Add the common Stow package `stow/common/ghostty/` and the macOS-only Stow package
`stow/macos/ghostty/` exactly as specified in Architecture 0026, validate them without touching
`$HOME`, document them, and leave the real Stow dry-run and install to the operator.

## Assumptions

- PRD 0028 and Architecture 0026 are Approved by the operator, including the review 0081 fixes.
  Reviews 0080, 0081, and 0082 are Complete. Review 0082 has no blocking issue.
- Review 0082 suggestion 1 is applied in this plan. In a `( set -eu; … )` block, `set -e` ignores a
  failure on the left of `&&` or `||`. So every check below tests its exit code explicitly, prints
  `FAIL: …` and leaves the block with `exit 1`, and ends with one `PASS: …` line. **A missing
  `PASS:` line is a failure**, even if no `FAIL:` line was printed.
- Review 0082 suggestion 2 (rewrap PRD `:246`) is not part of this plan; the PRD is not edited.
- The work happens in the worktree lane `feat/ghostty-package`. All commands run from the root of
  that worktree. Git commands use `git -C "$REPO"` with:

  ```bash
  REPO="$(git rev-parse --show-toplevel)"
  ```

  Every block that uses `$REPO` repeats this line at its top, so it works in a shell that does
  not keep variables between blocks.

- Ghostty 1.3.1 is installed on macOS at `/Applications/Ghostty.app`. Validation uses
  `/Applications/Ghostty.app/Contents/MacOS/ghostty`. The binary is not on `PATH` on macOS.
- `$HOME/.config/ghostty` does not exist on the macOS machine. Task 1 confirms this.
- `$HOME/Downloads/ghosty.icns` (misspelled name) exists. Its SHA-256 is
  `6796c0f423a066009fef4f69ab7800a086627304fc633d3cba69a4ca173632ac`. It is read only, never moved
  or changed.
- The Builder never runs `stow` against `$HOME`, never writes to `$HOME`, never launches
  `Ghostty.app`, and never touches
  `~/Library/Application Support/com.mitchellh.ghostty/config.ghostty` or the app bundle.
  Fake-home blocks write only into their own `mktemp -d` directory, which is outside the repository
  and outside `$HOME` on macOS (`$TMPDIR`).
- Only the operator launches Ghostty, runs the numpad check, and runs the real dry-run and install.
  The operator's results are recorded in the implementation review (Task 24).
- **Plan decision — `stow/macos/.gitkeep` stays.** Reasons:
  1. It is not a package. Stow acts only on the package named on the command line, and
     `task list` lists directories only (`find … -type d`), so the marker is never linked and never
     listed.
  2. `stow/arch/.gitkeep` and `stow/debian/.gitkeep` stay. Keeping the macOS marker keeps the three
     platform directories uniform.
  3. If `stow/macos/ghostty/` is ever removed, `stow/macos/` stays tracked without a new commit.
  4. Removing it is a delete that the PRD and the architecture do not ask for.

  Consequence: pages that say `stow/macos/` holds "only `.gitkeep`" are reworded to say it holds
  `ghostty` (plus its `.gitkeep` marker), not that the marker is gone (Task 20).
- File content is copied exactly from Architecture 0026, "File Content". The Builder does not
  improvise content.

## Ordered Tasks

Each task names its files, commands, expected result, who runs it, and its rollback. The
Builder stops at the first result that differs from **Expected** and reports the raw output.

### Task 1 — Preflight (Builder)

Files: none. Read-only.

```bash
# macOS
REPO="$(git rev-parse --show-toplevel)"
git -C "$REPO" branch --show-current
git -C "$REPO" status --porcelain
for p in stow/common/ghostty stow/macos/ghostty docs/guides/ghostty-setup.md; do
  test ! -e "$p" && echo "PASS: absent $p" || echo "FAIL: exists $p"
done
test -f stow/macos/.gitkeep && echo "PASS: stow/macos/.gitkeep present" || echo "FAIL: no stow/macos/.gitkeep"
test ! -e "$HOME/.config/ghostty" && echo "PASS: ~/.config/ghostty absent" || echo "FAIL: ~/.config/ghostty exists"
/Applications/Ghostty.app/Contents/MacOS/ghostty --version | head -n 1
[ "$(shasum -a 256 "$HOME/Downloads/ghosty.icns" | cut -d' ' -f1)" = \
  6796c0f423a066009fef4f69ab7800a086627304fc633d3cba69a4ca173632ac ] \
  && echo "PASS: source icon sha256" || echo "FAIL: source icon sha256"
command -v stow >/dev/null && echo "PASS: stow found" || echo "FAIL: stow missing"
```

Expected: branch `feat/ghostty-package`; empty `status --porcelain`; seven `PASS:` lines and no
`FAIL:` line; Ghostty version line names `1.3.1`.

Then record the untouched state of the Application Support file and the app bundle (read-only):

```bash
# macOS
wc -c < "$HOME/Library/Application Support/com.mitchellh.ghostty/config.ghostty" | tr -d ' '
codesign --verify --deep --strict /Applications/Ghostty.app; echo "exit=$?"
```

Expected: `0`; `exit=0`. Both outputs are recorded in the implementation review (Task 24).

Rollback: nothing to undo.

### Task 2 — Create `stow/common/ghostty/.config/ghostty/config.ghostty` (Builder)

Files: `stow/common/ghostty/.config/ghostty/config.ghostty` — created.

Write the file with the exact content of Architecture 0026, "File Content → `config.ghostty`".
No numpad `keybind` line yet (Task 14 decides). Comments sit on their own lines.

```bash
tail -n 1 stow/common/ghostty/.config/ghostty/config.ghostty
grep -c '^keybind = ' stow/common/ghostty/.config/ghostty/config.ghostty
grep -c '^macos-' stow/common/ghostty/.config/ghostty/config.ghostty
```

Expected: `config-file = ?macos.ghostty`; `5`; `0`.

Rollback (uncommitted, new file):

```bash
REPO="$(git rev-parse --show-toplevel)"
git -C "$REPO" clean -n -- stow/common/ghostty/.config/ghostty/config.ghostty
```

⚠️  MANUAL STEP — review before running
```bash
REPO="$(git rev-parse --show-toplevel)"
git -C "$REPO" clean -f -- stow/common/ghostty/.config/ghostty/config.ghostty
```

### Task 3 — Create `stow/common/ghostty/.config/ghostty/themes/catppuccin-macchiato` (Builder)

Files: `stow/common/ghostty/.config/ghostty/themes/catppuccin-macchiato` — created.

Write the file with the exact content of Architecture 0026, "File Content →
`themes/catppuccin-macchiato`".

```bash
grep -c '^palette = ' stow/common/ghostty/.config/ghostty/themes/catppuccin-macchiato
grep -cE '^(theme|config-file) ' stow/common/ghostty/.config/ghostty/themes/catppuccin-macchiato
```

Expected: `16`; `0`.

Rollback: as Task 2, with this file's path.

### Task 4 — Create `stow/common/ghostty/.stow-local-ignore` (Builder)

Files: `stow/common/ghostty/.stow-local-ignore` — created.

```bash
/bin/cp -n stow/common/alacritty/.stow-local-ignore stow/common/ghostty/.stow-local-ignore
diff stow/common/alacritty/.stow-local-ignore stow/common/ghostty/.stow-local-ignore \
  && echo "PASS: ignore file matches alacritty" || echo "FAIL: ignore file differs"
```

Expected: `PASS: ignore file matches alacritty`.

Rollback: as Task 2, with this file's path.

### Task 5 — Create `stow/common/ghostty/README.md` (Builder)

Files: `stow/common/ghostty/README.md` — created.

Write the exact content of Architecture 0026, "Package `README.md`", including the line "On macOS,
also stow `stow/macos/ghostty` …". Its guide link resolves once Task 19 lands, on the same branch.

```bash
grep -c 'docs/guides/ghostty-setup.md' stow/common/ghostty/README.md
grep -c 'stow/macos/ghostty' stow/common/ghostty/README.md
```

Expected: `1`; `1`.

Rollback: as Task 2, with this file's path.

### Task 6 — Create `stow/macos/ghostty/.stow-local-ignore` (Builder)

Files: `stow/macos/ghostty/.stow-local-ignore` — created.

```bash
/bin/mkdir -p stow/macos/ghostty
/bin/cp -n stow/common/ghostty/.stow-local-ignore stow/macos/ghostty/.stow-local-ignore
diff stow/common/ghostty/.stow-local-ignore stow/macos/ghostty/.stow-local-ignore \
  && echo "PASS: macOS ignore file matches common" || echo "FAIL: macOS ignore file differs"
```

Expected: `PASS: macOS ignore file matches common`.

Rollback: as Task 2, with this file's path.

### Task 7 — Create `stow/macos/ghostty/.config/ghostty/macos.ghostty` (Builder)

Files: `stow/macos/ghostty/.config/ghostty/macos.ghostty` — created.

Write the exact content of Architecture 0026, "File Content →
`stow/macos/ghostty/.config/ghostty/macos.ghostty`".

```bash
grep -c '^macos-option-as-alt = true$' stow/macos/ghostty/.config/ghostty/macos.ghostty
grep -c '^macos-icon = custom$' stow/macos/ghostty/.config/ghostty/macos.ghostty
grep -c '^macos-custom-icon' stow/macos/ghostty/.config/ghostty/macos.ghostty
```

Expected: `1`; `1`; `0`.

Rollback: as Task 2, with this file's path.

### Task 8 — Copy the icon to `stow/macos/ghostty/.config/ghostty/Ghostty.icns` (Builder)

Files: `stow/macos/ghostty/.config/ghostty/Ghostty.icns` — created (binary, 152344 bytes). The
source `$HOME/Downloads/ghosty.icns` is only read.

The block refuses to run if the target already exists (file or symlink), so nothing is
overwritten. `/bin/cp -n` is a second guard.

```bash
# macOS
(
  set -eu
  SRC="$HOME/Downloads/ghosty.icns"
  DST="stow/macos/ghostty/.config/ghostty/Ghostty.icns"
  test -f "$SRC" || { echo "FAIL: source missing: $SRC"; exit 1; }
  test -d "$(dirname "$DST")" || { echo "FAIL: run Task 7 first"; exit 1; }
  if test -e "$DST" || test -L "$DST"; then echo "FAIL: target exists, not overwriting"; exit 1; fi
  /bin/cp -n "$SRC" "$DST" || { echo "FAIL: cp exit $?"; exit 1; }
  echo "PASS: icon copied"
)
ICNS=stow/macos/ghostty/.config/ghostty/Ghostty.icns
shasum -a 256 "$ICNS"
[ "$(shasum -a 256 "$ICNS" | cut -d' ' -f1)" = \
  6796c0f423a066009fef4f69ab7800a086627304fc633d3cba69a4ca173632ac ] \
  && echo "PASS: sha256" || echo "FAIL: sha256"
file "$ICNS"
file "$ICNS" | grep -q 'Mac OS X icon' && echo "PASS: file type" || echo "FAIL: file type"
```

Expected: `PASS: icon copied`; `shasum` prints
`6796c0f423a066009fef4f69ab7800a086627304fc633d3cba69a4ca173632ac`; `PASS: sha256`; `file`
reports `Mac OS X icon`; `PASS: file type`.

Rollback: as Task 2, with this file's path. The source in `~/Downloads` is never touched.

### Task 9 — Create `stow/macos/ghostty/README.md` (Builder)

Files: `stow/macos/ghostty/README.md` — created.

Write the exact content of Architecture 0026, "`stow/macos/ghostty/README.md`" (the inner content of
the four-backtick fence).

```bash
grep -c '6796c0f423a066009fef4f69ab7800a086627304fc633d3cba69a4ca173632ac' stow/macos/ghostty/README.md
grep -c 'macosicons.com' stow/macos/ghostty/README.md
grep -c 'Unknown' stow/macos/ghostty/README.md
grep -cE 'Ghostty\.icns|macos\.ghostty' stow/macos/ghostty/README.md
```

Expected: `1`; `1`; at least `1`; at least `2`.

Rollback: as Task 2, with this file's path.

### Task 10 — Read-only validation, checks 1, 2, 4, 5, 6 (Builder)

Files: none. Read-only. Commands are listed under **Validation Commands → Checks 1, 2, 4, 5, 6**.

Expected: as written there. Record every raw output for the implementation review, including
whether check 1 also loaded default config files (open Build question, Architecture 0026).

Rollback: nothing to undo.

### Task 11 — Fake-home validation, check 3 steps 1–3 (Builder)

Files: none in the repository. Writes only into a `mktemp -d` directory that the block removes on
exit. Commands are listed under **Validation Commands → Check 3**.

Expected: `PASS: check 3 step 1`, `PASS: check 3 step 2`, `PASS: check 3 step 3 [macOS]`. A
missing `PASS:` line is a failure.

Rollback: the `trap` removes the temporary directory. If a block was interrupted, it printed the
path; the operator removes it after looking at it. It is outside the repository and `$HOME`.

### Task 12 — Fake-home launch, check 7a: icon and `XDG_CONFIG_HOME` (operator)

Files: none in the repository. Launching `Ghostty.app` writes app state under `~/Library`; this
step does not claim to leave `$HOME` untouched. That is why only the operator runs it.

Before: quit Ghostty fully (Cmd+Q on every window). Confirm `~/.config/ghostty` is still absent
(Task 1), so a custom icon can come only from the fake home. Run the block from Alacritty or
Terminal.app, not from Ghostty, since Ghostty must be fully quit first.

Launching the GUI by running the bundle binary from a shell is not verified by PRD 0028 or
Architecture 0026. The block therefore ends with a neutral `DONE:` line, not `PASS:`; the operator
states explicitly whether a new Ghostty window opened. Do not switch to `open -na Ghostty.app --env
…`: `open` returns at once, so the `trap` would delete the fake home while Ghostty still reads it.

⚠️  MANUAL STEP — review before running
```bash
# macOS — operator only. Runs until Ghostty quits.
(
  set -eu
  test -d stow/common/ghostty || { echo "FAIL: run from the repository root"; exit 1; }
  test ! -e "$HOME/.config/ghostty" || { echo "FAIL: ~/.config/ghostty exists, result would be ambiguous"; exit 1; }
  FAKE_HOME="$(mktemp -d)"
  trap 'rm -rf "${FAKE_HOME:?}"' EXIT
  stow --dir=stow/common --target="${FAKE_HOME:?}" --no-folding ghostty \
    || { echo "FAIL: common stow exit $?"; exit 1; }
  stow --dir=stow/macos --target="${FAKE_HOME:?}" --no-folding ghostty \
    || { echo "FAIL: macOS stow exit $?"; exit 1; }
  echo "Fake home: ${FAKE_HOME:?}. Do Tasks 12 and 13 in the new window, then quit Ghostty (Cmd+Q)."
  XDG_CONFIG_HOME="${FAKE_HOME:?}/.config" /Applications/Ghostty.app/Contents/MacOS/ghostty \
    || echo "NOTE: ghostty exited with $?"
  echo "DONE: fake-home launch session ended"
)
```

In the new Ghostty window, check and write down:

0. Window: did a new Ghostty window open (yes or no)? If no, stop and record it; answers 1 to 5
   and Task 13 cannot be given.
1. Dock and app switcher icon: custom ("Ghostty Darken") or official. Custom means the
   `macos-custom-icon` default follows `XDG_CONFIG_HOME`. Official means it follows the literal
   `~` (or the icon did not load); Task 23 then settles the icon on the real stow.
2. Login shell: `[[ -o login ]] && echo login-shell` prints `login-shell`, and `echo $SHELL $0`
   names zsh (checks that `command = /bin/zsh -l` works, PRD Decision 7).
3. Theme: Catppuccin Macchiato colors; `echo $TERM` prints `xterm-256color`.
4. Keys: Option+N types `~`; Option+Shift+L types `|`; Shift+Enter at the prompt sends a newline.
5. Finder icon of `/Applications/Ghostty.app`: unchanged (expected).

Expected: the block ends with `DONE: fake-home launch session ended`, and the operator answers
"yes" to answer 0. Each answer above is recorded in the implementation review (Task 24) as
observed, custom icon or not.

Rollback: the `trap` removes the fake home after Ghostty quits. Nothing in the repository changes.

### Task 13 — Numpad verification, PRD Decision 9 (operator)

Files: none. Run in the window opened by Task 12, before quitting Ghostty. The config has no
numpad `keybind` lines at this point.

```bash
cat -v
```

Press, on the numeric keypad: `0`–`9`, `+`, `-`, `*`, `/`, `.`, then `Enter`. Then press Ctrl+C.
Repeat in application keypad mode:

```bash
tput smkx; cat -v
```

Press the same keys, then Ctrl+C, then:

```bash
tput rmkx
```

Expected: each key prints its literal character (`0123456789+-*/.`) and `Enter` ends the line, in
both runs. A key that prints anything else (for example an `^[O…` sequence) misbehaves. If the
keyboard has no numeric keypad, record "not tested" and add no lines.

Recorded in the implementation review (Task 24): per key, both outputs, and the list of
misbehaving keys (possibly empty).

Rollback: nothing to undo.

### Task 14 — Apply the numpad result (Builder)

Files: `stow/common/ghostty/.config/ghostty/config.ghostty` — modified only if Task 13 lists a
misbehaving key.

- Empty list or "not tested": change nothing.
- Otherwise: add one `keybind = numpad_<key>=text:<char>` line per misbehaving key, at the end of
  the key-binding block and before the final `config-file` line, under the own-line comment
  `# Numpad keys sent as literal characters (PRD 0028 Decision 9)`. Key names are the W3C snake
  case names (`numpad_0` … `numpad_9`, `numpad_add`, `numpad_subtract`, `numpad_multiply`,
  `numpad_divide`, `numpad_decimal`, `numpad_enter`); `numpad_enter` uses `text:\r`, as in the PRD
  mapping row.

After a change, re-run check 1, check 3 steps 2 and 3, and the `tail` and `macos-` lines of check
6, and ask the operator to re-run Task 12, then Task 13 for the changed keys (the Task 12 fake
home is already removed, so Task 13 cannot be repeated on its own).

Expected: no change, or the added lines pass check 1 (`exit=0`) and check 3, and the last line is
still `config-file = ?macos.ghostty`.

Rollback: remove the added numpad lines and their comment by hand. The file is untracked until
Task 17, so `git diff` and `git restore` do not apply; compare against Architecture 0026 instead.

### Task 15 — Update the status blocks in `AGENTS.md` and `CLAUDE.md` (Builder)

Files: `AGENTS.md` — modified (§1 bullet, §2 block); `CLAUDE.md` — modified (status block).

Replace the current text with the exact text of Architecture 0026, "Status-Block Updates":
`AGENTS.md` §2 block, `AGENTS.md` §1 bullet, and the two `CLAUDE.md` bullets. No per-package list
(`.claude/rules/status-sync.md`).

```bash
grep -n 'except ghostty\|except `ghostty`' AGENTS.md CLAUDE.md
grep -n 'stow/macos/' AGENTS.md CLAUDE.md
grep -n 'macos/, arch/, debian/ empty\|`macos/`, `arch/`, `debian/` empty' AGENTS.md CLAUDE.md
```

Expected: the first two commands match in both files; the third prints nothing.

Rollback (discards uncommitted edits with no recovery):

⚠️  MANUAL STEP — review before running
```bash
REPO="$(git rev-parse --show-toplevel)"
git -C "$REPO" restore -- AGENTS.md CLAUDE.md
```

### Task 16 — Update `README.md` (Builder)

Files: `README.md` — modified.

Edits, from Architecture 0026 ("Other files the Build creates or modifies", "Status-Block
Updates", and "Statements made false by a populated `stow/macos/`"):

1. `:15-16` — "in `stow/common/` and `stow/macos/`".
2. `:24` — `Managed packages:               see stow/common/ and stow/macos/`.
3. `:25` — `Home directory:                 stowed — all common packages linked except ghostty`.
4. `:28-29` — the source-of-truth paragraph, worded as in the architecture row for `:28-29`.
5. `:33-34` — `stow/macos/` holds `ghostty`; only `stow/arch/` and `stow/debian/` are empty.
6. Package table — a **ghostty** row between **eza** and **git**: Ghostty terminal — window, font,
   keybinds, Catppuccin Macchiato theme; macOS-only options and custom icon in
   `stow/macos/ghostty`; links to both package READMEs; guide `docs/guides/ghostty-setup.md`.
7. `:60` — add `[ghostty](docs/guides/ghostty-setup.md)` to the per-package guide list, between
   eza and git.
8. `:85` — first Safety bullet: "All `stow/common/` packages except `ghostty` are stowed; …".
9. `:105` — `macos/          macOS-specific packages` (drop `(empty)`; `arch/` and `debian/` keep
   it).

```bash
grep -n 'ghostty' README.md
grep -n '(empty)' README.md
grep -n 'currently empty' README.md
```

Expected: ghostty appears on the lines for edits 3 to 8; `(empty)` appears only on the
`arch/` and `debian/` lines; `currently empty` (if still present) names only `stow/arch/` and
`stow/debian/`.

Rollback (discards uncommitted edits with no recovery):

⚠️  MANUAL STEP — review before running
```bash
REPO="$(git rev-parse --show-toplevel)"
git -C "$REPO" restore -- README.md
```

### Task 17 — Commit 1: both packages and the status blocks (Builder)

Files: commit only. One commit, per `.claude/rules/status-sync.md`.

```bash
REPO="$(git rev-parse --show-toplevel)"
git -C "$REPO" add stow/common/ghostty stow/macos/ghostty AGENTS.md CLAUDE.md README.md
git -C "$REPO" status --porcelain
git -C "$REPO" diff --staged --stat
git -C "$REPO" diff --staged --check && echo "PASS: no whitespace errors"
```

Run **Validation Commands → Repository checks**. Run the privacy checklist
(`.claude/rules/privacy.md`) on `git -C "$REPO" diff --staged`, and the status-sync self-check.
Show the staged stat to the operator. Commit only after the operator approves:

```bash
REPO="$(git rev-parse --show-toplevel)"
git -C "$REPO" commit -m "feat(ghostty): add common and macOS Ghostty stow packages"
```

Expected staged files (11): the 4 common package files, the 4 macOS package files (including the
binary `Ghostty.icns`), `AGENTS.md`, `CLAUDE.md`, `README.md`. Nothing else.
`PASS: no whitespace errors` is printed, and the Repository checks give their expected output.

Rollback: before commit, `git -C "$REPO" restore --staged -- <path>`. After commit, with `<sha>`
the commit-1 SHA:

```bash
REPO="$(git rev-parse --show-toplevel)"
git -C "$REPO" revert --no-commit <sha>
git -C "$REPO" commit -m "revert(ghostty): remove Ghostty stow packages" -m "Refs: <sha>"
```

### Task 18 — Create `docs/guides/ghostty-setup.md` (Builder)

Files: `docs/guides/ghostty-setup.md` — created.

Follow Architecture 0026, "Human Setup Guide", sections 1–10 in order, modeled on
`docs/guides/alacritty-setup.md`. Every install, `stow` install, and `stow --delete` fence has
`⚠️  MANUAL STEP — review before running` on the line directly above it. Dry-run fences use
`-v` and state the expected `LINK:` lines. Use placeholders (`/path/to/dotfiles`); no real
username or path.

```bash
grep -c 'MANUAL STEP' docs/guides/ghostty-setup.md
grep -B1 -n '^```bash' docs/guides/ghostty-setup.md
grep -nE '/Users/|/home/' docs/guides/ghostty-setup.md
grep -c '^## ' docs/guides/ghostty-setup.md
```

Expected: at least 6 markers (2 prerequisites, 2 installs, 2 rollback deletes); each dangerous
fence is preceded by the marker line; no `/Users/` or `/home/` match; at least 10 `##` sections.

Rollback: as Task 2, with this file's path.

### Task 19 — Commit 2: the setup guide (Builder)

```bash
REPO="$(git rev-parse --show-toplevel)"
git -C "$REPO" add docs/guides/ghostty-setup.md
git -C "$REPO" diff --staged --stat
```

Run **Validation Commands → Repository checks**. Show the staged stat to the operator; commit
after approval:

```bash
REPO="$(git rev-parse --show-toplevel)"
git -C "$REPO" commit -m "docs(guides): add Ghostty setup guide"
```

Expected: one file staged; the Repository checks give their expected output.

Rollback: before commit, `git -C "$REPO" restore --staged -- docs/guides/ghostty-setup.md`. After
commit, with `<sha>` the commit-2 SHA:

```bash
REPO="$(git rev-parse --show-toplevel)"
git -C "$REPO" revert --no-commit <sha>
git -C "$REPO" commit -m "revert(guides): remove Ghostty setup guide" -m "Refs: <sha>"
```

### Task 20 — Update `docs/stow-usage.md` and the website pages (Builder)

Files — modified:

- `docs/stow-usage.md` — package tree (`ghostty/` under `common/` and `macos/`), `--no-folding`
  package list, the "Platform directories are not packages" section (`:33`; `stow/macos/` holds
  `ghostty` plus its `.gitkeep` marker; example `task dry-run AREA=macos PACKAGE=ghostty`), and a
  new "Installing the ghostty package" section after the alacritty one, covering both packages.
- `website/index.md` — "Terminal" row.
- `website/features/index.md` — "Terminal" row and the Catppuccin Macchiato tool list.
- `website/features/terminal.md` — Ghostty section next to Alacritty, with dry-run and install.
- `website/features/packages.md` — Codex note: Ghostty owns terminal colors too.
- `website/usage/daily-workflow.md` — Ghostty starts the same login zsh.
- `website/reference/stow.md` — package tree, `--no-folding` list, the "Platform directories are
  not packages" note (`:37`).
- `website/reference/supported-systems.md:31` — Ghostty in the portability row; the Ghostty common
  file has no macOS-only lines (PRD Decision 12).
- `website/reference/troubleshooting.md` — `--no-folding` package list.
- `website/getting-started.md:25`, `website/installation.md:19`,
  `website/reference/repository-structure.md:14` — drop "currently empty" for `macos/`.
- `website/reference/repository-structure.md:41-44` — "`stow/common/` and `stow/macos/` define
  which packages exist"; only `stow/arch/` and `stow/debian/` are empty.

`website/philosophy.md` is not changed. No page claims Ghostty is stowed. Note: `task dry-run` has
no `--no-folding`; pages that show it for ghostty say to use the explicit `stow -v … --no-folding`
command for the real dry-run.

In both `docs/stow-usage.md` and `website/features/terminal.md`, every install and `stow --delete`
fence has `⚠️  MANUAL STEP — review before running` on the line directly above it.

```bash
grep -rn 'currently empty\|(empty)\|only `.gitkeep`' docs/stow-usage.md website/
grep -rln -i 'ghostty' docs/stow-usage.md website/
grep -B1 -n '^```bash' docs/stow-usage.md website/features/terminal.md
```

Expected: the first command matches no line that names `stow/macos/` or `macos/` as empty; the
second lists `docs/stow-usage.md` and at least the eight pages from `website/index.md` to
`website/reference/troubleshooting.md` above; in the third, each install and `stow --delete` fence
is preceded by the marker line.

Rollback (discards uncommitted edits with no recovery; the explicit list leaves unrelated edits
under `website/` alone):

⚠️  MANUAL STEP — review before running
```bash
REPO="$(git rev-parse --show-toplevel)"
git -C "$REPO" restore -- docs/stow-usage.md website/index.md website/features/index.md \
  website/features/terminal.md website/features/packages.md website/usage/daily-workflow.md \
  website/reference/stow.md website/reference/supported-systems.md \
  website/reference/troubleshooting.md website/reference/repository-structure.md \
  website/getting-started.md website/installation.md
```

### Task 21 — Commit 3: documentation and website mentions (Builder)

```bash
REPO="$(git rev-parse --show-toplevel)"
git -C "$REPO" add docs/stow-usage.md website/
git -C "$REPO" diff --staged --stat
```

Run **Validation Commands → Repository checks**. Show the staged stat to the operator; commit
after approval:

```bash
REPO="$(git rev-parse --show-toplevel)"
git -C "$REPO" commit -m "docs: add Ghostty to stow usage and website pages"
```

Expected: only the files listed in Task 20 are staged; the Repository checks give their expected
output.

Rollback: before commit, `git -C "$REPO" restore --staged -- <path>`. After commit, with `<sha>`
the commit-3 SHA:

```bash
REPO="$(git rev-parse --show-toplevel)"
git -C "$REPO" revert --no-commit <sha>
git -C "$REPO" commit -m "revert(docs): remove Ghostty from stow usage and website pages" -m "Refs: <sha>"
```

### Task 22 — Real dry-run of both packages (operator)

Files: none. Reads `$HOME`, writes nothing. Run from the repository root.

```bash
# Step 1 — common package, macOS and Arch
stow -v --dir=stow/common --target="$HOME" --simulate --no-folding ghostty; echo "exit=$?"
```

```bash
# macOS
# Step 2 — macOS package
stow -v --dir=stow/macos --target="$HOME" --simulate --no-folding ghostty; echo "exit=$?"
```

Expected: step 1 prints `LINK:` lines for `.config/ghostty/config.ghostty` and
`.config/ghostty/themes/catppuccin-macchiato`; step 2 prints `LINK:` lines for
`.config/ghostty/Ghostty.icns` and `.config/ghostty/macos.ghostty`. `MKDIR:` lines and the
simulation-mode warning may appear. No conflict line. Each ends with `exit=0`. A conflict or a
non-zero exit: stop, do not install, report. Never use `--adopt`.

Recorded in the implementation review: both raw outputs.

Rollback: nothing to undo.

### Task 23 — Real install of both packages and check 7b (operator)

Files: creates symlinks under `$HOME/.config/ghostty/`. Only after Task 22 passed and the operator
approves this session.

⚠️  MANUAL STEP — review before running
```bash
# Step 3 — install the common package (macOS and Arch)
stow --dir=stow/common --target="$HOME" --no-folding ghostty; echo "exit=$?"
```

⚠️  MANUAL STEP — review before running
```bash
# macOS
# Step 4 — install the macOS package
stow --dir=stow/macos --target="$HOME" --no-folding ghostty; echo "exit=$?"
```

Then check (read-only):

```bash
# macOS
test -d "$HOME/.config/ghostty" && test ! -L "$HOME/.config/ghostty" \
  && test ! -L "$HOME/.config/ghostty/themes" && echo "PASS: real directories" || echo "FAIL: real directories"
readlink "$HOME/.config/ghostty/config.ghostty" "$HOME/.config/ghostty/themes/catppuccin-macchiato" \
  "$HOME/.config/ghostty/Ghostty.icns" "$HOME/.config/ghostty/macos.ghostty"
/Applications/Ghostty.app/Contents/MacOS/ghostty +validate-config; echo "exit=$?"
```

Quit Ghostty fully, start it again, and check (check 7b): Dock and app switcher show the custom
icon; Finder icon unchanged (expected); Option+N types `~`.

Expected: both installs `exit=0`; `PASS: real directories`; four `readlink` targets inside
`stow/common/ghostty/` or `stow/macos/ghostty/`; `+validate-config` `exit=0` with no message.

Recorded in the implementation review: install outputs, validation output, Dock icon, Finder icon,
Option+N.

Rollback:

⚠️  MANUAL STEP — review before running
```bash
# macOS only: remove the macOS package links first
stow --dir=stow/macos --target="$HOME" --delete ghostty
stow --dir=stow/common --target="$HOME" --delete ghostty
```

### Task 24 — Implementation review (Reviewer)

Files: `docs/reviews/NNNN-ghostty-configuration-implementation-review.md` — created (the next
free number under `docs/reviews/`, expected `0085`, since `0084` is taken by the plan confirmation
review); `docs/plans/0031-implement-ghostty-configuration.md` and `docs/plans/README.md` — status
changed by the Reviewer only.

Before writing the review, record again that the Application Support file and the app bundle are
untouched (read-only):

```bash
# macOS
wc -c < "$HOME/Library/Application Support/com.mitchellh.ghostty/config.ghostty" | tr -d ' '
codesign --verify --deep --strict /Applications/Ghostty.app; echo "exit=$?"
```

Expected: `0`; `exit=0`.

The review records: raw outputs of Tasks 1, 8, 10, 11, 22, 23; the operator results of Tasks 12,
13, and 23 (window opened, icon and `XDG_CONFIG_HOME` answer, login shell, keys, numpad table, Dock
and Finder icon); the Task 14 outcome; the three commit SHAs; the `wc -c` and `codesign` outputs
from Task 1 and from this task. It sets this plan Complete only with no blocking issue.

The review also records as a follow-up that `Taskfile.yml:67` describes `task dry-run` as
"AREA=<common> … (macos/arch/debian are future areas)", which is stale once `stow/macos/ghostty`
exists (review 0083 suggestion 10). This plan does not change `Taskfile.yml`.

Rollback, with `<sha>` the review commit SHA:

```bash
REPO="$(git rev-parse --show-toplevel)"
git -C "$REPO" revert --no-commit <sha>
git -C "$REPO" commit -m "revert(reviews): remove Ghostty implementation review" -m "Refs: <sha>"
```

### Task 25 — Follow-up: status blocks after the first stow (Builder, on operator request)

Only after Task 23 succeeded and the operator asks. This is a "first stowed" event
(`.claude/rules/status-sync.md`, Architecture 0026 "Status-Block Updates"): remove the
"except ghostty" / "not yet stowed" wording from `AGENTS.md`, `CLAUDE.md`, and the `README.md`
status lines, in one separate commit:

```bash
REPO="$(git rev-parse --show-toplevel)"
git -C "$REPO" add AGENTS.md CLAUDE.md README.md
git -C "$REPO" diff --staged --stat
git -C "$REPO" diff --staged
```

Run the privacy checklist (`.claude/rules/privacy.md`) on the staged diff and the status-sync
self-check (`.claude/rules/status-sync.md`; this is a "first stowed" event, so both status blocks
change in this commit). Show the staged stat to the operator. Commit only after the operator
approves:

```bash
REPO="$(git rev-parse --show-toplevel)"
git -C "$REPO" commit -m "docs: mark Ghostty packages as stowed"
```

If the two packages are stowed in separate sessions, each first stow gets its own status commit.

Rollback, with `<sha>` the follow-up commit SHA:

```bash
REPO="$(git rev-parse --show-toplevel)"
git -C "$REPO" revert --no-commit <sha>
git -C "$REPO" commit -m "revert(docs): mark Ghostty packages as not stowed" -m "Refs: <sha>"
```

## Commit Grouping

| Commit | Task | Contents | Message |
|---|---|---|---|
| 1 | 17 | `stow/common/ghostty/` (4 files), `stow/macos/ghostty/` (4 files), `AGENTS.md`, `CLAUDE.md`, `README.md` | `feat(ghostty): add common and macOS Ghostty stow packages` |
| 2 | 19 | `docs/guides/ghostty-setup.md` | `docs(guides): add Ghostty setup guide` |
| 3 | 21 | `docs/stow-usage.md`, `website/` pages from Task 20 | `docs: add Ghostty to stow usage and website pages` |
| Follow-up | 25 | `AGENTS.md`, `CLAUDE.md`, `README.md` status lines | `docs: mark Ghostty packages as stowed` |

Numpad lines, if any (Task 14), are part of commit 1. The implementation review is the Reviewer's
own commit. No commit carries a `Co-Authored-By:` trailer or tool footer.

## Files Affected

- `stow/common/ghostty/.config/ghostty/config.ghostty` — created
- `stow/common/ghostty/.config/ghostty/themes/catppuccin-macchiato` — created
- `stow/common/ghostty/.stow-local-ignore` — created
- `stow/common/ghostty/README.md` — created
- `stow/macos/ghostty/.config/ghostty/macos.ghostty` — created
- `stow/macos/ghostty/.config/ghostty/Ghostty.icns` — created (binary copy of
  `$HOME/Downloads/ghosty.icns`)
- `stow/macos/ghostty/.stow-local-ignore` — created
- `stow/macos/ghostty/README.md` — created
- `stow/macos/.gitkeep` — unchanged (kept; see Assumptions)
- `AGENTS.md` — modified (§1 bullet, §2 block)
- `CLAUDE.md` — modified (status block)
- `README.md` — modified
- `docs/guides/ghostty-setup.md` — created
- `docs/stow-usage.md` — modified
- `website/index.md` — modified
- `website/features/index.md` — modified
- `website/features/terminal.md` — modified
- `website/features/packages.md` — modified
- `website/usage/daily-workflow.md` — modified
- `website/reference/stow.md` — modified
- `website/reference/supported-systems.md` — modified
- `website/reference/troubleshooting.md` — modified
- `website/reference/repository-structure.md` — modified
- `website/getting-started.md` — modified
- `website/installation.md` — modified
- `docs/reviews/NNNN-ghostty-configuration-implementation-review.md` — created by the Reviewer
- `docs/plans/0031-implement-ghostty-configuration.md`, `docs/plans/README.md` — status changed by
  the Reviewer only

Not touched: `stow/common/alacritty/`, `~/Library/Application Support/com.mitchellh.ghostty/`,
`/Applications/Ghostty.app`, `$HOME/Downloads/ghosty.icns`, anything in `$HOME` before Task 23.

## Safety Checks

- Before Task 2: Task 1 passed; the branch is `feat/ghostty-package`; the tree is clean.
- The Builder never runs `stow` with `--target="$HOME"`, never launches Ghostty, and never writes
  to `$HOME`. Only Tasks 12, 13, 22, and 23 touch `$HOME` or launch the app, and only the operator
  runs them.
- No `stow --adopt`, no `rm`, `mv`, or `ln -s` against `$HOME` or outside the repository. The only
  `rm` is `rm -rf "${FAKE_HOME:?}"` on the block's own `mktemp -d` directory.
- Every fake-home block is `( set -eu; … )`, uses `${FAKE_HOME:?}` on every `stow --target`, `test`,
  `XDG_CONFIG_HOME`, and `rm`, and checks each command's exit code explicitly. A missing `PASS:` line
  is a failure (review 0082 suggestion 1).
- Task 8 checks that the target is absent before copying; `/bin/cp -n` never overwrites.
- A dry-run conflict (Task 22, or check 3 step 1) stops the plan; the operator resolves it manually.
- `~/Library/Application Support/com.mitchellh.ghostty/config.ghostty` stays untouched and empty.
- The signed `/Applications/Ghostty.app` bundle is not modified.
- Before each commit: `git diff --staged` reviewed against `.claude/rules/privacy.md`; the
  status-sync self-check (`.claude/rules/status-sync.md`) for commit 1; operator approves the staged
  stat.
- No push, merge, or branch deletion in this plan.

## Validation Commands

Run from the repository root. Read-only unless stated.

### Checks 1 and 2 — `+validate-config` on the repo files

```bash
# macOS
GHOSTTY=/Applications/Ghostty.app/Contents/MacOS/ghostty
"$GHOSTTY" +validate-config \
  --config-file=stow/common/ghostty/.config/ghostty/config.ghostty; echo "exit=$?"
"$GHOSTTY" +validate-config \
  --config-file=stow/common/ghostty/.config/ghostty/themes/catppuccin-macchiato; echo "exit=$?"
```

Expected: check 2 prints `exit=0` and no message. Check 1 prints `exit=0` and no message, or only
a theme-not-found message for `catppuccin-macchiato` (no `themes/` beside the default config yet);
check 3 step 2 settles that case. Any other message or exit code: stop and report.

### Check 3 — fake-home Stow and theme resolution

Each block writes only into its own `mktemp -d` directory, removed by the `trap` on exit. If a
block is interrupted before the trap is set, it may leave a temporary directory outside the
repository and `$HOME`.

⚠️  MANUAL STEP — review before running
```bash
# Step 1 — conflict check
(
  set -eu
  test -d stow/common/ghostty || { echo "FAIL: run from the repository root"; exit 1; }
  FAKE_HOME="$(mktemp -d)"
  trap 'rm -rf "${FAKE_HOME:?}"' EXIT
  stow -v --dir=stow/common --target="${FAKE_HOME:?}" --simulate --no-folding ghostty \
    || { echo "FAIL: common simulate exit $?"; exit 1; }
  echo "PASS: check 3 step 1"
)
```

⚠️  MANUAL STEP — review before running
```bash
# macOS — Step 2: common package only (simulates the Arch layout)
# Theme by name, optional include skipped
(
  set -eu
  test -d stow/common/ghostty || { echo "FAIL: run from the repository root"; exit 1; }
  GHOSTTY=/Applications/Ghostty.app/Contents/MacOS/ghostty
  FAKE_HOME="$(mktemp -d)"
  trap 'rm -rf "${FAKE_HOME:?}"' EXIT
  CFG="${FAKE_HOME:?}/.config/ghostty"
  stow --dir=stow/common --target="${FAKE_HOME:?}" --no-folding ghostty \
    || { echo "FAIL: common stow exit $?"; exit 1; }
  if test -L "$CFG" || test -L "$CFG/themes"; then echo "FAIL: folded directory"; exit 1; fi
  if ! test -L "$CFG/config.ghostty" || ! test -L "$CFG/themes/catppuccin-macchiato"; then
    echo "FAIL: missing link"; exit 1
  fi
  if test -e "$CFG/macos.ghostty"; then echo "FAIL: macos.ghostty present"; exit 1; fi
  OUT="$(XDG_CONFIG_HOME="${FAKE_HOME:?}/.config" "$GHOSTTY" +validate-config \
    --config-file="$CFG/config.ghostty" 2>&1)" \
    || { echo "FAIL: validate-config: $OUT"; exit 1; }
  test -z "$OUT" || { echo "FAIL: validate-config printed: $OUT"; exit 1; }
  XDG_CONFIG_HOME="${FAKE_HOME:?}/.config" "$GHOSTTY" +show-config \
    | grep -qx 'palette = 0=#494d64' || { echo "FAIL: repo palette not applied"; exit 1; }
  stow --dir=stow/common --target="${FAKE_HOME:?}" --delete ghostty \
    || { echo "FAIL: common delete exit $?"; exit 1; }
  echo "PASS: check 3 step 2"
)
```

⚠️  MANUAL STEP — review before running
```bash
# macOS
# Step 3 — both packages into one fake home
(
  set -eu
  test -d stow/macos/ghostty || { echo "FAIL: run from the repository root"; exit 1; }
  GHOSTTY=/Applications/Ghostty.app/Contents/MacOS/ghostty
  FAKE_HOME="$(mktemp -d)"
  trap 'rm -rf "${FAKE_HOME:?}"' EXIT
  CFG="${FAKE_HOME:?}/.config/ghostty"
  stow --dir=stow/common --target="${FAKE_HOME:?}" --no-folding ghostty \
    || { echo "FAIL: common stow exit $?"; exit 1; }
  stow -v --dir=stow/macos --target="${FAKE_HOME:?}" --simulate --no-folding ghostty \
    || { echo "FAIL: macOS simulate exit $?"; exit 1; }
  stow --dir=stow/macos --target="${FAKE_HOME:?}" --no-folding ghostty \
    || { echo "FAIL: macOS stow exit $?"; exit 1; }
  if test -L "$CFG"; then echo "FAIL: folded directory"; exit 1; fi
  if ! test -L "$CFG/Ghostty.icns" || ! test -L "$CFG/macos.ghostty"; then
    echo "FAIL: macOS file not linked"; exit 1
  fi
  OUT="$(XDG_CONFIG_HOME="${FAKE_HOME:?}/.config" "$GHOSTTY" +validate-config \
    --config-file="$CFG/config.ghostty" 2>&1)" \
    || { echo "FAIL: validate-config: $OUT"; exit 1; }
  test -z "$OUT" || { echo "FAIL: validate-config printed: $OUT"; exit 1; }
  SHOWN="$(XDG_CONFIG_HOME="${FAKE_HOME:?}/.config" "$GHOSTTY" +show-config)" \
    || { echo "FAIL: show-config"; exit 1; }
  printf '%s\n' "$SHOWN" | grep -qx 'macos-icon = custom' \
    || { echo "FAIL: macos-icon not loaded"; exit 1; }
  printf '%s\n' "$SHOWN" | grep -qx 'macos-option-as-alt = true' \
    || { echo "FAIL: macos-option-as-alt not loaded"; exit 1; }
  stow --dir=stow/macos --target="${FAKE_HOME:?}" --delete ghostty \
    || { echo "FAIL: macOS delete exit $?"; exit 1; }
  stow --dir=stow/common --target="${FAKE_HOME:?}" --delete ghostty \
    || { echo "FAIL: common delete exit $?"; exit 1; }
  echo "PASS: check 3 step 3 [macOS]"
)
```

Expected: each block ends with its `PASS:` line. Step 1 shows two `LINK:` lines and no conflict.

### Check 4 — palette parity with Alacritty

```bash
DIFF="$(comm -23 \
  <(grep -oE '#[0-9a-f]{6}' stow/common/ghostty/.config/ghostty/themes/catppuccin-macchiato | sort -u) \
  <(grep -oE '#[0-9a-f]{6}' stow/common/alacritty/.config/alacritty/catppuccin-macchiato.toml | sort -u))"
test -z "$DIFF" && echo "PASS: palette parity" || printf 'FAIL: not in Alacritty:\n%s\n' "$DIFF"
```

Expected: `PASS: palette parity`. The Reviewer also compares each key to its PRD theme-mapping row.

### Check 5 — privacy and dependency audit

```bash
if grep -rEi 'password|token|secret|api.?key|private.?key|BEGIN (RSA|OPENSSH|EC)|hostname\.' \
  stow/common/ghostty/; then echo "FAIL: secret pattern"; else echo "PASS: no secret pattern (common)"; fi
if grep -rEi 'brew|pacman|curl|wget|npm|pip|cargo|apt' stow/common/ghostty/.config/; then
  echo "FAIL: install command"; else echo "PASS: no install command"; fi
if grep -rE '/Users/|/home/' stow/common/ghostty/; then
  echo "FAIL: user path"; else echo "PASS: no user path (common)"; fi
if grep -rEi \
  'password|token|secret|api.?key|private.?key|BEGIN (RSA|OPENSSH|EC)|hostname\.|/Users/|/home/' \
  stow/macos/ghostty/README.md stow/macos/ghostty/.stow-local-ignore \
  stow/macos/ghostty/.config/ghostty/macos.ghostty; then
  echo "FAIL: macOS package pattern"; else echo "PASS: no secret or user path (macOS)"; fi
```

Expected: four `PASS:` lines and no match printed.

### Check 6 — package integrity

```bash
(
  set -u
  ICNS=stow/macos/ghostty/.config/ghostty/Ghostty.icns
  COMMON=stow/common/ghostty/.config/ghostty/config.ghostty
  MACOS=stow/macos/ghostty/.config/ghostty/macos.ghostty
  SHA=6796c0f423a066009fef4f69ab7800a086627304fc633d3cba69a4ca173632ac
  [ "$(shasum -a 256 "$ICNS" | cut -d' ' -f1)" = "$SHA" ] && echo "PASS: sha256" || echo "FAIL: sha256"
  grep -q "$SHA" stow/macos/ghostty/README.md && echo "PASS: README sha256" || echo "FAIL: README sha256"
  file "$ICNS" | grep -q 'Mac OS X icon' && echo "PASS: file type" || echo "FAIL: file type"
  [ "$(wc -c < "$ICNS" | tr -d ' ')" = 152344 ] && echo "PASS: size" || echo "FAIL: size"
  diff -q stow/common/ghostty/.stow-local-ignore stow/macos/ghostty/.stow-local-ignore >/dev/null \
    && echo "PASS: ignore files equal" || echo "FAIL: ignore files differ"
  grep -q '^macos-' "$COMMON" && echo "FAIL: macos- in common" || echo "PASS: no macos- in common"
  [ "$(tail -n 1 "$COMMON")" = 'config-file = ?macos.ghostty' ] \
    && echo "PASS: last line" || echo "FAIL: last line"
  [ "$(grep -c '^macos-option-as-alt = true$' "$MACOS")" = 1 ] \
    && echo "PASS: option-as-alt" || echo "FAIL: option-as-alt"
  [ "$(grep -c '^macos-icon = custom$' "$MACOS")" = 1 ] && echo "PASS: icon option" || echo "FAIL: icon option"
  grep -rIn '^[[:space:]]*macos-custom-icon' stow/common/ghostty/.config/ stow/macos/ghostty/.config/ \
    && echo "FAIL: macos-custom-icon set" || echo "PASS: macos-custom-icon not set"
)
```

Expected: ten `PASS:` lines and no `FAIL:` line.

### Repository checks

Run in Tasks 17, 19, and 21, before each commit.

```bash
REPO="$(git rev-parse --show-toplevel)"
git -C "$REPO" diff --check && git -C "$REPO" diff --staged --check \
  && echo "PASS: no whitespace errors"
task check:decisions; echo "exit=$?"
git -C "$REPO" status --porcelain
git -C "$REPO" log --oneline -5
```

Expected: `PASS: no whitespace errors`; `exit=0`; only the files of the current task are changed;
the commits made so far by Tasks 17, 19, and 21 appear in order (none before the Task 17
commit, one before the Task 19 commit, two before the Task 21 commit).

## Rollback Strategy

- All git rollback stays on the lane branch `feat/ghostty-package`. No `git reset --hard`, no force
  push, no history rewrite.
- **Before commit, new files** (Tasks 2–9, 18): preview with `git -C "$REPO" clean -n -- <path>`,
  then remove with `git -C "$REPO" clean -f -- <path>` (`-fd` for a directory) under the
  `⚠️  MANUAL STEP` marker. Only repository paths.
- **Before commit, modified files** (Tasks 15, 16, 20): `git -C "$REPO" restore -- <path>` under
  the `⚠️  MANUAL STEP` marker, since it discards uncommitted edits with no recovery; name explicit
  files, not a directory. Staged: `git -C "$REPO" restore --staged -- <path>` first.
- **After commit** (Tasks 17, 19, 21, 24, 25): `git -C "$REPO" revert --no-commit <sha>`, then
  `git -C "$REPO" commit -m "revert(<scope>): <description>" -m "Refs: <sha>"` with the subject
  given in that task, newest first. Never `revert --no-edit`: its default `Revert "…"` subject
  breaks Conventional Commits. Reverting commit 1 reverts the status blocks with the packages, so
  they stay in sync.
- **Fake-home blocks** (Tasks 11, 12): the `trap` removes the `mktemp -d` directory. A leftover
  directory is outside the repository and `$HOME`; the operator removes it after looking at the
  path.
- **Real stow** (Task 23): `stow --delete` for the macOS package first, then the common package,
  under the marker shown in Task 23. Ghostty then falls back to its defaults and, after a full
  restart, the official icon.
- The icon source `$HOME/Downloads/ghosty.icns` and the Application Support file are never changed,
  so they need no rollback.

## Completion Criteria

- [ ] `stow/common/ghostty/` holds `config.ghostty`, `themes/catppuccin-macchiato`,
  `.stow-local-ignore`, and `README.md`, with the content of Architecture 0026.
- [ ] `stow/macos/ghostty/` holds `.config/ghostty/macos.ghostty`, `.config/ghostty/Ghostty.icns`,
  `.stow-local-ignore`, and `README.md`; `stow/macos/.gitkeep` is unchanged.
- [ ] `Ghostty.icns` SHA-256 is `6796c0f423a066009fef4f69ab7800a086627304fc633d3cba69a4ca173632ac`
  and `file` reports `Mac OS X icon`.
- [ ] Checks 1, 2, 4, 5, and 6 give their expected output; check 3 prints all three `PASS:` lines.
- [ ] `config.ghostty` has no `macos-*` line and ends with `config-file = ?macos.ghostty`.
- [ ] The numpad result (Task 13) is recorded, and lines exist only for misbehaving keys.
- [ ] `AGENTS.md`, `CLAUDE.md`, and `README.md` status lines are updated in commit 1, together with
  both packages.
- [ ] `docs/guides/ghostty-setup.md` exists, with every dangerous fence marked, in commit 2.
- [ ] `docs/stow-usage.md` and the website pages are updated in commit 3; no page says
  `stow/macos/` is empty.
- [ ] No symlink in `$HOME` was created by the Builder; no `stow --adopt` was run; the Application
  Support file and the app bundle are unchanged.
- [ ] The operator results of Tasks 12, 13, 22, and 23 are recorded in the implementation review.
- [ ] The implementation review has no blocking issue; the Reviewer sets this plan Complete.
