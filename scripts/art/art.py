#!/usr/bin/env python3
"""Command line for the art generators. See scripts/art.sh and docs/guides/art-setup.md."""
import fnmatch
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
IMAGES = ROOT / "website/assets/images"
THEME = ROOT / "stow/common/alacritty/.config/alacritty/catppuccin-macchiato.toml"

# name -> (SVG base name, committed?). The diagram is generated at docs build and git-ignored.
OUTPUTS = {
    "banner": ("dotfiles-readme-banner", True),
    "social": ("dotfiles-social-preview", True),
    "logo": ("dotfiles-logo", True),
    "architecture": ("dotfiles-architecture", False),
}
FIX = "task art:build"

# A change to any of these can alter an image, so only then is a stale SVG worth a reminder.
INPUT_GLOBS = [
    "scripts/art/*", "scripts/art.sh", "stow/*", "Taskfile.yml", "docs/decisions/*", "docs/guides/*",
    ".github/workflows/*", "README.md", "CHANGELOG.md", "packages/*", "website/assets/images/*",
]
SHORT = {"dotfiles-readme-banner.svg": "banner", "dotfiles-social-preview.svg": "social preview",
         "dotfiles-logo.svg": "logo"}


def markup(name, facts):
    if name == "banner":
        import banner
        return banner.svg(facts)
    if name == "social":
        import social
        return social.svg(facts)
    if name == "logo":
        import logo
        return logo.svg()
    if name == "architecture":
        import architecture
        return architecture.svg(facts)
    raise KeyError(name)


def build(names, png=True):
    import facts as facts_mod
    import render
    facts = facts_mod.read()
    for name in names:
        base, _ = OUTPUTS[name]
        svg = markup(name, facts)
        print("wrote", render.write(svg, IMAGES / f"{base}.svg", png=png))
        if name == "logo" and png:
            print("wrote", render.write_png_from_svg(svg, IMAGES / "favicon.png", 64, 64))
    return 0


def stale_svgs(facts):
    """Committed SVGs whose bytes differ from a fresh render."""
    stale = []
    for name, (base, committed) in OUTPUTS.items():
        if not committed:
            continue
        path = IMAGES / f"{base}.svg"
        fresh = markup(name, facts)
        if not path.exists() or path.read_text(encoding="utf-8") != fresh:
            stale.append(path.relative_to(ROOT).as_posix())
    return stale


def check():
    import facts as facts_mod
    import palette
    problems = palette.check(THEME)
    for p in problems:
        print(f"palette: {p}", file=sys.stderr)
    stale = stale_svgs(facts_mod.read())
    for s in stale:
        print(f"stale: {s}", file=sys.stderr)
    if stale:
        print(f"Regenerate with: {FIX}", file=sys.stderr)
    return 1 if (problems or stale) else 0


def changed_files(args):
    """File names for `--staged` or `--range A..B` (compared from the merge base, as a pull request is)."""
    if args[:1] == ["--staged"]:
        cmd = ["git", "diff", "--cached", "--name-only"]
    elif args[:1] == ["--working"]:  # `git commit -a`: staged changes plus modified tracked files
        cmd = ["git", "diff", "HEAD", "--name-only"]
    elif len(args) == 2 and args[0] == "--range":
        rng = args[1] if "..." in args[1] else args[1].replace("..", "...")
        cmd = ["git", "diff", "--name-only", rng]
    else:
        raise ValueError("usage: remind --staged | --working | --range A..B")
    out = subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True, check=True).stdout
    return [l for l in out.splitlines() if l]


def remind(args):
    """Print a reminder when an input changed and a committed SVG is stale. Silent otherwise.

    Read-only, and it never fails a commit: any error ends in silence and exit status 0.
    """
    try:
        files = changed_files(args)
        if not any(fnmatch.fnmatch(f, g) for f in files for g in INPUT_GLOBS):
            return 0
        import facts as facts_mod
        stale = stale_svgs(facts_mod.read())
        if not stale:
            return 0
        names = ", ".join(SHORT.get(Path(f).name, Path(f).name) for f in stale)
        print(f"⚠️  MANUAL STEP — the generated art is out of date ({names})")
        print(f"    {FIX}")
        print("    git add website/assets/images")
        print("(This reminder changes nothing. CI fails the pull request until the SVGs are current.)")
    except Exception:
        pass
    return 0


def parse_only(args):
    names = list(OUTPUTS)
    png = True
    i = 0
    while i < len(args):
        a = args[i]
        if a == "--no-png":
            png = False
        elif a == "--only" and i + 1 < len(args):
            i += 1
            names = args[i].split(",")
        else:
            raise SystemExit(f"art.sh: unknown option '{a}'")
        i += 1
    for n in names:
        if n not in OUTPUTS:
            raise SystemExit(f"art.sh: unknown image '{n}' (one of: {', '.join(OUTPUTS)})")
    return names, png


def main(argv):
    if not argv:
        print("usage: art.sh build [--only NAME] [--no-png] | logo | check | remind", file=sys.stderr)
        return 2
    cmd, rest = argv[0], argv[1:]
    try:
        if cmd == "build":
            names, png = parse_only(rest)
            return build(names, png)
        if cmd == "logo":
            return build(["logo"], True)
        if cmd == "check":
            return check()
        if cmd == "remind":
            return remind(rest)
    except Exception as exc:  # RenderError and friends: say what failed, change nothing
        print(f"art.sh: {exc}", file=sys.stderr)
        return 1
    print(f"art.sh: '{cmd}' is not implemented yet", file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
