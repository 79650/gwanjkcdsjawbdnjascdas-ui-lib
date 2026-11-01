#!/usr/bin/env python3
"""Draws a script's own icon sheet: every listed lucide icon at every listed on-screen size, pixel for pixel,
so Roblox shows them without any scaling (the sharpest an icon can be). Used with Lib.Icons.UseSheet(manifest).

  python3 tools/gen_sheet.py <lucide icons dir> <id> <version> <names: a,b,c> <sizes: 5-29> <out dir> [split]
writes <out dir>/<id>-<n>.png and <out dir>/<id>.lua (the manifest: page and place of every size). With `split`
(e.g. 20) the sizes below it and the sizes from it go on separate pages (small icons / big icons). A page is at
most 1024 x 1024: Roblox shrinks bigger images, which would undo the pixel-exact drawing. Bump the version when the
sheet changes: clients keep old files under the old name.

How an icon is drawn:
- strokes are exactly 1 screen pixel up to 17 px (lucide's 2 / 24 would be under a pixel at 10 - 12 px, and a
  1.25 px line always leaves a grey band), lucide's own weight from 18 px on;
- each icon is drawn 16x larger in Chromium and averaged down (exact edge coverage);
- hinting: the icon may move by up to half a pixel (quarter steps) so its lines land on whole pixels; of the 16
  positions the one with the fewest half-covered pixels wins (straight strokes come out solid, not grey and blurred),
  when it clearly beats the unmoved one (15 % fewer half pixels).
  Half a pixel never shows as a shift, the gain in sharpness at 9 - 14 px does.
"""
import json, os, re, subprocess, sys, tempfile, pathlib
import numpy as np
from PIL import Image

SUPER = 16           # drawn this many times larger, then averaged down
STEPS = 4            # hinting: quarter-pixel positions per axis
MARGIN = 1           # a free pixel round every icon in the hi-res render (room to move)
PAGE = 1024

icons_dir, sheet_id, version, names_arg, sizes_arg, out_dir = sys.argv[1:7]
split = int(sys.argv[7]) if len(sys.argv) > 7 else None
icons_dir, out_dir = pathlib.Path(icons_dir), pathlib.Path(out_dir)
lo, hi = (int(x) for x in sizes_arg.split("-"))
sizes = list(range(lo, hi + 1))
have = {p.stem for p in icons_dir.glob("*.svg")}
alias = {}
for meta in icons_dir.glob("*.json"):
    try: data = json.loads(meta.read_text())
    except Exception: continue
    for entry in data.get("aliases", []):
        alias[entry["name"] if isinstance(entry, dict) else entry] = meta.stem
order = []
for name in [n for n in names_arg.split(",") if n]:
    src = name if name in have else alias.get(name)
    if src and name not in [n for n, _ in order]: order.append((name, src))
svgs = {src: re.sub(r"<!--.*?-->", "", (icons_dir / f"{src}.svg").read_text(), flags=re.S).replace("currentColor", "#ffffff") for _, src in order}

