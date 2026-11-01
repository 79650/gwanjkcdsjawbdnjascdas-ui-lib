#!/bin/bash
# Renders test/widgets_demo.lua (the dashboard-style elements) -> test/showcase/widgets_*.png
HERE="$(cd "$(dirname "$0")" && pwd)"; ROOT="$HERE/.."; TOOLS="${TOOLS:-/home/claude/nova/tools}"; OUT="$HERE/showcase"
mkdir -p "$OUT"
python3 "$ROOT/build.py" > /dev/null || exit 1
B="$(mktemp --suffix=.lua)"; STEPS="$(mktemp --suffix=.lua)"; RUN="$(mktemp)"
{ echo 'getgenv().TestLib = (function()'; cat "$ROOT/dist/qustah-ui-lib.lua"; echo 'end)()'; cat "$HERE/widgets_demo.lua"; } > "$B"
{
cat "$TOOLS/gui_dump.lua"
cat <<'LUA'
getfenv(0).SMOKE_STEPS = function(MOCK)
  local Lib = getfenv(0).getgenv().TestLib
  local w = Lib.Windows[1]
  local function wait(t) MOCK.advance(t or 0.6, MOCK.frame) end
  wait(2)
  if w._dialog then w._dialog:Close() end
  for _, t in ipairs(Lib._openToasts or {}) do pcall(t.dismiss) end
  MOCK.setViewport(1400, 1400) wait(0.5)
  w.width, w.height = 600, 1000 w.topLeft = Vector2.new(20, 20) w:_layout() wait(1)
  for _, tab in ipairs(w.Tabs) do
    if tab.Title ~= "Settings" and tab.Title ~= "Dashboard" then
      for pi, page in ipairs(tab.Pages or {}) do
        tab:Select() wait() page:Select() wait(1.5)
        w:_hideTip()
        local name = tab.Title .. "_" .. pi
        GUI_DUMP(w.gui, name)
        local s = w.scale.Scale
        print(string.format("RECT %s %.1f,%.1f,%.1f,%.1f", name, w.topLeft.X - 14, w.topLeft.Y - 14, (w.width + 12 + 40) * s + 28, w.height * s + 28))
        print("PAGE " .. name)
      end
    end
  end
end
LUA
} > "$STEPS"
"$TOOLS/smoke.sh" "$B" "$STEPS" > "$RUN" 2>&1
grep -E "SMOKE|thread error|attempt to|error" "$RUN" | grep -v "^@@" | head -20
for n in $(grep "^PAGE" "$RUN" | awk '{print $2}'); do
  r=$(grep "^RECT $n " "$RUN" | awk '{print $3}')
  VIEWPORT=1400,1400 python3 "$TOOLS/render.py" "$RUN" "$n" "$OUT/widgets_$n.png" $r > /dev/null 2>&1 || echo "render fail $n"
done
cp "$RUN" "$HERE/widgets_last.txt"
