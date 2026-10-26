-- Toast notifications, bottom-right: Lib:Notify({ Title, Content, Duration }).
-- Without Duration the time follows the text length (3-10 s). Hovering a toast pauses its timer
-- (PauseOnHover = false turns that off). At most Lib.MaxNotifications (6) are shown; the oldest makes room.
-- Lib:Toast("Saved") / Lib:Toast({ Text, Icon, Image, Color, Position = "Top" | "Bottom", Duration }): a small pill
-- at the top (or bottom) centre for quick confirmations.
local Util = require("util")
local Theme = require("theme")
local UIFont = require("font")
local Icons = require("icons")

local create, corner, stroke, label, tween = Util.create, Util.corner, Util.stroke, Util.label, Util.tween

local Notify = {}

function Notify.holder(Lib)
    if Lib._notifyHolder and Lib._notifyHolder.Parent then return Lib._notifyHolder end
    local gui = Util.screenGui("QustahUI_Notifications", 60)
    Lib.maid:give(gui)
    UIFont.register(gui, Lib.maid)
    local holder = create("Frame", {
        Name = "Toasts", BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -16, 1, -16),
        Size = UDim2.new(0, 250, 1, -32), Parent = gui,
    })
    Util.list(holder, 6, nil, nil, Enum.VerticalAlignment.Bottom)
    Lib._notifyHolder = holder
    return holder
end

