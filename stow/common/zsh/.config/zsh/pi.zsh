# pi.zsh — pi coding agent CLI completion. Guarded; no-op without `pi`.
#
# pi ships NO native zsh completion (no `_pi` on fpath, and `pi completion zsh` prints no
# script), so this file AUTHORS the completion and registers it with compdef — same pattern as
# lms.zsh and herdr.zsh. Sourced after compinit (owned by plugins.zsh, ADR-0049) via index.zsh
# (slot 6h).
#
# Command and option trees validated against pi 1.5.2 (2026-11). Extension flags (for example
# --plan) are not known here; zsh falls back to file completion for them.
#
# Subprocess use from any completion path is strictly read-only: `pi --list-models`, `pi list`,
# and a `jq` read of the key NAMES of ~/.pi/agent/mcp.json. Never run here: `pi mcp list` (it
# starts servers), `pi auth ...`, install, update, remove. Nothing here reads credentials,
# sessions or server values; these functions only ADD candidates (ADR-0088).

command -v pi >/dev/null 2>&1 || return 0

# Models pi knows, as provider/id (pi's own syntax). Read-only; the table is local and fast.
_pi_models() {
  local -a models
  models=("${(@f)$(pi --list-models 2>/dev/null \
    | awk '$1 == "provider" { h = 1; next } h && NF >= 2 { print $1 "/" $2 }')}")
  models=(${models:#})
  (( $#models )) || return 0
  compadd -- "${models[@]}"
}

# Provider names, one each. Read-only.
_pi_providers() {
  local -a providers
  providers=("${(@f)$(pi --list-models 2>/dev/null \
    | awk '$1 == "provider" { h = 1; next } h && NF >= 2 && !seen[$1]++ { print $1 }')}")
  providers=(${providers:#})
  (( $#providers )) || return 0
  compadd -- "${providers[@]}"
}

# Installed package sources (first field of each two-space-indented line of `pi list`).
_pi_packages() {
  local -a pkgs
  pkgs=("${(@f)$(pi list 2>/dev/null | awk '/^  [^ ]/ { print $1 }')}")
  pkgs=(${pkgs:#})
  (( $#pkgs )) || return 0
  compadd -- "${pkgs[@]}"
}

# MCP server names: the keys under .mcpServers, nothing else. jq or nothing. Values (commands,
# URLs, environment, headers) are never read into a candidate.
_pi_mcp_servers() {
  local -a names
  command -v jq >/dev/null 2>&1 || return 0
  names=("${(@f)$(jq -r '(.mcpServers // {}) | keys[]' "$HOME/.pi/agent/mcp.json" 2>/dev/null)}")
  names=(${names:#})
  (( $#names )) || return 0
  compadd -- "${names[@]}"
}

_pi() {
  local context state line
  typeset -A opt_args

  _arguments -C \
    '(-h --help)'{-h,--help}'[show help]' \
    '(-v --version)'{-v,--version}'[print version]' \
    '--provider=[provider to search for --model]:provider:_pi_providers' \
    '--model=[model pattern or ID]:model:_pi_models' \
    '--api-key=[API key]:key:' \
    '--system-prompt=[system prompt text]:text:' \
    '*--append-system-prompt=[append text or file to the system prompt]:text or file:_files' \
    '--mode=[output mode]:mode:(text json rpc)' \
    '(-p --print)'{-p,--print}'[non-interactive: process the prompt and exit]' \
    '(-c --continue)'{-c,--continue}'[continue the most recent session]' \
    '(-r --resume)'{-r,--resume}'[pick a session to resume]' \
    '--session=[open a session by path or ID]:session:_files' \
    '--session-id=[use the current directory session with this ID]:id:' \
    '--fork=[fork a session into the current directory]:session:_files' \
    '--session-dir=[session storage directory]:directory:_files -/' \
    '--no-session[do not save the session]' \
    '(-n --name)'{-n,--name}'[session display name]:name:' \
    '--models=[model patterns for Ctrl+P cycling]:patterns:' \
    '(-nt --no-tools)'{-nt,--no-tools}'[disable all tools by default]' \
    '(-nbt --no-builtin-tools)'{-nbt,--no-builtin-tools}'[disable built-in tools only]' \
    '(-t --tools)'{-t,--tools}'[tool allowlist]:tools:' \
    '(-xt --exclude-tools)'{-xt,--exclude-tools}'[tool denylist]:tools:' \
    '--thinking=[thinking level]:level:(off minimal low medium high xhigh max)' \
    '*'{-e,--extension}'[load an extension file or builtin:name]:extension:_files' \
    '(-ne --no-extensions)'{-ne,--no-extensions}'[disable extension discovery]' \
    '--no-mcp[disable built-in MCP support]' \
    '*--skill=[load a skill file or directory]:skill:_files' \
    '(-ns --no-skills)'{-ns,--no-skills}'[disable skills]' \
    '*--prompt-template=[load a prompt template file or directory]:template:_files' \
    '(-np --no-prompt-templates)'{-np,--no-prompt-templates}'[disable prompt templates]' \
    '*--theme=[load a theme file or directory]:theme:_files' \
    '--no-themes[disable themes]' \
    '--use-theme=[initial theme]:theme:' \
    '(-nc --no-context-files)'{-nc,--no-context-files}'[skip AGENTS.md and CLAUDE.md]' \
    '--export=[export a session file to HTML and exit]:session file:_files' \
    '--list-models[list available models]' \
    '--verbose[force verbose startup]' \
    '--tui-mode=[TUI mode]:mode:(fullscreen regular)' \
    '(-a --approve -na --no-approve)'{-a,--approve}'[trust project-local files for this run]' \
    '(-a --approve -na --no-approve)'{-na,--no-approve}'[ignore project-local files for this run]' \
    '--offline[disable startup network operations]' \
    '1:command:(
      install
      remove
      uninstall
      update
      list
      config
      auth
      mcp
    )' \
    '*::arg:->args'

  case "$line[1]" in
    (install)
      _arguments -C \
        '1:source:_files' \
        '(-l --local)'{-l,--local}'[install project-locally]' \
        '(-a --approve -na --no-approve)'{-a,--approve}'[trust project-local files]' \
        '(-a --approve -na --no-approve)'{-na,--no-approve}'[ignore project-local files]' ;;
    (remove|uninstall)
      _arguments -C \
        '1:package:_pi_packages' \
        '(-l --local)'{-l,--local}'[remove from project settings]' \
        '(-a --approve -na --no-approve)'{-a,--approve}'[trust project-local files]' \
        '(-a --approve -na --no-approve)'{-na,--no-approve}'[ignore project-local files]' ;;
    (update)
      _arguments -C \
        '1:target:(self pi)' \
        '(--extensions --models --all)--self[update pi only]' \
        '(--self --models --all)--extensions[update installed packages only]' \
        '(--self --extensions --all)--models[refresh model catalogs only]' \
        '(--self --extensions --models)--all[update pi and installed packages]' \
        '--extension=[update one package only]:package:_pi_packages' \
        '--force[reinstall pi even if current]' \
        '(-a --approve -na --no-approve)'{-a,--approve}'[trust project-local files]' \
        '(-a --approve -na --no-approve)'{-na,--no-approve}'[ignore project-local files]' ;;
    (list)
      _arguments -C \
        '(-a --approve -na --no-approve)'{-a,--approve}'[trust project-local files]' \
        '(-a --approve -na --no-approve)'{-na,--no-approve}'[ignore project-local files]' ;;
    (config)
      _arguments -C \
        '(-l --local)'{-l,--local}'[edit project overrides]' \
        '(-a --approve -na --no-approve)'{-a,--approve}'[trust project-local files]' \
        '(-a --approve -na --no-approve)'{-na,--no-approve}'[ignore project-local files]' ;;
    (auth)
      _arguments -C \
        '1:auth command:(login logout print-api-key print-bearer-token check)' \
        '*::arg:->authargs'
      case "$line[1]" in
        (login)
          _arguments -C \
            '1:provider:_pi_providers' \
            '--api-key[save an API key instead of signing in]' \
            '--no-browser[do not open a browser]' ;;
        (logout)
          _arguments -C '1:provider:_pi_providers' ;;
        (print-api-key)
          _arguments -C \
            '--provider=[provider]:provider:_pi_providers' \
            '--model=[model]:model:_pi_models' ;;
        (print-bearer-token)
          _arguments -C \
            '--provider=[provider]:provider:_pi_providers' \
            '--model=[model]:model:_pi_models' \
            '--min-expiry=[minimum remaining lifetime]:duration:' ;;
        (check)
          _arguments -C \
            '--provider=[provider]:provider:_pi_providers' \
            '--model=[model]:model:_pi_models' \
            '--json[output JSON]' \
            '--credentials[include credential details]' \
            '--no-refresh[do not refresh expired tokens]' ;;
      esac ;;
    (mcp)
      _arguments -C \
        '1:mcp command:(add remove list login logout)' \
        '*::arg:->mcpargs'
      case "$line[1]" in
        (add)
          _arguments -C \
            '1:server name:' \
            '--url=[streamable HTTP server URL]:url:' \
            '*--env=[environment variable for a stdio server]:KEY=VALUE:' \
            '--cwd=[working directory for a stdio server]:directory:_files -/' \
            '*--header=[HTTP header]:KEY=VALUE:' \
            '--bearer-token-env-var=[send Authorization: Bearer from this variable]:name:' \
            '--oauth-client-id=[pre-registered OAuth client id]:id:' \
            '--oauth-client-secret=[OAuth client secret]:secret:' \
            '--oauth-callback-port=[fixed OAuth callback port]:port:' \
            '--oauth-client-name=[client name sent when registering]:name:' \
            '--oauth-client-registration=[registration mode]:mode:(auto cimd dcr)' \
            '--exposure=[exposure mode]:mode:(codemode deferred direct hidden)' \
            '--description=[what the server offers]:text:' \
            '(-l --local)'{-l,--local}'[use .pi/mcp.json in the current project]' ;;
        (remove|logout)
          _arguments -C \
            '1:server:_pi_mcp_servers' \
            '(-l --local)'{-l,--local}'[use .pi/mcp.json in the current project]' ;;
        (login)
          _arguments -C \
            '1:server:_pi_mcp_servers' \
            '--timeout=[seconds to wait for sign-in]:seconds:' \
            '(-l --local)'{-l,--local}'[use .pi/mcp.json in the current project]' ;;
        (list)
          _arguments -C '--json[output JSON]' ;;
      esac ;;
  esac
}

compdef _pi pi

# fzf-tab preview, subcommand position only: that subcommand's own --help, else the top-level
# help. The word is matched against a fixed list first, so a model or package name is never passed
# to pi. Read-only; text only.
zstyle ':fzf-tab:complete:pi:argument-1' fzf-preview \
  'case "$word" in install|remove|uninstall|update|list|config|auth|mcp) pi "$word" --help ;; *) pi --help ;; esac 2>/dev/null'
