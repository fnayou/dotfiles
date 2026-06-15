#!/usr/bin/env bash
# Usage: bash scripts/check.sh — prints PASS/FAIL for each required tool; exits 1 if any fail

set -uo pipefail

FAILED=0

if command -v stow >/dev/null 2>&1; then
  echo "PASS: stow"
else
  echo "FAIL: stow (not installed)"
  FAILED=1
fi

if command -v git >/dev/null 2>&1; then
  echo "PASS: git"
else
  echo "FAIL: git (not installed)"
  FAILED=1
fi

if command -v task >/dev/null 2>&1; then
  echo "PASS: task"
else
  echo "FAIL: task (not installed)"
  FAILED=1
fi

exit "${FAILED}"
