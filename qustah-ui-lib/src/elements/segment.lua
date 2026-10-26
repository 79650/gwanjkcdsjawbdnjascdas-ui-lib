-- card:Segment({ Title, Desc, Flag, Options = { "Head", "Body", "Closest" }, Default, Callback, Locked })
-- One choice shown as a row of buttons (Qustah's Aim Part / Priority rows). On a narrow card the buttons move
-- under the title.
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")

local create, corner, stroke = Util.create, Util.corner, Util.stroke

return function(card, cfg)
    local options = {}
    for _, option in ipairs(cfg.Options or cfg.Values or {}) do options[#options + 1] = tostring(option) end
    local row, title, desc = Base.row(card, cfg, 40, {})
    title.Size = UDim2.new(0, 110, 0, cfg.Desc and 18 or 40)
    if desc then desc.Size = UDim2.new(0, 110, 0, 14) end
    local strip = create("Frame", {
        Name = "Segments", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 120, 0.5, 0),
        Size = UDim2.new(1, -120, 0, 28), Parent = row,
    })

    local element = Base.element(card, "Segment", cfg, row, title, desc)
    local buttons, outlines = {}, {}
    local function render(animate)
        local duration = animate and 0.12 or nil
        for index, option in ipairs(options) do
            local selected = option == element.Value
            Theme.tweenTo(buttons[index], "BackgroundColor3", selected and "selected" or "input", duration)
            Theme.tweenTo(buttons[index], "TextColor3", selected and "accent" or "muted", duration)
            Theme.tweenTo(outlines[index], "Color", selected and "accent" or "line", duration)
            outlines[index].Transparency = selected and 0.25 or 0.65
        end
    end
    for index, option in ipairs(options) do
        local button = create("TextButton", {
            Name = option, Text = option, TextSize = 10, Font = Enum.Font.GothamMedium, AutoButtonColor = false, BorderSizePixel = 0,
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new((index - 0.5) / #options, 0, 0.5, 0),
            Size = UDim2.new(1 / #options, -4, 0, 24), TextTruncate = Enum.TextTruncate.AtEnd, Parent = strip,
        })
        corner(button, 6)
        buttons[index], outlines[index] = button, stroke(button)
        button.Activated:Connect(function() if not element.Locked then element:Set(option) end end)
    end

    -- narrow card: title on top, buttons underneath
    local function fit()
        local stacked = row.AbsoluteSize.X > 0 and row.AbsoluteSize.X < 300
        row.Size = UDim2.new(1, 0, 0, stacked and 70 or (cfg.Desc and 46 or 40))
        strip.AnchorPoint = stacked and Vector2.new(0, 0) or Vector2.new(0, 0.5)
        strip.Position = stacked and UDim2.fromOffset(0, cfg.Desc and 40 or 30) or UDim2.new(0, 120, 0.5, 0)
        strip.Size = stacked and UDim2.new(1, 0, 0, 28) or UDim2.new(1, -120, 0, 28)
        title.Size = UDim2.new(stacked and 1 or 0, stacked and 0 or 110, 0, cfg.Desc and 18 or (stacked and 28 or 40))
    end
    row:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)

    function element:Set(value, silent)
        value = value ~= nil and tostring(value) or nil
        if value and not table.find(options, value) then return end
        local changed = value ~= self.Value
        self.Value = value
        render(true)
        self:_fire(value, silent or not changed)
    end
    function element:Get() return self.Value end

    element.Value = cfg.Default ~= nil and table.find(options, tostring(cfg.Default)) and tostring(cfg.Default) or options[1]
    render(false)
    fit()
    element:_fire(element.Value, true)
    return Base.finish(element, cfg)
end
