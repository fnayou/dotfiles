# Status Sync Rules

These rules apply to all agents and all sessions.

`AGENTS.md` (§1–2) and `CLAUDE.md` each carry a "current status" block describing
implementation phase and Stow packages. These blocks are tracked state — they must match
reality. See `docs/decisions/0048-status-blocks-kept-in-sync-with-repo-state.md`.

## Required behaviour

- When a Stow package is **added**, **removed**, or **first stowed to `$HOME`**, update
  **both** status blocks in the **same commit** as the change.
- Keep the two blocks consistent with each other — they describe the same state.
- The blocks describe **prose state only** (phase, stowed-vs-not). Do **not** re-introduce
  a hand-maintained per-package list — point to `stow/common/` (and `stow/macos/`,
  `stow/arch/` when populated). The directory is the source of truth.

## Self-check before any commit that touches `stow/`

- [ ] Did this change add, remove, or first-stow a package?
- [ ] If yes: are both status blocks updated in this same commit?
- [ ] Do the two blocks agree with each other and with `stow/`?
