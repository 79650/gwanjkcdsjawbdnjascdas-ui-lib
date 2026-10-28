-- card:Button({ Title, Desc, Icon, Callback, Confirm, Locked, Risky,
--               Style = "Default" | "Primary" | "Soft" | "Outline" | "Ghost" | "Danger" | "Link",
--               Size = "Small" | "Default" | "Large", IconSide = "Left" | "Right", Align = "Center" | "Left" })
-- Confirm = true (or a text) asks for a second click within 2 seconds before running the callback.
-- Icon without a Title gives an icon-only button. Put buttons in card:Row() to line them up side by side.
-- element:SetStyle(style), element:SetTitle(text), element:SetIcon(name), element:Fire()
local Util = require("util")
local Theme = require("theme")
local Base = require("elements/base")
local Icons = require("icons")

local create, corner, stroke = Util.create, Util.corner, Util.stroke

-- each style: background role + transparency, text role, outline role + transparency; "hover" is the same set on hover
local STYLES = {
    Default = { bg = "input", bgT = 0, text = "text", edge = "buttonEdge", edgeT = 0,
        hover = { bg = "hover", bgT = 0, text = "heading" } },
    Primary = { bg = "accent", bgT = 0, text = "onAccent", edge = "accent", edgeT = 0,
        hover = { bg = "accent", bgT = 0.15, text = "onAccent" } },
    Soft = { bg = "accent", bgT = 0.86, text = "accent", edge = "accent", edgeT = 0.72,
        hover = { bg = "accent", bgT = 0.76, text = "accent" } },
    Outline = { bg = "hover", bgT = 1, text = "text", edge = "buttonEdge", edgeT = 0,
        hover = { bg = "hover", bgT = 0.4, text = "heading" } },
    Ghost = { bg = "hover", bgT = 1, text = "muted", edge = "buttonEdge", edgeT = 1,
        hover = { bg = "hover", bgT = 0, text = "heading" } },
    Danger = { bg = "danger", bgT = 0.86, text = "danger", edge = "danger", edgeT = 0.65,
        hover = { bg = "danger", bgT = 0.74, text = "danger" } },
    Link = { bg = "hover", bgT = 1, text = "accent", edge = "accent", edgeT = 1,
        hover = { bg = "hover", bgT = 1, text = "heading" } },
}
local SIZES = { Small = { 22, 9, 11 }, Default = { 28, 10, 13 }, Large = { 34, 11, 15 } }

local function styleName(value)
    value = tostring(value or "Default")
    for name in pairs(STYLES) do if name:lower() == value:lower() then return name end end
    return "Default"
end

