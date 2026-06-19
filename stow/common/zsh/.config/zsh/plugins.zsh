# plugins.zsh — plugin manager (Zinit)
# Zinit must be installed manually before this file activates (ADR-0020).
# Install: git clone https://github.com/zdharma-continuum/zinit.git \
#   "${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
# This file must not install or clone anything during shell startup.

ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"

if [[ -r "$ZINIT_HOME/zinit.zsh" ]]; then
  source "$ZINIT_HOME/zinit.zsh"

  zinit light zsh-users/zsh-syntax-highlighting
  zinit light zsh-users/zsh-completions
  zinit light zsh-users/zsh-autosuggestions
  zinit light Aloxaf/fzf-tab
fi

unset ZINIT_HOME
