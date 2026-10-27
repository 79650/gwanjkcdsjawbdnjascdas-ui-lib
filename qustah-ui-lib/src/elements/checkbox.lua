-- card:Checkbox({ Title, Desc, Flag, Default = false, Callback = function(on) end, Locked })
-- A plain tick box before the title: lighter than a Toggle for lists of options. Click the row or the box.
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")
local Icons = require("icons")

local create, corner, stroke = Util.create, Util.corner, Util.stroke

return function(card, cfg)
    local row, title, desc = Base.row(card, cfg, cfg.Desc and 40 or 28, { button = true, noIcon = true })
    -- the box sits where an icon would; title / description move right of it
    local box = create("Frame", { Name = "Box", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0, cfg.Desc and 12 or 14), Size = UDim2.fromOffset(16, 16), BorderSizePixel = 0, Parent = row })
    corner(box, 4)
    local edge = stroke(box)
    local tick = Icons.themed(box, "check", 12, "onAccent", { Name = "Tick", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5) })
    title.Position = UDim2.new(0, 26, 0, title.Position.Y.Offset)
    title.Size = UDim2.new(1, -26 - (cfg.Help and 16 or 0), 0, title.Size.Y.Offset)
    if desc then desc.Position = UDim2.fromOffset(26, 23) desc.Size = UDim2.new(1, -26, 0, 14) end

    local element = Base.element(card, "Checkbox", cfg, row, title, desc)
    element.Value = cfg.Default == true
    local hovered = false
    local function render(animate)
        local on = element.Value
        local duration = animate and 0.12 or nil
        Theme.tweenTo(box, "BackgroundColor3", on and "accent" or (hovered and "hover" or "input"), duration)
        Theme.tweenTo(edge, "Color", on and "accent" or "buttonEdge", duration)
        if tick then tick.Visible = on end
    end
    function element:Set(value, silent)
        value = value == true
        local changed = value ~= self.Value
        self.Value = value
        render(true)
        self:_fire(value, silent or not changed)
    end
    function element:Get() return self.Value end

    row.Activated:Connect(function() if not element.Locked then element:Set(not element.Value) end end)
    row.MouseEnter:Connect(function() hovered = true render(true) Theme.tweenTo(title, "TextColor3", cfg.Risky and "danger" or "heading", 0.12) end)
    row.MouseLeave:Connect(function() hovered = false render(true) Theme.tweenTo(title, "TextColor3", cfg.Risky and "danger" or "text", 0.12) end)
    render(false)
    element:_fire(element.Value, true)
    return Base.finish(element, cfg)
end
