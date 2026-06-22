# taskfile.zsh — go-task (Taskfile) completion tuning. Guarded; no-op without `task`.
#
# Native completion comes from the package-shipped `_task` file on the default fpath
# (Homebrew: .../share/zsh/site-functions/_task; Arch: /usr/share/zsh/site-functions/_task),
# autoloaded by compinit via its `#compdef task` tag. This file only tunes presentation.
# Sourced after compinit. Nothing here installs, fetches, or executes a task.

command -v task >/dev/null 2>&1 || return

# Show task descriptions in completion candidates (fzf-tab renders this list).
zstyle ':completion:*:*:task:*' verbose true

# Conservative fzf-tab preview: read-only. `--summary` prints the highlighted task's
# summary text; falls back to `--list-all` when the task has no summary so the pane is
# never empty. Both subcommands print text only and never execute a task target.
zstyle ':fzf-tab:complete:task:*' fzf-preview \
  'task --summary "$word" 2>/dev/null || task --list-all 2>/dev/null'
