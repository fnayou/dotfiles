# index.zsh — managed zsh entry point
# Sourced by the single guarded include block in your real ~/.zshrc (see docs/guides/zsh-setup.md).
#
# This file owns SOURCE ORDER only. Each layer file owns its own guarded logic.
# It installs nothing, clones nothing, and activates nothing automatically — every
# source is guarded, so a partially-adopted machine still starts a clean shell.

# 1) PATH additions: prepend before shared so tools are findable.
[[ -r "$HOME/.config/zsh/path.zsh" ]] && source "$HOME/.config/zsh/path.zsh"

# 2) Portable layer: XDG, env, history, and shell options.
[[ -r "$HOME/.config/zsh/shared.zsh" ]] && source "$HOME/.config/zsh/shared.zsh"

# 3) History: HISTFILE, HISTSIZE, SAVEHIST, setopts.
[[ -r "$HOME/.config/zsh/history.zsh" ]] && source "$HOME/.config/zsh/history.zsh"

# 4) Platform layer: OS-detected, sourced only if present.
if [[ "$OSTYPE" == "darwin"* ]]; then
  [[ -r "$HOME/.config/zsh/macos.zsh" ]] && source "$HOME/.config/zsh/macos.zsh"
elif [[ -f /etc/arch-release ]]; then
  [[ -r "$HOME/.config/zsh/arch.zsh" ]] && source "$HOME/.config/zsh/arch.zsh"
fi

# 5) Plugin manager (Zinit) — guarded; no-op when not installed.
[[ -r "$HOME/.config/zsh/plugins.zsh" ]] && source "$HOME/.config/zsh/plugins.zsh"

# 6) Completion system.
[[ -r "$HOME/.config/zsh/completions.zsh" ]] && source "$HOME/.config/zsh/completions.zsh"

# 7) Key bindings.
[[ -r "$HOME/.config/zsh/keybindings.zsh" ]] && source "$HOME/.config/zsh/keybindings.zsh"

# 8) Optional tool integrations (fzf, zoxide) — all guarded.
[[ -r "$HOME/.config/zsh/tools.zsh" ]] && source "$HOME/.config/zsh/tools.zsh"

# 9) Portable aliases.
[[ -r "$HOME/.config/zsh/aliases.zsh" ]] && source "$HOME/.config/zsh/aliases.zsh"

# 10) Prompt: Oh My Posh — double-guarded inside prompt.zsh; no-op if missing.
[[ -r "$HOME/.config/zsh/prompt.zsh" ]] && source "$HOME/.config/zsh/prompt.zsh"

# 11) Local overrides — machine-specific/sensitive, git-ignored, sourced LAST so it wins.
[[ -r "$HOME/.config/zsh/local.zsh" ]] && source "$HOME/.config/zsh/local.zsh"
