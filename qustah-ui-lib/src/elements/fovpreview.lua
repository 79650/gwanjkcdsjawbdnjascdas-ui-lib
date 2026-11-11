-- card:FovPreview({ Height = 140 }) - the aim FOV circle round the cursor exactly as big as on screen (real pixels,
-- whatever the UI scale); one too big for the box is shrunk to fit and the corner says so ("300 px · shown at 40 %").
-- element:Update(settings):
--   Radius (px on the real screen), Sides (under 16: drawn as the polygon it is), Thickness, Color,
--   Transparency (0 - 1, the outline), Filled, FillColor, FillTransparency (0 - 1), Visible (false: shown faint), HiddenReason (the note then, default "hidden").
-- Drawn again on its own when the UI scale changes.
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")

local create, corner, stroke = Util.create, Util.corner, Util.stroke

local DEFAULTS = {
    Radius = 60, Sides = 100, Thickness = 1, Color = Color3.new(1, 1, 1), Transparency = 0,
    Filled = false, FillColor = Color3.new(1, 1, 1), FillTransparency = 0.85, Visible = true,
}

return function(card, cfg)
    local window = card.window
    local box = create("Frame", {
        Name = "FovPreview", Size = UDim2.new(1, 0, 0, cfg.Height or 140), BorderSizePixel = 0, ClipsDescendants = true,
        LayoutOrder = card:_order(), Parent = card.body,
    })
    Theme.bind(box, "BackgroundColor3", "base")
    corner(box, 6)
    Theme.bind(stroke(box), "Color", "line")
    local cursor = create("Frame", { Name = "Cursor", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(4, 4), BorderSizePixel = 0, BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 3, Parent = box })
    corner(cursor, 2)
    local circle = create("Frame", { Name = "Circle", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BorderSizePixel = 0, Parent = box })
    corner(circle, 999)
    local ring = stroke(circle, nil, 0, 1)
    local lines, fills = {}, {}
    local note = Util.label(box, "", 8, { Name = "Note", AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -8, 1, -5), Size = UDim2.fromOffset(160, 12), TextXAlignment = Enum.TextXAlignment.Right })
    Theme.bind(note, "TextColor3", "muted")

    local element = Base.element(card, "FovPreview", {}, box, nil, nil)
    element.Settings = {}
    for key, value in pairs(DEFAULTS) do element.Settings[key] = value end

    local function draw()
        local s = element.Settings
        -- real screen pixels: the window's UI scale is undone (k = 1 / scale), unless the circle would not fit
        local scaleUI = window and window.scale and window.scale.Scale or 1
        local height = cfg.Height or 140
        local realRadius = math.max(tonumber(s.Radius) or 60, 1)
        local k = math.min(1 / scaleUI, (height - 14) / (2 * realRadius))
        local fit = k * scaleUI
        local radius = realRadius * k
        local sides = math.floor(tonumber(s.Sides) or 100)
        local color = typeof(s.Color) == "Color3" and s.Color or Color3.new(1, 1, 1)
        local thickness = math.max(1, (tonumber(s.Thickness) or 1) * k)
        local shown = s.Visible ~= false
        local outline = shown and math.clamp(tonumber(s.Transparency) or 0, 0, 1) or 0.85
        circle.Size = UDim2.fromOffset(radius * 2, radius * 2)
        circle.BackgroundColor3 = typeof(s.FillColor) == "Color3" and s.FillColor or Color3.new(1, 1, 1)
        -- a round circle from 16 sides up; fewer sides are drawn as the polygon they are (outline and fill)
        local polygon = sides < 16
        local fillAlpha = (s.Filled and shown) and math.clamp(tonumber(s.FillTransparency) or 0.85, 0, 1) or 1
        circle.BackgroundTransparency = polygon and 1 or fillAlpha
        -- the polygon's fill: 2 px rows, each as wide as the polygon is at that height
        local rows = (polygon and fillAlpha < 1) and math.max(1, math.ceil(radius)) or 0
        for index = 1, math.max(#fills, rows) do
            local row = fills[index]
            if not row then
                row = create("Frame", { Name = "Fill", AnchorPoint = Vector2.new(0.5, 0.5), BorderSizePixel = 0, Parent = box })
                fills[index] = row
            end
            local y = -radius + (index - 0.5) * 2
            local left, right = math.huge, -math.huge
            if index <= rows then
                for side = 1, sides do
                    local a1, a2 = (side - 1) / sides * math.pi * 2, side / sides * math.pi * 2
                    local x1, y1 = math.cos(a1) * radius, math.sin(a1) * radius
                    local x2, y2 = math.cos(a2) * radius, math.sin(a2) * radius
                    if (y1 - y) * (y2 - y) <= 0 and y1 ~= y2 then
                        local x = x1 + (x2 - x1) * (y - y1) / (y2 - y1)
                        left, right = math.min(left, x), math.max(right, x)
                    end
                end
            end
            if right > left then
                row.Position = UDim2.new(0.5, (left + right) / 2, 0.5, y)
                row.Size = UDim2.fromOffset(right - left, 2)
                row.BackgroundColor3, row.BackgroundTransparency, row.Visible = circle.BackgroundColor3, fillAlpha, true
            else
                row.Visible = false
            end
        end
        ring.Color, ring.Thickness, ring.Transparency = color, thickness, polygon and 1 or outline
        for index = 1, math.max(#lines, polygon and sides or 0) do
            local line = lines[index]
            if not line then
                line = create("Frame", { Name = "Side", AnchorPoint = Vector2.new(0.5, 0.5), BorderSizePixel = 0, ZIndex = 2, Parent = box })
                lines[index] = line
            end
            if polygon and index <= sides then
                local a1, a2 = (index - 1) / sides * math.pi * 2, index / sides * math.pi * 2
                -- from the centre of the box (like the circle), so the UI scale cannot move it off
                local x1, y1 = math.cos(a1) * radius, math.sin(a1) * radius
                local x2, y2 = math.cos(a2) * radius, math.sin(a2) * radius
                local dx, dy = x2 - x1, y2 - y1
                line.Position = UDim2.new(0.5, (x1 + x2) / 2, 0.5, (y1 + y2) / 2)
                line.Size = UDim2.fromOffset(math.sqrt(dx * dx + dy * dy) + 1, thickness)
                line.Rotation = math.deg(math.atan2(dy, dx))
                line.BackgroundColor3, line.BackgroundTransparency, line.Visible = color, outline, true
            else
                line.Visible = false
            end
        end
        note.Text = (shown and "" or (tostring(s.HiddenReason or "hidden") .. " · ")) .. math.floor(realRadius) .. " px"
            .. (fit < 0.995 and " · shown at " .. math.floor(fit * 100 + 0.5) .. " %" or " · real size")
    end
    function element:Update(changes)
        for key, value in pairs(changes or {}) do self.Settings[key] = value end
        draw()
    end

    -- the UI scale changed (the box's on-screen size with it): drawn again, so the circle stays real size
    local lastSize
    local sizeConnection = box:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        if box.AbsoluteSize ~= lastSize then lastSize = box.AbsoluteSize draw() end
    end)
    if window and window.maid then window.maid:give(sizeConnection) end
    element:Update(cfg.Settings)
    return Base.finish(element, cfg)
end
