# path.zsh — portable PATH helpers and common PATH entries
# Add machine-specific paths in ~/.config/zsh/local.zsh (git-ignored).

# --- PATH helpers ---
path_prepend() {
  [[ -d "$1" ]] || return 0

  case ":$PATH:" in
    *":$1:"*) ;;
    *) export PATH="$1:$PATH" ;;
  esac
}

path_append() {
  [[ -d "$1" ]] || return 0

  case ":$PATH:" in
    *":$1:"*) ;;
    *) export PATH="$PATH:$1" ;;
  esac
}

# --- Default PATH entries ---
path_prepend "$HOME/.local/bin"
path_prepend "$HOME/bin"
