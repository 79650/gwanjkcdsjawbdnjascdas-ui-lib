-- card:ThemeGallery({ Flag, Items = Theme.packOrder, Default = "Charcoal", Callback = function(name) end,
--                     New = function() end, NewTitle = "New theme", NewDesc = "From Edit colours" })
-- The theme packs as a grid of small windows, three to a row. Each tile is drawn in that pack's own colours (window,
-- cards with their outline, the pack's accent) whatever theme is on, so the choice is made by looking; the chosen one
-- has a ring. Glass shows its see-through panes over a soft colour background. New adds a last tile that runs the
-- callback (the settings tab opens the theme editor there). Value: the pack name. :SetItems(list) after a theme is
-- saved or deleted.
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")
local Icons = require("icons")

local create, corner, stroke, label = Util.create, Util.corner, Util.stroke, Util.label
local TILE_HEIGHT, SHOT_HEIGHT, GAP = 78, 52, 7

-- a pack's colour for a role: its own, or the base palette's
local function packColor(name, role)
    local pack = Theme.packs[name]
    local own = pack and pack[role]
    if typeof(own) == "Color3" then return own end
    return Theme.defaults[role] or Color3.new(0.5, 0.5, 0.5)
end

-- the little window: background, two cards on the left, a tall one on the right, accent marks and an input bar
local function drawShot(parent, name)
    local pack = Theme.packs[name] or {}
    local alpha = pack.extras and pack.extras.alpha or {}
    local shot = create("Frame", { Name = "Shot", Position = UDim2.fromOffset(4, 4), Size = UDim2.new(1, -8, 0, SHOT_HEIGHT),
        BackgroundColor3 = packColor(name, "base"), BackgroundTransparency = alpha.base or 0, BorderSizePixel = 0, ClipsDescendants = true, Parent = parent })
    corner(shot, 6)
    stroke(shot, packColor(name, "line"), 0)
    if alpha.base then                                               -- see-through packs: a soft colour behind
        local glow = create("Frame", { Name = "Behind", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 0, Parent = shot })
        create("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(96, 70, 190), Color3.fromRGB(40, 140, 170)), Rotation = 25, Parent = glow })
        shot.BackgroundTransparency = 1
        local tint = create("Frame", { Name = "Tint", Size = UDim2.fromScale(1, 1), BackgroundColor3 = packColor(name, "base"), BackgroundTransparency = alpha.base, BorderSizePixel = 0, ZIndex = 1, Parent = shot })
        corner(tint, 6)
    end
    local accent = Theme.neutral(name)
    local cardColor, line, input = packColor(name, "card"), packColor(name, "line"), packColor(name, "input")
    local function pane(position, size)
        local frame = create("Frame", { Position = position, Size = size, BackgroundColor3 = cardColor, BackgroundTransparency = alpha.card or 0, BorderSizePixel = 0, ZIndex = 2, Parent = shot })
        corner(frame, 3)
        stroke(frame, line, 0)
        return frame
    end
    pane(UDim2.fromOffset(5, 5), UDim2.new(0.45, -6, 0, 18))
    pane(UDim2.fromOffset(5, 27), UDim2.new(0.45, -6, 1, -32))
    local tall = pane(UDim2.new(0.45, 3, 0, 5), UDim2.new(0.55, -8, 1, -10))
    local function bar(parent, position, size, color, radius)
        local frame = create("Frame", { Position = position, Size = size, BackgroundColor3 = color, BorderSizePixel = 0, ZIndex = 3, Parent = parent })
        corner(frame, radius or 2)
        return frame
    end
    bar(shot, UDim2.fromOffset(9, 11), UDim2.new(0.45, -24, 0, 3), accent)
    bar(shot, UDim2.fromOffset(9, 33), UDim2.new(0.45, -20, 0, 7), input, 3)
    bar(tall, UDim2.new(1, -20, 0, 6), UDim2.fromOffset(14, 7), accent, 4)
    bar(tall, UDim2.new(0, 6, 0, 20), UDim2.new(1, -12, 0, 3), input)
    return shot
end

return function(card, cfg)
    local holder = create("Frame", { Name = "ThemeGallery", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, TILE_HEIGHT),
        LayoutOrder = card:_order(), Parent = card.body })
    local grid = create("UIGridLayout", { CellPadding = UDim2.fromOffset(GAP, GAP), CellSize = UDim2.new(1 / 3, -math.ceil(GAP * 2 / 3), 0, TILE_HEIGHT),
        SortOrder = Enum.SortOrder.LayoutOrder, Parent = holder })
    local element = Base.element(card, "ThemeGallery", cfg, holder, nil, nil)
    local items, tiles = {}, {}

    local function render()
        for name, tile in pairs(tiles) do
            local on = name == element.Value
            Theme.bind(tile.ring, "Color", on and "heading" or "line")
            tile.ring.Thickness = on and 1.5 or 1
            tile.ring.Transparency = on and 0 or 0.35
            Theme.bind(tile.caption, "TextColor3", on and "heading" or "text")
        end
    end
    local function tileFrame(name, order)
        local tile = create("TextButton", { Name = name, Text = "", AutoButtonColor = false, BorderSizePixel = 0, LayoutOrder = order, Parent = holder })
        Theme.bind(tile, "BackgroundColor3", "input")
        corner(tile, 9)
        local ring = stroke(tile, nil, 0.35)
        ring.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        Theme.bind(ring, "Color", "line")
        return tile, ring
    end
    local function build()
        for _, child in ipairs(holder:GetChildren()) do
            if child:IsA("GuiButton") then child:Destroy() end
        end
        table.clear(tiles)
        for index, name in ipairs(items) do
            local tile, ring = tileFrame(name, index)
            drawShot(tile, name)
            local caption = label(tile, name, 10, { Name = "Caption", Position = UDim2.fromOffset(8, SHOT_HEIGHT + 6), Size = UDim2.new(1, -16, 0, 14), Font = Enum.Font.GothamMedium,
                TextTruncate = Enum.TextTruncate.AtEnd })
            tiles[name] = { tile = tile, ring = ring, caption = caption }
            tile.Activated:Connect(function() if not element.Locked then element:Set(name) end end)
            tile.MouseEnter:Connect(function() if name ~= element.Value then Theme.tweenTo(tile, "BackgroundColor3", "hover", 0.08) end end)
            tile.MouseLeave:Connect(function() Theme.tweenTo(tile, "BackgroundColor3", "input", 0.08) end)
        end
        if type(cfg.New) == "function" then
            local tile = tileFrame("New", #items + 1)
            local box = create("Frame", { Name = "Shot", Position = UDim2.fromOffset(4, 4), Size = UDim2.new(1, -8, 0, SHOT_HEIGHT), BackgroundTransparency = 1, Parent = tile })
            corner(box, 6)
            Theme.bind(stroke(box, nil, 0.4), "Color", "buttonEdge")
            local plus = Icons.themed(box, "plus", 14, "muted", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, -6) })
            local text = label(box, tostring(cfg.NewTitle or "New theme"), 9, { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.5, plus and 4 or -6),
                Size = UDim2.new(1, -8, 0, 12), TextXAlignment = Enum.TextXAlignment.Center })
            Theme.bind(text, "TextColor3", "muted")
            local caption = label(tile, tostring(cfg.NewDesc or "From Edit colours"), 9, { Position = UDim2.fromOffset(8, SHOT_HEIGHT + 6), Size = UDim2.new(1, -16, 0, 14),
                TextTruncate = Enum.TextTruncate.AtEnd })
            Theme.bind(caption, "TextColor3", "muted")
            tile.Activated:Connect(function() if not element.Locked then element:_call(cfg.New) end end)
        end
        local count = #items + (type(cfg.New) == "function" and 1 or 0)
        local rows = math.max(1, math.ceil(count / 3))
        holder.Size = UDim2.new(1, 0, 0, rows * TILE_HEIGHT + (rows - 1) * GAP)
        render()
    end

    function element:SetItems(list, keep)
        items = {}
        for _, name in ipairs(list or {}) do if Theme.packs[tostring(name)] then items[#items + 1] = tostring(name) end end
        build()
        if not keep and not table.find(items, self.Value) then self:Set(items[1]) end
    end
    function element:Set(value, silent)
        value = value ~= nil and tostring(value) or nil
        if not value or not table.find(items, value) then return end
        local changed = value ~= self.Value
        self.Value = value
        render()
        self:_fire(value, silent or not changed)
    end
    function element:Get() return self.Value end

    for _, name in ipairs(cfg.Items or Theme.packOrder) do if Theme.packs[tostring(name)] then items[#items + 1] = tostring(name) end end
    element.Value = cfg.Default ~= nil and table.find(items, tostring(cfg.Default)) and tostring(cfg.Default) or items[1]
    build()
    element:_fire(element.Value, true)
    return Base.finish(element, cfg)
end
