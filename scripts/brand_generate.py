#!/usr/bin/env python3
"""Deterministic brand asset generator.

Renders SVG templates in brand/src with values from brand/data into
brand/generated. Copy this file into a project's scripts directory.

    brand_generate.py --generate   write brand/generated
    brand_generate.py --check      fail when committed output is stale

Standard library only. Raster derivatives are optional and need rsvg-convert.
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
import tempfile
import xml.etree.ElementTree as ET
from pathlib import Path
from xml.sax.saxutils import escape

PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"
HEX_COLOR = re.compile(r"^#[0-9a-fA-F]{6}$")
PLACEHOLDER = re.compile(r"\{\{[^}]*\}\}")
LOOSE_COLOR = re.compile(
    r"(?:fill|stroke|stop-color|flood-color|color)\s*[:=]\s*[\"']?\s*#[0-9a-fA-F]{3,8}\b"
)
REMOTE_REFERENCE = re.compile(r"(?:href|src)\s*=\s*[\"']\s*(?:https?:)?//", re.IGNORECASE)


class BrandError(Exception):
    """Raised when brand data, a template, or generated output is invalid."""


def read_json(path: Path) -> dict:
    if not path.is_file():
        raise BrandError(f"missing {path}")
    try:
        with path.open(encoding="utf-8") as handle:
            value = json.load(handle)
    except json.JSONDecodeError as error:
        raise BrandError(f"{path} is not valid JSON: {error}") from error
    if not isinstance(value, dict):
        raise BrandError(f"{path} must contain a JSON object")
    return value


def load_tokens(brand: dict, facts: dict) -> dict[str, str]:
    palette = brand.get("palette")
    if not isinstance(palette, dict) or not palette:
        raise BrandError("brand.json needs a non-empty palette object")
    tokens: dict[str, str] = {}
    for key, value in palette.items():
        if not isinstance(value, str) or not HEX_COLOR.fullmatch(value):
            raise BrandError(f"palette entry {key} must be a hex color like #24273a")
        tokens[key.upper()] = value
    if "ACCENT" not in tokens:
        raise BrandError("palette needs an accent entry")
    for key, value in facts.items():
        if isinstance(value, list) and all(isinstance(item, (str, int)) for item in value):
            text = ", ".join(str(item) for item in value)
        elif isinstance(value, (str, int)) and not isinstance(value, bool):
            text = str(value)
        else:
            raise BrandError(f"fact {key} must be a string, number, or list of those")
        if key.upper() in tokens:
            raise BrandError(f"fact {key} collides with a palette entry")
        tokens[key.upper()] = escape(text)
    return tokens


def check_template(name: str, text: str) -> None:
    if LOOSE_COLOR.search(text):
        raise BrandError(f"template {name} uses a loose hex color; use a palette token")
    if REMOTE_REFERENCE.search(text) or "<script" in text.lower():
        raise BrandError(f"template {name} has a remote reference or script")


def render(name: str, template: str, tokens: dict[str, str]) -> str:
    check_template(name, template)
    rendered = template
    for token, value in sorted(tokens.items()):
        rendered = rendered.replace("{{" + token + "}}", value)
    leftover = PLACEHOLDER.search(rendered)
    if leftover:
        raise BrandError(f"template {name} has an unresolved placeholder {leftover.group(0)}")
    try:
        root = ET.fromstring(rendered)
    except ET.ParseError as error:
        raise BrandError(f"template {name} renders to invalid XML: {error}") from error
    if not root.tag.endswith("svg") or not root.get("viewBox"):
        raise BrandError(f"template {name} must be an svg element with a viewBox")
    if not any(child.tag.endswith("title") for child in root):
        raise BrandError(f"template {name} needs a title element for an accessible name")
    return rendered if rendered.endswith("\n") else rendered + "\n"


def render_all(root: Path) -> dict[str, str]:
    data_dir = root / "brand" / "data"
    src_dir = root / "brand" / "src"
    facts = read_json(data_dir / "facts.json")
    sys.path.insert(0, str(root / "scripts" / "art"))
    import facts as repository_facts
    derived = repository_facts.read()
    facts.update({
        "package_count": len(derived["packages"]),
        "task_count": len(derived["tasks"]),
        "release": derived["version"],
    })
    tokens = load_tokens(read_json(data_dir / "brand.json"), facts)
    sources = sorted(src_dir.glob("*.svg"))
    if not sources:
        raise BrandError(f"no SVG templates in {src_dir}")
    return {
        path.name: render(path.name, path.read_text(encoding="utf-8"), tokens)
        for path in sources
    }


def raster_specs(root: Path) -> list[dict]:
    specs = read_json(root / "brand" / "data" / "brand.json").get("rasters", [])
    if not isinstance(specs, list):
        raise BrandError("brand.json rasters must be a list")
    for spec in specs:
        if not (
            isinstance(spec, dict)
            and isinstance(spec.get("source"), str)
            and isinstance(spec.get("width"), int)
            and isinstance(spec.get("height"), int)
        ):
            raise BrandError("each raster needs source, width, and height")
    return specs


def rasterize(svg_text: str, width: int, height: int) -> bytes:
    with tempfile.TemporaryDirectory(prefix="brand-") as tmp:
        svg_path = Path(tmp) / "in.svg"
        png_path = Path(tmp) / "out.png"
        svg_path.write_text(svg_text, encoding="utf-8")
        try:
            done = subprocess.run(
                ["rsvg-convert", "-w", str(width), "-h", str(height), "-o", str(png_path), str(svg_path)],
                capture_output=True,
                check=False,
            )
        except FileNotFoundError as error:
            raise BrandError("rsvg-convert is not installed (package librsvg2-bin)") from error
        if done.returncode != 0:
            raise BrandError("rsvg-convert failed: " + done.stderr.decode("utf-8", "replace").strip())
        return png_path.read_bytes()


def png_problems(data: bytes, width: int, height: int) -> list[str]:
    if data[:8] != PNG_SIGNATURE:
        return ["not a PNG file"]
    actual = (int.from_bytes(data[16:20], "big"), int.from_bytes(data[20:24], "big"))
    if actual != (width, height):
        return [f"size is {actual[0]}x{actual[1]}, expected {width}x{height}"]
    return []


def generate(root: Path) -> None:
    out_dir = root / "brand" / "generated"
    out_dir.mkdir(parents=True, exist_ok=True)
    rendered = render_all(root)
    for name, text in rendered.items():
        (out_dir / name).write_text(text, encoding="utf-8")
    for spec in raster_specs(root):
        if spec["source"] not in rendered:
            raise BrandError(f"raster source {spec['source']} has no template")
        png = rasterize(rendered[spec["source"]], spec["width"], spec["height"])
        (out_dir / (Path(spec["source"]).stem + ".png")).write_bytes(png)


def check(root: Path) -> list[str]:
    out_dir = root / "brand" / "generated"
    problems: list[str] = []
    rendered = render_all(root)
    sys.path.insert(0, str(root / "scripts" / "art"))
    import palette
    theme = root / "stow/common/alacritty/.config/alacritty/catppuccin-macchiato.toml"
    problems.extend(f"palette: {problem}" for problem in palette.check(theme))
    for name, text in rendered.items():
        path = out_dir / name
        if not path.is_file():
            problems.append(f"missing generated/{name}")
        elif path.read_text(encoding="utf-8") != text:
            problems.append(f"stale generated/{name}")
    for path in sorted(out_dir.glob("*.svg")) if out_dir.is_dir() else []:
        if path.name not in rendered:
            problems.append(f"generated/{path.name} has no template")
    for spec in raster_specs(root):
        path = out_dir / (Path(spec["source"]).stem + ".png")
        if not path.is_file():
            problems.append(f"missing generated/{path.name}")
            continue
        problems += [f"generated/{path.name}: {p}" for p in png_problems(path.read_bytes(), spec["width"], spec["height"])]
    return problems


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--generate", action="store_true")
    mode.add_argument("--check", action="store_true")
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1])
    args = parser.parse_args(argv)
    try:
        if args.generate:
            generate(args.root)
            print("brand assets generated")
            return 0
        problems = check(args.root)
    except BrandError as error:
        print(f"brand: {error}", file=sys.stderr)
        return 1
    for problem in problems:
        print(f"brand: {problem}", file=sys.stderr)
    if problems:
        return 1
    print("brand assets are current")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
