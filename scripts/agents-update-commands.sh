#!/usr/bin/env bash
# Usage: bash scripts/agents-update-commands.sh
# Prints the per-OS update commands for rtk, caveman, and Matt Pocock skills.
# Does not run them. All commands are MANUAL USE ONLY.

set -euo pipefail

detect_os() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "macos"
  elif [[ -f /etc/arch-release ]]; then
    echo "arch"
  elif [[ -f /etc/debian_version ]]; then
    echo "debian"
  else
    echo "unsupported"
  fi
}

os=$(detect_os)

echo ""
echo "Agent tooling update commands"
echo "============================="
echo "Detected OS: $os"
echo ""
echo "These commands are shown for review. They modify tools outside this"
echo "repository and may write to \$HOME. Run them manually, one at a time."
echo ""

# --- rtk --------------------------------------------------------------

echo "1. Update rtk"
echo "-------------"
case "$os" in
  macos)
    echo "  ⚠️  MANUAL STEP — review before running"
    echo "  brew upgrade rtk"
    ;;
  arch)
    echo "  ⚠️  MANUAL STEP — review before running"
    echo "  yay -Syu rtk-bin"
    echo ""
    echo "  Or build from source:"
    echo "  ⚠️  MANUAL STEP — review before running"
    echo "  yay -Syu rtk"
    ;;
  debian)
    echo "  rtk is not in the Debian archive. Choose one:"
    echo ""
    echo "  ⚠️  MANUAL STEP — review before running"
    echo "  brew upgrade rtk                              # if using Homebrew on Linux"
    echo ""
    echo "  ⚠️  MANUAL STEP — review before running"
    echo "  cargo install --git https://github.com/rtk-ai/rtk   # if a Rust toolchain is present"
    ;;
  *)
    echo "  Unsupported OS — install manually from https://github.com/rtk-ai/rtk"
    ;;
esac
echo ""
echo "  Verify after updating:"
echo "    rtk --version"
echo "    rtk gain"
echo ""

# --- caveman ----------------------------------------------------------

echo "2. Update caveman"
echo "-----------------"
echo "  Claude Code plugin:"
echo "  ⚠️  MANUAL STEP — review before running"
echo "  claude plugin update caveman@caveman"
echo ""
echo "  opencode and Codex CLI (run from a scratch directory):"
echo "  ⚠️  MANUAL STEP — review before running"
echo "  cd /tmp"
echo "  npx -y github:JuliusBrussee/caveman -- --only opencode --only codex --non-interactive"
echo ""
echo "  After any caveman install or update, confirm the Claude Code status line"
echo "  still points to the repo-owned script:"
echo ""
echo "    jq '.statusLine' ~/.claude/settings.json"
echo ""
echo "  Expected:"
echo '    { "type": "command", "command": "bash \"$HOME/.claude/statusline-command.sh\"" }'
echo ""
echo "  If it changed, restore it. Caveman's hooks are wanted; its status line is not."
echo ""

# --- Matt Pocock skills -----------------------------------------------

echo "3. Update Matt Pocock skills"
echo "----------------------------"
echo "  ⚠️  MANUAL STEP — review before running"
echo "  npx skills update"
echo ""
echo "  This re-pulls upstream skills without review. They run with full agent"
echo "  permissions — the update is the same trust decision as the install."
echo ""
echo "  Verify after updating:"
echo "    npx skills@latest ls -g"
echo "    ls -1 ~/.agents/skills | wc -l"
echo ""
