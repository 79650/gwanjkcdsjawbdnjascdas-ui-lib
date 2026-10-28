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
  tab("Server") shot("server")
  local T = tab("Settings") T.Pages[1]:Select() shot("settings")
  w.flags.__ui_theme:Set("Tokyo Night") tab("Visuals") V.Pages[1]:Select() shot("tokyo")
  w.flags.__ui_theme:Set("Light") shot("light")
  tab("Misc") shot("misc_light")
  tab("Silent") shot("silent_light")
  w.flags.__ui_theme:Set("Dark")
  -- button styles page (README "Buttons" image)
  local B = w:Tab({ Title = "Buttons", Icon = "mouse-pointer-click" })
  local S = B:Card({ Title = "Styles" })
  local styleRows = { { "Default", "refresh-cw", "Rejoin" }, { "Primary", "play", "Start farm" }, { "Soft", "sparkles", "Redeem codes" },
    { "Outline", "shuffle", "Server hop" }, { "Ghost", "rotate-ccw", "Reset to default" }, { "Danger", "trash-2", "Delete profile" }, { "Link", "external-link", "Open Discord" } }
  for _, r in ipairs(styleRows) do S:Button({ Title = r[3], Icon = r[2], Style = r[1] }) end
  local L = B:Card({ Title = "Sizes and layout", Side = "Right" })
  L:Button({ Title = "Small", Size = "Small", Icon = "minimize-2" })
  L:Button({ Title = "Large", Size = "Large", Style = "Primary", Icon = "zap" })
  local r1 = L:Row()
  r1:Button({ Title = "Rejoin", Icon = "refresh-cw" }) r1:Button({ Title = "Server hop", Icon = "shuffle" })
  local r2 = L:Row({ Widths = { 3, 1 } })
  r2:Button({ Title = "Save config", Icon = "save", Style = "Primary" }) r2:Button({ Icon = "trash-2", Style = "Danger" })
  local r3 = L:Row()
  for _, i in ipairs({ "play", "pause", "square", "skip-forward" }) do r3:Button({ Icon = i, Style = "Soft" }) end
  L:Button({ Title = "Next step", Icon = "arrow-right", IconSide = "Right", Style = "Outline" })
  L:Button({ Title = "Teleport to spawn", Icon = "map-pin", Align = "Left" })
  B:Select() wait() shot("buttons")
  w.flags.__ui_theme:Set("Light") shot("buttons_light")
  w.flags.__ui_theme:Set("Dark")
  local B2 = w:Tab({ Title = "Smart", Icon = "zap" })
  local X = B2:Card({ Title = "Smart buttons" })
  local cd = X:Button({ Title = "Server hop", Icon = "shuffle", Cooldown = 5 })
  local hd = X:Button({ Title = "Hold to wipe data", Icon = "trash-2", Style = "Danger", Hold = 1.5 })
  local ld = X:Button({ Title = "Redeem all codes", Icon = "gift", Callback = function() task.wait(30) end })
  local kr = X:Row()
  kr:Button({ Title = "Rejoin", Icon = "refresh-cw", Bind = Enum.KeyCode.R })
  kr:Button({ Title = "Auto farm", Icon = "sprout", Toggle = true, Default = true })
  local mr = X:Row({ Widths = { 3, 1 } })
  mr:Button({ Title = "Teleport", Icon = "map-pin", Menu = { "Spawn", "Shop", "Arena" }, Selected = "Shop" })
  mr:Button({ Icon = "inbox", Badge = 3, Style = "Soft" })
  local R = B2:Card({ Title = "Reset to default", Side = "Right" })
  local sp = R:Slider({ Title = "Walk speed", Flag = "showWalk", Min = 16, Max = 100, Default = 16, Suffix = " studs/s" })
  R:Slider({ Title = "Jump power", Flag = "showJump", Min = 0, Max = 200, Default = 50 })
  local fov = R:Toggle({ Title = "Show FOV circle", Flag = "showFov", Default = false })
  local tm = R:Dropdown({ Title = "Target part", Flag = "showPart", Options = { "Head", "Torso", "Random" }, Default = "Head" })
  wait(0.2)
  B2:Select() wait()
  fov:Set(true) tm:Set("Torso")
  sp:Set(42)
  MOCK.click(cd.Row.Button)
  MOCK.click(ld.Row.Button)
  MOCK.fire(hd.Row.Button, "InputBegan", MOCK.input(Enum.KeyCode.Unknown, Enum.UserInputType.MouseButton1))
  MOCK.advance(0.6, MOCK.frame)
  -- (the mock finishes tweens at their end: set the half-way fills by hand for the picture)
  cd.Row.Button.Fill.Size = UDim2.fromScale(0.88, 1)
  hd.Row.Button.Fill.Size = UDim2.fromScale(0.4, 1)
  w:_hideTip()
  GUI_DUMP(w.gui, "smart")
  local s = w.scale.Scale
  print(string.format("RECT %s %.1f,%.1f,%.1f,%.1f", "smart", w.topLeft.X - 14, w.topLeft.Y - 14, (w.width + 12 + 40) * s + 28, w.height * s + 28))
  print("SHOT smart")
  MOCK.fire(hd.Row.Button, "InputEnded", MOCK.input(Enum.KeyCode.Unknown, Enum.UserInputType.MouseButton1))
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
