#!/usr/bin/env bash
# Usage: bash scripts/check-zsh-deps.sh
# Checks that zsh shell-tier dependencies are installed.
# Prints PASS/FAIL per tool. Exits 1 if any required tool is missing.
# Never installs anything. Read-only.
#
# For core repo tooling (git, stow, task), run: bash scripts/check.sh

set -uo pipefail

FAILED=0

# --- Detect OS for install hints ---
if [[ "$OSTYPE" == "darwin"* ]]; then
  OS="macos"
elif [[ -f /etc/arch-release ]]; then
  OS="arch"
else
  OS="unknown"
fi

hint_install() {
  if [[ "$OS" == "macos" ]]; then
    echo "  → Install hint (macOS): brew bundle --file=packages/macos/Brewfile.shell"
  elif [[ "$OS" == "arch" ]]; then
    echo "  → Install hint (Arch): install via pacman or AUR — see docs/shell-dependencies.md"
  else
    echo "  → Install hint: see docs/shell-dependencies.md"
  fi
}

hint_zinit() {
  echo "  → Install hint: one-time manual clone — see docs/shell-dependencies.md"
  echo "    git clone https://github.com/zdharma-continuum/zinit.git \\"
  echo "      \"\${XDG_DATA_HOME:-\$HOME/.local/share}/zinit/zinit.git\""
}

# --- Check shell-tier tools ---

for tool in fzf zoxide eza oh-my-posh; do
  if command -v "$tool" >/dev/null 2>&1; then
    echo "PASS: $tool"
  else
    echo "FAIL: $tool (not installed)"
    hint_install
    FAILED=1
  fi
done

# --- Check zinit (not a $PATH binary — check install directory) ---
ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
if [[ -f "${ZINIT_HOME}/zinit.zsh" ]]; then
  echo "PASS: zinit"
else
  echo "FAIL: zinit (not found at ${ZINIT_HOME})"
  hint_zinit
  FAILED=1
fi

exit "${FAILED}"
