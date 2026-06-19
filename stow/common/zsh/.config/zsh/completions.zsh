# completions.zsh — zsh completion initialization and styles

autoload -Uz compinit
compinit

zstyle ':completion:*' menu no

if command -v eza >/dev/null 2>&1; then
  zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza --color=always --long --icons $realpath'
  zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'eza --color=always --long --icons $realpath'
else
  zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls -la $realpath'
  zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls -la $realpath'
fi
