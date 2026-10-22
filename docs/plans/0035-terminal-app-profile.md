# Plan: macOS Terminal.app Profile

**Number:** 0035
**Status:** Complete
**Date:** 2026-10-22
**PRD:** [0031-terminal-app-profile](../prd/0031-terminal-app-profile.md) (Approved)
**Architecture:** [0027-terminal-app-profile-architecture](../architecture/0027-terminal-app-profile-architecture.md) (Approved)
**Plan review:** [0096](../reviews/0096-terminal-app-profile-plan-review.md), [0097](../reviews/0097-terminal-app-profile-plan-re-review.md), [0098](../reviews/0098-terminal-app-profile-plan-third-review.md) — blocking issues addressed in this revision

## Objective

Add a Catppuccin Macchiato Terminal.app profile with `JetBrainsMono Nerd Font`, deployed by a
user-run, dry-run-by-default `task terminal:sync`, and document it in the guide and the website.

## Assumptions

- Work happens on branch `docs/terminal-app-profile-prd`. PRD 0031, architecture 0027, this plan
  and reviews 0096, 0097 and 0098 are on it, uncommitted. Task 0 commits them on their own, so every
  later rollback concerns only the build.
- Plan 0035 is Approved by the user before Task 0 starts. The Builder does not change plan status.
- `JetBrainsMonoNF-Regular` is the verified PostScript name; `font-jetbrains-mono-nerd-font` is installed separately with
  `brew install --cask`, not through the Brewfile, as `docs/guides/ghostty-setup.md` documents.
- `ProfileCurrentVersion` is `2.09`, read once from the existing "Clear Dark" profile on
  2026-10-22. It is a committed constant of the build; the build never reads local preferences.
- The highest ADR is 0080 and the highest review is 0098. The Builder
  confirms the next free ADR number with `ls docs/decisions` before writing the ADR.
- `mkdocs` is not installed locally. `mkdocs build --strict` runs in CI (`.github/workflows/docs.yml`)
  and is the authority for the website criterion.
- `website/features/packages.md` lists stowed packages only, and the Terminal.app package is
  deliberately not stowed, so that page is not changed. This determination is recorded in the
  implementation review. `website/features/terminal.md` and `website/features/scripts.md` are
  changed.
- No agent runs `--apply`, `--set-default`, `defaults write` against `com.apple.Terminal`, or
  `open` on the profile. Those are the user's `⚠️  MANUAL STEP`s at the end.

## Ordered Tasks

Tasks run in this order. Dependencies are stated where a task needs an earlier one.

0. **Commit the planning documents.** Stage exactly `docs/prd/0031-terminal-app-profile.md`,
   `docs/architecture/0027-terminal-app-profile-architecture.md`,
   `docs/plans/0035-terminal-app-profile.md` (with its status set to Approved by the user's
   explicit approval), and `docs/reviews/0096-terminal-app-profile-plan-review.md` and
   `docs/reviews/0097-terminal-app-profile-plan-re-review.md`, and `docs/reviews/0098-terminal-app-profile-plan-third-review.md`. Audit the staged diff, then make one
   commit `docs(plans): add Terminal.app profile PRD, architecture and plan`. After this commit
   the working tree is clean, so everything below is new work with a clean rollback.
1. **Package skeleton.** Create `stow/macos/terminal/` with `.stow-local-ignore` (ignores the
   profile, the README and itself) and `README.md`. The README states that the package is
   deliberately not stowed, that Stow links nothing from it, and that it is deployed with
   `task terminal:sync`. Validate with `stow --simulate` against a scratch target, and check the
   README text with `grep -n "not stowed" stow/macos/terminal/README.md`.
2. **Script skeleton.** Create `scripts/terminal-sync.sh`: strict mode, usage, argument parsing for
   `--apply`, `--set-default`, `--build`, rejection of `--set-default` without `--apply`, and the
   macOS guard through `scripts/detect-os.sh`. The guard and the checks for a missing `defaults`
   binary and a missing `com.apple.Terminal` domain run before any preference is read. Unfinished
   modes exit with a clear "not implemented" message.
