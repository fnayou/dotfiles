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

# --- Edit command line in $EDITOR ---
# Press Ctrl-x Ctrl-e to open the current command in $EDITOR (nvim), edit it,
# then save+quit to return it to the prompt. Builtin widget; degrades to
# whatever $EDITOR/$VISUAL resolves to if nvim is not installed.
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^x^e' edit-command-line
