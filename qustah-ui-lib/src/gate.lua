-- Key system: a key screen before the window opens.
--   Lib:CreateWindow({ ..., KeySystem = {
--       Keys = { "QUSTAH-1234" },                      -- accepted keys, or:
--       Check = function(key) return ok, message end,  -- your own check (may call a web API)
--       Url = "https://discord.gg/yourserver",         -- "Get key" copies this
--       Title = "Qustāh", Subtitle = "Enter your key to continue", Note = "Keys reset every 24 hours",
--       Remember = true,                               -- save the key in <Folder>/key.txt (checked again next time)
--   } })
-- CreateWindow waits until a key is accepted. Closing the key screen stops the script (OnCancel runs first).
-- Lib:ForgetKey(folder) deletes the saved key.
local Util = require("util")
local Theme = require("theme")
local Icons = require("icons")
local UIFont = require("font")

local create, corner, stroke, label, tween = Util.create, Util.corner, Util.stroke, Util.label, Util.tween

local Gate = {}

local function trim(text) return (tostring(text or ""):gsub("^%s+", ""):gsub("%s+$", "")) end

-- ok, message
local function check(spec, key)
    key = trim(key)
    if key == "" then return false, "Enter a key" end
    if type(spec.Check) == "function" then
        local ran, ok, message = pcall(spec.Check, key)
        if not ran then return false, "The key could not be checked" end
        return ok == true, message
    end
    for _, valid in ipairs(spec.Keys or {}) do
        if key == trim(valid) then return true end
    end
    return false, "Wrong key"
end
Gate.check = check

function Gate.file(folder) return folder .. "/key.txt" end

