#!/bin/bash
# Renders the main pages in every theme pack -> test/themes/<pack>_<page>.png (visual check of the packs)
HERE="$(cd "$(dirname "$0")" && pwd)"; TOOLS="${TOOLS:-/home/claude/nova/tools}"; OUT="$HERE/themes"
mkdir -p "$OUT"; rm -f "$OUT"/*.png
"$HERE/run.sh" > /dev/null
STEPS="$(mktemp)"
{
cat "$TOOLS/gui_dump.lua"
echo "getfenv(0).PACKS_ENV = \"${PACKS:-}\""
cat <<'LUA'
getfenv(0).SMOKE_STEPS = function(MOCK)
  local E = getfenv(0)
  local Lib = E.getgenv().TestLib
  local w = Lib.Windows[1]
  local function wait(t) MOCK.advance(t or 0.6, MOCK.frame) end
  local function tab(title) for _, t in ipairs(w.Tabs) do if t.Title == title then t:Select() wait() return t end end end
  local function shot(name) wait(0.8) GUI_DUMP(w.gui, name) print("SHOT " .. name) end
  w.width, w.height = 600, 640 w:_layout() wait()
  w:ReportError("ESP", "attempt to index nil with 'Character'")
  w:KeybindList(true) w:Watermark(true)
  local PACKS = {}
  for pack in string.gmatch(E.PACKS_ENV or "", "[^,]+") do PACKS[#PACKS + 1] = pack end
  if #PACKS == 0 then PACKS = { "Dark", "Midnight", "AMOLED", "Light" } end
  for _, pack in ipairs(PACKS) do
    w.flags.__ui_theme:Set(pack) wait()
    local V = tab("Visuals") V.Pages[1]:Select() shot(pack .. "_overview")
    tab("Silent") shot(pack .. "_silent")
    tab("Misc") shot(pack .. "_misc")
    local T = tab("Settings") T.Pages[1]:Select() shot(pack .. "_settings")
    T.Pages[3]:Select() shot(pack .. "_info")
    T.Pages[1]:Select()
    local ed = w.gui:FindFirstChild("Section_Edit colours", true)
    if ed and not ed.Body.Visible then ed.Header.Activated:Fire() end
    wait() shot(pack .. "_editor")
    tab("Dashboard") shot(pack .. "_dashboard")
  end
  w.flags.__ui_accent:Set(E.Color3.fromRGB(110, 200, 130))
  for _, pack in ipairs({ "Dark", "Light" }) do
    w.flags.__ui_theme:Set(pack) wait()
    local V = tab("Visuals") V.Pages[1]:Select() shot(pack .. "_green")
  end
end
LUA
} > "$STEPS"
"$TOOLS/smoke.sh" "$HERE/example_bundled.lua" "$STEPS" > "$OUT/run.txt" 2>&1
grep -E "attempt" "$OUT/run.txt" | head -3
for s in $(grep -o "^SHOT .*" "$OUT/run.txt" | cut -d' ' -f2); do python3 "$TOOLS/render.py" "$OUT/run.txt" "$s" "$OUT/$s.png" >/dev/null; done
rm -f "$STEPS"; ls "$OUT" | wc -l
