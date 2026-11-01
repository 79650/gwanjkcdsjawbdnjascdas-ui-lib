-- card:Notice({ Kind = "success" | "warning" | "danger" | "info", Title = "Everything is running", Desc = "1 module limited",
--              Icon = "circle-check", Button = { Title = "Debug info", Icon = "copy", Callback = function() end } })
-- A tinted strip with an icon, a bold line, a smaller line and an optional button on the right (status banners,
-- "5 unsaved changes - Save"). :Set({ Kind, Title, Desc, Icon }) changes any of them. No flag.
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")
local Icons = require("icons")

local create, corner, label = Util.create, Util.corner, Util.label

local ICONS = { success = "circle-check", warning = "circle-alert", danger = "circle-x", info = "info" }

return function(card, cfg)
    local holder = create("Frame", { Name = tostring(cfg.Title or "Notice"), BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, cfg.Desc and 44 or 34), LayoutOrder = card:_order(), Parent = card.body })
    corner(holder, 8)
    Theme.bind(holder, "BackgroundColor3", "card")
    -- a tint of the kind's colour over the card
    local tint = create("Frame", { Name = "Tint", BorderSizePixel = 0, BackgroundTransparency = 0.88, Size = UDim2.fromScale(1, 1), Parent = holder })
    corner(tint, 8)
    local edge = Util.stroke(holder, nil, 0.55)
    local title = label(holder, "", 11, { Name = "Title", Position = UDim2.fromOffset(34, cfg.Desc and 7 or 0), Size = UDim2.new(1, -150, 0, cfg.Desc and 16 or 34), Font = Enum.Font.GothamMedium })
    local desc = label(holder, "", 9, { Name = "Desc", Position = UDim2.fromOffset(34, 23), Size = UDim2.new(1, -150, 0, 13) })
    local element = Base.element(card, "Notice", { Title = cfg.Title }, holder, title, desc)
    local icon
    local state = { Kind = cfg.Kind or "info", Title = cfg.Title, Desc = cfg.Desc, Icon = cfg.Icon }
    if cfg.Button then
        local b = cfg.Button
        local text = tostring(b.Title or "OK")
        local width = Util.textWidth(text, 10, Enum.Font.GothamMedium) + (b.Icon and 34 or 20)
        local button = create("TextButton", { Name = "Button", Text = "", AutoButtonColor = false, BorderSizePixel = 0, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(width, 24), Parent = holder })
        corner(button, 6)
        Theme.bind(button, "BackgroundColor3", "card")
        Theme.bind(Util.stroke(button, nil, 0.2), "Color", "buttonEdge")
        if b.Icon then Icons.themed(button, b.Icon, 11, "text", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 9, 0.5, 0) }) end
        local bt = label(button, text, 10, { Position = UDim2.fromOffset(b.Icon and 24 or 10, 0), Size = UDim2.new(1, -(b.Icon and 30 or 20), 1, 0), Font = Enum.Font.GothamMedium })
        Theme.bind(bt, "TextColor3", "text")
        button.Activated:Connect(function() if b.Callback then element:_call(b.Callback) end end)
    end
    function element:Set(changes)
        for key, value in pairs(changes or {}) do state[key] = value end
        local role = state.Kind == "info" and "accent" or state.Kind
        Theme.bind(tint, "BackgroundColor3", role)
        Theme.bind(edge, "Color", role)
        title.Text = tostring(state.Title or "")
        Theme.bind(title, "TextColor3", role == "accent" and "heading" or role)
        desc.Text = tostring(state.Desc or "")
        desc.Visible = state.Desc ~= nil
        Theme.bind(desc, "TextColor3", "muted")
        if icon then icon:Destroy() end
        icon = Icons.themed(holder, state.Icon or ICONS[state.Kind] or "info", 16, role, { Name = "Icon", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 10, 0.5, 0) })
    end
    element:Set({})
    return Base.finish(element, cfg)
end
