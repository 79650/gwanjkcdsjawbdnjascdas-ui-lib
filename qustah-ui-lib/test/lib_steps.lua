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
    do
        local conflicts = {}
        for key, list in pairs(window:GetKeyConflicts()) do conflicts[#conflicts + 1] = key .. ": " .. table.concat(list, ", ") end
        if #conflicts > 0 then print("CONFLICTS", table.concat(conflicts, " | ")) end
        check("the example has no key conflicts", #conflicts == 0)
    end
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
    check("bind label shows F", findIn("ESP enabled", "Bind").Text == "F")
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
    -- multi lists react on press (InputBegan) so they can be drag-selected
    local function pressItem(item) MOCK.fire(item, "InputBegan", mouseInput(Enum.UserInputType.MouseButton1)) uis.InputEnded:Fire(mouseInput(Enum.UserInputType.MouseButton1), false) end
    if list then pressItem(list:FindFirstChild("Weapon", true)) pressItem(list:FindFirstChild("Name", true)) wait(0.1) end
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
    check("confirm asks first", hop:FindFirstChild("Text", true).Text ~= "Server hop")
    wait(2.2)
    check("confirm resets after 2 s", hop:FindFirstChild("Text", true).Text == "Server hop")

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
    MOCK.click(find("CombatTab")) wait()
    check("tab switch hides strip for one-page tab", window.current.Title == "Combat" and not visuals.strip.Visible)

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
    check("location shows tab", window.locationLabel.Text == "Combat")
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
    local silentTab = tabNamed("Combat") silentTab:Select() wait(0.1)
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
    tabNamed("Live"):Select() wait(0.1)
    MOCK.click(findIn("Crosshair style", "Image2")) wait(0.1)
    check("image picker", F.crosshair == "locate-fixed")
    wait(1.2)
    check("graph shows fps", findIn("FPS", "Value") and findIn("FPS", "Value").Text:find("FPS") ~= nil)

    -- status / errors / safe callbacks
    check("footer limited", window.statusText == "Limited")
    local boom = tabNamed("Live").Pages[1]:Card({ Title = "Boom" }):Toggle({ Title = "Explodes", Callback = function() error("kaboom") end })
    boom:Set(true) wait(0.1)
    check("callback error reported", window.statusText == "Errors: 1" and #window:GetErrors() == 1)
    boom:Set(false) wait(0.1)
    check("same error counted", #window:GetErrors() == 1 and window:GetErrors()[1].count == 2)
    check("error report text", window:GetErrorReport():find("kaboom") ~= nil)
    window:ClearErrors()
    check("clear errors", window.statusText == "Limited")
    window:SetStatus("Custom") check("manual status", window.statusText == "Custom")
    window:SetStatus(nil) check("auto status again", window.statusText == "Limited")

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
    tabNamed("Live"):Select() wait(0.1)
    check("header tabs hidden elsewhere", window.headerTabs.Visible == false)
    MOCK.click(window.headerTabs:FindFirstChild("Dashboard")) wait(0.1)
    check("header tab selects", window.current == tabNamed("Dashboard"))
    check("dashboard modules", findIn("Modules", "Tile_Mark") ~= nil)
    local markTile = findIn("Modules", "Tile_Mark")
    check("module tile pill", markTile and markTile:FindFirstChild("State").Text == "LIMITED")
    window:SetModule("ESP", "On", nil, { Icon = "eye", Tab = "Visuals" }) wait(0.1)
    local espTile = findIn("Modules", "Tile_ESP")
    check("module tile icon", espTile and espTile:FindFirstChild("Icon").Visible == true)
    MOCK.click(espTile) wait(0.1)
    check("module tile opens its tab", window.current == tabNamed("Visuals"))
    tabNamed("Dashboard"):Select() wait(0.1)
    local chips = find("Chips")
    check("profile chips", chips and chips:FindFirstChild("FPS") ~= nil and chips:FindFirstChild("Players"):FindFirstChild("Text").Text ~= "--")
    local vt = tabNamed("Visuals")
    vt:SetActive(true) wait()
    check("tab active dot", vt.button:FindFirstChild("ActiveDot") and vt.button.ActiveDot.Visible)
    vt:SetActive(false) wait()
    check("tab active dot hides", vt.button.ActiveDot.Visible == false)
    local gRow = tabNamed("Live"):Card({ Title = "GraphTiles" }):Row()
    local cg = gRow:Graph({ Title = "FPS", Style = "Line", Source = function() return 42 end, Compact = true, Height = 30 })
    check("compact graph: big value under the title", cg.Row:FindFirstChild("Value").TextSize == 17 and cg.Row:FindFirstChild("Area").Position.Y.Offset == 40)
    local mpage = tabNamed("Live").Pages[1]
    local tall = mpage:Card({ Title = "TallOne", Side = "Left" })
    for i = 1, 4 do tall:Toggle({ Title = "T" .. i }) end
    local short = mpage:Card({ Title = "ShortOne", Side = "Right" })
    short:Toggle({ Title = "S1" })
    mpage:MatchHeights(tall, short) wait(0.3)
    local sp = short.frame:FindFirstChild("MatchSpacer")
    check("match heights: spacer under the shorter card", sp and sp.Visible and sp.Size.Y.Offset > 50 and not tall.frame.MatchSpacer.Visible)
    tall.frame:Destroy() short.frame:Destroy()
    local wb = tabNamed("Live").Pages[1]:Card({ Title = "UnderColumns", Wide = "Bottom" })
    check("Wide = Bottom goes under the columns", wb.frame.Parent.Name == "WideBottom")
    wb.frame:Destroy()
    local det = find("Section_Details")
    check("ids folded under Details", det and det:FindFirstChild("Body").Visible == false and det:FindFirstChild("User ID", true) ~= nil)
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

    -- every theme pack: readable text, visible accent / switches
    local T = Lib.Theme
    local packIssues = {}
    for _, name in ipairs(T.packOrder) do
        W.__ui_theme:Set(name)
        local c = T.colors
        local function need(a, b, min, what)
            local ratio = T.contrast(c[a], c[b])
            if ratio < min then packIssues[#packIssues + 1] = string.format("%s %s %.2f", name, what or (a .. "/" .. b), ratio) end
        end
        need("text", "card", 4.5) need("heading", "card", 4.5) need("muted", "card", 3) need("text", "input", 4)
        need("icon", "dock", 3) need("accent", "card", 2.5) need("knob", "toggleOn", 1.4) need("buttonEdge", "card", 1.3)
        need("success", "card", 2.5) need("danger", "card", 2.5) need("warning", "card", 2.5)
    end
    for _, issue in ipairs(packIssues) do print("PACK ISSUE " .. issue) end
    check("all " .. #T.packOrder .. " packs readable", #packIssues == 0)
    check("palette pack brings its accent", (function() W.__ui_accent:Set(T.neutral("Dark")) W.__ui_theme:Set("Dracula") return T.get("accentUser") == T.hex("#bd93f9") end)())
    W.__ui_theme:Set("Dark")
    check("accent back to neutral", T.get("accentUser") == E.Color3.fromRGB(177, 178, 183))
    -- theme editor: save, list, export, import, delete
    local saveBox = findIn("SaveTheme", "Box")
    T.set("base", E.Color3.fromRGB(20, 10, 30))
    saveBox.Text = "Grape" MOCK.click(findIn("SaveTheme", "Action")) wait(0.1)
    check("custom theme saved", T.packs.Grape ~= nil and table.find(W.__ui_theme.Options, "Grape") ~= nil and F.__ui_theme == "Grape")
    check("custom theme on disk", E.readfile("Qustah/themes.json"):find("Grape") ~= nil)
    MOCK.clipboard = nil
    MOCK.click(find("Copy code"):FindFirstChild("Button")) wait(0.1)
    local themeCode = MOCK.clipboard
    check("theme code", type(themeCode) == "string" and themeCode:sub(1, 8) == "QTHEME1:")
    MOCK.click(find("Delete", find("Theme editor")):FindFirstChild("Button")) wait(0.1)
    MOCK.click(findIn("Dialog", "Delete")) wait(0.1)
    check("custom theme deleted", T.packs.Grape == nil and F.__ui_theme == "Dark")
    local importBox = findIn("ImportTheme", "Box")
    importBox.Text = themeCode wait(0.1)
    MOCK.click(findIn("ImportTheme", "Action")) wait(0.1)
    check("theme imported", T.packs.Grape ~= nil and F.__ui_theme == "Grape" and T.get("base") == E.Color3.fromRGB(20, 10, 30))
    W.__ui_theme:Set("Dark")

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
    MOCK.click(find("Copy debug info"):FindFirstChild("Button")) wait(0.1)
    check("copy debug info", type(MOCK.clipboard) == "string" and MOCK.clipboard:find("render failed") ~= nil and MOCK.clipboard:find("executor:", 1, true) ~= nil)
    local dbg = W.__ui_debug
    check("debug switch in the Errors header", dbg and dbg.Row.Name == "HeaderSwitch")
    local accentDots = findIn("Accent", "Custom colour")
    check("accent dots + custom dot", accentDots ~= nil and findIn("Accent", "Blue"):FindFirstChild("Dot").Size.X.Offset == 16)
    MOCK.click(accentDots) wait(0.1)
    check("custom dot opens the colour panel", W.__ui_accent.Row.Parent:FindFirstChild("Picker").Visible == true)
    MOCK.click(accentDots) wait(0.1)
    check("background visibility hidden without an image", W.__ui_bg_alpha.Row.Visible == false)
    W.__ui_bg:Set("123456") wait(0.1)
    check("background visibility shows with an image", W.__ui_bg_alpha.Row.Visible == true)
    W.__ui_bg:Set("") wait(0.1)
    W.__ui_glow:Set(false) wait(0.1)
    MOCK.click(find("Reset interface"):FindFirstChild("Button")) wait(0.1)
    if window._dialog then
        for _, d in ipairs(window._dialog.Frame:GetDescendants()) do if d:IsA("TextButton") and d.Text == "Reset" then MOCK.click(d) end end
    end
    wait(0.2)
    check("reset interface brings the defaults back", W.__ui_glow.Value == true)
    window:Count("Teleports") window:Count("Teleports") window:Count("Server hops", 3) wait(1.1)
    local sessionRows = findIn("This session", "Teleports")
    check("session counters", sessionRows and sessionRows:FindFirstChild("Value").Text == "2" and findIn("This session", "Server hops"):FindFirstChild("Value").Text == "3")
    check("lua memory row", findIn("This session", "Lua memory"):FindFirstChild("Value").Text:find("MB") ~= nil or findIn("This session", "Lua memory"):FindFirstChild("Value").Text == "unavailable")
    local vh = window:ShowVersionHistory() wait(0.1)
    check("version history dialog", window._dialog ~= nil and window._dialog.Frame:FindFirstChild("Content", true).Text:find("current", 1, true) ~= nil)
    if window._dialog then window._dialog:Close() end
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
    local confirmButton = tabNamed("Live").Pages[1]:Card({ Title = "ConfirmCard" }):Button({ Title = "Wipe all", Icon = "trash-2", Confirm = true })
    local toolsHop = confirmButton.Row.Button
    MOCK.click(toolsHop) wait(0.1)
    check("icons: button confirm text", toolsHop:FindFirstChild("Text", true).Text ~= "Wipe all")
    wait(2.2)
    check("icons: button text back", toolsHop:FindFirstChild("Text", true).Text == "Wipe all")
    window:Notify({ Title = "Icon toast", Icon = "bell" }) wait(0.1)
    check("icons: toast icon", find("ToastIcon", Lib._notifyHolder) ~= nil)
    check("icons: bad name falls back", Lib.Windows[1]:Tab({ Title = "Zz", Icon = "nope-nope" }).iconProperty == "TextColor3")

    -- v1.4: pending config values / custom data
    local store2 = window.Config
    store2:Apply({ lateFlag = true, espRange = 2000 })
    check("pending kept for unknown flag", store2.pending.lateFlag == true and F.espRange == 2000)
    check("snapshot keeps pending", store2:Snapshot().lateFlag == true)
    local lateCard = tabNamed("Live").Pages[1]:Card({ Title = "Late" })
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
    tabNamed("Combat"):Select() wait(0.1)
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
    local big = tabNamed("Combat").Pages[1]:Card({ Title = "Big" }):Dropdown({ Title = "Big list", Options = many })
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
    tabNamed("Live"):Select() wait(0.1)
    local farmValue = findIn("Auto farm", "Value")
    check("progress text", farmValue and farmValue.Text == "3 / 10 quests")
    check("progress finished after delay", findIn("Loading assets", "Value").Text == "100%")
    local spin = tabNamed("Live").Pages[1]:Card({ Title = "Spin" }):Progress({ Title = "Spinner", Indeterminate = true })
    check("progress indeterminate", findIn("Spinner", "Value").Text == "Working...")
    spin:SetIndeterminate(false) spin:Set(50)
    check("progress percent", findIn("Spinner", "Value").Text == "50%")
    local farmRow = W.autoFarm.Row.Parent
    MOCK.click(W.autoFarm.Row:FindFirstChild("Button")) wait(0.1)
    check("row toggle button works", farmValue.Text == "4 / 10 quests" and Lib.Flags.autoFarm == true)
    check("row widths 3:1", math.abs(farmRow:FindFirstChild("Auto farm").Size.X.Scale - 0.75) < 0.001 and math.abs(farmRow:FindFirstChild("inbox").Size.X.Scale - 0.25) < 0.001)
    local rowFrame = tabNamed("Live").Pages[1]:Card({ Title = "RowCard" }):Row()
    local ra, rb = rowFrame:Button({ Title = "Start" }), rowFrame:Button({ Title = "Stop" }) wait(0.1)
    check("row equal widths", ra.Row.Size.X.Scale == 0.5 and rb.Row.Size.X.Scale == 0.5)
    local advancedBody = find("Section_Advanced"):FindFirstChild("Body")
    check("section starts closed", advancedBody.Visible == false)
    MOCK.click(find("Section_Advanced"):FindFirstChild("Header")) wait(0.1)
    check("section opens", advancedBody.Visible == true and W.delay ~= nil)
    check("group", find("Group_Build") ~= nil and find("Group_Build"):FindFirstChild("Version") ~= nil)
    local codeText = find("loader.lua"):FindFirstChild("Code", true)
    check("code highlighted", codeText.Text:find("<font") ~= nil and codeText.Text:find("loadstring") ~= nil)
    MOCK.clipboard = nil
    MOCK.click(find("loader.lua"):FindFirstChild("Copy", true)) wait(0.1)
    check("code copy", MOCK.clipboard and MOCK.clipboard:find("HttpGet") ~= nil)
    check("viewport", find("Viewport") ~= nil and find("Viewport"):FindFirstChild("View") ~= nil)
    local img = tabNamed("Live").Pages[1]:Card({ Title = "Pics" }):Image({ Image = "rbxassetid://123", Caption = "logo" })
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

    -- v1.5 dropdown: key / label values, images, chunks, drag select
    local dcard = tabNamed("Live").Pages[1]:Card({ Title = "Dd" })
    local dict = dcard:Dropdown({ Title = "Mode", Options = { pvp = "PvP mode", farm = "Auto farm" }, Default = "farm" })
    check("dict dropdown value is the key", dict.Value == "farm" and dict.Row:FindFirstChild("Select"):FindFirstChildWhichIsA("TextLabel").Text == "Auto farm")
    dict:Set("PvP mode")
    check("set by label resolves to key", dict.Value == "pvp" and dict:GetLabel() == "PvP mode")
    local huge = {}
    for i = 1, 5000 do huge[i] = "Item " .. i end
    local big2 = dcard:Dropdown({ Title = "Huge", Options = huge })
    MOCK.click(big2.Row:FindFirstChild("Select")) wait(0.1)
    local drawnCount = 0
    for _, c in ipairs(find("DropdownList"):FindFirstChild("Options"):GetChildren()) do if c:IsA("TextButton") then drawnCount = drawnCount + 1 end end
    check("huge list drawn in chunks", drawnCount <= 60 and find("DropdownList"):FindFirstChild("More", true).Visible)
    find("DropdownList"):FindFirstChild("Search", true).Text = "Item 4999" wait(0.1)
    check("search finds beyond the first chunk", find("DropdownList"):FindFirstChild("Item 4999", true) ~= nil)
    window:_closePopup()
    local pics = dcard:Dropdown({ Title = "Pics", Multi = true, Options = { { Title = "A", Image = "rbxassetid://1" }, { Title = "B" }, { Title = "C" }, { Title = "D" } } })
    MOCK.click(pics.Row:FindFirstChild("Select")) wait(0.1)
    local plist = find("DropdownList")
    check("option image", plist:FindFirstChild("A", true):FindFirstChild("Icon").Image == "rbxassetid://1")
    MOCK.fire(plist:FindFirstChild("A", true), "InputBegan", mouseInput(Enum.UserInputType.MouseButton1))
    MOCK.fire(plist:FindFirstChild("B", true), "MouseEnter")
    MOCK.fire(plist:FindFirstChild("C", true), "MouseEnter")
    uis.InputEnded:Fire(mouseInput(Enum.UserInputType.MouseButton1), false)
    MOCK.fire(plist:FindFirstChild("D", true), "MouseEnter")
    check("drag select", #pics.Value == 3 and not table.find(pics.Value, "D"))
    window:_closePopup()

    -- v1.5: mouse unlock
    local modal = window.main:FindFirstChild("MouseUnlock")
    check("mouse free while open", modal and modal.Modal == true and uis.MouseIconEnabled == true)
    window:SetVisible(false) wait(0.2)
    check("mouse back when hidden", modal.Modal == false)
    window:SetVisible(true) wait(0.2)
    W.__ui_mouse:Set(false)
    check("mouse unlock switch", modal.Modal == false)
    W.__ui_mouse:Set(true)

    -- interactive keybind list
    W.espEnabled:SetBind(Enum.KeyCode.F)
    window:KeybindList(true) wait(0.6)
    local kb = window._keybindHud.panel
    local espRow
    for _, r in ipairs(kb:FindFirstChild("List"):GetChildren()) do
        if r:IsA("TextButton") and r.Visible and r:FindFirstChildWhichIsA("TextLabel").Text:find("ESP enabled") then espRow = r end
    end
    check("keybind list shows bound toggle", espRow ~= nil)
    local espBefore = F.espEnabled
    if espRow then MOCK.click(espRow) wait(0.1) end
    check("click a bind row flips the toggle", F.espEnabled == not espBefore)
    MOCK.click(kb:FindFirstChild("Edit", true)) wait(0.1)
    for _, r in ipairs(kb:FindFirstChild("List"):GetChildren()) do
        if r:IsA("TextButton") and r.Visible and r:FindFirstChildWhichIsA("TextLabel").Text:find("ESP enabled") then espRow = r end
    end
    MOCK.click(espRow) wait(0.1)
    MOCK.click(kb:FindFirstChild("Edit", true)) wait(0.6)
    local stillShown = false
    for _, r in ipairs(kb:FindFirstChild("List"):GetChildren()) do
        if r:IsA("TextButton") and r.Visible and r:FindFirstChildWhichIsA("TextLabel").Text:find("ESP enabled") then stillShown = true end
    end
    check("hidden in edit mode", not stillShown and window.memory.hud.keybindsHidden["ESP enabled"] == true)
    MOCK.click(kb:FindFirstChild("Fold", true)) wait(0.6)
    check("fold keybind list", kb.Size.Y.Offset == 30)
    MOCK.click(kb:FindFirstChild("Fold", true)) wait(0.1)
    window.memory.hud.keybindsHidden["ESP enabled"] = nil
    window:KeybindList(false)

    -- risky + warning + card desc / collapse
    tabNamed("Combat"):Select() wait(0.1)
    local riskyTitle = W.silentAim.Row:FindFirstChild("Title")
    check("risky title is red", riskyTitle.TextColor3 == Lib.Theme.get("danger") and W.silentAim.Row:FindFirstChild("Help") ~= nil)
    check("page warning", find("Warning") ~= nil and find("Warning"):FindFirstChild("Text", true).Text:find("ranked") ~= nil)
    local aimCard = W.silentAim.Card.frame
    check("card desc", aimCard:FindFirstChild("CardDesc") ~= nil)
    MOCK.click(aimCard:FindFirstChild("Collapse", true)) wait(0.2)
    check("card collapses", W.silentAim.Row.Visible == false and window.memory.collapsed["Combat/Combat/Silent Aim"] == true)
    MOCK.click(aimCard:FindFirstChild("Collapse", true)) wait(0.2)
    check("card expands", W.silentAim.Row.Visible == true and W.prediction.Row.Visible == true)

    -- per-game profiles
    local cstore = window.Config
    cstore:SetPerGame("Game")
    check("per-game path", cstore.path:find("configs/" .. tostring(E.game.GameId)) ~= nil)
    cstore:Save("gameonly")
    check("per-game save", E.isfile(cstore.path .. "/gameonly.json"))
    cstore:SetAutoLoad("gameonly")
    cstore:SetPerGame(false)
    check("shared list does not see it", not cstore:Exists("gameonly") and cstore:GetAutoLoad() ~= "gameonly")
    cstore:SetPerGame("Game") cstore:Delete("gameonly") cstore:ClearAutoLoad() cstore:SetPerGame(false)

    -- notification progress / steps
    local ptoast = window:Notify({ Title = "Farm", Steps = 4, Content = "Start" })
    check("step toast text", ptoast:FindFirstChild("Content").Text == "0/4  ·  Start")
    ptoast:SetStep(2, "Quest")
    check("step toast advances", ptoast:FindFirstChild("Content").Text == "2/4  ·  Quest" and ptoast.Step == 2)
    wait(4)
    check("progress toast stays", ptoast.Parent ~= nil)
    ptoast:SetStep(4, "Done") wait(1.6)
    check("progress toast closes at the end", ptoast.Parent == nil)
    local snd = window:Notify({ Title = "Ping", Sound = true })
    check("sound toast", snd ~= nil)

    ------------------------------------------------------------------ v1.6 (Rayfield round)
    local misc
    for _, t in ipairs(window.Tabs) do if t.Title == "Live" then misc = t end end
    local tc = misc:Card({ Title = "V16" })

    -- secure mode: random gui names
    Lib:SetSecure(true)
    local sg = Lib.Util.screenGui("SecureProbe")
    check("secure: random gui name", sg.Name ~= "SecureProbe" and Lib:IsSecure())
    sg:Destroy()
    Lib:SetSecure(false)
    local sg2 = Lib.Util.screenGui("PlainProbe")
    check("secure off: plain name", sg2.Name == "PlainProbe")
    sg2:Destroy()

    -- atomic save + recovery
    local cfgs = window.Config
    cfgs:Save("atomic")
    local apath = cfgs.path .. "/atomic.json"
    check("atomic save writes, no tmp left", E.isfile(apath) and not E.isfile(apath .. ".tmp"))
    local good = E.readfile(apath)
    MOCK.files[apath] = "{broken"
    MOCK.files[apath .. ".tmp"] = good
    local recovered
    cfgs:OnRecovered(function(name) recovered = name end)
    local lok = cfgs:Load("atomic")
    check("damaged profile restored from tmp", lok == true and recovered == "atomic" and E.readfile(apath) == good and not E.isfile(apath .. ".tmp"))
    MOCK.files[apath .. ".tmp"] = "{stale"
    cfgs:Read("atomic")
    check("stale tmp removed when the file is fine", not E.isfile(apath .. ".tmp"))
    MOCK.files[apath] = nil
    MOCK.files[apath .. ".tmp"] = good
    check("tmp-only profile is listed", table.find(cfgs:List(), "atomic") ~= nil and cfgs:Exists("atomic"))
    cfgs:Read("atomic")
    check("tmp-only profile restored", E.isfile(apath))
    cfgs:Delete("atomic")

    -- Window.Flags proxy
    window.Flags.espRange = 2000
    check("Flags proxy write sets element", F.espRange == 2000 and W.espRange.Value == 2000 and window.Flags.espRange == 2000)
    local seen = 0
    for flag, value in window.Flags do if flag == "espRange" and value == 2000 then seen = seen + 1 end end
    check("Flags proxy iterates", seen == 1)
    window.Flags.espRange = 1500
    window:SetFlag("proxyLate", true)
    local late = tc:Toggle({ Title = "Late", Flag = "proxyLate" }) wait(0.1)
    check("SetFlag before the element exists", late.Value == true)

    -- auto flags
    window.cfg.AutoFlags = true
    local auto1 = tc:Toggle({ Title = "Auto one" })
    local auto2 = tc:Toggle({ Title = "Auto one" })
    local autoButton = tc:Button({ Title = "Auto button" })
    window.cfg.AutoFlags = nil
    check("auto flag from names", auto1.Flag == "Live.V16.Auto one" and auto2.Flag == "Live.V16.Auto one 2" and autoButton.Flag == nil)
    check("auto flag registered", window.flags["Live.V16.Auto one"] == auto1)

    -- callback error flash
    local errorsBefore = #window:GetErrors()
    local bad = tc:Button({ Title = "Broken", Callback = function() error("boom") end })
    MOCK.click(bad.Row:FindFirstChild("Button") or bad.Row) wait(0.1)
    local badTitle = bad.Row:FindFirstChild("Button") or bad.Row
    check("error reported", #window:GetErrors() == errorsBefore + 1)
    check("error flash + title", bad.Row:FindFirstChild("Flash", true) ~= nil and (badTitle.Text:find("Error") ~= nil or badTitle:FindFirstChild("Text", true).Text:find("Error") ~= nil))
    wait(2.6)
    local restoredText = badTitle.Text ~= "" and badTitle.Text or badTitle:FindFirstChild("Text", true).Text
    check("title restored after error", restoredText == "Broken")
    local badToggle = tc:Toggle({ Title = "Bad toggle", Callback = function() error("nope") end })
    badToggle:Set(true) wait(0.1)
    check("toggle error title", badToggle.Row:FindFirstChild("Title").Text:find("Error") ~= nil)
    badToggle:SetTitle("Renamed") wait(2.6)
    check("rename during error kept", badToggle.Row:FindFirstChild("Title").Text == "Renamed")
    window:ClearErrors()

    -- accepted flash
    local inp = tc:Input({ Title = "Flash input" })
    inp:Set("abc")
    check("input accepted flash", inp.Row:FindFirstChild("Flash") ~= nil)

    -- move / remove
    local m1 = tc:Toggle({ Title = "M1" })
    local m2 = tc:Toggle({ Title = "M2" })
    local m3 = tc:ColorPicker({ Title = "M3", Flag = "m3color" })
    local i1 = m1:GetIndex()
    m3:MoveTo(i1)
    check("MoveTo", m3:GetIndex() == i1 and m1:GetIndex() == i1 + 1)
    local panel = tc.body:FindFirstChild("Picker")
    check("panel follows its row", panel and panel.LayoutOrder == m3.Row.LayoutOrder + 1)
    m1:MoveDown()
    check("MoveDown", m1:GetIndex() == i1 + 2 and m2:GetIndex() == i1 + 1)
    m1:MoveUp()
    check("MoveUp", m1:GetIndex() == i1 + 1)
    m3:Remove() wait()
    check("Remove takes the panel and flag", m3.Row.Parent == nil and window.flags.m3color == nil and tc.body:FindFirstChild("Picker") == nil)

    -- lock reason
    local lk = tc:Toggle({ Title = "Lockable", Desc = "Normal text" })
    lk:Lock("Needs premium")
    check("lock reason replaces desc", lk.Row:FindFirstChild("Desc").Text == "Needs premium" and lk.Locked)
    lk:SetDesc("Changed")
    lk:Unlock()
    check("unlock restores (latest) desc", lk.Row:FindFirstChild("Desc").Text == "Changed")
    local lk2 = tc:Toggle({ Title = "Lockable 2" })
    lk2:Lock("Turn on X")
    local reason = lk2.Row:FindFirstChild("Reason", true)
    check("lock reason pill without desc", reason and reason.Visible and reason:FindFirstChild("Text").Text == "Turn on X")
    MOCK.click(lk2.Row) wait()
    check("locked toggle ignores clicks", lk2.Value == false)

    -- slider dragging argument
    local dragCalls = {}
    W.espRange:OnChanged(function(value, dragging) table.insert(dragCalls, { value, dragging }) end)
    local strack, shit = findIn("Max distance", "Track"), findIn("Max distance", "Hit")
    local sp, ss = strack.AbsolutePosition, strack.AbsoluteSize
    MOCK.mouseLocation = Vector2.new(sp.X + ss.X * 0.25, sp.Y)
    MOCK.fire(shit, "InputBegan", mouseInput(Enum.UserInputType.MouseButton1))
    MOCK.mouseLocation = Vector2.new(sp.X + ss.X * 0.6, sp.Y)
    uis.InputChanged:Fire(mouseInput(Enum.UserInputType.MouseMovement), false)
    uis.InputEnded:Fire(mouseInput(Enum.UserInputType.MouseButton1), false)
    local last = dragCalls[#dragCalls]
    check("slider dragging flag", #dragCalls >= 3 and dragCalls[1][2] == true and last[2] == false and last[1] == F.espRange)
    W.espRange:Set(1500)

    -- keybind hold + toggle hold bind
    local held = {}
    local hk = tc:Keybind({ Title = "Hold key", Default = Enum.KeyCode.H, Mode = "Hold", Pressed = function(down) table.insert(held, down) end })
    uis.InputBegan:Fire(MOCK.input(Enum.KeyCode.H), false)
    check("hold keybind down", held[1] == true and hk.Held == true)
    uis.InputEnded:Fire(MOCK.input(Enum.KeyCode.H, nil, Enum.UserInputState.End), false)
    check("hold keybind up", held[2] == false and hk.Held == false)
    local ht = tc:Toggle({ Title = "Hold toggle", Bind = Enum.KeyCode.J, BindMode = "Hold" })
    uis.InputBegan:Fire(MOCK.input(Enum.KeyCode.J), false)
    check("hold toggle on while held", ht.Value == true)
    uis.InputEnded:Fire(MOCK.input(Enum.KeyCode.J, nil, Enum.UserInputState.End), false)
    check("hold toggle off on release", ht.Value == false)

    -- colour picker alpha
    local alphaSeen
    local ap = tc:ColorPicker({ Title = "Alpha pick", Alpha = true, Transparency = 0.4, Callback = function(color, t) alphaSeen = t end })
    check("alpha default", ap.Transparency == 0.4 and ap.Row.Parent and tc.body:FindFirstChild("Picker"):FindFirstChild("Alpha", true) ~= nil)
    ap:SetTransparency(0.7)
    check("alpha callback", alphaSeen == 0.7 and type(ap:_save()) == "table" and ap:_save().Alpha == 0.7)
    ap:_load("FF0000")
    check("alpha load from plain hex", ap.Transparency == 0 and ap:_save() == "FF0000")

    -- segmented progress
    local seg = tc:Progress({ Title = "Seg", Steps = 4, Value = 2 }) wait(0.5)
    local holderSeg = seg.Row:FindFirstChild("Segments")
    check("segments built", holderSeg and #holderSeg:GetChildren() == 5) -- 4 + list layout
    check("segments fill", holderSeg:FindFirstChild("Segment2").Fill.Size.X.Scale == 1 and holderSeg:FindFirstChild("Segment3").Fill.Size.X.Scale == 0)
    check("segment text", seg.Row:FindFirstChild("Value").Text == "2 / 4")
    seg:Set(3) wait(0.5)
    check("segment advances", holderSeg:FindFirstChild("Segment3").Fill.Size.X.Scale == 1)

    -- stat
    local st = tc:Stat({ Title = "Coins", Value = 1234, Prefix = "$", Icon = "coins" })
    local digitsFrame = st.Row:FindFirstChild("Digits")
    local count = 0
    for _, child in ipairs(digitsFrame:GetChildren()) do if child.Name == "Digit" then count = count + 1 end end
    check("stat digits", count == 4)
    st:Set(1300) wait(0.8)
    local chip = st.Row:FindFirstChild("Delta")
    check("stat delta chip", chip.Visible and chip:FindFirstChild("Text").Text == "+5.3%")
    local strip
    for _, child in ipairs(digitsFrame:GetChildren()) do if child.Name == "Digit" and child.LayoutOrder == 4 then strip = child.Strip end end
    check("stat digit rolled", strip and strip.Position.Y.Offset == -22 * 3)
    st:Set(25) wait(0.1)
    count = 0
    for _, child in ipairs(digitsFrame:GetChildren()) do if child.Name == "Digit" then count = count + 1 end end
    check("stat rebuilds on new shape", count == 2 and chip:FindFirstChild("Text").Text:sub(1, 1) == "-")
    local inv = tc:Stat({ Title = "Ping", Value = 50, Delta = "absolute", Invert = true, Suffix = " ms" })
    inv:Set(40)
    check("inverted stat: lower is good", inv.Row:FindFirstChild("Delta"):FindFirstChild("Text").Text == "-10 ms")

    -- console
    local con = tc:Console({ Title = "TestLog", MaxLines = 2, Time = false })
    con:Append("one") con:Append("two", "warning") con:Print("three", 3)
    check("console max lines", #con.Lines == 2 and con.Lines[2].text == "three 3")
    check("console text", con:GetText() == "WARNING: two\nthree 3")
    con:Clear()
    check("console clear", #con.Lines == 0 and con.Row:FindFirstChild("Empty", true).Visible)

    -- notifications: hover pause, stack limit, length-based time
    local ht2 = window:Notify({ Title = "Hover", Duration = 1 })
    MOCK.fire(ht2.Frame, "MouseEnter")
    wait(1.6)
    check("hover pauses toast", ht2:IsOpen())
    MOCK.fire(ht2.Frame, "MouseLeave")
    wait(1.6)
    check("toast closes after hover", not ht2:IsOpen())
    Lib.MaxNotifications = 3
    local many = {}
    for i = 1, 5 do many[i] = window:Notify({ Title = "Stack " .. i, Duration = 30 }) end
    local openCount = 0
    for i = 1, 5 do if many[i]:IsOpen() then openCount = openCount + 1 end end
    check("max notifications", openCount == 3 and not many[1]:IsOpen() and many[5]:IsOpen())
    for i = 1, 5 do many[i]:Close() end
    Lib.MaxNotifications = 6
    local long = window:Notify({ Title = "Long", Content = string.rep("word ", 24) })
    wait(5)
    check("long toast stays longer", long:IsOpen())
    wait(5)
    check("long toast closes", not long:IsOpen())

    -- pill toast + welcome
    local pill = Lib:Toast({ Text = "Saved", Icon = "check" })
    check("pill toast", pill.Frame.Parent ~= nil and pill.Frame:FindFirstChild("Text", true).Text == "Saved")
    wait(3.5)
    check("pill toast closes", pill.Frame.Parent == nil)
    check("welcome remembered", window:_state("welcomed") == tostring(E.game:GetService("Players").LocalPlayer.UserId))

    -- tags
    local betaTag
    for _, child in ipairs(window.titleRow:GetChildren()) do if child.Name == "Tag" then betaTag = child end end
    check("title tag", betaTag and betaTag:FindFirstChild("Text").Text == "BETA")
    local white = window:AddTag("PRO", { Color = E.Color3.new(1, 1, 1) })
    check("tag auto contrast", white.Frame:FindFirstChild("Text").TextColor3.R < 0.2)
    local dark = window:AddTag("X", { Color = E.Color3.fromRGB(20, 20, 60) })
    check("tag auto contrast dark", dark.Frame:FindFirstChild("Text").TextColor3.R > 0.9)
    white:Remove() dark:Remove()
    check("tag removed", white.Frame.Parent == nil)

    -- kick watcher
    local kickInfo
    window:OnKick(function(info) kickInfo = info end)
    window:_kicked("You were kicked from this experience: Exploiting\n(Error Code: 267)", 267)
    check("kick parsed", kickInfo and kickInfo.Reason == "Exploiting" and kickInfo.Kind == "Kicked" and kickInfo.Code == 267)
    check("kick saved", window:GetKicks()[1].Reason == "Exploiting")
    window:_kicked("You were kicked from this experience: Exploiting\n(Error Code: 267)", 267)
    check("kick deduped", #window:GetKicks() == 1)
    local lost = window._parseKick("Lost connection to the game server, please reconnect (Error Code: 277)")
    check("connection lost parsed", lost.Code == 277 and lost.Kind == "Connection lost" and lost.Reason == "Lost connection to the game server, please reconnect")
    wait(0.1)
    local disc = find("Disconnects")
    check("kicks listed in Settings", disc and disc:FindFirstChildWhichIsA("TextLabel", true) and (function()
        for _, o in ipairs(disc:GetDescendants()) do if o:IsA("TextLabel") and o.Text:find("Exploiting") then return true end end
        return false end)())

    -- live background + edge glow
    window:SetLiveBackground(true) wait(1)
    local live = window.main:FindFirstChild("LiveBackground")
    check("live background", live and live:FindFirstChildWhichIsA("UIGradient").Rotation > 0)
    window:SetLiveBackground(false)
    check("live background off", window.main:FindFirstChild("LiveBackground") == nil)
    window:SetAccentGlow(true) wait(0.5)
    check("edge glow", window.mainStroke.Thickness == 1.5 and window.mainStroke.Transparency >= 0.29 and window.mainStroke.Transparency <= 0.81)
    window:SetAccentGlow(false)
    check("edge glow off", window.mainStroke.Thickness == 1 and window.mainStroke.Transparency == 0)

    ------------------------------------------------------------------ v1.7
    local t7 = misc:Card({ Title = "V17" })

    -- checkbox
    local cb = t7:Checkbox({ Title = "Tick me", Flag = "tickMe" })
    MOCK.click(cb.Row) wait(0.2)
    check("checkbox click", F.tickMe == true and cb.Row:FindFirstChild("Box"):FindFirstChild("Tick").Visible)
    MOCK.click(cb.Row) wait(0.2)
    check("checkbox off", F.tickMe == false)

    -- radio
    local picked
    local rd = t7:Radio({ Title = "Target", Flag = "radioTarget", Options = { "Closest", { Title = "Lowest HP", Value = "hp", Desc = "Weakest first" }, { Title = "Locked", Locked = true } }, Callback = function(v) picked = v end })
    check("radio default", F.radioTarget == "Closest")
    MOCK.click(rd.Row:FindFirstChild("Lowest HP", true)) wait(0.1)
    check("radio click uses Value", F.radioTarget == "hp" and picked == "hp")
    MOCK.click(rd.Row:FindFirstChild("Locked", true)) wait(0.1)
    check("radio locked option ignored", F.radioTarget == "hp")
    rd:Set("Closest")
    check("radio set by title", F.radioTarget == "Closest")
    rd:SetOptions({ "A", "B" })
    check("radio options swapped", F.radioTarget == "A")

    -- table
    local clicked
    local tb = t7:Table({ Title = "Players", Search = true, Columns = { "Name", { Title = "Kills", Align = "Right" }, "Team" },
        Rows = { { "Zed", 3, "Red" }, { "Amy", 12, "Blue" }, { "Bob", nil, "Red" } }, OnRowClick = function(row) clicked = row[1] end })
    check("table rows", #tb:GetRows() == 3 and tb:GetRows()[3][3] == "Red" and tb.Row:FindFirstChild("Count").Text == "3 rows")
    tb:Sort("Kills", true)
    local body = tb.Row:FindFirstChild("Rows", true)
    local function firstName()
        local best
        for _, child in ipairs(body:GetChildren()) do if child:IsA("TextButton") and (not best or child.LayoutOrder < best.LayoutOrder) then best = child end end
        return best and best:FindFirstChild("Cell1").Text
    end
    check("table sort desc by number", firstName() == "Amy")
    tb:Sort(1)
    check("table sort by name", firstName() == "Amy")
    tb:Sort(2, false)
    check("table numbers before blanks", firstName() == "Zed")
    tb.Row:FindFirstChild("Search").Text = "red" wait()
    check("table search", tb.Row:FindFirstChild("Count").Text == "2 / 3")
    tb.Row:FindFirstChild("Search").Text = ""
    for _, child in ipairs(body:GetChildren()) do if child:IsA("TextButton") and child:FindFirstChild("Cell1").Text == "Bob" then MOCK.click(child) end end
    check("table row click", clicked == "Bob")
    tb:AddRow({ "Cat", 5, "Blue" }) tb:RemoveRow(1)
    check("table add / remove", #tb:GetRows() == 3 and tb:GetRows()[1][1] == "Amy")
    tb:Clear()
    check("table clear", tb.Row:FindFirstChild("Empty", true).Visible)

    -- line graph with two series
    local lg = t7:Graph({ Title = "Net", Style = "Line", Points = 10, Series = { { Name = "In" }, { Name = "Out", Color = "warning" } } })
    for i = 1, 6 do lg:Push(i * 10, "In") lg:Push(30, "Out") end
    wait()
    local legend = lg.Row:FindFirstChild("Legend")
    check("line graph legend", legend and legend:FindFirstChild("In"):FindFirstChild("Text").Text == "In 60")
    local function countSegments()
        local n = 0
        for _, child in ipairs(lg.Row:FindFirstChild("Area"):GetChildren()) do if child.Name == "Segment" and child.Visible then n = n + 1 end end
        return n
    end
    local hiddenTab = not Lib.Util.shown(lg.Row)
    check("line graph not drawn while hidden", not hiddenTab or countSegments() == 0)
    misc:Select() wait(0.4)
    check("line graph segments", countSegments() == 10) -- 5 per series (drawn once the tab shows)
    local bars = t7:Graph({ Title = "Bars" }) bars:Push(5)
    check("bar graph still works", bars.Row:FindFirstChild("Value").Text == "5")

    -- DependsOn
    local master = t7:Toggle({ Title = "Master", Flag = "depMaster" })
    local follower = t7:Slider({ Title = "Follower", Flag = "depFollower", DependsOn = "depMaster" })
    local hiddenOne = t7:Toggle({ Title = "Hidden one", DependsOn = { Flag = "depMaster", Mode = "Hide" } })
    local inverse = t7:Toggle({ Title = "Inverse", DependsOn = { Flag = "depMaster", Not = true } })
    local byValue = t7:Toggle({ Title = "By value", DependsOn = { Flag = "radioTarget", Value = "B" } })
    local byFn = t7:Toggle({ Title = "By fn", DependsOn = function(flags) return flags.depMaster == true and flags.tickMe == true end })
    local depCard = misc:Card({ Title = "DepCard", DependsOn = "depMaster" })
    wait()
    check("depends: locked with reason", follower.Locked and follower.Row:FindFirstChild("Reason", true).Visible and follower.Row:FindFirstChild("Reason", true):FindFirstChild("Text").Text == "Turn on Master first")
    check("depends: hide / not / card", hiddenOne.Row.Visible == false and not inverse.Locked and depCard.frame.Visible == false)
    master:Set(true) wait()
    check("depends: unlock on change", not follower.Locked and hiddenOne.Row.Visible and inverse.Locked and depCard.frame.Visible)
    check("depends: value", byValue.Locked)
    rd:Set("B") wait()
    check("depends: value match", not byValue.Locked)
    check("depends: function", byFn.Locked)
    cb:Set(true) wait()
    check("depends: function true", not byFn.Locked)
    follower:Lock("Mine") master:Set(false) master:Set(true) wait()
    check("depends: keeps a manual lock", follower.Locked and follower._lockReason == "Mine")
    follower:Unlock()

    local depRow = t7:Row()
    depRow:Button({ Title = "RowA" })
    local rowB = depRow:Button({ Title = "RowB", DependsOn = { Flag = "depMaster", Mode = "Hide" } })
    wait()
    check("row shares width while visible", rowB.Row.Visible and rowB.Row.Size.X.Scale == 0.5)
    master:Set(false) wait()
    local rowA = t7.body:FindFirstChild("RowA", true)
    check("row gives the room back when hidden", not rowB.Row.Visible and rowA.Size.X.Scale == 1)
    master:Set(true) wait()

    -- tooltip
    local tipped = t7:Toggle({ Title = "Tipped", Tooltip = "Hello tip" })
    MOCK.fire(tipped.Row, "MouseEnter") wait(0.5)
    check("tooltip shows", window.tip.Visible and window.tipText.Text == "Hello tip")
    MOCK.fire(tipped.Row, "MouseLeave") wait()
    check("tooltip hides", not window.tip.Visible)
    MOCK.fire(tipped.Row, "MouseEnter") wait(4.6)
    check("tooltip hides by itself", not window.tip.Visible)

    -- sounds
    Lib.Sounds.Enabled = true
    local soundService = E.game:GetService("SoundService")
    local before = #soundService:GetChildren()
    t7:Button({ Title = "Beep" }) MOCK.click(t7.body:FindFirstChild("Beep", true):FindFirstChild("Button") or t7.body:FindFirstChild("Beep", true))
    check("ui sound plays", #soundService:GetChildren() > before)
    Lib.Sounds.Enabled = false

    -- blur
    local lighting = E.game:GetService("Lighting")
    window:SetBlur(true) wait(0.5)
    check("blur on", lighting:FindFirstChild("QustahUIBlur") ~= nil)
    window:SetVisible(false)
    wait(0.5)
    check("blur off when hidden", lighting:FindFirstChild("QustahUIBlur") == nil)
    window:SetVisible(true) wait(0.5)
    check("blur back when shown", lighting:FindFirstChild("QustahUIBlur") ~= nil)
    lighting:FindFirstChild("QustahUIBlur"):Destroy()
    window:SetVisible(false) window:SetVisible(true) wait(0.5)
    check("blur recreated after the game removed it", lighting:FindFirstChild("QustahUIBlur") ~= nil)
    window:SetBlur(false) wait(0.5)
    check("blur removed", lighting:FindFirstChild("QustahUIBlur") == nil)

    -- changelog once per version
    window.cfg.Changelog = { Version = "9.9", Items = { "Added tables" }, Delay = 0 }
    window:_changelog() wait(0.3)
    check("changelog shown", window._dialog ~= nil and window._dialog.Frame:FindFirstChild("Content", true).Text:find("Added tables") ~= nil)
    window._dialog:Close() wait()
    window:_changelog() wait(0.3)
    check("changelog only once", window._dialog == nil)
    window.cfg.Changelog = nil

    -- lock closes an open colour panel; toggle can't take the menu key
    local lp = t7:ColorPicker({ Title = "LockPick" })
    lp:SetOpen(true) lp:Lock("no")
    local lpPanel
    for _, child in ipairs(t7.body:GetChildren()) do if child.Name == "Picker" and child.LayoutOrder == lp.Row.LayoutOrder + 1 then lpPanel = child end end
    check("lock closes colour panel", lpPanel and lpPanel.Visible == false)
    local mk = t7:Toggle({ Title = "MenuKeyTest", Bindable = true })
    MOCK.fire(mk.Row, "MouseButton2Click") wait() MOCK.press(window.key) wait()
    check("toggle can't take the menu key", mk.BindKey == nil)
    if not window.visible then window:SetVisible(true) end

    -- stale toasts don't block the stack limit
    local stale = {}
    for i = 1, 8 do stale[i] = window:Notify({ Title = "Stale " .. i, Duration = 30 }) stale[i].Frame:Destroy() end
    local fresh = window:Notify({ Title = "Fresh", Duration = 30 })
    check("stack limit with stale toasts", fresh:IsOpen() and #Lib._openToasts <= Lib.MaxNotifications)
    fresh:Close()

    -- a newer complete .tmp wins
    local jpath = window.Config.folder .. "/probe.json"
    E.writefile(jpath, '{"v":1}') E.writefile(jpath .. ".tmp", '{"v":2}')
    check("newer tmp wins", window.Config:ReadJSON("probe").v == 2 and E.readfile(jpath) == '{"v":2}' and not E.isfile(jpath .. ".tmp"))

    -- key system
    local keyWindow
    task.spawn(function() keyWindow = Lib:CreateWindow({ Title = "KeyTest", Folder = "KeyTest", KeySystem = { Keys = { "abc" }, Url = "https://example.com" } }) end)
    wait(0.5)
    local keyGui = Lib.Util.guiParent():FindFirstChild("QustahUI_Key")
    check("key screen opens", keyGui ~= nil and keyWindow == nil)
    local keyBox = keyGui and keyGui:FindFirstChild("Box", true)
    keyBox.Text = "nope" MOCK.click(keyGui:FindFirstChild("Check", true)) wait(0.3)
    check("wrong key", keyGui:FindFirstChild("Status", true).Text == "Wrong key" and keyWindow == nil)
    keyBox.Text = "  abc " MOCK.click(keyGui:FindFirstChild("Check", true)) wait(0.6)
    check("right key opens the window", keyWindow ~= nil and E.isfile("KeyTest/key.txt") and E.readfile("KeyTest/key.txt") == "abc")
    if keyWindow then keyWindow:Destroy() end
    local again
    task.spawn(function() again = Lib:CreateWindow({ Title = "KeyTest", Folder = "KeyTest", KeySystem = { Keys = { "abc" } } }) end)
    wait(0.2)
    check("remembered key skips the screen", again ~= nil)
    if again then again:Destroy() end
    Lib:ForgetKey("KeyTest")
    check("forget key", not E.isfile("KeyTest/key.txt"))
    local stopped
    task.spawn(function()
        local ok = pcall(function() Lib:CreateWindow({ Title = "KeyTest2", Folder = "KeyTest2", KeySystem = { Keys = { "x" } } }) end)
        stopped = not ok
    end)
    wait(0.3)
    MOCK.click(Lib.Util.guiParent():FindFirstChild("QustahUI_Key"):FindFirstChild("Close", true)) wait(0.5)
    check("closing the key screen stops the script", stopped == true)

    -- input box hugs its text: same gap both sides, empty or not
    local hug = t7:Input({ Title = "Hug", Placeholder = "player name" })
    local hugBox = hug.Row:FindFirstChild("Box")
    local emptyWidth = hugBox.Size.X.Offset
    local expectEmpty = math.ceil(Lib.Util.textWidth("player name", 10, hugBox.Font)) + 22
    hugBox.Text = "a much longer player name here" wait()
    local longWidth = hugBox.Size.X.Offset
    hugBox.Text = "ab" wait()
    check("input hugs placeholder", emptyWidth == math.max(56, expectEmpty))
    check("input grows with text, capped", longWidth > emptyWidth and longWidth <= 170)
    check("input shrinks to a minimum", hugBox.Size.X.Offset == 56)

    -- theme bindings are kept (not weak) and leave with their objects
    local beforeCount = Lib.Theme._boundCount()
    local probeCard = misc:Card({ Title = "ThemeProbe" })
    probeCard:ActionInput({ Placeholder = "Theme name", Button = "Save" })
    local afterCount = Lib.Theme._boundCount()
    check("bindings recorded", afterCount > beforeCount)
    probeCard.frame:Destroy() wait()
    check("bindings dropped on destroy", Lib.Theme._boundCount() < afterCount)
    -- every bound outline / box follows a theme switch (Light: no Dark input colour left anywhere in the editor)
    W.__ui_theme:Set("Light") wait()
    local darkInput, stale = Lib.Theme.packs and Lib.Theme.packs.Dark and Lib.Theme.packs.Dark.input, 0
    local editorCard = find("Theme editor")
    for _, object in ipairs(editorCard and editorCard:GetDescendants() or {}) do
        if object:IsA("GuiObject") and darkInput and object.BackgroundColor3 == darkInput and object.BackgroundTransparency < 1 then stale = stale + 1 end
    end
    check("theme editor follows Light", editorCard ~= nil and stale == 0)
    W.__ui_theme:Set("Dark") wait()

    -- notifications fit a small screen
    MOCK.setViewport(640, 300) wait(0.2)
    local small = {}
    for i = 1, 6 do small[i] = window:Notify({ Title = "Small " .. i, Content = "two lines", Duration = 30 }) end
    local openSmall, usedSmall = 0, 0
    for i = 1, 6 do if small[i]:IsOpen() then openSmall = openSmall + 1 usedSmall = usedSmall + small[i].Frame.Size.Y.Offset + 6 end end
    check("toasts fit the screen height", openSmall < 6 and usedSmall <= 300 - 32 + 6 and small[6]:IsOpen())
    for i = 1, 6 do small[i]:Close() end
    MOCK.setViewport(1280, 720) wait(0.2)
    window:SetFlag(nil, 1)
    check("SetFlag(nil) is ignored", true)
    check("reserved profile names", window.Config:FreeName("con") ~= "con" and #window.Config:FreeName(string.rep("x", 200)) <= 60)

    ------------------------------------------------------------------ v1.8
    local t8 = misc:Card({ Title = "V18" })
    -- empty card message
    local emptyCard = misc:Card({ Title = "EmptyOne" }) wait()
    check("empty card says so", emptyCard.frame:FindFirstChild("Empty").Visible == true)
    local only = emptyCard:Toggle({ Title = "Only", DependsOn = { Flag = "depMaster", Mode = "Hide" } }) wait()
    check("empty message hides when an element shows", master.Value == true and emptyCard.frame:FindFirstChild("Empty").Visible == false)
    master:Set(false) wait() wait()
    check("empty message back when all are hidden", emptyCard.frame:FindFirstChild("Empty").Visible == true)
    master:Set(true) wait()
    local noEmpty = misc:Card({ Title = "NoEmpty", Empty = false }) wait()
    check("Empty = false", noEmpty.frame:FindFirstChild("Empty") == nil)

    -- fading scroll bars
    local pageFrame = window.current and window.current.current and window.current.current.frame
    check("page scrollbar hidden when idle", pageFrame and pageFrame.ScrollBarImageTransparency == 1)
    pageFrame.CanvasPosition = Vector2.new(0, 20) wait(0.3)
    check("scrollbar shows while scrolling", pageFrame.ScrollBarImageTransparency < 1)
    wait(1.8)
    check("scrollbar fades again", pageFrame.ScrollBarImageTransparency == 1)

    -- hover pop on grid cells
    local pick = t8:ImagePicker({ Title = "Pop", Images = { "crosshair", "target" } })
    local cell = pick.Row:FindFirstChild("Image1", true)
    MOCK.fire(cell, "MouseEnter") wait(0.3)
    check("image cell grows on hover", cell:FindFirstChildOfClass("UIScale").Scale > 1)
    MOCK.fire(cell, "MouseLeave") wait(0.3)
    check("and back", cell:FindFirstChildOfClass("UIScale").Scale == 1)

    -- merged notifications
    local m1 = window:Notify({ Title = "Merged", Content = "same", Duration = 2 })
    wait(1.5)
    local m2 = window:Notify({ Title = "Merged", Content = "same", Duration = 2 })
    local m3 = window:Notify({ Title = "Merged", Content = "same", Duration = 2 })
    check("repeats merge into one toast", m1 == m2 and m2 == m3 and m1:GetCount() == 3)
    check("merged title shows the count", m1.Frame:FindFirstChildWhichIsA("TextLabel").Text:find("×3") ~= nil or (function()
        for _, o in ipairs(m1.Frame:GetDescendants()) do if o:IsA("TextLabel") and o.Text:find("×3") then return true end end return false end)())
    wait(1)
    check("merging restarts the timer", m1:IsOpen())
    check("history counts too", Lib.NotifyHistory[1].Count == 3)
    local other = window:Notify({ Title = "Merged", Content = "different", Duration = 2 })
    check("different content does not merge", other ~= m1)
    local withButtons = window:Notify({ Title = "Merged", Content = "same", Buttons = { { Title = "Ok" } } })
    check("toasts with buttons never merge", withButtons ~= m1)
    m1:Close() other:Close() withButtons:Close()

    -- UI scale
    window:SetUIScale(1.25) wait()
    check("ui scale applies", math.abs(window.scale.Scale - 1.25) < 0.01 and window.memory.uiScale == 1.25)
    MOCK.setViewport(700, 420) wait(0.2)
    check("ui scale still fits small screens", window.scale.Scale < 1.2 and (window.width + 52) * window.scale.Scale <= 700 - 24 + 0.5)
    MOCK.setViewport(1280, 720) wait(0.2)
    window:SetUIScale(1) wait()
    check("ui scale back", window.scale.Scale == 1 and window.memory.uiScale == nil)

    -- stepper
    local st8 = t8:Stepper({ Title = "Count", Flag = "stepCount", Min = 0, Max = 5, Step = 1, Default = 4 })
    local plusButton, minusButton = st8.Row:FindFirstChild("Plus", true), st8.Row:FindFirstChild("Minus", true)
    MOCK.fire(plusButton, "InputBegan", mouseInput(Enum.UserInputType.MouseButton1)) MOCK.fire(plusButton, "InputEnded", mouseInput(Enum.UserInputType.MouseButton1)) wait()
    check("stepper plus", F.stepCount == 5)
    MOCK.fire(plusButton, "InputBegan", mouseInput(Enum.UserInputType.MouseButton1)) MOCK.fire(plusButton, "InputEnded", mouseInput(Enum.UserInputType.MouseButton1)) wait()
    check("stepper clamps at max", F.stepCount == 5)
    MOCK.fire(minusButton, "InputBegan", mouseInput(Enum.UserInputType.MouseButton1)) wait(1.2)
    MOCK.fire(minusButton, "InputEnded", mouseInput(Enum.UserInputType.MouseButton1)) wait()
    check("stepper hold repeats", F.stepCount == 0)
    local stepBox = st8.Row:FindFirstChild("Value", true)
    stepBox.Text = "3.6" MOCK.fire(stepBox, "FocusLost", true) wait()
    check("stepper typed (rounded)", F.stepCount == 4 and stepBox.Text == "4")
    st8:Set(0 / 0) st8:Set("x")
    check("stepper ignores junk", F.stepCount == 4)

    -- text area
    local ta = t8:TextArea({ Title = "Notes", Flag = "notes", MaxLength = 10, Placeholder = "Write..." })
    local taBox = ta.Row:FindFirstChild("Box")
    check("text area is multi-line", taBox.MultiLine == true and taBox.TextWrapped == true)
    taBox.Text = "line one\nline two that is long" wait()
    check("text area max length", #taBox.Text == 10 and ta.Row:FindFirstChild("Counter").Text == "10 / 10")
    MOCK.fire(taBox, "FocusLost", false) wait()
    check("text area value", F.notes == "line one\nl")

    -- mobile button
    window:SetMobileButton(true)
    window:SetVisible(false) wait(0.3)
    local pillButton = window.gui:FindFirstChild("MobileButton")
    check("mobile button shows while hidden", pillButton and pillButton.Visible)
    MOCK.mouseLocation = Vector2.new(pillButton.AbsolutePosition.X + 5, pillButton.AbsolutePosition.Y + 5)
    MOCK.fire(pillButton:FindFirstChild("Hit"), "InputBegan", mouseInput(Enum.UserInputType.MouseButton1))
    uis.InputEnded:Fire(mouseInput(Enum.UserInputType.MouseButton1), false) wait(0.3)
    check("tap opens the menu", window.visible == true and not pillButton.Visible)
    window:SetVisible(false) wait(0.3)
    local before = pillButton.Position
    MOCK.fire(pillButton:FindFirstChild("Hit"), "InputBegan", mouseInput(Enum.UserInputType.MouseButton1))
    MOCK.mouseLocation = Vector2.new(pillButton.AbsolutePosition.X + 120, pillButton.AbsolutePosition.Y + 80)
    uis.InputChanged:Fire(mouseInput(Enum.UserInputType.MouseMovement), false)
    uis.InputEnded:Fire(mouseInput(Enum.UserInputType.MouseButton1), false) wait(0.3)
    check("drag moves it, menu stays hidden", window.visible == false and pillButton.Position ~= before and window.memory.mobilePill ~= nil)
    window:SetVisible(true) window:SetMobileButton(false) wait(0.3)
    check("mobile button off", not pillButton.Visible)

    -- haptics never throw (no HapticEffect in the mock)
    Lib.Haptics.Enabled = true
    local hapticOk = pcall(function() Lib.Haptics.Play("click") Lib.Haptics.Play("notify") Lib.Haptics.Play("nope") end)
    check("haptics are safe", hapticOk)
    Lib.Haptics.Enabled = false

    -- lazy tab
    local built = 0
    local lazy = window:Tab({ Title = "Lazy", BuildDelay = false, Build = function(tab)
        built = built + 1
        tab:Card({ Title = "LazyCard" }):Toggle({ Title = "Lazy toggle", Flag = "lazyFlag" })
    end })
    window:SetFlag("lazyFlag", true)
    check("lazy tab not built yet", built == 0 and window.flags.lazyFlag == nil)
    lazy:Select() wait()
    check("lazy tab builds on open", built == 1 and window.flags.lazyFlag ~= nil and F.lazyFlag == true)
    lazy:Select() wait()
    check("lazy tab builds once", built == 1)
    local auto = 0
    window:Tab({ Title = "LazyAuto", BuildDelay = 0.2, Build = function() auto = auto + 1 end })
    wait(0.5)
    check("lazy tab builds itself in the background", auto == 1)
    window:SelectTab("Live")

    -- button styles, sizes, icon-only, Row widths
    local bc = tabNamed("Live").Pages[1]:Card({ Title = "Btn" })
    local fired = 0
    local styled = {}
    for _, name in ipairs({ "Default", "Primary", "Soft", "Outline", "Ghost", "Danger", "Link" }) do
        styled[name] = bc:Button({ Title = name, Style = name, Callback = function() fired = fired + 1 end })
    end
    check("button styles made", styled.Primary.Style == "Primary" and styled.Link.Style == "Link")
    check("primary uses the accent", styled.Primary.Row.Button.BackgroundColor3 == Lib.Theme.get("accent"))
    check("ghost has no outline", styled.Ghost.Row.Button:FindFirstChildWhichIsA("UIStroke").Transparency == 1)
    styled.Ghost:SetStyle("primary") wait(0.2)
    check("SetStyle (any case)", styled.Ghost.Style == "Primary" and styled.Ghost.Row.Button.BackgroundTransparency == 0)
    check("unknown style falls back", bc:Button({ Title = "X", Style = "Nope" }).Style == "Default")
    local small, large = bc:Button({ Title = "S", Size = "Small" }), bc:Button({ Title = "L", Size = "large" })
    check("button sizes", small.Row.Button.Size.Y.Offset == 22 and large.Row.Button.Size.Y.Offset == 34)
    local iconOnly = bc:Button({ Icon = "trash-2", Callback = function() fired = fired + 1 end })
    local content = iconOnly.Row.Button:FindFirstChild("Content")
    check("icon-only button", content and content.Text.Visible == false and iconOnly.Row.Button.Text == "")
    iconOnly:Fire() styled.Soft:Fire()
    check("styled buttons fire", fired == 2)
    local right = bc:Button({ Title = "Next", Icon = "arrow-right", IconSide = "Right" })
    check("icon on the right", right.Row.Button.Content.ButtonIcon.LayoutOrder > right.Row.Button.Content.Text.LayoutOrder)
    local wr = bc:Row({ Widths = { 2, 1 }, Gap = 6 })
    local wa, wb = wr:Button({ Title = "Wide" }), wr:Button({ Title = "Narrow", Style = "Ghost" })
    wait(0.1)
    check("row widths share", math.abs(wa.Row.Size.X.Scale - 2 / 3) < 0.001 and math.abs(wb.Row.Size.X.Scale - 1 / 3) < 0.001)
    local er = bc:Row()
    local e1, e2 = er:Button({ Title = "A" }), er:Button({ Title = "B" })
    wait(0.1)
    check("row equal by default", e1.Row.Size.X.Scale == 0.5 and e2.Row.Size.X.Scale == 0.5)

    -- button extras: cooldown, hold, loading, bind, toggle, menu, badge
    local bx = tabNamed("Live").Pages[1]:Card({ Title = "BtnX" })
    local count = 0
    local cool = bx:Button({ Title = "Cool", Cooldown = 1, Callback = function() count = count + 1 end })
    MOCK.click(cool.Row.Button) wait(0.1)
    MOCK.click(cool.Row.Button) wait(0.1)
    check("cooldown blocks a second click", count == 1 and cool.CoolingDown == true and cool.Row.Button.Timer.Visible)
    wait(1.1)
    MOCK.click(cool.Row.Button) wait(0.1)
    check("cooldown ends", count == 2)
    cool:ResetCooldown()
    check("ResetCooldown", cool.CoolingDown == false)

    local held = 0
    local hold = bx:Button({ Title = "Hold", Hold = 0.5, Callback = function() held = held + 1 end })
    local press = MOCK.input(Enum.KeyCode.Unknown, Enum.UserInputType.MouseButton1)
    MOCK.click(hold.Row.Button) wait(0.1)
    check("hold: a click does nothing", held == 0)
    MOCK.fire(hold.Row.Button, "InputBegan", press) wait(0.2)
    MOCK.fire(hold.Row.Button, "InputEnded", press) wait(0.5)
    check("hold: letting go early cancels", held == 0)
    MOCK.fire(hold.Row.Button, "InputBegan", press) wait(0.6)
    check("hold: runs when full", held == 1)

    local slowRuns = 0
    local slow = bx:Button({ Title = "Slow", Icon = "download", Callback = function() slowRuns = slowRuns + 1 task.wait(0.5) end })
    MOCK.click(slow.Row.Button) wait(0.1)
    check("loading while the callback waits", slow.Loading == true and slow.Row.Button.Content.Spinner.Visible)
    MOCK.click(slow.Row.Button) wait(0.1)
    check("loading blocks clicks", slowRuns == 1)
    wait(0.5)
    check("loading ends with a tick", slow.Loading == false and slow.Row.Button.Content.Spinner.Visible)
    wait(1.3)
    check("tick goes away", not slow.Row.Button.Content.Spinner.Visible and slow.Row.Button.Content.ButtonIcon.Visible)
    local quick = bx:Button({ Title = "Quick", Callback = function() end })
    MOCK.click(quick.Row.Button) wait(0.05)
    check("a quick callback shows no spinner", quick.Loading ~= true and not quick.Row.Button.Content.Spinner.Visible)
    quick:SetLoading(true, "Working")
    check("SetLoading by hand", quick.Loading and quick.Row.Button.Content.Text.Text == "Working")
    quick:SetLoading(false)
    check("SetLoading off", quick.Row.Button.Content.Text.Text == "Quick")

    local keyed = 0
    local bound = bx:Button({ Title = "Keyed", Bind = Enum.KeyCode.G, Callback = function() keyed = keyed + 1 end })
    check("bind key cap", bound.Row.Button.Key.Visible and bound.Row.Button.Key:FindFirstChildWhichIsA("TextLabel").Text == "G")
    MOCK.press(Enum.KeyCode.G) wait(0.1)
    check("bind presses the button", keyed == 1)
    bound:SetBind(nil)
    check("unbind hides the key cap", not bound.Row.Button.Key.Visible)

    local toggled
    local tb = bx:Button({ Title = "Farm", Toggle = true, Flag = "farmButton", OnTitle = "Farming", Callback = function(v) toggled = v end })
    MOCK.click(tb.Row.Button) wait(0.2)
    check("toggle button on", tb.Value == true and toggled == true and Lib.Flags.farmButton == true)
    check("toggle button uses Primary when on", tb.Row.Button.BackgroundColor3 == Lib.Theme.get("accent") and tb.Row.Button.Content.Text.Text == "Farming")
    tb:Set(false)
    check("toggle button Set", tb.Value == false and toggled == false and tb.Row.Button.Content.Text.Text == "Farm")

    local picked
    local split = bx:Button({ Title = "Teleport", Menu = { "Spawn", { Title = "Shop", Icon = "store" }, "Arena" }, Callback = function(o) picked = o end })
    check("menu: first option selected", split.Selected == "Spawn" and split.Row.Button.Content.Selected.Text == "Spawn")
    MOCK.click(split.Row.Button.MenuArrow) wait(0.1)
    local list = window.gui:FindFirstChild("ButtonMenu")
    check("menu opens", list ~= nil and list:FindFirstChild("Shop") ~= nil)
    MOCK.click(list.Shop) wait(0.1)
    check("menu pick runs it", picked == "Shop" and split.Selected == "Shop" and window.gui:FindFirstChild("ButtonMenu") == nil)
    picked = nil
    MOCK.click(split.Row.Button) wait(0.1)
    check("menu main part repeats the choice", picked == "Shop")
    split:SetOptions({ "North", "South" })
    check("menu SetOptions", split.Selected == "North")

    local badged = bx:Button({ Title = "Inbox", Badge = 3 })
    check("badge shows", badged.Row.Button.Badge.Visible and badged.Row.Button.Badge:FindFirstChildWhichIsA("TextLabel").Text == "3")
    badged:SetBadge(0)
    check("badge hides on 0", not badged.Row.Button.Badge.Visible)

    -- long titles in narrow buttons are cut, not spilling out; icon-only errors come back
    local narrow = bx:Row()
    local longOnes = {}
    for i = 1, 4 do longOnes[i] = narrow:Button({ Title = "A very long button title " .. i, Icon = "play" }) end
    wait(0.2)
    local b1 = longOnes[1].Row.Button
    local text1 = b1.Content.Text
    check("narrow button text is cut", text1.TextTruncate == Enum.TextTruncate.AtEnd and text1.Size.X.Offset < b1.AbsoluteSize.X and longOnes[1]._tooltip ~= nil)
    local wide = bx:Button({ Title = "Short" }) wait(0.1)
    check("short text is not cut", wide.Row.Button.Content.Text.TextTruncate == Enum.TextTruncate.None)
    local iconBad = bx:Button({ Icon = "bug", Callback = function() error("icon boom") end })
    MOCK.click(iconBad.Row.Button) wait(0.1)
    check("icon-only error note", iconBad.Row.Button.Content.Text.Text:find("Error") ~= nil)
    wait(2.8)
    check("icon-only button comes back", iconBad.Row.Button.Content.Text.Visible == false)
    local cd2 = bx:Button({ Title = "Hop", Cooldown = 2 })
    MOCK.click(cd2.Row.Button) wait(0.1)
    check("cooldown moves the text clear of the timer", cd2.Row.Button.Content.Position.X.Offset < 0)
    cd2:ResetCooldown()
    check("text back in the middle", cd2.Row.Button.Content.Position.X.Offset == 0)

    -- odd button options never throw
    local oddOk = pcall(function()
        bx:Button({ Title = "Odd 1", Cooldown = "abc", Hold = -1, Style = 123, Size = 5, Badge = {}, Bind = "NotAKey" })
        local m = bx:Button({ Title = "Odd 2", Menu = {} })
        MOCK.click(m.Row.Button.MenuArrow) wait(0.05) window:_closePopup()
        MOCK.click(m.Row.Button) wait(0.05)
        bx:Button({ Title = "Odd 3", Menu = "nope", Selected = "missing" })
        local t = bx:Button({ Title = "Odd 4", Toggle = true, OnStyle = "Weird", OnIcon = "nope-icon", Icon = "play" })
        MOCK.click(t.Row.Button) wait(0.05)
        t:SetStyle(nil) t:SetBadge(false) t:SetBind(nil) t:SetLoading(true) t:SetLoading(false)
        bx:Button({}) bx:Button({ Title = "" }) bx:Button({ Icon = "no-such-icon" })
        local d = bx:Button({ Title = "Gone", Cooldown = 1, Callback = function() task.wait(0.2) end })
        MOCK.click(d.Row.Button) d:Destroy() wait(1.3)
    end)
    check("odd button options don't throw", oddOk)

    -- reset to default
    local rs = bx:Slider({ Title = "Speed", Flag = "resetSpeed", Min = 0, Max = 100, Default = 16 })
    wait(0.1)
    check("reset hidden at default", rs.Row:FindFirstChild("Reset") ~= nil and not rs.Row.Reset.Visible)
    rs:Set(50) wait(0.1)
    check("reset shows when changed", rs.Row.Reset.Visible)
    MOCK.click(rs.Row.Reset) wait(0.1)
    check("reset brings the default back", rs.Value == 16 and not rs.Row.Reset.Visible)
    local noReset = bx:Toggle({ Title = "Plain", Flag = "noResetToggle", Reset = false })
    wait(0.1)
    check("Reset = false", noReset.Row:FindFirstChild("Reset") == nil)
    check("no reset on built-in settings", window.flags.__ui_theme.Row:FindFirstChild("Reset") == nil)

    -- presets
    local pc = tabNamed("Live").Pages[1]:Card({ Title = "Aim presets" })
    pc:Slider({ Title = "P fov", Flag = "pFov", Min = 0, Max = 500, Default = 100 })
    pc:Toggle({ Title = "P smooth", Flag = "pSmooth", Default = false })
    local presetChanges = {}
    local presets = pc:Presets({ { "Legit", { pFov = 80, pSmooth = true } }, { "Rage", { pFov = 400, pSmooth = false } } },
        { Callback = function(name) presetChanges[#presetChanges + 1] = name end })
    wait(0.2)
    check("presets: chips in the header", pc.frame:FindFirstChild("Presets", true) ~= nil and pc.frame:FindFirstChild("Legit", true) ~= nil and pc.frame:FindFirstChild("Custom", true) ~= nil)
    check("presets: no match = Custom", presets:Get() == "Custom")
    window:SetFlag("pFov", 250) wait(0.1)
    presets:Select("Rage") wait(0.1)
    check("presets: Select sets the flags", Lib.Flags.pFov == 400 and Lib.Flags.pSmooth == false and presets:Get() == "Rage")
    MOCK.click(pc.frame:FindFirstChild("Legit", true)) wait(0.1)
    check("presets: chip click", Lib.Flags.pFov == 80 and Lib.Flags.pSmooth == true and presets:Get() == "Legit")
    window:SetFlag("pFov", 90) wait(0.1)
    check("presets: a manual change = Custom", presets:Get() == "Custom")
    presets:Select("Rage") wait(0.1)
    presets:Select("Custom") wait(0.1)
    check("presets: Custom brings your values back", Lib.Flags.pFov == 90 and Lib.Flags.pSmooth == true and presets:Get() == "Custom")
    check("presets: Callback on change", #presetChanges >= 3)
    presets:Add("Off", { pFov = 0, pSmooth = false })
    presets:Select("Off") wait(0.1)
    check("presets: Add", presets:Get() == "Off" and Lib.Flags.pFov == 0)

    -- hidden tab: no dock icon, no gap
    local dockBefore = window.dockHeight
    local ghostTab = window:Tab({ Title = "GhostTab", Icon = "ghost", Hidden = true })
    check("hidden tab: not in the dock", not ghostTab.button.Visible and window.dockHeight == dockBefore)
    ghostTab:SetHidden(false)
    check("hidden tab: shown again", ghostTab.button.Visible and window.dockHeight > dockBefore)
    ghostTab:SetHidden(true)
    check("hidden tab: selectable from code", (function() ghostTab:Select() wait() return window.current == ghostTab end)())
    tabNamed("Live"):Select() wait()

    -- tab badge
    local misc = tabNamed("Live")
    misc:SetBadge(3)
    check("tab badge number", misc.button.Badge.Visible and misc.button.Badge.Text.Text == "3")
    misc:SetBadge(250)
    check("tab badge 99+", misc.button.Badge.Text.Text == "99+")
    misc:SetBadge(true, "danger")
    check("tab badge dot", misc.button.Badge.Visible and misc.button.Badge.Text.Text == "" and misc.button.Badge.Size.X.Offset == 8)
    misc:SetBadge(0)
    check("tab badge hides", not misc.button.Badge.Visible and misc.Badge == nil)

    -- key conflicts
    local kc = tabNamed("Live").Pages[1]:Card({ Title = "Keys" })
    local function conflictWith(name) for _, list in pairs(window:GetKeyConflicts()) do if table.find(list, name) then return list end end end
    local k1 = kc:Toggle({ Title = "Hover", Bind = Enum.KeyCode.KeypadFive })
    local k2 = kc:Button({ Title = "Dash", Bind = Enum.KeyCode.KeypadFive })
    local k3 = kc:Keybind({ Title = "Phase", Default = Enum.KeyCode.KeypadSix })
    wait(0.1)
    check("conflict found", conflictWith("Hover") ~= nil and k1.KeyConflict ~= nil and k2.KeyConflict ~= nil)
    check("conflict tag is yellow", k1.Row.Bind.TextColor3 == Lib.Theme.get("warning") and k2.Row.Button.Key:FindFirstChildWhichIsA("TextLabel").TextColor3 == Lib.Theme.get("warning"))
    check("conflict tooltip text", k1._conflictTip and k1._conflictTip:find("Dash") ~= nil)
    check("no conflict on a free key", k3.KeyConflict == nil)
    local notesBefore = #(Lib.NotifyHistory or {})
    k3:Set(Enum.KeyCode.KeypadFive) wait(0.1)
    check("third one joins the conflict", k3.KeyConflict ~= nil and #conflictWith("Hover") == 3)
    k2:SetBind(Enum.KeyCode.KeypadSeven) k3:Set(Enum.KeyCode.KeypadSix) wait(0.1)
    check("conflict clears", k1.KeyConflict == nil and k2.KeyConflict == nil and conflictWith("Hover") == nil and k1.Row.Bind.TextColor3 ~= Lib.Theme.get("warning"))
    local k4 = kc:Keybind({ Title = "Opens menu", Default = window.key }) wait(0.1)
    check("menu key conflict", k4.KeyConflict ~= nil and table.find(k4.KeyConflict, "Menu") ~= nil)
    k4:Set(Enum.KeyCode.KeypadNine) wait(0.1)

    -- input validate
    local vc = tabNamed("Live").Pages[1]:Card({ Title = "Validate" })
    local got
    local vin = vc:Input({ Title = "Job ID", Flag = "vJob", Validate = function(text)
        if text == "" then return nil end
        return #text >= 4, #text >= 4 and "Looks good" or "At least 4 characters"
    end, Callback = function(text) got = text end })
    local vbox = vin.Row.Box
    MOCK.fire(vbox, "Focused") vbox.Text = "ab" wait(0.1)
    check("validate: red while wrong", vin.Valid == false and vin.Row.Hint.Visible and vin.Row.Hint.Text == "At least 4 characters")
    MOCK.fire(vbox, "FocusLost", false) wait(0.1)
    check("validate: a wrong value is not taken", got == nil and Lib.Flags.vJob == "" and vbox:FindFirstChildWhichIsA("UIStroke").Color == Lib.Theme.get("danger"))
    MOCK.fire(vbox, "Focused") vbox.Text = "abcdef" wait(0.1)
    check("validate: green when right", vin.Valid == true and vin.Row.Hint.Text == "Looks good")
    MOCK.fire(vbox, "FocusLost", false) wait(0.1)
    check("validate: taken and the hint goes", got == "abcdef" and Lib.Flags.vJob == "abcdef" and not vin.Row.Hint.Visible)

    -- tour
    window:SetVisible(true) wait(0.1)
    local finished
    local tour = window:Tour(nil, { Id = "test", OnFinish = function(done) finished = done end })
    wait(0.1)
    local overlay = window.gui:FindFirstChild("Tour")
    check("tour opens", tour ~= nil and overlay ~= nil and overlay.Panel.Head.Title.Text == "Tabs")
    check("tour ring around the dock", overlay.Ring.Visible and math.abs(overlay.Ring.AbsoluteSize.Y - (window.dock.AbsoluteSize.Y + 12)) < 2)
    MOCK.click(overlay.Panel.Foot.Next) wait(0.1)
    check("tour next", tour.Index == 2 and overlay.Panel.Foot.Back.Visible)
    MOCK.press(Enum.KeyCode.Left) wait(0.1)
    check("tour back with a key", tour.Index == 1)
    for _ = 1, #tour.Steps do MOCK.click(overlay.Panel.Foot.Next) wait(0.05) end
    check("tour done", window.gui:FindFirstChild("Tour") == nil and finished == true and window:HasSeenTour("test"))
    check("tour Once skips a seen tour", window:Tour(nil, { Id = "test", Once = true }) == nil)
    local custom = window:Tour({ { Target = vin, Title = "Job box", Text = "Type here" }, { Title = "No target", Text = "Centred" } }, { Id = "custom" })
    wait(0.1)
    check("tour on an element", custom and window.gui.Tour.Ring.Visible and window.gui.Tour.Panel.Head.Title.Text == "Job box")
    custom:Next() wait(0.1)
    check("tour step without a target", not window.gui.Tour.Ring.Visible)
    MOCK.press(Enum.KeyCode.Escape) wait(0.1)
    check("tour Escape skips", window.gui:FindFirstChild("Tour") == nil)
    window:ResetTour("test")
    check("ResetTour", not window:HasSeenTour("test"))
    -- a once-only tour is seen as soon as it opens, and that is read back by the next run (same folder)
    local once = window:Tour(nil, { Id = "firstRun", Once = true }) wait(0.1)
    check("once tour marks itself seen on open", once ~= nil and window:HasSeenTour("firstRun"))
    once:Close() wait(0.1)
    local saved = readfile(window.Config.folder .. "/state.json")
    check("seen tour written to state.json", type(saved) == "string" and saved:find("tour:firstRun", 1, true) ~= nil)
    local rerun = Lib:CreateWindow({ Title = "TourRerun", Folder = window.Config.folder }) wait(0.1)
    check("next run does not show it again", rerun:HasSeenTour("firstRun") and rerun:Tour(nil, { Id = "firstRun", Once = true }) == nil)
    rerun:Destroy() wait(0.1)

    -- canvas sized by hand under a UIScale (Roblox's AutomaticCanvasSize comes out short there)
    do
        local U = Lib.Util
        local host = Instance.new("Frame") host.Size = UDim2.fromOffset(300, 200) host.Parent = window.gui
        local uiScale = Instance.new("UIScale") uiScale.Scale = 0.5 uiScale.Parent = host
        local sc = Instance.new("ScrollingFrame") sc.Size = UDim2.fromOffset(300, 200) sc.AutomaticCanvasSize = Enum.AutomaticSize.Y sc.Parent = host
        local inner = Instance.new("Frame") inner.Size = UDim2.fromOffset(280, 460) inner.Position = UDim2.fromOffset(0, 4) inner.Parent = sc
        local update = U.fitCanvas(sc, inner, 10)
        update()
        check("canvas: UIScale is taken out", U.uiScale(sc) == 0.5 and sc.AutomaticCanvasSize == Enum.AutomaticSize.None and sc.CanvasSize.Y.Offset == 474)
        host:Destroy()
    end

    ------------------------------------------------------------------ v1.9.5 audit round
    do
        local misc5
        for _, t in ipairs(window.Tabs) do if t.Title == "Live" then misc5 = t end end
        misc5:Select() wait(0.2)
        local c5 = misc5:Card({ Title = "Audit195" })
        -- a long value next to a short name borrows room from the name
        local inf = c5:Info({ Title = "Mark", Value = "Limited · client-side only and then some" }) wait(0.1)
        local v = inf.Row:FindFirstChild("Value")
        check("info: long value gets more room", v.Position.X.Scale == 0 and v.Position.X.Offset < inf.Row.AbsoluteSize.X * 0.42)
        -- multi dropdown: names that do not fit become "+N"
        local dd = c5:Dropdown({ Title = "Parts", Multi = true, Options = { "Name", "Health", "Distance", "Weapon", "Team" }, Default = { "Name", "Health", "Distance", "Weapon", "Team" } }) wait(0.1)
        local shown = dd.Row:FindFirstChild("Select"):FindFirstChildWhichIsA("TextLabel").Text
        check("dropdown: overflow as +N", shown:find("+", 1, true) ~= nil and shown:sub(1, 4) == "Name")
        -- split button in a narrow row: the chosen option hides before the title is cut
        local r5 = c5:Row()
        r5:Button({ Title = "Rejoin" })
        local split = r5:Button({ Title = "Hop", Icon = "shuffle", Menu = { "A much longer option name" } }) wait(0.2)
        local sel = split.Row:FindFirstChild("Selected", true)
        local txt = split.Row:FindFirstChild("Text", true)
        check("split button: title kept, option hidden when tight", txt.TextTruncate == Enum.TextTruncate.None and sel.Visible == false)
        -- an action input without a hint has no empty line under it
        local ai = c5:ActionInput({ Placeholder = "Job ID", Button = "Join", Validate = function(t) return #t > 3, #t > 3 and "ok" or "short" end })
        check("action input: no empty hint line", ai.Row:FindFirstChild("HintRow").Visible == false)
        ai.Row:FindFirstChild("Box", true).Text = "ab" wait()
        check("action input: hint appears with a message", ai.Row:FindFirstChild("HintRow").Visible == true)
        -- toggle key as a key cap (no brackets)
        local tk = c5:Toggle({ Title = "Capped", Bindable = true, Bind = Enum.KeyCode.KeypadSeven })
        local cap = tk.Row:FindFirstChild("Bind")
        check("toggle key cap", cap.Text == "NUM 7" or cap.Text == Lib.Util.keyName(Enum.KeyCode.KeypadSeven))
        check("toggle key cap has an outline", cap:FindFirstChildWhichIsA("UIStroke") ~= nil)
        -- help is an icon now
        local hp = c5:Toggle({ Title = "Helped", Help = "Some help" })
        check("help icon", hp.Row:FindFirstChild("Help"):FindFirstChild("Icon") ~= nil)
        -- Escape closes an open popup
        MOCK.click(dd.Row:FindFirstChild("Select")) wait()
        local opened = window._popup ~= nil
        MOCK.press(Enum.KeyCode.Escape) wait()
        check("escape closes popup", opened and window._popup == nil)
        -- recolouring touches only what changed: a role nothing uses leaves every object alone
        local T = Lib.Theme
        local probe = Instance.new("Frame") probe.Parent = window.gui
        T.bind(probe, "BackgroundColor3", "card")
        probe.BackgroundColor3 = Color3.new(1, 0, 1) -- (pretend something else painted it)
        T.set("success", T.get("success"))         -- same colour: no recolour pass at all
        check("theme: unchanged colour skips the pass", probe.BackgroundColor3 == Color3.new(1, 0, 1))
        T.set("card", T.get("card"):Lerp(Color3.new(1, 1, 1), 0.01))
        check("theme: changed role recolours", probe.BackgroundColor3 == T.get("card"))
        probe:Destroy()
        -- text widths are cached
        local U = Lib.Util
        check("textWidth cache", U.textWidth("cache me", 10) == U.textWidth("cache me", 10))
        c5.frame:Destroy()
        -- card heading: dot by default, Icon replaces it, Dot = false leaves the plain title
        local cd1 = misc5:Card({ Title = "Dotted" })
        local cd2 = misc5:Card({ Title = "Iconed", Icon = "info" })
        local cd3 = misc5:Card({ Title = "Plain", Dot = false })
        local function head(c) return c.frame:FindFirstChild("Heading") end
        check("card dot by default", head(cd1):FindFirstChild("Dot") ~= nil)
        check("card icon replaces the dot", head(cd2):FindFirstChild("CardIcon") ~= nil and head(cd2):FindFirstChild("Dot") == nil)
        check("Dot = false: plain title at the edge", head(cd3):FindFirstChild("Dot") == nil and cd3.titleLabel.Position.X.Offset == 0)
        cd1.frame:Destroy() cd2.frame:Destroy() cd3.frame:Destroy()
        -- hiding fades the window outline together with the inside (and it comes back with it)
        window:SetAccentGlow(false)
        window:SetVisible(false) wait(0.3)
        check("hide fades the outline too", window.mainStroke.Transparency >= 0.99 and window.main.GroupTransparency >= 0.99)
        window:SetVisible(true) wait(0.3)
        check("show brings the outline back", window.mainStroke.Transparency <= 0.01 and window.main.GroupTransparency <= 0.01)
        local dockEdge = window.dock:FindFirstChildWhichIsA("UIStroke")
        check("dock outline back too", dockEdge and dockEdge.Transparency <= 0.01)
    end

    -- re-creating a window with the same title replaces the old one
    local second = Lib:CreateWindow({ Title = "Qustāh" }) wait(0.1)
    check("old window destroyed on re-run", window.alive == false and gui.Parent == nil)
    second:Destroy() wait(0.1)
    check("destroy removes gui", second.gui.Parent == nil)
    MOCK.press(Enum.KeyCode.F) wait(0.1)
    check("binds dead after destroy", true)

    print(string.format("== LIB TESTS: %d passed, %d failed", passed, failed))
end
