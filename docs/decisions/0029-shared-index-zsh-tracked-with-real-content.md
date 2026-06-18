# Decision: `shared.zsh` and `index.zsh` Tracked with Real Safe Content

**Number:** 0029
**Date:** 2026-06-18
**Status:** Accepted
**Related:** ADR-0016, ADR-0021, Architecture-0009

## Context

Prior to this decision, the zsh package convention established by Architecture-0004 was
`.example`-only for files that might contain machine-specific values. `shared.zsh` and
`index.zsh` were already tracked as real filenames (not `.example`) by PRD-0007's
implementation, but `shared.zsh` still contained placeholder tokens (`YOUR_EDITOR`,
`YOUR_PAGER`) that prevented it from functioning as real configuration.

The question was: should `shared.zsh` be untracked (moved to git-ignored status, with
only `shared.zsh.example` committed) or should it be kept tracked and populated with
real safe values?

## Decision

Keep both `shared.zsh` and `index.zsh` tracked in git, and populate `shared.zsh` with
real, portable, safe values — replacing `YOUR_EDITOR` with `nvim` and `YOUR_PAGER`
with `less`.

"Safe to commit" is defined as: works on both macOS and Arch Linux without modification,
contains no real identity (name, email, hostname), no machine-specific absolute paths,
no secrets, tokens, or keys, and no install/clone/network calls.

## Consequences

- `shared.zsh` with `nvim` and `less` is safe to commit: both are portable tool names,
  not paths, and neither reveals any private information.
- The `.example` counterpart (`shared.zsh.example`) remains for new-machine documentation.
- Un-tracking would require `git rm --cached shared.zsh` and add confusion about which
  file is authoritative.
- `index.zsh` is already final and has no placeholders — its tracked status is unchanged.
- Future contributors see the real operating file, not only a template.
- If a user prefers a different editor or pager, they override in `local.zsh` (ADR-0023).
- Trade-off accepted: a committed tool preference (`nvim`) is a minor opinion but
  completely safe, portable, and overridable.
