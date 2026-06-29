#!/usr/bin/env bash
# Usage: bash scripts/check-nvim-deps.sh
# Checks that the Neovim-tier system dependencies are installed.
# Prints PASS/FAIL per tool. Exits 1 if any required tool is missing.
# Never installs anything. Read-only.
#
# For zsh shell-tier tools, run: bash scripts/check-zsh-deps.sh
# For core repo tooling (git, stow, task), run: bash scripts/check.sh

set -uo pipefail

FAILED=0

# --- Detect OS for install hints ---
if [[ "$OSTYPE" == "darwin"* ]]; then
  OS="macos"
elif [[ -f /etc/arch-release ]]; then
  OS="arch"
elif [[ -f /etc/debian_version ]]; then
  OS="debian"
else
  OS="unknown"
fi

hint_install() {
  if [[ "$OS" == "macos" ]]; then
    echo "  → Install hint (macOS): brew bundle --file=packages/Brewfile"
    echo "    tree-sitter CLI is not in the Brewfile: npm install -g tree-sitter-cli"
  elif [[ "$OS" == "arch" ]]; then
    echo "  → Install hint (Arch): sudo pacman -S neovim ripgrep fd nodejs npm python python-pipx base-devel tree-sitter-cli"
    echo "  → Full list: packages/arch/packages.txt"
  elif [[ "$OS" == "debian" ]]; then
    echo "  → Install hint (Debian): sudo apt install neovim ripgrep fd-find nodejs npm python3 python3-pip pipx build-essential"
    echo "    tree-sitter CLI (node-free prebuilt binary):"
    echo "    curl -fsSL https://github.com/tree-sitter/tree-sitter/releases/latest/download/tree-sitter-linux-x64.gz | gunzip > ~/.local/bin/tree-sitter && chmod +x ~/.local/bin/tree-sitter"
    echo "    (Debian binaries: bat->batcat, fd->fdfind)"
    echo "  → Full list: packages/debian/packages.txt"
  else
    echo "  → Install hint: see stow/common/nvim/README.md"
  fi
}

# --- Check Neovim-tier tools ---
# nvim       — the editor itself
# tree-sitter — parser builder; missing → nvim-treesitter ENOENT on parser build
# rg / fd    — snacks picker live-grep and file finding
# node       — powers most Mason-installed LSP servers
for tool in nvim tree-sitter rg fd node; do
  if command -v "$tool" >/dev/null 2>&1; then
    echo "PASS: $tool"
  else
    echo "FAIL: $tool (not installed)"
    hint_install
    FAILED=1
  fi
done

exit "${FAILED}"
