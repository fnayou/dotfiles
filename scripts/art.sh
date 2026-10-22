#!/usr/bin/env bash
# Generate and check the repository's brand art and architecture diagram.
#
# Usage:
#   art.sh build [--only NAME] [--no-png]   write every image (SVG, then its PNG beside it)
#   art.sh logo                             rebuild the logo, its PNG and the favicon only
#   art.sh check                            read-only: committed SVGs and the palette are current
#   art.sh remind --staged | --working | --range A..B   read-only: print a reminder when art is stale
#
# Everything is Python 3 standard library. A PNG needs `rsvg-convert` (librsvg); without it the PNG
# step is skipped with a message and the SVG is still written. See docs/guides/art-setup.md.
set -euo pipefail

ART_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/art"
# -B: do not write __pycache__ into the repository
exec python3 -B "$ART_DIR/art.py" "$@"
