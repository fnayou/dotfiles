# plugins.zsh — plugin manager (Zinit)
# Zinit must be installed manually before this file activates (ADR-0020).
# Install: git clone https://github.com/zdharma-continuum/zinit.git \
#   "${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
# This file must not install or clone anything during shell startup.

# --- Zinit bootstrap ---
ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"

if [[ -r "$ZINIT_HOME/zinit.zsh" ]]; then
  source "$ZINIT_HOME/zinit.zsh"

  # --- Plugins ---
  zinit blockf for zsh-users/zsh-completions
  zinit light zsh-users/zsh-syntax-highlighting
  zinit light zsh-users/zsh-autosuggestions
  zinit light Aloxaf/fzf-tab
else
    print -P "%F{red}%B[ERROR]: Zinit is not installed!%b%f"
    print -P "Please install it to load your configuration properly."
    return 1
fi

unset ZINIT_HOME
