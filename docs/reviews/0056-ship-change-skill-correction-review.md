# Review: Correct the ship-change Skill's Hang Guidance

**Number:** 0056
**Status:** Complete
**Date:** 2026-07-30
**Plan reviewed:** None — corrective documentation fix (see Process Note)
**Branch:** `docs/correct-ship-change-hang-guidance`

**Files reviewed:**

- `.claude/skills/ship-change/SKILL.md`

---

## Summary

`ship-change` told agents that `rtk git commit` hangs and that `/usr/bin/git` should be used to
sidestep the wrapper. Both claims are wrong, and the second is actively harmful: the absolute path is
the one form that is **not** rewritten to `rtk git …`, so it matches no entry in
`.claude/settings.local.json` and queues a permission prompt instead of running.

The claims were tested rather than reasoned about, on rtk 0.44.1:

| Check | Result |
|---|---|
| `rtk hook claude` fed a `git commit` payload | returns in 0s, rewrites to `rtk git commit` |
| `rtk git commit -q -m …` in a throwaway repo | 0s, commit created |
| `: git commit` (literal text, runs nothing) | no stall |
| `/usr/bin/git status --short` | no stall |
| plain `git add && git commit`, direct Bash call | no stall |

What the observed stalls actually were: a permission prompt awaiting the user. `ps` during a stall
showed the shell wrapper in `sigsuspend` with **no git child process** — the command had never
started. Consistent with this, `.claude/settings.local.json` gained a `Bash(/usr/bin/git show *)`
entry during the session that is absent from that file's git history, which only happens through the
prompt flow.

One genuine hang remains, with a different cause: `git commit -F -` fed by a heredoc. The hook
rewrites the command string, the heredoc does not survive intact, and git waits forever on stdin.
The skill now bans `-F -` outright and requires `-F <file>`.

Changes:

1. "Commit / push / PR hang (auto-background)" replaced with "A silent stall is a pending permission
   prompt, not a hang", describing the `sigsuspend` / no-child signature.
2. "rtk wrapper" rewritten — prefer plain `git` so the rewrite lands on the allow-listed
   `Bash(rtk git *)`; do not reach for `/usr/bin/git`.
3. New section banning `git commit -F -`.
4. Script files reframed as a convenience for multi-step flows, with an honest note that they also
   sidestep prompts because the matcher inspects the visible command and not the script's contents.
5. Step 5 cross-reference repaired (it pointed at the deleted "Commit hangs" heading).
6. **Step 7 reversed** — it instructed agents to end PR bodies with the Claude Code generated-by
   line, contradicting the user's standing rule that commits and PRs carry no Claude trailer or
   footer. See Scope Note.

---

## Blocking Issues

None.

---

## Non-Blocking Suggestions

- **The permission-prompt explanation is strongly evidenced but not directly observed.** Prompts are
  not visible from inside a tool call, so the diagnosis rests on the process signature, the
  allow-list contents, and the unexplained `settings.local.json` entry. Stated in the skill as what
  a stall *is* — if a future stall turns out to have another cause, this section should be revisited
  rather than trusted.

- **`Bash(/usr/bin/git show *)` in `.claude/settings.local.json` is now dead weight.** The skill no
  longer recommends absolute-path git. Harmless, but it can be dropped.

- **Adding `Bash(git commit *)` to the allow-list would remove the remaining prompt surface.** Not
  done here — widening write permissions is the user's call, not a documentation fix.

---

## Safety Verdict

**PASS** — Documentation only. No `stow`, `rm`, `mv`, or `ln -s`. No file outside the repository was
modified. The guidance change makes agent behaviour *more* conservative in one respect: it removes
advice to bypass a wrapper that the permission allow-list is built around.

## Privacy Verdict

**PASS** — No credentials, tokens, hostnames, or personal data. The allow-list entries quoted are
already committed in `.claude/settings.local.json`.

## Documentation Verdict

**PASS** — Every claim in the new text is backed by a command that was run, and the measurements are
tabulated in the skill itself so a future reader can re-verify rather than trust. The dangling
cross-reference from step 5 is repaired. No dangerous commands were introduced, so no
`⚠️  MANUAL STEP` markers were needed.

---

## Process Note

Corrective documentation fix to a single file — no PRD, Architecture, or Plan, consistent with
reviews 0054 and 0055. Written before the commit.

## Scope Note

The user asked to "fix the skill" in the context of the hang guidance. Change 6 (the PR footer)
goes beyond that thread, and is included because it is a live contradiction with the user's standing
rule sitting in the same file — a future session following the skill verbatim would violate it. It
is called out here and in the PR so it can be reverted independently if unwanted.

---

## Recommended Next Action

Approve and open the PR. Confirm CI is green before merging.
