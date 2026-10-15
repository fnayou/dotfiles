# lms.zsh — LM Studio CLI completion. Guarded; no-op without `lms`.
#
# lms ships NO native zsh completion (no `_lms` on fpath, and `lms completion`
# errors with `unknown command 'completion'`), so this file AUTHORS the completion
# and registers it with compdef — same pattern as herdr.zsh. Sourced after compinit
# (owned by plugins.zsh, ADR-0049) via index.zsh (slot 6f).
#
# Subcommand trees validated against lms CLI commit 69d945a (2026-10). Subprocess
# usage from any completion path is strictly read-only: `lms ls --json`,
# `lms ps --json`, and `--help` forms. `lms get` stays local-only by design — no
# network/Hub search at completion time. Nothing mutating (load/unload/push/dev
# and friends) is ever run here; these functions only ADD candidates.

command -v lms >/dev/null 2>&1 || return

# Models available on disk — candidates for `lms load`. Read-only (`lms ls --json`).
# Prefer the selected variant key when one exists, else the model key. jq or nothing:
# the plain `lms ls` table is not stable enough to parse.
_lms_disk_models() {
  local -a models
  if command -v jq >/dev/null 2>&1; then
    models=("${(@f)$(lms ls --json 2>/dev/null | jq -r \
      '.[] | (.selectedVariant // .modelKey) // empty' 2>/dev/null)}")
  fi
  compadd -a models
}

# Models currently loaded in memory — candidates for `lms unload`. Read-only.
_lms_loaded_models() {
  local -a models
  if command -v jq >/dev/null 2>&1; then
    models=("${(@f)$(lms ps --json 2>/dev/null | jq -r \
      '.[].identifier // empty' 2>/dev/null)}")
  fi
  compadd -a models
}

_lms() {
  local context state line
  typeset -A opt_args

  _arguments -C \
    '(-h --help)'{-h,--help}'[show help]' \
    '--version[print version]' \
    '1:command:(
      chat
      get
      load
      unload
      ls
      ps
      import
      server
      log
      link
      runtime
      clone
      push
      dev
      login
      logout
      whoami
    )' \
    '*::arg:->args'

  case "$line[1]" in
    (server)
      _arguments -C '1:server command:(start stop status)' ;;
    (log)
      _arguments -C '1:log command:(stream)' ;;
    (link)
      _arguments -C '1:link command:(enable disable status set-device-name set-preferred-device)' ;;
    (runtime)
      _arguments -C '1:runtime command:(ls select remove update get survey)' ;;
    (load)
      _arguments -C \
        '1:model key:_lms_disk_models' \
        '--auto[auto-choose context length and placement]' \
        '--gpu[GPU offload ratio]:ratio:(off max 0 0.25 0.5 0.75 1)' \
        '(-c --context-length)'{-c=,--context-length=}'[context length]:length:' \
        '--ttl[seconds of inactivity before unload]:seconds:' \
        '--identifier[identifier to assign to the loaded model]:identifier:' \
        '(-y --yes)'{-y,--yes}'[auto-approve all prompts]' ;;
    (unload)
      _arguments -C \
        '1:identifier:_lms_loaded_models' \
        '(-a --all)'{-a,--all}'[unload all models]' ;;
    (ls)
      _arguments -C \
        '(--embedding)--llm[show only LLM models]' \
        '(--llm)--embedding[show only embedding models]' \
        '--variants[show variants for all models]' \
        '--json[output JSON]' ;;
    (ps)
      _arguments -C '--json[output JSON]' ;;
  esac
}

compdef _lms lms

# fzf-tab preview: the highlighted subcommand's own help, else the top-level help.
# Read-only only. For load/unload model lists, a filtered --json view:
zstyle ':fzf-tab:complete:lms:*' fzf-preview \
  'lms $word --help 2>/dev/null || lms --help 2>/dev/null'
zstyle ':fzf-tab:complete:lms:load:*' fzf-preview \
  'lms ls --json 2>/dev/null | jq -C --arg w "$word" '\''.[] | select((.selectedVariant // .modelKey) == $w) | {modelKey, displayName, paramsString}'\'' 2>/dev/null || lms ls 2>/dev/null'
zstyle ':fzf-tab:complete:lms:unload:*' fzf-preview \
  'lms ps --json 2>/dev/null | jq -C --arg w "$word" '\''.[] | select(.identifier == $w) | {identifier, modelKey, status}'\'' 2>/dev/null || lms ps 2>/dev/null'
