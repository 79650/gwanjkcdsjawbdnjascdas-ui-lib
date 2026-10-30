-- card:Swatches({ Title, Desc, Flag, Colors = { { "Neutral", Color3 }, { "Blue", Color3 }, ... }, Default = "Blue", Columns = 4, Callback = function(color, name) end })
-- Named colour presets as a grid (Qustah's accent picker). Value is the chosen name; Callback gets the Color3 and the name.
-- Without Colors it uses Qustah's eight accent presets.
-- Style = "Dots": one row of small round colour dots (the name shows on hover). Custom = function(open) end adds a
-- last dot for "any colour" (a script opens its own picker there); it lights up while a custom colour is chosen.
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")

local create, corner, stroke, label = Util.create, Util.corner, Util.stroke, Util.label

local PRESETS = {
    { "Neutral", Color3.fromRGB(177, 178, 183) }, { "Blue", Color3.fromRGB(61, 151, 219) },
    { "Red", Color3.fromRGB(220, 110, 110) }, { "Purple", Color3.fromRGB(165, 125, 230) },
    { "Pink", Color3.fromRGB(225, 120, 180) }, { "Green", Color3.fromRGB(110, 200, 130) },
    { "Orange", Color3.fromRGB(215, 170, 105) }, { "Cyan", Color3.fromRGB(100, 200, 210) },
}

return function(card, cfg)
    local colors = cfg.Colors or PRESETS
    local dots = cfg.Style == "Dots"
    local maxColumns = math.max(1, tonumber(cfg.Columns) or 4)
    local columns = maxColumns
    local rowsCount = math.ceil(#colors / columns)
    local top = (cfg.Title and 20 or 0) + (cfg.Desc and 16 or 0) + (cfg.Title and 4 or 0)
    local holder = create("Frame", { Name = tostring(cfg.Title or "Swatches"), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, top + (dots and 28 or rowsCount * 34)), LayoutOrder = card:_order(), Parent = card.body })
    local title, desc
    if cfg.Title then
        title = label(holder, tostring(cfg.Title), 11, { Name = "Title", Size = UDim2.new(1, 0, 0, 20) })
        Theme.bind(title, "TextColor3", "text")
    end
    if cfg.Desc then
        desc = label(holder, tostring(cfg.Desc), 9, { Name = "Desc", Position = UDim2.fromOffset(0, cfg.Title and 20 or 0), Size = UDim2.new(1, 0, 0, 14) })
        Theme.bind(desc, "TextColor3", "muted")
    end
    local grid = create("Frame", { Name = "Grid", BackgroundTransparency = 1, Position = UDim2.fromOffset(0, top), Size = UDim2.new(1, 0, 1, -top), Parent = holder })

    local element = Base.element(card, "Swatches", cfg, holder, title, desc)
    local entries, byName = {}, {}
    local customEntry
    local function render()
        for _, entry in ipairs(entries) do
            local on = entry.name == element.Value
            if dots then
                entry.outline.Transparency = on and 0 or 1
            else
                Theme.tweenTo(entry.button, "BackgroundColor3", on and "selected" or "card", 0.1)
                Theme.tweenTo(entry.text, "TextColor3", on and "heading" or "muted", 0.1)
                entry.outline.Transparency = on and 0.3 or 1
            end
        end
        if customEntry then
            local custom = element.Value == nil and element.Color ~= nil
            customEntry.outline.Transparency = custom and 0 or 1
            customEntry.fill.BackgroundColor3 = custom and element.Color or Color3.new(1, 1, 1)
            customEntry.fill.BackgroundTransparency = custom and 0 or 1
            if customEntry.icon then customEntry.icon.Visible = not custom end
        end
    end
    -- Dots: a round dot with a ring around the chosen one (the name as a tooltip)
    local function dot(name, color)
        local button = create("TextButton", { Name = name, Text = "", AutoButtonColor = false, BorderSizePixel = 0, BackgroundTransparency = 1, Size = UDim2.fromOffset(26, 26), Parent = grid })
        local fill = create("Frame", { Name = "Dot", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(18, 18), BorderSizePixel = 0, BackgroundColor3 = color or Color3.new(1, 1, 1), Parent = button })
        corner(fill, 9)
        local ringFrame = create("Frame", { Name = "Ring", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Parent = button })
        corner(ringFrame, 13)
        local outline = stroke(ringFrame, nil, 1, 1.5)
        Theme.bind(outline, "Color", "heading")
        Util.hoverPop(button, 1.08)
        button.MouseEnter:Connect(function() card.window:_tip(name) end)
        button.MouseLeave:Connect(function() card.window:_hideTip() end)
        return button, fill, outline
    end
    for index, item in ipairs(colors) do
        local name, color = tostring(item[1] or item.Name), item[2] or item.Color
        if dots then
            local button, fill, outline = dot(name, color)
            button.LayoutOrder = index
            local entry = { name = name, color = color, button = button, outline = outline, fill = fill }
            entries[#entries + 1] = entry
            byName[name] = entry
            button.Activated:Connect(function() if not element.Locked then element:Set(name) end end)
            continue
        end
        local button = create("TextButton", { Name = name, Text = "", AutoButtonColor = false, BorderSizePixel = 0, LayoutOrder = index, Parent = grid })
        corner(button, 6)
        local outline = stroke(button, Color3.new(1, 1, 1), 1)
        Theme.bind(outline, "Color", "accent")
        local dot = create("Frame", { Name = "Dot", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 8, 0.5, 0), Size = UDim2.fromOffset(14, 14), BorderSizePixel = 0, BackgroundColor3 = color, Parent = button })
        corner(dot, 4)
        local text = label(button, name, 10, { Position = UDim2.fromOffset(28, 0), Size = UDim2.new(1, -32, 1, 0) })
        local entry = { name = name, color = color, button = button, text = text, outline = outline }
        entries[#entries + 1] = entry
        byName[name] = entry
        Util.hoverPop(button, 1.04)
        button.MouseEnter:Connect(function()
            if element.Value ~= name then
                Theme.tweenTo(button, "BackgroundColor3", "input", 0.1)
                Theme.tweenTo(text, "TextColor3", "heading", 0.1)
            end
        end)
        button.MouseLeave:Connect(render)
        button.Activated:Connect(function() if not element.Locked then element:Set(name) end end)
    end

    if dots and type(cfg.Custom) == "function" then
        local button, fill, outline = dot("Custom colour", Color3.new(1, 1, 1))
        button.LayoutOrder = #entries + 1
        fill.BackgroundTransparency = 1
        local edge = stroke(fill, nil, 0, 1)
        Theme.bind(edge, "Color", "muted")
        local icon = require("icons").themed(fill, "plus", 11, "muted", { Name = "Plus", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5) })
        customEntry = { button = button, fill = fill, outline = outline, icon = icon }
        local open = false
        button.Activated:Connect(function()
            if element.Locked then return end
            open = not open
            element:_call(cfg.Custom, open)
        end)
    end
    if dots then
        -- one row, the dots spread over the width (gaps 6 - 14 px)
        local list = Util.list(grid, 8, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center)
        local function spread()
            local count = #entries + (customEntry and 1 or 0)
            local scale = card.window.scale and card.window.scale.Scale or 1
            local width = holder.AbsoluteSize.X / scale
            if width <= 0 or count < 2 then return end
            list.Padding = UDim.new(0, math.clamp(math.floor((width - count * 26) / (count - 1)), 2, 14))
        end
        holder:GetPropertyChangedSignal("AbsoluteSize"):Connect(spread)
        spread()
    end
    -- columns follow the width (about 90 px per chip, at most Columns)
    local function place()
        if dots then return end
        local width = holder.AbsoluteSize.X
        columns = width > 0 and math.clamp(math.floor((width + 6) / 90), 2, maxColumns) or maxColumns
        columns = math.min(columns, math.max(1, #entries))
        for index, entry in ipairs(entries) do
            local column, line = (index - 1) % columns, (index - 1) // columns
            entry.button.Position = UDim2.new(column / columns, column == 0 and 0 or 3, 0, line * 34)
            entry.button.Size = UDim2.new(1 / columns, -6 + (column == 0 and 3 or 0) + (column == columns - 1 and 3 or 0), 0, 28)
        end
        holder.Size = UDim2.new(1, 0, 0, top + math.ceil(#entries / columns) * 34)
    end
    holder:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        if dots then return end
        local before = columns
        local width = holder.AbsoluteSize.X
        local want = width > 0 and math.min(math.clamp(math.floor((width + 6) / 90), 2, maxColumns), #entries) or maxColumns
        if want ~= before then place() end
    end)
    place()

    function element:Set(name, silent)
        if typeof(name) == "Color3" then -- pick the preset with this colour
            for _, entry in ipairs(entries) do if entry.color == name then name = entry.name break end end
        end
        if typeof(name) == "Color3" then -- a custom colour: no preset is selected
            self.Value, self.Color = nil, name
            render()
            return
        end
        local entry = byName[tostring(name)]
        if not entry then return end
        local changed = entry.name ~= self.Value
        self.Value = entry.name
        self.Color = entry.color
        render()
        if self.Flag then card.window.Lib.Flags[self.Flag] = entry.name card.window:_flagChanged(self.Flag) end
        if not silent and changed then
            self:_call(cfg.Callback, entry.color, entry.name)
            for _, callback in ipairs(self._changed) do self:_call(callback, entry.color, entry.name) end
        end
    end
    function element:Get() return self.Value, self.Color end
    -- recolour one preset (e.g. "Neutral" per theme pack)
    function element:SetColor(name, color)
        for _, entry in ipairs(entries) do
            if entry.name == name and typeof(color) == "Color3" then
                entry.color = color
                local dot = entry.button:FindFirstChild("Dot")
                if dot then dot.BackgroundColor3 = color end
                if self.Value == name then self.Color = color end
            end
        end
    end

    element:Set(cfg.Default or (entries[1] and entries[1].name), true)
    return Base.finish(element, cfg)
end
