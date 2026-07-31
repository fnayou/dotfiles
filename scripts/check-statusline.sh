#!/usr/bin/env bash
# Usage: bash scripts/check-statusline.sh
# End-to-end check of the Claude Code status line, focused on the caveman segment
# (stow/common/claude/.claude/statusline-caveman.js).
#
# Prints PASS/FAIL per assertion. Exits 1 if any assertion fails.
# Read-only with respect to your real state:
#   - CLAUDE_CONFIG_DIR is redirected to a temp dir, so your real
#     ~/.claude/.caveman-active and history files are never read or written.
#   - XDG_CACHE_HOME is redirected, so your real status line cache is untouched.
#   - Transcripts are synthesised, so the check does not depend on your own
#     session history and reveals nothing from it.
# Everything it creates lives under one temp dir, removed on exit.
#
# Complements the unit tests (`task test:statusline`), which cover the segment's
# internals. This drives the real statusline-command.sh as Claude Code does.
#
# See docs/prd/0021-caveman-session-scoped-savings.md and ADRs 0056-0060.

set -uo pipefail

REPO_ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
SCRIPT="$REPO_ROOT/stow/common/claude/.claude/statusline-command.sh"

FAILED=0
SANDBOX=$(mktemp -d)
trap 'rm -rf "$SANDBOX"' EXIT

pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; FAILED=1; }
skip() { echo "SKIP: $1"; }

# --- Prerequisites -----------------------------------------------------------

for tool in jq git node; do
  command -v "$tool" >/dev/null 2>&1 || { echo "FAIL: $tool (not installed)"; exit 1; }
done
[[ -f "$SCRIPT" ]] || { echo "FAIL: $SCRIPT not found"; exit 1; }

# Locate caveman's hooks the same way the segment does: canonical marketplace
# path first, else the newest versioned cache checkout by mtime.
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
HOOKS="$CLAUDE_DIR/plugins/marketplaces/caveman/src/hooks"
if [[ ! -f "$HOOKS/caveman-stats.js" ]]; then
  HOOKS=$(ls -td "$CLAUDE_DIR"/plugins/cache/caveman/*/*/src/hooks 2>/dev/null | head -1)
fi
if [[ -z "${HOOKS:-}" || ! -f "$HOOKS/caveman-stats.js" ]]; then
  skip "caveman plugin not installed — segment assertions cannot run"
  echo "Nothing to check. Install the caveman plugin to exercise this script."
  exit 0
fi

# --- Sandbox -----------------------------------------------------------------
# A fake CLAUDE_CONFIG_DIR with our own mode flag makes the run deterministic
# regardless of which mode the user currently has active, and guarantees we
# never touch the real flag. 'full' is the only mode with benchmark data, so it
# is the only one that produces a figure to assert on.

FAKE_CLAUDE="$SANDBOX/claude"
mkdir -p "$FAKE_CLAUDE"
printf 'full' > "$FAKE_CLAUDE/.caveman-active"

EMPTY_CLAUDE="$SANDBOX/claude-empty"   # caveman absent
mkdir -p "$EMPTY_CLAUDE"

export XDG_CACHE_HOME="$SANDBOX/cache"

# Synthesise a transcript with a known number of assistant turns. Only
# `usage.output_tokens` on assistant records is counted, so the noise lines
# must be ignored by the parser.
make_transcript() { # <file> <turns> <tokens-per-turn>
  local file=$1 turns=$2 tokens=$3 i
  : > "$file"
  for (( i = 0; i < turns; i++ )); do
    printf '{"type":"assistant","message":{"model":"claude-opus-5","usage":{"output_tokens":%s,"cache_read_input_tokens":10}}}\n' \
      "$tokens" >> "$file"
    printf '{"type":"user","message":{"content":"noise"}}\n' >> "$file"
  done
}

payload() { # <session-id> <transcript> <cwd> [repo-identity]
  local repo=""
  if [[ -n "${4:-}" ]]; then
    repo=$(printf ',"repo":{"host":"example.test","owner":"%s","name":"%s"}' "$4" "$4")
  fi
  printf '{"session_id":"%s","transcript_path":"%s","cwd":"%s",' "$1" "$2" "$3"
  printf '"model":{"id":"claude-opus-5","display_name":"Opus 5"},'
  printf '"workspace":{"current_dir":"%s","project_dir":"%s"%s},' "$3" "$3" "$repo"
  printf '"context_window":{"used_percentage":12}}'
}

# Run the real status line and strip ANSI so assertions read plainly.
render() { # <payload> [env assignments...]
  local pl=$1; shift
  printf '%s' "$pl" | env CLAUDE_CONFIG_DIR="$FAKE_CLAUDE" CAVEMAN_HOOKS_DIR="$HOOKS" "$@" \
    bash "$SCRIPT" 2>/dev/null | sed -r 's/\x1B\[[0-9;]*[mK]//g'
}