3. **`--build` mode.** Read `stow/common/alacritty/.config/alacritty/catppuccin-macchiato.toml`
   with `tomllib`, build the `NSKeyedArchiver` color and font blobs and the profile dictionary
   (Architecture Decision 5), and write `stow/macos/terminal/Catppuccin Macchiato.terminal`.
   Selection background is Surface2 `#5b6078` (Decision 6). `ProfileCurrentVersion` is the
   constant `2.09` with a comment giving its origin. `--build` reads no preference domain and
   writes only inside the repository.
4. **Generate and validate the profile** (depends on Task 3). Run `--build`, then check:
   `plutil -lint`; decode every color and the font with `NSKeyedUnarchiver` (via
   `osascript -l JavaScript`, read-only); optionally compare the archive structure with the live
   "Clear Dark" profile as a read-only validation, never as a build input; assert that the 16 ANSI
   slots, background, foreground and cursor equal the Alacritty values and that the selection
   equals `#5b6078`. The implementation review records the selection as a deliberate exception to
   PRD 0031's "equal the Macchiato values used by the Alacritty theme" (Architecture Decision 6).
5. **Report mode (default)** (depends on Tasks 2 and 4). Read-only status: font installed, profile
   present in `Window Settings` or not, drift between the live profile and the committed file,
   current default and startup profile. Reads with `defaults export`; writes nothing. It does not
   depend on `--apply`.
6. **`--apply` mode** (depends on Tasks 2 and 4). In this order: refuse if Terminal.app is running
   (Decision 3); write a backup with `defaults export com.apple.Terminal` to
   `"$HOME/Library/Preferences/com.apple.Terminal.plist.bak-<YYYYmmddHHMMSS>"`, next to the live
   file as `codex-sync.sh` does (`scripts/codex-sync.sh:219-223`), and print its path; then
   `defaults write com.apple.Terminal "Window Settings" -dict-add "Catppuccin Macchiato" <xml>`.
   Touch no other key.
7. **`--set-default`** (depends on Task 6). Only with `--apply`: write `Default Window Settings`
   and `Startup Window Settings`. Before writing, print the previous values together with the exact
   `defaults write` commands that restore them, and keep the same text in the guide. When a key
   was absent, print the `defaults delete com.apple.Terminal <key>` command that restores that state
   instead of a `defaults write`.
8. **Scratch-domain test hook** (depends on Tasks 5–7). Add the environment override
   `TERMINAL_SYNC_DOMAIN`. The script accepts the live domain `com.apple.Terminal` (the default) or a
   value that starts with `com.example.terminal-sync-test`; any other value exits with status 2 and
   changes nothing. The running-Terminal guard and the backup are skipped only for a
   `com.example.terminal-sync-test*` domain and always apply for the live domain, so the override can
   never produce an unguarded live write. Document that the hook exists for validation only.
9. **Task target.** Add `terminal:sync` to `Taskfile.yml` beside `codex:sync`, same shape, with a
   description that states "DRY RUN by default" and the `--apply` form.
10. **Validate the script without touching the live domain** (depends on Tasks 5–9). Use
    `TERMINAL_SYNC_DOMAIN=com.example.terminal-sync-test`. First seed the scratch domain with an
    unrelated key and an unrelated profile in `Window Settings`. Then: report on it, `--apply`,
    re-run `--apply` (no duplicate key; the seeded key and profile are intact),
    `--apply --set-default`, report again. Also check: `TERMINAL_SYNC_DOMAIN=com.apple.Terminal` and
    an arbitrary domain behave as specified in Task 8. The live-domain check is read-only: it runs
    only the default report mode (and the invalid-domain rejection), and no agent or test ever
    runs `--apply` or `--set-default` against `com.apple.Terminal`. `--set-default` alone is rejected; a faked
    non-macOS `detect-os` result exits before any preference is read; a missing `defaults` binary
    and a missing domain exit with a clear message. Remove the scratch domain with `defaults delete`
    on `com.example.terminal-sync-test` only.
