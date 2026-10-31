#!/usr/bin/env python3
"""Builds the downloadable UI fonts (the ones Roblox's own font library lacks): fonts/<Family>/<Family>-<weight>.ttf
(Regular / Medium / SemiBold / Bold, cut down to Latin + punctuation so each file stays small). All OFL.
  Geist           from Vercel's static files (vercel/geist-font, fonts/Geist/ttf)
  GeistMono       from Vercel's static files (vercel/geist-font, fonts/GeistMono/ttf)
  GeistPixel      from Vercel's Geist Pixel Square (one weight: the same file for all four)
  git clone --depth 1 --filter=blob:none --sparse https://github.com/vercel/geist-font.git /tmp/geist
  (cd /tmp/geist && git sparse-checkout set --no-cone '/fonts/**')
  python3 tools/gen_fonts.py /tmp/geist/fonts
"""
import io, pathlib, shutil, sys
from fontTools.ttLib import TTFont
from fontTools import subset

VERCEL = pathlib.Path(sys.argv[1])
OUT = pathlib.Path(__file__).resolve().parent.parent / "fonts"
WEIGHTS = {400: "Regular", 500: "Medium", 600: "SemiBold", 700: "Bold"}
UNICODES = "U+0000-024F,U+0300-036F,U+1E00-1EFF,U+2000-206F,U+20A0-20CF,U+2100-214F,U+2190-21FF,U+2200-22FF,U+25A0-25FF"

def static(pattern):
    return lambda weight: TTFont(str(pattern).format(WEIGHTS[weight]))
FAMILIES = {
    "Geist": (static(VERCEL / "Geist" / "ttf" / "Geist-{}.ttf"), VERCEL.parent / "LICENSE.txt"),
    "GeistMono": (static(VERCEL / "GeistMono" / "ttf" / "GeistMono-{}.ttf"), VERCEL.parent / "LICENSE.txt"),
    "GeistPixel": (lambda weight: TTFont(VERCEL / "GeistPixel" / "ttf" / "GeistPixel-Square.ttf"), VERCEL.parent / "LICENSE.txt"),
}

for family, (load, licence) in FAMILIES.items():
    target = OUT / family
    target.mkdir(parents=True, exist_ok=True)
    if licence.exists(): shutil.copy(licence, target / "OFL.txt")
    for weight, label in WEIGHTS.items():
        if family == "GeistPixel" and weight != 400: continue  # one weight: the family file points every weight at it
        font = load(weight)
        options = subset.Options()
        options.layout_features = ["*"]
        options.name_IDs = ["*"]
        options.notdef_outline = True
        sub = subset.Subsetter(options)
        sub.populate(unicodes=subset.parse_unicodes(UNICODES))
        sub.subset(font)
        path = target / f"{family}-{label}.ttf"
        font.save(path)
        print(path.relative_to(OUT.parent), path.stat().st_size // 1024, "KB")
