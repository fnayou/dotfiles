# tools.zsh — optional tool integrations (guarded; no-op when tool is missing)
command -v fzf    >/dev/null 2>&1 && eval "$(fzf --zsh)"
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"
command -v eza    >/dev/null 2>&1 && alias ls='eza'
