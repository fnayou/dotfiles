"""Small helpers shared by the generators: fonts, text width, escaping, a minimal document builder."""
import re
from html import escape

import palette

C = palette.COLORS
# GitHub renders an SVG image with the viewer's fonts: list the ones with a 0.6 em advance first.
FONT = "'JetBrains Mono','JetBrainsMono Nerd Font','SF Mono',Menlo,Consolas,'DejaVu Sans Mono',monospace"
CW = 0.6  # monospace advance, in em


def esc(value):
    return escape(str(value))


def text_width(s, size, pad=0):
    return len(s) * CW * size + pad


def num(v):
    """Fixed number formatting, so the same drawing always prints the same bytes."""
    return f"{v:.1f}".rstrip("0").rstrip(".") if isinstance(v, float) else str(v)


_LONG = re.compile(r"(?<![0-9A-Za-z#.])(-?\d+\.\d{3,})")


def tidy(markup):
    """Round the long fractions left by coordinate arithmetic, so the markup is short and stable."""
    return _LONG.sub(lambda m: num(round(float(m.group(1)), 2)), markup)


class Doc:
    """An SVG document: collects elements, prints the final string."""

    def __init__(self, width, height, title, desc, body_font=True):
        self.width, self.height = width, height
        self.title, self.desc = title, desc
        self.defs = []
        self.parts = []
        self.body_font = body_font

    def add(self, markup):
        self.parts.append(markup)

    def text(self, x, y, s, size=18, fill=None, weight=400, anchor="start", spacing=None):
        extra = f' letter-spacing="{spacing}"' if spacing else ""
        self.add(f'<text x="{num(x)}" y="{num(y)}" font-size="{num(size)}" font-weight="{weight}" '
                 f'fill="{fill or C["text"]}" text-anchor="{anchor}"{extra}>{esc(s)}</text>')

    def rect(self, x, y, w, h, fill, stroke=None, rx=12, sw=1.5, dash=None):
        s = f' stroke="{stroke}" stroke-width="{num(sw)}"' if stroke else ""
        s += f' stroke-dasharray="{dash}"' if dash else ""
        self.add(f'<rect x="{num(x)}" y="{num(y)}" width="{num(w)}" height="{num(h)}" rx="{num(rx)}" '
                 f'fill="{fill}"{s}/>')

    def circle(self, cx, cy, r, fill="none", stroke=None, sw=2):
        s = f' stroke="{stroke}" stroke-width="{num(sw)}"' if stroke else ""
        self.add(f'<circle cx="{num(cx)}" cy="{num(cy)}" r="{num(r)}" fill="{fill}"{s}/>')

    def line(self, x1, y1, x2, y2, stroke, sw=2, opacity=None):
        o = f' opacity="{opacity}"' if opacity is not None else ""
        self.add(f'<line x1="{num(x1)}" y1="{num(y1)}" x2="{num(x2)}" y2="{num(y2)}" stroke="{stroke}" '
                 f'stroke-width="{num(sw)}"{o}/>')

    def render(self):
        head = (f'<svg xmlns="http://www.w3.org/2000/svg" width="{self.width}" height="{self.height}" '
                f'viewBox="0 0 {self.width} {self.height}" role="img" aria-labelledby="t d">'
                f'<title id="t">{esc(self.title)}</title><desc id="d">{esc(self.desc)}</desc>')
        defs = f'<defs>{"".join(self.defs)}</defs>' if self.defs else ""
        body = "\n".join(self.parts)
        wrap = f'<g font-family="{FONT}">\n{body}\n</g>' if self.body_font else body
        return tidy(f"{head}{defs}\n{wrap}\n</svg>\n")