return function(card, cfg)
    local size = SIZES[tostring(cfg.Size or "Default"):sub(1, 1):upper() .. tostring(cfg.Size or "Default"):sub(2):lower()] or SIZES.Default
    local buttonHeight, textSize, iconSize = size[1], size[2], size[3]
    local height = cfg.Desc and buttonHeight + 16 or buttonHeight
    local title = cfg.Title ~= nil and tostring(cfg.Title) or (cfg.Icon and "" or "Button")
    local row = create("Frame", { Name = title ~= "" and title or tostring(cfg.Icon), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, height), LayoutOrder = card:_order(), Parent = card.body })
    local button = create("TextButton", {
        Name = "Button", Size = UDim2.new(1, 0, 0, buttonHeight), BorderSizePixel = 0, Text = title,
        TextSize = textSize, Font = Enum.Font.Gotham, AutoButtonColor = false, Parent = row,
    })
    corner(button, 6)
    local outline = stroke(button)
    local desc
    if cfg.Desc then
        desc = Util.label(row, tostring(cfg.Desc), 9, { Position = UDim2.fromOffset(2, buttonHeight + 2), Size = UDim2.new(1, -4, 0, 14) })
        Theme.bind(desc, "TextColor3", "muted")
    end

    -- Icon = "name": icon + text together (centred, or on the left with Align = "Left"); IconSide = "Right" swaps them
    local icon, textLabel
    local left = tostring(cfg.Align or ""):lower() == "left"
    if cfg.Icon and Icons.Get(cfg.Icon) then
        local content = create("Frame", {
            Name = "Content", BackgroundTransparency = 1, AnchorPoint = Vector2.new(left and 0 or 0.5, 0.5),
            Position = left and UDim2.new(0, 10, 0.5, 0) or UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0, 1), AutomaticSize = Enum.AutomaticSize.X, Parent = button,
        })
        Util.list(content, 6, Enum.FillDirection.Horizontal, left and Enum.HorizontalAlignment.Left or Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center)
        local right = tostring(cfg.IconSide or ""):lower() == "right"
        icon = Icons.themed(content, cfg.Icon, iconSize, "text", { Name = "ButtonIcon", LayoutOrder = right and 3 or 1 })
        textLabel = Util.label(content, button.Text, textSize, { Name = "Text", Size = UDim2.fromScale(0, 1), AutomaticSize = Enum.AutomaticSize.X, TextTruncate = Enum.TextTruncate.None, LayoutOrder = 2, Visible = title ~= "" })
        -- keep the label in step with the button's text / colour (hover, Confirm)
        button:GetPropertyChangedSignal("Text"):Connect(function()
            if button.Text ~= "" then textLabel.Text = button.Text textLabel.Visible = true button.Text = "" end
        end)
        button:GetPropertyChangedSignal("TextColor3"):Connect(function()
            textLabel.TextColor3 = button.TextColor3
            if icon then icon.ImageColor3 = button.TextColor3 end
        end)
        button.Text = ""
    elseif left then
        button.TextXAlignment = Enum.TextXAlignment.Left
        Util.padding(button, 10, 10, 0, 0)
    end

    local element = Base.element(card, "Button", cfg, row, button, desc)
    element.Text = title
    local style = STYLES[styleName(cfg.Style)]
    local hovered = false
    local function textRole(set)
        -- Risky keeps the red text on the plain styles
        if cfg.Risky and (style == STYLES.Default or style == STYLES.Outline or style == STYLES.Ghost) then return "danger" end
        return set.text
    end
    local function paint(duration)
        local set = hovered and style.hover or style
        Theme.tweenTo(button, "BackgroundColor3", set.bg, duration)
        Theme.tweenTo(button, "TextColor3", textRole(set), duration)
        if duration > 0 then Util.tween(button, duration, { BackgroundTransparency = set.bgT }) else button.BackgroundTransparency = set.bgT end
        Theme.tweenTo(outline, "Color", style.edge, duration)
        outline.Transparency = style.edgeT
        -- the icon and label follow the same role (so a theme change repaints them right too)
        if textLabel then Theme.tweenTo(textLabel, "TextColor3", textRole(set), duration) end
        if icon then Theme.tweenTo(icon, "ImageColor3", textRole(set), duration) end
    end
    paint(0)

    function element:SetTitle(text) self.Text = tostring(text) button.Text = self.Text end
    function element:SetIcon(name) if icon then Icons.Apply(icon, name) end end
    function element:SetStyle(name) style = STYLES[styleName(name)] self.Style = styleName(name) paint(0.12) end
    function element:Fire() element:_call(cfg.Callback) end
    element.Style = styleName(cfg.Style)

    button.MouseEnter:Connect(function() hovered = true paint(0.12) end)
    button.MouseLeave:Connect(function() hovered = false paint(0.12) end)
    local armed = 0
    button.Activated:Connect(function()
        require("sounds").Play("click")
        if element.Locked then return end
        if cfg.Confirm then
            if armed == 0 then
                armed = armed + 1
                local token = armed
                button.Text = type(cfg.Confirm) == "string" and cfg.Confirm or "Click again to confirm"
                Theme.tweenTo(outline, "Color", "accent", 0.1)
                outline.Transparency = 0
                task.delay(2, function()
                    if armed == token and button.Parent then
                        armed = 0
                        button.Text = element.Text
                        if element.Text == "" and textLabel then textLabel.Visible = false end
                        paint(0.1)
                    end
                end)
                return
            end
            armed = 0
            button.Text = element.Text
            if element.Text == "" and textLabel then textLabel.Visible = false end
            paint(0.1)
        end
        element:_call(cfg.Callback)
    end)
    return Base.finish(element, cfg)
end
