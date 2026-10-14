#!/usr/bin/env bash
# Usage: bash scripts/agents-status.sh
# Read-only summary of rtk, caveman, and Matt Pocock skills across agents.

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

CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
OPENCODE_DIR="${OPENCODE_CONFIG_DIR:-$HOME/.config/opencode}"
CODEX_DIR="${CODEX_CONFIG_DIR:-$HOME/.codex}"
AGENTS_SKILLS_DIR="${AGENTS_SKILLS:-$HOME/.agents/skills}"

os=$(detect_os)

echo ""
echo "AI agent tooling status"
echo "======================="
echo "Detected OS: $os"
echo ""

# --- rtk --------------------------------------------------------------

echo "rtk"
echo "---"
if ! command -v rtk >/dev/null 2>&1; then
  echo "  binary: not found in PATH"
else
  echo "  binary: $(command -v rtk)"
  echo "  version: $(rtk --version 2>/dev/null || echo "unknown")"
  if rtk gain >/dev/null 2>&1; then
    echo "  gain check: OK (rtk-ai/rtk)"
  else
    echo "  gain check: FAIL — wrong rtk or not initialized"
  fi
  if rtk init --show >/dev/null 2>&1; then
    echo "  registered hooks:"
    rtk init --show 2>/dev/null | sed 's/^/    /' || true
  else
    echo "  registered hooks: (none or not initialized)"
  fi
fi
echo ""

# --- caveman ----------------------------------------------------------

echo "caveman"
echo "-------"

claude_caveman_dir="$CLAUDE_DIR/plugins/marketplaces/caveman"
if [[ -d "$claude_caveman_dir" ]]; then
  echo "  Claude plugin: installed"
  if [[ -f "$claude_caveman_dir/package.json" ]] && command -v jq >/dev/null 2>&1; then
    echo "  Claude version: $(jq -r '.version // "unknown"' "$claude_caveman_dir/package.json" 2>/dev/null || echo "unknown")"
  fi
else
  echo "  Claude plugin: not installed"
fi

if [[ -d "$OPENCODE_DIR/plugins/caveman" ]]; then
  echo "  opencode plugin: installed"
else
  echo "  opencode plugin: not installed"
fi

if [[ -d "$CODEX_DIR/caveman" ]] || [[ -f "$CODEX_DIR/.caveman-active" ]]; then
  echo "  Codex integration: present"
else
  echo "  Codex integration: not detected"
fi

if [[ -f "$CLAUDE_DIR/.caveman-active" ]]; then
  echo "  active mode: $(cat "$CLAUDE_DIR/.caveman-active")"
else
  echo "  active mode: none"
fi

echo ""
echo "Claude status line"
echo "------------------"
settings_file="$CLAUDE_DIR/settings.json"
if [[ -f "$settings_file" ]] && command -v jq >/dev/null 2>&1; then
  current=$(jq -c '.statusLine // empty' "$settings_file" 2>/dev/null || true)
  if [[ -n "$current" ]]; then
    echo "  $current"
    expected='{"type":"command","command":"bash \"$HOME/.claude/statusline-command.sh\""}'
    if [[ "$current" == "$expected" ]]; then
      echo "  OK: repo-owned status line script"
    else
      echo "  WARN: status line does not point to the repo-owned script"
    fi
  else
    echo "  not configured"
  fi
else
  echo "  settings.json or jq not available"
fi

echo ""

# --- Matt Pocock skills -----------------------------------------------

echo "Matt Pocock skills"
echo "------------------"
if [[ -d "$AGENTS_SKILLS_DIR" ]]; then
  count=$(find "$AGENTS_SKILLS_DIR" -maxdepth 1 -mindepth 1 -type d | wc -l | tr -d ' ')
  echo "  shared skills installed: $count"
  if [[ "$count" -eq 58 ]]; then
    echo "  expected count: 58 (OK)"
  else
    echo "  expected count: 58 (run 'npx skills@latest ls -g' to inspect)"
  fi
else
  echo "  shared skills directory missing: $AGENTS_SKILLS_DIR"
fi
echo ""