# ---- 1. render every size as its own hi-res grid (one Chromium screenshot per size)
GRID_COLS = 12
tmp = tempfile.mkdtemp()
jobs = []
for size in sizes:
    cell = size + 2 * MARGIN
    # whole-pixel strokes up to 17 px: a 1 px line that the hinting puts on the pixel grid is solid white; a 1.25 px
    # one always leaves a grey band beside it. From 18 px on lucide's own weight (size / 12).
    stroke = (1.0 if size <= 17 else size / 12) * 24 / size
    cells = []
    for i, (_, src) in enumerate(order):
        svg = svgs[src].replace('width="24"', f'width="{size}"').replace('height="24"', f'height="{size}"')
        svg = svg.replace('stroke-width="2"', f'stroke-width="{stroke:.3f}"')
        x, y = (i % GRID_COLS) * cell + MARGIN, (i // GRID_COLS) * cell + MARGIN
        cells.append(f'<div style="position:absolute;left:{x}px;top:{y}px;width:{size}px;height:{size}px">{svg}</div>')
    w, h = GRID_COLS * cell, ((len(order) + GRID_COLS - 1) // GRID_COLS) * cell
    path = os.path.join(tmp, f"s{size}.html")
    open(path, "w").write(f'<html><body style="margin:0;background:transparent;width:{w}px;height:{h}px;position:relative">{"".join(cells)}</body></html>')
    jobs.append([path, w, h, os.path.join(tmp, f"s{size}.png")])
script = """const {chromium}=require('playwright');(async()=>{const b=await chromium.launch();
for (const [f,w,h,o] of JSON.parse(process.argv[1])){const p=await b.newPage({viewport:{width:w,height:h},deviceScaleFactor:%d});
await p.goto('file://'+f);await p.waitForTimeout(200);await p.screenshot({path:o,omitBackground:true,clip:{x:0,y:0,width:w,height:h}});await p.close();}
await b.close();})();""" % SUPER
subprocess.run(["node", "-e", script, json.dumps(jobs)], check=True)

# ---- 2. per icon: the best quarter-pixel position, averaged down to `size` x `size`
def best_cell(hires, size):
    """hires: (size + 2 * MARGIN) * SUPER square alpha (0..1). Returns size x size coverage."""
    best, best_score, base, base_score = None, None, None, None
    step = SUPER // STEPS
    for oy in range(-STEPS // 2, STEPS // 2):
        for ox in range(-STEPS // 2, STEPS // 2):
            y0, x0 = MARGIN * SUPER + oy * step, MARGIN * SUPER + ox * step
            window = hires[y0:y0 + size * SUPER, x0:x0 + size * SUPER]
            # whatever is cut off by the move would be lost: such a position is not allowed
            if abs(window.sum() - hires.sum()) > 1e-3 * max(hires.sum(), 1):
                continue
            small = window.reshape(size, SUPER, size, SUPER).mean(axis=(1, 3))
            partial = float((4 * small * (1 - small)).sum())       # 0 for solid / empty pixels, 1 for half
            if ox == 0 and oy == 0: base, base_score = small, partial
            if best_score is None or partial < best_score:
                best, best_score = small, partial
    # a move only for a clear gain (at least 15 % fewer half pixels): small gains can look worse than they score
    if base is not None and not (best_score < 0.85 * base_score): return base
    return best

coverage = {}
for size, (_, w, h, png) in zip(sizes, jobs):
    alpha = np.asarray(Image.open(png).getchannel("A"), dtype=np.float32) / 255.0
    cell = (size + 2 * MARGIN) * SUPER
    coverage[size] = []
    for i in range(len(order)):
        x, y = (i % GRID_COLS) * cell, (i // GRID_COLS) * cell
        coverage[size].append(best_cell(alpha[y:y + cell, x:x + cell], size))

# ---- 3. pack: rows of icons per size, pages of at most 1024 x 1024 (a new page at `split`)
pages, layout = [], {}
page_y = None
for size in sizes:
    pitch = size + 2
    cols = PAGE // pitch
    rows = (len(order) + cols - 1) // cols
    new_group = split is not None and size == split
    if page_y is None or new_group or page_y + rows * pitch > PAGE:
        pages.append([])
        page_y = 0
    layout[size] = (len(pages), page_y, cols)
    for i in range(len(order)):
        pages[-1].append((size, i, (i % cols) * pitch + 1, page_y + (i // cols) * pitch + 1))
    page_y += rows * pitch

out_dir.mkdir(parents=True, exist_ok=True)
files = []
for k, items in enumerate(pages, 1):
    height = max(y + size + 1 for size, _, _, y in items)
    alpha = np.zeros((height, PAGE), dtype=np.float32)
    for size, i, x, y in items:
        alpha[y:y + size, x:x + size] = coverage[size][i]
    a = Image.fromarray(np.clip(alpha * 255 + 0.5, 0, 255).astype(np.uint8), "L")
    white = Image.new("L", a.size, 255)
    name = f"{sheet_id}-{k}.png"
    Image.merge("RGBA", (white, white, white, a)).save(out_dir / name, optimize=True)
    files.append(name)

lua = [f"-- {sheet_id} icon sheet manifest, generated by qustah-ui-lib tools/gen_sheet.py. Do not edit by hand.",
       "return {",
       f'    Id = "{sheet_id}", Version = {int(version)},',
       "    Files = { " + ", ".join(f'"{f}"' for f in files) + " },",
       '    Names = "' + ",".join(n for n, _ in order) + '",',
       "    Sizes = {"]
for size in sizes:
    p, y0, cols = layout[size]
    lua.append(f"        [{size}] = {{ {p}, {y0}, {cols} }},")
lua += ["    },", "}", ""]
(out_dir / f"{sheet_id}.lua").write_text("\n".join(lua))
print(len(order), "icons,", len(sizes), "sizes,", len(files), "page(s):",
      ", ".join(f"{f} ({Image.open(out_dir / f).size[0]}x{Image.open(out_dir / f).size[1]})" for f in files))
