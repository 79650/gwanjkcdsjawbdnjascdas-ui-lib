#!/bin/bash
# Showcase renders of the current UI with real lucide icons -> test/showcase/*.png (2x, cropped to window + dock).
# Needs ICON_DIR: <asset id>.png icons (white on transparent), see tools note in the session.
HERE="$(cd "$(dirname "$0")" && pwd)"; TOOLS="${TOOLS:-/home/claude/nova/tools}"; OUT="$HERE/showcase"
mkdir -p "$OUT"
"$HERE/run.sh" > /dev/null
STEPS="$(mktemp)"
{
cat "$TOOLS/gui_dump.lua"
cat <<'LUA'
getfenv(0).SMOKE_STEPS = function(MOCK)
  local E = getfenv(0)
  local Lib = E.getgenv().TestLib
  local w = Lib.Windows[1]
  local function wait(t) MOCK.advance(t or 0.6, MOCK.frame) end
  wait(2)
  if w._dialog then w._dialog:Close() end
  for _, t in ipairs(Lib._openToasts or {}) do pcall(t.dismiss) end
  w.width, w.height = 600, 440 w.topLeft = nil w:_layout() wait(1)
  w:SetFooter("Universal")
  wait(21) -- let the FPS graph fill
  local function tab(title) for _, t in ipairs(w.Tabs) do if t.Title == title then t:Select() wait() return t end end end
  local function shot(name)
    wait(1.2)
    w:_hideTip()
    GUI_DUMP(w.gui, name)
    local s = w.scale.Scale
    print(string.format("RECT %s %.1f,%.1f,%.1f,%.1f", name, w.topLeft.X - 14, w.topLeft.Y - 14, (w.width + 12 + 40) * s + 28, w.height * s + 28))
    print("SHOT " .. name)
  end
  tab("Dashboard") shot("dashboard")
  local V = tab("Visuals") V.Pages[1]:Select() shot("visuals")
  V.Pages[2]:Select() shot("appearance")
  tab("Silent") shot("silent")
  tab("Misc") shot("misc")
  local T = tab("Settings") T.Pages[1]:Select() shot("settings")
  w.flags.__ui_theme:Set("Tokyo Night") tab("Visuals") V.Pages[1]:Select() shot("tokyo")
  w.flags.__ui_theme:Set("Light") shot("light")
  tab("Misc") shot("misc_light")
  tab("Silent") shot("silent_light")
  w.flags.__ui_theme:Set("Dark")
end
LUA
} > "$STEPS"
VIEWPORT=1280,720 "$TOOLS/smoke.sh" "$HERE/example_bundled.lua" "$STEPS" > "$OUT/run.txt" 2>&1
grep -E "attempt|error|FAIL" "$OUT/run.txt" | head
for s in $(grep -o "^SHOT .*" "$OUT/run.txt" | cut -d' ' -f2); do
  rect=$(grep "^RECT $s " "$OUT/run.txt" | cut -d' ' -f3)
  BG=transparent SS=3 OUTSCALE=2 python3 "$TOOLS/render.py" "$OUT/run.txt" "$s" "$OUT/$s.png" "$rect" rgba >/dev/null
done
rm -f "$STEPS"; ls "$OUT"
