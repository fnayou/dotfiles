# arch.zsh — Arch / EndeavourOS-specific zsh config (sourced only on Arch via index.zsh)

# AUR helper alias (guarded — no-op when neither is installed).
command -v yay  >/dev/null 2>&1 && alias aur='yay'
command -v paru >/dev/null 2>&1 && alias aur='paru'

# systemd aliases.
alias sc='systemctl'
alias scu='systemctl --user'
if command -v pacman >/dev/null 2>&1; then
  alias pacs='pacman -Ss'
  alias paci='sudo pacman -S'
  alias pacu='sudo pacman -Syu'
fi
