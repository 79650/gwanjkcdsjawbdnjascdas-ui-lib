-- card:CrosshairPreview({ Height = 110, Scale = 2 }) - a dark box with the crosshair drawn the way the settings
-- would draw it (2x by default) and its style in the corner. element:Update(settings) takes the settings of
-- Lib.Crosshair (Style, Color, Opacity, Outline, Length, Thickness, Gap, Spin, SpinSpeed, Enabled); a spinning
-- crosshair turns at the same speed as on screen while the preview is in view.
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")
local Crosshair = require("crosshair")

local create, corner, stroke = Util.create, Util.corner, Util.stroke

return function(card, cfg)
    local window = card.window
    local box = create("Frame", {
        Name = "CrosshairPreview", Size = UDim2.new(1, 0, 0, cfg.Height or 110), BorderSizePixel = 0, ClipsDescendants = true,
        LayoutOrder = card:_order(), Parent = card.body,
    })
    Theme.bind(box, "BackgroundColor3", "base")
    corner(box, 6)
    Theme.bind(stroke(box), "Color", "line")
    local drawn = Crosshair.build(box, 2)
    drawn.root.Position = UDim2.fromScale(0.5, 0.5)
    local caption = Util.label(box, "", 8, { Name = "Caption", AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -8, 1, -5), Size = UDim2.fromOffset(140, 12), TextXAlignment = Enum.TextXAlignment.Right })
    Theme.bind(caption, "TextColor3", "muted")

    local element = Base.element(card, "CrosshairPreview", {}, box, nil, nil)
    element.Settings = Crosshair.settings()
    local spinConnection, angle = nil, 0
    local function stopSpin()
        if spinConnection then spinConnection:Disconnect() spinConnection = nil end
    end
    if window and window.maid then window.maid:give(stopSpin) end
    function element:Update(changes)
        for key, value in pairs(changes or {}) do self.Settings[key] = value end
        local settings = self.Settings
        drawn.layout(settings, cfg.Scale or 2)
        caption.Text = (settings.Enabled == false and "off · " or "") .. tostring(settings.Style)
        if settings.Spin and not spinConnection then
            spinConnection = Util.Services.RunService.RenderStepped:Connect(function(dt)
                if not box.Parent then stopSpin() return end
                if not Util.shown(box) then return end
                angle = (angle + (tonumber(self.Settings.SpinSpeed) or 120) * dt) % 360
                drawn.root.Rotation = drawn.baseRotation + angle
            end)
        elseif not settings.Spin then
            stopSpin()
            angle = 0
        end
        if not settings.Spin then drawn.root.Rotation = drawn.baseRotation end
    end
    element:Update(cfg.Settings)
    return Base.finish(element, cfg)
end
