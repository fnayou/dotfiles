"""The README banner: title, subtitle, a terminal prompt and four numbers read from the repository."""
from svg import C, CW, Doc, num

W, H = 1670, 558

APPLE = ("M12.152 6.896c-.948 0-2.415-1.078-3.96-1.04-2.04.027-3.91 1.183-4.961 3.014-2.117 3.675-.546 "
         "9.103 1.519 12.09 1.013 1.454 2.208 3.09 3.792 3.039 1.52-.065 2.09-.987 3.935-.987 1.831 0 "
         "2.35.987 3.96.948 1.637-.026 2.676-1.48 3.676-2.948 1.156-1.688 1.636-3.325 1.662-3.415-.039-"
         ".013-3.182-1.221-3.22-4.857-.026-3.04 2.48-4.494 2.597-4.559-1.429-2.09-3.623-2.324-4.39-2.376-"
         "2-.156-3.675 1.09-4.61 1.09zM15.53 3.83c.843-1.012 1.4-2.427 1.245-3.83-1.207.052-2.662.805-3.532 "
         "1.818-.78.896-1.454 2.338-1.273 3.714 1.338.104 2.715-.688 3.559-1.701")


def sparkle(cx, cy, r, fill):
    k = r * 0.22
    d = (f"M{num(cx)},{num(cy - r)} C{num(cx + k)},{num(cy - k)} {num(cx + k)},{num(cy - k)} {num(cx + r)},{num(cy)} "
         f"C{num(cx + k)},{num(cy + k)} {num(cx + k)},{num(cy + k)} {num(cx)},{num(cy + r)} "
         f"C{num(cx - k)},{num(cy + k)} {num(cx - k)},{num(cy + k)} {num(cx - r)},{num(cy)} "
         f"C{num(cx - k)},{num(cy - k)} {num(cx - k)},{num(cy - k)} {num(cx)},{num(cy - r)}Z")
    return f'<path d="{d}" fill="{fill}"/>'


def stat(doc, x, y, anchor, number, label):
    doc.text(x, y, number, 46, C["blue"], 700, anchor)
    doc.text(x, y + 30, label, 21, C["overlay1"], 400, anchor, spacing=1)


def svg(facts):
    n_pkgs, n_tasks = len(facts["packages"]), len(facts["tasks"])
    n_adrs, version = facts["docs"]["decisions"], facts["version"]
    doc = Doc(W, H, "fnayou/dotfiles",
              f"Modular personal dotfiles for macOS, Debian and Arch: {n_pkgs} packages, {n_tasks} tasks, "
              f"{n_adrs} decision records, release {version}.")
    doc.defs.append(f'<linearGradient id="bg" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{C["mantle"]}"/>'
                    f'<stop offset="1" stop-color="{C["crust"]}"/></linearGradient>'
                    f'<linearGradient id="card" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="{C["base"]}"/>'
                    f'<stop offset="1" stop-color="{C["mantle"]}"/></linearGradient>'
                    f'<linearGradient id="edge" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="{C["lavender"]}" '
                    f'stop-opacity=".55"/><stop offset="1" stop-color="{C["mauve"]}" stop-opacity=".35"/></linearGradient>')
    # The background and the card sit outside the font group, like the original banner.
    doc.add(f'<rect width="{W}" height="{H}" fill="url(#bg)"/>')
    doc.add(f'<rect x="38" y="40" width="{W - 76}" height="{H - 82}" rx="30" fill="url(#card)" '
            f'stroke="url(#edge)" stroke-width="2"/>')
    # title row
    doc.add(f'<text x="{W // 2}" y="196" text-anchor="middle" font-size="88" font-weight="500">'
            f'<tspan fill="{C["lavender"]}">fnayou/</tspan><tspan fill="{C["blue"]}">dotfiles</tspan></text>')
    doc.line(170, 160, 392, 160, C["overlay0"], 2, ".7")
    doc.line(1314, 160, 1506, 160, C["overlay0"], 2, ".7")
    doc.add(sparkle(136, 165, 18, C["mauve"]))
    doc.add(sparkle(1538, 165, 18, C["mauve"]))
    doc.add(f'<text x="{W // 2}" y="272" text-anchor="middle" font-size="35" fill="{C["subtext0"]}">'
            f'Modular personal dotfiles for <tspan fill="{C["blue"]}">macOS</tspan>, '
            f'<tspan fill="{C["blue"]}">Debian</tspan> and <tspan fill="{C["blue"]}">Arch</tspan></text>')
    # terminal box
    tx, ty, tw, th = 430, 330, 808, 158
    px, py, fs = tx + 40, ty + 70, 44
    path_txt = "~/works/dotfiles"
    path_x = px + 70
    on_x = path_x + len(path_txt) * CW * fs + 22
    branch_x = on_x + 2 * CW * fs + 20
    doc.add(f'<rect x="{tx}" y="{ty}" width="{tw}" height="{th}" rx="16" fill="{C["mantle"]}" fill-opacity=".6" '
            f'stroke="{C["surface1"]}" stroke-width="2"/>')
    doc.add(f'<g transform="translate({px},{py - 36}) scale(1.5)" fill="{C["mauve"]}"><path d="{APPLE}"/></g>')
    doc.text(path_x, py, path_txt, fs, C["blue"])
    doc.text(on_x, py, "on", fs, C["green"])
    bx, by = branch_x, py - 36
    doc.add(f'<g stroke="{C["green"]}" stroke-width="3.4" fill="none" stroke-linecap="round">'
            f'<path d="M{num(bx + 4)},{by} V{by + 30}"/><path d="M{num(bx + 4)},{by + 12} C{num(bx + 4)},{by + 4} '
            f'{num(bx + 22)},{by + 6} {num(bx + 22)},{by + 14}"/></g>'
            f'<g fill="{C["green"]}"><circle cx="{num(bx + 22)}" cy="{by + 15}" r="4.5"/>'
            f'<circle cx="{num(bx + 4)}" cy="{by + 33}" r="4.5"/></g>')
    # The prompt always shows the default branch: the banner never advertises a feature branch.
    doc.text(bx + 36, py, "main", fs, C["green"])
    doc.text(px + 2, py + 62, "❯", fs, C["mauve"], 700)
    doc.add(f'<rect x="{px + 70}" y="{py + 26}" width="26" height="46" fill="{C["rosewater"]}">'
            f'<animate attributeName="opacity" values="1;1;0;0;1" keyTimes="0;.5;.5;.95;1" dur="1.2s" '
            f'repeatCount="indefinite"/></rect>')
    # numbers read from the repository
    stat(doc, 330, 380, "end", n_pkgs, "PACKAGES")
    stat(doc, 330, 462, "end", n_tasks, "TASKS")
    stat(doc, 1340, 380, "start", n_adrs, "DECISION RECORDS")
    stat(doc, 1340, 462, "start", version, "RELEASE")
    return doc.render()
