"""The qustah icon sheet: filled icons drawn pixel for pixel, with no grey edges, at the sizes the lib uses.

    python3 tools/gen_filled_sheet.py --iconify PATH/icon-sets/json [--review DIR]

Reads tools/qustah_icons.json (lucide name -> "solar:NAME" (Solar Bold) or "mdi:NAME") and tools/qustah_picks.json
(choices by eye), draws every icon at every size in SIZES and writes:
    ../qustah/icons/qustah-vN-K.png   the pages (1024 px wide, white icons on transparent)
    src/icons_qustah.lua              where each icon is (Names, Sizes = { [size] = { page, y, columns } })
With --review, also contact sheets (every icon at every size, and the candidates for the small sizes) to look at.

How an icon is drawn at s px (no grey: every pixel is on or off):
    the vector is drawn big (768 px), then placed at s px many ways - moved by 1/8 px steps, shrunk to 88-100 %,
    and (for some candidates) thinned by up to 3/8 px so inner gaps stay a full pixel - and each pixel is on when
    at least half of it is covered. The way picked is the one with the fewest half-covered pixels that still has
    the icon's parts and holes (and, where the candidate asks, its mirror symmetry).
Candidates (picks.json can choose one per icon and size, e.g. "eye@20": "C"):
    A  no thinning, symmetry ignored          (most icons)
    B  thinning allowed (inner gaps kept)     (grids, lists, server)
    C  thinning allowed, symmetry kept        (round details: an eye's pupil)
    D  thinning allowed, symmetry as a tie-break
Without a pick: the first of A, B, D, C that keeps the parts and holes (and leaves a symmetric icon nearly
symmetric); failing that, the first that keeps the parts and holes; failing that, C.
picks.json "edits" fix single pixels by hand: { "server@14": ["3,2=1", "4,2=0"] } (x,y from the top left).
tools/qustah_drawn.json holds icons drawn by hand: { "save": { "14": ["..##..", ...], "16": [...] } } replaces the drawn
sizes outright. Sizes not drawn are made from the drawing (twice a drawn size: doubled; otherwise fitted from the biggest
drawing), so a hand-drawn icon looks the same at every UI scale. "vector": [20, 24] keeps those sizes on the mapped
vector instead (server: the card is drawn after the dock's 20 px icon, which stays the vector fit).
"""
import argparse, io, json, os, sys
import numpy as np
from PIL import Image, ImageDraw, ImageFont
from scipy import ndimage

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
SIZES = [14, 16, 20, 24, 28, 30]
PAGE = 1024
SRC = 768
Q = 8
SCALES = [1.0, 0.96, 0.92, 0.88]
OFFS = np.arange(-0.5, 0.5, 1 / 8)
EIGHT = np.ones((3, 3), bool)
# candidate -> (weight of a lost part / hole, weight of a pixel breaking a mirror symmetry, thinning allowed)
CANDIDATES = {"A": (6, 0.0, False), "B": (6, 0.0, True), "C": (20, 0.4, True), "D": (6, 0.08, True)}


# ------------------------------------------------------------------ sources
def load_sets(folder):
    sets = {}
    for name in ("solar", "mdi"):
        with open(os.path.join(folder, name + ".json")) as f:
            sets[name] = json.load(f)
    return sets


def svg_of(sets, ref):
    """the SVG of "solar:eye" (its bold version) or "mdi:sword"; aliases are followed"""
    set_name, name = ref.split(":")
    data = sets[set_name]
    if set_name == "solar":
        name += "-bold"
    seen = 0
    while name not in data["icons"] and name in data.get("aliases", {}) and seen < 5:
        name = data["aliases"][name]["parent"]
        seen += 1
    icon = data["icons"][name]
    w = icon.get("width", data.get("width", 24))
    h = icon.get("height", data.get("height", 24))
    body = icon["body"].replace("currentColor", "#fff")
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{SRC}" height="{SRC}" viewBox="0 0 {w} {h}">{body}</svg>'


