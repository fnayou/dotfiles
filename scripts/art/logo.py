"""The logo mark: a terminal prompt next to a git branch, in Catppuccin Macchiato."""
from svg import C, Doc

SIZE = 1254


def mark():
    """The rounded square with the chevron, underscore and branch nodes, in logo coordinates."""
    out = [f'<rect x="134" y="154" width="986" height="966" rx="165" fill="{C["mantle"]}" '
           f'stroke="{C["surface1"]}" stroke-width="16"/>',
           f'<path d="M318,562 L478,730 L318,898" fill="none" stroke="{C["blue"]}" stroke-width="64" '
           f'stroke-linecap="round" stroke-linejoin="round"/>',
           f'<rect x="536" y="884" width="244" height="58" rx="29" fill="{C["blue"]}"/>',
           f'<path d="M696,448 V730" stroke="{C["mauve"]}" stroke-width="20" stroke-linecap="round" fill="none"/>',
           f'<path d="M696,660 C696,606 740,576 800,576 L900,576" stroke="{C["mauve"]}" stroke-width="20" '
           f'stroke-linecap="round" fill="none"/>']
    for cx, cy, fill in ((696, 384, C["blue"]), (946, 576, C["blue"]), (696, 734, C["mauve"])):
        out.append(f'<circle cx="{cx}" cy="{cy}" r="72" fill="{C["surface0"]}" stroke="{C["surface1"]}" '
                   f'stroke-width="10"/>')
        out.append(f'<circle cx="{cx}" cy="{cy}" r="52" fill="{fill}"/>')
    return "\n".join(out)


def svg():
    doc = Doc(SIZE, SIZE, "fnayou/dotfiles", "Logo of fnayou/dotfiles: a terminal prompt and a git branch.",
              body_font=False)
    doc.add(f'<rect width="{SIZE}" height="{SIZE}" fill="{C["crust"]}"/>')
    doc.add(mark())
    return doc.render()