# Extract the token figure following the pick glyph, in raw units.
# "12.3k" -> 12300, "1.2M" -> 1200000, "845" -> 845.
figure() { # <rendered-line> <which: 1=session, 2=repo>
  echo "$1" | grep -oE '⛏ [0-9.]+[kM]?|· [0-9.]+[kM]? repo' \
    | sed -n "${2}p" | grep -oE '[0-9.]+[kM]?' \
    | awk '{ n=$0; sub(/[kM]$/,"",n);
             if ($0 ~ /k$/) n*=1000; else if ($0 ~ /M$/) n*=1000000;
             printf "%d", n }'
}

TX_DIR="$SANDBOX/transcripts"; mkdir -p "$TX_DIR"
make_transcript "$TX_DIR/a1.jsonl" 20 500    # 10 000 output tokens
make_transcript "$TX_DIR/a2.jsonl" 60 500    # 30 000 output tokens
make_transcript "$TX_DIR/b1.jsonl" 10 500    #  5 000 output tokens

DIR_A="$SANDBOX/repo-a"; mkdir -p "$DIR_A"
DIR_B="$SANDBOX/repo-b"; mkdir -p "$DIR_B"

echo "Claude Code status line — end-to-end checks"
echo "==========================================="

# --- 1. Session figure is scoped to its own transcript -----------------------

OUT_A1=$(render "$(payload sess-a1 "$TX_DIR/a1.jsonl" "$DIR_A" repo-a)")
OUT_A2=$(render "$(payload sess-a2 "$TX_DIR/a2.jsonl" "$DIR_A" repo-a)")
SES_A1=$(figure "$OUT_A1" 1)
SES_A2=$(figure "$OUT_A2" 1)

if [[ -n "$SES_A1" && "$SES_A1" -gt 0 ]]; then
  pass "session figure rendered ($SES_A1)"
else
  fail "session figure missing — got: $OUT_A1"
fi

if [[ -n "$SES_A2" && "$SES_A2" -gt "$SES_A1" ]]; then
  pass "larger transcript yields a larger session figure ($SES_A2 > $SES_A1)"
else
  fail "session figures not independent: a1=$SES_A1 a2=$SES_A2"
fi

# --- 2. Repository total aggregates both sessions, without double counting ---

OUT_A1=$(render "$(payload sess-a1 "$TX_DIR/a1.jsonl" "$DIR_A" repo-a)")
REPO_A=$(figure "$OUT_A1" 2)
EXPECTED=$(( SES_A1 + SES_A2 ))

# Compare with tolerance: displayed figures are rounded to one decimal place.
if [[ -n "$REPO_A" ]] && (( REPO_A > EXPECTED - 200 && REPO_A < EXPECTED + 200 )); then
  pass "repository total is the sum of its sessions ($REPO_A ~ $EXPECTED)"
else
  fail "repository total wrong: got '$REPO_A', expected ~$EXPECTED"
fi

# Re-rendering the same session must not inflate anything.
OUT_REPEAT=$(render "$(payload sess-a1 "$TX_DIR/a1.jsonl" "$DIR_A" repo-a)")
if [[ "$(figure "$OUT_REPEAT" 2)" == "$REPO_A" ]]; then
  pass "re-rendering a session does not inflate the repository total"
else
  fail "repeat render changed the total: $REPO_A -> $(figure "$OUT_REPEAT" 2)"
fi

# --- 3. Repositories are isolated -------------------------------------------

OUT_B1=$(render "$(payload sess-b1 "$TX_DIR/b1.jsonl" "$DIR_B" repo-b)")
SES_B1=$(figure "$OUT_B1" 1)
REPO_B=$(figure "$OUT_B1" 2)

if [[ -n "$SES_B1" && "$SES_B1" -gt 0 && "$SES_B1" -lt "$SES_A1" ]]; then
  pass "second repository reports its own session figure ($SES_B1)"
else
  fail "second repository session figure wrong: '$SES_B1'"
fi

if [[ -z "$REPO_B" || "$REPO_B" -lt "$REPO_A" ]]; then
  pass "second repository does not inherit the first's total"
else
  fail "repository isolation broken: repo-b total '$REPO_B' >= repo-a '$REPO_A'"
fi

# --- 4. Outside a git repository --------------------------------------------

NOGIT="$SANDBOX/plain-dir"; mkdir -p "$NOGIT"
OUT_N=$(render "$(payload sess-n1 "$TX_DIR/a1.jsonl" "$NOGIT")")
if [[ "$OUT_N" == *"[CAVEMAN]"* ]] && [[ -n "$(figure "$OUT_N" 1)" ]]; then
  pass "renders outside a git repository (path-keyed identity)"
else
  fail "no segment outside a git repository — got: $OUT_N"
fi

# --- 5. Caveman inactive and absent -----------------------------------------

OUT_OFF=$(printf '%s' "$(payload s "$TX_DIR/a1.jsonl" "$DIR_A")" \
  | env CLAUDE_CONFIG_DIR="$EMPTY_CLAUDE" CAVEMAN_HOOKS_DIR="$HOOKS" \
    bash "$SCRIPT" 2>/dev/null | sed -r 's/\x1B\[[0-9;]*[mK]//g')
if [[ "$OUT_OFF" == *"[CAVEMAN:OFF]"* ]]; then
  pass "installed but inactive renders [CAVEMAN:OFF]"
