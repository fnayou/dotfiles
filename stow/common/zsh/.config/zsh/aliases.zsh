# aliases.zsh — portable aliases
alias grep='grep --color=auto'

if command -v eza >/dev/null 2>&1; then
  alias ls='eza --long --icons'
  alias ll='eza --long --all --icons'
  alias tree='eza --tree --icons'
else
  alias ll='ls -ahl'
fi

alias cp='cp -iv'
alias rm='rm -i'
alias mv='mv -iv'

alias meteo='curl -4 http://wttr.in/Plaisir'

sizeof(){ du -sh ./*; }
