#!/bin/bash
# Layout audit: every tab / page / popup / panel at several window and screen sizes -> test/audit/layout.txt
HERE="$(cd "$(dirname "$0")" && pwd)"; ROOT="$HERE/../.."; TOOLS="${TOOLS:-/home/claude/nova/tools}"
bash "$ROOT/test/run.sh" > /dev/null
STEPS="$(mktemp)"
{
cat "$TOOLS/gui_dump.lua"
cat <<'LUA'
getfenv(0).SMOKE_STEPS = function(MOCK)
  local E = getfenv(0)
  local Lib = E.getgenv().TestLib
  local w = Lib.Windows[1]
  local function wait(t) MOCK.advance(t or 0.4, MOCK.frame) end
  wait(2)
  if w._dialog then w._dialog:Close() end
  local n, vp = 0, "1280,720"
  local function shot(label)
    wait(0.3) n = n + 1
    local tag = string.format("s%03d_%s", n, label):gsub("[^%w_]", "")
    GUI_DUMP(w.gui, tag) print("SHOT " .. tag .. " " .. vp)
  end
  local function find(name, root) for _, o in ipairs((root or w.gui):GetDescendants()) do if o.Name == name then return o end end end
  local function everything(size)
    for _, tab in ipairs(w.Tabs) do
      tab:Select() wait(0.1)
      for _, page in ipairs(tab.Pages) do
        page:Select()
        -- open sections / card tabs / colour panels on this page
        for _, o in ipairs(page.frame:GetDescendants()) do
          if o.Name == "Picker" and o:IsA("Frame") then o.Visible = true end
          if o.Name:match("^Section_") and o:FindFirstChild("Body") then o.Body.Visible = true end
        end
        shot(size .. "_" .. tab.Title .. "_" .. page.Name)
        for _, o in ipairs(page.frame:GetDescendants()) do if o.Name == "Picker" and o:IsA("Frame") then o.Visible = false end end
      end
    end
    -- popups and floating things
    local V
    for _, tab in ipairs(w.Tabs) do if tab.Title == "Silent" then tab:Select() end end
    wait(0.1)
    local sel = w.flags.priority and w.flags.priority.Row:FindFirstChild("Select")
    if sel then MOCK.click(sel) shot(size .. "_dropdown") w:_closePopup() end
    w:Notify({ Title = "A rather long notification title for the audit", Content = "And a content line that is longer than the toast is wide, to see it cut", Buttons = { { Title = "Undo" }, { Title = "Open" } } })
    w:Dialog({ Title = "Delete profile \"ranked games low graphics\"?", Content = "This removes it from this PC. Profiles shared as codes keep working.", Buttons = { { Title = "Cancel" }, { Title = "Delete", Style = "Danger" } } })
    shot(size .. "_dialog")
    if w._dialog then w._dialog:Close() end
    w:Watermark(true, { Text = "extra text" }) w:KeybindList(true) w:SessionBar(true) w:StatsMonitor("Floating")
    shot(size .. "_overlays")
    w:Watermark(false) w:KeybindList(false) w:SessionBar(false) w:StatsMonitor("Off")
  end
  local sizes = {
    { "min", 400, 300, 1280, 720 }, { "default", 540, 390, 1280, 720 }, { "max", 920, 660, 1280, 720 },
    { "laptop", 540, 390, 1024, 576 }, { "phone", 540, 390, 640, 360 },
  }
  for _, s in ipairs(sizes) do
    MOCK.setViewport(s[4], s[5]) wait(0.3) vp = s[4] .. "," .. s[5]
    w.width, w.height, w.topLeft = s[2], s[3], nil w:_layout() wait(0.5)
    print(string.format("SIZE %s window %dx%d viewport %dx%d scale %.2f", s[1], s[2], s[3], s[4], s[5], w.scale.Scale))
    everything(s[1])
  end
end
LUA
} > "$STEPS"
"$TOOLS/smoke.sh" "$ROOT/test/example_bundled.lua" "$STEPS" > "$HERE/layout_run.txt" 2>&1
grep -E "attempt|== errors" "$HERE/layout_run.txt" | head -5
: > "$HERE/layout.txt"
grep "^SHOT " "$HERE/layout_run.txt" | while read -r _ s vp; do
  VIEWPORT=$vp AUDIT=1 python3 "$TOOLS/render.py" "$HERE/layout_run.txt" "$s" - >> "$HERE/layout.txt" 2>&1
done
grep "^SIZE" "$HERE/layout_run.txt"
rm -f "$STEPS"
echo "audit lines: $(grep -c ^AUDIT "$HERE/layout.txt")"
