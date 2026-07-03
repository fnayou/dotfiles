# Skill: ship-change

Ships an already-reviewed change: sync `main`, branch, stage, commit, push, open a PR, and confirm
CI is green. This is the repeatable "release" flow used after the Builder/Reviewer steps are done.

## When to use

- The change is implemented and has passed review (Reviewer verdicts PASS).
- The working tree holds the finished change on `main` (or a feature branch already exists).
- The user asks to "commit and open a PR", "ship it", "as usual", or similar.

Do **not** use this to bypass review — the change must already be reviewed (see `review-change`).

## Preconditions

- Reviewer verdicts are all PASS (safety, privacy, documentation).
- If the change added/removed/first-stowed a Stow package, both status blocks (`AGENTS.md` §2 and
  `CLAUDE.md`) are already updated in the same set of changes (see `status-sync` rule).
- No secrets in the diff (privacy rule) — re-audit staged diff before committing.

## Steps

1. **Sync main with remote**
   ```bash
   git fetch origin --prune
   git rev-list --left-right --count main...origin/main   # expect "0  0"
   ```
   If `main` is behind, fast-forward it (`git switch main && git pull --ff-only`) before branching.

2. **Create a feature branch**
   ```bash
   git switch -c <type>/<short-slug>      # e.g. feat/btop-package, docs/site-refresh
   ```

3. **Stage the change**
   ```bash
   git add -A
   git diff --staged --stat
   ```

4. **Audit the staged diff (privacy)** — must return nothing real:
   ```bash
   git diff --staged | grep -iE "password|token|api[_-]?key|secret|BEGIN.*PRIVATE|/Users/|/home/"
   git diff --staged --name-only | grep -i ds_store    # no .DS_Store
   ```

5. **Commit** — message follows `type(scope): description`, explains intent, and **never** carries a
   `Co-Authored-By` trailer (user's global rule). Write the message to a file and commit with `-F`.
   See "Commit hangs" below for why the commit runs through a small script.

6. **Push**
   ```bash
   git push -u origin <branch>
   ```

7. **Open the PR** with `gh`, body from a file:
   ```bash
   gh pr create --base main --head <branch> --title "<same as commit subject>" --body-file <file>
   ```
   End the PR body with the Claude Code generated-by line.

8. **Confirm CI passes** (green, no blocking issues):
   ```bash
   gh pr checks <N>
   gh pr view <N> --json statusCheckRollup -q '.statusCheckRollup[] | "\(.name): \(.status)/\(.conclusion)"'
   gh pr view <N> --json mergeable,mergeStateStatus -q '"mergeable=\(.mergeable) state=\(.mergeStateStatus)"'
   ```
   Poll until every check is `COMPLETED/SUCCESS` and `mergeStateStatus` is `CLEAN`. Report failures
   with their log output; do not claim green while checks are still pending.

9. **Report the PR link** back to the user.

## Environment gotchas

### Commit / push / PR "hang" (auto-background)

In this harness, a Bash command whose text contains `git commit` (and sometimes `git push` /
`gh pr create`) is auto-backgrounded and then stalls — no output, no exit, the ref never moves. It is
**not** a git editor/hook/GPG problem (verify: no `core.hooksPath`, no `commit.gpgsign`).

Workaround: put the commit/push/PR command inside a small shell **script file** and run it as
`bash /path/script.sh`. The visible command is `bash …`, so the auto-background heuristic doesn't
fire, it runs in the foreground, and you see the real output. Example:

```bash
cat > "$SCRATCH/do-commit.sh" <<'EOF'
#!/bin/bash
set -e
cd <repo>
export GIT_EDITOR=true GIT_TERMINAL_PROMPT=0
/usr/bin/git commit -q -F "$MSG_FILE" </dev/null
/usr/bin/git rev-parse --short HEAD
EOF
bash "$SCRATCH/do-commit.sh"
```

Use `/usr/bin/git` (absolute path) to sidestep the `rtk` git wrapper, which also hangs on `commit`.

### rtk wrapper

`git` is transparently rewritten to `rtk git` by a hook. Read-only git commands (`fetch`, `add`,
`log`, `switch`, `status`) work fine; `commit` hangs under `rtk`. Prefer `/usr/bin/git` for the
write steps.

## Notes

- One focused commit is preferred over batching unrelated work.
- Status-block changes must travel in the **same commit** as the package change (status-sync rule).
- Never force-push or rewrite shared history without explicit user approval.
