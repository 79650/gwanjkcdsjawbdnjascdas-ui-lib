-- Stress / edge cases: odd inputs must never throw and never leave broken state.
getfenv(0).SMOKE_STEPS = function(MOCK)
    local E = getfenv(0)
    local Lib = E.getgenv().TestLib
    local w = Lib.Windows[1]
    local function wait(t) MOCK.advance(t or 0.2, MOCK.frame) end
    wait(2)
    if w._dialog then w._dialog:Close() end
    local fails, oddities = 0, 0
    local function try(name, fn)
        local ok, err = pcall(fn)
        if not ok then fails = fails + 1 print("STRESS FAIL " .. name .. " :: " .. tostring(err)) end
        return ok
    end
    local function odd(name, condition, detail)
        if not condition then oddities = oddities + 1 print("STRESS ODD " .. name .. (detail and (" :: " .. tostring(detail)) or "")) end
    end
    local tab = w:Tab({ Title = "Stress", Icon = "flask-conical" })
    local card = tab:Card({ Title = "Edge" })
    local errorsBefore = #w:GetErrors()

    -- 1. every element with nothing / empty settings
    for name in pairs(require and {} or {}) do end
    local kinds = { "Toggle", "Checkbox", "Slider", "Range", "Dropdown", "Segment", "Radio", "Keybind", "ColorPicker", "Gradient", "Swatches",
        "Input", "ActionInput", "Button", "Label", "Paragraph", "Info", "Divider", "Code", "Progress", "Stat", "Graph", "Console", "Table",
        "Image", "ImagePicker", "PlayerList", "Viewport" }
    for _, kind in ipairs(kinds) do
        try("empty " .. kind, function() card[kind](card, {}) end)
        try("nil cfg " .. kind, function() card[kind](card) end)
    end
    try("empty options", function()
        card:Dropdown({ Title = "D0", Options = {} })
        card:Dropdown({ Title = "D0m", Options = {}, Multi = true })
        card:Segment({ Title = "S0", Options = {} })
        card:Radio({ Title = "R0", Options = {} })
        card:Swatches({ Title = "W0", Colors = {} })
        card:ImagePicker({ Title = "I0", Images = {} })
        card:Table({ Title = "T0", Columns = {}, Rows = {} })
        card:Tabs({})
    end)

    -- 2. odd numbers
    local slider = card:Slider({ Title = "Num", Min = 0, Max = 100, Default = 50 })
    for _, v in ipairs({ "abc", 1 / 0, -1 / 0, 0 / 0, 1e300, -5, "75" }) do try("slider set " .. tostring(v), function() slider:Set(v) end) end
    odd("slider stays a number in range", type(slider.Value) == "number" and slider.Value == slider.Value and slider.Value >= 0 and slider.Value <= 100, slider.Value)
    try("slider min>max / step 0", function()
        local s2 = card:Slider({ Title = "Rev", Min = 10, Max = 0, Step = 0, Default = 5 }) s2:Set(3.3)
        local s3 = card:Slider({ Title = "Same", Min = 5, Max = 5 }) s3:Set(9)
        odd("min==max slider", s3.Value == 5, s3.Value)
    end)
    local range = card:Range({ Title = "Rng", Min = 0, Max = 10, Default = { 8, 2 } })
    odd("range keeps low <= high", range.Value[1] <= range.Value[2], range.Value[1] .. "," .. range.Value[2])
    try("range set junk", function() range:Set({ "a", 0 / 0 }) range:Set(5) range:Set(nil) end)
    local progress = card:Progress({ Title = "P", Max = 0 })
    try("progress odd", function() progress:Set(0 / 0) progress:Set(1 / 0) progress:Set(-3) progress:SetMax(0) progress:SetSteps(-1) progress:SetSteps(1000) end)
    local stat = card:Stat({ Title = "St", Value = 0 })
    try("stat odd", function() stat:Set(0 / 0) stat:Set(1 / 0) stat:Set(-1e12) stat:Set("12") stat:Add("x") end)
    odd("stat finite", stat.Value == stat.Value and stat.Value ~= 1 / 0, stat.Value)
    local graph = card:Graph({ Title = "G", Style = "Line" })
    try("graph odd", function() for _, v in ipairs({ 0 / 0, 1 / 0, -1 / 0, -5, 1e9 }) do graph:Push(v) end graph:Push(1, "nope") graph:Set(nil) end)

    -- 3. odd values for choice elements
    local dd = card:Dropdown({ Title = "DD", Options = { "A", "B" }, Default = "A" })
    try("dropdown odd", function() dd:Set("Z") dd:Set(nil) dd:Set({ "A" }) dd:Set(5) dd:SetOptions({}) dd:SetOptions({ "C" }) end)
    local mdd = card:Dropdown({ Title = "MDD", Options = { "A", "B" }, Multi = true })
    try("multi dropdown odd", function() mdd:Set("A") mdd:Set({ "A", "A", "Z" }) mdd:Set(nil) end)
    odd("multi value is a list", type(mdd.Value) == "table", type(mdd.Value))
    local kb = card:Keybind({ Title = "KB", Default = "NotAKey" })
    try("keybind odd", function() kb:Set("Q") kb:Set(123) kb:Set({}) kb:Set(Enum.KeyCode.Unknown) end)
    local cp = card:ColorPicker({ Title = "CP", Default = "zzz" })
    try("colour odd", function() cp:Set("12345") cp:Set("#FFFFFF") cp:Set(5) cp:_load({}) cp:_load(nil) end)
    odd("colour stays a Color3", typeof(cp.Value) == "Color3", cp.Value)
    local inp = card:Input({ Title = "In", Default = 123, Numeric = true })
    try("input odd", function() inp:Set(nil) inp:Set({}) inp:Set(string.rep("x", 5000)) end)

    -- 4. text that could break rich text / layout
    local nasty = "<b>bold</b> & <font color=\"#ff0000\">x</font> < > \" ' " .. string.rep("long ", 60) .. "😀 ü ş ğ"
    try("nasty texts", function()
        card:Toggle({ Title = nasty, Desc = nasty })
        card:Paragraph({ Title = nasty, Content = nasty })
        card:Label(nasty)
        card:Info({ Title = nasty, Value = nasty, Copy = true })
        tab.Pages[1]:Warning(nasty, { Title = nasty })
        w:Notify({ Title = nasty, Content = nasty })
        w:Toast(nasty)
        local c = card:Console({ Title = "C" }) c:Append(nasty, "warning") c:Print(nil, false, {})
        local t = card:Table({ Columns = { "A" }, Rows = { { nasty } } }) t:AddRow({ nil }) t:AddRow({})
        w:AddTag(nasty)
        w:SetFooter(nasty)
    end)
    try("dialog odd", function()
        w:Dialog() if w._dialog then w._dialog:Close() end
        w:Dialog({ Title = nasty, Content = nasty, Buttons = {} }) if w._dialog then w._dialog:Close() end
        w:Confirm(nil, nil, nil) if w._dialog then w._dialog:Close() end
    end)
    try("notify odd", function()
        w:Notify() w:Notify("plain") w:Notify({ Duration = -1 }) w:Notify({ Duration = 0 }) w:Notify({ Steps = 0 }) w:Notify({ Progress = 2 })
        w:Toast() w:Toast("") w:Toast({ Duration = 0 })
    end)

    -- 5. element management edge cases
    local m = card:Toggle({ Title = "Mover" })
    try("move odd", function() m:MoveTo(-5) m:MoveTo(1e6) m:MoveTo(0 / 0) m:MoveUp() m:MoveUp() m:MoveDown() end)
    try("lock odd", function() m:Lock() m:Lock("") m:Lock(nasty) m:Unlock() m:Unlock() m:SetTooltip(nil) end)
    try("remove twice", function() m:Remove() m:Remove() m:Set(true) m:Lock("x") m:SetTitle("y") end)
    try("depends odd", function()
        card:Toggle({ Title = "Dep nothing", DependsOn = "no_such_flag" })
        card:Toggle({ Title = "Dep self", Flag = "selfDep", DependsOn = "selfDep" })
        card:Toggle({ Title = "Dep bad fn", DependsOn = function() error("boom") end })
        card:Toggle({ Title = "Dep table", DependsOn = {} })
    end)
    wait(0.3)
    try("flags proxy odd", function()
        w.Flags.nothing_here = 5
        w.Flags.selfDep = "not a bool"
        local _ = w.Flags[nil]
        w:SetFlag(nil, 1)
    end)

    -- 6. window level odd calls
    try("window odd", function()
        w:SelectTab("Nope") w:SelectTab(nil)
        w:SetToggleKey(nil) w:SetToggleKey("NotAKey") w:SetToggleKey(123)
        w:KeyHint({}) w:KeyHint({ Key = "garbage" })
        tab:Page("Same") tab:Page("Same")
        w:SetBackgroundImage("garbage") w:SetBackgroundImage(nil) w:SetBackgroundTransparency("x")
        w:SetFullscreen(true) w:Minimize() w:SetFullscreen(false) w:Minimize()
        w:SetBlur(true, "big") w:SetBlur(false)
        w:SetStatus(nil) w:SetModule(nil, nil) w:ReportError(nil, nil)
        w:HeaderButton({}) w:AddTag(nil)
        w:StatsMonitor("nope") w:StatsMonitor("Off")
        w:Watermark(true, { Text = nasty }) w:Watermark(false)
    end)
    odd("menu key still valid", typeof(w.key) == "EnumItem", w.key)
    try("theme odd", function()
        Lib:SetAccent(nil) Lib:SetColor("nope", Color3.new(1, 0, 0)) Lib:SetColor("card", "red")
        Lib.Theme.applyPack("Nope") Lib.Theme.applyPack(nil)
        w.flags.__ui_theme:Set("Light") w.flags.__ui_theme:Set("Dark")
    end)

    -- 7. config odd names / files
    local cfg = w.Config
    try("config odd", function()
        for _, name in ipairs({ "", "../../evil", "con", string.rep("n", 300), "a/b\\c", "ok name" }) do cfg:Save(name) end
        cfg:Load("missing") cfg:Read("missing") cfg:Delete("missing") cfg:Rename("missing", "x") cfg:Copy("missing", "y")
        E.writefile(cfg.path .. "/broken.json", "{not json") cfg:Load("broken")
        E.writefile(cfg.path .. "/noflags.json", "{\"version\":1}") cfg:Load("noflags")
        cfg:Decode(nil) cfg:Decode("QUSTAH1:@@@@") cfg:Decode("QUSTAH1:" .. Lib.Util.base64encode("[1,2,3]"))
        cfg:Apply({ esp = { nested = true } })
    end)
    for path in pairs(MOCK.files) do
        odd("no path escape", not tostring(path):find("%.%."), path)
        local file = tostring(path):match("([^/]+)%.json$")
        odd("no reserved / long file names", not (file and (file:lower() == "con" or #file > 60)), path)
    end

    -- 8. a second window, destroy in odd moments
    local second
    try("second window", function()
        second = Lib:CreateWindow({ Title = "Second", Folder = "Second", Welcome = false })
        local c2 = second:Tab({ Title = "T" }):Card({ Title = "C" })
        c2:Toggle({ Title = "esp", Flag = "esp" }) -- the same flag as the first window
        second:SettingsTab()
    end)
    try("destroy with things open", function()
        if second then
            local c = second.Tabs[1].Pages[1]
            second:Dialog({ Title = "open" })
            second:Notify({ Title = "x" })
            second:Destroy()
            second:Destroy()
            second:SetVisible(true) second:Notify({ Title = "after destroy" })
        end
    end)
    odd("first window alive", w.alive == true)

    -- 9. callbacks that misbehave
    local depth = 0
    local loop = card:Toggle({ Title = "Self setter" })
    loop:OnChanged(function(v) depth = depth + 1 if depth < 50 then loop:Set(not v) end end)
    try("callback recursion", function() loop:Set(true) end)
    card:Button({ Title = "Yielder", Callback = function() E.task.wait(1) end }):Fire()
    try("callback error in OnChanged", function() local t = card:Toggle({ Title = "Err" }) t:OnChanged(function() error("x") end) t:Set(true) end)

    -- 10. lots of elements
    local big = tab:Card({ Title = "Big" })
    local started = os.clock()
    try("500 toggles", function() for i = 1, 500 do big:Toggle({ Title = "T" .. i, Flag = "bulk" .. i }) end end)
    print(string.format("STRESS 500 toggles built in %.2fs (mock)", os.clock() - started))
    try("dropdown 5000 options", function()
        local list = {} for i = 1, 5000 do list[i] = "Option " .. i end
        big:Dropdown({ Title = "Huge", Options = list, Multi = true })
    end)

    wait(1)
    print(string.format("== STRESS fails %d oddities %d (callback errors reported: %d)", fails, oddities, #w:GetErrors() - errorsBefore))
end
