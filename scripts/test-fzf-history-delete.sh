#!/usr/bin/env bash
# Usage: bash scripts/test-fzf-history-delete.sh
# Tests stow/common/zsh/.config/zsh/scripts/fzf-history-delete against a history file that zsh
# itself writes, in a temporary directory. Needs zsh. Exits 1 if any check fails.
#
# NEVER reads or writes $HOME/.zsh_history: every run sets HISTFILE to a file under mktemp -d.
# The commands in the test history are made up.

set -uo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
HELPER="$ROOT/stow/common/zsh/.config/zsh/scripts/fzf-history-delete"
TMP=$(mktemp -d)
FAILED=0

cleanup() { chmod -R u+w "$TMP" 2>/dev/null; rm -rf "$TMP"; }
trap cleanup EXIT

pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; FAILED=$((FAILED + 1)); }

command -v zsh >/dev/null 2>&1 || { echo "FAIL: zsh not installed"; exit 1; }
[[ -r "$HELPER" ]] || { echo "FAIL: helper not found: $HELPER"; exit 1; }

# Build a history file written by zsh itself (EXTENDED_HISTORY format), one entry per print -rs.
GEN="$TMP/gen.zsh"
{
  printf '%s\n' 'HISTFILE=$1; HISTSIZE=1000; SAVEHIST=1000; setopt EXTENDED_HISTORY'
  printf '%s\n' "print -rs -- 'echo tok-single'"
  printf '%s\n' "print -rs -- \$'echo tok-multi-bs \\\\\\nsecond-bs'"
  printf '%s\n' "print -rs -- \$'echo tok-multi-plain\\nsecond-plain'"
  printf '%s\n' "print -rs -- 'echo tok-trail-bs \\'"
  printf '%s\n' "print -rs -- 'echo tok-mid-bs a\\\\b'"
  printf '%s\n' "print -rs -- 'echo tok-end-two-bs x\\\\'"
  printf '%s\n' "print -rs -- \$'echo tok-special \$HOME \"q\" \\'s\\' \`x\`'"
  printf '%s\n' "print -rs -- 'echo tok-pre'"
  printf '%s\n' "print -rs -- 'echo tok-pre-longer'"
  printf '%s\n' "print -rs -- 'echo tok-single'"
  printf '%s\n' "print -rs -- 'echo tok-unicode café ñ 日本 ✓'"
  printf '%s\n' "print -rs -- 'echo tok-last'"
  printf '%s\n' "fc -W"
} >"$GEN"

fresh() { # fresh <name> -> sets H (history file) with a new copy of the generated history
  H="$TMP/$1/h"; mkdir -p "$TMP/$1"
  zsh -f -i -c "source '$GEN' '$H'" </dev/null >/dev/null 2>&1
}

