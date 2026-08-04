#!/usr/bin/env bash
# Usage: bash scripts/detect-os.sh — prints "macos", "arch", or "debian"; exits 1 on unsupported OS
#
# Debian became a supported platform in ADR-0053; this script was not updated at the
# time and reported it as unsupported.
#
# Order matters (AGENTS.md §10): /etc/arch-release is tested BEFORE
# /etc/debian_version. The Debian marker is present on Debian and on every
# derivative, so testing it first would misreport any system carrying both.
# scripts/check-zsh-deps.sh and scripts/doctor.sh use this same ordering.

set -euo pipefail

if [[ "$OSTYPE" == "darwin"* ]]; then
  echo "macos"
elif [[ -f /etc/arch-release ]]; then
  echo "arch"
elif [[ -f /etc/debian_version ]]; then
  echo "debian"
else
  echo "unsupported: $OSTYPE" >&2
  exit 1
fi
