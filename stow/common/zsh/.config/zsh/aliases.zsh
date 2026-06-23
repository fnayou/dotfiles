# aliases.zsh — portable aliases

# --- File listing (eza / ls fallback) ---
if command -v eza >/dev/null 2>&1; then
  alias ls='eza --icons --long'
  alias ll='eza --icons --all --long'
  alias tree='eza --icons --tree'
else
  alias ll='ls -ahl'
fi

# --- Safety overrides ---
alias grep='grep --color=auto'
alias cp='cp -iv'
alias rm='rm -i'
alias mv='mv -iv'
# --- Suffix aliases (bat) ---
if command -v bat >/dev/null 2>&1; then
  alias cat='bat'
  alias -s md=bat
  alias -s txt=bat
  alias -s log=bat
fi

# --- Editor ---
alias vi='vim'

# --- Navigation ---
alias ..='cd ..'

# --- Docker / Compose ---
if command -v docker >/dev/null 2>&1; then
  alias dc='docker compose'
  alias dcup='docker compose up -d'
  alias dcps='docker compose ps'
  alias dcb='docker compose build'
  alias dcd='docker compose down'
  # Stop and remove every container (destructive — wipes all containers).
  alias dcs='docker stop $(docker ps -a -q) && docker rm $(docker ps -a -q)'

  dci()  { docker inspect "$@"; }
  dcip() { docker inspect "$(docker ps -f name="$1" -q)" | grep IPAddress; }
  dcbash() { docker compose run "$@" bash; }
fi

# --- Functions ---
sizeof(){ du -sh ./*; }

# Make a directory (and parents) then cd into it.
mkcd() { mkdir -p "$@" && cd "$_" || return; }

# Truncate the zsh history file (HISTFILE set in history.zsh).
cleanup() { : > "${HISTFILE:-$HOME/.zsh_history}"; }

chpwd() {
  ll
}
