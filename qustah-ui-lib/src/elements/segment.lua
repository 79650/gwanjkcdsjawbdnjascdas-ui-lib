-- card:Segment({ Title, Desc, Flag, Items = { "Head", "Body", "Closest" }, Default, Callback, Locked, Style })
-- One choice shown as a row of buttons (Qustah's Aim Part / Priority rows). On a narrow card the buttons move
-- under the title. Style (or CreateWindow({ SegmentStyle })): "Boxed" (a framed button each, the default),
-- "Track" (one rounded track, a thumb slides under the chosen one), "Underline" (plain words, a line under the
-- chosen one), "Line" (a short line under the chosen word only), "Dot" (a dot under it), "Divided" (words split
-- by thin bars, the chosen one bright), "Ghost" (a thin outline round the chosen word) or "Pills" (small pills as
-- wide as their word, the chosen one filled). "Tab" is Underline with a fainter base line and a word-wide
-- line; "Capsule" is Pills inside one rounded track, the filled part sliding to the chosen word.
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")

local create, corner, stroke = Util.create, Util.corner, Util.stroke

return function(card, cfg)
    local options = {}
    for _, option in ipairs(cfg.Items or {}) do options[#options + 1] = tostring(option) end
    local row, title, desc = Base.row(card, cfg, 40, {})
    title.Size = UDim2.new(0, 110, 0, cfg.Desc and 18 or 40)
    if desc then desc.Size = UDim2.new(0, 110, 0, 14) end
    local strip = create("Frame", {
        Name = "Segments", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 120, 0.5, 0),
        Size = UDim2.new(1, -120, 0, 28), Parent = row,
    })

    local window = card.window
    local style = tostring(cfg.Style or (window and window.cfg and window.cfg.SegmentStyle) or "Boxed")
    local STYLES = { Boxed = true, Track = true, Underline = true, Line = true, Dot = true, Divided = true, Ghost = true, Pills = true, Tab = true, Capsule = true }
    if not STYLES[style] then style = "Boxed" end
    local element = Base.element(card, "Segment", cfg, row, title, desc)
    element.Style = style
    element.Items = options
    local buttons, outlines = {}, {}
    local count = math.max(1, #options)
    -- the moving part of Track (a thumb behind the chosen word) and Underline (a bar under it)
    local thumb, bar
    if style == "Track" then
        Theme.bind(strip, "BackgroundColor3", "input")
        strip.BackgroundTransparency = 0
        corner(strip, 8)
        Theme.bind(stroke(strip, nil, 0.6), "Color", "line")
        thumb = create("Frame", { Name = "Thumb", BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.new(1 / count, -6, 1, -6), Parent = strip })
        Theme.bind(thumb, "BackgroundColor3", "selected")
        corner(thumb, 6)
        Theme.bind(stroke(thumb, nil, 0.55), "Color", "buttonEdge")
    elseif style == "Underline" then
        local base = create("Frame", { Name = "Line", BorderSizePixel = 0, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, 1), Parent = strip })
        Theme.bind(base, "BackgroundColor3", "line")
        bar = create("Frame", { Name = "Bar", BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 1), Size = UDim2.new(1 / count, -16, 0, 2), ZIndex = 2, Parent = strip })
        Theme.bind(bar, "BackgroundColor3", "accent")
        corner(bar, 1)
    elseif style == "Tab" then
        local base = create("Frame", { Name = "Line", BorderSizePixel = 0, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, 1), BackgroundTransparency = 0.5, Parent = strip })
        Theme.bind(base, "BackgroundColor3", "line")
        bar = create("Frame", { Name = "Bar", BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 1), Size = UDim2.fromOffset(20, 2), ZIndex = 2, Parent = strip })
        Theme.bind(bar, "BackgroundColor3", "accent")
        corner(bar, 1)
    elseif style == "Capsule" then
        -- a track as wide as its words (left), the filled thumb slides / resizes to the chosen one
        strip.BackgroundTransparency = 0
        Theme.bind(strip, "BackgroundColor3", "input")
        corner(strip, 13)
        Theme.bind(stroke(strip, nil, 0.6), "Color", "line")
        thumb = create("Frame", { Name = "Thumb", BorderSizePixel = 0, AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.fromOffset(40, 20), Parent = strip })
        Theme.bind(thumb, "BackgroundColor3", "accent")
        corner(thumb, 10)
    elseif style == "Line" then
        bar = create("Frame", { Name = "Bar", BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 1), Size = UDim2.fromOffset(20, 2), ZIndex = 2, Parent = strip })
        Theme.bind(bar, "BackgroundColor3", "accent")
        corner(bar, 1)
    elseif style == "Dot" then
        bar = create("Frame", { Name = "Dot", BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 1), Size = UDim2.fromOffset(4, 4), ZIndex = 2, Parent = strip })
        Theme.bind(bar, "BackgroundColor3", "accent")
        corner(bar, 2)
    elseif style == "Divided" then
        for index = 1, count - 1 do
            local divider = create("Frame", { Name = "Divider", BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(index / count, 0, 0.5, 0), Size = UDim2.fromOffset(1, 12), Parent = strip })
            Theme.bind(divider, "BackgroundColor3", "line")
        end
    elseif style == "Pills" then
        Util.list(strip, 6, Enum.FillDirection.Horizontal).VerticalAlignment = Enum.VerticalAlignment.Center
    end
    local function render(animate)
        local duration = animate and 0.12 or nil
        local chosen = table.find(options, element.Value) or 1
        for index, option in ipairs(options) do
            local selected = option == element.Value
            local button = buttons[index]
            if style == "Boxed" then
                Theme.tweenTo(button, "BackgroundColor3", selected and "selected" or "input", duration)
                Theme.tweenTo(button, "TextColor3", selected and "accent" or "muted", duration)
                Theme.tweenTo(outlines[index], "Color", selected and "accent" or "line", duration)
                outlines[index].Transparency = selected and 0.25 or 0.65
            elseif style == "Pills" then
                Theme.tweenTo(button, "BackgroundColor3", selected and "accent" or "input", duration)
                Theme.tweenTo(button, "TextColor3", selected and "base" or "muted", duration)
            elseif style == "Ghost" then
                Theme.tweenTo(button, "TextColor3", selected and "heading" or "muted", duration)
                outlines[index].Transparency = selected and 0.35 or 1
            elseif style == "Capsule" then
                Theme.tweenTo(button, "TextColor3", selected and "base" or "muted", duration)
            elseif style == "Line" or style == "Dot" or style == "Divided" or style == "Tab" then
                Theme.tweenTo(button, "TextColor3", selected and "heading" or "muted", duration)
            else
                Theme.tweenTo(button, "TextColor3", selected and (style == "Track" and "heading" or "accent") or "muted", duration)
            end
        end
        local target = UDim2.new((chosen - 0.5) / count, 0, thumb and 0.5 or 1, style == "Dot" and -1 or 0)
        if style == "Capsule" and buttons[chosen] then
            local button = buttons[chosen]
            target = UDim2.new(0, button.Position.X.Offset, 0.5, 0)
            if animate then Util.tween(thumb, 0.16, { Size = UDim2.fromOffset(button.Size.X.Offset, 20) }) else thumb.Size = UDim2.fromOffset(button.Size.X.Offset, 20) end
        end
        if (style == "Line" or style == "Tab") and options[chosen] then
            local width = Util.textWidth(options[chosen], 10, Enum.Font.GothamMedium) + (style == "Tab" and 16 or 6)
            if animate then Util.tween(bar, 0.16, { Size = UDim2.fromOffset(width, 2) }) else bar.Size = UDim2.fromOffset(width, 2) end
        end
        local moving = thumb or bar
        if moving then
            if animate then Util.tween(moving, 0.16, { Position = target }) else moving.Position = target end
        end
    end
    for index, option in ipairs(options) do
        local button = create("TextButton", {
            Name = option, Text = option, TextSize = 10, Font = Enum.Font.GothamMedium, AutoButtonColor = false, BorderSizePixel = 0,
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new((index - 0.5) / count, 0, 0.5, 0),
            Size = UDim2.new(1 / count, -4, 0, 24), TextTruncate = Enum.TextTruncate.AtEnd, LayoutOrder = index, ZIndex = 3, Parent = strip,
        })
        if style == "Boxed" then
            corner(button, 6)
            outlines[index] = stroke(button)
        elseif style == "Pills" then
            corner(button, 12)
            button.Size = UDim2.fromOffset(Util.textWidth(option, 10, Enum.Font.GothamMedium) + 26, 24)
        else
            button.BackgroundTransparency = 1
            if style == "Capsule" then
                button.AnchorPoint = Vector2.new(0, 0.5)
                button.ZIndex = 3
            end
            if style == "Ghost" then
                corner(button, 12)
                button.Size = UDim2.new(1 / count, -10, 0, 22)
                outlines[index] = stroke(button)
                Theme.bind(outlines[index], "Color", "accent")
            end
        end
        buttons[index] = button
        button.Activated:Connect(function() if not element.Locked then element:Set(option) end end)
        -- plain words: a word under the mouse brightens a little
        if style == "Tab" or style == "Capsule" then
            button.MouseEnter:Connect(function() if option ~= element.Value and not element.Locked then Theme.tweenTo(button, "TextColor3", "text", 0.08) end end)
            button.MouseLeave:Connect(function() if option ~= element.Value then Theme.tweenTo(button, "TextColor3", "muted", 0.08) end end)
        end
    end
    -- Capsule: each word as wide as itself, side by side from the left; the track fits around them
    if style == "Capsule" then
        local x = 3
        for _, button in ipairs(buttons) do
            local width = Util.textWidth(button.Text, 10, Enum.Font.GothamMedium) + 24
            button.Size = UDim2.fromOffset(width, 20)
            button.Position = UDim2.new(0, x, 0.5, 0)
            x = x + width + 2
        end
        strip.Size = UDim2.fromOffset(x + 1, 26)
    end

    -- narrow card: title on top, buttons underneath
    local function fit()
        local stacked = row.AbsoluteSize.X > 0 and row.AbsoluteSize.X < 300
        row.Size = UDim2.new(1, 0, 0, stacked and 70 or (cfg.Desc and 46 or 40))
        strip.AnchorPoint = stacked and Vector2.new(0, 0) or Vector2.new(0, 0.5)
        strip.Position = stacked and UDim2.fromOffset(0, cfg.Desc and 40 or 30) or UDim2.new(0, 120, 0.5, 0)
        if style == "Capsule" then
            strip.Size = UDim2.fromOffset(strip.Size.X.Offset, 26) -- (as wide as its words)
        else
            strip.Size = stacked and UDim2.new(1, 0, 0, 28) or UDim2.new(1, -120, 0, 28)
        end
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
