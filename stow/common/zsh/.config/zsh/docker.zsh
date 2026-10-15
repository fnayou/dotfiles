# docker.zsh — docker completion shim adding `docker desktop`. Guarded; no-op
# without `docker`.
#
# Homebrew's _docker (~3100 lines, `#compdef docker dockerd`) builds its
# first-level command list live from `docker --help`, so `desktop` appears at
# first level — but its nested dispatcher `__docker_subcommand` is a hardcoded
# `case $words[1]` with no `(desktop)` branch. Even Docker's own generated
# `docker completion zsh` has zero desktop coverage. Result, diagnosed 2026-10 on
# docker CLI 29.8.2: `docker desktop <Tab>` yields no candidates, so fzf-tab
# never opens.
#
# This file does NOT vendor or patch _docker. It re-registers `docker` to a shim
# that completes only the `desktop` branch (strictly static — zero subprocess
# calls in the completion path) and delegates everything else — including
# `dockerd` and `$service` subservice dispatch — to the package-shipped _docker
# unchanged. Homebrew stays authoritative; delete this shim once upstream _docker
# gains a `(desktop)` case.
#
# Sourced after compinit via index.zsh (slot 6g): the later compdef registration
# replaces compinit's earlier `#compdef docker dockerd` mapping for `docker`.

command -v docker >/dev/null 2>&1 || return

# Docker Desktop CLI subcommand tree, validated against `docker desktop --help`
# (docker CLI 29.8.2, 2026-10). Fully static.
_docker_desktop() {
  local -a dcommands
  dcommands=(
    'auth:authenticate to Docker Desktop'
    'kubernetes:manage the Kubernetes cluster'
    'disable:turn off Docker Desktop'
    'enable:turn on Docker Desktop'
    'diagnose:run diagnostics'
    'logs:show Docker Desktop logs'
    'restart:restart Docker Desktop'
    'start:start Docker Desktop'
    'status:show Docker Desktop status'
    'stop:stop Docker Desktop'
    'update:check for and apply updates'
    'version:show Docker Desktop version'
  )

  # Serve the subcommand list at both entry shapes: `docker <Tab>` (the
  # no-Homebrew degradation path, CURRENT=2) and `docker desktop <Tab>`
  # (CURRENT=3). Positional `_arguments` specs cannot serve the nested shape:
  # `desktop` already occupies relative argument 1 there, so the `*::arg:->args`
  # redirection fires instead and no case branch matches — zero candidates.
  # `_describe` plus explicit `CURRENT` checks avoids that entirely.
  if (( CURRENT == 2 )) || { (( CURRENT == 3 )) && [[ ${words[2]} == desktop ]] }; then
    _describe -t docker-desktop-command 'desktop command' dcommands
    return
  fi

  if (( CURRENT == 4 )); then
    local -a scommands
    case ${words[3]} in
      (auth)
        scommands=(status:show authentication status) ;;
      (kubernetes)
        scommands=(
          'images:list images available to the cluster'
          'reset-cluster:reset the Kubernetes cluster'
          'status:show Kubernetes status'
        ) ;;
    esac
    if (( ${#scommands} )); then
      _describe -t docker-desktop-sub-command 'command' scommands
    fi
    return
  fi

  case ${words[3]} in
    (logs)
      _arguments \
        '(-b --boot)-b[boot number (0 = current)]:boot:' \
        '(-b --boot)--boot[boot number (0 = current)]:boot:' \
        '(-c --color)-c[always enable colored output]' \
        '(-m --color-mode)-m[color mode]:mode:(default priority)' \
        '(-m --color-mode)--color-mode[color mode]:mode:(default priority)' \
        '(-D --directory)-D[custom log directory]:directory:_directories' \
        '(-D --directory)--directory[custom log directory]:directory:_directories' ;;
    (update)
      _arguments \
        '(-k --check-only)-k[check for updates without applying]' \
        '(-k --check-only)--check-only[check for updates without applying]' \
        '(-q --quiet)-q[quietly check and apply]' \
        '(-q --quiet)--quiet[quietly check and apply]' ;;
  esac
}

_docker_shim() {
  # dockerd and subservice shells go straight to the original completion.
  if [[ $service != docker ]]; then
    _docker "$@"
    return
  fi
  if [[ ${words[1]} == docker && ${words[2]} == desktop ]]; then
    _docker_desktop "$@"
  elif (( $+functions[_docker] )); then
    # Delegate by calling the autoloaded _docker function DIRECTLY — never
    # through compdef/as a completer — so this shim cannot recurse. On first
    # call zsh reads the package file from fpath, which defines `_docker` and
    # self-invokes it with the current words; later calls run the loaded body.
    _docker "$@"
  else
    # No package-shipped _docker on fpath (non-Homebrew systems): degrade to
    # the desktop tree alone rather than completing nothing at all.
    _docker_desktop "$@"
  fi
}

compdef _docker_shim docker

# fzf-tab preview, read-only: `--help` output for Docker Desktop subcommands;
# nothing for other docker words (the shipped completion already describes them).
zstyle ':fzf-tab:complete:docker:desktop:*' fzf-preview \
  'case $word in
    (auth|kubernetes|diagnose|logs|restart|start|status|stop|update|version)
      docker desktop $word --help 2>/dev/null ;;
    (*) : ;;
  esac'
