"""The architecture diagram: one technical picture of the repository, generated from its facts.

Every number, package, destination, task group, zsh layer and CI step comes from `facts.py`, so a new
package, task or workflow step shows up on the next run. Only the grouping of packages into families
is described here, and an unknown package lands in an "Other" slot. The header carries no commit
hash, branch or date, so two runs on one checkout are byte-identical.
"""
from html import escape

from svg import C, CW, FONT, tidy

FAMILIES = [  # description only; a package that is not listed lands in "Other"
    ("Terminal and shell", C["sapphire"], ["alacritty", "ghostty", "terminal", "zsh", "omp", "herdr"]),
    ("Editor and CLI tools", C["green"], ["nvim", "bat", "eza", "btop", "git"]),
    ("AI agents", C["mauve"], ["claude", "codex"]),
]


# ----------------------------------------------------------------------------- drawing

out = []


def w_of(text, size, pad=0):
    return len(text) * CW * size + pad


def text(x, y, s, size=18, fill=None, weight=400, anchor="start", spacing=None, opacity=None):
    extra = f' letter-spacing="{spacing}"' if spacing else ""
    extra += f' opacity="{opacity}"' if opacity else ""
    out.append(f'<text x="{x:.1f}" y="{y:.1f}" font-size="{size}" font-weight="{weight}" '
               f'fill="{fill or C["text"]}" text-anchor="{anchor}"{extra}>{escape(str(s))}</text>')


def rect(x, y, w, h, fill, stroke=None, r=12, sw=1.5, opacity=None, dash=None):
    s = f' stroke="{stroke}" stroke-width="{sw}"' if stroke else ""
    s += f' stroke-dasharray="{dash}"' if dash else ""
    s += f' fill-opacity="{opacity}"' if opacity is not None else ""
    out.append(f'<rect x="{x:.1f}" y="{y:.1f}" width="{w:.1f}" height="{h:.1f}" rx="{r}" fill="{fill}"{s}/>')


def band(x, y, w, h, title, sub, accent):
    rect(x, y, w, h, C["mantle"], C["surface1"], r=18, sw=1.5)
    rect(x, y, 9, h, accent, None, r=4)
    text(x + 32, y + 40, title, 25, accent, 700, spacing=2)
    text(x + 32 + w_of(title, 25) + 28, y + 40, sub, 18, C["overlay1"])


def chip(x, y, s, size=17, fill=None, stroke=None, color=None, h=None, pad=18, weight=400):
    h = h or size + 16
    w = w_of(s, size, pad * 2)
    rect(x, y, w, h, fill or C["surface0"], stroke or C["surface1"], r=h / 2.6, sw=1.3)
    text(x + pad, y + h / 2 + size * 0.34, s, size, color or C["text"], weight)
    return w


def chips_flow(x, y, items, maxw, size=17, gap=10, rowgap=10, **kw):
    cx, cy = x, y
    h = kw.get("h") or size + 16
    for it in items:
        s, extra = (it if isinstance(it, tuple) else (it, {}))
        w = w_of(s, size, kw.get("pad", 18) * 2)
        if cx + w > x + maxw:
            cx, cy = x, cy + h + rowgap
        args = {**kw, **extra}
        chip(cx, cy, s, size, **args)
        cx += w + gap
    return cy + h


def arrow(x1, y1, x2, y2, color=None, label=None, dash=None, lx=None, ly=None, sw=2.4, anchor="start"):
    color = color or C["overlay1"]
    d = f' stroke-dasharray="{dash}"' if dash else ""
    out.append(f'<path d="M{x1},{y1} L{x2},{y2}" stroke="{color}" stroke-width="{sw}" fill="none"{d} marker-end="url(#ah)"/>')
    if label:
        text(lx if lx is not None else x1 + 14, ly if ly is not None else (y1 + y2) / 2 + 6, label, 16, color,
             anchor=anchor)


def elbow(points, color=None, label=None, lx=0, ly=0, dash=None, anchor="start"):
    color = color or C["overlay1"]
    d = "M" + " L".join(f"{px},{py}" for px, py in points)
    da = f' stroke-dasharray="{dash}"' if dash else ""
    out.append(f'<path d="{d}" stroke="{color}" stroke-width="2.4" fill="none"{da} stroke-linejoin="round" marker-end="url(#ah)"/>')
    if label:
        text(lx, ly, label, 16, color, anchor=anchor)


