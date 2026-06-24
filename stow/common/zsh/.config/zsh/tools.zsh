# tools.zsh — optional tool integrations (guarded; no-op when tool is missing)
# fzf lives in fzf.zsh (must init before completions). zoxide stays here because
# it must init LAST, after Oh My Posh rewrites the hook array (see index.zsh).

# --- zoxide ---
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init --cmd cd zsh)"
