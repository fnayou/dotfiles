# shared.zsh — portable zsh environment (XDG vars + editor/pager + AUTO_CD)
# Sourced on every platform by index.zsh. Must remain portable: no brew, pacman,
# pbcopy, systemctl, or any platform-specific content belongs here.

# --- XDG base directories ---
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

# --- Portable environment ---
export EDITOR="${EDITOR:-nvim}"
export VISUAL="${VISUAL:-nvim}"
export PAGER="${PAGER:-less}"

# --- Shell options (portable) ---
setopt AUTO_CD
setopt INTERACTIVE_COMMENTS
setopt NO_BEEP
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_SILENT
setopt AUTO_PUSHD
