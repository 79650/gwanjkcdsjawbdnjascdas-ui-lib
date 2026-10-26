-- card:Button({ Title, Desc, Callback, Confirm, Locked })
-- Confirm = true (or a text) asks for a second click within 2 seconds before running the callback.
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")
local Icons = require("icons")

local create, corner, stroke = Util.create, Util.corner, Util.stroke

return function(card, cfg)
    local height = cfg.Desc and 44 or 28
    local row = create("Frame", { Name = tostring(cfg.Title or "Button"), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, height), LayoutOrder = card:_order(), Parent = card.body })
    local button = create("TextButton", {
        Name = "Button", Size = UDim2.new(1, 0, 0, 28), BorderSizePixel = 0, Text = tostring(cfg.Title or "Button"),
        TextSize = 10, Font = Enum.Font.Gotham, AutoButtonColor = false, Parent = row,
    })
    Theme.bind(button, "BackgroundColor3", "input")
    Theme.bind(button, "TextColor3", cfg.Risky and "danger" or "text")
    corner(button, 6)
    local outline = stroke(button)
    Theme.bind(outline, "Color", "buttonEdge")
    local desc
    if cfg.Desc then
        desc = Util.label(row, tostring(cfg.Desc), 9, { Position = UDim2.fromOffset(2, 30), Size = UDim2.new(1, -4, 0, 14) })
        Theme.bind(desc, "TextColor3", "muted")
    end

    -- Icon = "name": icon + text centred together
    local textLabel
    if cfg.Icon and Icons.Get(cfg.Icon) then
        local content = create("Frame", { Name = "Content", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0, 1), AutomaticSize = Enum.AutomaticSize.X, Parent = button })
        Util.list(content, 6, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center)
        local icon = Icons.themed(content, cfg.Icon, 13, "text", { Name = "ButtonIcon", LayoutOrder = 1 })
        textLabel = Util.label(content, button.Text, 10, { Name = "Text", Size = UDim2.fromScale(0, 1), AutomaticSize = Enum.AutomaticSize.X, TextTruncate = Enum.TextTruncate.None, LayoutOrder = 2 })
        Theme.bind(textLabel, "TextColor3", "text")
        -- keep the label in step with the button's text / colour (hover, Confirm)
        button:GetPropertyChangedSignal("Text"):Connect(function() if button.Text ~= "" then textLabel.Text = button.Text button.Text = "" end end)
        button:GetPropertyChangedSignal("TextColor3"):Connect(function() textLabel.TextColor3 = button.TextColor3 icon.ImageColor3 = button.TextColor3 end)
        button.Text = ""
    end

    local element = Base.element(card, "Button", cfg, row, button, desc)
    element.Text = tostring(cfg.Title or "Button")
    function element:SetTitle(text) self.Text = tostring(text) button.Text = self.Text end
    function element:Fire() card.window:_safe(element.Text, cfg.Callback) end

    button.MouseEnter:Connect(function() Theme.tweenTo(button, "BackgroundColor3", "hover", 0.12) Theme.tweenTo(button, "TextColor3", "heading", 0.12) end)
    button.MouseLeave:Connect(function() Theme.tweenTo(button, "BackgroundColor3", "input", 0.12) Theme.tweenTo(button, "TextColor3", cfg.Risky and "danger" or "text", 0.12) end)
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
        card.window:_safe(element.Text, cfg.Callback)
    end)
    return Base.finish(element, cfg)
end
