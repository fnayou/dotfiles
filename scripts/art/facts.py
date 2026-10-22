"""Facts about the repository, read from files only.

No subprocess, no git, no `task` binary and no clock: two runs on the same checkout return the same
dictionary, so the SVGs built from it are byte-identical. Every list is sorted.
"""
import re
from pathlib import Path

import palette

ROOT = Path(__file__).resolve().parents[2]
BOILERPLATE = {"README.md", ".stow-local-ignore", ".DS_Store"}
MACCHIATO_HEX = {v.lstrip("#").lower() for v in palette.COLORS.values()}
HEX = re.compile(r"(?<![0-9A-Za-z])(#?)([0-9a-fA-F]{6})(?![0-9A-Za-z])")


def _ignored(patterns, rel):
    for pat in patterns:
        try:
            if re.fullmatch(pat, "/" + rel) or re.fullmatch(pat, rel.split("/")[-1]) or re.search(pat + r"$", "/" + rel):
                return True
        except re.error:
            continue
    return False


def package(area, d):
    files = sorted(f for f in d.rglob("*") if f.is_file() and f.name not in BOILERPLATE)
    ign = d / ".stow-local-ignore"
    patterns = []
    if ign.exists():
        patterns = [l.strip() for l in ign.read_text(encoding="utf-8").splitlines() if l.strip() and not l.startswith("#")]
    dests, unlinked, hexes = set(), [], 0
    for f in files:
        rel = str(f.relative_to(d))
        if _ignored(patterns, rel):
            unlinked.append(rel.split("/")[-1])
            continue
        top = rel.split("/")
        if top[0] == ".config" and len(top) > 2:
            dests.add("~/.config/" + top[1])
        elif top[0].startswith("."):
            dests.add("~/" + top[0])
    for f in files:
        try:
            text = f.read_text(encoding="utf-8")
        except (UnicodeDecodeError, OSError):
            continue
        hexes += sum(1 for m in HEX.finditer(text)
                     if m.group(2).lower() in MACCHIATO_HEX and (m.group(1) == "#" or f.suffix == ".theme"))
    readme = d / "README.md"
    says = readme.exists() and "macchiato" in readme.read_text(encoding="utf-8").lower()
    return {"name": d.name, "area": area, "files": len(files), "dests": sorted(dests),
            "unlinked": sorted(unlinked), "palette": hexes > 0 or says}


def tasks(taskfile):
    """Top-level task names: the keys at two-space indent under `tasks:`."""
    names, inside = [], False
    for line in taskfile.read_text(encoding="utf-8").splitlines():
        if re.match(r"^tasks:\s*$", line):
            inside = True
            continue
        if inside and re.match(r"^\S", line) and not line.startswith("#"):
            break
        m = re.match(r"^  ([A-Za-z0-9][A-Za-z0-9:_-]*):\s*$", line) if inside else None
        if m:
            names.append(m.group(1))
    return sorted(names)


def install_count(path):
    names = set()
    for line in path.read_text(encoding="utf-8").splitlines():
        m = re.match(r"#\s+(?:sudo\s+)?(?:pacman -S|yay -S|apt(?:-get)? install)\s+(.*)", line)
        if m:
            body = m.group(1).split(" # ")[0].split("#")[0]
            names.update(t for t in body.split() if not t.startswith("-"))
    return len(names)


def release(changelog):
    for line in changelog.read_text(encoding="utf-8").splitlines():
        m = re.match(r"^## \[([^\]]+)\]", line)
        if m and m.group(1).lower() != "unreleased":
            return "v" + m.group(1)
    return "dev"


def read():
    f = {"packages": []}
    for area in ("common", "macos", "arch", "debian"):
        base = ROOT / "stow" / area
        if base.is_dir():
            for d in sorted(base.iterdir()):
                if d.is_dir() and not d.name.startswith("."):
                    f["packages"].append(package(area, d))
    f["tasks"] = tasks(ROOT / "Taskfile.yml")
    groups = {}
    for n in f["tasks"]:
        groups.setdefault(n.split(":")[0], []).append(n)
    f["task_groups"] = {k: sorted(v) for k, v in sorted(groups.items())}
    f["scripts"] = sorted(p.name for p in (ROOT / "scripts").glob("*.sh"))
    d = ROOT / "docs"
    f["docs"] = {name: len(list((d / name).glob("[0-9]*.md"))) for name in
                 ("prd", "architecture", "plans", "reviews", "decisions")}
    f["docs"]["guides"] = len(list((d / "guides").glob("*.md")))
    cl = ROOT / ".claude"
    f["agents"] = sorted(p.stem for p in (cl / "agents").glob("*.md"))
    f["rules"] = sorted(p.stem for p in (cl / "rules").glob("*.md"))
    f["skills"] = sorted(p.name for p in (cl / "skills").iterdir() if p.is_dir())
    zi = (ROOT / "stow/common/zsh/.config/zsh/index.zsh").read_text(encoding="utf-8")
    f["zsh_layers"] = re.findall(r'source "\$HOME/\.config/zsh/([a-z]+)\.zsh"', zi)
    ci = (ROOT / ".github/workflows/ci.yml").read_text(encoding="utf-8")
    f["ci_steps"] = [s.strip() for s in re.findall(r"- name: (.+)", ci) if s.strip() != "Checkout repository"]
    f["workflows"] = sorted(p.name for p in (ROOT / ".github/workflows").glob("*.yml"))
    f["brew"] = sum(1 for l in (ROOT / "packages/Brewfile").read_text(encoding="utf-8").splitlines() if l.startswith(("brew ", "cask ")))
    f["arch_pkgs"] = install_count(ROOT / "packages/arch/packages.txt")
    f["debian_pkgs"] = install_count(ROOT / "packages/debian/packages.txt")
    f["version"] = release(ROOT / "CHANGELOG.md")
    return f


if __name__ == "__main__":
    import json
    print(json.dumps(read(), indent=1, sort_keys=True))