def card(x, y, w, h, p, accent):
    rect(x, y, w, h, C["base"], C["surface1"], r=12)
    rect(x, y, 6, h, accent, None, r=3)
    text(x + 22, y + 30, p["name"], 21, C["text"], 700)
    if p["palette"]:
        out.append(f'<circle cx="{x + w - 24}" cy="{y + 25}" r="7" fill="{C["blue"]}"/>')
    else:
        out.append(f'<circle cx="{x + w - 24}" cy="{y + 25}" r="7" fill="none" stroke="{C["overlay0"]}" stroke-width="2"/>')
    dest = ", ".join(p["dests"]) if p["dests"] else "(nothing is linked)"
    text(x + 22, y + 56, dest, 16, C["subtext0"])
    if p["unlinked"]:
        names = ", ".join(p["unlinked"])
        tag = "not linked: " + names
        if w_of(tag, 15) > w - 40:
            tag = f'{len(p["unlinked"])} file(s) not linked'
        text(x + 22, y + 78, tag, 15, C["peach"])


def insert_band(idx, x, y, w, h, title, sub, accent):
    global out
    saved, out = out, []
    band(x, y, w, h, title, sub, accent)
    block, out = out, saved
    out[idx:idx] = block


def svg(f):
    global out
    out = []
    W = 2400
    pkgs = f["packages"]
    common = [p for p in pkgs if p["area"] == "common"]
    macos = [p for p in pkgs if p["area"] == "macos"]
    d = f["docs"]
    X, BW = 40, 2320
    gap = 56
    bands = []  # (y, h) for the arrows between bands

    # ---- header
    text(60, 78, "fnayou/", 52, C["lavender"], 500)
    text(60 + w_of("fnayou/", 52), 78, "dotfiles", 52, C["blue"], 500)
    text(60 + w_of("fnayou/dotfiles", 52) + 28, 78, "system architecture, generated from the repository", 24, C["subtext0"])
    text(60, 114, f'release {f["version"]} · {len(common)} common + {len(macos)} macOS packages · '
         f'{len(f["tasks"])} tasks · {len(f["scripts"])} scripts · {d["decisions"]} ADRs', 19, C["overlay1"])
    lx = W - 700
    out.append(f'<circle cx="{lx}" cy="46" r="7" fill="{C["blue"]}"/>')
    text(lx + 18, 52, "package files carry the Macchiato palette", 16.5, C["subtext0"])
    out.append(f'<circle cx="{lx}" cy="76" r="7" fill="none" stroke="{C["overlay0"]}" stroke-width="2"/>')
    text(lx + 18, 82, "no colours of its own, inherits the terminal", 16.5, C["subtext0"])
    text(lx, 112, "orange text", 16.5, C["peach"], 700)
    text(lx + 118, 112, "= file kept out of Stow", 16.5, C["subtext0"])
    out.append(f'<path d="M{lx},136 L{lx + 50},136" stroke="{C["overlay1"]}" stroke-width="2.4" stroke-dasharray="7 5" marker-end="url(#ah)"/>')
    text(lx + 66, 142, "= manual step, you run it", 16.5, C["subtext0"])

    # ============================================================ 1. governance
    y1 = 176
    i1 = len(out)
    flow = [("PRD", d["prd"], C["blue"]), ("Architecture", d["architecture"], C["sapphire"]),
            ("Plan", d["plans"], C["teal"]), ("Review", None, C["yellow"]), ("Build", None, C["peach"]),
            ("Review", d["reviews"], C["yellow"]), ("Commit + PR", None, C["green"])]
    cx = X + 40
    for i, (name, n, col) in enumerate(flow):
        label = name + (f"  ×{n}" if n is not None else "")
        w = chip(cx, y1 + 78, label, 21, fill=C["base"], stroke=col, color=col, h=48, pad=22, weight=700)
        if i < len(flow) - 1:
            arrow(cx + w + 4, y1 + 102, cx + w + 30, y1 + 102, col, sw=2.6)
        cx += w + 36
    text(X + 44, y1 + 168, "docs/prd · docs/architecture · docs/plans · docs/reviews · docs/decisions (ADR) · "
         f'docs/guides ({d["guides"]})', 17, C["overlay1"])
    text(X + 44, y1 + 198, "Draft → Approved → Complete. Only you move a document to Approved.", 17, C["subtext0"])
    text(X + 44, y1 + 226, "status-sync rule: the status blocks in AGENTS.md and CLAUDE.md change in the same commit as a package.", 17, C["subtext0"])
    ax = 1520
    text(ax, y1 + 78, ".claude/", 19, C["mauve"], 700)
    b1 = chips_flow(ax + 110, y1 + 54, [(a, {"color": C["mauve"]}) for a in f["agents"]], 740, 16, fill=C["base"], stroke=C["mauve"])
    text(ax, b1 + 40, "rules", 17, C["overlay1"])
    b2 = chips_flow(ax + 110, b1 + 16, [(r, {}) for r in f["rules"]], 740, 16)
    text(ax, b2 + 40, "skills", 17, C["overlay1"])
    b3 = chips_flow(ax + 110, b2 + 16, [(s, {}) for s in f["skills"]], 740, 16)
    h1 = max(b3 - y1, 250) + 30
    insert_band(i1, X, y1, BW, h1, "1  GOVERNANCE", "PRD first, every gate needs your explicit approval, agents propose and never approve", C["lavender"])
    bands.append((y1, h1))

    # ============================================================ 2. source of truth
    y2 = y1 + h1 + gap
    i2 = len(out)
    px0 = X + 40
    text(px0, y2 + 84, "stow/common", 22, C["text"], 700)
    text(px0 + 170, y2 + 84, "same on macOS, Arch and Debian", 17, C["overlay1"])
    fam_x = [px0, px0 + 372, px0 + 744]
    cols = []
    for title, col, names in FAMILIES:
        cols.append((title, col, [p for n in names for p in common if p["name"] == n and p["area"] == "common"]))
    rest = [p for p in common if not any(p in c[2] for c in cols)]
    if rest:
        cols.append(("Other", C["overlay1"], rest))
    bot2 = y2 + 140
    other = cols[3][2] if len(cols) > 3 else []
    for ci_, (title, col, plist) in enumerate(cols[:3]):
        x = fam_x[ci_]
        text(x, y2 + 124, title.upper(), 16, col, 700, spacing=1.5)
        for i, p in enumerate(plist):
            card(x, y2 + 140 + i * 100, 352, 90, p, col)
        bot2 = max(bot2, y2 + 140 + len(plist) * 100)
    # a package that belongs to no family still shows up, under the AI column
    ai_count = len(cols[2][2]) if len(cols) > 2 else 0
    label_gap = 34 if other else 0
    if other:
        text(fam_x[2], y2 + 140 + ai_count * 100 + 20, "OTHER", 16, C["overlay1"], 700, spacing=1.5)
    for j, p in enumerate(other):
        card(fam_x[2], y2 + 140 + ai_count * 100 + label_gap + j * 100, 352, 90, p, C["overlay1"])
    ai_n = ai_count + len(other)
    pal_y = y2 + 140 + ai_n * 100 + label_gap + 10
    rect(fam_x[2], pal_y, 352, 150, C["base"], C["blue"], r=12, dash="6 5")
    text(fam_x[2] + 20, pal_y + 32, "Palette source of truth", 18, C["blue"], 700)
    text(fam_x[2] + 20, pal_y + 60, "alacritty/catppuccin-macchiato.toml", 15, C["subtext0"])
    text(fam_x[2] + 20, pal_y + 84, "→ ghostty theme (same hex)", 15, C["subtext0"])
    text(fam_x[2] + 20, pal_y + 106, "→ Terminal.app profile (--build)", 15, C["subtext0"])
    text(fam_x[2] + 20, pal_y + 130, "blue accent #8aadf4", 15, C["blue"])
    bot2 = max(bot2, pal_y + 150)
    # macOS
    mx = px0 + 1136
    text(mx, y2 + 84, "stow/macos", 22, C["text"], 700)
    text(mx + 160, y2 + 84, "macOS only", 17, C["overlay1"])
    for i, p in enumerate(macos):
        card(mx, y2 + 140 + i * 100, 352, 90, p, C["peach"])
    ay = y2 + 140 + len(macos) * 100 + 8
    text(mx, ay + 26, "stow/arch · stow/debian", 18, C["subtext0"], 700)
    text(mx, ay + 52, "empty on purpose, nothing platform-", 16, C["overlay1"])
    text(mx, ay + 74, "specific is needed there yet", 16, C["overlay1"])
    bot2 = max(bot2, ay + 80)
    # right column
    rx = 1590
    rw = X + BW - 40 - rx
    text(rx, y2 + 84, "packages/", 22, C["text"], 700)
    text(rx + 140, y2 + 84, "what to install, per platform", 17, C["overlay1"])
    yy = y2 + 112
    for lab, n, col in (("Brewfile", f["brew"], C["peach"]), ("arch/packages.txt", f["arch_pkgs"], C["sapphire"]),
                        ("debian/packages.txt", f["debian_pkgs"], C["red"])):
        chip(rx, yy, f"{lab}  ·  {n} packages", 17, fill=C["base"], stroke=col, color=col)
        yy += 42
    text(rx, yy + 28, "scripts/", 22, C["text"], 700)
    text(rx + 120, yy + 28, f'{len(f["scripts"])} bash scripts, each header documents its modes', 17, C["overlay1"])
    yy = chips_flow(rx, yy + 46, [(s.replace(".sh", ""), {}) for s in f["scripts"]], rw, 15, gap=8, rowgap=8, pad=12) + 26
    text(rx, yy + 26, "Taskfile.yml", 22, C["text"], 700)
    text(rx + 170, yy + 26, f'{len(f["tasks"])} tasks, the only entry point', 17, C["overlay1"])
    tg = [(f"{g}" + (f" ×{len(v)}" if len(v) > 1 else ""), {}) for g, v in sorted(f["task_groups"].items(), key=lambda kv: (-len(kv[1]), kv[0]))]
    bot2 = max(bot2, chips_flow(rx, yy + 44, tg, rw, 15, gap=8, rowgap=8, pad=12))
    h2 = bot2 - y2 + 34
    insert_band(i2, X, y2, BW, h2, "2  SOURCE OF TRUTH", "this repository: every config, script and list lives here, nothing is generated on the machine", C["blue"])
    bands.append((y2, h2))

    # ============================================================ 3. deployment
    y3 = y2 + h2 + gap
    i3 = len(out)
    h3 = 310
    lanes = [
        ("Stow  ·  symlinks", C["green"], [
            "stow --simulate  <package>", "review the LINK lines, stop on conflict", "stow --no-folding  <package>",
            "never `stow .`, never --adopt"]),
        ("Task sync  ·  merge or import", C["yellow"], [
            "task codex:sync      (dry run)", "task terminal:sync   (dry run)", "ARGS='--apply'  →  backup, then write",
            "for the files Stow ignores"]),
        ("Provision  ·  install", C["sapphire"], [
            "task deps:brew · deps:arch · deps:debian", "task zsh:bootstrap · git:bootstrap", "each has a dry-run twin",
            "OS detected, never assumed"]),
        ("Verify  ·  read only", C["lavender"], [
            "task doctor", "task check · check:decisions", "task dry-run · detect", "CI runs the same checks"]),
    ]
    lw = (BW - 80 - 3 * 24) / 4
    for i, (title, col, lines) in enumerate(lanes):
        x = X + 40 + i * (lw + 24)
        rect(x, y3 + 66, lw, 220, C["base"], col, r=14)
        text(x + 20, y3 + 100, title, 20, col, 700)
        for j, ln in enumerate(lines):
            text(x + 20, y3 + 140 + j * 34, ln, 16.5, C["subtext1"] if j < 3 else C["overlay1"])
    insert_band(i3, X, y3, BW, h3, "3  DEPLOYMENT", "always manual, always a dry run first, never from a script", C["peach"])
    bands.append((y3, h3))

    # ============================================================ 4. machine
    y4 = y3 + h3 + gap
    i4 = len(out)
    text(X + 40, y4 + 84, "Platforms", 22, C["text"], 700)
    plats = [("macOS", "primary", "brew", f'Brewfile {f["brew"]}', C["peach"]),
             ("EndeavourOS / Arch", "also used", "pacman · yay", f'{f["arch_pkgs"]} packages', C["sapphire"]),
             ("Debian 13 trixie", "all servers", "apt", f'{f["debian_pkgs"]} packages', C["red"])]
    for i, (n, sub, pm, cnt, col) in enumerate(plats):
        y = y4 + 108 + i * 118
        rect(X + 40, y, 360, 102, C["base"], col, r=14)
        text(X + 62, y + 36, n, 21, col, 700)
        text(X + 62, y + 64, sub, 16, C["overlay1"])
        text(X + 62, y + 88, f"{pm} · {cnt}", 16, C["subtext0"])
    text(X + 40, y4 + 478, "scripts/detect-os.sh", 17, C["subtext0"], 700)
    text(X + 40, y4 + 504, "arch is tested before debian", 16, C["overlay1"])
    text(X + 40, y4 + 528, "Homebrew is never assumed", 16, C["overlay1"])
    bot4 = y4 + 540

    hx = X + 470
    text(hx, y4 + 84, "$HOME  (symlinks into the repo)", 22, C["text"], 700)
    seen = {}
    for p in common + macos:
        for dd in p["dests"]:
            seen.setdefault(dd, []).append(p["name"] + (" (macOS)" if p["area"] == "macos" else ""))
    lines = [(dd, "← " + " + ".join(names)) for dd, names in sorted(seen.items())]
    unl = [(p["name"], ", ".join(p["unlinked"])) for p in common + macos if p["unlinked"]]
    box_h = 40 + len(lines) * 31 + (60 + len(unl) * 28 if unl else 0)
    rect(hx, y4 + 100, 560, box_h, C["base"], C["surface1"], r=14)
    yy = y4 + 140
    for dd, rhs in lines:
        text(hx + 24, yy, dd, 18, C["green"], 700)
        text(hx + 24 + w_of(dd, 18) + 14, yy, rhs, 16, C["subtext0"])
        yy += 31
    if unl:
        yy += 18
        text(hx + 24, yy, "regular files, Stow ignores them:", 16, C["overlay1"])
        yy += 28
        for name, files in unl:
            t = f"{name}: {files}"
            if w_of(t, 16) > 510:
                t = f"{name}: {len(files.split(','))} file(s)"
            text(hx + 24, yy, t, 16, C["peach"])
            yy += 28
    bot4 = max(bot4, y4 + 100 + box_h)

    tx = hx + 620
    text(tx, y4 + 84, "Runtime", 22, C["text"], 700)
    steps = [("Terminal", "Alacritty · Ghostty · Terminal.app", C["sapphire"]),
             ("zsh -l", "login shell: ~/.zprofile (brew), then ~/.zshrc", C["green"]),
             ("~/.zshrc  →  index.zsh", "one guarded include, owns the source order", C["blue"])]
    yy = y4 + 108
    for i, (a, b, col) in enumerate(steps):
        rect(tx, yy, 520, 68, C["base"], col, r=12)
        text(tx + 20, yy + 30, a, 19, col, 700)
        text(tx + 20, yy + 55, b, 15.5, C["subtext0"])
        if i < len(steps) - 1:
            arrow(tx + 260, yy + 70, tx + 260, yy + 90, col)
        yy += 92
    text(tx, yy + 22, "layers, in source order", 17, C["overlay1"])
    lay = [(f"{i + 1} {n}", {"color": C["lavender"] if n in ("plugins", "prompt", "tools", "local") else C["text"]})
           for i, n in enumerate(f["zsh_layers"])]
    ye = chips_flow(tx, yy + 38, lay, 520, 15, gap=7, rowgap=7, pad=11)
    text(tx, ye + 30, "prompt Oh My Posh · jump zoxide", 15, C["overlay1"])
    text(tx, ye + 52, "fuzzy fzf + fzf-tab · plugins zinit", 15, C["overlay1"])
    text(tx, ye + 74, "local.zsh is git-ignored, loaded last, wins", 15, C["overlay1"])
    bot4 = max(bot4, ye + 84)

    ux = tx + 600
    text(ux, y4 + 84, "Tools", 22, C["text"], 700)
    tl = [("herdr", "agent multiplexer", C["mauve"]), ("nvim", "kickstart + catppuccin", C["green"]),
          ("bat · eza · btop", "pager, ls, monitor", C["green"]), ("git", "config + aliases", C["green"]),
          ("claude", "statusline, agents, rules", C["mauve"]), ("codex", "theme + synced config", C["mauve"])]
    for i, (n, sub, col) in enumerate(tl):
        y = y4 + 108 + i * 78
        rect(ux, y, 340, 66, C["base"], col, r=12)
        text(ux + 18, y + 28, n, 19, col, 700)
        text(ux + 18, y + 52, sub, 15.5, C["subtext0"])
    text(ux, y4 + 108 + 6 * 78 + 24, "every tool reads the Macchiato theme", 15.5, C["blue"])
    text(ux, y4 + 108 + 6 * 78 + 46, "from its own config file", 15.5, C["blue"])
    bot4 = max(bot4, y4 + 108 + 6 * 78 + 52)
    h4 = bot4 - y4 + 34
    insert_band(i4, X, y4, BW, h4, "4  THE MACHINE", "what you get after deployment", C["green"])
    bands.append((y4, h4))

    # ============================================================ 5. delivery
    y5 = y4 + h4 + gap
    i5 = len(out)
    chain = [("branch", C["lavender"]), ("pull request", C["lavender"]), ("CI  ci.yml", C["yellow"]),
             ("merge to main", C["green"]), ("docs.yml", C["blue"]), ("zensical build --strict", C["blue"]),
             ("GitHub Pages", C["blue"])]
    cx = X + 40
    for i, (n, col) in enumerate(chain):
        w = chip(cx, y5 + 66, n, 19, fill=C["base"], stroke=col, color=col, h=46, pad=18, weight=700)
        if i < len(chain) - 1:
            arrow(cx + w + 4, y5 + 89, cx + w + 26, y5 + 89, col)
        cx += w + 32
    text(X + 40, y5 + 156, "Repository Hygiene:", 16.5, C["yellow"], 700)
    ye = chips_flow(X + 40 + w_of("Repository Hygiene:", 16.5) + 16, y5 + 132, [(s, {}) for s in f["ci_steps"]], 1900, 14, gap=7, rowgap=8, pad=11)
    text(X + 40, ye + 40, f'git-cliff → CHANGELOG.md from Conventional Commits · CalVer tags (latest {f["version"]}) · '
         "Conventional Commits also name every PR title", 16.5, C["subtext0"])
    h5 = ye + 40 - y5 + 30
    insert_band(i5, X, y5, BW, h5, "5  DELIVERY", "GitHub, one pull request per change, rebase merge", C["mauve"])
    bands.append((y5, h5))

    # ============================================================ arrows between bands
    labels = [("approved plan, then the Builder edits", 300, C["lavender"], None),
              ("you run each step", 1000, C["peach"], "8 6"),
              ("symlinks, writes, installs", 1900, C["green"], "8 6")]
    for k, (lab, ax_, col, dash) in enumerate(labels):
        yb = bands[k][0] + bands[k][1]
        yn = bands[k + 1][0]
        elbow([(ax_, yb + 2), (ax_, yn - 3)], col, lab, ax_ + 16, yb + 34, dash=dash)
    yb = bands[3][0] + bands[3][1]
    elbow([(1200, yb + 2), (1200, bands[4][0] - 3)], C["mauve"], "git, one change at a time", 1216, yb + 34)

    H = bands[-1][0] + bands[-1][1] + 40
    head = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}" role="img" '
            f'aria-labelledby="t d">',
            '<title id="t">dotfiles: system architecture</title>',
            f'<desc id="d">Generated from the repository: {len(common)} common and {len(macos)} macOS packages, '
            f'{len(f["tasks"])} tasks, {d["decisions"]} decision records.</desc>',
            f'<defs><marker id="ah" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="8" markerHeight="8" '
            f'orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="{C["overlay1"]}"/></marker>'
            f'<linearGradient id="bg" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{C["mantle"]}"/>'
            f'<stop offset="1" stop-color="{C["crust"]}"/></linearGradient></defs>',
            f'<rect width="{W}" height="{H}" fill="url(#bg)"/>', f'<g font-family="{FONT}">']
    return tidy("\n".join(head + out + ["</g></svg>"]) + "\n")
