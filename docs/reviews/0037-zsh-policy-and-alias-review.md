# Review Note: Zsh Personal-Configuration Policy and Alias Update

**Document:** docs/reviews/0037-zsh-policy-and-alias-review.md
**Follows:** docs/reviews/0036-real-zsh-blocker-fixes-review.md
**Date:** 2026-06-19
**Status:** Complete

---

## Verdict

**Approved for commit.**

All three prior blockers are resolved. ADR-0044 establishes the correct policy for a private personal dotfiles repository. No safety, privacy, or correctness issues found.

---

## Blocker Re-evaluation

| # | Blocker (from review 0035) | Status | Rationale |
|---|---------------------------|--------|-----------|
| B1 | `completions.zsh` double compinit with Zinit | Resolved | `typeset -f zinit` guard present at line 3. No bare `compinit`. ADR-0039 satisfied. |
| B2 | `aliases.zsh` opinionated eza aliases | Resolved — policy updated | ADR-0044 supersedes ADR-0037 and ADR-0042. Guarded personal aliases are now explicitly permitted in this private personal repo. All eza aliases inside single `command -v eza` guard. |
| B3 | `tools.zsh` duplicate `ls` alias | Resolved | `tools.zsh` contains only `fzf` and `zoxide` initializations. No `alias ls=`. `aliases.zsh` is sole owner. |

---

## Policy Checks

| Check | Result | Evidence |
|---|--------|----------|
| ADR-0044 accepted | Pass | `**Status:** Accepted` in 0044 |
| ADR-0037 superseded | Pass | `**Status:** Superseded by 0044` |
| ADR-0042 superseded | Pass | `**Status:** Superseded by 0044` |
| Policy permits guarded personal aliases | Pass | ADR-0044 §Decision lists six conditions; eza aliases satisfy all |
| `local.zsh` policy documented | Pass | ADR-0044 defines `local.zsh` scope: private paths, work-specific, credentials, machine-specific, secrets, temporary |

---

## Alias Checks

| Check | Result | Evidence |
|---|--------|----------|
| `aliases.zsh` eza block is guarded | Pass | `command -v eza >/dev/null 2>&1 && { ... }` wraps all eza aliases |
| `aliases.zsh` aliases: `ls`, `ll`, `la`, `lt`, `tree` | Pass | All five inside guard block |
| No eza flags committed without guard | Pass | All eza aliases inside the block; no bare `alias ll=` at top level |
| `tools.zsh` no duplicate `ls` alias | Pass | `grep "alias ls=" tools.zsh` → no matches |
| `alias rm='rm -i'` is safeguarded | Pass | `-i` flag prompts before delete — explicitly permitted by ADR-0044 |
| `alias cp='cp -iv'`, `alias mv='mv -iv'` | Pass | Safety flags; non-destructive |
| `alias meteo=` (wttr.in) | Pass | Public service, no secrets, no private hostname, personal daily-use alias — permitted by ADR-0044 |
| No destructive unguarded aliases | Pass | No bare `rm -rf` aliases or similar |

---

## Safety Checks

| Check | Result | Evidence |
|---|--------|----------|
| No secrets, credentials, tokens | Pass | `grep -rE 'token\|secret\|password\|api.key'` → no matches |
| No private hostnames or company-specific commands | Pass | `wttr.in` is a public service; no internal URLs |
| No machine-specific absolute paths | Pass | `grep -rE '/Users/fnayou\|/home/fnayou' aliases.zsh` → no matches |
| No `$HOME` files modified | Pass | `git diff --name-only HEAD` shows only `stow/` and `docs/` changes |
| No real-home Stow run | Pass | No evidence of stow execution against `$HOME` |
| `zsh:bootstrap` not run | Pass | `~/.zshrc` unchanged |
| `aliases.zsh` passes `zsh -n` | Pass | Exit 0 |
| `tools.zsh` passes `zsh -n` | Pass | Exit 0 |
| `completions.zsh` passes `zsh -n` | Pass | Exit 0 |
| `local.zsh` not tracked | Pass | `git ls-files stow/common/zsh/.config/zsh/local.zsh` → no output |

---

## Conclusion

The policy update (ADR-0044) correctly reflects the repository's nature as a private personal dotfiles repo. The previous blocker criterion of "minimal/uncontroversial only" was appropriate for shared templates but incorrect for owned personal configuration. All eza aliases are guarded, non-destructive, and satisfy ADR-0044's six conditions. The compinit fix from review 0036 holds. No safety or privacy issues detected. The implementation is approved for commit.
