"""Read the project's Catppuccin Macchiato palette and compare it with Alacritty (ADR 0068)."""
import json
import tomllib
from pathlib import Path

DEFAULT_COLORS = {
    "rosewater": "#f4dbd6", "flamingo": "#f0c6c6", "pink": "#f5bde6", "mauve": "#c6a0f6",
    "red": "#ed8796", "maroon": "#ee99a0", "peach": "#f5a97f", "yellow": "#eed49f",
    "green": "#a6da95", "teal": "#8bd5ca", "sky": "#91d7e3", "sapphire": "#7dc4e4",
    "blue": "#8aadf4", "lavender": "#b7bdf8", "text": "#cad3f5", "subtext1": "#b8c0e0",
    "subtext0": "#a5adcb", "overlay2": "#939ab7", "overlay1": "#8087a2", "overlay0": "#6e738d",
    "surface2": "#5b6078", "surface1": "#494d64", "surface0": "#363a4f", "base": "#24273a",
    "mantle": "#1e2030", "crust": "#181926",
}

ROOT = Path(__file__).resolve().parents[2]
BRAND_DATA = ROOT / "brand/data/brand.json"


def colors():
    """Read the brand palette; retain the legacy table only before brand data exists."""
    if BRAND_DATA.is_file():
        return json.loads(BRAND_DATA.read_text(encoding="utf-8"))["palette"]
    return DEFAULT_COLORS


COLORS = colors()

# Alacritty theme slot -> palette name.
THEME_SLOTS = {
    ("primary", "background"): "base",
    ("primary", "foreground"): "text",
    ("cursor", "text"): "base",
    ("cursor", "cursor"): "rosewater",
    ("vi_mode_cursor", "text"): "base",
    ("vi_mode_cursor", "cursor"): "lavender",
    ("search", "matches", "foreground"): "base",
    ("search", "matches", "background"): "subtext0",
    ("search", "focused_match", "foreground"): "base",
    ("search", "focused_match", "background"): "green",
    ("footer_bar", "background"): "subtext0",
    ("footer_bar", "foreground"): "base",
    ("hints", "start", "foreground"): "base",
    ("hints", "start", "background"): "yellow",
    ("hints", "end", "foreground"): "base",
    ("hints", "end", "background"): "subtext0",
    ("selection", "text"): "base",
    ("selection", "background"): "rosewater",
    ("normal", "black"): "surface1", ("normal", "red"): "red", ("normal", "green"): "green",
    ("normal", "yellow"): "yellow", ("normal", "blue"): "blue", ("normal", "magenta"): "pink",
    ("normal", "cyan"): "teal", ("normal", "white"): "subtext1",
    ("bright", "black"): "surface2", ("bright", "red"): "red", ("bright", "green"): "green",
    ("bright", "yellow"): "yellow", ("bright", "blue"): "blue", ("bright", "magenta"): "pink",
    ("bright", "cyan"): "teal", ("bright", "white"): "subtext0",
    ("dim", "black"): "surface1", ("dim", "red"): "red", ("dim", "green"): "green",
    ("dim", "yellow"): "yellow", ("dim", "blue"): "blue", ("dim", "magenta"): "pink",
    ("dim", "cyan"): "teal", ("dim", "white"): "subtext1",
}


def check(theme_path, colors=None):
    """Return a list of problems; an empty list means the palette matches the theme."""
    colors = colors if colors is not None else globals()["colors"]()
    theme = tomllib.loads(Path(theme_path).read_text(encoding="utf-8"))["colors"]
    problems = []
    for slot, name in THEME_SLOTS.items():
        node = theme
        try:
            for part in slot:
                node = node[part]
        except KeyError:
            problems.append(f"theme slot {'.'.join(slot)} is missing")
            continue
        if node.lower() != colors[name].lower():
            problems.append(f"{'.'.join(slot)} is {node}, palette {name} is {colors[name]}")
    return problems