def render_all(svgs):
    """name -> 768 px alpha image (Chromium draws the SVGs)"""
    from playwright.sync_api import sync_playwright
    out = {}
    with sync_playwright() as p:
        exe = os.environ.get("CHROME")
        b = p.chromium.launch(**({"executable_path": exe} if exe else {}), args=["--no-sandbox"])
        page = b.new_page(device_scale_factor=1)
        for name, svg in svgs.items():
            page.set_content(f'<html><body style="margin:0">{svg.replace("<svg ", "<svg style=\'display:block\' ", 1)}</body></html>')
            png = page.locator("svg").screenshot(omit_background=True)
            out[name] = Image.open(io.BytesIO(png)).getchannel("A")
        b.close()
    return out


# ------------------------------------------------------------------ drawing
def place(src, s, k, dx, dy):
    hi = s * Q
    f = SRC / (s * k * Q)
    ox = (s * (1 - k) / 2 + dx) * Q
    oy = (s * (1 - k) / 2 + dy) * Q
    img = src.transform((hi, hi), Image.AFFINE, (f, 0, -ox * f, 0, f, -oy * f), resample=Image.BILINEAR)
    return np.asarray(img, dtype=np.float32) / 255


def cover(a, s):
    return a.reshape(s, Q, s, Q).mean(axis=(1, 3))


def topology(mask):
    parts = ndimage.label(mask, structure=EIGHT)[1]
    bg, n = ndimage.label(~mask)
    edge = set(np.unique(np.concatenate([bg[0], bg[-1], bg[:, 0], bg[:, -1]])))
    return parts, len([i for i in range(1, n + 1) if i not in edge])


def draw_candidates(src, s):
    """every candidate's pixels for one icon at s px: {"A": (pixels, keeps parts/holes, asymmetric pixels), ...}"""
    truth = place(src, s, 1.0, 0, 0) > 0.5
    want = topology(truth)
    lr = (truth == truth[:, ::-1]).mean() > 0.985
    ud = (truth == truth[::-1, :]).mean() > 0.985
    best = {}
    for k in SCALES:
        for dx in OFFS:
            for dy in OFFS:
                a = place(src, s, k, dx, dy)
                m0 = a > 0.5
                for e in (0, 1, 2, 3):
                    if e:
                        m = ndimage.binary_erosion(m0, iterations=e)
                        c = cover(m.astype(np.float32), s)
                    else:
                        c = cover(a, s)
                    b = c >= 0.5
                    got = topology(b)
                    lost = abs(got[0] - want[0]) + abs(got[1] - want[1])
                    asym = (int((b != b[:, ::-1]).sum()) if lr else 0) + (int((b != b[::-1, :]).sum()) if ud else 0)
                    grain = float(np.minimum(c, 1 - c).sum())
                    for key, (wt, ws, thin) in CANDIDATES.items():
                        if e and not thin:
                            continue
                        cost = grain + wt * lost + ws * asym + 1.5 * e + 40 * (1 - k)
                        if key not in best or cost < best[key][0]:
                            best[key] = (cost, b, lost == 0, asym)
    return {key: (v[1], v[2], v[3]) for key, v in best.items()}, (lr or ud)


def choose(cands, symmetric, pick):
    if pick in cands:
        return pick
    order = "ABDC"
    # the first that keeps the parts and holes (and a symmetric icon nearly symmetric), else the first that keeps them
    for key in order:
        keeps, asym = cands[key][1], cands[key][2]
        if keeps and (not symmetric or asym <= 2):
            return key
    for key in order:
        if cands[key][1]:
            return key
    return "C"


def load_drawn():
    """name -> size -> pixels, from tools/qustah_drawn.json"""
    path = os.path.join(HERE, "qustah_drawn.json")
    if not os.path.exists(path):
        return {}
    drawn = {}
    for name, sizes in json.load(open(path)).items():
        if name.startswith("_"):
            continue
        drawn[name] = {}
        vector = set(sizes.pop("vector", []))
        for size, rows in sizes.items():
            b = np.array([[c == "#" for c in row] for row in rows])
            if b.shape != (int(size), int(size)):
                raise SystemExit(f"qustah_drawn.json: {name}@{size} is {b.shape[1]}x{b.shape[0]}")
            drawn[name][int(size)] = b
        fill_sizes(drawn[name], vector)
    return drawn