11. **ADR.** Write the next free ADR in `docs/decisions/` recording that Terminal.app is deployed
    by a Task with `defaults write`, not by Stow or `open`, and add its row to
    `docs/decisions/README.md`.
12. **Guide.** Write `docs/guides/terminal-app-setup.md`: font prerequisite, dry run, apply,
    set default, rollback (restore the backup with `defaults import`, restore the previous default
    with the printed commands, or delete the profile in Terminal.app), the 24-bit color limit and
    `killall cfprefsd` as a manual fallback. Every live-system command is preceded by
    `⚠️  MANUAL STEP — review before running`. Add the guide to `README.md`: the package table (the
    Ghostty row is the model) and the "Per-package setup guides" list.
13. **Website and package docs.** Update `website/features/terminal.md` (Terminal.app section and
    the `task terminal:sync` flow, following how Ghostty is described) and
    `website/features/scripts.md` (the new script). Update the package tree in
    `docs/stow-usage.md` and verify the entry with `grep -n terminal docs/stow-usage.md`.
    `website/features/packages.md` is unchanged (see Assumptions).
14. **Status blocks.** In the same change, append this exact clause to the `Stowed to $HOME:` line
    of `AGENTS.md` §2 and to the matching sentence in `CLAUDE.md`:
    `; other stow/macos/ packages are not stowed`.
    It states stowed versus not and nothing else: no package name, no per-package list, no
    deployment detail, and `stow/macos/` stays the source of truth, as
    `.claude/rules/status-sync.md` requires. It satisfies PRD 0031's criterion that both blocks are
    updated in the same commit. The two blocks must read identically on this point.
15. **Local checks.** `bash -n` and `shellcheck` (if installed) on the new script,
    `task check:decisions`, `task --list`, then stage exactly the files listed under Files Affected
    (the planning documents were committed in Task 0 and are not restaged) and audit the staged diff
    for secrets, user names and absolute home paths. Commit only after the Task 16 review passes.
    The `stow/macos/terminal/` package and both status-block updates (Task 14) go in the same
    commit: `feat(terminal): add Terminal.app Macchiato profile and terminal:sync task`.
16. **Review.** The Reviewer checks safety, privacy and documentation, stores the report under
    `docs/reviews/`, and marks this plan Complete only if there are no blocking issues.
17. **User deployment (manual, after the review).** The user quits Terminal.app, then runs the dry
    run, `--apply`, and optionally `--apply --set-default` from another terminal, and confirms the
    glyph and colors. This is acceptance by the user, not a prerequisite for the Reviewer.

## Files Affected

Created:
- `stow/macos/terminal/.stow-local-ignore`
- `stow/macos/terminal/README.md`
- `stow/macos/terminal/Catppuccin Macchiato.terminal`
- `scripts/terminal-sync.sh`
- `docs/guides/terminal-app-setup.md`
- `docs/decisions/<next free number>-terminal-app-deployed-by-task-not-stow.md`
- `docs/reviews/<next number>-terminal-app-profile-implementation-review.md`

Modified:
- `Taskfile.yml` — new `terminal:sync` target
- `docs/decisions/README.md` — ADR index row
- `docs/stow-usage.md` and `website/reference/stow.md` — package tree
- `README.md` — package table row and guide list
- `website/features/terminal.md`, `website/features/scripts.md`
- `AGENTS.md` (§2) and `CLAUDE.md` — status blocks
Committed in Task 0, before the build: `docs/prd/0031-terminal-app-profile.md`,
`docs/architecture/0027-terminal-app-profile-architecture.md`,
`docs/plans/0035-terminal-app-profile.md`, and reviews 0096, 0097 and 0098.

Deleted: none.

## Safety Checks

