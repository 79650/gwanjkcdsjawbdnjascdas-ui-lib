-- Toast notifications, bottom-right: Lib:Notify({ Title, Content, Duration = 3 }).
local Util = require("util")
local Theme = require("theme")

local create, corner, stroke, label, tween = Util.create, Util.corner, Util.stroke, Util.label, Util.tween

local Notify = {}

function Notify.holder(Lib)
    if Lib._notifyHolder and Lib._notifyHolder.Parent then return Lib._notifyHolder end
    local gui = Util.screenGui("QustahUI_Notifications", 60)
    Lib.maid:give(gui)
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
    Lib._toastOrder = (Lib._toastOrder or 0) + 1
    local duration = tonumber(cfg.Duration) or 3
    local hasContent = cfg.Content ~= nil and cfg.Content ~= ""
    local height = hasContent and 50 or 34
    local toast = create("CanvasGroup", {
        Name = "Toast", Size = UDim2.new(1, 0, 0, height), BorderSizePixel = 0, GroupTransparency = 1,
        LayoutOrder = Lib._toastOrder, Parent = holder,
    })
    Theme.bind(toast, "BackgroundColor3", "card")
    corner(toast, 8)
    Theme.bind(stroke(toast), "Color", "line")
    local marker = create("Frame", { Position = UDim2.fromOffset(12, 10), Size = UDim2.new(0, 3, 1, -20), BorderSizePixel = 0, Parent = toast })
    corner(marker, 2)
    local progress = create("Frame", { Position = UDim2.new(0, 0, 1, -2), Size = UDim2.new(1, 0, 0, 2), BorderSizePixel = 0, Parent = toast })
    if typeof(cfg.Color) == "Color3" then
        marker.BackgroundColor3, progress.BackgroundColor3 = cfg.Color, cfg.Color
    else
        Theme.bind(marker, "BackgroundColor3", "accent")
        Theme.bind(progress, "BackgroundColor3", "accent")
    end
    local title = label(toast, tostring(cfg.Title or ""), 11, { Position = UDim2.fromOffset(23, hasContent and 8 or 0), Size = UDim2.new(1, -32, 0, hasContent and 17 or height), Font = Enum.Font.GothamBold })
    Theme.bind(title, "TextColor3", "heading")
    if hasContent then
        local content = label(toast, tostring(cfg.Content), 10, { Position = UDim2.fromOffset(23, 25), Size = UDim2.new(1, -32, 0, 16) })
        Theme.bind(content, "TextColor3", "muted")
    end
    tween(toast, 0.2, { GroupTransparency = 0 })
    tween(progress, duration, { Size = UDim2.new(0, 0, 0, 2) }, Enum.EasingStyle.Linear)
    task.delay(duration, function()
        if not toast.Parent then return end
        tween(toast, 0.3, { GroupTransparency = 1 })
        task.delay(0.32, function() if toast.Parent then toast:Destroy() end end)
    end)
    return toast
end

return Notify
