"""Write an SVG and, beside it, a PNG with the same base name.

Order: validate the SVG, render the PNG from a temporary copy, and only then move both files into
place. If any step fails, the previous pair is left exactly as it was. Without `rsvg-convert` the
SVG is still written and the PNG step is skipped with a message.
"""
import os
import re
import shutil
import subprocess
import tempfile
import xml.dom.minidom
from pathlib import Path


class RenderError(Exception):
    pass


def _svg_width(markup):
    m = re.search(r'<svg[^>]*\swidth="(\d+)"', markup)
    return int(m.group(1)) if m else None


def _tmp(directory, suffix):
    fd, name = tempfile.mkstemp(prefix=".art-", suffix=suffix, dir=directory)
    os.close(fd)
    os.chmod(name, 0o644)  # tracked images are world-readable; mkstemp would create them 0600
    return Path(name)


def _rsvg(src, dst, width, height=None):
    exe = shutil.which("rsvg-convert")
    if exe is None:
        return False
    cmd = [exe, "-w", str(width)]
    if height:
        cmd += ["-h", str(height)]
    cmd += [str(src), "-o", str(dst)]
    r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode != 0:
        raise RenderError(f"rsvg-convert failed: {r.stderr.strip()}")
    return True


def write(svg_markup, svg_path, png=True, png_width=None):
    """Write `svg_path` and its PNG sibling. Returns a short status string for the report."""
    svg_path = Path(svg_path)
    directory = svg_path.parent
    directory.mkdir(parents=True, exist_ok=True)
    try:
        xml.dom.minidom.parseString(svg_markup)
    except Exception as exc:  # malformed markup must never reach the repository
        raise RenderError(f"{svg_path.name}: invalid SVG ({exc})") from exc
    tmp_svg, tmp_png = _tmp(directory, ".svg"), _tmp(directory, ".png")
    try:
        tmp_svg.write_text(svg_markup, encoding="utf-8")
        made_png = False
        if png:
            width = png_width or _svg_width(svg_markup) or 1200
            made_png = _rsvg(tmp_svg, tmp_png, width)
        previous = svg_path.read_bytes() if svg_path.exists() else None
        os.replace(tmp_svg, svg_path)
        status = f"{svg_path.name}"
        if made_png:
            try:
                os.replace(tmp_png, svg_path.with_suffix(".png"))
            except OSError:
                # keep the pair consistent: put the previous SVG back (or remove the new one)
                if previous is None:
                    svg_path.unlink()
                else:
                    svg_path.write_bytes(previous)
                raise
            status += f" + {svg_path.with_suffix('.png').name}"
        elif png:
            status += "  (PNG skipped: rsvg-convert not found)"
        return status
    finally:
        for t in (tmp_svg, tmp_png):
            if t.exists():
                t.unlink()


def write_png_from_svg(svg_markup, png_path, width, height=None):
    """Render one PNG (for example the favicon) from SVG markup, atomically."""
    png_path = Path(png_path)
    tmp_svg, tmp_png = _tmp(png_path.parent, ".svg"), _tmp(png_path.parent, ".png")
    try:
        tmp_svg.write_text(svg_markup, encoding="utf-8")
        if not _rsvg(tmp_svg, tmp_png, width, height):
            return f"{png_path.name}  (PNG skipped: rsvg-convert not found)"
        os.replace(tmp_png, png_path)
        return png_path.name
    finally:
        for t in (tmp_svg, tmp_png):
            if t.exists():
                t.unlink()
