#!/usr/bin/env bash
# Usage: bash scripts/agents-verify.sh
# Read-only verification of rtk, caveman, and Matt Pocock skills.
# Prints PASS/FAIL per check and exits with the number of failures.

set -uo pipefail

failures=0

fail() {
  echo "  FAIL: $1"
  failures=$((failures + 1))
}

pass() {
  echo "  PASS: $1"
}

warn() {
  echo "  WARN: $1"
}

CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
OPENCODE_DIR="${OPENCODE_CONFIG_DIR:-$HOME/.config/opencode}"
CODEX_DIR="${CODEX_CONFIG_DIR:-$HOME/.codex}"
AGENTS_SKILLS_DIR="${AGENTS_SKILLS:-$HOME/.agents/skills}"

echo ""
echo "AI agent tooling verification"
echo "============================="
echo ""

# --- rtk --------------------------------------------------------------

echo "rtk"
echo "---"
if command -v rtk >/dev/null 2>&1; then
  pass "binary is in PATH"
  if rtk gain >/dev/null 2>&1; then
    pass "rtk gain works (correct rtk-ai/rtk)"
  else
    fail "rtk gain failed — wrong rtk or not initialized"
  fi
  rtk_show=$(rtk init --show 2>/dev/null || true)
  if printf '%s' "$rtk_show" | grep -q "Hook: rtk hook claude"; then
    pass "Claude Code hook registered"
  else
    warn "Claude Code hook not registered"
  fi
  if printf '%s' "$rtk_show" | grep -q "codex"; then
    pass "Codex hook registered"
  else
    warn "Codex hook not registered"
  fi
  if printf '%s' "$rtk_show" | grep -q "OpenCode: plugin installed"; then
    pass "opencode hook registered"
  else
    warn "opencode hook not registered"
  fi
else
  fail "binary not found in PATH"
fi
echo ""

# --- caveman ----------------------------------------------------------

echo "caveman"
echo "-------"
if [[ -d "$CLAUDE_DIR/plugins/marketplaces/caveman" ]]; then
  pass "Claude plugin installed"
else
  warn "Claude plugin not installed"
fi

if [[ -d "$OPENCODE_DIR/plugins/caveman" ]]; then
  pass "opencode plugin installed"
else
  warn "opencode plugin not installed"
fi

if [[ -d "$CODEX_DIR/caveman" ]] || [[ -f "$CODEX_DIR/.caveman-active" ]]; then
  pass "Codex integration present"
else
  warn "Codex integration not detected"
fi

if [[ -f "$CLAUDE_DIR/.caveman-active" ]]; then
  pass "caveman mode is set: $(cat "$CLAUDE_DIR/.caveman-active")"
else
  warn "no caveman mode set"
fi

settings_file="$CLAUDE_DIR/settings.json"
if [[ -f "$settings_file" ]] && command -v jq >/dev/null 2>&1; then
  current=$(jq -c '.statusLine // empty' "$settings_file" 2>/dev/null || true)
  expected='{"type":"command","command":"bash \"$HOME/.claude/statusline-command.sh\""}'
  if [[ "$current" == "$expected" ]]; then
    pass "Claude status line points to repo-owned script"
  else
    fail "Claude status line is not the repo-owned script"
  fi
else
  warn "cannot verify status line (settings.json or jq missing)"
fi
echo ""

# --- Matt Pocock skills -----------------------------------------------

echo "Matt Pocock skills"
echo "------------------"
if [[ -d "$AGENTS_SKILLS_DIR" ]]; then
  count=$(find "$AGENTS_SKILLS_DIR" -maxdepth 1 -mindepth 1 -type d | wc -l | tr -d ' ')
  if [[ "$count" -eq 58 ]]; then
    pass "shared skills count is 58"
  else
    warn "shared skills count is $count (expected 58)"
  fi
else
  fail "shared skills directory missing"
fi
echo ""

# --- summary ----------------------------------------------------------

echo "Summary"
echo "-------"
if [[ "$failures" -eq 0 ]]; then
  echo "No failures. Warnings above may be expected if a tool is intentionally absent."
else
  echo "$failures check(s) failed."
fi
exit "$failures"
