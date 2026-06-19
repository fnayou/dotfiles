# macos.zsh — macOS-specific shell configuration
# Safe, guarded, and portable across Intel/Apple Silicon Homebrew installs.

if command -v brew >/dev/null 2>&1; then
  eval "$(brew shellenv)"
fi

alias o='open'
