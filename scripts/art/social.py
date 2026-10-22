"""The GitHub social preview (1280x720): the title, what the repo is, six packages and live numbers."""
import logo
from banner import APPLE
from svg import C, CW, Doc, num

W, H = 1280, 720

# Marketing copy for the packages on the card. Only names that exist in the repository are drawn.
FEATURED = [
    ("bat", "Syntax highlighting and paging.", C["mauve"]),
    ("eza", "Modern replacement for ls.", C["sapphire"]),
    ("git", "Git configuration and aliases.", C["peach"]),
    ("herdr", "Agent multiplexer and session manager.", C["green"]),
    ("omp", "Oh My Posh prompt, Macchiato segments.", C["yellow"]),
    ("zsh", "Zsh configuration, prompt and completions.", C["blue"]),
]


def svg(facts):
    names = {p["name"] for p in facts["packages"]}
    d = facts["docs"]
    doc = Doc(W, H, "fnayou/dotfiles",
              "fnayou/dotfiles: modular personal dotfiles for macOS, Debian and Arch, managed with GNU Stow.")
    doc.defs.append(f'<linearGradient id="bg" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{C["mantle"]}"/>'
                    f'<stop offset="1" stop-color="{C["crust"]}"/></linearGradient>')
    doc.add(f'<rect width="{W}" height="{H}" fill="url(#bg)"/>')

    # logo mark, scaled from the logo drawing
    k = 0.122
    doc.add(f'<g transform="translate({num(50 - 134 * k)},{num(44 - 154 * k)}) scale({k})">{logo.mark()}</g>')

    # title block
    doc.text(50, 258, "fnayou/", 52, C["lavender"], 700)
    doc.text(50 + 7 * CW * 52, 258, "dotfiles", 52, C["blue"], 700)
    doc.text(50, 306, "Modular personal dotfiles", 22, C["subtext0"])
    doc.text(50, 336, "for macOS, Debian and Arch", 22, C["subtext0"])
    doc.line(50, 360, 520, 360, C["surface1"], 1.5)
    for i, line in enumerate(["Private, safe and cross-platform dotfiles", "managed with GNU Stow. Version controlled,",
                              "manually applied, and documented."]):
        doc.text(50, 394 + i * 27, line, 17, C["subtext1"])
    feats = [("Modular", "Package-based", "and stowed", C["blue"]), ("Safe", "Deliberate, manual", "and reversible", C["green"]),
             ("Documented", "Well explained", "and reproducible", C["mauve"])]
    for i, (a, b, c, col) in enumerate(feats):
        x = 50 + i * 172
        doc.rect(x, 486, 6, 52, col, rx=3, sw=0)
        doc.text(x + 18, 503, a, 17, col, 700)
        doc.text(x + 18, 524, b, 13, C["subtext0"])
        doc.text(x + 18, 542, c, 13, C["subtext0"])
    cx = 50
    for lab, col in [("macOS", C["peach"]), ("Arch / EndeavourOS", C["sapphire"]), ("Debian", C["red"])]:
        w = len(lab) * CW * 15 + 46
        doc.rect(cx, 560, w, 30, C["base"], C["surface1"], rx=15, sw=1.3)
        doc.circle(cx + 18, 575, 5, col)
        doc.text(cx + 32, 580, lab, 15, C["text"])
        cx += w + 12

    # trunk and branches from the logo to the package rows
    rows = [p for p in FEATURED if p[0] in names]
    row_y0, row_h, tx = 232, 50, 556
    ys = [row_y0 + i * row_h + row_h // 2 for i in range(len(rows))]
    if rows:
        doc.add(f'<path d="M176,106 H{tx - 14} Q{tx},106 {tx},120 V{ys[-1] - 14} Q{tx},{ys[-1]} {tx + 14},{ys[-1]} H592" '
                f'fill="none" stroke="{C["surface2"]}" stroke-width="2"/>')
        for y in ys[:-1]:
            doc.add(f'<path d="M{tx},{y} H592" stroke="{C["surface2"]}" stroke-width="2" fill="none"/>')
        for y in ys:
            doc.circle(592, y, 5, C["blue"])

    # terminal box
    doc.rect(610, 44, 630, 124, C["mantle"], C["surface1"], rx=16)
    for i, col in enumerate((C["red"], C["yellow"], C["green"])):
        doc.circle(634 + i * 22, 68, 6, col)
    doc.add(f'<g transform="translate(634,90) scale(0.88)" fill="{C["mauve"]}"><path d="{APPLE}"/></g>')
    doc.text(668, 112, "~/works/dotfiles", 22, C["blue"])
    doc.text(668 + 16 * CW * 22 + 12, 112, "on", 22, C["green"])
    bx = 668 + 19 * CW * 22 + 12
    doc.add(f'<g stroke="{C["green"]}" stroke-width="2.2" fill="none" stroke-linecap="round">'
            f'<path d="M{num(bx)},96 V114"/><path d="M{num(bx)},103 C{num(bx)},98 {num(bx + 12)},99 {num(bx + 12)},104"/></g>')
    doc.text(bx + 22, 112, "main", 22, C["green"])
    doc.text(634, 146, "❯", 22, C["mauve"], 700)
    doc.rect(668, 130, 14, 24, C["rosewater"], rx=0, sw=0)

    # managed packages card
    doc.rect(606, 186, 634, 354, C["mantle"], C["surface1"], rx=16)
    doc.text(628, 218, "Managed packages in", 18, C["subtext1"])
    doc.text(628 + 20 * CW * 18, 218, "~/.config", 18, C["blue"])
    for i, (name, desc, col) in enumerate(rows):
        y = row_y0 + i * row_h
        if i:
            doc.line(624, y, 1222, y, C["surface0"], 1.2)
        doc.rect(634, y + 15, 20, 20, "none", col, rx=6, sw=2)
        doc.circle(644, y + 25, 3.5, col)
        doc.text(676, y + 31, name, 19, col, 700)
        doc.text(780, y + 31, desc, 17, C["subtext1"])

    # strip with numbers read from the repository
    doc.rect(26, 596, 1228, 92, C["mantle"], C["surface1"], rx=16)
    items = [("GNU Stow", f'{len(facts["packages"])} packages, manual', C["green"]),
             ("Version controlled", f'{facts["version"]}, Conventional', C["blue"]),
             ("Well documented", f'{d["guides"]} guides, {d["decisions"]} ADRs', C["mauve"]),
             ("Taskfile automation", f'{len(facts["tasks"])} tasks, dry run', C["yellow"]),
             ("Cross-platform", "macOS · Arch · Debian", C["sapphire"])]
    cw = 1228 / 5
    for i, (a, b, col) in enumerate(items):
        x = 26 + i * cw + 28
        if i:
            doc.line(26 + i * cw, 616, 26 + i * cw, 668, C["surface0"], 1.5)
        doc.rect(x, 620, 5, 44, col, rx=2.5, sw=0)
        doc.text(x + 18, 640, a, 16, col, 700)
        doc.text(x + 18, 662, b, 13.5, C["subtext0"])
    return doc.render()
