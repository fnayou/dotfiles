# Review: Claude Code Statusline Package — Implementation

**Number:** 0058
**Status:** Complete
**Date:** 2026-07-31
**Plan reviewed:** 0020 — Implement Claude Code Statusline Package
**PRD:** 0017 · **Architecture:** 0017

**Files reviewed:**

- `stow/common/claude/.claude/statusline-command.sh`
- `stow/common/claude/.stow-local-ignore`
- `stow/common/claude/README.md`
- `docs/guides/claude-setup.md`
- machine state: `~/.claude/statusline-command.sh`, `~/.claude/settings.json`

---

## Summary

Retrospective implementation review for **Plan 0020 — Implement Claude Code Statusline Package**.
Like Plan 0016, it shipped without a review and sat at `Approved`.

Verification against the running machine found **one blocking defect**, fixed in this same change
before marking the plan Complete. Everything else passes.

| Check | Result |
|---|---|
| `statusline-command.sh` present, executable | yes |
| `bash -n` syntax clean | pass |
| `.stow-local-ignore`, `README.md` present | yes |
| `docs/guides/claude-setup.md` present | yes |
| `~/.claude/statusline-command.sh` symlinked into the repo | yes |
| `~/.claude/settings.json` `statusLine` wiring | present and correct |
| No machine-specific absolute paths in the script | confirmed |
| Script executes against a real payload | rc=0, renders all segments |

---

## Blocking Issue — found and fixed

**`statusline-command.sh:105` — `stat` invocation was not OS-portable.** Plan 0020 task 2 requires
the script match the approved "single-file, **OS-portable**, no-secrets design", so this blocked
completion until fixed.

Original:

```bash
mtime=$(stat -f %m "$cache_file" 2>/dev/null || stat -c %Y "$cache_file" 2>/dev/null || echo 0)
```

The intent is "try the BSD/macOS form, fall back to GNU". It fails on Linux in a way the `||` chain
cannot absorb: GNU `stat -f` means `--file-system`. It exits non-zero **but still writes a
filesystem block to stdout**. Command substitution captures that, then the fallback appends the real
timestamp, so `$mtime` becomes the filesystem dump concatenated with a number:

```
line 106: ((: File: "/home/…/mr_github__…"
    ID: eb7f2aaed9c14a98 Namelen: 255  Type: ext2/ext3
    … 1785448784: arithmetic syntax error in expression
```

**Impact:** `(( now - mtime > ttl ))` throws and evaluates false, so the PR/MR lookup **never
refreshes on Linux** — the segment is frozen at whatever first landed in the cache. It only triggers
once the cache file exists, which is why it survived initial review, and Claude Code swallows
statusline stderr, so it was invisible in normal use.

Fix — GNU form first, plus a numeric guard:

```bash
mtime=$(stat -c %Y "$cache_file" 2>/dev/null || stat -f %m "$cache_file" 2>/dev/null || echo 0)
[[ "$mtime" =~ ^[0-9]+$ ]] || mtime=0
```

The reversed order is safe on both platforms: BSD/macOS `stat` rejects `-c` with a usage error on
**stderr and nothing on stdout**, so its fallback is clean — the precise asymmetry that made the
original order fail.

**Verified by A/B run** against the same payload, with the cache file present (the triggering
condition):

| Version | stdout | stderr |
|---|---|---|
| Original (HEAD) | 248 bytes | **862 bytes** — arithmetic syntax error |
| Fixed | 248 bytes | **0 bytes** |

---

## Non-Blocking Suggestions

- **macOS is unverified by execution.** The fix is reasoned from BSD `stat` semantics and confirmed
  on Linux only; no macOS host was available. The failure mode there would be the mirror image
  (`stat -c` rejected, `stat -f %m` used), which is the documented BSD behaviour, but it is
  inference rather than measurement.

- **The privacy audit produces a false positive.** Grepping the script for
  `token` matches three comments about *context tokens* and *token savings*. Reviewers should not
  read that as a finding.

- **No regression test exists.** This defect was invisible because stderr is discarded. A cheap
  guard would be a check that the script emits nothing on stderr for a sample payload; there is no
  test harness in this repository today, so none was added.

---

## Safety Verdict

**PASS** — No `stow --adopt`, `rm`, `mv`, or `ln -s` against `$HOME`. The fix touches two lines of a
read-only status renderer. All install/delete commands in the guide and README carry
`⚠️  MANUAL STEP` markers.

## Privacy Verdict

**PASS** — No credentials, tokens, or machine-specific absolute paths in the script (the `token`
grep hits are comments — see above). The cache path is derived at runtime from `XDG_CACHE_HOME`/
`$HOME`, not hard-coded.

## Documentation Verdict

**PASS** — README and `docs/guides/claude-setup.md` accurately describe the package, the exclusion
list, and the `--no-folding` workflow. The fix is internal to one line and changes no documented
behaviour, so no guide edits were required.

---

## Plan Status

Plan 0020 is marked **Complete** in this change. The blocking issue above was fixed within the same
change, so completion reflects a package that now satisfies the OS-portability requirement rather
than one that was assumed to.

---

## Recommended Next Action

Approve and merge. Re-verify on macOS opportunistically.
