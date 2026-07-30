# ADR 0060 — Caveman's global mode flag is a known limitation, accepted as-is

**Status:** Accepted
**Date:** 2026-07-31
**Context:** PRD 0021, Architecture 0020

## Context

Caveman stores the active mode in **one file for the whole machine**:

```
~/.claude/.caveman-active      # contents: "full"
```

`caveman-mode-tracker.js` (a `UserPromptSubmit` hook) writes it with
`safeWriteFlag` when it sees `/caveman <mode>` or a natural-language activation,
and **deletes** it on `/caveman off`, "stop caveman", "normal mode" and similar.

The file has no session dimension. Consequences today, before any change of ours:

1. Two concurrent Claude Code sessions cannot run different caveman modes. The
   most recent `/caveman <mode>` wins for both.
2. Typing `/caveman off` in session B silently disables caveman in session A,
   including A's per-turn reinforcement.
3. The same applies to the mode badge: both sessions show whichever mode was set
   last, not their own.

Our segment reads that flag with caveman's `readFlag`, so it inherits all three.
There is a further consequence specific to this feature: the savings estimate
multiplies output tokens by the ratio for the *current* mode, so if the mode
changes mid-session the reported figure for that session shifts, even for turns
that ran under the previous mode.

## Decision

Do not change it. Read the global flag, document the limitation, and keep the
per-session state we do own (savings) strictly separate from it.

## Rationale

- Fixing it properly means session-scoped mode state — writing
  `~/.claude/caveman/sessions/<session-id>/mode` and teaching the mode tracker,
  the statusline and the per-turn reinforcement hook to prefer it, with fallback
  to the global flag for backward compatibility. All three of those live in the
  plugin checkout that upgrades overwrite (ADR 0056), so the change would have to
  go upstream or into a fork.
- It is not required for the requested statistics. Session savings come from the
  transcript (ADR 0057) and repository savings from our own ledger (ADR 0058);
  neither needs per-session mode to be correct in the single-mode case, which is
  the normal case.
- PRD 0021 explicitly scopes redesigning caveman out.

## Consequences

- Two sessions in different repositories running at once will show the same mode
  badge, and their savings will both be estimated with that mode's ratio. Their
  **token figures remain independent and correct per session**, because those
  come from separate transcripts.
- Documented in `stow/common/claude/README.md` and
  `docs/guides/claude-setup.md` so the behaviour is not rediscovered as a bug.
- If the limitation becomes painful, the minimal upstream-shaped fix is:
  1. `caveman-mode-tracker.js` writes `<claudeDir>/caveman/sessions/<session_id>/mode`
     using the `session_id` it already receives on stdin, in addition to the
     global flag.
  2. `readFlag` callers try the session path first, then the global flag.
  3. `/caveman off` removes the session file; the global flag is only removed
     when no session files remain.
  That keeps every existing installation working unchanged, which is why it is
  recorded here rather than attempted locally.
