#!/usr/bin/env python3
"""Prepare ignored website staging assets from committed brand sources."""

from pathlib import Path
import shutil

ROOT = Path(__file__).resolve().parents[1]
DEST = ROOT / "website/assets/generated-brand"


def main() -> None:
    DEST.mkdir(parents=True, exist_ok=True)
    for name in ("logo.svg", "favicon.svg", "social-preview.png"):
        shutil.copy2(ROOT / "brand/generated" / name, DEST / name)


if __name__ == "__main__":
    main()
