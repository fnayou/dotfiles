# fzf.zsh — fzf shell integration (guarded; no-op when fzf is missing)
#
# Sourced AFTER compinit (plugins.zsh) but BEFORE completion styles
# (completions.zsh): `fzf --zsh` registers completions via `compdef`, which
# needs compinit already run, and the completion layer must see fzf's widgets.
command -v fzf >/dev/null 2>&1 && eval "$(fzf --zsh)"

# Ctrl+R picker: ctrl-x removes the highlighted entry from the history file (ADR-0087).
# Registered only when every part is present: fzf >= 0.60.0 (the `exclude` action), perl (the
# widget then lists numbered records), and the helper script. Otherwise there is no key.
# `exclude` hides the entry in this picker; the running shell keeps it in memory until it restarts.
# If local.zsh sets FZF_CTRL_R_OPTS, append to it (`FZF_CTRL_R_OPTS+=" ..."`); do not overwrite it.
if command -v fzf >/dev/null 2>&1 && command -v perl >/dev/null 2>&1; then
  _fzf_hist_helper="$HOME/.config/zsh/scripts/fzf-history-delete"
  _fzf_hist_file="${HISTFILE:-$HOME/.zsh_history}"
  autoload -Uz is-at-least
  if [[ -r $_fzf_hist_helper && $_fzf_hist_helper != *\'* && $_fzf_hist_file != *\'* ]] \
      && is-at-least 0.60.0 "${$(fzf --version)[(w)1]}"; then
    FZF_CTRL_R_OPTS="${FZF_CTRL_R_OPTS:+$FZF_CTRL_R_OPTS }--bind 'ctrl-x:execute-silent(HISTFILE=${(q)_fzf_hist_file} zsh ${(q)_fzf_hist_helper} {f})+exclude'"
  fi
  unset _fzf_hist_helper _fzf_hist_file
fi
