#!/usr/bin/env python3
"""Bundles src/ into one file: dist/qustah-ui-lib.lua (load it with loadstring(game:HttpGet(raw url))()).

Each module becomes a function in a small module table; require("name") inside the bundle returns that
module (loaded once). Module names are paths under src/ without .lua, e.g. "elements/toggle".
Usage: python3 build.py            -> dist/qustah-ui-lib.lua + dist/qustah-ui-lib.min.lua (comments / indentation stripped)
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


def minify(source):
    """Removes comments, indentation and blank lines. Strings (quoted and [[long]]) are copied untouched;
    line breaks stay, so statement boundaries never change. No renaming - the code means exactly the same."""
    out, i, n = [], 0, len(source)
    line_start = True
    while i < n:
        c = source[i]
        if line_start and c in " \t":
            i += 1
            continue
        line_start = False
        if source.startswith("--", i):
            m = re.match(r"--\[(=*)\[", source[i:])
            if m:
                end = source.find("]" + m.group(1) + "]", i)
                i = n if end < 0 else end + len(m.group(1)) + 2
            else:
                end = source.find("\n", i)
                i = n if end < 0 else end
            continue
        m = re.match(r"\[(=*)\[", source[i:])
        if m:
            end = source.find("]" + m.group(1) + "]", i)
            end = n if end < 0 else end + len(m.group(1)) + 2
            out.append(source[i:end]); i = end
            continue
        if c in "\"'":
            j = i + 1
            while j < n and source[j] != c:
                if source[j] == "\\": j += 1
                if source[j] == "\n": break
                j += 1
            out.append(source[i:j + 1]); i = j + 1
            continue
        if c == "\n":
            # drop trailing spaces and empty lines
            while out and out[-1] in (" ", "\t"): out.pop()
            if out and out[-1] != "\n": out.append("\n")
            line_start = True
            i += 1
            continue
        if c in " \t":
            # a space is only kept between two word characters (and a few pairs that would fuse into other tokens)
            j = i
            while j < n and source[j] in " \t": j += 1
            prev = out[-1][-1] if out and out[-1] else "\n"
            nxt = source[j] if j < n else "\n"
            word = lambda ch: ch.isalnum() or ch == "_"
            keep = (word(prev) and word(nxt)) or (prev == "-" and nxt == "-") or (prev == "[" and nxt == "[") \
                or (prev == "." and nxt == ".") or (prev.isdigit() and nxt == ".") or (prev == "." and nxt.isdigit()) \
                or (prev == "=" and nxt == "=") or (prev in "<>~" and nxt == "=")
            if keep and prev != "\n": out.append(" ")
            i = j
            continue
        out.append(c); i += 1
    return "".join(out)


minified = DIST / "qustah-ui-lib.min.lua"
body = "\n".join(out[2:]) + "\n"
minified.write_text(f"-- qustah-ui-lib v{VERSION} (minified build of dist/qustah-ui-lib.lua)\n" + minify(body))
print(f"built {minified.relative_to(ROOT)}: {minified.stat().st_size // 1024} KB")
