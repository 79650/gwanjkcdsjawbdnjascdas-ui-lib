#!/bin/bash
# Tall renders of every page (whole content visible) + popups, for visual review -> test/review/*.png
HERE="$(cd "$(dirname "$0")" && pwd)"; TOOLS="${TOOLS:-/home/claude/nova/tools}"; OUT="$HERE/review"
"$HERE/run.sh" > /dev/null
STEPS="$(mktemp)"
{
cat "$TOOLS/gui_dump.lua"
cat <<'LUA'
getfenv(0).SMOKE_STEPS = function(MOCK)
  local E = getfenv(0)
  local Lib = E.getgenv().TestLib
  local w = Lib.Windows[1]
  local gui = w.gui
  local Enum = E.Enum
  local function wait(t) MOCK.advance(t or 0.6, MOCK.frame) end
  w.width, w.height = 560, 600 w:_layout() wait(1)
  local function tab(title) for _, t in ipairs(w.Tabs) do if t.Title == title then t:Select() wait() return t end end end
  local function find(name, root) for _, o in ipairs((root or gui):GetDescendants()) do if o.Name == name then return o end end end
  local function shot(name) wait(1) GUI_DUMP(gui, name) print("SHOT " .. name) end
  local function page() local p = w.current and w.current.current return p and p.frame end
  local function both(name)
    shot(name)
    local sc = page()
    local content = sc and sc:FindFirstChild("Content")
    local total = content and content.AbsoluteSize.Y + 30 or 0
    print("SIZES", name, total, sc and sc.AbsoluteSize.Y)
    if sc and total > sc.AbsoluteSize.Y + 4 then
      sc.CanvasPosition = E.Vector2.new(0, total - sc.AbsoluteSize.Y) shot(name .. "_end")
      sc.CanvasPosition = E.Vector2.new(0, 0)
    end
  end
  print("SCALE", w.scale.Scale)
  tab("Dashboard") both("dashboard")
  local V = tab("Visuals") V.Pages[1]:Select() both("overview")
  V.Pages[2]:Select() w.flags.fillColor:SetOpen(true) both("appearance")
  w.flags.fillColor:SetOpen(false)
  local sel = w.flags.font.Row:FindFirstChild("Select") print("ABS", sel.AbsolutePosition, sel.AbsoluteSize, w.flags.font.Row.AbsolutePosition, w.flags.font.Row.AbsoluteSize, find("Text").AbsolutePosition, find("Name color").AbsoluteSize) MOCK.click(sel) shot("dropdown")
  w:_closePopup() wait()
  tab("Silent") both("silent")
  MOCK.click(find("Filters", find("Targets"))) shot("silent_filters")
  tab("Misc") w.height = 900 w:_layout() wait() MOCK.click(find("Section_Advanced"):FindFirstChild("Header")) shot("misc_tall")
  w.height = 600 w:_layout() wait()
  tab("Silent") MOCK.click(w.flags.priority.Row:FindFirstChild("Select")) shot("dropdown_icons") w:_closePopup()
  w:Notify({ Title = "Profile deleted", Content = "pvp was removed", Icon = "trash-2", Buttons = { { Title = "Undo" }, { Title = "Open" } } })
  tab("Visuals") V.Pages[2]:Select() shot("toast_buttons")
  tab("Misc") both("misc")
  local T = tab("Settings") T.Pages[1]:Select() both("settings")
  w.Config:Save("ranked") w.Config:SetAutoLoad("ranked") w.Config:Save("pvp")
  local m = w.Config:ReadMeta() m.pvp = { saved = os.time(), note = "ranked games, low graphics" } w.Config:WriteMeta(m)
  w.flags.espRange:Set(2000)
  T.Pages[2]:Select() wait(1.5)
  MOCK.click(find("Profile_pvp"):FindFirstChild("Head")) both("profiles")
  MOCK.click(find("Profile_Default"):FindFirstChild("Head")) shot("profiles_default")
  w.width = 800 w:_layout() wait()
  local cb = find("CreateProfile"):FindFirstChild("Box", true) cb.Text = "ranked games" shot("profiles_typing")
  cb.Text = "pvp" shot("profiles_exists")
  cb.Text = ""
  MOCK.click(find("New profile"):FindFirstChild("Import", true)) wait()
  local ib = find("ImportProfile"):FindFirstChild("Box", true) ib.Text = w.Config:Export("pvp") shot("profiles_import")
  ib.Text = "" w.width = 560 w:_layout() wait()
  for i = 1, 3 do w:Notify({ Title = "Loaded " .. i, Content = "Profile pvp loaded" }) end
  w:Notify({ Title = "Teleport failed", Content = "No other public server found", Color = E.Color3.fromRGB(215, 130, 130) })
  wait(0.5) shot("bell_unread")
  MOCK.click(w.inboxButton) shot("inbox")
  w:_closePopup()
  w:ReportError("ESP", "attempt to index nil with 'Character'") w:ReportError("ESP", "attempt to index nil with 'Character'")
  w:ReportError("Silent Aim", "a very long error message that goes on and on to check wrapping inside the errors card on the info page")
  T.Pages[3]:Select() both("info")
  w:Confirm("Unload Qustāh?", "The menu and everything it runs will be removed.", function() end, "Unload", true) shot("dialog")
  w._dialog:Close()
  w:Watermark(true) w:KeybindList(true) w:SessionBar(true) w:StatsMonitor("Floating") tab("Visuals") wait(1) shot("overlays")
  V.Pages[2]:Select() w.flags.chams:SetOpen(true) shot("gradient")
  w.flags.chams:SetOpen(false) w:Watermark(false)
  w.flags.__ui_theme:Set("Light") tab("Settings") T.Pages[1]:Select() shot("light")
  tab("Visuals") V.Pages[1]:Select() shot("light_overview")
  w.flags.__ui_theme:Set("Midnight") shot("midnight")
  w.flags.__ui_theme:Set("AMOLED") shot("amoled")
  w.flags.__ui_theme:Set("Dark")
  w:StatsMonitor("Header") shot("header_stats")
  w:StatsMonitor("Off") w:KeybindList(false) w:SessionBar(false)
  w.width, w.height = 420, 420 w:_layout() tab("Visuals") V.Pages[1]:Select() both("narrow")
  w.width, w.height = 560, 390 w:_layout() wait()
  MOCK.setViewport(700, 420) wait(1) print("SMALLSCALE", w.scale.Scale) tab("Silent") shot("small")
end
LUA
} > "$STEPS"
sed -i 's/  w:_dialog_close_dummy() //' "$STEPS"
"$TOOLS/smoke.sh" "$HERE/example_bundled.lua" "$STEPS" > "$OUT/run.txt" 2>&1
grep -E "attempt|error|FAIL" "$OUT/run.txt" | head
rm -f "$OUT"/*.png
for s in $(grep -o "^SHOT .*" "$OUT/run.txt" | cut -d' ' -f2); do
  python3 "$TOOLS/render.py" "$OUT/run.txt" "$s" "$OUT/$s.png" >/dev/null
done
grep "SCALE" "$OUT/run.txt"
rm -f "$STEPS"; ls "$OUT"
