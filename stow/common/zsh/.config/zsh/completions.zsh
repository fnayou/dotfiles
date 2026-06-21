# completions.zsh — zsh completion initialization and styles

# --- Completion init ---
autoload -Uz compinit && compinit

# --- Completion styles ---
zstyle ':completion:*' menu select
zstyle ':completion:*' special-dirs true

# Force file/directory completions to take absolute precedence for listing commands
zstyle ':completion:*:*:(eza|ls|ll):*' tag-order 'files directories targets' '*'
zstyle ':completion:*:*:(eza|ls|ll):*' group-order files directories targets options

# --- fzf-tab preview ---
if command -v eza >/dev/null 2>&1; then
  zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza --color=always --long --icons $realpath'
  zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'eza --color=always --long --icons $realpath'

  # Previews when completing arguments for ls, ll, and eza
  zstyle ':fzf-tab:complete:(eza|ls|ll):*' fzf-preview '
    if [[ -d $realpath ]]; then
      eza --color=always --long --icons $realpath
    else
      bat --color=always --style=numbers $realpath 2>/dev/null || cat $realpath
    fi
  '
else
  zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls -la $realpath'
  zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls -la $realpath'

  # Fallback: Standard ls preview if eza isn't present
  zstyle ':fzf-tab:complete:(ls|ll):*' fzf-preview 'ls -la $realpath'
fi

# Include hidden files (dotfiles) in completion menus automatically
_comp_options+=(globdots)
