#!/usr/bin/env bash
# Usage: bash scripts/detect-os.sh — prints "macos" or "arch"; exits 1 on unsupported OS

set -euo pipefail

if [[ "$OSTYPE" == "darwin"* ]]; then
  echo "macos"
elif [[ -f /etc/arch-release ]]; then
  echo "arch"
else
  echo "unsupported: $OSTYPE" >&2
  exit 1
fi