item_file() { # item_file <path> <command text> -> picker item: "N<TAB>command", tab after each newline
  local text=${2//$'\n'/$'\n\t'}
  printf '12\t%s' "$text" >"$1"
}

run() { # run <history file> <command text> -> sets RC and OUT
  local f="$TMP/item"; item_file "$f" "$2"
  OUT=$(HISTFILE="$1" zsh "$HELPER" "$f" 2>&1); RC=$?
}

entries() { grep -c -a '^: [0-9]*:[0-9]*;' "$1"; }
has() { grep -a -q -F -- "$2" "$1"; }

expect_removed() { # expect_removed <name> <command text> <token> <expected removed entries>
  local name=$1 text=$2 tok=$3 n=$4
  fresh "$name"; cp -p "$H" "$TMP/$name/orig"
  local before; before=$(entries "$H")
  run "$H" "$text"
  [[ $RC -eq 0 ]] && pass "$name: exit 0" || fail "$name: exit $RC (expected 0)"
  [[ -z $OUT ]] && pass "$name: prints nothing" || fail "$name: printed output"
  has "$H" "$tok" && fail "$name: '$tok' still present" || pass "$name: '$tok' removed"
  [[ $(entries "$H") -eq $((before - n)) ]] && pass "$name: $n entries removed" || fail "$name: entry count $(entries "$H"), expected $((before - n))"
  [[ -z $(diff "$TMP/$name/orig" "$H" | grep -a '^>') ]] && pass "$name: no line added or changed" || fail "$name: lines were changed"
  cmp -s "$TMP/$name/orig" "$H.bak" && pass "$name: backup equals the original" || fail "$name: backup missing or different"
}

expect_untouched() { # expect_untouched <name> <command text> <expected exit>
  local name=$1 text=$2 rc=$3
  fresh "$name"; cp -p "$H" "$TMP/$name/orig"
  run "$H" "$text"
  [[ $RC -eq $rc ]] && pass "$name: exit $rc" || fail "$name: exit $RC (expected $rc)"
  [[ -z $OUT ]] && pass "$name: prints nothing" || fail "$name: printed output"
  cmp -s "$TMP/$name/orig" "$H" && pass "$name: file unchanged" || fail "$name: file changed"
}

# --- Matches ---
expect_removed single      'echo tok-single'                        tok-single       2
expect_removed multi_plain $'echo tok-multi-plain\nsecond-plain'    tok-multi-plain  1
expect_removed multi_bs    $'echo tok-multi-bs \\\nsecond-bs'       tok-multi-bs     1
expect_removed trail_bs    'echo tok-trail-bs \'                    tok-trail-bs     1
expect_removed mid_bs      'echo tok-mid-bs a\\b'                   tok-mid-bs       1
expect_removed end_two_bs  'echo tok-end-two-bs x\\'                tok-end-two-bs   1
expect_removed special     $'echo tok-special $HOME "q" \'s\' `x`'  tok-special      1
expect_removed unicode     'echo tok-unicode café ñ 日本 ✓'          tok-unicode      1

# Look-alike: removing "echo tok-pre" removes exactly that entry and keeps "echo tok-pre-longer".
fresh lookalike; before=$(entries "$H"); run "$H" 'echo tok-pre'
[[ $RC -eq 0 ]] && ! grep -a -q ';echo tok-pre$' "$H" && pass "lookalike: exact command removed" || fail "lookalike: exact command still present (rc=$RC)"
has "$H" 'echo tok-pre-longer' && pass "lookalike: longer command kept" || fail "lookalike: longer command was removed"
[[ $(entries "$H") -eq $((before - 1)) ]] && pass "lookalike: one entry removed" || fail "lookalike: entry count wrong"

# --- No match, bad input ---
expect_untouched nomatch   'echo not-in-history'                    1
expect_untouched partial   'echo tok-sing'                          1
expect_untouched empty     ''                                       2

# Item without the "N<TAB>" prefix is rejected, file untouched.
fresh noprefix; cp -p "$H" "$TMP/noprefix/orig"
printf 'echo tok-last' >"$TMP/item"; OUT=$(HISTFILE="$H" zsh "$HELPER" "$TMP/item" 2>&1); RC=$?
[[ $RC -eq 2 && -z $OUT ]] && cmp -s "$TMP/noprefix/orig" "$H" && pass "noprefix: rejected, file unchanged" || fail "noprefix: exit $RC"

# Missing arguments and missing history file.
OUT=$(HISTFILE="$TMP/none" zsh "$HELPER" 2>&1); RC=$?
[[ $RC -eq 2 && -z $OUT ]] && pass "noargs: exit 2" || fail "noargs: exit $RC"
item_file "$TMP/item" 'echo x'
OUT=$(HISTFILE="$TMP/does-not-exist" zsh "$HELPER" "$TMP/item" 2>&1); RC=$?
[[ $RC -eq 2 && -z $OUT ]] && pass "nofile: exit 2" || fail "nofile: exit $RC"

# --- Permissions ---
fresh perms; chmod 600 "$H"; run "$H" 'echo tok-last'
mode=$(stat -f '%Lp' "$H" 2>/dev/null || stat -c '%a' "$H")
bmode=$(stat -f '%Lp' "$H.bak" 2>/dev/null || stat -c '%a' "$H.bak")
[[ $RC -eq 0 && $mode == 600 && $bmode == 600 ]] && pass "perms: history and backup stay 600" || fail "perms: rc=$RC history=$mode backup=$bmode"

# --- Failed write leaves the original untouched ---
fresh readonly; cp -p "$H" "$TMP/readonly/orig"; chmod 555 "$TMP/readonly"
run "$H" 'echo tok-last'
chmod 755 "$TMP/readonly"
[[ $RC -ne 0 && $RC -ne 1 ]] && pass "readonly: failed write exits non-zero ($RC)" || fail "readonly: exit $RC"
cmp -s "$TMP/readonly/orig" "$H" && pass "readonly: original untouched" || fail "readonly: original changed"
[[ -z $(ls "$TMP/readonly" | grep -v -E '^(h|orig)$') ]] && pass "readonly: no temp file left" || fail "readonly: stray files: $(ls "$TMP/readonly")"

echo
if [[ $FAILED -eq 0 ]]; then
  echo "PASS: fzf-history-delete tests"
else
  echo "FAILED: $FAILED check(s)"
  exit 1
fi
