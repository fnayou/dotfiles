# history.zsh — zsh history configuration

# --- History file ---
HISTSIZE=5000
HISTFILE="${HISTFILE:-$HOME/.zsh_history}"
SAVEHIST="$HISTSIZE"

# --- History options ---
setopt APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_SPACE
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_SAVE_NO_DUPS
setopt HIST_IGNORE_DUPS
setopt HIST_FIND_NO_DUPS
setopt EXTENDED_HISTORY
