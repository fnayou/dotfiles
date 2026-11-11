#!/usr/bin/env bash
# Usage: bash scripts/test-pi-completion.sh
# Tests stow/common/zsh/.config/zsh/pi.zsh (pi CLI completion) with a stub `pi` and a made-up
# mcp.json in a temporary directory. Needs zsh. Exits 1 if any check fails.
#
# NEVER runs the real pi and NEVER reads the real ~/.pi: every run sets HOME and PATH to a temporary
# directory. The values in the made-up mcp.json are fake.

set -uo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
FILE="$ROOT/stow/common/zsh/.config/zsh/pi.zsh"
INDEX="$ROOT/stow/common/zsh/.config/zsh/index.zsh"
TMP=$(mktemp -d)
FAILED=0

trap 'rm -rf "$TMP"' EXIT

pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; FAILED=$((FAILED + 1)); }

ZSH=$(command -v zsh) || { echo "FAIL: zsh not installed"; exit 1; }
[[ -r "$FILE" ]] || { echo "FAIL: not found: $FILE"; exit 1; }

# --- Stub pi and a fake home ---
BIN="$TMP/bin"; FHOME="$TMP/home"
mkdir -p "$BIN" "$FHOME/.pi/agent" "$TMP/empty"
cat >"$BIN/pi" <<'STUB'
#!/bin/sh
case "$1" in
  --list-models)
    printf 'provider     model                 context  max-out  thinking  images\n'
    printf 'lmstudio     model-one@q4          262.1K   8.2K     yes       no\n'
    printf 'opencode-go  vendor/model-two      1.0M     8.2K     yes       yes\n'
    printf 'opencode-go  vendor/model-three    1.0M     8.2K     yes       yes\n' ;;
  list)
    printf 'User packages:\n  npm:fake-package\n    /fake/path/fake-package\n  git:github.com/example/repo\n    /fake/path/repo\n' ;;
  *) exit 0 ;;
esac
STUB
chmod +x "$BIN/pi"
cat >"$FHOME/.pi/agent/mcp.json" <<'JSON'
{"mcpServers":{"alpha":{"command":"run-alpha","env":{"TOKEN":"fake-secret-value"}},"beta":{"url":"https://example.invalid/mcp"}}}
JSON

# Run a zsh snippet with the stub on PATH. compadd is replaced by a function that prints its arguments.
zrun() { HOME="$FHOME" PATH="$BIN:/usr/bin:/bin" "$ZSH" -f -c "
autoload -Uz compinit; compinit -u -D 2>/dev/null
compadd() { print -r -- \"\$@\"; }
source '$FILE'
$1" 2>&1; }

# --- Syntax ---
"$ZSH" -n "$FILE" && pass "zsh -n pi.zsh" || fail "zsh -n pi.zsh"

# --- Loads with pi, no-op without ---
out=$(zrun 'whence -w _pi; print -r -- "comp=${_comps[pi]}"')
[[ $out == *'_pi: function'* && $out == *'comp=_pi'* ]] && pass "with pi: _pi defined and registered" || fail "with pi: $out"

out=$(HOME="$TMP/empty" PATH="/usr/bin:/bin" "$ZSH" -f -c "
autoload -Uz compinit; compinit -u -D 2>/dev/null
source '$FILE'; print -r -- \"rc=\$?\"; whence -w _pi; print -r -- \"comp=\${_comps[pi]-none}\"" 2>&1)
[[ $out == *'rc=0'* && $out != *'_pi: function'* && $out == *'comp=none'* ]] && pass "without pi: no-op, nothing defined" || fail "without pi: $out"

# --- Live candidates come from the stub, read-only ---
out=$(zrun '_pi_models')
[[ $out == *'lmstudio/model-one@q4'* && $out == *'opencode-go/vendor/model-two'* && $out != *context* ]] \
  && pass "models: provider/id candidates, header skipped" || fail "models: $out"

out=$(zrun '_pi_providers')
[[ $out == *lmstudio* && $out == *opencode-go* && $out != *provider* ]] && pass "providers: names, header skipped" || fail "providers: $out"
[[ $(grep -o 'opencode-go' <<<"$out" | wc -l) -eq 1 ]] && pass "providers: no duplicates" || fail "providers: duplicates in $out"

out=$(zrun '_pi_packages')
[[ $out == *'npm:fake-package'* && $out == *'git:github.com/example/repo'* && $out != *'/fake/path'* ]] \
  && pass "packages: sources only, no paths" || fail "packages: $out"

# --- mcp.json: key names only, never values ---
out=$(zrun '_pi_mcp_servers')
[[ $out == *alpha* && $out == *beta* ]] && pass "mcp servers: names listed" || fail "mcp servers: $out"
[[ $out != *fake-secret-value* && $out != *example.invalid* && $out != *run-alpha* && $out != *TOKEN* ]] \
  && pass "mcp servers: no values printed" || fail "mcp servers: a value leaked: $out"

out=$(HOME="$TMP/empty" PATH="$BIN:/usr/bin:/bin" "$ZSH" -f -c "
autoload -Uz compinit; compinit -u -D 2>/dev/null
compadd() { print -r -- \"\$@\"; }
source '$FILE'; _pi_mcp_servers; print -r -- \"rc=\$?\"" 2>&1)
[[ $out == 'rc=0' ]] && pass "mcp servers: missing file gives no candidates, no error" || fail "mcp servers missing file: $out"

# --- No mutating or secret-reading call in the file (comments ignored) ---
code=$(grep -v '^[[:space:]]*#' "$FILE")
for bad in 'pi install' 'pi update' 'pi auth' 'pi mcp list' 'pi mcp add' 'pi remove' 'pi uninstall' \
           'pi print-' 'auth.json' '/sessions' '/.pi/agent/auth'; do
  if grep -qF -- "$bad" <<<"$code"; then fail "pi.zsh runs or reads: $bad"; else pass "pi.zsh does not use: $bad"; fi
done

# --- Wired into index.zsh after compinit and guarded ---
grep -q 'pi.zsh' "$INDEX" && pass "index.zsh sources pi.zsh" || fail "index.zsh does not source pi.zsh"
grep -q '\[\[ -r "\$HOME/.config/zsh/pi.zsh" \]\] && source' "$INDEX" && pass "index.zsh guard matches its neighbours" || fail "index.zsh guard missing"

echo
if [[ $FAILED -eq 0 ]]; then
  echo "PASS: pi completion tests"
else
  echo "FAILED: $FAILED check(s)"
  exit 1
fi
