-- card:FovPreview({ Height }) - the screen in small (its shape follows the real screen) with an aim FOV circle at
-- its real size against it, and "140 px on 1920×1080" in the corner. element:Update(settings):
--   Radius (px on the real screen), Sides (under 16: drawn as the polygon it is), Thickness, Color,
--   Transparency (0 - 1, the outline), Filled, FillColor, FillTransparency (0 - 1), Visible (false: shown faint).
-- Drawn again on its own when the screen size or the UI scale changes.
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
    local lines = {}
    local note = Util.label(box, "", 8, { Name = "Note", AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -8, 1, -5), Size = UDim2.fromOffset(160, 12), TextXAlignment = Enum.TextXAlignment.Right })
    Theme.bind(note, "TextColor3", "muted")

    local element = Base.element(card, "FovPreview", {}, box, nil, nil)
    element.Settings = {}
    for key, value in pairs(DEFAULTS) do element.Settings[key] = value end

    local function draw()
        local s = element.Settings
        local camera = workspace.CurrentCamera
        local screen = camera and camera.ViewportSize or Vector2.new(1920, 1080)
        -- the box keeps the screen's shape; everything inside is scaled the same way
        local scaleUI = window and window.scale and window.scale.Scale or 1
        local width = box.AbsoluteSize.X / scaleUI
        local height = math.clamp(width * screen.Y / math.max(screen.X, 1), 90, 200)
        box.Size = UDim2.new(1, 0, 0, height)
        local k = width / math.max(screen.X, 1)
        local radius = (tonumber(s.Radius) or 60) * k
        local sides = math.floor(tonumber(s.Sides) or 100)
        local color = typeof(s.Color) == "Color3" and s.Color or Color3.new(1, 1, 1)
        local thickness = math.max(1, (tonumber(s.Thickness) or 1) * math.max(k * 2, 0.75))
        local shown = s.Visible ~= false
        local outline = shown and math.clamp(tonumber(s.Transparency) or 0, 0, 1) or 0.85
        circle.Size = UDim2.fromOffset(radius * 2, radius * 2)
        circle.BackgroundColor3 = typeof(s.FillColor) == "Color3" and s.FillColor or Color3.new(1, 1, 1)
        circle.BackgroundTransparency = (s.Filled and shown) and math.clamp(tonumber(s.FillTransparency) or 0.85, 0, 1) or 1
        -- a round circle from 16 sides up; fewer sides are drawn as the polygon they are
        local polygon = sides < 16
        ring.Color, ring.Thickness, ring.Transparency = color, thickness, polygon and 1 or outline
        for index = 1, math.max(#lines, polygon and sides or 0) do
            local line = lines[index]
            if not line then
                line = create("Frame", { Name = "Side", AnchorPoint = Vector2.new(0.5, 0.5), BorderSizePixel = 0, ZIndex = 2, Parent = box })
                lines[index] = line
            end
            if polygon and index <= sides then
                local a1, a2 = (index - 1) / sides * math.pi * 2, index / sides * math.pi * 2
                local cx, cy = width / 2, height / 2
                local x1, y1 = cx + math.cos(a1) * radius, cy + math.sin(a1) * radius
                local x2, y2 = cx + math.cos(a2) * radius, cy + math.sin(a2) * radius
                local dx, dy = x2 - x1, y2 - y1
                line.Position = UDim2.fromOffset((x1 + x2) / 2, (y1 + y2) / 2)
                line.Size = UDim2.fromOffset(math.sqrt(dx * dx + dy * dy) + 1, thickness)
                line.Rotation = math.deg(math.atan2(dy, dx))
                line.BackgroundColor3, line.BackgroundTransparency, line.Visible = color, outline, true
            else
                line.Visible = false
            end
        end
        note.Text = (shown and "" or "hidden · ") .. math.floor(tonumber(s.Radius) or 60) .. " px on " .. math.floor(screen.X) .. "×" .. math.floor(screen.Y)
    end
    function element:Update(changes)
        for key, value in pairs(changes or {}) do self.Settings[key] = value end
        draw()
    end

    -- the box resized (UI scale, window size) or the screen size changed: drawn again
    local maid = window and window.maid
    local lastWidth
    local sizeConnection = box:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        if box.AbsoluteSize.X ~= lastWidth then lastWidth = box.AbsoluteSize.X draw() end
    end)
    local viewportConnection
    local function watchCamera()
        if viewportConnection then viewportConnection:Disconnect() viewportConnection = nil end
        local camera = workspace.CurrentCamera
        if camera then viewportConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(draw) end
        draw()
    end
    local cameraConnection = workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(watchCamera)
    if maid then
        maid:give(sizeConnection)
        maid:give(cameraConnection)
        maid:give(function() if viewportConnection then viewportConnection:Disconnect() end end)
    end
    element:Update(cfg.Settings)
    watchCamera()
    return Base.finish(element, cfg)
end
