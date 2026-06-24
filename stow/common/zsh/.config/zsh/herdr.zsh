# herdr.zsh — Herdr completion. Guarded; no-op without `herdr`.
#
# Herdr ships NO native zsh completion (no _herdr on fpath, no `herdr completion`
# subcommand), so this file AUTHORS the completion and registers it with compdef —
# unlike taskfile.zsh, which only tunes the package-shipped _task. Sourced after
# compinit (owned by plugins.zsh, ADR-0049). jq is preferred for parsing; an awk
# fallback keeps session completion working without jq. Nothing here starts, stops,
# attaches, or otherwise mutates a session — only read-only `herdr session list`.

command -v herdr >/dev/null 2>&1 || return

# Dynamic session-name candidates from the live, read-only session list.
_herdr_sessions() {
  local -a sessions

  if command -v jq >/dev/null 2>&1; then
    sessions=("${(@f)$(herdr session list --json 2>/dev/null \
      | jq -r '.sessions[]?.name // empty' 2>/dev/null)}")
  else
    sessions=("${(@f)$(herdr session list 2>/dev/null | awk 'NR > 1 {print $1}')}")
  fi

  compadd -a sessions
}

_herdr() {
  local context state line
  typeset -A opt_args

  _arguments -C \
    '--session[attach to a named Herdr session]:session:_herdr_sessions' \
    '--remote[attach to a remote Herdr host]:remote host:_hosts' \
    '--remote-keybindings[choose keybindings source]:(local server)' \
    '--handoff[use live handoff when supported]' \
    '--no-session[single-process escape hatch]' \
    '--default-config[print default config]' \
    '--version[print version]' \
    '1:command:(session config server status workspace worktree tab pane agent terminal wait integration plugin update channel notification)' \
    '*::arg:->args'

  case "$line[1]" in
    session)
      _arguments -C \
        '1:session command:(list attach stop delete)' \
        '2:session name:_herdr_sessions' \
        '--json[print JSON]'
      ;;
  esac
}

compdef _herdr herdr

# fzf-tab preview for session names. Read-only: lists sessions and filters to the
# highlighted word; never mutates. Falls back to the plain table without jq.
zstyle ':fzf-tab:complete:herdr:*' fzf-preview \
  'herdr session list --json 2>/dev/null | jq -C --arg s "$word" '\''.sessions[]? | select(.name == $s)'\'' 2>/dev/null || herdr session list 2>/dev/null'
