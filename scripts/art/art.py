#!/usr/bin/env python3
"""Generate the build-time architecture diagram and print art freshness reminders."""

import fnmatch
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
IMAGE = ROOT / "website/assets/images/dotfiles-architecture.svg"
FIX = "task brand:generate"
INPUT_GLOBS = [
    "brand/*", "brand/**/*", "scripts/art/*", "scripts/art.sh", "scripts/brand_generate.py",
    "stow/*", "Taskfile.yml", "docs/decisions/*", "docs/guides/*", ".github/workflows/*",
    "README.md", "CHANGELOG.md", "packages/*", "website/assets/images/*",
]


def build():
    sys.path.insert(0, str(ROOT / "scripts/art"))
    import architecture
    import facts
    IMAGE.parent.mkdir(parents=True, exist_ok=True)
    IMAGE.write_text(architecture.svg(facts.read()), encoding="utf-8")
    print("wrote", IMAGE.relative_to(ROOT))
    return 0


def changed_files(args):
    if args[:1] == ["--staged"]:
        cmd = ["git", "diff", "--cached", "--name-only"]
    elif args[:1] == ["--working"]:
        cmd = ["git", "diff", "HEAD", "--name-only"]
    elif len(args) == 2 and args[0] == "--range":
        rng = args[1] if "..." in args[1] else args[1].replace("..", "...")
        cmd = ["git", "diff", "--name-only", rng]
    else:
        raise ValueError("usage: remind --staged | --working | --range A..B")
    out = subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True, check=True).stdout
    return [line for line in out.splitlines() if line]


def remind(args):
    try:
        changed = changed_files(args)
        if not any(fnmatch.fnmatch(path, pattern) for path in changed for pattern in INPUT_GLOBS):
            return 0
        sys.path.insert(0, str(ROOT / "scripts"))
        import brand_generate
        stale = brand_generate.check(ROOT)
        if stale:
            print("⚠️  MANUAL STEP — generated brand assets are out of date")
            print(f"    {FIX}")
            print("    git add brand/generated")
            print("(This reminder changes nothing and does not block the command.)")
    except Exception:
        pass
    return 0


def main(argv):
    if not argv:
        print("usage: art.sh build --only architecture --no-png | remind --staged | --working | --range A..B", file=sys.stderr)
        return 2
    if argv[0] == "build":
        return build()
    if argv[0] == "remind":
        return remind(argv[1:])
    print(f"art.sh: '{argv[0]}' is not implemented", file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
