# Decision: Personal Preferences Permitted in Committed Managed Zsh Files

**Number:** 0044
**Date:** 2026-06-19
**Status:** Accepted
**Supersedes:** ADR-0037, ADR-0042
**Related:** ADR-0023, ADR-0026, ADR-0033

## Context

ADR-0037 and ADR-0042 restricted committed zsh files to minimal, uncontroversial aliases only. That policy was appropriate when committed files were `.example` templates intended as a conservative baseline that any user (or future contributor) might copy — imposing strong aliases on unknown workflows was risky.

The repository now commits real managed files that represent the owner's actual dotfiles. There is no multi-user ambiguity: this is a private personal repository. Forcing personal daily-use preferences into the untracked `local.zsh` creates unnecessary friction and defeats the purpose of version control.

## Decision

Committed managed zsh files in this repository may contain personal daily-use configuration, including aliases, prompt preferences, editor/pager choices, completion styles, history settings, and optional-tool preferences — provided all of the following conditions are met:

**Permitted if ALL hold:**
1. No secrets, credentials, tokens, or API keys.
2. No private hostnames, internal URLs, or company-specific commands.
3. No machine-specific absolute paths (use `$HOME`-relative or `$XDG_*` paths).
4. No destructive aliases without explicit safeguards (e.g., `rm -i` is acceptable; bare `rm -rf` aliases are not).
5. Optional tools are guarded with `command -v <tool> >/dev/null 2>&1`.
6. Behavior is safe on both macOS and Linux, or is explicitly OS-gated (in `macos.zsh` or `arch.zsh`).

**`local.zsh` remains untracked and is used only for:**
- Private paths (work binaries, internal tools).
- Work-specific aliases or commands.
- Machine-specific overrides that differ between personal machines.
- Credentials, tokens, secrets.
- Temporary experiments not ready to commit.
- Non-portable behavior that cannot be OS-gated.

**Alias ownership:**
- Each alias must have a single authoritative location. Duplicate alias definitions across files are not permitted unless load order intentionally overrides and this is documented.
- `aliases.zsh` owns portable aliases, including guarded eza aliases.
- `tools.zsh` owns tool initialization (`fzf --zsh`, `zoxide init`) and must not define aliases already owned by `aliases.zsh`.

**Invariants that still hold regardless of this decision:**
- Zinit must not auto-clone.
- Shell startup must not install dependencies or perform network access.
- `~/.zshrc` must remain unmanaged.
- `local.zsh` must remain untracked.
- No secrets or private paths may be committed.

## Consequences

- `aliases.zsh` may commit daily-use eza aliases (`ls`, `ll`, `la`, `lt`, `tree`) as long as they are guarded with `command -v eza`.
- `local.zsh.example` documents the pattern for private overrides.
- The reviewer criterion of "minimal/uncontroversial only" from ADR-0037 and ADR-0042 no longer applies to committed managed files. Those ADRs are superseded.
- Future alias additions must satisfy the six conditions above, not a conservatism criterion.
- The distinction between "committed" and "private" is now: safe + portable + personal = committed; private + machine-specific + secret = `local.zsh`.