def fill_sizes(sizes, vector=()):
    """Every sheet size for a hand-drawn icon, so the drawing shows whatever size the UI scale picks: a size twice a
    drawn one is that drawing doubled; any other is fitted from the biggest drawing (its pixels as the vector)."""
    drawn_sizes = sorted(sizes)
    biggest = sizes[drawn_sizes[-1]]
    src = Image.fromarray(biggest.astype(np.uint8) * 255, "L").resize((SRC, SRC), Image.NEAREST)
    for s in SIZES:
        if s in sizes or s in vector:
            continue
        if s % 2 == 0 and s // 2 in drawn_sizes:
            sizes[s] = sizes[s // 2].repeat(2, 0).repeat(2, 1)
            continue
        cands, symmetric = draw_candidates(src, s)
        sizes[s] = cands[choose(cands, symmetric, None)][0]


def apply_edits(b, edits):
    b = b.copy()
    for edit in edits or ():
        where, value = edit.split("=")
        x, y = (int(v) for v in where.split(","))
        b[y, x] = value.strip() == "1"
    return b


# ------------------------------------------------------------------ sheet
def layout(count):
    """size -> (page, y, columns); a page is cut when the next size would not fit"""
    lay, page, y = {}, 1, 0
    for s in SIZES:
        pitch = s + 2
        cols = PAGE // pitch
        rows = -(-count // cols)
        if y + rows * pitch > PAGE:
            page, y = page + 1, 0
        lay[s] = (page, y, cols)
        y += rows * pitch
    return lay


def write_sheet(names, pixels, version, folder):
    lay = layout(len(names))
    pages = {}
    for s in SIZES:
        page, y0, cols = lay[s]
        pitch = s + 2
        pages.setdefault(page, []).append((s, y0, cols))
    files = []
    for page in sorted(pages):
        height = max(y0 + (-(-len(names) // cols)) * (s + 2) for s, y0, cols in pages[page])
        img = np.zeros((height, PAGE), np.uint8)
        for s, y0, cols in pages[page]:
            pitch = s + 2
            for i, name in enumerate(names):
                x, y = (i % cols) * pitch + 1, y0 + (i // cols) * pitch + 1
                img[y:y + s, x:x + s] = pixels[(name, s)] * 255
        rgba = np.zeros((height, PAGE, 4), np.uint8)
        rgba[..., :3] = 255
        rgba[..., 3] = img
        file = f"qustah-v{version}-{page}.png"
        Image.fromarray(rgba, "RGBA").save(os.path.join(folder, file), optimize=True)
        files.append(file)
    return files, lay


def write_manifest(names, files, lay, version, path):
    lines = [
        "-- The lib's own icon sheet (repo folder qustah/icons, drawn by tools/gen_filled_sheet.py): filled icons",
        "-- (Solar Bold, a few Material Design Icons) at " + ", ".join(map(str, SIZES)) + " px, pixel for pixel with no grey edges.",
        "-- Downloaded once and used before the lucide sheets (icons.lua); icons are snapped to these sizes.",
        "return {",
        f'    Id = "qustah", Version = {version},',
        "    Files = { " + ", ".join(f'"{f}"' for f in files) + " },",
        '    Names = "' + ",".join(names) + '",',
        "    Sizes = {",
    ]
    for s in SIZES:
        p, y, c = lay[s]
        lines.append(f"        [{s}] = {{ {p}, {y}, {c} }},")
    lines += ["    },", "}", ""]
    with open(path, "w") as f:
        f.write("\n".join(lines))


# ------------------------------------------------------------------ review
def review(names, pixels, chosen, all_cands, folder):
    os.makedirs(folder, exist_ok=True)
    font = ImageFont.load_default()
    bg, fg = (20, 21, 26), (235, 237, 242)
    for s in SIZES:
        z = max(2, 64 // s)
        cell = s * z + 8
        cols = 12
        rows = -(-len(names) // cols)
        img = Image.new("RGB", (cols * (cell + 70), rows * (cell + 14)), (13, 14, 17))
        d = ImageDraw.Draw(img)
        for i, n in enumerate(names):
            x, y = (i % cols) * (cell + 70), (i // cols) * (cell + 14)
            t = Image.fromarray(np.where(pixels[(n, s)][..., None], fg, bg).astype(np.uint8)).resize((s * z, s * z), Image.NEAREST)
            img.paste(t, (x + 4, y + 4))
            d.text((x + s * z + 10, y + 6), n[:12], fill=(200, 200, 205), font=font)
            d.text((x + s * z + 10, y + 18), chosen[(n, s)], fill=(130, 200, 255), font=font)
        img.save(os.path.join(folder, f"sheet_{s}.png"))
    for s in (14, 16):
        z = 4
        cell = s * z + 6
        img = Image.new("RGB", (110 + 4 * cell, len(names) * (cell + 4)), (13, 14, 17))
        d = ImageDraw.Draw(img)
        for i, n in enumerate(names):
            y = i * (cell + 4)
            d.text((4, y + cell // 2 - 5), n[:16], fill=(200, 200, 205), font=font)
            for j, key in enumerate("ABCD"):
                if key not in all_cands[(n, s)]:
                    continue
                b = all_cands[(n, s)][key][0]
                t = Image.fromarray(np.where(b[..., None], fg, bg).astype(np.uint8)).resize((s * z, s * z), Image.NEAREST)
                img.paste(t, (110 + j * cell, y))
                if chosen[(n, s)] == key:
                    d.rectangle([110 + j * cell - 2, y - 2, 110 + j * cell + s * z + 1, y + s * z + 1], outline=(130, 200, 255))
        img.save(os.path.join(folder, f"candidates_{s}.png"))


# ------------------------------------------------------------------ main
def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--iconify", required=True, help="folder with solar.json and mdi.json (github.com/iconify/icon-sets/json)")
    ap.add_argument("--version", type=int, default=22)
    ap.add_argument("--review", help="write contact sheets here")
    ap.add_argument("--only", help="comma separated names (try a few icons quickly; nothing is written but the review)")
    args = ap.parse_args()

    with open(os.path.join(HERE, "qustah_icons.json")) as f:
        mapping = {k: v for k, v in json.load(f).items() if not k.startswith("_")}
    picks_path = os.path.join(HERE, "qustah_picks.json")
    picks = json.load(open(picks_path)) if os.path.exists(picks_path) else {}
    edits = picks.pop("edits", {})
    picks.pop("_about", None)
    drawn = load_drawn()
    names = sorted(mapping)
    if args.only:
        names = [n for n in names if n in args.only.split(",")]

    sets = load_sets(args.iconify)
    for n in names:
        if mapping[n] == "drawn" and n not in drawn:
            raise SystemExit(f"qustah_icons.json: {n} is \"drawn\" but has no drawing in qustah_drawn.json")
    # an icon mapped to "drawn" exists only as a drawing (every size is made from it), so it needs no vector
    big = render_all({n: svg_of(sets, mapping[n]) for n in names if mapping[n] != "drawn"})

    pixels, chosen, all_cands = {}, {}, {}
    for i, n in enumerate(names):
        for s in SIZES:
            if mapping[n] == "drawn":
                all_cands[(n, s)] = {}
                chosen[(n, s)] = "drawn"
                pixels[(n, s)] = drawn[n][s]
                continue
            cands, symmetric = draw_candidates(big[n], s)
            key = choose(cands, symmetric, picks.get(f"{n}@{s}"))
            all_cands[(n, s)] = cands
            chosen[(n, s)] = key
            pixels[(n, s)] = apply_edits(cands[key][0], edits.get(f"{n}@{s}"))
            if s in drawn.get(n, {}):
                chosen[(n, s)] = "drawn"
                pixels[(n, s)] = drawn[n][s]
        print(f"\r{i + 1}/{len(names)} {n}            ", end="", file=sys.stderr, flush=True)
    print(file=sys.stderr)

    if args.review:
        review(names, pixels, chosen, all_cands, args.review)
    if args.only:
        return
    out = os.path.join(os.path.dirname(ROOT), "qustah", "icons")
    for old in os.listdir(out):
        if old.startswith("qustah-v") and old.endswith(".png"):
            os.remove(os.path.join(out, old))
    files, lay = write_sheet(names, pixels, args.version, out)
    write_manifest(names, files, lay, args.version, os.path.join(ROOT, "src", "icons_qustah.lua"))
    print("wrote", ", ".join(files))


if __name__ == "__main__":
    main()
