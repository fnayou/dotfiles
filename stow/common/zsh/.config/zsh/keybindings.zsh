# keybindings.zsh — key bindings
bindkey -e  # emacs key map

# Autosuggest accept — guard: only bind if the widget is loaded (requires zsh-autosuggestions).
if typeset -f _zsh_autosuggest_accept >/dev/null 2>&1 || zle -l autosuggest-accept >/dev/null 2>&1; then
  bindkey '^L' autosuggest-accept
fi
