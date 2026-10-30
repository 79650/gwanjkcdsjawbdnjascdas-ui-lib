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
  local function hideTab(t) t:SetHidden(true) end
  tab("Dashboard") shot("dashboard")
  local V = tab("Visuals") V.Pages[1]:Select() shot("visuals")
  V.Pages[2]:Select() shot("appearance")
  tab("Combat") shot("combat")
  local P = tab("Player")
  -- (the renderer can't draw 3D: a stand-in figure inside the Viewport for the picture)
  for _, o in ipairs(P.Pages[1].frame:GetDescendants()) do
    if o:IsA("ViewportFrame") then
      local fig = Instance.new("ImageLabel")
      fig.BackgroundTransparency = 1 fig.Image = "rbxassetid://125020872044147" fig.ImageColor3 = Lib.Theme.get("muted")
      fig.AnchorPoint = Vector2.new(0.5, 0.5) fig.Position = UDim2.fromScale(0.5, 0.5) fig.Size = UDim2.fromOffset(96, 96) fig.Parent = o
    end
  end
  shot("player")
  tab("Live") shot("live")
  local C = tab("Components") C.Pages[1]:Select() shot("buttons")
  C.Pages[2]:Select() shot("inputs")
  C.Pages[3]:Select() shot("content")
  tab("Server") shot("server")
  local T = tab("Settings") T.Pages[1]:Select() shot("settings")
  w.flags.__ui_theme:Set("Tokyo Night") tab("Visuals") V.Pages[1]:Select() shot("tokyo")
  w.flags.__ui_theme:Set("Light") shot("light")
  tab("Live") shot("live_light")
  C.Pages[1]:Select() tab("Components") shot("buttons_light")
  w.flags.__ui_theme:Set("Dark")
  -- smart buttons caught mid-way (README "Smart buttons" image); a hidden tab so the dock stays the example's
  local B2 = w:Tab({ Title = "Smart", Icon = "zap" }) hideTab(B2)
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
  -- presets, key conflict, input validation, tab badges
  local F = w:Tab({ Title = "Aimbot", Icon = "swords" }) hideTab(F)
  local A = F:Card({ Title = "Aimbot" })
  A:Slider({ Title = "FOV", Flag = "shFov", Min = 10, Max = 500, Default = 120, Suffix = "px" })
  A:Slider({ Title = "Smoothness", Flag = "shSmooth", Min = 0, Max = 1, Step = 0.05, Default = 0.3 })
  A:Toggle({ Title = "Prediction", Flag = "shPred", Default = false })
  A:Presets({ { "Legit", { shFov = 80, shSmooth = 0.6, shPred = false } }, { "Rage", { shFov = 400, shSmooth = 0, shPred = true } } })
  local K = F:Card({ Title = "Keys", Side = "Right" })
  K:Toggle({ Title = "Fly", Bind = Enum.KeyCode.F })
  K:Toggle({ Title = "ESP", Bind = Enum.KeyCode.F })
  K:Keybind({ Title = "Noclip", Default = Enum.KeyCode.N })
  local V = F:Card({ Title = "Join friend", Side = "Right" })
  local job = V:Input({ Title = "Job ID", Placeholder = "paste id", Validate = function(t) if t == "" then return nil end return #t >= 8, #t >= 8 and "Looks good" or "At least 8 characters" end })
  wait(0.3)
  F:Select() wait()
  A.frame:FindFirstChild("Rage", true) -- (exists)
  w:SetFlag("shFov", 400) w:SetFlag("shSmooth", 0) w:SetFlag("shPred", true)
  MOCK.fire(job.Row.Box, "Focused") job.Row.Box.Text = "8f2a" wait(0.2)
  for _, t in ipairs(w.Tabs) do if t.Title == "Live" then t:SetBadge(3) elseif t.Title == "Server" then t:SetBadge(true, "danger") end end
  shot("features")
  MOCK.fire(job.Row.Box, "FocusLost", false)
  -- the tour, on its "Menu key" step
  tab("Dashboard")
  local tour = w:Tour(nil, { Id = "showcase" })
  tour:Go(4) wait(0.3)
  shot("tour")
  tour:Close()
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