function Notify.show(Lib, cfg)
    if type(cfg) == "string" then cfg = { Title = cfg } end
    cfg = cfg or {}
    local holder = Notify.holder(Lib)
    -- history (the bell in the window header); History = false keeps a toast out of it
    if cfg.History ~= false then
        Lib.NotifyHistory = Lib.NotifyHistory or {}
        table.insert(Lib.NotifyHistory, 1, { Title = tostring(cfg.Title or ""), Content = cfg.Content and tostring(cfg.Content) or nil, Color = cfg.Color, Icon = cfg.Icon, Time = os.time() })
        while #Lib.NotifyHistory > 50 do table.remove(Lib.NotifyHistory) end
        for _, listener in ipairs(Lib._historyListeners or {}) do Util.safe(listener) end
    end
    Lib._toastOrder = (Lib._toastOrder or 0) + 1
    -- reading time: about 22 characters a second on top of a short base
    local length = #tostring(cfg.Title or "") + #tostring(cfg.Content or "")
    local duration = tonumber(cfg.Duration) or math.clamp(2.5 + length * 0.045, 3, 10)
    -- Progress = 0..1 / Steps = 5 (+ Step) / Persist = true: the toast stays until :Close() or the progress reaches the end
    local tracked = cfg.Progress ~= nil or cfg.Steps ~= nil or cfg.Persist == true
    local hasContent = (cfg.Content ~= nil and cfg.Content ~= "") or cfg.Steps ~= nil
    local buttons = type(cfg.Buttons) == "table" and #cfg.Buttons > 0 and cfg.Buttons or nil
    if buttons and not cfg.Duration then duration = math.max(duration, 6) end
    local textHeight = hasContent and 50 or 34
    local height = textHeight + (buttons and 32 or 0)
    local toast = create("CanvasGroup", {
        Name = "Toast", Size = UDim2.new(1, 0, 0, height), BorderSizePixel = 0, GroupTransparency = 1,
        LayoutOrder = Lib._toastOrder, Parent = holder,
    })
    Theme.bind(toast, "BackgroundColor3", "card")
    corner(toast, 8)
    Theme.bind(stroke(toast), "Color", "line")
    local marker = create("Frame", { Position = UDim2.fromOffset(12, 10), Size = UDim2.new(0, 3, 0, textHeight - 20), BorderSizePixel = 0, Parent = toast })
    corner(marker, 2)
    local progress = create("Frame", { Position = UDim2.new(0, 0, 1, -2), Size = UDim2.new(1, 0, 0, 2), BorderSizePixel = 0, Parent = toast })
    -- Color: a Color3 or a theme role ("danger", "success", "warning"); default the accent
    local tint = (typeof(cfg.Color) == "Color3" or type(cfg.Color) == "string") and cfg.Color or "accent"
    Theme.bind(marker, "BackgroundColor3", tint)
    Theme.bind(progress, "BackgroundColor3", tint)
    -- Icon = "name": icon in place of the bar (tinted with Color / the accent)
    local textX = 23
    local icon = cfg.Icon and Icons.Get(cfg.Icon) and Icons.Image(cfg.Icon, { Name = "ToastIcon", Size = UDim2.fromOffset(16, 16) })
    if icon then
        marker.Visible = false
        icon.AnchorPoint = Vector2.new(0, 0.5)
        icon.Position = UDim2.new(0, 12, 0, textHeight / 2)
        Theme.bind(icon, "ImageColor3", tint)
        icon.Parent = toast
        textX = 36
    end
    local closeRoom = cfg.CanClose ~= false and 22 or 0
    local contentLabel
    local title = label(toast, tostring(cfg.Title or ""), 11, { Position = UDim2.fromOffset(textX, hasContent and 8 or 0), Size = UDim2.new(1, -textX - 9 - closeRoom, 0, hasContent and 17 or textHeight), Font = Enum.Font.GothamBold })
    Theme.bind(title, "TextColor3", "heading")
    if hasContent then
        contentLabel = label(toast, tostring(cfg.Content or ""), 10, { Name = "Content", Position = UDim2.fromOffset(textX, 25), Size = UDim2.new(1, -textX - 9 - closeRoom, 0, 16) })
        Theme.bind(contentLabel, "TextColor3", "muted")
    end
    local closed = false
    local timer
    local entry = { toast = toast }
    local function dismiss()
        if closed or not toast.Parent then return end
        closed = true
        if timer then timer:Disconnect() timer = nil end
        for index, item in ipairs(Lib._openToasts or {}) do if item == entry then table.remove(Lib._openToasts, index) break end end
        tween(toast, 0.25, { GroupTransparency = 1 })
        task.delay(0.27, function() if toast.Parent then toast:Destroy() end end)
    end
    entry.dismiss = dismiss
    -- too many on screen: the oldest one goes
    Lib._openToasts = Lib._openToasts or {}
    table.insert(Lib._openToasts, entry)
    local limit = math.max(1, tonumber(Lib.MaxNotifications) or 6)
    while #Lib._openToasts > limit do Lib._openToasts[1].dismiss() end
    local hovered = false
    toast.MouseEnter:Connect(function() hovered = true end)
    toast.MouseLeave:Connect(function() hovered = false end)
    -- CanClose (default true): a small x in the corner
    if cfg.CanClose ~= false then
        local close = create("TextButton", {
            Name = "Close", Text = "", AutoButtonColor = false, BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -6, 0, 6), Size = UDim2.fromOffset(18, 18), Parent = toast,
        })
        for _, rotation in ipairs({ 45, -45 }) do
            local bar = create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(9, 1.5), Rotation = rotation, BorderSizePixel = 0, Parent = close })
            Theme.bind(bar, "BackgroundColor3", "muted")
        end
        close.Activated:Connect(dismiss)
    end
    -- Buttons = { { Title = "Undo", Callback = fn, Style = "Primary" } }: a row under the text; a click closes the toast
    if buttons then
        local row = create("Frame", { Name = "Buttons", BackgroundTransparency = 1, Position = UDim2.new(0, textX, 0, textHeight - 4), Size = UDim2.new(1, -textX - 10, 0, 24), Parent = toast })
        Util.list(row, 6, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center)
        for index, spec in ipairs(buttons) do
            local text = tostring(spec.Title or "OK")
            local button = create("TextButton", {
                Name = text, Text = text, TextSize = 9, Font = Enum.Font.GothamMedium, AutoButtonColor = false, BorderSizePixel = 0,
                Size = UDim2.fromOffset(Util.textWidth(text, 9, Enum.Font.GothamMedium) + 20, 22), LayoutOrder = index, Parent = row,
            })
            corner(button, 6)
            local outline = stroke(button)
            if spec.Style == "Primary" or index == 1 then
                Theme.bind(button, "BackgroundColor3", "accentDeep")
                Theme.bind(button, "TextColor3", "accent")
                Theme.bind(outline, "Color", "accent")
                outline.Transparency = 0.5
            else
                Theme.bind(button, "BackgroundColor3", "input")
                Theme.bind(button, "TextColor3", "text")
                Theme.bind(outline, "Color", "buttonEdge")
            end
            button.Activated:Connect(function()
                Util.safe(spec.Callback)
                if spec.Close ~= false then dismiss() end
            end)
        end
    end
    tween(toast, 0.2, { GroupTransparency = 0 })

    -- Sound = true (a short built-in ping) or an asset id; Volume 0-1
    if cfg.Sound then
        pcall(function()
            local sound = Instance.new("Sound")
            sound.SoundId = cfg.Sound == true and "rbxasset://sounds/electronicpingshort.wav" or (tostring(cfg.Sound):match("^%d+$") and ("rbxassetid://" .. cfg.Sound) or tostring(cfg.Sound))
            sound.Volume = tonumber(cfg.Volume) or 0.4
            sound.Parent = Util.Services.SoundService
            sound:Play()
            task.delay(4, function() sound:Destroy() end)
        end)
    end

    -- the handle: a toast you can update (Progress / Steps) - it also answers like the Frame (toast.Parent, :FindFirstChild)
    local handle = { Frame = toast }
    local steps = tonumber(cfg.Steps)
    function handle:SetTitle(text) title.Text = tostring(text) end
    function handle:SetContent(text) if contentLabel then contentLabel.Text = tostring(text) end end
    function handle:SetProgress(value)
        value = math.clamp(tonumber(value) or 0, 0, 1)
        self.Progress = value
        tween(progress, 0.2, { Size = UDim2.new(value, 0, 0, 2) })
        if value >= 1 then task.delay(1.2, dismiss) end
    end
    function handle:SetStep(step, text)
        step = tonumber(step) or 0
        self.Step = step
        if contentLabel then contentLabel.Text = string.format("%d/%d%s", math.min(step, steps or step), steps or step, text and ("  ·  " .. tostring(text)) or "") end
        if steps and steps > 0 then self:SetProgress(step / steps) end
    end
    function handle:Close() dismiss() end
    function handle:IsOpen() return not closed and toast.Parent ~= nil end

    if tracked then
        progress.Size = UDim2.new(0, 0, 0, 2)
        if steps then handle:SetStep(tonumber(cfg.Step) or 0, cfg.Content) elseif cfg.Progress then handle:SetProgress(cfg.Progress) end
    end
    -- countdown (paused while the mouse is over the toast); the bar shows the time left
    if not tracked or cfg.Duration then
        local remaining = duration
        timer = Util.Services.RunService.Heartbeat:Connect(function(dt)
            if closed then return end
            if hovered and cfg.PauseOnHover ~= false then return end
            remaining = remaining - (tonumber(dt) or 0)
            if not tracked then progress.Size = UDim2.new(math.clamp(remaining / duration, 0, 1), 0, 0, 2) end
            if remaining <= 0 then dismiss() end
        end)
    end
    handle.Paused = function() return hovered end
    return setmetatable(handle, {
        __index = function(_, key)
            local value = toast[key]
            if type(value) == "function" then return function(_, ...) return value(toast, ...) end end
            return value
        end,
    })
