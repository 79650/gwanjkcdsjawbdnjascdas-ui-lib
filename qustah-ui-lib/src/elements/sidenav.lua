-- local nav = card:SideNav({ Width = 140, Height = 320, Items = { { "Appearance", "palette" }, { "Behaviour", "sliders-horizontal" } } })
-- local look = nav:Section("Appearance")       -- a card-like part: look:Toggle({ ... }), look:Slider({ ... }), ...
-- A menu down the left of the card and the chosen part on the right (one part shows at a time). nav:Select(name),
-- nav.Selected, nav:OnSelect(function(name) end). Footer = function(part) end builds something under the menu
-- (an Unload button...). No flag.
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")
local Icons = require("icons")

local create, corner, label = Util.create, Util.corner, Util.label

return function(card, cfg)
    local width = tonumber(cfg.Width) or 140
    local holder = create("Frame", { Name = tostring(cfg.Title or "SideNav"), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, tonumber(cfg.Height) or 200), LayoutOrder = card:_order(), Parent = card.body })
    local menu = create("Frame", { Name = "Menu", BackgroundTransparency = 1, Size = UDim2.new(0, width, 1, 0), Parent = holder })
    local list = create("Frame", { Name = "Items", BackgroundTransparency = 1, Size = UDim2.new(1, -8, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = menu })
    Util.list(list, 2)
    local divider = create("Frame", { Name = "Divider", Position = UDim2.new(0, width, 0, 0), Size = UDim2.new(0, 1, 1, 0), BorderSizePixel = 0, Parent = holder })
    Theme.bind(divider, "BackgroundColor3", "line")
    local content = create("Frame", { Name = "Content", BackgroundTransparency = 1, Position = UDim2.fromOffset(width + 12, 0), Size = UDim2.new(1, -width - 12, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = holder })
    local element = Base.element(card, "SideNav", { Title = cfg.Title }, holder, nil, nil)
    local parts, buttons, listeners = {}, {}, {}

    local function paint()
        for name, button in pairs(buttons) do
            local on = name == element.Selected
            Theme.tweenTo(button.frame, "BackgroundColor3", on and "selected" or "card", 0.1)
            button.frame.BackgroundTransparency = on and 0 or 1
            Theme.tweenTo(button.text, "TextColor3", on and "heading" or "muted", 0.1)
            if button.icon then Theme.tweenTo(button.icon, "ImageColor3", on and "heading" or "muted", 0.1) end
        end
    end
    function element:Section(name)
        name = tostring(name)
        if parts[name] then return parts[name] end
        local body = create("Frame", { Name = name, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Visible = false, Parent = content })
        Util.list(body, 4)
        local part = setmetatable({ page = card.page, window = card.window, order = 0, body = body, frame = card.frame, title = name }, getmetatable(card))
        parts[name] = part
        if not self.Selected then self:Select(name) end
        return part
    end
    function element:Select(name)
        name = tostring(name)
        self.Selected = name
        for other, part in pairs(parts) do part.body.Visible = other == name end
        paint()
        for _, callback in ipairs(listeners) do card.window:_safe("SideNav", callback, name) end
    end
    function element:OnSelect(callback) listeners[#listeners + 1] = callback return self end
    for index, item in ipairs(cfg.Items or {}) do
        if type(item) ~= "table" then item = { item } end
        local name, iconName = tostring(item[1] or item.Title), item[2] or item.Icon
        local frame = create("TextButton", { Name = name, Text = "", AutoButtonColor = false, BorderSizePixel = 0, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 28), LayoutOrder = index, Parent = list })
        corner(frame, 7)
        local icon = iconName and Icons.themed(frame, iconName, 13, "muted", { Name = "Icon", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 9, 0.5, 0) })
        local text = label(frame, name, 10, { Name = "Title", Position = UDim2.fromOffset(icon and 29 or 10, 0), Size = UDim2.new(1, -36, 1, 0) })
        buttons[name] = { frame = frame, text = text, icon = icon }
        frame.Activated:Connect(function() element:Select(name) end)
        element:Section(name)
    end
    if cfg.Footer then
        -- under the menu items (an Unload button...)
        local foot = create("Frame", { Name = "Footer", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 1e6, Parent = list })
        Util.list(foot, 4)
        Util.padding(foot, 0, 0, 10, 0)
        local part = setmetatable({ page = card.page, window = card.window, order = 0, body = foot, frame = card.frame, title = "Footer" }, getmetatable(card))
        card.window:_safe("SideNav footer", cfg.Footer, part)
    end
    -- the menu column is as tall as the content (or Height)
    local function fit()
        if cfg.Height then return end
        local scale = card.window.scale and card.window.scale.Scale or 1
        local need = math.max(list.AbsoluteSize.Y, content.AbsoluteSize.Y) / scale
        if need >= 40 then holder.Size = UDim2.new(1, 0, 0, need) end
    end
    content:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
    list:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
    task.defer(fit)
    paint()
    return Base.finish(element, cfg)
end