-- Blocks until a key is accepted (true) or the screen is closed (false).
function Gate.run(Lib, cfg)
    local spec = cfg.KeySystem
    -- (the same folder name Config uses)
    local folder = trim((tostring(cfg.Folder or cfg.Title or "QustahUI"):gsub("[^%w_%- ]", "")))
    if folder == "" then folder = "QustahUI" end
    local file = Gate.file(folder)
    -- a remembered key that still passes skips the screen
    if spec.Remember ~= false and type(isfile) == "function" and type(readfile) == "function" and isfile(file) then
        local ok, saved = pcall(readfile, file)
        if ok and check(spec, saved) then return true end
    end

    -- a re-run while the key screen is open replaces it (the old one counts as closed)
    local genv = (getgenv and getgenv()) or _G
    if genv.__QustahKeyGate then pcall(genv.__QustahKeyGate) end
    local gui = Util.screenGui("QustahUI_Key", 70)
    UIFont.register(gui, Lib.maid)
    local shade = create("Frame", { Name = "Shade", Size = UDim2.fromScale(1, 1), BorderSizePixel = 0, BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1, Parent = gui })
    local panel = create("CanvasGroup", {
        Name = "KeySystem", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(340, 232),
        BorderSizePixel = 0, GroupTransparency = 1, Parent = gui,
    })
    Theme.bind(panel, "BackgroundColor3", "base")
    corner(panel, 12)
    Theme.bind(stroke(panel), "Color", "edge")
    local scale = create("UIScale", { Scale = 0.96, Parent = panel })

    -- header: icon tile, title, subtitle, close
    local tile = create("Frame", { Name = "IconTile", Position = UDim2.fromOffset(20, 20), Size = UDim2.fromOffset(36, 36), BorderSizePixel = 0, Parent = panel })
    Theme.bind(tile, "BackgroundColor3", "accentDeep")
    corner(tile, 10)
    Theme.bind(stroke(tile, nil, 0.6), "Color", "accent")
    Icons.themed(tile, spec.Icon or "key-round", 17, "accent", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5) })
    local title = label(panel, tostring(spec.Title or cfg.Title or "Key system"), 15, { Name = "Title", Position = UDim2.fromOffset(68, 19), Size = UDim2.new(1, -110, 0, 20), Font = Enum.Font.GothamBold })
    Theme.bind(title, "TextColor3", "heading")
    local subtitle = label(panel, tostring(spec.Subtitle or "Enter your key to continue"), 10, { Name = "Subtitle", Position = UDim2.fromOffset(68, 39), Size = UDim2.new(1, -110, 0, 16) })
    Theme.bind(subtitle, "TextColor3", "muted")
    local close = create("TextButton", { Name = "Close", Text = "", AutoButtonColor = false, BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 14), Size = UDim2.fromOffset(26, 26), Parent = panel })
    corner(close, 6)
    Theme.bind(close, "BackgroundColor3", "input")
    Icons.themed(close, "x", 14, "muted", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5) })

    -- key box + check button
    local field = create("Frame", { Name = "Field", Position = UDim2.fromOffset(20, 74), Size = UDim2.new(1, -40, 0, 34), BorderSizePixel = 0, Parent = panel })
    Theme.bind(field, "BackgroundColor3", "input")
    corner(field, 8)
    local fieldEdge = stroke(field)
    Theme.bind(fieldEdge, "Color", "buttonEdge")
    local box = create("TextBox", {
        Name = "Box", BackgroundTransparency = 1, Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -96, 1, 0), Text = "",
        PlaceholderText = "Paste your key", TextSize = 11, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false, Parent = field,
    })
    Theme.bind(box, "TextColor3", "heading")
    Theme.bind(box, "PlaceholderColor3", "muted")
    local submit = create("TextButton", {
        Name = "Check", Text = "Check", TextSize = 10, Font = Enum.Font.GothamMedium, AutoButtonColor = false, BorderSizePixel = 0,
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -4, 0.5, 0), Size = UDim2.fromOffset(76, 26), Parent = field,
    })
    corner(submit, 6)
    Theme.bind(submit, "BackgroundColor3", "accentDeep")
    Theme.bind(submit, "TextColor3", "accent")
    local submitEdge = stroke(submit, nil, 0.45)
    Theme.bind(submitEdge, "Color", "accent")
    local status = label(panel, "", 10, { Name = "Status", Position = UDim2.fromOffset(20, 112), Size = UDim2.new(1, -40, 0, 16) })
    Theme.bind(status, "TextColor3", "muted")
    local note = label(panel, tostring(spec.Note or ""), 9, {
        Name = "Note", Position = UDim2.fromOffset(20, 132), Size = UDim2.new(1, -40, 0, 30), TextWrapped = true,
        TextTruncate = Enum.TextTruncate.None, TextYAlignment = Enum.TextYAlignment.Top,
    })
    Theme.bind(note, "TextColor3", "muted")

    -- footer: get key
    local line = create("Frame", { Position = UDim2.new(0, 0, 1, -54), Size = UDim2.new(1, 0, 0, 1), BorderSizePixel = 0, Parent = panel })
    Theme.bind(line, "BackgroundColor3", "line")
    local getKey = create("TextButton", {
        Name = "GetKey", Text = "", AutoButtonColor = false, BorderSizePixel = 0, Position = UDim2.new(0, 20, 1, -42), Size = UDim2.new(1, -40, 0, 30),
        Visible = spec.Url ~= nil, Parent = panel,
    })
    corner(getKey, 7)
    Theme.bind(getKey, "BackgroundColor3", "input")
    Theme.bind(stroke(getKey), "Color", "buttonEdge")
    local getRow = create("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Parent = getKey })
    Util.list(getRow, 6, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center)
    Icons.themed(getRow, "link", 12, "text", { LayoutOrder = 1 })
    local getText = label(getRow, "Get key", 10, { AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 30), Font = Enum.Font.GothamMedium, TextTruncate = Enum.TextTruncate.None, LayoutOrder = 2 })
    Theme.bind(getText, "TextColor3", "text")
    if not spec.Url then panel.Size = UDim2.fromOffset(340, 178) line.Visible = false end

    tween(shade, 0.2, { BackgroundTransparency = 0.45 })
    Util.fade(panel, 0.2, 0)
    tween(scale, 0.25, { Scale = 1 }, Enum.EasingStyle.Back)

    local result, busy = nil, false
    local function say(text, role)
        status.Text = tostring(text or "")
        Theme.bind(status, "TextColor3", role or "muted")
    end
    local function attempt()
        if busy or result ~= nil then return end
        busy = true
        submit.Text = "..."
        local key = trim(box.Text)
        local ok, message = check(spec, key)
        busy = false
        submit.Text = "Check"
        if ok then
            say(message or "Key accepted", "success")
            Theme.bind(fieldEdge, "Color", "success")
            if spec.Remember ~= false and type(writefile) == "function" then
                pcall(function() if type(isfolder) == "function" and not isfolder(folder) then makefolder(folder) end end)
                Util.writeAtomic(file, key)
            end
            result = true
        else
            say(message or "Wrong key", "danger")
            Theme.bind(fieldEdge, "Color", "danger")
            -- small shake
            local x = panel.Position
            task.spawn(function()
                for _, dx in ipairs({ -6, 6, -4, 4, 0 }) do
                    panel.Position = x + UDim2.fromOffset(dx, 0)
                    task.wait(0.03)
                end
            end)
        end
    end
    submit.Activated:Connect(attempt)
    box.FocusLost:Connect(function(enter) if enter then attempt() end end)
    box:GetPropertyChangedSignal("Text"):Connect(function()
        if result == nil and status.Text ~= "" then say("") Theme.bind(fieldEdge, "Color", "buttonEdge") end
    end)
    getKey.Activated:Connect(function()
        local clipboard = setclipboard or toclipboard
        local ok = type(clipboard) == "function" and pcall(clipboard, tostring(spec.Url))
        say(ok and "Link copied - open it in your browser" or tostring(spec.Url), ok and "accent" or "muted")
    end)
    close.Activated:Connect(function() result = false end)
    local function replaced() if result == nil then result = false end end
    genv.__QustahKeyGate = replaced

    while result == nil and gui.Parent do task.wait(0.05) end
    if result == nil then result = false end
    if genv.__QustahKeyGate == replaced then genv.__QustahKeyGate = nil end
    tween(shade, 0.18, { BackgroundTransparency = 1 })
    Util.fade(panel, 0.18, 1)
    task.delay(0.2, function() gui:Destroy() end)
    if result == false then Util.safe(spec.OnCancel) end
    return result
end

function Gate.forget(folder)
    local file = Gate.file(tostring(folder or "QustahUI"):gsub("[^%w_%- ]", ""))
    if type(isfile) == "function" and type(delfile) == "function" and isfile(file) then pcall(delfile, file) end
end

return Gate
