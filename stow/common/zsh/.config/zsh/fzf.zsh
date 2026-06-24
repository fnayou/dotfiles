# fzf.zsh — fzf shell integration (guarded; no-op when fzf is missing)
#
# Sourced AFTER compinit (plugins.zsh) but BEFORE completion styles
# (completions.zsh): `fzf --zsh` registers completions via `compdef`, which
# needs compinit already run, and the completion layer must see fzf's widgets.
command -v fzf >/dev/null 2>&1 && eval "$(fzf --zsh)"
