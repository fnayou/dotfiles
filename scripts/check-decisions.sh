#!/usr/bin/env bash
# Usage: bash scripts/check-decisions.sh — validates the ADR record; exits 1 on any inconsistency
#
# READ-ONLY. Touches nothing outside stdout. Needs no network and no $HOME, so it
# runs in CI.
#
# Why this exists: two audits missed two real contradictions. Review 0069's audit
# compared each ADR's status field against its index row, which cannot detect two
# ADRs that disagree with EACH OTHER — so ADR-0036 ("no local.zsh.example exists;
# this is intentional") and ADR-0054 (which describes that same file) both passed as
# Accepted. ADR-0064 recorded that gap. The same class of miss had already left
# ADR-0030's supersession of 0013/0014 unrecorded for weeks.
#
# Checks performed:
#   1. Every ADR file has exactly one index row in README.md
#   2. Index status matches the file's own Status field
#   3. Every index link target resolves to a real file
#   4. Every "Supersedes: Y" is matched by a "Superseded..." status on Y
#   5. Every ADR has a Status field at all
#   6. No duplicate ADR numbers

set -uo pipefail

DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../docs/decisions" && pwd)
INDEX="$DIR/README.md"
FAILED=0

fail() { echo "FAIL: $1"; FAILED=$((FAILED + 1)); }
pass() { echo "PASS: $1"; }

[[ -f "$INDEX" ]] || { echo "FAIL: $INDEX not found"; exit 1; }

# Normalise a status string: turn markdown links into bare numbers and squeeze
# whitespace, so `Superseded by [ADR-0030](0030-x.md)` compares equal to the index's
# `Superseded by 0030`. Handles [ADR-NNNN](...) and [NNNN](...) alike.
normalise_status() {
  sed -E 's/\[(ADR-)?([0-9]{4})\]\([^)]*\)/\2/g; s/[[:space:]]+/ /g; s/^ //; s/ $//'
}

# A file's own Status, from either `**Status:** X` or `- Status: X`.
file_status() {
  grep -m1 -E '^\*\*Status:\*\*|^- Status:' "$1" 2>/dev/null |
    sed -E 's/^\*\*Status:\*\* *//; s/^- Status: *//' | normalise_status
}

# The status cell for an ADR number in the index table.
index_status() {
  grep -m1 "^| \[$1\]" "$INDEX" | awk -F'|' '{print $4}' | normalise_status
}

cd "$DIR"

count=0
for f in [0-9][0-9][0-9][0-9]-*.md; do
  [[ -e "$f" ]] || { echo "FAIL: no ADR files found in $DIR"; exit 1; }
  count=$((count + 1))
  n=${f%%-*}

  # 6. duplicate numbers
  matches=$(printf '%s\n' "$n"-*.md | wc -l | tr -d ' ')
  if [[ "$matches" -gt 1 ]]; then
    fail "$n — $matches files share this number"
  fi

  # 5. status present
  fs=$(file_status "$f")
  if [[ -z "$fs" ]]; then
    fail "$n — no Status field in $f"
    continue
  fi

  # 1 + 2. indexed, and consistently
  rows=$(grep -c "^| \[$n\]" "$INDEX")
  if [[ "$rows" -eq 0 ]]; then
    fail "$n — not listed in README.md"
  elif [[ "$rows" -gt 1 ]]; then
    fail "$n — listed $rows times in README.md"
  else
    is=$(index_status "$n")
    [[ "$fs" != "$is" ]] && fail "$n — file says '$fs', index says '$is'"
  fi

  # 4. supersession is mutual.
  # Parenthesised segments are stripped FIRST: they hold prose that mentions other
  # ADRs without superseding them, e.g. ADR-0032's
  #   "**Supersedes:** N/A (lifts the ADR-0009 restriction for this bounded case)"
  # which named 0009 without superseding it. Markdown link targets live in
  # parentheses too, and their number is already present in the label.
  sup_line=$(grep -m1 -E '^\*\*Supersedes:\*\*' "$f" 2>/dev/null)
  if [[ -n "$sup_line" ]]; then
    targets=$(printf '%s\n' "$sup_line" | sed -E 's/\([^)]*\)//g' | grep -oE '[0-9]{4}' | sort -u)
    for t in $targets; do
      tf=$(printf '%s\n' "$t"-*.md)
      if [[ ! -f "$tf" ]]; then
        fail "$n — claims to supersede $t, which does not exist"
        continue
      fi
      ts=$(file_status "$tf")
      case "$ts" in
        *[Ss]uperseded*) ;;
        *) fail "$t — superseded by $n, but its status reads '$ts'" ;;
      esac
    done
  fi
done

# 3. index links resolve
while IFS= read -r target; do
  [[ -f "$target" ]] || fail "index links to $target, which does not exist"
done < <(awk -F'[()]' '/^\| \[[0-9]{4}\]/ {print $2}' "$INDEX")

# Index rows with no corresponding file
while IFS= read -r n; do
  [[ -n "$(printf '%s\n' "$n"-*.md 2>/dev/null | grep -v '\*')" ]] ||
    fail "index lists $n, but no such ADR file exists"
done < <(grep -oE '^\| \[[0-9]{4}\]' "$INDEX" | grep -oE '[0-9]{4}')

echo
if [[ $FAILED -eq 0 ]]; then
  pass "decision record is self-consistent ($count ADRs)"
  exit 0
fi
echo "$FAILED inconsistency(ies) found."
exit 1
