# keybindings.zsh — key bindings

# --- Key map ---
bindkey -e  # emacs key map

# --- zsh-autosuggestions ---
# Only bind if the widget is loaded (requires zsh-autosuggestions).
if typeset -f _zsh_autosuggest_accept >/dev/null 2>&1 || zle -l autosuggest-accept >/dev/null 2>&1; then
  bindkey '^K' autosuggest-accept
fi

# --- Built-in enhancements ---
bindkey ' ' magic-space
