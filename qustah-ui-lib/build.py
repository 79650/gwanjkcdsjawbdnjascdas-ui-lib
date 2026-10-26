#!/usr/bin/env python3
"""Bundles src/ into one file: dist/qustah-ui-lib.lua (load it with loadstring(game:HttpGet(raw url))()).

Each module becomes a function in a small module table; require("name") inside the bundle returns that
module (loaded once). Module names are paths under src/ without .lua, e.g. "elements/toggle".
Usage: python3 build.py            -> dist/qustah-ui-lib.lua
"""
import json, pathlib, re, sys

ROOT = pathlib.Path(__file__).resolve().parent
SRC, DIST = ROOT / "src", ROOT / "dist"
VERSION = re.search(r'Version = "([^"]+)"', (SRC / "init.lua").read_text()).group(1)

modules = sorted(p for p in SRC.rglob("*.lua"))
names = {p: p.relative_to(SRC).with_suffix("").as_posix() for p in modules}

# every require("x") must point at a module
missing = []
for path in modules:
    for name in re.findall(r'require\("([^"]+)"\)', path.read_text()):
        if name not in names.values():
            missing.append(f"{names[path]} requires unknown module '{name}'")
if missing:
    sys.exit("\n".join(missing))

out = [
    f"-- qustah-ui-lib v{VERSION} | bundled from src/ by build.py - edit the source files, not this one.",
    "-- local Lib = loadstring(game:HttpGet(\"<raw url>/dist/qustah-ui-lib.lua\"))()",
    "local __modules, __loaded = {}, {}",
    "local function require(name)",
    "    local loaded = __loaded[name]",
    "    if loaded == nil then",
    "        local module = __modules[name]",
    "        if not module then error(\"[qustah-ui-lib] missing module: \" .. tostring(name), 2) end",
    "        loaded = module()",
    "        __loaded[name] = loaded",
    "    end",
    "    return loaded",
    "end",
    "",
]
for path in modules:
    out.append(f"__modules[{json.dumps(names[path])}] = function()")
    out.append(path.read_text().rstrip("\n"))
    out.append("end")
    out.append("")
out.append('return require("init")')

DIST.mkdir(exist_ok=True)
target = DIST / "qustah-ui-lib.lua"
target.write_text("\n".join(out) + "\n")
print(f"built {target.relative_to(ROOT)}: {len(modules)} modules, {target.stat().st_size // 1024} KB, v{VERSION}")
