# Review: Taskfile/fzf-tab Completion — Implementation Review

**Number:** 0047
**Status:** Complete
**Date:** 2026-06-22
**Plan reviewed:** 0019 — Implement Native Taskfile Completion (go-task + fzf-tab)
**Files reviewed:**
- `stow/common/zsh/.config/zsh/plugins.zsh`
- `stow/common/zsh/.config/zsh/completions.zsh`
- `stow/common/zsh/.config/zsh/taskfile.zsh` (new)
- `stow/common/zsh/.config/zsh/index.zsh`
- `stow/common/zsh/.config/zsh/local.zsh.example`
- `stow/common/zsh/.config/zsh/aliases.zsh`
- `docs/decisions/0049-compinit-moves-to-plugins-for-fzf-tab-order.md` (new)
- `docs/decisions/0046-compinit-unconditional-zinit-light-mode.md`
- `stow/common/zsh/README.md`

## Summary

Plan 0019 implemented in full: fzf-tab load-order fix (Option C), native go-task completion
styling, conservative read-only preview, ADR-0049, local.zsh.example cleanup, README update.
All checklist items pass. No blockers found.

## Blocking Issues

None.

## Implementation Checklist

**compinit runs exactly once:**
- Zinit-present path: `plugins.zsh` line 23 — one call, after `zsh-completions` fpath,
  before `fzf-tab`. ✅
- No-zinit fallback path: `plugins.zsh` line 34 — one call in the `else` branch before
  `return 1`. ✅
- `completions.zsh`: compinit call removed; comment updated to reference ADR-0049. ✅
- No other `compinit` call sites in any sourced zsh file. ✅

**Correct load order in `plugins.zsh`:**
1. `zinit blockf for zsh-users/zsh-completions` (fpath before compinit) ✅
2. `autoload -Uz compinit && compinit` ✅
3. `zinit light Aloxaf/fzf-tab` (after compinit) ✅
4. `zinit light zsh-users/zsh-syntax-highlighting` (widget-wrap after fzf-tab) ✅
5. `zinit light zsh-users/zsh-autosuggestions` (widget-wrap after fzf-tab) ✅

**Missing-tool startup safety:**
- Missing Zinit: `else` branch prints error, calls fallback `compinit`, then `return 1` —
  shell continues cleanly, completion works natively. ✅
- Missing `task`: `taskfile.zsh` line 8 `command -v task >/dev/null 2>&1 || return` — no-op. ✅
- Missing `fzf`: `:fzf-tab:complete:task:*` is a harmless `zstyle`; fzf-tab degrades to
  default completion menu if fzf is absent. ✅
- Missing `fzf-tab`: if plugin not loaded, the `zstyle` is unused — no error. ✅

**Taskfile completion behavior:**
- Guard: `command -v task >/dev/null 2>&1 || return` ✅
- Descriptions: `zstyle ':completion:*:*:task:*' verbose true` ✅
- Preview: `zstyle ':fzf-tab:complete:task:*' fzf-preview 'task --summary "$word" 2>/dev/null || task --list-all 2>/dev/null'` ✅
- Preview is read-only: uses `--summary` (prints text) and `--list-all` (prints list);
  never `--dry`/`-n`; both `2>/dev/null`; no task target executed. ✅
- Completion inserts only: standard zsh completion behavior — fzf-tab selection populates
  the command line, user presses Enter manually. ✅
- No launcher alias/function added. ✅
- No fzf-make added anywhere. ✅ (docs references only, correctly negating it)

**`index.zsh` sourcing:**
- Step 6 comment updated to "Completion styles (styles-only; compinit runs in plugins.zsh
  — see ADR-0049)". ✅
- Step 6b added: `[[ -r "$HOME/.config/zsh/taskfile.zsh" ]] && source "$HOME/.config/zsh/taskfile.zsh"` ✅
- Follows the `[[ -r ... ]] && source` pattern used by all other layers. ✅
- Correctly positioned after `completions.zsh` (after compinit) and before `keybindings.zsh`. ✅

**`local.zsh.example` cleanup:**
- Stale eza extended-aliases example removed (contradicted ADR-0042/0044). ✅
- Stale zoxide `--cmd cd` example removed (redundant with tools.zsh, ADR-0047). ✅
- Weather alias example retained (genuinely machine-specific). ✅

**ADR-0049:**
- Correctly explains both fzf-tab violations (loaded before compinit; loaded after widget
  plugins). ✅
- Decision block shows the correct interleaved order with numbered comments. ✅
- `Supersedes: 0046` in frontmatter. ✅
- "Why this supersedes ADR-0046" section accurately distinguishes location change from the
  one-compinit invariant (which is preserved). ✅

**ADR-0046:**
- Status updated to `Superseded by 0049`. ✅

**README.md:**
- `taskfile.zsh` row added to files table. ✅
- Plugin load order section documents canonical sequence. ✅
- go-task completion section explains workflow, brew/pacman requirement, non-package
  install limitation, and read-only preview. ✅

**Syntax check:** `zsh -n stow/common/zsh/.config/zsh/*.zsh` — ALL OK. ✅

## Non-Blocking Suggestions

- **N1 — `aliases.zsh` blank-line diff in context.** The diff shows a blank-line change
  near the bat guard (the `cat='bat'` move from earlier in this session). Not part of
  Plan 0019, but already present as an uncommitted change from before this build. No action
  needed for this review; flag it for commit grouping.
- **N2 — `taskfile.zsh` preview variable.** `$word` is the standard fzf-tab variable for
  the current completion word. Correct for `:fzf-tab:complete:task:*` context. No issue —
  noted for future reference if fzf-tab version ever renames the variable.

## Safety Verdict

PASS — no `stow --adopt`, no `$HOME` writes, no `rm`/`mv`/`ln -s` targeting `$HOME`, no
real-home stow. All changes confined to the repository tree.

## Privacy Verdict

PASS — no API keys, tokens, passwords, private hostnames, internal URLs, or work-specific
values in any changed file.

## Documentation Verdict

PASS — ADR-0049 complete and accurate; ADR-0046 marked superseded; README covers workflow,
dependency, and limitation.

## Recommended Next Action

**Approve and commit.** All three verdicts PASS, no blockers. Stage the files listed in
Plan 0019 (plus `aliases.zsh` if grouping the bat-guard fix from earlier in the session),
verify `git diff --staged` for secrets, then commit.
