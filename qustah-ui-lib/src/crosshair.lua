-- Crosshair drawn from frames: Plus, Plus + Dot, X, Dot, Circle, Circle + Dot.
--   local xh = Lib.Crosshair.Overlay({ Enabled = true, Style = "X" })   -- on screen, follows the mouse
--   xh:Update({ Color = Color3.fromRGB(255, 80, 80), Spin = true })     -- only the given keys change
--   xh:Destroy()
-- card:CrosshairPreview({ Height = 110 }) draws the same settings at 2x in a card (element:Update(settings)).
-- Settings: Enabled, Style, Color, Opacity (0 - 100), Outline (a thin black edge), Length, Thickness, Gap (px),
-- Spin, SpinSpeed (degrees a second).
local Util = require("util")

local create, corner, stroke = Util.create, Util.corner, Util.stroke
local Crosshair = { Styles = { "Plus", "Plus + Dot", "X", "Dot", "Circle", "Circle + Dot" } }

local DEFAULTS = {
    Enabled = true, Style = "Plus", Color = Color3.new(1, 1, 1), Opacity = 100, Outline = true,
    Length = 8, Thickness = 2, Gap = 4, Spin = false, SpinSpeed = 120,
}
-- a full settings table: the defaults, then `settings`
function Crosshair.settings(settings)
    local out = {}
    for key, value in pairs(DEFAULTS) do out[key] = value end
    for key, value in pairs(settings or {}) do out[key] = value end
    return out
end

-- The frames of one crosshair under `parent` (arms, a dot, a ring around a zero-size root):
-- { root, layout(settings, scale), baseRotation } - the X style is the Plus turned by 45 degrees.
function Crosshair.build(parent, zindex)
    local root = create("Frame", { Name = "Crosshair", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(0, 0), ZIndex = zindex, Parent = parent })
    local arms = {}
    for index = 1, 4 do
        local arm = create("Frame", { Name = "Arm" .. index, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = zindex, Parent = root })
        arms[index] = { frame = arm, edge = stroke(arm, Color3.new(), 0, 1) }
    end
    local dot = create("Frame", { Name = "Dot", BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = zindex, Parent = root })
    corner(dot, 999)
    local dotEdge = stroke(dot, Color3.new(), 0, 1)
    local ring = create("Frame", { Name = "Ring", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = zindex, Parent = root })
    corner(ring, 999)
    local ringLine = stroke(ring, nil, 0, 1)
    local self = { root = root, baseRotation = 0 }
    function self.layout(settings, scale)
        scale = scale or 1
        local style = settings.Style or "Plus"
        local color = typeof(settings.Color) == "Color3" and settings.Color or Color3.new(1, 1, 1)
        local alpha = 1 - math.clamp((tonumber(settings.Opacity) or 100) / 100, 0, 1)
        local length = (tonumber(settings.Length) or 8) * scale
        local thick = math.max(1, (tonumber(settings.Thickness) or 2) * scale)
        local gap = (tonumber(settings.Gap) or 4) * scale
        local outline = settings.Outline ~= false
        local hasArms = style == "Plus" or style == "Plus + Dot" or style == "X"
        local hasDot = style == "Dot" or style == "Plus + Dot" or style == "Circle + Dot"
        local hasRing = style == "Circle" or style == "Circle + Dot"
        for index, arm in ipairs(arms) do
            local horizontal = index <= 2
            local offset = ((index % 2 == 1) and -1 or 1) * (gap + length / 2)
            arm.frame.Visible = hasArms
            arm.frame.Size = horizontal and UDim2.fromOffset(length, thick) or UDim2.fromOffset(thick, length)
            arm.frame.Position = horizontal and UDim2.fromOffset(offset, 0) or UDim2.fromOffset(0, offset)
            arm.frame.BackgroundColor3, arm.frame.BackgroundTransparency = color, alpha
            arm.edge.Enabled, arm.edge.Transparency = outline, alpha
        end
        local dotSize = math.max(2, thick * 1.6)
        dot.Visible, dot.Size = hasDot, UDim2.fromOffset(dotSize, dotSize)
        dot.BackgroundColor3, dot.BackgroundTransparency = color, alpha
        dotEdge.Enabled, dotEdge.Transparency = outline, alpha
        local radius = gap + length
        ring.Visible, ring.Size = hasRing, UDim2.fromOffset(radius * 2, radius * 2)
        ringLine.Color, ringLine.Thickness, ringLine.Transparency = color, thick, alpha
        self.baseRotation = style == "X" and 45 or 0
    end
    return self
end

-- A crosshair on screen at the mouse (its own ScreenGui; the per-frame follow only runs while it is enabled).
function Crosshair.Overlay(settings)
    local gui = Util.screenGui("QustahUI_Crosshair", 50)
    local drawn = Crosshair.build(gui, 1)
    local UserInputService, RunService = Util.Services.UserInputService, Util.Services.RunService
    local self = { settings = Crosshair.settings({ Enabled = false }), gui = gui, root = drawn.root }
    local connection, angle = nil, 0
    local function follow(dt)
        local mouse = UserInputService:GetMouseLocation()
        drawn.root.Position = UDim2.fromOffset(mouse.X, mouse.Y)
        if self.settings.Spin then angle = (angle + (tonumber(self.settings.SpinSpeed) or 120) * dt) % 360 else angle = 0 end
        drawn.root.Rotation = drawn.baseRotation + angle
    end
    function self:Update(changes)
        for key, value in pairs(changes or {}) do self.settings[key] = value end
        local on = self.settings.Enabled == true and gui.Parent ~= nil
        gui.Enabled = on
        drawn.layout(self.settings, 1)
        if on and not connection then
            connection = RunService.RenderStepped:Connect(follow)
            follow(0)
        elseif not on and connection then
            connection:Disconnect()
            connection = nil
        end
    end
    function self:SetEnabled(on) self:Update({ Enabled = on == true }) end
    function self:Destroy()
        if connection then connection:Disconnect() connection = nil end
        gui:Destroy()
    end
    self:Update(settings)
    return self
end

return Crosshair
