# prompt.zsh — shell prompt (Oh My Posh)
# No-op if oh-my-posh is not installed or the theme file is missing.
# Install: see docs/guides/zsh-setup.md
# Theme: managed by stow/common/omp/ package.

# --- Oh My Posh ---
if command -v oh-my-posh >/dev/null 2>&1 && [[ -r "$HOME/.config/omp/omp.toml" ]]; then
  eval "$(oh-my-posh init zsh --config "$HOME/.config/omp/omp.toml")"
fi
