#!/usr/bin/env python3
"""Check a built documentation site without network access.

Copy this file into a project's scripts directory.

    check_docs.py site                        check the built HTML
    check_docs.py site --base-path /repo/     also reject links outside the base path
    check_docs.py site --palette brand/data/brand.json
                                              also check palette contrast
    check_docs.py site --require-og-image     every page needs an absolute og:image

Standard library only. Exits 1 and prints one line per problem.
"""

from __future__ import annotations

import argparse
import json
import sys
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import unquote, urlsplit

MIN_CONTRAST = 4.5


class Page(HTMLParser):
    def __init__(self, name: str) -> None:
        super().__init__(convert_charrefs=True)
        self.name = name
        self.errors: list[str] = []
        self.ids: set[str] = set()
        self.links: list[tuple[int, str]] = []
        self.lang = ""
        self.title = ""
        self.in_title = False
        self.h1 = 0
        self.main = 0
        self.og_image = ""
        self.in_anchor: list[dict] = []

    def handle_starttag(self, tag: str, pairs: list[tuple[str, str | None]]) -> None:
        attrs = {key: value or "" for key, value in pairs}
        line = self.getpos()[0]
        if tag == "html":
            self.lang = attrs.get("lang", "").strip()
        elif tag == "title":
            self.in_title = True
        elif tag == "h1":
            self.h1 += 1
        elif tag == "main":
            self.main += 1
        elif tag == "meta" and attrs.get("property") == "og:image":
            self.og_image = attrs.get("content", "").strip()
        elif tag == "img" and "alt" not in attrs:
            self.errors.append(f"{self.name}:{line}: image has no alt attribute")
        if attrs.get("id"):
            self.ids.add(attrs["id"])
        if tag == "a" and attrs.get("name"):
            self.ids.add(attrs["name"])
        if tag in {"a", "link"} and attrs.get("href", "").strip():
            self.links.append((line, attrs["href"].strip()))
        if tag in {"script", "img"} and attrs.get("src", "").strip():
            self.links.append((line, attrs["src"].strip()))
        if tag == "a" and attrs.get("href") and not attrs.get("id", "").startswith("__codelineno-"):
            named = any(attrs.get(k, "").strip() for k in ("aria-label", "aria-labelledby", "title"))
            self.in_anchor.append({"line": line, "named": named, "text": ""})
        if tag == "img" and attrs.get("alt") and self.in_anchor:
            self.in_anchor[-1]["text"] += attrs["alt"]

    def handle_endtag(self, tag: str) -> None:
        if tag == "title":
            self.in_title = False
        elif tag == "a" and self.in_anchor:
            anchor = self.in_anchor.pop()
            if not anchor["named"] and not anchor["text"].strip():
                self.errors.append(f"{self.name}:{anchor['line']}: link has no accessible name")

    def handle_data(self, data: str) -> None:
        if self.in_title:
            self.title += data
        if self.in_anchor:
            self.in_anchor[-1]["text"] += data

    def problems(self, require_og_image: bool = False) -> list[str]:
        if require_og_image and not self.og_image.startswith(("https://", "http://")):
            self.errors.append(f"{self.name}: missing absolute og:image meta tag")
        if not self.lang:
            self.errors.append(f"{self.name}: missing html lang attribute")
        if not self.title.strip():
            self.errors.append(f"{self.name}: missing title")
        if self.h1 != 1:
            self.errors.append(f"{self.name}: expected one h1, found {self.h1}")
        if not self.main:
            self.errors.append(f"{self.name}: missing main landmark")
        return self.errors


def resolve(root: Path, page: Path, href: str) -> tuple[Path, str]:
    parsed = urlsplit(href)
    path = unquote(parsed.path)
    target = root / page if not path else (root / path.lstrip("/") if path.startswith("/") else root / page.parent / path)
    target = target.resolve()
    if target.is_dir() or (not target.exists() and not target.suffix):
        target = target / "index.html"
    return target, unquote(parsed.fragment)


def luminance(color: str) -> float:
    channels = [int(color[i : i + 2], 16) / 255 for i in (1, 3, 5)]
    linear = [c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4 for c in channels]
    return 0.2126 * linear[0] + 0.7152 * linear[1] + 0.0722 * linear[2]


def contrast(first: str, second: str) -> float:
    light, dark = sorted((luminance(first), luminance(second)), reverse=True)
    return (light + 0.05) / (dark + 0.05)


def palette_problems(path: Path) -> list[str]:
    palette = json.loads(path.read_text(encoding="utf-8")).get("palette", {})
    problems = []
    for foreground in ("text", "subtext1", "accent"):
        if foreground in palette and "base" in palette:
            ratio = contrast(palette[foreground], palette["base"])
            if ratio < MIN_CONTRAST:
                problems.append(f"palette: {foreground} on base has contrast {ratio:.2f}, need {MIN_CONTRAST}")
    return problems


def check_site(site: Path, base_path: str, require_og_image: bool = False) -> list[str]:
    root = site.resolve()
    pages = sorted(root.rglob("*.html")) if root.is_dir() else []
    if not pages:
        return [f"no built HTML pages in {site}"]
    scans: dict[Path, Page] = {}
    errors: list[str] = []
    for html in pages:
        rel = html.relative_to(root)
        scan = Page(str(rel))
        scan.feed(html.read_text(encoding="utf-8"))
        scans[rel] = scan
        errors += scan.problems(require_og_image)
    prefix = base_path.strip("/")
    for rel, scan in scans.items():
        for line, href in scan.links:
            parsed = urlsplit(href)
            if parsed.scheme or parsed.netloc:
                continue
            if prefix and parsed.path.startswith("/") and not parsed.path.lstrip("/").startswith(prefix):
                errors.append(f"{rel}:{line}: root-absolute link is outside the base path: {href}")
                continue
            if prefix and parsed.path.startswith("/"):
                href = "/" + parsed.path.lstrip("/")[len(prefix):].lstrip("/") + (f"#{parsed.fragment}" if parsed.fragment else "")
            target, fragment = resolve(root, rel, href)
            try:
                target_rel = target.relative_to(root)
            except ValueError:
                errors.append(f"{rel}:{line}: link leaves the site: {href}")
                continue
            if not target.is_file():
                errors.append(f"{rel}:{line}: broken link {href}")
            elif fragment and target.suffix == ".html":
                other = scans.get(target_rel)
                if other is not None and fragment not in other.ids:
                    errors.append(f"{rel}:{line}: missing anchor #{fragment} in {target_rel}")
    return errors


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("site", type=Path)
    parser.add_argument("--base-path", default="")
    parser.add_argument("--palette", type=Path)
    parser.add_argument("--require-og-image", action="store_true")
    args = parser.parse_args(argv)
    problems = check_site(args.site, args.base_path, args.require_og_image)
    if args.palette:
        problems += palette_problems(args.palette)
    for problem in problems:
        print(f"docs: {problem}", file=sys.stderr)
    if problems:
        return 1
    print("documentation checks passed")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
