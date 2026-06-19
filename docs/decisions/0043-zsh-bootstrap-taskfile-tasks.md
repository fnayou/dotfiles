# Decision: `zsh:bootstrap` and `zsh:bootstrap:dry-run` as Mutating Taskfile Tasks for Zsh

**Number:** 0043
**Date:** 2026-06-19
**Status:** Accepted
**Supersedes:** N/A
**Related:** ADR-0002, ADR-0009, ADR-0032, ADR-0027

## Context

ADR-0032 authorized the first mutating Taskfile tasks (`git:bootstrap`, `git:bootstrap:dry-run`)
and required that any future mutating tasks meet these conditions:
- User-invoked only, never automatic
- Idempotent
- Backup-creating
- Scoped to a minimal, safe change
- Never a dependency of another task

After the zsh package is stowed, `~/.config/zsh/index.zsh` is symlinked but not yet active.
The user's `~/.zshrc` must contain a guarded include block to source it. Without a task for
this, wiring the managed layer is a manual, error-prone step.

ADR-0027 explicitly states that `~/.zshrc` stays unmanaged and must not be symlinked.

## Decision

Add two tasks to `Taskfile.yml`:

- `zsh:bootstrap:dry-run` — previews what would change. Never writes any file.
- `zsh:bootstrap` — appends the managed block to `~/.zshrc` if absent. Idempotent.
  Creates a timestamped backup before any modification.

**Managed block** (appended once, checked-before-append):

```
# >>> dotfiles managed zsh layer >>>
if [[ -r "$HOME/.config/zsh/index.zsh" ]]; then
  source "$HOME/.config/zsh/index.zsh"
fi
# <<< dotfiles managed zsh layer <<<
```

**Safety invariants (all must hold):**
- Refuses if `~/.zshrc` is a symlink — will not write into a managed symlink target.
- Creates timestamped backup (`~/.zshrc.bak.YYYYMMDDHHMMSS`) before any write.
- Idempotent: checks for block marker before appending. A second run does nothing.
- Appends only — never overwrites or removes existing content.
- Never touches `~/.config/zsh/local.zsh`, never runs Stow, never installs dependencies.
- Never called by another task, never triggered automatically.

All ADR-0032 conditions are met.

## Consequences

- Users run `task zsh:bootstrap:dry-run` first to preview, then `task zsh:bootstrap`.
- The backup provides a rollback path (restore backup, or remove/comment the managed block).
- Running `zsh:bootstrap` twice is safe — no duplicate blocks, no errors.
- `~/.zshrc` stays unmanaged per ADR-0027; only a single, removable block is appended.
