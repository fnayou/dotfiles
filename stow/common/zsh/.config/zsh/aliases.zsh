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

# --- Functions ---
sizeof(){ du -sh ./*; }

# List the directory after every `cd`, but only at a real terminal. Coding
# agents inherit this hook and run `cd` with their output captured; there the
# eza listing has hung their shell for minutes, so skip it for them.
chpwd() {
  [[ -t 1 ]] && ll
}