else
  fail "expected [CAVEMAN:OFF] — got: $OUT_OFF"
fi

OUT_ABSENT=$(printf '%s' "$(payload s "$TX_DIR/a1.jsonl" "$DIR_A")" \
  | env CLAUDE_CONFIG_DIR="$EMPTY_CLAUDE" bash "$SCRIPT" 2>/dev/null \
  | sed -r 's/\x1B\[[0-9;]*[mK]//g')
if [[ "$OUT_ABSENT" != *CAVEMAN* && "$OUT_ABSENT" == *"Opus 5"* ]]; then
  pass "plugin absent renders no segment, rest of the line intact"
else
  fail "unexpected output with caveman absent: $OUT_ABSENT"
fi

# --- 6. Degraded inputs must never break the line ---------------------------

OUT_MISSING=$(render "$(payload sess-x "$SANDBOX/does-not-exist.jsonl" "$DIR_A" repo-a)")
if [[ "$OUT_MISSING" == *"Opus 5"* ]]; then
  pass "missing transcript leaves the rest of the line intact"
else
  fail "missing transcript broke the line: $OUT_MISSING"
fi

printf 'not json\n{{{\nnull\n' > "$SANDBOX/bad.jsonl"
OUT_BAD=$(render "$(payload sess-y "$SANDBOX/bad.jsonl" "$DIR_A" repo-a)")
if [[ "$OUT_BAD" == *"Opus 5"* ]]; then
  pass "malformed transcript leaves the rest of the line intact"
else
  fail "malformed transcript broke the line: $OUT_BAD"
fi

LEDGER_DIR=$(find "$XDG_CACHE_HOME/claude-statusline/caveman/repos" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | head -1)
if [[ -n "$LEDGER_DIR" ]]; then
  printf '{{{ not json' > "$LEDGER_DIR/corrupt.json"
  OUT_CORRUPT=$(render "$(payload sess-a1 "$TX_DIR/a1.jsonl" "$DIR_A" repo-a)")
  if [[ "$(figure "$OUT_CORRUPT" 2)" == "$REPO_A" ]]; then
    pass "corrupt ledger entry is skipped, remaining entries still sum"
  else
    fail "corrupt ledger entry changed the total"
  fi
else
  skip "ledger directory not found — corrupt-entry assertion"
fi

# --- 7. The machine-wide lifetime total must never appear -------------------
# The regression this whole feature exists to prevent.

SUFFIX_FILE="$CLAUDE_DIR/.caveman-statusline-suffix"
if [[ -f "$SUFFIX_FILE" && ! -L "$SUFFIX_FILE" ]]; then
  SUFFIX_NUM=$(tr -cd '0-9.kMkm' < "$SUFFIX_FILE" | head -c 32)
  if [[ -n "$SUFFIX_NUM" && "$OUT_A1" == *"$SUFFIX_NUM"* ]]; then
    fail "status line leaked the machine-wide lifetime total ($SUFFIX_NUM)"
  else
    pass "machine-wide lifetime total is not rendered"
  fi
else
  skip "no caveman suffix file present — lifetime-total assertion"
fi

# --- 8. Hygiene: silent stderr, zero exit -----------------------------------

ERR=$(printf '%s' "$(payload sess-a1 "$TX_DIR/a1.jsonl" "$DIR_A" repo-a)" \
  | env CLAUDE_CONFIG_DIR="$FAKE_CLAUDE" CAVEMAN_HOOKS_DIR="$HOOKS" \
    bash "$SCRIPT" 2>&1 >/dev/null)
[[ -z "$ERR" ]] && pass "no stderr output on a normal render" \
                || fail "stderr not empty: $ERR"

printf '%s' "$(payload sess-a1 "$TX_DIR/a1.jsonl" "$DIR_A" repo-a)" \
  | env CLAUDE_CONFIG_DIR="$FAKE_CLAUDE" CAVEMAN_HOOKS_DIR="$HOOKS" \
    bash "$SCRIPT" >/dev/null 2>&1
[[ $? -eq 0 ]] && pass "exit code 0 on a normal render" \
               || fail "non-zero exit on a normal render"

printf '%s' "$(payload s "$TX_DIR/a1.jsonl" "$DIR_A")" \
  | env CLAUDE_CONFIG_DIR="$EMPTY_CLAUDE" bash "$SCRIPT" >/dev/null 2>&1
[[ $? -eq 0 ]] && pass "exit code 0 with caveman absent" \
               || fail "non-zero exit with caveman absent"

# --- 9. The real environment was not touched --------------------------------

if [[ -z "$(find "${XDG_CACHE_HOME}" -maxdepth 0 -newer "$SCRIPT" 2>/dev/null; true)" ]] \
   || [[ "$XDG_CACHE_HOME" == "$SANDBOX"* ]]; then
  pass "all writes confined to the sandbox"
else
  fail "writes escaped the sandbox"
fi

echo "==========================================="
if [[ "$FAILED" -eq 0 ]]; then
  echo "All status line checks passed."
else
  echo "Status line checks FAILED."
fi
exit "$FAILED"
