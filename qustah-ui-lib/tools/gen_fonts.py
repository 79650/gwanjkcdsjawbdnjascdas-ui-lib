#!/usr/bin/env python3
"""Builds the downloadable UI fonts: fonts/<Family>/<Family>-<weight>.ttf (static Regular / Medium / SemiBold / Bold,
cut down to Latin + Turkish + punctuation so each file stays small) from Google Fonts' variable fonts (all OFL).
  git clone --depth 1 --filter=blob:none --sparse https://github.com/google/fonts.git /tmp/gfonts
  (cd /tmp/gfonts && git sparse-checkout set ofl/inter ofl/geist ofl/manrope ofl/jetbrainsmono)
  python3 tools/gen_fonts.py /tmp/gfonts/ofl
"""
import pathlib, shutil, sys
from fontTools.ttLib import TTFont
from fontTools.varLib.instancer import instantiateVariableFont
from fontTools import subset

SRC = pathlib.Path(sys.argv[1])
OUT = pathlib.Path(__file__).resolve().parent.parent / "fonts"
FAMILIES = {  # name -> (folder, file, extra axes)
    "Inter": ("inter", "Inter[opsz,wght].ttf", {"opsz": 14}),
    "Geist": ("geist", "Geist[wght].ttf", {}),
    "Manrope": ("manrope", "Manrope[wght].ttf", {}),
    "JetBrainsMono": ("jetbrainsmono", "JetBrainsMono[wght].ttf", {}),
}
WEIGHTS = {400: "Regular", 500: "Medium", 600: "SemiBold", 700: "Bold"}
UNICODES = "U+0000-024F,U+0300-036F,U+1E00-1EFF,U+2000-206F,U+20A0-20CF,U+2100-214F,U+2190-21FF,U+2200-22FF,U+25A0-25FF"

for family, (folder, file, axes) in FAMILIES.items():
    target = OUT / family
    target.mkdir(parents=True, exist_ok=True)
    shutil.copy(SRC / folder / "OFL.txt", target / "OFL.txt")
    for weight, label in WEIGHTS.items():
        font = TTFont(SRC / folder / file)
        static = instantiateVariableFont(font, {"wght": weight, **axes})
        options = subset.Options()
        options.layout_features = ["*"]
        options.name_IDs = ["*"]
        options.notdef_outline = True
        sub = subset.Subsetter(options)
        sub.populate(unicodes=subset.parse_unicodes(UNICODES))
        sub.subset(static)
        path = target / f"{family}-{label}.ttf"
        static.save(path)
        print(path.relative_to(OUT.parent), path.stat().st_size // 1024, "KB")
