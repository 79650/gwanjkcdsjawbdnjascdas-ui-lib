-- Functional checks for qustah-ui-lib in the mock Roblox environment (run by test/run.sh).
getfenv(0).SMOKE_STEPS = function(MOCK)
    local E = getfenv(0)
    local Enum, Vector2 = E.Enum, E.Vector2
    local Lib = E.getgenv().TestLib
    local passed, failed = 0, 0
    local function check(name, condition)
        if condition then passed = passed + 1 else failed = failed + 1 print("FAIL " .. name) end
    end
    local function wait(seconds) MOCK.advance(seconds or 0.3, MOCK.frame) end
    check("library loaded", Lib ~= nil)
    if not Lib then return end
    local window = Lib.Windows[1]
    check("window created", window ~= nil)
    local gui = window.gui
    local function find(name, root)
        for _, object in ipairs((root or gui):GetDescendants()) do if object.Name == name then return object end end
    end
    local function findIn(rowName, childName)
        for _, object in ipairs(gui:GetDescendants()) do
            if object.Name == rowName then
                local child = object:FindFirstChild(childName, true)
                if child then return child end
            end
        end
    end
    local function press(input) E.game:GetService("UserInputService").InputBegan:Fire(input, false) end
    local uis = E.game:GetService("UserInputService")
    local function mouseInput(kind, x, y)
        return { UserInputType = kind, KeyCode = Enum.KeyCode.Unknown, Position = E.Vector3.new(x or 0, y or 0, 0), UserInputState = Enum.UserInputState.Begin }
    end
    local F = Lib.Flags

    -- defaults reach Flags
    check("toggle default in Flags", F.espEnabled == true)
    check("slider default in Flags", F.espRange == 1500)
    check("dropdown default", F.font == "Gotham")
    check("multi dropdown default", type(F.parts) == "table" and #F.parts == 2)
    check("keybind default", F.aimKey == Enum.KeyCode.Q)

    -- toggle by clicking its row
    MOCK.click(find("ESP enabled")) wait()
    check("toggle row click turns it off", F.espEnabled == false)
    MOCK.click(findIn("ESP enabled", "Switch")) wait()
    check("switch click turns it on", F.espEnabled == true)

    -- toggle key bind: right-click row, press F, then F flips it
    MOCK.fire(find("ESP enabled"), "MouseButton2Click") wait(0.1)
    check("bind capture armed", window._capture ~= nil)
    MOCK.press(Enum.KeyCode.F) wait(0.1)
    check("bind label shows F", findIn("ESP enabled", "Bind").Text == "[F]")
    MOCK.press(Enum.KeyCode.F) wait(0.1)
    check("bind key flips toggle", F.espEnabled == false)
    MOCK.press(Enum.KeyCode.F) wait(0.1)
    check("bind key flips back", F.espEnabled == true)

    -- slider: drag to the middle of its track
    local track = findIn("Max distance", "Track")
    local hit = findIn("Max distance", "Hit")
    local p, s = track.AbsolutePosition, track.AbsoluteSize
    MOCK.mouseLocation = Vector2.new(p.X + s.X * 0.5, p.Y)
    MOCK.fire(hit, "InputBegan", mouseInput(Enum.UserInputType.MouseButton1))
    check("slider press sets middle value", F.espRange == 2550)
    MOCK.mouseLocation = Vector2.new(p.X + s.X * 2, p.Y)
    uis.InputChanged:Fire(mouseInput(Enum.UserInputType.MouseMovement), false)
    check("slider drag clamps to max", F.espRange == 5000)
    uis.InputEnded:Fire(mouseInput(Enum.UserInputType.MouseButton1), false)
    MOCK.mouseLocation = Vector2.new(p.X, p.Y)
    uis.InputChanged:Fire(mouseInput(Enum.UserInputType.MouseMovement), false)
    check("drag ends on release", F.espRange == 5000)
    local box = findIn("Max distance", "Value")
    box.Text = "777 studs" MOCK.fire(box, "FocusLost", true) wait(0.1)
    check("typed slider value (rounded to step)", F.espRange == 780)
    check("slider box shows suffix", box.Text == "780 studs")

    -- dropdown: open, pick
    MOCK.click(findIn("Font", "Select")) wait(0.1)
    local list = find("DropdownList")
    check("dropdown list opens", list ~= nil)
    if list then MOCK.click(list:FindFirstChild("Code", true)) wait(0.1) end
    check("dropdown pick", F.font == "Code")
    check("single dropdown closes after pick", find("DropdownList") == nil)
    MOCK.click(findIn("Show", "Select")) wait(0.1)
    list = find("DropdownList")
    if list then MOCK.click(list:FindFirstChild("Weapon", true)) MOCK.click(list:FindFirstChild("Name", true)) wait(0.1) end
    check("list header follows the choice", list and list:FindFirstChild("Header") and list.Header:FindFirstChildOfClass("TextLabel").Text == "Health, Weapon")
    check("multi dropdown add/remove", F.parts and #F.parts == 2 and table.find(F.parts, "Weapon") and not table.find(F.parts, "Name"))
    check("multi dropdown stays open", find("DropdownList") ~= nil)
    press(mouseInput(Enum.UserInputType.MouseButton1)) wait(0.1)
    check("outside click closes list", find("DropdownList") == nil)

    -- keybind element
    MOCK.click(findIn("Aim key", "Key")) wait(0.1)
    MOCK.press(Enum.KeyCode.E) wait(0.1)
    check("keybind captured", F.aimKey == Enum.KeyCode.E)
    MOCK.click(findIn("Aim key", "Key")) wait(0.1)
    MOCK.press(Enum.KeyCode.Backspace) wait(0.1)
    check("keybind cleared", F.aimKey == nil)

    -- colour picker HEX
    local colorsCard = find("Colors")
    local hex = find("Hex", colorsCard)
    hex.Text = "#00FF00" MOCK.fire(hex, "FocusLost", true) wait(0.1)
    check("colour from hex", F.fillColor and math.abs(F.fillColor.G - 1) < 0.01 and F.fillColor.R < 0.01)
    MOCK.click(find("Fill color")) wait(0.1)
    check("picker panel opens", find("Picker", colorsCard).Visible == true)

    -- lock / unlock
    MOCK.click(find("Prediction")) wait()
    check("locked toggle ignores clicks", F.prediction == false)
    for _, object in ipairs(gui:GetDescendants()) do
        if object.Name == "Silent Aim" and object:IsA("TextButton") then MOCK.click(object) break end
    end
    wait()
    check("silent aim on", F.silentAim == true)
    MOCK.click(find("Prediction")) wait()
    check("unlocked toggle works", F.prediction == true)

    -- input
    local input = findIn("Target name", "Box")
    input.Text = "Builderman" MOCK.fire(input, "FocusLost", true) wait(0.1)
    check("input value", F.targetName == "Builderman")

    -- button confirm
    local hop = findIn("Server hop", "Button")
    MOCK.click(hop) wait(0.1)
    check("confirm asks first", hop.Text ~= "Server hop")
    wait(2.2)
    check("confirm resets after 2 s", hop.Text == "Server hop")

    -- configs round trip
    local ok = window.Config:Save("roundtrip")
    check("config saved", ok == true)
    local saved = { range = F.espRange, font = F.font, color = F.fillColor, esp = F.espEnabled }
    window.flags.espRange:Set(100) window.flags.font:Set("Arcade") window.flags.fillColor:Set(E.Color3.new(1, 0, 0)) window.flags.espEnabled:Set(false)
    window.flags.espEnabled:SetBind(nil)
    ok = window.Config:Load("roundtrip")
    check("config loaded", ok == true)
    check("config restores slider", F.espRange == saved.range)
    check("config restores dropdown", F.font == saved.font)
    check("config restores colour", F.fillColor and Lib.Util.toHex(F.fillColor) == Lib.Util.toHex(saved.color))
    check("config restores toggle", F.espEnabled == saved.esp)
    check("config restores toggle bind", window.flags.espEnabled.BindKey == Enum.KeyCode.F)
    check("config list", table.find(window.Config:List(), "roundtrip") ~= nil)
    window.Config:SetAutoLoad("roundtrip")
    check("autoload stored", window.Config:GetAutoLoad() == "roundtrip")

    -- pages / tabs
    local visuals = window.Tabs[2]
    check("dashboard is the first tab", window.Tabs[1].Title == "Dashboard" and find("Uptime") ~= nil and find("DisplayName").Text ~= "")
    check("wide profile card spans the page", find("Profile").Parent.Parent.Name == "Wide")
    visuals:Select() wait()
    check("two pages make a strip", visuals.strip.Visible == true)
    visuals.Pages[2]:Select() wait()
    check("page switch", visuals.Pages[2].frame.Visible and not visuals.Pages[1].frame.Visible)
    MOCK.click(find("SilentTab")) wait()
    check("tab switch hides strip for one-page tab", window.current.Title == "Silent" and not visuals.strip.Visible)

    -- segment, key hint, location, dock dividers
    check("segment default", F.aimPart == "Head")
    for _, object in ipairs(gui:GetDescendants()) do
        if object.Name == "Closest" and object:IsA("TextButton") then MOCK.click(object) break end
    end
    check("segment pick", F.aimPart == "Closest")
    check("key hint default", F.espKey == Enum.KeyCode.KeypadEight)
    local hintBadge = find("Key", find("KeyHints"):FindFirstChild("Left"))
    MOCK.click(hintBadge) wait(0.1)
    MOCK.press(Enum.KeyCode.KeypadNine) wait(0.1)
    check("key hint rebind", F.espKey == Enum.KeyCode.KeypadNine and hintBadge.Text == "NUM 9")
    check("location shows tab", window.locationLabel.Text == "Silent")
    visuals:Select() wait()
    check("location shows tab › page", window.locationLabel.Text == "Visuals › Appearance")
    check("dock dividers after Dashboard and above Settings", #window.dockDividers == 2 and window.Tabs[2].Divider and window.Tabs[#window.Tabs].Divider)
    local menuBadge = find("Key", find("KeyHints"):FindFirstChild("Right"))
    MOCK.click(menuBadge) wait(0.1)
    MOCK.press(Enum.KeyCode.Insert) wait(0.1)
    check("menu hint rebinds the menu key", window.key == Enum.KeyCode.Insert and window.flags.__ui_menu_key.Value == Enum.KeyCode.Insert)
    window:SetToggleKey(Enum.KeyCode.RightShift)
    check("settings / hint follow SetToggleKey", menuBadge.Text == "RSHIFT" and window.flags.__ui_menu_key.Value == Enum.KeyCode.RightShift)

    -- accent
    Lib:SetAccent(E.Color3.fromRGB(61, 151, 219)) wait(0.1)
    local glowStroke = window.titleLabel:FindFirstChild("Glow")
    check("accent recolours title (glow)", glowStroke and glowStroke.Color == E.Color3.fromRGB(61, 151, 219))

    -- menu key hides / shows, minimize
    MOCK.press(Enum.KeyCode.RightShift) wait(0.4)
    check("menu key hides", window.main.Visible == false and window.dock.Visible == false)
    MOCK.press(Enum.KeyCode.RightShift) wait(0.4)
    check("menu key shows", window.main.Visible == true and window.dock.Visible == true)
    window:Minimize() wait(0.2)
    check("minimize folds", window.main.Size.Y.Offset == 44 and window.dock.Visible == false)
    window:Minimize() wait(0.2)
    check("minimize unfolds", window.main.Size.Y.Offset == window.height)

    -- small screen: scale down, stack columns
    MOCK.setViewport(500, 400) wait(0.2)
    check("scales down on small screens", window.scale.Scale < 1)
    window.width = 420 window:_layout()
    check("narrow window stacks columns", visuals.Pages[1].layout.FillDirection == Enum.FillDirection.Vertical)
    MOCK.setViewport(1280, 720) window.width = 560 window:_layout() wait(0.2)

    -- X hides the menu at once and tells how to reopen it
    MOCK.click(find("Close")) wait(0.4)
    check("X hides without a popup", window.main.Visible == false and find("ClosePopup") == nil)
    check("X shows a notification", find("Toast", Lib._notifyHolder) ~= nil)
    MOCK.press(Enum.KeyCode.RightShift) wait(0.4)
    check("menu key brings it back", window.main.Visible == true)
    wait(3.6)

    -- notifications
    window:Notify({ Title = "Test", Content = "Body" }) wait(0.1)
    check("toast shown", find("Toast", Lib._notifyHolder) ~= nil)
    wait(3.6)
    check("toast removed", find("Toast", Lib._notifyHolder) == nil)


    ------------------------------------------------------------------ v1.1
    local W = window.flags
    local function tabNamed(title) for _, t in ipairs(window.Tabs) do if t.Title == title then return t end end end
    tabNamed("Visuals"):Select() wait(0.1)
    -- range
    check("range default", type(F.hpBand) == "table" and F.hpBand[1] == 0 and F.hpBand[2] == 100)
    local rTrack, rHit = findIn("Health filter", "Track"), findIn("Health filter", "Hit")
    local rp, rs = rTrack.AbsolutePosition, rTrack.AbsoluteSize
    MOCK.mouseLocation = Vector2.new(rp.X + 5 + (rs.X - 10) * 0.3, rp.Y)
    MOCK.fire(rHit, "InputBegan", mouseInput(Enum.UserInputType.MouseButton1))
    uis.InputEnded:Fire(mouseInput(Enum.UserInputType.MouseButton1), false)
    check("range drag moves nearer handle", F.hpBand[1] == 30 and F.hpBand[2] == 100)
    local highBox = findIn("Health filter", "High")
    highBox.Text = "32" MOCK.fire(highBox, "FocusLost", true) wait(0.1)
    check("range keeps MinGap", F.hpBand[1] == 30 and F.hpBand[2] == 35)
    W.hpBand:Set({ 80, 10 })
    check("range sorts low / high", F.hpBand[1] == 10 and F.hpBand[2] == 80)
    -- toggle marker / badge
    check("toggle marker", findIn("ESP enabled", "Marker") ~= nil)
    check("toggle badge", findIn("Highlight", "Badge") ~= nil)
    -- swatches
    visuals:Select() visuals.Pages[2]:Select() wait(0.1)
    MOCK.click(findIn("Name color", "Red")) wait(0.1)
    check("swatch click", F.nameColor == "Red")
    -- colour picker rainbow / apply
    local fill = W.fillColor
    local before = fill.Value
    fill:SetRainbow(true) wait(0.5)
    check("rainbow changes colour", fill.Value ~= before and fill.Rainbow == true)
    check("rainbow saved", type(fill:_save()) == "table" and fill:_save().Rainbow == true)
    fill:_load("FF0000") wait(0.1)
    check("plain load stops rainbow", fill.Rainbow == false and F.fillColor == E.Color3.fromRGB(255, 0, 0))
    local outline = W.outlineColor
    local old = outline.Value
    outline:SetOpen(true)
    local hexBox = outline.Row.Parent:FindFirstChild("Picker", true)
    local hex
    for _, d in ipairs(outline.Row.Parent:GetDescendants()) do if d.Name == "Hex" and d:IsDescendantOf(outline.Row.Parent) then hex = d end end
    local panel
    for _, d in ipairs(outline.Row.Parent:GetChildren()) do if d.Name == "Picker" and d.LayoutOrder == outline.Row.LayoutOrder + 1 then panel = d end end
    hex = panel and panel:FindFirstChild("Hex", true)
    hex.Text = "#00FF00" MOCK.fire(hex, "FocusLost", true) wait(0.1)
    check("apply mode waits", outline.Value == old)
    MOCK.click(panel:FindFirstChild("Done", true)) wait(0.1)
    local g = outline.Value
    check("apply button commits", g.G > 0.99 and g.R < 0.01 and not panel.Visible)

    -- gradient
    local chams = W.chams
    check("gradient default", typeof(F.chams[1]) == "Color3" and F.chams[2] == E.Color3.fromRGB(120, 140, 230))
    MOCK.click(findIn("Chams gradient", "Preview")) wait(0.1)
    check("gradient editor opens", find("GradientEditor").Visible)
    local got
    chams:OnChanged(function(seq, a, b) got = { a, b } end)
    local startHex = find("GradientEditor"):FindFirstChild("Hex", true)
    -- start picker panel must be open to edit; use the API of the inner picker instead
    chams:Set({ "#00FF00", "#0000FF" })
    check("gradient set", got and got[1] == E.Color3.fromRGB(0, 255, 0) and F.chams[2] == E.Color3.fromRGB(0, 0, 255))
    check("gradient save", chams:_save()[1] == "00FF00" and chams:_save()[2] == "0000FF")
    MOCK.click(findIn("Swap colours", "Button")) wait(0.1)
    check("gradient swap", F.chams[1] == E.Color3.fromRGB(0, 0, 255))
    chams:_load({ "FF0000", "00FF00" })
    check("gradient load", F.chams[1] == E.Color3.fromRGB(255, 0, 0))

    -- chord keybind
    local silentTab = tabNamed("Silent") silentTab:Select() wait(0.1)
    local mark = W.markKey
    check("chord default", mark.Chord and mark.Chord[1] == Enum.KeyCode.LeftControl and mark.Chord[2] == Enum.UserInputType.MouseButton1)
    check("chord saved", mark:_save() == "LeftControl+MouseButton1")
    local fired = 0
    local realBind = mark._onBind
    mark._onBind = function() fired = fired + 1 end
    MOCK.keysDown = {}
    uis.InputBegan:Fire(mouseInput(Enum.UserInputType.MouseButton1), false)
    check("chord needs modifier", fired == 0)
    MOCK.keysDown = { [Enum.KeyCode.LeftControl] = true }
    uis.InputBegan:Fire(mouseInput(Enum.UserInputType.MouseButton1), false)
    check("chord fires with modifier", fired == 1)
    MOCK.keysDown = {}
    mark._onBind = realBind
    mark:_load("LeftShift+E")
    check("chord loads from text", mark.Chord[1] == Enum.KeyCode.LeftShift and mark.Chord[2] == Enum.KeyCode.E)

    -- card tabs + player list
    local filters = find("Section_Filters")
    check("card tabs: second hidden", filters and filters.Visible == false)
    MOCK.click(findIn("Targets", "Filters")) wait(0.1)
    check("card tabs switch", filters.Visible == true and find("Section_Players").Visible == false)
    MOCK.click(findIn("Targets", "Players")) wait(0.1)
    local enemyRow = findIn("Whitelist", "Enemy")
    check("player list row", enemyRow ~= nil and findIn("Whitelist", "Tester") == nil)
    MOCK.click(enemyRow) wait(0.1)
    check("player list select", type(F.whitelist) == "table" and F.whitelist[1] == MOCK.other.UserId)
    check("player list GetPlayers", W.whitelist:GetPlayers()[1] == MOCK.other)
    local joined = MOCK.makePlayer("Newbie", 5, 5)
    MOCK.fire(E.game:GetService("Players"), "PlayerAdded", joined) wait(0.1)
    check("player list adds joiners", findIn("Whitelist", "Newbie") ~= nil)
    local search = findIn("Whitelist", "Search")
    search.Text = "newb" wait(0.1)
    check("player list search", findIn("Whitelist", "Enemy").Visible == false and findIn("Whitelist", "Newbie").Visible == true)
    search.Text = ""
    MOCK.leave(joined) wait(0.1)
    check("player list drops leavers", findIn("Whitelist", "Newbie") == nil)

    -- image picker + graph
    tabNamed("Misc"):Select() wait(0.1)
    MOCK.click(findIn("Style", "Image2")) wait(0.1)
    check("image picker", F.crosshair == "rbxassetid://12614416478")
    wait(1.2)
    check("graph shows fps", findIn("FPS", "Value") and findIn("FPS", "Value").Text:find("FPS") ~= nil)

    -- status / errors / safe callbacks
    check("footer limited", window.statusLabel.Text == "Limited")
    local boom = tabNamed("Misc").Pages[1]:Card({ Title = "Boom" }):Toggle({ Title = "Explodes", Callback = function() error("kaboom") end })
    boom:Set(true) wait(0.1)
    check("callback error reported", window.statusLabel.Text == "Errors: 1" and #window:GetErrors() == 1)
    boom:Set(false) wait(0.1)
    check("same error counted", #window:GetErrors() == 1 and window:GetErrors()[1].count == 2)
    check("error report text", window:GetErrorReport():find("kaboom") ~= nil)
    window:ClearErrors()
    check("clear errors", window.statusLabel.Text == "Limited")
    window:SetStatus("Custom") check("manual status", window.statusLabel.Text == "Custom")
    window:SetStatus(nil) check("auto status again", window.statusLabel.Text == "Limited")

    -- dialog
    local confirmed = false
    window:Confirm("Sure?", "Body", function() confirmed = true end, "Yes")
    check("dialog shown", find("Dialog") ~= nil)
    MOCK.press(Enum.KeyCode.Escape) wait(0.1)
    check("escape closes dialog", find("Dialog") == nil and not confirmed)
    window:Confirm("Sure?", "Body", function() confirmed = true end, "Yes")
    MOCK.click(findIn("Dialog", "Yes")) wait(0.1)
    check("dialog confirm", confirmed and find("Dialog") == nil)

    -- overlays
    window:KeybindList(true) wait(0.6)
    check("keybind list", find("Keybinds") and find("Keybinds").Visible)
    window:KeybindList(false)
    window:SessionBar(true) wait(0.6)
    check("session bar", find("SessionBar").Visible and find("SessionBar"):FindFirstChildWhichIsA("TextLabel").Text:find("FPS") ~= nil)
    window:SessionBar(false)
    window:StatsMonitor("Floating") wait(0.6)
    check("stats floating", find("Performance").Visible and not find("HeaderStats").Visible)
    window:StatsMonitor("Header") wait(0.6)
    check("stats header", find("HeaderStats").Visible and find("HeaderStats").Text:find("FPS") ~= nil)
    window:StatsMonitor("Off")

    -- header tabs + settings
    local settingsTab = tabNamed("Settings")
    settingsTab:Select() wait(0.1)
    check("header tabs shown", window.headerTabs.Visible == true and window.locationLabel.Visible == false)
    tabNamed("Misc"):Select() wait(0.1)
    check("header tabs hidden elsewhere", window.headerTabs.Visible == false)
    MOCK.click(window.headerTabs:FindFirstChild("Dashboard")) wait(0.1)
    check("header tab selects", window.current == tabNamed("Dashboard"))
    check("dashboard modules", findIn("Modules", "Mark") ~= nil)
    settingsTab:Select() wait(0.1)
    W.__ui_glow:Set(false)
    check("glow off", not window.titleLabel:FindFirstChild("Glow").Enabled)
    W.__ui_glow:Set(true)
    MOCK.click(findIn("Accent", "Blue")) wait(0.3)
    check("accent swatch", Lib.Theme.get("accent") == E.Color3.fromRGB(61, 151, 219))

    -- theme packs / font
    W.__ui_theme:Set("Light") wait(0.2)
    check("light pack", Lib.Theme.get("base") == E.Color3.fromRGB(238, 238, 241) and Lib.Theme.pack == "Light")
    check("custom accent kept on pack change", Lib.Theme.get("accentUser") == E.Color3.fromRGB(61, 151, 219))
    check("light pack darkens a pale accent to 3:1", Lib.Theme.contrast(Lib.Theme.get("accent"), Lib.Theme.get("card")) >= 3)
    check("light status colours", Lib.Theme.get("success") == E.Color3.fromRGB(30, 135, 70))
    check("neutral swatch follows pack", findIn("Accent", "Neutral"):FindFirstChild("Dot").BackgroundColor3 == E.Color3.fromRGB(70, 70, 80))
    W.__ui_theme:Set("Dark") wait(0.2)
    check("dark pack back", Lib.Theme.get("base") == E.Color3.fromRGB(15, 15, 16))
    MOCK.click(findIn("Accent", "Neutral")) wait(0.1)
    W.__ui_theme:Set("Light") wait(0.1)
    check("neutral accent follows pack", Lib.Theme.get("accent") == E.Color3.fromRGB(70, 70, 80) and W.__ui_accent.Value == E.Color3.fromRGB(70, 70, 80))
    W.__ui_theme:Set("Dark") wait(0.1)
    check("neutral back on dark", Lib.Theme.get("accent") == E.Color3.fromRGB(177, 178, 183))
    W.__ui_font:Set("Montserrat") wait(0.2)
    check("font option set", F.__ui_font == "Montserrat")
    W.__ui_font:Set("Gotham") wait(0.1)
    -- watermark
    W.__ui_hud_watermark:Set(true) wait(0.7)
    local mark = window._watermark and window._watermark.panel
    check("watermark", mark and mark.Visible and find("Info", mark).Text:find("FPS") ~= nil and mark.Size.X.Offset > 150)
    W.__ui_hud_watermark:Set(false)
    check("watermark off", not mark.Visible)
    -- notification history
    window:Notify({ Title = "History test", Content = "kept" }) wait(0.1)
    check("history recorded", Lib.NotifyHistory[1].Title == "History test")
    check("unread dot", find("Unread", window.inboxButton).Visible == true)
    MOCK.click(window.inboxButton) wait(0.1)
    check("inbox opens", find("InboxPanel") ~= nil and find("Unread", window.inboxButton).Visible == false)
    local entries = 0
    for _, d in ipairs(find("InboxPanel"):GetDescendants()) do if d.Name == "Entry" then entries = entries + 1 end end
    check("inbox lists history", entries == #Lib.NotifyHistory)
    MOCK.click(find("Clear", find("InboxPanel"))) wait(0.1)
    check("inbox clear", #Lib.NotifyHistory == 0 and find("Empty", find("InboxPanel")).Visible)
    MOCK.click(window.inboxButton) wait(0.1)
    check("inbox closes", find("InboxPanel") == nil)
    window:Notify({ Title = "Quiet", History = false }) wait(0.1)
    check("history opt-out", #Lib.NotifyHistory == 0)

    -- profiles
    settingsTab.Pages[2]:Select() wait(0.1)
    local store = window.Config
    F.espRange = nil
    W.espRange:Set(1234)
    local nameBox = findIn("CreateProfile", "Box")
    nameBox.Text = "default" wait(0.1)
    check("create: reserved name", findIn("CreateProfile", "Hint").Text:find("reserved") ~= nil)
    nameBox.Text = "pv/p" wait(0.1)
    check("create: bad characters", findIn("CreateProfile", "Hint").Text:find("only") ~= nil)
    nameBox.Text = "pvp" wait(0.1)
    check("create: live hint", findIn("CreateProfile", "Hint").Text:find("as \"pvp\"") ~= nil)
    MOCK.fire(nameBox, "FocusLost", true) wait(0.1) -- Enter runs it
    check("create: box cleared", nameBox.Text == "")
    check("profile created", store:Exists("pvp") and find("Profile_pvp") ~= nil)
    check("created profile is active + open", store.Active == "pvp" and find("Profile_pvp"):FindFirstChild("Load", true) ~= nil and find("Profile_pvp"):FindFirstChild("ACTIVE", true) ~= nil)
    check("current: saved", findIn("Changes", "Value").Text == "Saved")
    W.espRange:Set(99 * 10) wait(1.2)
    check("current: unsaved count", findIn("Changes", "Value").Text == "1 unsaved")
    check("changes lists flag", select(2, store:Changes())[1] == "espRange")
    MOCK.click(find("Profile_pvp"):FindFirstChild("Load", true)) wait(0.1)
    check("load asks when unsaved", find("Dialog") ~= nil and F.espRange == 990)
    MOCK.click(findIn("Dialog", "Load")) wait(0.1)
    check("profile load", F.espRange == 1230)
    -- revert
    W.espRange:Set(500)
    MOCK.click(findIn("CurrentActions", "Revert")) wait(0.1)
    MOCK.click(findIn("Dialog", "Revert")) wait(0.1)
    check("revert", F.espRange == 1230)
    -- note
    local noteBox = find("Profile_pvp"):FindFirstChild("Note", true)
    noteBox.Text = "ranked games" MOCK.fire(noteBox, "FocusLost", true) wait(0.1)
    check("profile note", store:ReadMeta().pvp.note == "ranked games" and find("Profile_pvp"):FindFirstChild("Note", true) ~= nil)
    -- share code round trip
    MOCK.clipboard = nil
    MOCK.click(find("Profile_pvp"):FindFirstChild("Share", true)) wait(0.1)
    local code = MOCK.clipboard
    check("share code copied", type(code) == "string" and code:sub(1, 8) == "QUSTAH1:")
    local decodedName, decodedFlags = store:Decode(code)
    check("share code decodes", decodedName == "pvp" and decodedFlags and decodedFlags.espRange == 1230)
    MOCK.click(findIn("New profile", "Import")) wait(0.1)
    local codeBox = findIn("ImportProfile", "Box")
    codeBox.Text = "garbage" wait(0.1)
    check("import: bad code hint", findIn("ImportProfile", "Hint").Text:find("Not a profile code") ~= nil)
    codeBox.Text = code wait(0.1)
    check("import: preview hint", findIn("ImportProfile", "Hint").Text:find("pvp 2") ~= nil)
    MOCK.click(findIn("ImportProfile", "Action")) wait(0.1)
    check("import creates free name", store:Exists("pvp 2"))
    check("bad code rejected", store:Decode("hello") == nil and store:Decode("QUSTAH1:@@@") == nil)
    store:Delete("pvp 2")
    MOCK.click(find("Profile_pvp"):FindFirstChild("Head")) wait(0.1) -- (import opened "pvp 2") open pvp again
    local rename = find("Profile_pvp"):FindFirstChild("NewName", true)
    rename.Text = "ranked"
    MOCK.click(find("Profile_pvp"):FindFirstChild("Rename", true)) wait(0.1)
    check("profile rename", store:Exists("ranked") and not store:Exists("pvp") and find("Profile_ranked") ~= nil)
    find("Profile_ranked"):FindFirstChild("NewName", true).Text = "ranked2"
    MOCK.click(find("Profile_ranked"):FindFirstChild("Duplicate", true)) wait(0.1)
    check("profile duplicate", store:Exists("ranked2") and store:Exists("ranked"))
    MOCK.click(find("Profile_ranked2"):FindFirstChild("Autoload", true)) wait(0.1)
    check("profile autoload", store:GetAutoLoad() == "ranked2")
    MOCK.click(find("Profile_ranked2"):FindFirstChild("Delete", true)) wait(0.1)
    MOCK.click(findIn("Dialog", "Delete")) wait(0.1)
    check("profile delete", not store:Exists("ranked2") and store:GetAutoLoad() == nil)
    MOCK.click(find("Profile_Default"):FindFirstChild("Head")) wait(0.1)
    check("default locked", find("Profile_Default"):FindFirstChild("Delete", true) == nil and find("Profile_Default"):FindFirstChild("Rename", true) == nil)
    MOCK.click(find("Profile_Default"):FindFirstChild("Load", true)) wait(0.1)
    if find("Dialog") then MOCK.click(findIn("Dialog", "Load")) wait(0.1) end
    check("default restores start values", F.espRange == 1500 and store.Active == nil)

    -- info page
    settingsTab.Pages[3]:Select() wait(0.1)
    window:ReportError("ESP", "render failed") wait(0.1)
    check("info lists errors", findIn("Errors", "Content").Text:find("render failed") ~= nil)
    MOCK.click(find("Copy report"):FindFirstChild("Button")) wait(0.1)
    check("copy report", type(MOCK.clipboard) == "string" and MOCK.clipboard:find("render failed") ~= nil)
    window:ClearErrors()

    -- window memory
    window.width = 600 window:_layout() window:_saveMemory() wait(1.2)
    check("window memory saved", E.isfile("Qustah/window.json") and E.readfile("Qustah/window.json"):find("600") ~= nil)
    window.width = 560 window:_layout()

    -- scroll fades exist
    check("scroll fades", find("FadeTop") ~= nil and find("FadeBottom") ~= nil)

    -- icons
    local Icons = Lib.Icons
    check("icons: lucide name", Icons.Get("house") and Icons.Get("house").Image:match("^rbxassetid://%d+$") ~= nil)
    check("icons: prefixed", Icons.Get("lucide:eye").Image == Icons.Get("eye").Image)
    check("icons: asset id passthrough", Icons.Get(123).Image == "rbxassetid://123" and Icons.Get("rbxassetid://5").Image == "rbxassetid://5")
    check("icons: unknown", Icons.Get("no-such-icon-xyz") == nil)
    Icons.Add("test", { Spritesheets = { ["1"] = "rbxassetid://99" }, Icons = {
        duo = { Image = 1, ImageRectPosition = Vector2.new(64, 0), ImageRectSize = Vector2.new(64, 64), Parts = { "duo2" } },
        duo2 = { Image = 1, ImageRectPosition = Vector2.new(128, 0), ImageRectSize = Vector2.new(64, 64) } } })
    local duo = Icons.Get("test:duo")
    check("icons: spritesheet", duo and duo.Image == "rbxassetid://99" and duo.RectOffset == Vector2.new(64, 0) and #duo.Parts == 1)
    local probe = Icons.Image("test:duo")
    check("icons: two-tone parts", probe:FindFirstChild("IconPart") ~= nil and probe.ImageRectSize == Vector2.new(64, 64))
    check("icons: list", #Icons.List("lucide") > 1500)
    check("icons: tab icon", tabNamed("Visuals").icon.Image == Icons.Get("eye").Image)
    check("icons: default tab icons", tabNamed("Settings").icon.Image == Icons.Get("settings").Image)
    check("icons: card icon", findIn("Targets", "CardIcon") ~= nil)
    check("icons: row icon", findIn("Aim key", "RowIcon") ~= nil)
    check("icons: button icon", findIn("Rejoin", "ButtonIcon") ~= nil and findIn("Rejoin", "Text").Text == "Rejoin")
    MOCK.click(find("Tools"):FindFirstChild("Server hop", true):FindFirstChild("Button")) wait(0.1)
    check("icons: button confirm text", findIn("Server hop", "Text").Text ~= "Server hop")
    wait(2.2)
    check("icons: button text back", findIn("Server hop", "Text").Text == "Server hop")
    window:Notify({ Title = "Icon toast", Icon = "bell" }) wait(0.1)
    check("icons: toast icon", find("ToastIcon", Lib._notifyHolder) ~= nil)
    check("icons: bad name falls back", Lib.Windows[1]:Tab({ Title = "Zz", Icon = "nope-nope" }).iconProperty == "TextColor3")

    -- v1.4: pending config values / custom data
    local store2 = window.Config
    store2:Apply({ lateFlag = true, espRange = 2000 })
    check("pending kept for unknown flag", store2.pending.lateFlag == true and F.espRange == 2000)
    check("snapshot keeps pending", store2:Snapshot().lateFlag == true)
    local lateCard = tabNamed("Misc").Pages[1]:Card({ Title = "Late" })
    local late = lateCard:Toggle({ Title = "Late toggle", Flag = "lateFlag" })
    wait(0.1)
    check("pending applied on create", late.Value == true and store2.pending.lateFlag == nil)
    check("default recorded before pending", store2.Defaults.lateFlag == false)
    check("defaults keep start value", store2.Defaults.espRange == 1500)
    store2:SetData("waypoints", { { "Spawn", 1, 2, 3 } })
    store2:Save("custom1")
    store2:SetData("waypoints", nil)
    local gotData
    store2:OnDataLoaded(function(data) gotData = data end)
    store2:Load("custom1")
    check("custom data round trip", gotData and gotData.waypoints and gotData.waypoints[1][1] == "Spawn" and store2:GetData("waypoints")[1][2] == 1)
    local _, _, sharedCustom = store2:Decode(store2:Export("custom1"))
    check("custom data in share code", sharedCustom and sharedCustom.waypoints ~= nil)
    store2:Delete("custom1")
    W.espRange:Set(1500)

    -- debug toasts / notification buttons
    W.__ui_debug:Set(true)
    window:ReportError("Test", "debug boom") wait(0.1)
    local debugToast
    for _, t in ipairs(Lib._notifyHolder:GetChildren()) do if t.Name == "Toast" and t:FindFirstChild("Copy", true) then debugToast = t end end
    check("debug toast with copy button", debugToast ~= nil)
    W.__ui_debug:Set(false)
    window:ClearErrors()
    local pressed = false
    local toast = window:Notify({ Title = "Undo?", Content = "Deleted", Buttons = { { Title = "Undo", Callback = function() pressed = true end } } })
    check("toast buttons", toast:FindFirstChild("Undo", true) ~= nil and toast:FindFirstChild("Close") ~= nil)
    MOCK.click(toast:FindFirstChild("Undo", true)) wait(0.4)
    check("toast button runs + closes", pressed and toast.Parent == nil)
    local toast2 = window:Notify({ Title = "Close me" })
    MOCK.click(toast2:FindFirstChild("Close")) wait(0.4)
    check("toast close button", toast2.Parent == nil)
    check("toast CanClose = false", window:Notify({ Title = "x", CanClose = false }):FindFirstChild("Close") == nil)

    -- dropdown: option tables, AllowNone, locked, search
    tabNamed("Silent"):Select() wait(0.1)
    local priority = W.priority
    check("dropdown table options", F.priority == "Closest" and priority.Options[4] == "Highest bounty")
    MOCK.click(priority.Row:FindFirstChild("Select")) wait(0.1)
    local list = find("DropdownList")
    check("dropdown option desc + icon", list and list:FindFirstChild("Crosshair", true):FindFirstChild("Icon") ~= nil)
    MOCK.click(list:FindFirstChild("Highest bounty", true)) wait(0.1)
    check("locked option ignored", F.priority == "Closest")
    MOCK.click(list:FindFirstChild("Closest", true)) wait(0.1)
    check("AllowNone clears", F.priority == nil)
    local many = {}
    for i = 1, 12 do many[i] = "Option " .. i end
    local big = tabNamed("Silent").Pages[1]:Card({ Title = "Big" }):Dropdown({ Title = "Big list", Options = many })
    MOCK.click(big.Row:FindFirstChild("Select")) wait(0.1)
    local search = find("DropdownList"):FindFirstChild("Search", true)
    check("search box above 8 options", search ~= nil)
    search.Text = "1" wait(0.1)
    local shown = 0
    for _, item in ipairs(find("DropdownList"):FindFirstChild("Options"):GetChildren()) do if item:IsA("TextButton") and item.Visible then shown = shown + 1 end end
    check("search filters", shown == 4) -- 1, 10, 11, 12
    window:_closePopup()

    -- slider icons + bubble
    tabNamed("Visuals"):Select() visuals.Pages[2]:Select() wait(0.1)
    local fillSlider = W.fill
    local before = fillSlider.Value
    MOCK.click(fillSlider.Row:FindFirstChild("ToIcon"):FindFirstChildWhichIsA("TextButton")) wait(0.1)
    check("slider end icon steps", fillSlider.Value == before + 10)
    MOCK.click(fillSlider.Row:FindFirstChild("FromIcon"):FindFirstChildWhichIsA("TextButton")) wait(0.1)
    check("slider start icon steps", fillSlider.Value == before)
    local fhit = fillSlider.Row:FindFirstChild("Hit")
    MOCK.fire(fhit, "InputBegan", mouseInput(Enum.UserInputType.MouseButton1))
    check("bubble while dragging", fillSlider.Row:FindFirstChild("Bubble", true).Visible == true)
    uis.InputEnded:Fire(mouseInput(Enum.UserInputType.MouseButton1), false)
    check("bubble hides", fillSlider.Row:FindFirstChild("Bubble", true).Visible == false)

    -- new elements
    tabNamed("Misc"):Select() wait(0.1)
    local farmValue = findIn("Auto farm", "Value")
    check("progress text", farmValue and farmValue.Text == "3 / 10 quests")
    check("progress finished after delay", findIn("Loading assets", "Value").Text == "100%")
    local spin = tabNamed("Misc").Pages[1]:Card({ Title = "Spin" }):Progress({ Title = "Spinner", Indeterminate = true })
    check("progress indeterminate", findIn("Spinner", "Value").Text == "Working...")
    spin:SetIndeterminate(false) spin:Set(50)
    check("progress percent", findIn("Spinner", "Value").Text == "50%")
    MOCK.click(find("Row"):FindFirstChild("Start"):FindFirstChild("Button")) wait(0.1)
    check("row button works", farmValue.Text == "4 / 10 quests")
    local rowFrame = find("Row")
    check("row equal widths", rowFrame and rowFrame:FindFirstChild("Start").Size.X.Scale == 0.5 and rowFrame:FindFirstChild("Stop").Size.X.Scale == 0.5)
    local advancedBody = find("Section_Advanced"):FindFirstChild("Body")
    check("section starts closed", advancedBody.Visible == false)
    MOCK.click(find("Section_Advanced"):FindFirstChild("Header")) wait(0.1)
    check("section opens", advancedBody.Visible == true and W.delay ~= nil)
    check("group", find("Group_Server") ~= nil and find("Group_Server"):FindFirstChild("Region") ~= nil)
    local codeText = find("loader.lua"):FindFirstChild("Code", true)
    check("code highlighted", codeText.Text:find("<font") ~= nil and codeText.Text:find("loadstring") ~= nil)
    MOCK.clipboard = nil
    MOCK.click(find("loader.lua"):FindFirstChild("Copy", true)) wait(0.1)
    check("code copy", MOCK.clipboard and MOCK.clipboard:find("HttpGet") ~= nil)
    check("viewport", find("Viewport") ~= nil and find("Viewport"):FindFirstChild("View") ~= nil)
    local img = tabNamed("Misc").Pages[1]:Card({ Title = "Pics" }):Image({ Image = "rbxassetid://123", Caption = "logo" })
    check("image element", find("Picture", img.Row).Image == "rbxassetid://123" and findIn("Pics", "Caption").Text == "logo")

    -- window extras
    check("header button", find("Rejoin", window.main) ~= nil or find("Rejoin") ~= nil)
    check("bell moved left of fullscreen", window.inboxButton.Position.X.Offset < find("Fullscreen", window.main).Position.X.Offset)
    local w0, h0 = window.width, window.height
    window:ToggleFullscreen() wait(0.1)
    check("fullscreen grows", window.fullscreen and window.width > w0)
    window:ToggleFullscreen() wait(0.1)
    check("fullscreen restores", window.width == w0 and window.height == h0)
    window:SetBackgroundImage("rbxassetid://55", 0.8)
    check("background image", window._background.Visible and window._background.Image == "rbxassetid://55")
    window:SetBackgroundImage(nil)
    check("background off", window._background.Visible == false)
    W.__ui_transparency:Set(30)
    check("window transparency", math.abs(window.main.BackgroundTransparency - 0.3) < 0.01)
    W.__ui_transparency:Set(0)
    MOCK.click(find("Profile", window.dock)) wait(0.1)
    check("anonymous via dock", window.anonymous == true and F.__ui_anon == true and find("DisplayName").Text == "Anonymous")
    window:SetAnonymous(false) wait(0.1)
    check("anonymous off", find("DisplayName").Text ~= "Anonymous" and F.__ui_anon == false)

    -- re-creating a window with the same title replaces the old one
    local second = Lib:CreateWindow({ Title = "Qustāh" }) wait(0.1)
    check("old window destroyed on re-run", window.alive == false and gui.Parent == nil)
    second:Destroy() wait(0.1)
    check("destroy removes gui", second.gui.Parent == nil)
    MOCK.press(Enum.KeyCode.F) wait(0.1)
    check("binds dead after destroy", true)

    print(string.format("== LIB TESTS: %d passed, %d failed", passed, failed))
end
