# tools.zsh — optional tool integrations (guarded; no-op when tool is missing)

# --- fzf ---
command -v fzf    >/dev/null 2>&1 && eval "$(fzf --zsh)"

# --- zoxide ---
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init --cmd cd zsh)"
