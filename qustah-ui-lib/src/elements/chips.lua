-- card:Chips({ Title, Flag, Items = { "ESP", { Title = "Silent Aim", Icon = "crosshair" }, ... }, Multi = true,
--              Default = { "ESP" }, Callback = function(value) end })
-- A wrapping row of rounded chips. Multi = true: each chip turns on / off (value = list of names);
-- Multi = false: one chosen at a time (value = the name). Lit chips get the accent outline.
-- :Set(value), :Get(), :SetItems(items).
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")
local Icons = require("icons")

local create, corner, label = Util.create, Util.corner, Util.label

return function(card, cfg)
    local multi = cfg.Multi ~= false
    local top = cfg.Title and 22 or 0
    local holder = create("Frame", { Name = tostring(cfg.Title or "Chips"), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, top + 24), LayoutOrder = card:_order(), Parent = card.body })
    local title
    if cfg.Title then
        title = label(holder, tostring(cfg.Title), 11, { Name = "Title", Size = UDim2.new(1, 0, 0, 20) })
        Theme.bind(title, "TextColor3", "text")
    end
    local area = create("Frame", { Name = "Chips", BackgroundTransparency = 1, Position = UDim2.fromOffset(0, top), Size = UDim2.new(1, 0, 1, -top), Parent = holder })
    local element = Base.element(card, "Chips", cfg, holder, title, nil)
    local chips = {}
    local function chosen(name)
        if multi then return type(element.Value) == "table" and table.find(element.Value, name) ~= nil end
        return element.Value == name
    end
    local function render()
        for _, chip in ipairs(chips) do
            local on = chosen(chip.name)
            Theme.tweenTo(chip.button, "BackgroundColor3", on and "selected" or "input", 0.1)
            Theme.tweenTo(chip.edge, "Color", on and "accent" or "buttonEdge", 0.1)
            chip.edge.Transparency = on and 0.35 or 0.3
            Theme.tweenTo(chip.text, "TextColor3", on and "heading" or "muted", 0.1)
            if chip.icon then Theme.tweenTo(chip.icon, "ImageColor3", on and "heading" or "muted", 0.1) end
        end
    end
    -- lays the chips out left to right, wrapping (sizes from the text)
    local function layout()
        local width = area.AbsoluteSize.X / (card.window.scale and card.window.scale.Scale or 1)
        if width <= 0 then width = 400 end
        local x, y = 0, 0
        for _, chip in ipairs(chips) do
            local w = chip.width
            if x > 0 and x + w > width then x, y = 0, y + 28 end
            chip.button.Position = UDim2.fromOffset(x, y)
            x = x + w + 6
        end
        holder.Size = UDim2.new(1, 0, 0, top + y + 24)
    end
    function element:SetItems(items)
        for _, chip in ipairs(chips) do chip.button:Destroy() end
        table.clear(chips)
        for index, item in ipairs(items or {}) do
            if type(item) ~= "table" then item = { Title = item } end
            local name = tostring(item.Title)
            local iconW = item.Icon and 16 or 0
            local width = Util.textWidth(name, 10, Enum.Font.GothamMedium) + 22 + iconW
            local button = create("TextButton", { Name = name, Text = "", AutoButtonColor = false, BorderSizePixel = 0, Size = UDim2.fromOffset(width, 24), LayoutOrder = index, Parent = area })
            corner(button, 12)
            local edge = Util.stroke(button, nil, 0.3)
            local icon = item.Icon and Icons.themed(button, item.Icon, 11, "muted", { Name = "Icon", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 10, 0.5, 0) })
            local text = label(button, name, 10, { Name = "Text", Position = UDim2.fromOffset(11 + (icon and 15 or 0), 0), Size = UDim2.new(1, -16, 1, 0), Font = Enum.Font.GothamMedium, TextTruncate = Enum.TextTruncate.None })
            local chip = { name = name, button = button, edge = edge, text = text, icon = icon, width = width }
            chips[#chips + 1] = chip
            button.Activated:Connect(function()
                if element.Locked then return end
                if multi then
                    local value = table.clone(type(element.Value) == "table" and element.Value or {})
                    local at = table.find(value, name)
                    if at then table.remove(value, at) else value[#value + 1] = name end
                    element:Set(value)
                else
                    element:Set(name)
                end
            end)
        end
        layout()
        render()
    end
    function element:Set(value, silent)
        if multi and type(value) ~= "table" then value = value ~= nil and { value } or {} end
        self.Value = value
        render()
        self:_fire(value, silent)
    end
    function element:Get() return self.Value end
    area:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
    element:SetItems(cfg.Items)
    element.Value = cfg.Default ~= nil and cfg.Default or (multi and {} or nil)
    if multi and type(element.Value) ~= "table" then element.Value = { element.Value } end
    render()
    element:_fire(element.Value, true)
    return Base.finish(element, cfg)
end
