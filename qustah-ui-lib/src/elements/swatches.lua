-- card:Swatches({ Title, Desc, Flag, Colors = { { "Neutral", Color3 }, { "Blue", Color3 }, ... }, Default = "Blue", Columns = 4, Callback = function(color, name) end })
-- Named colour presets as a grid (Qustah's accent picker). Value is the chosen name; Callback gets the Color3 and the name.
-- Without Colors it uses Qustah's eight accent presets.
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
    local maxColumns = math.max(1, tonumber(cfg.Columns) or 4)
    local columns = maxColumns
    local rowsCount = math.ceil(#colors / columns)
    local top = (cfg.Title and 20 or 0) + (cfg.Desc and 16 or 0) + (cfg.Title and 4 or 0)
    local holder = create("Frame", { Name = tostring(cfg.Title or "Swatches"), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, top + rowsCount * 34), LayoutOrder = card:_order(), Parent = card.body })
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
    local function render()
        for _, entry in ipairs(entries) do
            local on = entry.name == element.Value
            Theme.tweenTo(entry.button, "BackgroundColor3", on and "selected" or "card", 0.1)
            Theme.tweenTo(entry.text, "TextColor3", on and "heading" or "muted", 0.1)
            entry.outline.Transparency = on and 0.3 or 1
        end
    end
    for index, item in ipairs(colors) do
        local name, color = tostring(item[1] or item.Name), item[2] or item.Color
        local button = create("TextButton", { Name = name, Text = "", AutoButtonColor = false, BorderSizePixel = 0, LayoutOrder = index, Parent = grid })
        corner(button, 6)
        local outline = stroke(button, Color3.new(1, 1, 1), 1)
        Theme.bind(outline, "Color", "accent")
        local dot = create("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 8, 0.5, 0), Size = UDim2.fromOffset(14, 14), BorderSizePixel = 0, BackgroundColor3 = color, Parent = button })
        corner(dot, 4)
        local text = label(button, name, 10, { Position = UDim2.fromOffset(28, 0), Size = UDim2.new(1, -32, 1, 0) })
        local entry = { name = name, color = color, button = button, text = text, outline = outline }
        entries[#entries + 1] = entry
        byName[name] = entry
        button.MouseEnter:Connect(function() if element.Value ~= name then Theme.tweenTo(button, "BackgroundColor3", "input", 0.1) end end)
        button.MouseLeave:Connect(render)
        button.Activated:Connect(function() if not element.Locked then element:Set(name) end end)
    end

    -- columns follow the width (about 90 px per chip, at most Columns)
    local function place()
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
        local entry = byName[tostring(name)]
        if not entry then return end
        local changed = entry.name ~= self.Value
        self.Value = entry.name
        self.Color = entry.color
        render()
        if self.Flag then card.window.Lib.Flags[self.Flag] = entry.name end
        if not silent and changed then
            local source = tostring(cfg.Title or "Swatches")
            card.window:_safe(source, cfg.Callback, entry.color, entry.name)
            for _, callback in ipairs(self._changed) do card.window:_safe(source, callback, entry.color, entry.name) end
        end
    end
    function element:Get() return self.Value, self.Color end

    element:Set(cfg.Default or (entries[1] and entries[1].name), true)
    return Base.finish(element, cfg)
end
