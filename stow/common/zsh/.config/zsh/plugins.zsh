# plugins.zsh — plugin manager (Zinit)
# Zinit must be installed manually before this file activates (ADR-0020).
# Install: git clone https://github.com/zdharma-continuum/zinit.git \
#   "${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
# This file must not install or clone anything during shell startup.
#
# Plugin load order satisfies the fzf-tab upstream contract (ADR-0049):
#   1. zsh-completions  — populates fpath BEFORE compinit
#   2. compinit         — runs exactly once, after fpath is ready
#   3. fzf-tab          — after compinit, before widget-wrapping plugins
#   4. syntax-highlighting / autosuggestions — widget-wrap, after fzf-tab

# --- Zinit bootstrap ---
ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"

if [[ -r "$ZINIT_HOME/zinit.zsh" ]]; then
  source "$ZINIT_HOME/zinit.zsh"

  # 1) Completions onto fpath — BEFORE compinit.
  zinit blockf for zsh-users/zsh-completions

  # 2) Completion system — after fpath plugin, before fzf-tab.
  autoload -Uz compinit && compinit

  # 3) fzf-tab — after compinit, before widget-wrapping plugins.
  zinit light Aloxaf/fzf-tab

  # 4) Widget-wrapping plugins — after fzf-tab.
  zinit light zsh-users/zsh-syntax-highlighting
  zinit light zsh-users/zsh-autosuggestions
else
  print -P "%F{red}%B[ERROR]: Zinit is not installed!%b%f"
  print -P "Please install it to load your configuration properly."
  autoload -Uz compinit && compinit   # fallback: native completion without zinit
  return 1
fi

unset ZINIT_HOME
