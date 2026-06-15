# Safety Rules

These rules apply to all agents and all sessions.

## Forbidden actions

- Never delete real user dotfiles — deleted dotfiles cannot be recovered if not in version control.
- Never overwrite real user dotfiles — overwritten files may permanently lose user customizations.
- Never use `stow --adopt` automatically — it silently overwrites existing files with repository versions.
- Never run `rm` against `$HOME` or any path outside the repository — irreversible data loss.
- Never run `mv` against `$HOME` or any path outside the repository — moves are irreversible without backups.
- Never run `ln -s` creating symlinks in `$HOME` without explicit per-session user approval.
- Never overwrite existing symlinks in `$HOME` without explicit per-session user approval.
- Never modify files outside the repository root.

## Required approach

- Prefer **dry-run commands** — show what would happen before doing it.
- Prefer `.example`, `.sample`, or `.template` files for initial configuration.
- Any risky command must be **shown to the user, not executed**.
- When in doubt, stop and ask.

## Stow safety

Before any `stow` install command:

1. Run `stow --simulate` (dry run) first.
2. Show the output to the user.
3. Wait for explicit user approval.
4. Only then run the install command.

## Command safety markers

Mark dangerous commands clearly before showing them:

```
⚠️  MANUAL STEP — review output before running
```

Do not chain risky commands in a single copy-paste block without this marker.