end

-------------------------------------------------------------------------------- pill toasts
function Notify.pillHolder(Lib, bottom)
    Lib._pillHolders = Lib._pillHolders or {}
    local key = bottom and "Bottom" or "Top"
    local existing = Lib._pillHolders[key]
    if existing and existing.Parent then return existing end
    local gui = Lib._pillGui
    if not gui or not gui.Parent then
        gui = Util.screenGui("QustahUI_Toasts", 61)
        Lib.maid:give(gui)
        UIFont.register(gui, Lib.maid)
        Lib._pillGui = gui
    end
    local holder = create("Frame", {
        Name = key, BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, bottom and 1 or 0),
        Position = UDim2.new(0.5, 0, bottom and 1 or 0, bottom and -70 or 58), Size = UDim2.new(0, 420, 0, 120), Parent = gui,
    })
    Util.list(holder, 6, nil, Enum.HorizontalAlignment.Center, bottom and Enum.VerticalAlignment.Bottom or Enum.VerticalAlignment.Top)
    Lib._pillHolders[key] = holder
    return holder
end

function Notify.pill(Lib, cfg)
    if type(cfg) ~= "table" then cfg = { Text = tostring(cfg) } end
    local bottom = cfg.Position == "Bottom"
    local holder = Notify.pillHolder(Lib, bottom)
    Lib._pillOrder = (Lib._pillOrder or 0) + 1
    -- three at most: the oldest goes
    local open = {}
    for _, child in ipairs(holder:GetChildren()) do if child.Name == "Pill" and child:GetAttribute("Closing") ~= true then open[#open + 1] = child end end
    table.sort(open, function(a, b) return a.LayoutOrder < b.LayoutOrder end)
    while #open >= 3 do
        local old = table.remove(open, 1)
        old:SetAttribute("Closing", true)
        tween(old, 0.15, { GroupTransparency = 1 })
        task.delay(0.16, function() if old.Parent then old:Destroy() end end)
    end
    local text = tostring(cfg.Text or cfg.Title or "")
    local pill = create("CanvasGroup", {
        Name = "Pill", AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 30), BorderSizePixel = 0,
        GroupTransparency = 1, LayoutOrder = bottom and Lib._pillOrder or -Lib._pillOrder, Parent = holder, -- newest next to the edge
    })
    Theme.bind(pill, "BackgroundColor3", "card")
    corner(pill, 15)
    local tint = (typeof(cfg.Color) == "Color3" or type(cfg.Color) == "string") and cfg.Color or "accent"
    local edge = stroke(pill, nil, 0.35)
    Theme.bind(edge, "Color", cfg.Color and tint or "line")
    local row = create("Frame", { Name = "Row", BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromScale(0, 1), Parent = pill })
    Util.list(row, 7, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center)
    Util.padding(row, cfg.Image and 4 or 12, 14, 0, 0)
    if cfg.Image then
        -- a picture in a circle (avatar: Image = Util.avatar(userId))
        local image = create("ImageLabel", { Name = "Image", BorderSizePixel = 0, Size = UDim2.fromOffset(22, 22), ScaleType = Enum.ScaleType.Crop, LayoutOrder = 1, Image = tostring(cfg.Image), Parent = row })
        Theme.bind(image, "BackgroundColor3", "input")
        corner(image, 11)
    elseif cfg.Icon and Icons.Get(cfg.Icon) then
        Icons.themed(row, cfg.Icon, 14, tint, { Name = "Icon", LayoutOrder = 1 })
    end
    local caption = label(row, text, 10, { Name = "Text", AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 30), Font = Enum.Font.GothamMedium, TextTruncate = Enum.TextTruncate.None, LayoutOrder = 2, RichText = true })
    Theme.bind(caption, "TextColor3", "heading")
    create("UISizeConstraint", { MaxSize = Vector2.new(320, 30), Parent = caption })

    local scale = create("UIScale", { Scale = 0.92, Parent = pill })
    tween(pill, 0.18, { GroupTransparency = 0 })
    tween(scale, 0.22, { Scale = 1 }, Enum.EasingStyle.Back)
    local closed = false
    local function close()
        if closed or not pill.Parent then return end
        closed = true
        pill:SetAttribute("Closing", true)
        tween(pill, 0.2, { GroupTransparency = 1 })
        tween(scale, 0.2, { Scale = 0.94 })
        task.delay(0.22, function() if pill.Parent then pill:Destroy() end end)
    end
    task.delay(tonumber(cfg.Duration) or math.clamp(1.6 + #text * 0.04, 2, 6), close)
    local handle = { Frame = pill }
    function handle:SetText(value) caption.Text = tostring(value) end
    function handle:Close() close() end
    return handle
end

return Notify
