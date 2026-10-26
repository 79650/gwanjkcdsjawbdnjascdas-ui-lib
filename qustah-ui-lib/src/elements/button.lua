-- card:Button({ Title, Desc, Callback, Confirm, Locked })
-- Confirm = true (or a text) asks for a second click within 2 seconds before running the callback.
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")

local create, corner, stroke = Util.create, Util.corner, Util.stroke

return function(card, cfg)
    local height = cfg.Desc and 44 or 28
    local row = create("Frame", { Name = tostring(cfg.Title or "Button"), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, height), LayoutOrder = card:_order(), Parent = card.body })
    local button = create("TextButton", {
        Name = "Button", Size = UDim2.new(1, 0, 0, 28), BorderSizePixel = 0, Text = tostring(cfg.Title or "Button"),
        TextSize = 10, Font = Enum.Font.Gotham, AutoButtonColor = false, Parent = row,
    })
    Theme.bind(button, "BackgroundColor3", "input")
    Theme.bind(button, "TextColor3", "text")
    corner(button, 6)
    local outline = stroke(button)
    Theme.bind(outline, "Color", "buttonEdge")
    local desc
    if cfg.Desc then
        desc = Util.label(row, tostring(cfg.Desc), 9, { Position = UDim2.fromOffset(2, 30), Size = UDim2.new(1, -4, 0, 14) })
        Theme.bind(desc, "TextColor3", "muted")
    end

    local element = Base.element(card, "Button", cfg, row, button, desc)
    element.Text = button.Text
    function element:SetTitle(text) self.Text = tostring(text) button.Text = self.Text end
    function element:Fire() Util.safe(cfg.Callback) end

    button.MouseEnter:Connect(function() Theme.tweenTo(button, "BackgroundColor3", "hover", 0.12) Theme.tweenTo(button, "TextColor3", "heading", 0.12) end)
    button.MouseLeave:Connect(function() Theme.tweenTo(button, "BackgroundColor3", "input", 0.12) Theme.tweenTo(button, "TextColor3", "text", 0.12) end)
    local armed = 0
    button.Activated:Connect(function()
        if element.Locked then return end
        if cfg.Confirm then
            if armed == 0 then
                armed = armed + 1
                local token = armed
                button.Text = type(cfg.Confirm) == "string" and cfg.Confirm or "Click again to confirm"
                Theme.tweenTo(outline, "Color", "accent", 0.1)
                task.delay(2, function()
                    if armed == token and button.Parent then armed = 0 button.Text = element.Text Theme.tweenTo(outline, "Color", "buttonEdge", 0.1) end
                end)
                return
            end
            armed = 0
            button.Text = element.Text
            Theme.tweenTo(outline, "Color", "buttonEdge", 0.1)
        end
        Util.safe(cfg.Callback)
    end)
    return Base.finish(element, cfg)
end