Before starting:
- Plan 0035 is Approved, the branch is `docs/terminal-app-profile-prd`, and `git status` shows only
  the planning documents named in Task 0. After Task 0 the tree is clean.

During execution:
- No agent or test command writes to `com.apple.Terminal`. The only preference domain an agent
  writes is the scratch test domain `com.example.terminal-sync-test`. The only writes under `$HOME`
  are the user's own `--apply` in Task 17: the backup file next to the live preferences and the
  `com.apple.Terminal` domain.
- The `TERMINAL_SYNC_DOMAIN` override cannot disable the running-Terminal guard or the backup for
  the live domain (Task 8).
- `--build` and tests write only inside the repository or a scratch directory outside it.
- The script contains no call to `stow`, and no other script or task calls `terminal:sync`.
- The staged diff is audited for secrets, user names and absolute home paths before commit.
- Dangerous commands appear in docs only behind the `⚠️  MANUAL STEP` marker.

## Validation Commands

```bash
git status --short
stow --dir=stow/macos --target="$(mktemp -d)" --simulate -v terminal   # links nothing
plutil -lint "stow/macos/terminal/Catppuccin Macchiato.terminal"
bash scripts/terminal-sync.sh                                           # read-only report
bash -n scripts/terminal-sync.sh
task --list | grep terminal:sync
task check:decisions
grep -rnE "/Users/|/home/" scripts/terminal-sync.sh stow/macos/terminal docs/guides/terminal-app-setup.md
```

The scratch-domain run in Task 10 and the CI `mkdocs build --strict` complete the validation.

## Rollback Strategy

Repository work (nothing outside the repository has changed until Task 17):
- Uncommitted: after Task 0 the tree started clean, so `git status --short` lists exactly this
  plan's changes and nothing else. Restore each modified file with `git restore <file>`. For each
  created file, confirm it in `git status --short` and delete that single path by hand. Do not use
  `git clean` over the tree. The planning documents are in the Task 0 commit and are not touched.
- Committed, not pushed: `git log --oneline main..HEAD` shows the commits; undo them with
  `git revert --no-edit <oldest>^..<newest>`, which keeps history and needs no reset.
- Merged: open a new branch and revert the merged commits the same way, then a pull request.
  This repository merges with rebase, so there is no single merge commit to revert.

Live Terminal.app (only after the user has run `--apply`):

⚠️  MANUAL STEP — review before running
```bash
# Restore the whole preference domain from the backup that --apply printed
defaults import com.apple.Terminal "$HOME/Library/Preferences/com.apple.Terminal.plist.bak-<timestamp>"
```

To undo only the default profile, use the restore commands that `--set-default` printed, also
recorded in the guide. To remove the profile alone, delete `Catppuccin Macchiato` in Terminal.app
under Settings → Profiles.

## Completion Criteria

- [ ] Every acceptance criterion in PRD 0031 is met and checked in the implementation review.
- [ ] `stow --simulate` on the package links nothing, and the README documents the ignored behavior.
- [ ] `plutil -lint` passes and the decoded palette equals the Alacritty theme, with the
      documented Surface2 selection exception.
- [ ] The dry run is read-only; `--apply` is idempotent and leaves the seeded unrelated key and
      profile intact on the scratch domain; `--set-default` is rejected without `--apply`.
- [ ] `TERMINAL_SYNC_DOMAIN` accepts only the live domain or `com.example.terminal-sync-test*`,
      and the guard and backup always apply to the live domain.
- [ ] The script exits cleanly on non-macOS and refuses `--apply` while Terminal.app runs.
- [ ] `task terminal:sync` appears in `task --list`.
- [ ] ADR, guide, website pages, `docs/stow-usage.md`, `README.md` and both status blocks are
      updated, and `task check:decisions` passes.
- [ ] CI `mkdocs build --strict` passes on the pull request.
- [ ] No secrets, user names or machine-specific paths are in the diff.
- [ ] The user has run the manual deployment steps on this machine and confirmed the Apple glyph
      and the Macchiato colors in Terminal.app.
